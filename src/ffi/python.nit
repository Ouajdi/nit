module python

import ffi_base

import c # solves property inheritance conflict

redef class String
	fun escape_python_for_c_string : String do return replace('\n', "\\n\\\n").replace('"',"\\\"")
end

class PythonWriter
	super Writer

	redef fun add( str ) do return super( str.escape_python_for_c_string )
end

redef class ExternCode
	fun is_python : Bool do return language != null and language_lowered == "python"
end

redef class FFIVisitor
	var python_extern_imports : ExternImportSet = new ExternImportSet
end

redef class MMType
	fun python_format : String
	do
		if local_class.name == once "Int".to_symbol then
			return "i"
		else if local_class.name == once "Float".to_symbol then
			return "f"
		else if local_class.name == once "Char".to_symbol then
			return "c"
		else if local_class.name == once "Bool".to_symbol then
			return "O"
		else if local_class.name == once "NativeString".to_symbol then
			return "s"
		else
			return "l"
		end
	end

	fun check_python_type( v : String ) : String
	do
		if local_class.name == once "Int".to_symbol then
			return "PyInt_Check( {v} )"
		else if local_class.name == once "Float".to_symbol then
			return "PyFloat_Check( {v} )"
		else if local_class.name == once "Char".to_symbol then
			return "PyInt_Check( {v} )"
		else if local_class.name == once "Bool".to_symbol then
			return "PyBool_Check( {v} )"
		else if local_class.name == once "NativeString".to_symbol then
			return "PyString_Check( {v} )"
		else
			return "PyLong_Check( {v} )"
		end
	end

	fun convert_to_python( v : String ) : String
	do
		if local_class.name == once "Bool".to_symbol then
			#return "({v}? Py_True: PyFalse)"
			return "PyBool_FromLong( {v} )"
		else
			return v
		end
	end

	fun ready_from_python( v : String ) : String
	do
		if local_class.name == once "Int".to_symbol then
			return "		long {v};\n" +
				"		PyArg_Parse( r, \"l\", &{v} );"
		else if local_class.name == once "Float".to_symbol then
			return "		float {v};\n" +
				"		PyArg_Parse( r, \"f\", &{v} );"
		else if local_class.name == once "Char".to_symbol then
			return "		long {v};\n" +
				"		PyArg_Parse( r, \"b\", &{v} );"
		else if local_class.name == once "Bool".to_symbol then
			#return "		long {v};\n" +
				#"		PyArg_Parse( r, \"O\", &{v} );" +
			print "Not yet implemented"
			abort
		else if local_class.name == once "NativeString".to_symbol then
			return "		long {v};\n" +
				"		PyArg_Parse( r, \"s\", &{v} );"
		else
			print "Not yet implemented"
			abort
		end
	end
end

redef class MMParam
	fun python_name : String = "nitpy_{name}"
	fun python_name_in_c : String do return "python_{name}"
end

