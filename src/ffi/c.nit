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
end

redef class MMMethod
	redef fun accept_ffi_visitor( v )
	do
		if extern_implementation.is_c then
			var fc = new ExternFunctionCompiler( self )
#			if extern_implementation.location != null then
				fc.decls.add( extern_implementation.location.as_line_pragma ) # TODO move?
#			end
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

redef class MMLocalClass
	 # TODO is this right?
	#redef fun accept_ffi_visitor( v )
	#do
		#if extern_type.is_c then
			 #extern_type.code  # TODO something
		#else
			#super
		#end
	#end
end
