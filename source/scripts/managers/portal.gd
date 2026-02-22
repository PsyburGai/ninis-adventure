class_name Portal
extends Area2D

## Portal - teleports Nini to the target scene when player presses UP.

@export var target_scene: String = ""
@export var target_spawn: String = "left"
@export var is_end_portal: bool = false

func _ready() -> void:
	print("Portal READY: ", name, " target_scene=", target_scene, " monitoring=", monitoring)

# YATI calls set() for custom Tiled properties
func _set(property: StringName, value: Variant) -> bool:
	match str(property):
		"target_scene":
			target_scene = str(value)
			print("Portal SET target_scene=", target_scene)
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
	var bodies = get_overlapping_bodies()
	print("Portal UP pressed - overlapping bodies: ", bodies.size())
	for body in bodies:
		print("  body: ", body.name, " groups: ", body.get_groups())
		if body.is_in_group("player"):
			_enter_portal()
			return

func _enter_portal() -> void:
	print("ENTERING PORTAL - target_scene: ", target_scene)
	if target_scene == "":
		push_warning(name + ": no target_scene set!")
		return
	SceneTransition.next_spawn = target_spawn
	SaveManager.update_scene(target_scene)
	if is_end_portal:
		get_tree().change_scene_to_file("res://source/scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(target_scene)
