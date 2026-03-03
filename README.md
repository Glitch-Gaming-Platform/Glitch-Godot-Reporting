This README provides a comprehensive guide for integrating your Godot game with the Glitch platform. By using these scripts, you can enable **Aegis Security**, **Player Payouts**, **Cloud Saves**, and **Behavioral Analytics**.

---

# Glitch Godot Integration Guide

This repository contains a set of GDScript files designed to connect your Godot game (PC, Mobile, or Web) to the Glitch platform. 

### What this enables:
1.  **Aegis Handshake:** Verifies that the player has a valid license to play your game.
2.  **Developer Payouts:** Automatically sends "heartbeats" every 60 seconds so you earn **$0.10 per hour** of active playtime.
3.  **Cloud Saves:** Store player progress in the Glitch database so they can resume playing on any device.
4.  **Analytics:** Track player behavior (e.g., "Tutorial Completed") to see where players are dropping off.

---

## 1. Installation

Since this is not a plugin, you simply need to add the files to your project manually:

1.  Create a folder in your Godot project named `res://scripts/glitch/`.
2.  Copy the following four files from this repo into that folder:
    *   `GlitchAegis.gd`
    *   `GlitchAegisAPI.gd`
    *   `GlitchAegisFingerprint.gd`
    *   `GlitchAegisSave.gd`

### Set up the Autoload (Singleton)
To ensure Glitch stays active even when you change scenes, you must set `GlitchAegis.gd` as an **Autoload**:

1.  Open Godot and go to **Project -> Project Settings**.
2.  Click the **Autoload** tab.
3.  Click the folder icon and select `res://scripts/glitch/GlitchAegis.gd`.
4.  Set the "Node Name" to **GlitchAegis**.
5.  Click **Add**.

---

## 2. Configuration

You need two pieces of information from your [Glitch Developer Dashboard](https://www.glitch.fun/dashboard):
*   **Title ID:** The unique ID for your game.
*   **Title Token:** Your secret API key (generated in the "Tokens" tab).

In your `GlitchAegis.gd` script (or via the Inspector if you click on the Autoload in the scene tree), set these variables:

```gdscript
@export var title_id: String = "your-uuid-here"
@export var title_token: String = "your-token-here"
```

---

## 3. Usage

### Starting the Session (The Handshake)
As soon as your game starts (usually in your Main Menu or Splash Screen), you should initialize the session. This verifies the player and starts the payout timer.

```gdscript
func _ready():
    # Connect to the success signal
    GlitchAegis.handshake_successful.connect(_on_glitch_ready)
    GlitchAegis.handshake_failed.connect(_on_glitch_failed)

    # Start the handshake
    GlitchAegis.initialize_session()

func _on_glitch_ready(user_name, license_type):
    print("Welcome, " + user_name + "! You are playing with a " + license_type + " license.")
    # Payouts are now active!

func _on_glitch_failed(reason):
    print("Security check failed: " + reason)
    # Optional: Show a popup and prevent the user from playing
```

### Tracking Player Events (Funnels)
Use this to track milestones. This data appears in your Glitch Dashboard under "Behavioral Funnels."

```gdscript
# Track when a player finishes a level
GlitchAegis.track_event("world_1", "level_complete", {"score": 5000, "time": 120})

# Track when a player opens the shop
GlitchAegis.track_event("ui", "open_shop")
```

### Using Cloud Saves
Cloud saves allow players to keep their progress across different computers or browsers.

**To Save Data:**
```gdscript
var my_data = {
    "level": 5,
    "health": 100,
    "inventory": ["sword", "shield"]
}

# Save to Slot 1
GlitchAegis.upload_save(1, my_data)
```

**To Handle Conflicts:**
If a player played on another device and the cloud has a *newer* save than the local device, the `save_conflict_detected` signal will fire. You can then ask the user which one to keep.

```gdscript
func _ready():
    GlitchAegis.save_conflict_detected.connect(_on_save_conflict)

func _on_save_conflict(data):
    var cloud_version = data["server_version"]
    # Show a UI to the user: "Cloud has version 10, you have version 5. Overwrite?"
```

---

## 4. Important Technical Notes

### The 60-Second Heartbeat
Once `initialize_session()` succeeds, the code automatically starts a timer that pings Glitch every 60 seconds. 
*   **Why?** This is how Glitch calculates your revenue. 
*   **Idle Detection:** If the player is tabbed out or inactive for too long, the Glitch backend will flag the heartbeat as "Idle," and that minute will not be paid out.

### WebGL / HTML5 Support
If you export your game for the Web, this code automatically uses a `JavaScriptBridge` to read the `install_id` from the URL provided by the Glitch launcher. You don't need to do anything extra for Web builds to work.

### Security
**Never share your Title Token.** If your token is leaked, someone could spoof heartbeats for your game. If you suspect a leak, revoke the token in the Glitch Dashboard and generate a new one.

---

## Support
If you run into issues, join our [Discord Community](https://discord.gg/RPYU9KgEmU) or check the [Technical Documentation](https://api.glitch.fun/api/documentation).
