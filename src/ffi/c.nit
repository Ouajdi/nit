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

# handles C inline code
# Doesn't do much since intermediate code is in C
module c

import hybrid_module

redef class ExternCode
	fun is_c : Bool do return language == null or
		language_lowered == "c" or language_lowered.has_prefix( "c " )

	fun is_c_body : Bool do return language == null or
		language_lowered == "c" or language_lowered ==  "c body"

	fun is_c_header : Bool do return language_lowered == "c header"

	redef fun accept_ffi_visitor( v ) do if not is_c then super
end

redef class MMMethod
	redef fun accept_ffi_visitor( v )
	do
		if extern_implementation.is_c then
			var fc = new ExternFunctionCompiler( self )
			fc.decls.add( extern_implementation.location.as_line_pragma ) # TODO move?
			fc.exprs.add( extern_implementation.code )
			v.add( fc )
		else
			super
		end
	end
end

redef class Location
	fun as_line_pragma : String
	do
		return "#line {line_start} \"{file.filename}\"\n"
	end
end

redef class MMModule
	redef fun accept_ffi_visitor( v )
	do
		super

		for block in extern_code_blocks do
			if block.is_c_header then
				v.header_custom.add( block.code )
			else if block.is_c_body then
				v.body_custom.add( block.code )
			end
		end
	end
end
