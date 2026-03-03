# GlitchAegisSave.gd
extends Node

func prepare_save_payload(data: Variant) -> Dictionary:
	var json_string = JSON.stringify(data)
	var bytes = json_string.to_utf8_buffer()
	
	return {
		"payload": Marshalls.raw_to_base64(bytes),
		"checksum": _calculate_checksum(bytes),
		"size_bytes": bytes.size()
	}

func decode_save_payload(base64_payload: String) -> Variant:
	var bytes = Marshalls.base64_to_raw(base64_payload)
	var json_string = bytes.get_string_from_utf8()
	return JSON.parse_string(json_string)

func _calculate_checksum(bytes: PackedByteArray) -> String:
	# Godot 4 hashing
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	var res = ctx.finish()
	return res.hex_encode()