redef class MMMethod
	redef fun accept_ffi_visitor( v )
	do
		if extern_implementation.is_python then
			mmmodule.uses_python = true

			var fc = new ExternFunctionCompiler( self )

			# TODO py_checker

			# user code
			var python_args = new Array[String].with_items( "self" )
			for param in signature.params do python_args.add( param.name.to_s )

			var python_code = new PythonWriter
			python_code.add( "def nitpy_fun( {python_args.join(", ")} ):\n" )
			python_code.add( extern_implementation.code + "\n\n" )

			# code to associate friendly methods to correct types
			if not explicit_imports.is_empty or need_super or not explicit_casts.is_empty then
				python_code.add( "def nitpy_assign_callback_methods( {python_args.join(", ")} ):\n" )

				# explicit callbacks
				for ei in explicit_imports do
					v.python_extern_imports.callbacks.add( ei )

					var meth = ei.method

					for param in signature.params do
						if param.mmtype.local_class.che <= meth.local_class then
							# if meth.local_class.is_extern and meth.local_class.is_python then
							# python_friendly_code.add( "if {param.python_name}.{meth.python_name} != None:\n" )
							python_code.add( "\t{param.name}.{meth.python_name} = {mmmodule.python_name}.{meth.python_to_c_name}\n" )
						end
					end
				end

				if need_super then
					v.python_extern_imports.supers.add( new MMExplicitImport( local_class, self ) )
					#python_code.add( "\t{param.python_name}.{meth.python_name_for_super} = {mmmodule.python_name}.{meth.python_name}\n" ) TODO define a super class?
				end

				for ec in explicit_casts do
					v.python_extern_imports.casts.add( ec )
					#python_code.add( "\t{param.python_name}.{meth.python_name} = {mmmodule.python_name}.{meth.python_name}\n" ) TODO? or ignore
				end

				python_code.add( "\n" )

				python_code.add( "\tf( {python_args.join(", ")} )\n" )
			end

			# escape code to c string
			#var escaped_code = python_code.to_s.escape_python_for_c_string
			#print python_code
			#print python_code.to_s
			#print escaped_code

			fc.exprs.add( "if ( ! Py_IsInitialized() ) Py_Initialize();\n" )
			fc.exprs.add( "if ( !nitpy_module_code_loaded ) nitpy_load_module_code();\n" )
			fc.exprs.add( "PyRun_SimpleString( \"" )
			fc.exprs.append( python_code )
			fc.exprs.add( "\" );\n" )
			fc.exprs.add( "PyObject* module = PyImport_ImportModule( \"__main__\" );\n" )

			# TODO remove HACK
			if not explicit_imports.is_empty or need_super or not explicit_casts.is_empty then
				fc.exprs.add( "PyObject* fun = PyObject_GetAttrString( module, \"nitpy_assign_callback_methods\" );\n" )
			else
				fc.exprs.add( "PyObject* fun = PyObject_GetAttrString( module, \"nitpy_fun\" );\n" )
			end

			# params
			signature.convert_params_from_c_to_python( fc )

			fc.decls.add( "PyObject* r; /* return value from python */\n" )
			fc.exprs.add( "r = PyObject_CallObject( fun, args );\n" )
			fc.exprs.add( "Py_DECREF( args );\n" )
			fc.exprs.add( "if ( r == NULL && PyErr_Occurred() != NULL ) \{\n" )
			fc.exprs.add( "	fprintf( stderr, \",---- Python error -- - -  -\\n\" );\n" )
			fc.exprs.add( "	PyErr_Print();\n" )
			fc.exprs.add( "	abort();\n" )
			fc.exprs.add( "\}\n" )

			if signature.return_type != null then
				#if return_type
				fc.exprs.add( "if (r != NULL) \{\n" )
				fc.exprs.add( "	if ( {signature.return_type.check_python_type( "r" ) } ) \{\n" )
				fc.exprs.add( signature.return_type.ready_from_python( "nitni_r" ) )
				fc.exprs.add( "		return nitni_r;\n" )
				fc.exprs.add( "	\} else \{\n" )
				fc.exprs.add( "		fprintf( stderr, \"Error: method {full_name} returns wrong type, expected {signature.return_type.as(not null)}.\\n\" );\n" )
				fc.exprs.add( "		abort();\n" )
				fc.exprs.add( "	\}\n" )
				fc.exprs.add( "\} else \{\n" )

				if signature.return_type.is_nullable then
					fc.exprs.add( "	return {signature.return_type.friendly_null_getter}();\n" )
				else
					fc.exprs.add( "	fprintf( stderr, \"Error: method {full_name} did not return a value.\\n\" );\n" )
					fc.exprs.add( "	abort();\n" )
				end
				fc.exprs.add( "\}\n" )
			end

			v.add( fc )
		else
			super
		end
	end

	fun python_to_c_name : String do return "nitpy_callback_{cname}"
	fun python_name : String do return name.to_s

	fun compile_python_to_c( v : FFIVisitor )
	do
		# params
		var tuple_format = new Array[String].with_items("l")
		var c_params = new Array[String].with_items("c_recv")
		for param in signature.params do
			tuple_format.add( param.mmtype.python_format )
			c_params.add( param.mmtype.convert_to_python( param.name.to_s ) )
		end

		var fc = new FunctionCompiler( "static PyObject* {python_to_c_name}(PyObject *python_self, PyObject *python_args)" )
		signature.convert_from_python_to_c( fc )
		if signature.return_type != null then
			fc.decls.add( "{signature.return_type.friendly_extern_name} result;\n" )
			fc.exprs.add( "result = {friendly_extern_name(local_class)}( {c_params.join(", ")} ); /* call to Nit */\n" )
			signature.convert_result_from_c_to_python( fc )
			fc.exprs.add( "return python_result;\n" )
		else
			fc.exprs.add( "{friendly_extern_name(local_class)}( {c_params.join(", ")} ); /* call to Nit */\n" )
		end

		v.body_decl.add( "{fc.signature};\n" )
		v.body_custom.append( fc.to_writer )
	end

end

