class_name Portal
extends Area2D

## Portal - teleports Nini to the target scene when player presses UP.
## Uses overlaps_body() polling instead of signals - more reliable when
## instantiated dynamically by YATI as a child of TiledMap.

@export var target_scene: String = ""
@export var target_spawn: String = "left"
@export var is_end_portal: bool = false

# YATI calls set() for custom Tiled properties - catch them here
func _set(property: StringName, value: Variant) -> bool:
	match str(property):
		"target_scene":
			target_scene = str(value)
			return true
		"target_spawn":
			target_spawn = str(value)
			return true
		"is_end_portal":
			is_end_portal = bool(value)
			return true
	return false

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("move_up"):
		return
	# Poll all overlapping bodies directly - no signal dependency
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_enter_portal()
			return

func _enter_portal() -> void:
	if target_scene == "":
		push_warning(name + ": no target_scene set! Was YATI able to set properties?")
		return
	SceneTransition.next_spawn = target_spawn
	SaveManager.update_scene(target_scene)
	if is_end_portal:
		get_tree().change_scene_to_file("res://source/scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(target_scene)
