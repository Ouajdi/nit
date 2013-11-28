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

redef class FFILanguageAssignationPhase
	var c_language: FFILanguage = new CLanguage(self)
end

class CLanguage
	super FFILanguage

	redef fun identify_language(n) do return n.is_c

	redef fun compile_module_block(block, ecc, nmodule)
	do
		if block.is_c_header then
			ecc.header_custom.add( block.location.as_line_pragma )
			ecc.header_custom.add( block.code )
		else if block.is_c_body then
			ecc.body_custom.add( block.location.as_line_pragma )
			ecc.body_impl.add( block.code )
		end
	end

	redef fun compile_extern_method(block, m, ecc, nmodule)
	do
		var fc = new ExternCFunction(m, nmodule.mmodule.as(not null))
		fc.decls.add( block.location.as_line_pragma )
		fc.exprs.add( block.code )
		ecc.add_exported_function( fc )
	end

	redef fun compile_extern_class(block, m, ecc, nmodule) do end

	redef fun get_ftype(block, m) do return new ForeignCType(block.code)

	redef fun compile_callback(callback, nmodule, mmodule, ecc)
	do
		callback.compile_callback_to_c(mmodule, ecc)
	end
end

redef class AExternCodeBlock
	fun is_c : Bool do return language_name == null or
		language_name_lowered == "c" or language_name_lowered.has_prefix( "c " )

	fun is_c_body : Bool do return language_name == null or
		language_name_lowered == "c" or language_name_lowered ==  "c body"

	fun is_c_header : Bool do return language_name_lowered == "c header"
end

redef class Location
	fun as_line_pragma : String
	do
		return "" #line {line_start} \"{file.filename}\"\n"
	end
end

redef class AModule
	var c_compiler_options writable = ""
	var c_linker_options writable = ""
end

# An extern C file to compile
class ExternCFile
	super ExternFile

	init (filename, cflags: String)
	do
		super filename

		self.cflags = cflags
	end

	# Additionnal specific CC compiler -c flags
	var cflags: String

	redef fun hash do return filename.hash
	redef fun ==(o) do return o isa ExternCFile and filename == o.filename
end

class ForeignCType
	super ForeignType

	redef var ctype: String

	init(ctype: String)
	do
		self.ctype = ctype
	end
end

redef class NitniCallback
	fun compile_callback_to_c(nmodule: MModule, ffi_ccu: CCompilationUnit) do end
end

redef class Object
	fun to_c_call_context: ToCCallContext do return once new ToCCallContext
	fun from_c_call_context: FromCCallContext do return once new FromCCallContext
end

redef class MExplicitCall
	redef fun compile_callback_to_c(mmodule, ffi_ccu)
	do
		var mproperty = mproperty.as(MMethod)

		var full_cname = mproperty.build_cname(recv_mtype, mmodule, null, long_signature, from_c_call_context)
		var friendly_cname = mproperty.build_cname(recv_mtype, mmodule, null, short_signature, to_c_call_context)
		ffi_ccu.body_decl.add("#define {friendly_cname} {full_cname}\n")
	end
end

# Call within, from and to C FFI
class CCallContext
	super CallContext
end

# Call from intern to C FFI
class ToCCallContext
	super CCallContext

	redef fun name_mtype(mtype)
	do
		if mtype isa MClassType and mtype.mclass.kind == extern_kind then return "void *"
		return mtype.cname
	end
end

# Call from C FFI to intern
class FromCCallContext
	super CCallContext

	redef fun name_mtype(mtype) do return mtype.cname
end

class ExternCFunction
	super CFunction

	var method: AExternPropdef

	init (method: AExternPropdef, mmodule: MModule)
	do
		self.method = method

		var recv_mtype = method.mpropdef.mclassdef.bound_mtype
		var csignature = method.mpropdef.mproperty.build_csignature(recv_mtype, mmodule, "___impl", long_signature, from_c_call_context)

		super( csignature )
	end
end