redef class MMSignature
	# declare intermediate variables
	# convert from original to intermediate
	private fun convert_from_python_to_c( fc : FunctionCompiler )
	do
		#fc.decls.add( "PyObject *python_recv;\n" )
		fc.decls.add( "void *c_recv;\n" )
		var tuple_format = new Array[String].with_items("l")
		var tuple_content = new Array[String].with_items("c_recv")
		for param in params do
			tuple_format.add( param.mmtype.python_format )
			tuple_content.add( param.mmtype.convert_to_python( param.name.to_s ) )
			fc.decls.add( "{param.mmtype.friendly_extern_name} {param.python_name_in_c};\n" )
		end

		fc.exprs.add( "PyArg_ParseTuple( python_args, \"{tuple_format}\", {tuple_content.join(", ")} );\n" )
	end

	private fun convert_params_from_c_to_python( fc : FunctionCompiler )
	do
		fc.decls.add( "PyObject *python_recv;\n" )
		var tuple_format = new Array[String].with_items("l")
		var tuple_content = new Array[String].with_items("python_recv")
		for param in params do
			tuple_format.add( param.mmtype.python_format )
			tuple_content.add( param.mmtype.convert_to_python( param.name.to_s ) )
			fc.decls.add( "{param.mmtype.friendly_extern_name} {param.python_name_in_c};\n" )
		end

		fc.exprs.add( "PyObject* args = Py_BuildValue(\"({tuple_format.join("")})\", \n" )
		fc.exprs.add( "	{tuple_content.join(", ")} );\n" )
	end

	private fun convert_result_from_c_to_python( fc : FunctionCompiler )
	do
		fc.decls.add( "PyObject *python_result;\n" )
		fc.exprs.add( "python_result = Py_BuildTuple( \"{return_type.python_format}\", result );\n" )
	end
end

redef class MMModule

	# is a python hybrid if has a python method
	# TODO any other cases
	var uses_python : Bool = false

	var init_module_for_python_fc : FunctionCompiler

	redef init(a,b,c,d)
	do
		super

		init_module_for_python_fc = new FunctionCompiler( "void init_python_module_{name}()" )
	end

	private fun python_name : String do return "nitpy_{name}"

	redef fun accept_ffi_visitor( v )
	do
		super

		if uses_python then
			# ready python-to-c function list
			var python_to_c_list_writer = new Writer
			python_to_c_list_writer.add( "static PyMethodDef NitpyMethods[] = \{\n" )

			for imp in v.python_extern_imports.callbacks do
				var meth = imp.method
				python_to_c_list_writer.add( "	\{\"{meth.python_to_c_name}\", {meth.python_to_c_name}, METH_VARARGS, \"{meth.full_name}\"\},\n" )
				meth.compile_python_to_c( v )
			end

			# complete python-to-c function list
			python_to_c_list_writer.add( "\{NULL, NULL, 0, NULL\} \};\n" )
			python_to_c_list_writer.add( "Py_InitModule( \"{python_name}\", NitpyMethods );\n" )

			#if is_python_hybrid then
				#v.header_custom.add( "#include <python2.6/Python.h>\n" )
			#end
			#if fc != null then
				#v.body_custom.append( python_module_code_fc.to_writer )
			#end

			var blocks = new Array[String]
			for block in extern_code_blocks do if block.is_python then
				blocks.add( block.code )
			end

			var python_code = blocks.join( "\n" )

			# hack to manage indent
			# only used when first line of code is indented
			var protect_indent = false
			for c in python_code do if (once [' ','\t']).has( c ) then
				protect_indent = true
				break
			else if c != '\n' then
				break
			end
			if protect_indent then
				python_code = "if True:\n {python_code}"
			end

			var c_code =
				"static int nitpy_module_code_loaded = 0;\n" +
				"static void nitpy_load_module_code() \{\n" +
				"	if ( ! Py_IsInitialized() ) Py_Initialize();\n" +
				"	PyRun_SimpleString( \"{python_code.escape_python_for_c_string.to_s}\" );\n" +
				"	nitpy_module_code_loaded = 1;\n"
			v.body_custom.add( c_code )
			v.body_custom.append( python_to_c_list_writer )
			v.body_custom.add( "	PyRun_SimpleString( \"import {python_name}\" );\n" )
			v.body_custom.add( "\}\n" )
		end
	end
end

redef class MMLocalClass
	redef fun accept_ffi_visitor( v )
	do
		if extern_type.is_python then
			v.tc.error( null, "Python external types are unsupported, specialize PythonObjecti or other types from the python module instead." )
			# retrieve PythonObject class
			#var python_object_name = once "PythonObject".to_symbol 
			#if v.mmmodule.has_global_class_named( python_object_name ) then
				#var python_object_class = v.mmmodule.class_by_name( python_object_name )
			#else
				#v.tc.error( null, "{name} declares an external type as python, to do so requires to import the python module" )
				#return
			#end
		else
			super
		end
	end
end
