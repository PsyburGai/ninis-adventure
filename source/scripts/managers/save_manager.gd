extends Node

const SAVE_DIR = "user://"
const SAVE_PREFIX = "save_slot_"
const SAVE_EXT = ".json"
const MAX_SLOTS = 3
const MAX_LEVEL: int = 20

# ── Level 1–20 scaling tables (index 0 = level 1) ────────────────────────────
const XP_TABLE: Array[int]  = [30, 45, 65, 90, 120, 155, 195, 240, 290, 345, 405, 470, 540, 615, 695, 780, 870, 965, 1065, 9999]
const HP_TABLE: Array[int]  = [50, 58, 66, 74, 82, 90, 98, 106, 114, 122, 130, 138, 146, 154, 162, 170, 178, 186, 194, 200]
const MP_TABLE: Array[int]  = [20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56, 59, 62, 65, 68, 71, 74, 80]
const ATK_TABLE: Array[int] = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 50]

# Active slot currently in use
var active_slot: int = -1

# Current game state held in memory
var current_scene: String = "res://source/scenes/levels/level_1_1.tscn"
var position: Vector2 = Vector2(240, 384)
var health: int = 50
var max_health: int = 50
var mp: int = 20
var max_mp: int = 20
var xp: int = 0
var level: int = 1
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

# ── Level / stat helpers ──────────────────────────────────────────────────────

## XP needed to reach the next level (for the current level).
func xp_for_next_level() -> int:
	return XP_TABLE[clampi(level - 1, 0, MAX_LEVEL - 1)]

## Attack power derived from current level.
func get_attack_power() -> int:
	return ATK_TABLE[clampi(level - 1, 0, MAX_LEVEL - 1)]

## Set max_health / max_mp from the tables for the current level.
func apply_level_stats() -> void:
	var idx = clampi(level - 1, 0, MAX_LEVEL - 1)
	max_health = HP_TABLE[idx]
	max_mp = MP_TABLE[idx]

## Check if the player has enough XP to level up.  Returns true if at least
## one level was gained.  Handles multi-level-ups (e.g. boss XP overflow).
func try_level_up() -> bool:
	if level >= MAX_LEVEL:
		return false
	var leveled = false
	while level < MAX_LEVEL and xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		level += 1
		apply_level_stats()
		health = max_health
		mp = max_mp
		leveled = true
	return leveled

# --- New Game on a slot ---
func new_game(slot: int) -> void:
	active_slot = slot
	current_scene = "res://source/scenes/levels/level_1_1.tscn"
	position = Vector2(240, 384)
	xp = 0
	level = 1
	apply_level_stats()
	health = max_health
	mp = max_mp
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
		"max_health": max_health,
		"mp": mp,
		"max_mp": max_mp,
		"xp": xp,
		"level": level,
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
	var pos = data.get("position", { "x": 240, "y": 384 })
	position = Vector2(pos["x"], pos["y"])
	health = data.get("health", 50)
	max_health = data.get("max_health", 50)
	mp = data.get("mp", 20)
	max_mp = data.get("max_mp", 20)
	xp = data.get("xp", 0)
	level = data.get("level", 1)
	items = data.get("items", [])
	equipment = data.get("equipment", {})
	levels_completed = data.get("levels_completed", [])
	apply_level_stats()
	# Clamp health/mp to table values (guards against stale saves)
	health = clampi(health, 0, max_health)
	mp = clampi(mp, 0, max_mp)
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
