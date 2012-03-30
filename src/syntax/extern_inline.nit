intrude import mmbuilder
import syntax_base
import primitive_info

# Extern code segment
class ExternCode
	var language : nullable String
	var code : String
end

redef class MMModule
	# extern code blocks in module
	var extern_code_blocks : Set[ExternCode] = new HashSet[ExternCode]
end

redef class MMLocalClass
	# extern equivalent of class
	var extern_type : nullable ExternCode = null

	# whare was the extern type explicitly declared
	private var extern_type_origin_cache : nullable MMLocalClass = null

	# extern type of an extern class
	private var extern_type_cache : nullable String = null

	fun compute_extern_type
	do
		if extern_type_cache != null then return # already computed
		if not global.is_extern then abort

		if name == once "Pointer".to_symbol then
			extern_type_cache = "void*"
			extern_type_origin_cache = self
			return
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
			for c in extern_types do stderr.write( "{c.extern_type} from {c}\n" )
			exit(1)
		else if extern_types.length == 1 then
			var source = extern_types.first
			extern_type_cache = source.extern_type
			extern_type_origin_cache = source
		else
			# Extern class has unknown extern type. This should never happen.
			abort
		end
	end

	redef fun extern_type : String
	do
		compute_extern_type
		return extern_type_cache.as(not null)
	end

	fun extern_type_origin : MMLocalClass
	do
		compute_extern_type
		return extern_type_origin_cache.as(not null)
	end

	private fun extern_type=( v : nullable String )
	do
		extern_type_cache = v
		extern_type_origin_cache = self
	end
end

redef class MMMethod
	# extern code bodu of extern method
	var extern_implementation : nullable ExternCode = null
end

redef class TExternCodeSegment
	# removes `{ and `} and return code of interest
	fun code : String do
		return text.substring( 2, text.length-4 )
	end
end

redef class AExternCodeBlock
	fun to_extern_code : ExternCode
	do
		var language
		if n_in_language == null then
			language = null
		else
			var text = n_in_language.n_string.text
			language = text.substring( 1, text.length-2 )
		end
		return new ExternCode( language, n_extern_code_segment.code )
	end
end

# Extern method
redef class AExternPropdef
	redef fun accept_property_verifier(v)
	do
		super

		var n_extern_code_block = self.n_extern_code_block
		if n_extern_code_block != null then
			if not method.is_extern then
				v.error( n_extern_code_block,
					"Cannot implement the non extern method {method.full_name} with extern code" )
			else
				method.extern_implementation = n_extern_code_block.to_extern_code
			end
		end
	end
end

# Extern type of extern class
redef class AStdClassdef
	redef fun accept_property_verifier(v)
	do
		super

		var extern_code_block = self.n_extern_code_block
		if extern_code_block != null then
			if not local_class.global.is_extern then
				v.error( extern_code_block,
					"Cannot define an extern equivalent in the non extern class {local_class.name}" )
			else
				local_class.extern_type = extern_code_block.to_extern_code
			end
		end
	end
end

redef class MMSrcModule
	# Syntax analysis and MM construction for the module
	# Require that supermodules are processed
	redef fun do_mmbuilder(tc: ToolContext)
	do
		super

		# extern code blocks
		for n_extern_code_block in node.n_extern_code_blocks do
			extern_code_blocks.add( n_extern_code_block.to_extern_code )
		end
	end
end
