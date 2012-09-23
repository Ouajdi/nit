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

module ffi_base

import c_tools
import parser
import modelbuilder
import nitni

redef class AExternCodeBlock
	fun language : nullable String do
		if n_in_language == null then return null
		return n_in_language.n_string.without_quotes
	end
	fun language_lowered : nullable String do
		if language == null then return null
		return language.to_lower
	end

	fun code : String do return n_extern_code_segment.without_guard

	var handler : nullable FFIVisitor writable = null
end

class FFIVisitor
	# module being visited
	#var mmmodule : AModule

	fun identify_language( block : AExternCodeBlock ) : Bool is abstract

	fun compile_module_block( block : AExternCodeBlock, m : AModule, ecc : ExternCodeCompiler ) is abstract
	fun compile_extern_method( block : AExternCodeBlock, m : AExternMethPropdef, ecc : ExternCodeCompiler ) is abstract
	fun compile_extern_class( block : AExternCodeBlock, m : AClassdef, ecc : ExternCodeCompiler ) : String is abstract
end

redef class AModule

	#redef fun accept_ffi_visitor( v )
	fun visit_ffi !visit( n : ANode )
	do
		for block in n_extern_code_blocks do
			#block.accept_ffi_verify( block )
			visit( block )
		end

		for nclassdef in n_classdefs do
			visit( nclassdef )
			for npropdef in nclassdef.n_propdefs do
				if npropdef isa AExternMethPropdef then
					visit( npropdef )
				end
			end
		end
	end
	fun visit_foreign_code !visit( n : AExternCodeBlock )
	do
		for block in n_extern_code_blocks do
			visit( block )
		end

		for nclassdef in n_classdefs do
			if nclassdef isa AStdClassdef and nclassdef.n_extern_code_block != null then
				visit( nclassdef.n_extern_code_block.as(not null) )
			end
			for npropdef in nclassdef.n_propdefs do
				if npropdef isa AExternMethPropdef then
					if npropdef.n_extern_code_block != null then
						visit( npropdef.n_extern_code_block.as(not null) )
					end
				end
			end
		end
	end

end

# FFI utils
redef class TString
	fun without_quotes : String
	do
		assert text.length >= 2

		return text.substring( 1, text.length - 2)
	end
end

redef class TExternCodeSegment
	fun without_guard : String
	do
		assert text.length >= 4

		return text.substring( 2, text.length - 4)
	end
end

class ExternFunctionCompiler
	super FunctionCompiler

	var method : AExternMethPropdef

	init ( m : AExternMethPropdef )
	do
		method = m

		var r
		if method.mpropdef.msignature.return_mtype != null then
			r = method.mpropdef.msignature.return_mtype.cname
		else
			r = "void"
		end

		var params = new Array[String]
		if not method.mpropdef.mproperty.is_init then
			params.add( "{method.mpropdef.mclassdef.mclass.mclass_type.cname} recv" )
		end
		for p in [0..method.mpropdef.msignature.arity[ do
			var name = method.mpropdef.msignature.parameter_names[p]
			var mtype = method.mpropdef.msignature.parameter_mtypes[p]

			params.add( "{mtype.cname} {name}" )
		end

		var sig = "{r} {method.mpropdef.impl_cname}( {params.join( ", " )} )"
		super( sig )
	end
end
