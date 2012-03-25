import primitive_info
intrude import extern_inline

redef class MMLocalClass
	# where was the extern type explicitly declared
	private var extern_type_origin_cache : nullable MMLocalClass = null

	# extern type of an extern class
	private var extern_type_cache : nullable ExternCode = null

	redef fun extern_type
	do
		if extern_type_cache != null then return extern_type_cache
		if not global.is_extern then abort

		if name == once "Pointer".to_symbol then
			extern_type_cache = new ExternCode( "C", "void*" )
			extern_type_origin_cache = self
			return extern_type_cache
		end

		# find all extern types in direct parents
		var extern_types = new HashSet[MMLocalClass]
		for c in cshe.direct_greaters do
			if c.global.is_extern then
				extern_types.add( c.extern_type_origin )
			end
		end

		if extern_types.length > 1 then
			stderr.write("Error: Extern class {mmmodule}::{name} has ambiguous extern type, found in super classes: \n")
			for c in extern_types do stderr.write( "{c.extern_type.code} from {c}\n" )
			exit(1)
		else if extern_types.length == 1 then
			var source = extern_types.first
			extern_type_cache = source.extern_type
			extern_type_origin_cache = source
		else
			# Extern class has unknown extern type. This should never happen.
			abort
		end

		return extern_type_cache
	end

	redef fun extern_c_type : String
	do
		return extern_type.code
	end

	fun extern_type_origin : MMLocalClass
	do
		extern_type
		return extern_type_origin_cache.as(not null)
	end

	redef fun extern_type=( v )
	do
		extern_type_cache = v
		extern_type_origin_cache = self
	end
end
