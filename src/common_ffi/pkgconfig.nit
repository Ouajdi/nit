
import c

redef class ToolContext
	var pkgconfig_phase: Phase = new PkgconfigPhase(self, null)
end

class PkgconfigPhase
	super Phase

	redef fun process_annotated_node(nmoduledecl, nat)
	do
		# Skip if we are not interested
		if nat.n_atid.n_id.text != "pkgconfig" then return

		# Do some validity checks and print errors if the annotation is used incorrectly
		var modelbuilder = toolcontext.modelbuilder

		if not nmoduledecl isa AModuledecl then
			modelbuilder.error(nat, "Syntax error: only the declaration of modules may use \"pkgconfig\".")
			return
		end

		var args = nat.n_args
		if args.is_empty then
			modelbuilder.error(nat, "Syntax error: \"pkgconfig\" expects at least one argument.")
			return
		end

		var pkgs = new Array[String]
		for arg in args do
			if not arg isa AExprAtArg then
				modelbuilder.error(nat, "Syntax error: \"pkgconfig\" expects its arguments to be the name of the package as String literals.")
				return
			end

			var expr = arg.n_expr
			if not expr isa AStringFormExpr then
				modelbuilder.error(nat, "Syntax error: \"pkgconfig\" expects its arguments to be the name of the package as String literals.")
				return
			end

			var pkg = expr.collect_text
			pkg = pkg.substring(1, pkg.length-2)
			pkgs.add(pkg)
		end

		# retreive module
		var nmodule = nmoduledecl.parent.as(AModule)

		# check availability of pkg-config
		var proc_which = new IProcess("which", "pkg-config")
		proc_which.wait
		var status = proc_which.status
		if status != 0 then
			modelbuilder.error(nat, "Error: program pkg-config not found, make sure it is installed.")
			return
		end

		for pkg in pkgs do
			var proc_exist = new Process("pkg-config", "--exists", pkg)
			proc_exist.wait
			status = proc_exist.status
			if status == 1 then
				modelbuilder.error(nat, "Error: package \"{pkg}\" unknown by pkg-config, make sure the development package is be installed.")
				return
			else if status != 0 then
				modelbuilder.error(nat, "Error: something went wrong calling pkg-config, make sure it is correctly installed.")
				return
			end

			# compiler
			var proc = new IProcess("pkg-config", "--cflags", pkg)
			var compiler_opts = proc.read_all
			nmodule.c_compiler_options = "{nmodule.c_compiler_options} {compiler_opts.replace("\n", " ")}"

			# linker
			proc = new IProcess("pkg-config", "--libs", pkg)
			var linker_opts = proc.read_all
			nmodule.c_linker_options = "{nmodule.c_linker_options} {linker_opts.replace("\n", " ")}"
		end

	end
end
