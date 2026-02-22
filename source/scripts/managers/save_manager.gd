extends Node

const SAVE_PATH = "user://save.json"

# Current game state held in memory
var current_scene: String = "res://source/scenes/levels/level_1_1.tscn"
var position: Vector2 = Vector2(16, 0)  # Far left of level_1-1
var health: int = 5
var items: Array = []
var equipment: Dictionary = {}
var levels_completed: Array = []

# --- New Game ---
func new_game() -> void:
	current_scene = "res://source/scenes/levels/level_1_1.tscn"
	position = Vector2(16, 0)
	health = 5
	items = []
	equipment = {}
	levels_completed = []
	save()
	get_tree().change_scene_to_file(current_scene)

# --- Save ---
func save() -> void:
	var data = {
		"current_scene": current_scene,
		"position": { "x": position.x, "y": position.y },
		"health": health,
		"items": items,
		"equipment": equipment,
		"levels_completed": levels_completed
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

# --- Load ---
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json = JSON.new()
	var err = json.parse(file.file_get_as_string())
	file.close()
	if err != OK:
		return false
	var data = json.get_data()
	current_scene = data.get("current_scene", "res://source/scenes/levels/level_1_1.tscn")
	var pos = data.get("position", { "x": 16, "y": 0 })
	position = Vector2(pos["x"], pos["y"])
	health = data.get("health", 5)
	items = data.get("items", [])
	equipment = data.get("equipment", {})
	levels_completed = data.get("levels_completed", [])
	get_tree().change_scene_to_file(current_scene)
	return true

# --- Has Save ---
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# --- Update position (call this every few seconds or at checkpoints) ---
func update_position(new_pos: Vector2) -> void:
	position = new_pos

# --- Update scene (call when entering a new level) ---
func update_scene(scene_path: String) -> void:
	current_scene = scene_path
	save()
