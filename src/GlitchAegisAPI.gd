# GlitchAegisAPI.gd
extends Node

signal request_completed(result: Dictionary, response_code: int, type: String)

var base_url: String = "https://api.glitch.fun/api/"
var title_id: String = ""
var title_token: String = ""

func setup(p_title_id: String, p_title_token: String):
	title_id = p_title_id
	title_token = p_title_token

func _get_headers() -> Array:
	return [
		"Content-Type: application/json",
		"Accept: application/json",
		"Authorization: Bearer " + title_token
	]

func send_request(path: String, method: int, data: Dictionary = {}, type: String = ""):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_request_completed.bind(http_request, type))
	
	var url = base_url + path
	var query = JSON.stringify(data) if not data.is_empty() else ""
	
	var error = http_request.request(url, _get_headers(), method, query)
	if error != OK:
		push_error("GlitchAegis: An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body, http_node, type):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var response_data = json if json != null else {}
	
	request_completed.emit(response_data, response_code, type)
	http_node.queue_free()
