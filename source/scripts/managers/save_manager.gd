extends Node

const SAVE_DIR = "user://"
const SAVE_PREFIX = "save_slot_"
const SAVE_EXT = ".json"
const MAX_SLOTS = 3

# Active slot currently in use
var active_slot: int = -1

# Current game state held in memory
var current_scene: String = "res://source/scenes/levels/level_1_1.tscn"
var position: Vector2 = Vector2(240, -20)
var health: int = 5
var items: Array = []
var equipment: Dictionary = {}
var levels_completed: Array = []

# --- Get save file path for a slot ---
func _slot_path(slot: int) -> String:
	return SAVE_DIR + SAVE_PREFIX + str(slot) + SAVE_EXT

# --- Check if a slot has a save ---
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

# --- Get save summary for slot display ---
func get_slot_summary(slot: int) -> Dictionary:
	if not has_save(slot):
		return { "empty": true }
	var file = FileAccess.open(_slot_path(slot), FileAccess.READ)
	if not file:
		return { "empty": true }
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		return { "empty": true }
	var data = json.get_data()
	return {
		"empty": false,
		"scene": data.get("current_scene", "").get_file().get_basename(),
		"timestamp": data.get("timestamp", "Unknown"),
		"levels_completed": data.get("levels_completed", []).size()
	}

# --- New Game on a slot ---
func new_game(slot: int) -> void:
	active_slot = slot
	current_scene = "res://source/scenes/levels/level_1_1.tscn"
	position = Vector2(240, -32)
	health = 5
	items = []
	equipment = {}
	levels_completed = []
	save()
	get_tree().change_scene_to_file(current_scene)

# --- Save to active slot ---
func save() -> void:
	if active_slot < 0:
		return
	var data = {
		"current_scene": current_scene,
		"position": { "x": position.x, "y": position.y },
		"health": health,
		"items": items,
		"equipment": equipment,
		"levels_completed": levels_completed,
		"timestamp": Time.get_datetime_string_from_system()
	}
	var file = FileAccess.open(_slot_path(active_slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

# --- Load a slot ---
func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false
	var file = FileAccess.open(_slot_path(slot), FileAccess.READ)
	if not file:
		return false
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		return false
	var data = json.get_data()
	active_slot = slot
	current_scene = data.get("current_scene", "res://source/scenes/levels/level_1_1.tscn")
	var pos = data.get("position", { "x": 240, "y": -20 })
	position = Vector2(pos["x"], pos["y"])
	health = data.get("health", 5)
	items = data.get("items", [])
	equipment = data.get("equipment", {})
	levels_completed = data.get("levels_completed", [])
	get_tree().change_scene_to_file(current_scene)
	return true

# --- Delete a slot ---
func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))

# --- Update position (called every frame from Nini) ---
func update_position(new_pos: Vector2) -> void:
	position = new_pos

# --- Update scene (called when entering a new level via portal) ---
func update_scene(scene_path: String) -> void:
	current_scene = scene_path
	save()
