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

import ffi_base

class CVisitor
	super FFIVisitor

	redef fun identify_language( n ) do return n.is_c

	redef fun compile_module_block( block, m, ecc )
	do
		if block.is_c_header then
			ecc.header_custom.add( block.location.as_line_pragma )
			ecc.header_custom.add( block.code )
		else if block.is_c_body then
			ecc.body_custom.add( block.location.as_line_pragma )
			ecc.body_custom.add( block.code )
		end
	end

	redef fun compile_extern_method( block, m, ecc )
	do
		var fc = new ExternFunctionCompiler( m )
		fc.decls.add( block.location.as_line_pragma )
		fc.exprs.add( block.code )
		ecc.add_exported( fc )
	end

	redef fun compile_extern_class( block, m, ecc )
	do
		return block.code
	end
end

redef class AExternCodeBlock
	fun is_c : Bool do return language == null or
		language_lowered == "c" or language_lowered.has_prefix( "c " )

	fun is_c_body : Bool do return language == null or
		language_lowered == "c" or language_lowered ==  "c body"

	fun is_c_header : Bool do return language_lowered == "c header"
end

redef class Location
	fun as_line_pragma : String
	do
		return "#line {line_start} \"{file.filename}\"\n"
	end
end
