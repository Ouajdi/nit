# FFI concers common between the compiler and interpreter
# Offers services to compile modules using foreign code.
# Mainly allows to wrap foreign code in C function similar
# to the old nitni.
module common_ffi

import parser
import modelbuilder

import nitni

import ffi_base
import c

class FFICompiler
	var modelbuilder : ModelBuilder
	var visitors = new Array[FFIVisitor]

	# Output
	var files = new Array[String]

	init ( mb : ModelBuilder )
	do
		modelbuilder = mb

		# create visitors ( one per language per module)
		visitors.add( new CVisitor )
	end

	fun verify_foreign_code( m : AModule )
	do
		# identify languages
		# detect unsupported languages and confusions
		# associate the language visitor with the code block
		m.visit_foreign_code !visit( n ) do
			var found = false
			for v in visitors do
				var r = v.identify_language( n )
				if r then
					assert not (found and r)
					n.handler = v
					found = true
				end

				assert found else print "Unknown language \"{n.language or else "unspecified"}\""
			end
		end
	end

	fun compile_ffi_wrapper( m : AModule, compdir : String )
	do
		# ready extern code compiler
		var ecc = new ExternCodeCompiler #( "TODO", m )

		# generate code
		for block in m.n_extern_code_blocks do
			block.handler.compile_module_block( block, m, ecc )
		end

		for nclassdef in m.n_classdefs do
			if nclassdef isa AStdClassdef and nclassdef.n_extern_code_block != null then # classes with an extern type
				var c_type = nclassdef.n_extern_code_block.handler.compile_extern_class( nclassdef.n_extern_code_block.as(not null), nclassdef, ecc )
			end
			for npropdef in nclassdef.n_propdefs do
				if npropdef isa AExternMethPropdef and npropdef.n_extern_code_block != null then # extern methods
					npropdef.n_extern_code_block.handler.compile_extern_method( npropdef.n_extern_code_block.as(not null), npropdef, ecc )
				end
			end
		end

		ecc.write_as_impl( m, compdir )
		files = ecc.files # TODO this is a horrible hack :(
	end
end

redef class ExternCodeCompiler
	fun write_as_impl( amodule : AModule, compdir : String )
	do
		var base_name = "{amodule.mmodule.name}._ffi"

		# .h
		var h_file = "{base_name}.h"
		var stream = new OFStream.open( "{compdir}/{h_file}" )
		write_header_to_stream( amodule, stream )
		stream.close

		var c_file = "{base_name}.c"
		stream = new OFStream.open( "{compdir}/{c_file}" )
		write_body_to_stream( amodule, stream )
		stream.close

		files.add( "{compdir}/{c_file}" )
	end

	fun write_header_to_stream( amodule : AModule, stream : OStream )
	do
		# header comments
		var module_info = "/*\n\tExtern implementation of Nit module {amodule.mmodule.name}\n*/\n"

		# header file guard
		var guard = "{amodule.cname.to_s.to_upper}_NIT_H"

		stream.write( module_info )
		stream.write( "#include <{amodule.mmodule.name}._nitni.h>\n\n" )
		stream.write( "#ifndef {guard}\n" )
		stream.write( "#define {guard}\n\n" )

		compile_header_core( stream )

		# header file guard close
		stream.write( "#endif\n" )
	end

	fun write_body_to_stream( amodule : AModule, stream : OStream )
	do
		var module_info = "/*\n\tExtern implementation of Nit module {amodule.mmodule.name}\n*/\n"
		var h_file = "{amodule.mmodule.name}._ffi.h"

		stream.write( module_info )
		stream.write( "#include \"{h_file}\"\n" )

		compile_body_core( stream )
	end
end
