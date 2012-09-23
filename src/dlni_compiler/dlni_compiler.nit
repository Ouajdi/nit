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

module dlni_compiler

import modelbuilder
import c_tools
import nitni

import dlni

class DLNICompiler
	var modelbuilder : ModelBuilder
	var files = new Array[String]

	var used_types = new HashSet[MType]

	# TODO move
	fun verify_nitni( m : AModule )
	do
		# collect callbacks
		for nclassdef in m.n_classdefs do
			for npropdef in nclassdef.n_propdefs do
				if npropdef isa AExternMethPropdef then # extern methods
					var ecs = npropdef.n_extern_calls
					if ecs != null then
						for call in ecs.n_extern_calls do
						end
					end

					# recv, return and param types
					# recv
					if not npropdef.mpropdef.mproperty.is_init then
						used_types.add( npropdef.mpropdef.mclassdef.mclass.mclass_type )
					end

					# return
					var rmt = npropdef.mpropdef.msignature.return_mtype
					if rmt != null then used_types.add( rmt ) # TODO resolve

					# params
					for t in npropdef.mpropdef.msignature.parameter_mtypes do
						used_types.add( t )
					end
				end
			end
		end
	end

	fun compile_dlni( m : AModule, compdir : String )
	do
		# ready extern code compiler
		var ecc = new ExternCodeCompiler

		ecc.header_decl.add( "typedef union u_native_call_stack_t \{\n" )
		ecc.header_decl.add( "\tvoid* instance; /* void* in lib */\n" )
		ecc.header_decl.add( "\tint int_v;\n" )
		ecc.header_decl.add( "\tfloat float_v;\n" )
		ecc.header_decl.add( "\} native_call_stack_t;\n" )

		ecc.body_decl.add( "#include <string.h>\n" )

		# types
		for t in used_types do
			var w = t.compile_ctype
			ecc.header_c_types.append( w )
		end

		# callbacks

		# casts

		for nclassdef in m.n_classdefs do
			for npropdef in nclassdef.n_propdefs do
				if npropdef isa AExternMethPropdef then # extern methods
					npropdef.compile_dlni_entry( ecc )
				end
			end
		end

		m.compile_ready_call_fun( ecc )

		ecc.write_as_dlni_frontier( m, compdir )
		files = ecc.files # TODO this is a horrible hack :(
	end
end

redef class ExternCodeCompiler
	fun write_as_dlni_frontier( amodule : AModule, compdir : String )
	do
		var base_name = "{amodule.mmodule.name}._nitni"
		var c_file = "{base_name}.c"
		var h_file = "{base_name}.h"

		# header comments
		var module_info = "/*\n\tExtern implementation of Nit module {amodule.mmodule.name}\n*/\n"

		# header file guard
		var guard = "{amodule.cname.to_s.to_upper}_DLNI_H"

		# .h
		var stream = new OFStream.open( "{compdir}/{h_file}" )
		stream.write( module_info )
		#stream.write( "#include <{amodule.mmodule.name}._nitni.h>\n\n" )
		stream.write( "#ifndef {guard}\n" )
		stream.write( "#define {guard}\n\n" )

		compile_header_core( stream )

		# header file guard close
		stream.write( "#endif\n" )

		stream.close

		# .c
		stream = new OFStream.open( "{compdir}/{c_file}" )
		stream.write( module_info )
		stream.write( "#include \"{h_file}\"\n" )

		compile_body_core( stream )

		stream.close

		files.add( "{compdir}/{c_file}" )
	end
end

