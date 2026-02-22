class_name Portal
extends Area2D

## Portal - teleports Nini to the target scene when player presses UP.
## Properties are set by YATI via set() - do NOT use @export or _set() is bypassed.

var target_scene: String = ""
var target_spawn: String = "left"
var is_end_portal: bool = false

func _ready() -> void:
	print("Portal READY: ", name, " target_scene='", target_scene, "'")

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("move_up"):
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_enter_portal()
			return

func _enter_portal() -> void:
	if target_scene == "":
		push_warning(name + ": no target_scene set!")
		return
	print("Transitioning to: ", target_scene)
	SceneTransition.next_spawn = target_spawn
	SaveManager.update_scene(target_scene)
	if is_end_portal:
		get_tree().change_scene_to_file("res://source/scenes/ui/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(target_scene)
