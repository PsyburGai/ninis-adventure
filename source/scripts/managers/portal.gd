extends Area2D

## Portal - teleports Nini to the target scene.
## Properties are set via the Tiled TMX object (target_scene, target_spawn).

@export var target_scene: String = ""
@export var target_spawn: String = "left"   # "left" or "right"
@export var is_end_portal: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if target_scene == "":
		push_warning("Portal has no target_scene set!")
		return

	# Store which spawn to use in the next scene
	SceneTransition.next_spawn = target_spawn

	if is_end_portal:
		# Show a "You Win!" screen or return to main menu
		get_tree().change_scene_to_file("res://source/scenes/levels/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(target_scene)
