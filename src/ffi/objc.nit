# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Copyright 2014 Alexis Laferrière <alexis.laf@xymus.net>
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

# FFI support for Objective-C
#
# Compiles all Objective-C code with clang. The user module must define
# the framework used.
#
# This module is heavily based on the C++ FFI.
module objc

import extern_classes
import c

redef class FFILanguageAssignationPhase
	# The Objective-C language visitor
	var objc_language: FFILanguage = new ObjCLanguage(self)
end

redef class MModule
	private var objc_file: nullable ObjCCompilationUnit = null
end

class ObjCLanguage
	super FFILanguage

	redef fun identify_language(n) do return n.is_objc

	redef fun compile_module_block(block, ecc, mmodule)
	do
		if mmodule.objc_file == null then mmodule.objc_file = new ObjCCompilationUnit

		if block.is_objc_header then
			mmodule.objc_file.header_custom.add block.location.as_line_pragma
			mmodule.objc_file.header_custom.add block.code
		else if block.is_objc_body then
			mmodule.objc_file.body_custom.add block.location.as_line_pragma
			mmodule.objc_file.body_custom.add block.code
		end
	end

	redef fun compile_extern_method(block, m, ecc, mmodule)
	do
		if mmodule.objc_file == null then mmodule.objc_file = new ObjCCompilationUnit

		var parent = m.parent
		assert parent isa AClassdef

		var mclass_type = parent.mclass.mclass_type
		var mproperty = m.mpropdef.mproperty

		# Signature of the indirection function implemented as `extern "C"` in Objective-C
		var indirection_sig = mproperty.build_csignature(mclass_type, mmodule, "___objc_impl_mid", long_signature, internal_call_context)

		## In C file (__ffi.c)
		
		# Declare the indirection function in C
		ecc.body_decl.add "{indirection_sig};\n"

		# Call the indirection function from C (___impl)
		var fc: CFunction = new ExternCFunction(m, mmodule)
		fc.exprs.add mproperty.build_ccall(mclass_type, mmodule, "___objc_impl_mid", long_signature, objc_call_context, null)
		fc.exprs.add "\n"
		ecc.add_exported_function fc

		## In Objective-C file (__ffi.m)

		# Declare the indirection function in Objective-C
		mmodule.objc_file.header_decl.add """
extern "C" {
	{{{indirection_sig}}};
}
"""

		# Implement the indirection function as extern in Objective-C
		# Will convert C arguments to Objective-C and call the Objective-C
		# implementation function.
		fc = new CFunction(indirection_sig)
		if not mproperty.is_init then
			var param_name = "recv"
			var type_name = to_objc_call_context.name_mtype(mclass_type)
			if mclass_type.mclass.ftype isa ForeignObjCType then
				fc.exprs.add "{type_name} {param_name}_for_objc = ({type_name})({param_name});\n"
			else
				fc.exprs.add "{type_name} {param_name}_for_objc = {param_name};\n"
			end
		end
		for param in m.mpropdef.msignature.mparameters do
			var param_name = param.name
			var type_name = to_objc_call_context.name_mtype(param.mtype)
			if mclass_type.mclass.ftype isa ForeignObjCType then
				fc.exprs.add("{type_name} {param_name}_for_objc = ({type_name})({param_name});\n")
			else
				fc.exprs.add("{type_name} {param_name}_for_objc = {param_name};\n")
			end
		end
		fc.exprs.add(mproperty.build_ccall(mclass_type, mmodule, "___objc_impl", long_signature, objc_call_context, "_for_objc"))
		fc.exprs.add("\n")
		mmodule.objc_file.add_exported_function fc

		# Custom Objective-C, the body of the Nit Objective-C method
		# is copied to its own Objective-C function
		var objc_signature = mproperty.build_csignature(mclass_type, mmodule, "___objc_impl", long_signature, objc_call_context)
		fc = new CFunction(objc_signature)
		fc.decls.add block.location.as_line_pragma
		fc.exprs.add block.code
		mmodule.objc_file.add_local_function fc
	end

	redef fun compile_extern_class(block, m, ecc, mmodule) do end

	redef fun get_ftype(block, m) do return new ForeignObjCType(block.code)

	redef fun compile_to_files(mmodule, compdir)
	do
		var objc_file = mmodule.objc_file
		assert objc_file != null

		# write .objc and .hpp file
		mmodule.objc_file.header_decl.add """
extern "C" {
	#include "{{{mmodule.name}}}._ffi.h";
}
"""

		var file = objc_file.write_to_files(mmodule, compdir)

		# add complation to makefile
		mmodule.ffi_files.add file
	end

	redef fun compile_callback(callback, mmodule, mainmodule, ecc)
	do
		callback.compile_callback_to_objc(mmodule, mainmodule)
	end
