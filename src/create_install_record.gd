# Godot GDScript
extends Node

var base_url = "https://api.glitch.fun/api/"
var auth_token = "YOUR_AUTH_TOKEN"

func create_install_record(title_id: String, user_install_id: String, platform: String):
    var url = base_url + "titles/" + title_id + "/installs"
    var json_body = {"user_install_id": user_install_id, "platform": platform}
    
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + auth_token
    ]
    var request = HTTPRequest.new()
    add_child(request)
    request.request(url, headers, true, HTTPClient.METHOD_POST, to_json(json_body))

