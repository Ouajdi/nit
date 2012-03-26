import c

redef class MMSrcModule
	redef fun compile_separate_module(cprogram: CProgram)
	do
		super

		if is_extern_hybrid then
			var visitor = new FFIVisitor( cprogram.program.tc, self )
			# TODO use cprogram to add generated files?

			# actually compile stub
			accept_ffi_visitor( visitor )

			# write to file
			if uses_ffi then
				visitor.compile( cprogram )
			end
		end
	end
end

redef class MMMethod
	super FFIVisited

	fun to_delete_TODO( v : FFIVisitor ) # TODO
	do
		# documentation to guide the user
		var helper_documentation = new Writer
		helper_documentation.add( "C implementation of {full_name}" )
		# TODO add nitdoc comment

		v.body_impl.add( "\n/*\n" )
		v.body_impl.append( helper_documentation )
		v.body_impl.add( "\n*/\n" )

		### extern method implementation
		v.header_decl.add( "{impl_csignature};\n" )

		v.body_impl.add( "{impl_csignature} \{" )

		# adds extern inline code if any
		if extern_implementation != null then # TODO should this check be made by language modules
			var impl = "TOREMOVE"
			if impl == null then
				var language = extern_implementation.language
				if language != null then
					print "Warning: language \"{language}\" used to implement {full_name} is unknown."
				else
					print "Warning: please specify a language to implement {full_name}."
				end
			else
				v.body_impl.add( impl )
			end
		end

		v.body_impl.add( "\}\n" )
		### end of implementation
	end
end

redef class MMLocalClass
	super FFIVisited

	redef fun accept_ffi_visitor( v: FFIVisitor )
	do	# TODO remove
		#v.header_decl.add( "#define {get_type.friendly_extern_name} {extern_c_type}\n" )
	end
end
