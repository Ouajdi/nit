module java

import ffi_base

import python # only for linearisation

redef class ExternCode
	fun is_java : Bool do return "java" == language_lowered
end

redef class MMMethod
	redef fun accept_ffi_visitor( v )
	do
		if extern_implementation.is_java then
			#mmmodule.add_java_module_code
			#mmmodule.add_java_embedding_code

			#var java_code = "void {friendly_extern_name}() \{\n" +
				#extern_implementation.code +
				#"\}"
			#v.java_writer.add( java_code )
		else
			super
		end
	end
end

redef class MMModule
	var java_writer : Writer = new Writer

	var added_java_embedding_code : Bool = false
	fun add_java_embedding_code
	do
		if added_java_embedding_code then return

		var embedding_code = "#include <java.h>\n"
		
		added_java_embedding_code = true
	end

	var added_java_module_code : Bool = false
	fun add_java_module_code
	do
		if added_java_module_code then return

		var blocks = new Array[String]
		for block in extern_code_blocks do if block.is_java then
			blocks.add( block.code )
		end

		java_writer.add( blocks.join( "\n" ) )

		added_java_module_code = true
	end
end
