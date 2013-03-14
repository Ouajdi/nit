# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2013 Lucas Bajolet <lucas.bajolet@gmail.com>
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

# Debugging of a nit program using the NaiveInterpreter
module debugger

intrude import naive_interpreter

redef class ToolContext
	# -d
	var opt_debugger_mode: OptionBool = new OptionBool("Launches the target program with the debugger attached to it", "-d")

	redef init
	do
		super
		self.option_context.add_option(self.opt_debugger_mode)
	end
end

redef class ModelBuilder
	# Execute the program from the entry point (Sys::main) of the `mainmodule'
	# `arguments' are the command-line arguments in order
	# REQUIRE that:
	#   1. the AST is fully loaded.
	#   2. the model is fully built.
	#   3. the instructions are fully analysed.
	fun run_debugger(mainmodule: MModule, arguments: Array[String])
	do
		var time0 = get_time
		self.toolcontext.info("*** START INTERPRETING ***", 1)

		var interpreter = new Debugger(self, mainmodule, arguments)

		init_naive_interpreter(interpreter, mainmodule)

		var time1 = get_time
		self.toolcontext.info("*** END INTERPRETING: {time1-time0} ***", 2)
	end
end

# The class extending NaiveInterpreter by adding debugging methods
class Debugger
	super NaiveInterpreter

	# Seeks a variable from the current frame called 'variable_path', can introspect complex objects using function get_variable_in_mutable_instance
	private fun seek_variable(variable_path: String, frame: Frame): nullable Instance
	do
		var full_variable = variable_path.split_with(".")

		var full_variable_iterator = full_variable.iterator

		var first_instance = get_variable_in_frame(full_variable_iterator.item, frame)

		if first_instance == null then	return null

		if full_variable.length <= 1 then return first_instance

		full_variable_iterator.next

		if not (first_instance isa MutableInstance and full_variable_iterator.is_ok) then return null

		return get_variable_in_mutable_instance(first_instance, full_variable_iterator)
	end

	# Gets a variable 'variable_name' contained in the frame 'frame'
	private fun get_variable_in_frame(variable_name: String, frame: Frame): nullable Instance
	do
		if variable_name == "self" then
			if frame.arguments.length >= 1 then return frame.arguments.first
		end

		var map_of_instances = frame.map

		for key in map_of_instances.keys do
			if key.to_s == variable_name then
				return map_of_instances[key]
			end
		end

		return null
	end

	# Gets an attribute 'attribute_name' contained in variable 'variable'
	fun get_attribute_in_mutable_instance(variable: MutableInstance, attribute_name: String): nullable MAttribute
	do
		var map_of_attributes = variable.attributes

		for key in map_of_attributes.keys do
			if key.to_s.substring_from(1) == attribute_name then
				return key
			end
		end

		return null
	end

	# Recursive function, returns the variable described by 'total_chain'
	fun get_variable_in_mutable_instance(variable: MutableInstance, iterator: Iterator[String]): nullable Instance
	do
		var attribute = get_attribute_in_mutable_instance(variable, iterator.item)

		if attribute == null then return null

		iterator.next

		if iterator.is_ok then
			var new_variable = variable.attributes[attribute]
			if new_variable isa MutableInstance then
				return get_variable_in_mutable_instance(new_variable, iterator)
			else
				return null
			end
		else
			return variable.attributes[attribute]
		end
	end

end