end

redef class AExternCodeBlock
	# Is this Objective-C code?
	fun is_objc : Bool do return language_name != null and
		(language_name_lowered == "objc" or language_name_lowered.has_prefix("objc "))

	# Is this Objective-C code for the body file?
	fun is_objc_body : Bool do return language_name != null and
		(language_name_lowered == "objc" or language_name_lowered == "objc body")

	# Is this Objective-C code for the header file?
	fun is_objc_header : Bool do return language_name != null and
		(language_name_lowered == "objc header")
end

class ObjCCompilationUnit
	super CCompilationUnit

	# Write this compilation unit to Objective-C source files
	fun write_to_files(mmodule: MModule, compdir: String): ExternObjCFile
	do
		var base_name = "{mmodule.name}._ffi"

		var h_file = "{base_name}.h"
		var guard = "{mmodule.cname.to_s.to_upper}_NIT_OBJC_H"

		write_header_to_file(mmodule, compdir/h_file, new Array[String], guard)

		var c_file = "{base_name}.m"
		write_body_to_file(mmodule, compdir/c_file, ["\"{h_file}\""])

		files.add compdir/c_file

		mmodule.c_linker_options = "{mmodule.c_linker_options} -lobjc"

		return new ExternObjCFile(compdir/c_file, mmodule)
	end
end

# A Objective-C file
class ExternObjCFile
	super ExternFile

	# Associated `MModule`
	var mmodule: MModule

	redef fun makefile_rule_name do return "{filename.basename(".m")}_m.o"
	redef fun makefile_rule_content do
		return "clang $(CFLAGS) -c {filename.basename("")} -o {makefile_rule_name}"
	end
	redef fun compiles_to_o_file do return true
end

# An Objective-C type
class ForeignObjCType
	super ForeignType

	# Type name
	var objc_type: String
end

redef class NitniCallback
	# Compile this callback to be callable from Objective-C
	fun compile_callback_to_objc(mmodule: MModule, mainmodule: MModule) do end
end

redef class Object
	private fun objc_call_context: ObjCCallContext do return once new ObjCCallContext
	private fun to_objc_call_context: ToObjCCallContext do return once new ToObjCCallContext
	private fun from_objc_call_context: FromObjCCallContext do return once new FromObjCCallContext
end

redef class MExplicitCall
	redef fun compile_callback_to_objc(mmodule, mainmodule)
	do
		var mproperty = mproperty
		assert mproperty isa MMethod

		var objc_signature = mproperty.build_csignature(recv_mtype, mainmodule, null, short_signature, from_objc_call_context)
		var ccall = mproperty.build_ccall(recv_mtype, mainmodule, null, long_signature, from_objc_call_context, null)
		var fc = new CFunction(objc_signature)
		fc.exprs.add ccall
		mmodule.objc_file.add_local_function fc
	end
end

private class ObjCCallContext
	super CallContext

	redef fun name_mtype(mtype)
	do
		if mtype isa MClassType then
			var ftype = mtype.mclass.ftype
			if ftype isa ForeignObjCType then
				return ftype.objc_type
			end
		end

		return mtype.cname
	end
end

class ToObjCCallContext
	super ObjCCallContext

	redef fun cast_to(mtype, name)
	do
		if mtype isa MClassType and mtype.mclass.ftype isa ForeignObjCType then
			return "(void*)({name})"
		else return name
	end
end

private class FromObjCCallContext
	super ObjCCallContext

	redef fun cast_from(mtype, name)
	do
		if mtype isa MClassType and mtype.mclass.ftype isa ForeignObjCType then
			return "({name_mtype(mtype)})({name})"
		else return name
	end
end
