# GlitchAegis.gd (Singleton)
extends Node

# Signals for the developer to hook into
signal handshake_successful(user_name: String, license_type: String)
signal handshake_failed(reason: String)
signal save_conflict_detected(conflict_data: Dictionary)
signal save_synced(slot_index: int, version: int)

@onready var API = preload("res://scripts/glitch/GlitchAegisAPI.gd").new()
@onready var Fingerprint = preload("res://scripts/glitch/GlitchAegisFingerprint.gd").new()
@onready var SaveSystem = preload("res://scripts/glitch/GlitchAegisSave.gd").new()

var current_install_id: String = ""
var current_version: int = 0
var is_active: bool = false

# Configuration - Set these in the Inspector or via code
@export var title_id: String = "YOUR_TITLE_ID"
@export var title_token: String = "YOUR_TITLE_TOKEN"
@export var heartbeat_interval: float = 60.0

func _ready():
	add_child(API)
	API.setup(title_id, title_token)
	API.request_completed.connect(_on_api_response)

func initialize_session():
	# 1. Try to get install_id from URL (Web) or Command Line (PC)
	current_install_id = Fingerprint.get_install_id_from_url()
	
	if current_install_id == "":
		push_warning("GlitchAegis: No Install ID found. Payouts and Cloud Saves will be disabled.")
		handshake_failed.emit("NO_INSTALL_ID")
		return

	# 2. Perform the Security Handshake
	var path = "titles/%s/installs/%s/validate" % [title_id, current_install_id]
	API.send_request(path, HTTPClient.METHOD_POST, {}, "handshake")

func start_payout_heartbeat():
	is_active = true
	_send_heartbeat()
	var timer = Timer.new()
	timer.wait_time = heartbeat_interval
	timer.autostart = true
	timer.timeout.connect(_send_heartbeat)
	add_child(timer)

func _send_heartbeat():
	if not is_active: return
	
	var data = {
		"user_install_id": current_install_id,
		"platform": OS.get_name().to_lower(),
		"game_version": ProjectSettings.get_setting("application/config/version"),
		"fingerprint_components": Fingerprint.get_components()
	}
	
	API.send_request("titles/%s/installs" % title_id, HTTPClient.METHOD_POST, data, "heartbeat")

# --- Behavioral Events ---

func track_event(step_key: String, action_key: String = "", metadata: Dictionary = {}):
	var data = {
		"game_install_id": current_install_id,
		"step_key": step_key,
		"action_key": action_key,
		"metadata": metadata,
		"event_timestamp": Time.get_datetime_string_from_system(true)
	}
	API.send_request("titles/%s/events" % title_id, HTTPClient.METHOD_POST, data, "event")

# --- Cloud Save ---

func upload_save(slot_index: int, save_data: Dictionary, save_type: String = "manual"):
	var payload = SaveSystem.prepare_save_payload(save_data)
	payload["slot_index"] = slot_index
	payload["save_type"] = save_type
	payload["base_version"] = current_version
	payload["client_timestamp"] = Time.get_datetime_string_from_system(true)
	
	var path = "titles/%s/installs/%s/saves" % [title_id, current_install_id]
	API.send_request(path, HTTPClient.METHOD_POST, payload, "save_upload")

func resolve_conflict(save_id: String, conflict_id: String, choice: String):
	# choice: "keep_server" or "use_client"
	var path = "titles/%s/installs/%s/saves/%s/resolve" % [title_id, current_install_id, save_id]
	var data = {"conflict_id": conflict_id, "choice": choice}
	API.send_request(path, HTTPClient.METHOD_POST, data, "save_resolve")

# --- Internal Response Handler ---

func _on_api_response(data: Dictionary, code: int, type: String):
	match type:
		"handshake":
			if code == 200 and data.get("valid"):
				handshake_successful.emit(data.get("user_name"), data.get("license_type"))
				start_payout_heartbeat()
			else:
				handshake_failed.emit(data.get("reason", "UNKNOWN_ERROR"))
				
		"save_upload":
			if code == 201:
				current_version = data.get("data").get("version")
				save_synced.emit(data.get("data").get("slot_index"), current_version)
			elif code == 409:
				save_conflict_detected.emit(data)
				
		"heartbeat":
			if code == 403:
				is_active = false
				handshake_failed.emit("SESSION_EXPIRED")
