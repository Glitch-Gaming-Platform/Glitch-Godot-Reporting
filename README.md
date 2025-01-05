# Godot (GDScript) - GlitchFun API Integration

This repository provides a **Godot GDScript** snippet to send POST requests to the GlitchFun API (`https://api.glitch.fun/api/`) to track game installs.

## Overview

- **File Name**: `create_install_record.gd`
- **Location**: `/src/create_install_record.gd`
- **Engine**: Godot (GDScript)

It uses `HTTPRequest` and `HTTPClient.METHOD_POST` to communicate with the Laravel backend.

## Installation

1. Copy or clone this repository into your Godot project.
2. Place `create_install_record.gd` in a suitable folder (e.g. `res://Scripts/`).
3. Ensure you have a **`HTTPRequest`** node in your scene, or dynamically create one in code.

## Usage

1. In your Godot scene, attach or reference `create_install_record.gd`.  
2. Make sure you set your **`auth_token`** to a valid Bearer token from your server’s auth system.
3. Call `create_install_record("TITLE_UUID", "UNIQUE_USER_ID", "apple")` or similar.

**Example**:

```gdscript
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
```

In your game logic, call:

```gdscript
create_install_record("abc123", "my-device-xyz", "android")
```

### Contributing
Please open an issue or PR for improvements.

### License
This sample is under the MIT License.
