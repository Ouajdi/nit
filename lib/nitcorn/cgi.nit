intrude import http_request
intrude import http_response

redef class HttpRequest
	# TODO
	var server_software: nullable String = null
	var server_name: nullable String = null
	var gateway_interface: nullable String = null
end

fun cgi_request: HttpRequest
do
	var request = new HttpRequest

	# HTTP protocol version
	request.http_version = "SERVER_PROTOCOL".environ

	# Method of this request (GET or POST)
	request.method = "REQUEST_METHOD".environ

	# The host targetter by this request (usually the server)
	request.host = "SERVER_ADDR".environ

	# The resource requested by the client (only the page, not the `query_string`)
	request.uri = "SCRIPT_NAME".environ

	# The string following `?` in the requested URL
	request.query_string = "QUERY_STRING".environ

	# The full URL requested by the client (including the `query_string`)
	request.url = "http://" + request.host / "REQUEST_URI".environ

	# GET
	request.fill_get_from_string(request.query_string)

	# POST
	#var content_length_s = "CONTENT_LENGTH".environ
	if request.method == "POST" then #content_length_s.is_numeric then
		#var content_length = content_length_s.to_i
		var content = sys.stdin.read_all#(content_length)
		request.fill_post_from_string(content)
	end

	# HEADERS
	# The header of this request
	#for header_key in ["HTTP_COOKIE"] do
	#var val = header_key.environ
	#if val.length > 0 then
	#request.header[header_key] = val
	#end
	#end

	return request
end

class CgiHttpResponse
	super HttpResponse

	#TODO var location = ""

	redef fun to_s: String
	do
		finalize

		var buf = new FlatBuffer

		if not header.keys.has("Status") then header["Status" ] = "{status_code} {status_message or else ""}"

		for key, value in header do
			buf.append("{key}: {value}\r\n")
		end
		buf.append("\r\n{body}")
		return buf.to_s
	end
end