redef class AMethPropdef
	# compiles the dynamic wrapper function to get to the custom code
	fun compile_dlni_entry( ecc : ExternCodeCompiler )
	do
		# move different signature to nitni
		var r
		if mpropdef.msignature.return_mtype != null then
			r = mpropdef.msignature.return_mtype.cname
		else
			r = "void"
		end

		var params = new Array[String]
		if not mpropdef.mproperty.is_init then
			params.add( mpropdef.mclassdef.mclass.mclass_type.cname )
		end
		for p in [0..mpropdef.msignature.arity[ do
			params.add( mpropdef.msignature.parameter_mtypes[p].cname )
		end

		var sig = "extern {r} {mpropdef.impl_cname}( {params.join( ", " )} );\n"
		ecc.body_decl.add( sig )

		var fc = new FunctionCompiler( "static int {mpropdef.entry_cname}( int argc, native_call_stack_t* argv, native_call_stack_t *result )" )

		# check argc
		fc.exprs.add( "\tif ( argc != {mpropdef.msignature.arity + 1} ) \{\n" ) # TODO check for vararg
		#fc.exprs.add( "\t\tnit_abort( \"Invalid argument count in '{mpropdef.mproperty.full_name}'\" );\n" )
		# TODO make optional
		#fc.exprs.add( "\t\tprintf( \"Invalid argument count in '{mpropdef.mproperty.full_name}'\" );\n" )
		#fc.exprs.add( "\t\texit( 1 );\n" )
		fc.exprs.add( "\t\}\n" )

		# unpack and prepare args
		var k = 0 # count position in argv
		var args_for_call = new Array[String]
		for p in [0 .. mpropdef.msignature.arity] do
			var ctype
			var arg_name
			if p == 0 then
				ctype = mpropdef.mclassdef.mclass.mclass_type.cname
				arg_name = "arg___self"
			else
				ctype = mpropdef.msignature.parameter_mtypes[p-1].cname
				arg_name = "arg__{mpropdef.msignature.parameter_names[p-1]}"
			end

			fc.decls.add( "\t{ctype} {arg_name};\n" )
			if ctype == "int" then
				fc.exprs.add( "\t{arg_name} = argv[{k}].int_v;\n" )
			else if ctype == "float" then
				fc.exprs.add( "\t{arg_name} = argv[{k}].float_v;\n" )
				# TODO
			else
				fc.exprs.add( "\t{arg_name} = argv[{k}].instance;\n" )
			end
			args_for_call.add( arg_name )

			k += 1
		end

		# call impl
		var args_compressed = args_for_call.join(", ")
		var rmt = mpropdef.msignature.return_mtype
		if rmt != null then
			fc.decls.add( "\t{rmt.cname} rval;\n" ) # malloc( sizeof(void*) );\n" )
			fc.exprs.add( "\trval = {mpropdef.impl_cname}( {args_compressed} );\n" )
			if rmt.cname == "int" then
				fc.exprs.add( "\tresult->int_v = rval;\n" )
			else if rmt.cname == "float" then
				fc.exprs.add( "\tresult->float_v = rval;\n" )
			else
				fc.exprs.add( "\tresult->instance = (void*)rval;\n" )
			end
			# TODO move result to caller...
		else
			fc.exprs.add( "\t{mpropdef.impl_cname}( {args_compressed} );\n" ) 
		end

		fc.exprs.add( "\treturn 0;\n" )

		ecc.add_local( fc )
	end
end

redef class AModule

	# TODO move?
	fun foreach_extern_meth !act( n : AExternMethPropdef )
	do
		for nclassdef in n_classdefs do
			for npropdef in nclassdef.n_propdefs do
				if npropdef isa AExternMethPropdef then # extern methods
					act( npropdef )
				end
			end
		end
	end

	# compiles a method to prepare a dynamic call from the interpreter
	# it returns a pointer to the appropriate function to call
	fun compile_ready_call_fun( ecc : ExternCodeCompiler )
	do
		var extern_meths = new Array[AExternMethPropdef]
		foreach_extern_meth !act( n ) do
			extern_meths.add( n )
		end

		var fc = new FunctionCompiler( "int (*NitReadyCall( const char* name ))\n(int,native_call_stack_t*,native_call_stack_t*)" )
		#var fc = new FunctionCompiler( "int (*nit_ready_call__{mmodule.name}( const char* name ))\n(int,void**,void**)" )
		# switch between know methods for this module
		if not extern_meths.is_empty then
			fc.exprs.add( "\tif ( strcmp( name, \"{extern_meths[0].mpropdef.cname}\" ) == 0 ) \{\n" )
			fc.exprs.add( "\t\treturn &{extern_meths[0].mpropdef.entry_cname};\n" )

			for i in [1..extern_meths.length[ do
				var m = extern_meths[ i ]
				fc.exprs.add( "\t\}\n" )
				fc.exprs.add( "\telse if ( strcmp( name, \"{m.mpropdef.cname}\" ) == 0 ) \{\n" )
				fc.exprs.add( "\t\treturn &{m.mpropdef.entry_cname};\n" )
			end

			fc.exprs.add( "\t\}\n" )
		end

		# return NULL in case the method is not found
		# this should not happen
		fc.exprs.add( "\treturn (void*)0;\n" )

		ecc.add_exported( fc )
	end
end

redef class MType
	fun compile_ctype : Writer is abstract

	fun to_dlni( name : String ) : String is abstract

	fun from_dlni( name : String ) : String is abstract
end

redef class MClassType
	redef fun compile_ctype
	do
		var w = new Writer

		if not is_cprimitive then
			w.add( "typedef void* {cname};\n" )
		end

		return w
	end

	redef fun to_dlni( name )
	do
		return "({cname}){name}"
	end

	redef fun from_dlni( name )
	do
		return "(Instance){name}"
	end
end

