# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2012 Alexis Laferrière <alexis.laf@xymus.net>
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

module nitni

import parser
import modelbuilder # builder only for externcalls

redef class MMethod
	fun short_cname : String do
		var nit_name = name
		#var nit_name = mpropdef.mproperty.name

		if nit_name == "+" then
			return "_plus"
		# TODO others
		else
			return nit_name
		end
	end
	fun call_cname( recv : MClass ) : String do return "{recv.name}_{short_cname}"
end

# TODO
#redef class MMethod
	#fun callback_cname( recv : MClass ) : String
	#do
		#return ""
	#end
#end

redef class AModule
	fun cname : String do return ""
end

redef class MMethodDef
	fun cname : String do return "{mclassdef.mclass.name}_{mproperty.short_cname}"
	fun impl_cname : String do return "{cname}___impl"
	fun super_cname : String do return "{cname}___super"
end

redef class MType
	fun cname : String is abstract
	fun is_cprimitive : Bool is abstract
end

redef class MClassType
	redef fun cname
	do
		var name = mclass.name
		if name == "Float" then
			return "float"
		else if name == "Int" then
			return "int"
		else
			return mclass.name
		end
	end

	redef fun is_cprimitive
	do
		var name = mclass.name
		return name == "Float" or name == "Int"
	end

end
