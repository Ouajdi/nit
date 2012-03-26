import ffi_base

redef class FFIVisitor
	## header
	# comments and native interface imports
	var header_c_base : Writer = new Writer

	# custom C header code or generated for other languages
	var header_custom : Writer = new Writer

	# types of extern classes and friendly types
	var header_c_types : Writer = new Writer

	# implementation declaration for extern methods
	var header_decl : Writer = new Writer

	## body
	# comments, imports
	var body_c_base : Writer = new Writer

	var body_decl : Writer = new Writer # TODO add to compile

	# custome code and generated for ffi
	var body_custom : Writer = new Writer

	# implementation body of extern methods
	var body_impl : Writer = new Writer

	fun compile( cprogram : CProgram )
	do
		var compdir = tc.compdir.as(not null)
		var base_name = "{mmmodule.cname}._ffi"
		var c_file = "{base_name}.c"
		var h_file = "{base_name}.h"

		#cprogram.files.add( "{compdir}/{c_file}" ) TODO

		# header comments
		var module_info = "/*\n\tExtern implementation of Nit module {mmmodule.name}\n*/\n"

		# header file guard
		var guard = "{mmmodule.cname.to_s.to_upper}_NIT_H"

		# .h
		var stream = new OFStream.open( "{compdir}/{h_file}" )
		stream.write( module_info )
		stream.write( "#include <{mmmodule.name}._nitni.h>\n\n" )
		stream.write( "#ifndef {guard}\n" )
		stream.write( "#define {guard}\n\n" )

		header_c_base.write_to_stream( stream )
		header_custom.write_to_stream( stream )

		# import autogenerated frontier header file
		header_c_types.write_to_stream( stream )
		header_decl.write_to_stream( stream )

		# header file guard close
		stream.write( "#endif\n" )

		stream.close

		# .c
		stream = new OFStream.open( "{compdir}/{c_file}" )
		stream.write( module_info )
		stream.write( "#include \"{h_file}\"\n" )
		body_c_base.write_to_stream( stream )
		body_decl.write_to_stream( stream )
		body_custom.write_to_stream( stream )
		body_impl.write_to_stream( stream )
		stream.close
	end

	fun add( efc : FunctionCompiler )
	do
		efc.integrate_to( self )
	end
end

redef class FunctionCompiler
	private fun integrate_to( v : FFIVisitor )
	do
		v.body_decl.add( "{signature};\n" )
		v.body_impl.append( to_writer )
	end
end

class ExternFunctionCompiler
	super FunctionCompiler

	var method : MMMethod

	init ( m : MMMethod )
	do
		method = m
		super( method.impl_csignature ) # TODO bring this method back here
	end

	redef fun integrate_to( v : FFIVisitor )
	do
		v.header_decl.add( "{signature};\n" )
		v.body_impl.append( to_writer )
	end
end
