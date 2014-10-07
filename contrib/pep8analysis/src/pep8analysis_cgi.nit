
import backbone
import ast
import model
import cfg
import flow_analysis
intrude import standard::stream

import nitcorn::cgi

redef class AnalysisManager

	fun run(src: String)
	do
		#sys.suggest_garbage_collection

		var stream = new StringIStream(src)
		var ast = build_ast("web", stream)
		if ast == null then return

		#sys.suggest_garbage_collection

		if failed then return

		# Build program model
		var model = build_model(ast)
		if failed then return

		if model.lines.is_empty then
			fatal_error( ast, "This programs appears empty" )
			return
		end

		#sys.suggest_garbage_collection

		# Create CFG
		var cfg = build_cfg(model)
		if failed then return

		# Run analyses

		#sys.suggest_garbage_collection

		## Reaching defs
		do_reaching_defs_analysis(cfg)

		#sys.suggest_garbage_collection

		## Range
		do_range_analysis(ast, cfg)

		#sys.suggest_garbage_collection

		## Types
		do_types_analysis(ast, cfg)

		#sys.suggest_garbage_collection

		print_notes
		if notes.is_empty then print "Success: Nothing wrong detected"

		var of = new StringOStream
		cfg.print_dot(of, false)
		of.close
		show_graph(of.to_s)

		# Ready next
		reset
		clear
	end

	fun show_graph(content: String) do sys.graph = content
end

class StringIStream
	super BufferedIStream

	init(str: String) do _buffer = new FlatBuffer.from(str)

	redef fun fill_buffer do end_reached = true
	redef var end_reached: Bool = false
end

redef class Sys
	var lines = new Array[String]
	var graph: nullable String = null
end

redef fun print(s) do sys.lines.add s.to_s

var request = cgi_request

if not request.all_args.keys.has("program") then
	var response = new CgiHttpResponse(200) #400)
	response.body = "Bad Request\n"
	#"all: {request.all_args.join(":", ";")}\n"+
		#"get: {request.get_args.join(":", ";")}\n"+
		#"post: {request.post_args.join(":", ";")}\n" + "CONTENT_LENGTH".environ + " _" + sys.aaa + "_\n"

	sys.stdout.write response.to_s + "\n"
	exit 0
end

var program = request.all_args["program"]

manager.run program

var response = new CgiHttpResponse(200)
response.header["Content-type"] = "text/html"

var graph = sys.graph
var json_graph
if graph == null then
	json_graph = "null"
else
	json_graph = "\"{graph}\""
end

var object = """
{
	"results": ["{{{sys.lines.join("\", \"")}}}"],
	"graph": "asdf"
}"""
#{{{json_graph}}}

var content = sys.lines.join("\n")
response.body = object

sys.stdout.write response.to_s + "\n"
