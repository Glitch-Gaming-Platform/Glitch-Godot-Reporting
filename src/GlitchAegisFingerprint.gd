# GlitchAegisFingerprint.gd
extends Node

func get_components() -> Dictionary:
	var components = {
		"device": {
			"model": OS.get_model_name(),
			"type": _get_device_type(),
			"manufacturer": "unknown" # Godot doesn't expose manufacturer directly on all platforms
		},
		"os": {
			"name": OS.get_name(),
			"version": OS.get_version()
		},
		"display": {
			"resolution": str(DisplayServer.window_get_size().x) + "x" + str(DisplayServer.window_get_size().y),
			"density": DisplayServer.screen_get_dpi()
		},
		"hardware": {
			"cpu": OS.get_processor_name(),
			"cores": OS.get_processor_count(),
			"memory": OS.get_static_memory_usage() / 1024 / 1024 # MB
		},
		"environment": {
			"language": OS.get_locale(),
			"timezone": Time.get_time_zone_from_system()["name"]
		},
		"keyboard_layout": get_keyboard_layout_map()
	}
	return components

func _get_device_type() -> String:
	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return "desktop"
		"Android", "iOS":
			return "mobile"
		"Web":
			return "web"
		_:
			return "console"

func get_keyboard_layout_map() -> Dictionary:
	var layout = {}
	var keys_to_map = [
		"KeyQ", "KeyW", "KeyE", "KeyR", "KeyT", "KeyY", "KeyU", "KeyI", "KeyO", "KeyP",
		"KeyA", "KeyS", "KeyD", "KeyF", "KeyG", "KeyH", "KeyJ", "KeyK", "KeyL",
		"KeyZ", "KeyX", "KeyC", "KeyV", "KeyB", "KeyN", "KeyM",
		"Backquote", "Digit1", "Digit2", "Digit3", "Digit4", "Digit5", "Digit6", "Digit7", "Digit8", "Digit9", "Digit0",
		"Minus", "Equal", "BracketLeft", "BracketRight", "Backslash",
		"Semicolon", "Quote", "Comma", "Period", "Slash"
	]
	
	for key_code_name in keys_to_map:
		# We use OS.get_keycode_string to find what character is mapped to the physical key
		var keycode = OS.find_keycode_from_string(key_code_name.replace("Key", ""))
		layout[key_code_name] = OS.get_keycode_string(keycode).to_lower()
		
	return layout

func get_install_id_from_url() -> String:
	if OS.has_feature("web"):
		var id = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('install_id')")
		return id if id != null else ""
	return ""
