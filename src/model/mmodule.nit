# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012 Jean Privat <jean@pryen.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# modules and module hierarchies in the metamodel
module mmodule

import location
import mproject
private import more_collections

# The container class of a Nit object-oriented model.
# A model knows modules, classes and properties and can retrieve them.
redef class Model
	# All known modules
	var mmodules = new Array[MModule]

	# Full module importation hierarchy including private or nested links.
	var mmodule_importation_hierarchy = new POSet[MModule]

	# Collections of modules grouped by their short names
	private var mmodules_by_name = new MultiHashMap[String, MModule]

	# Return all module named `name`
	# If such a module does not exist, null is returned (instead of an empty array)
	#
	# Visibility or modules are not considered
	fun get_mmodules_by_name(name: String): nullable Array[MModule]
	do
		if mmodules_by_name.has_key(name) then
			return mmodules_by_name[name]
		else
			return null
		end
	end
end

redef class MGroup
	# The loaded modules of this group
	var mmodules = new Array[MModule]

	# The default module of a group (if any, and if loaded)
	#
	# The default module of a group is the one that has the same name.
	# Return `null` if the group has no default module or if the default
	# module is not loaded.
	var default_mmodule: nullable MModule = null

	redef fun mdoc_or_fallback
	do
		if mdoc != null then return mdoc
		if default_mmodule == null then return null
		return default_mmodule.mdoc_or_fallback
	end
end

# A Nit module is usually associated with a Nit source file.
class MModule
	super MConcern

	# The model considered
	redef var model: Model

	# The group of module in the project if any
	var mgroup: nullable MGroup

	# The short name of the module
	redef var name: String

	# The origin of the definition
	var location: Location

	# Alias for `name`
	redef fun to_s do return self.name

	# The view of the module in the `model.mmodule_importation_hierarchy`
	var in_importation: POSetElement[MModule] is noinit

	# The canonical name of the module
	# Example: `"project::name"`
	fun full_name: String
	do
		var mgroup = self.mgroup
		if mgroup == null or mgroup.mproject.name == self.name then
			return self.name
		else
			return "{mgroup.mproject.name}::{self.name}"
		end
	end

	# Create a new empty module and register it to a model
	init
	do
		model.mmodules_by_name.add_one(name, self)
		model.mmodules.add(self)
		if mgroup != null then
			mgroup.mmodules.add(self)
			if mgroup.name == name then
				assert mgroup.default_mmodule == null
				mgroup.default_mmodule = self
			end
			# placebo for old module nesting hierarchy
			var direct_owner = mgroup.default_mmodule
			if direct_owner == self then
				# The potential owner is the default_mmodule of the parent group
				if mgroup.parent != null then direct_owner = mgroup.parent.default_mmodule
			end
		end
		self.in_importation = model.mmodule_importation_hierarchy.add_node(self)
	end

	# Register the imported modules (ie "import some_module")
	# This function can only invoked once by mmodule.
	# The visibility must be set with `set_visibility_for`.
	fun set_imported_mmodules(imported_mmodules: Array[MModule])
	do
		assert unique_invocation: self.in_importation.direct_greaters.is_empty
		for m in imported_mmodules do
			self.model.mmodule_importation_hierarchy.add_edge(self, m)
		end
	end

	private var intrude_mmodules = new HashSet[MModule]
	private var public_mmodules = new HashSet[MModule]
	private var private_mmodules = new HashSet[MModule]

	# Return the visibility level of an imported module `m`
	fun visibility_for(m: MModule): MVisibility
	do
		if m == self then return intrude_visibility
		if self.intrude_mmodules.has(m) then return intrude_visibility
		if self.public_mmodules.has(m) then return public_visibility
		if self.private_mmodules.has(m) then return private_visibility
		return none_visibility
	end

	# Set the visibility of an imported module
	# REQUIRE: the visibility of the modules imported by `m` are already set for `m`
	fun set_visibility_for(m: MModule, v: MVisibility)
	do
		if v == intrude_visibility then
			self.intrude_mmodules.add(m)
			self.intrude_mmodules.add_all(m.intrude_mmodules)
			self.public_mmodules.add_all(m.public_mmodules)
			self.private_mmodules.add_all(m.private_mmodules)
		else if v == public_visibility then
			self.public_mmodules.add(m)
			self.public_mmodules.add_all(m.intrude_mmodules)
			self.public_mmodules.add_all(m.public_mmodules)
		else if v == private_visibility then
			self.private_mmodules.add(m)
			self.private_mmodules.add_all(m.intrude_mmodules)
			self.private_mmodules.add_all(m.public_mmodules)
		else
			print "{self} visibility for {m} = {v}"
			abort # invalid visibility
		end
	end

	# Return true if a class or a property introduced in `intro_mmodule` with a visibility of `visibility` is visible in self.
	fun is_visible(intro_mmodule: MModule, visibility: MVisibility): Bool
	do
		var v = visibility_for(intro_mmodule)
		if v == intrude_visibility then
			return visibility >= private_visibility
		else if v == public_visibility then
			return visibility > private_visibility
		else if v == private_visibility then
			return visibility > private_visibility
		else if v == none_visibility then
			return false
		else
			abort
		end
	end

	# Is `self` created for internal purpose?
	# Fictive modules are instantiated internally but they should not be
	# exposed to the final user.
	var is_fictive: Bool = false is writable

	redef fun parent_concern do return mgroup
end
