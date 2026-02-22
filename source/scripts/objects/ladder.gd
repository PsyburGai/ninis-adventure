class_name Ladder
extends Area2D

## Ladder/Rope - Nini can climb up/down when overlapping.
## Place in Tiled as class="instance" with res_path pointing to this scene.

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.has_method("enter_ladder"):
		body.enter_ladder()

func _on_body_exited(body: Node) -> void:
	if body.has_method("exit_ladder"):
		body.exit_ladder()
