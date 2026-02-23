class_name Ladder
extends Area2D

## Ladder/Rope - Nini can climb up/down when overlapping.
## Place in Tiled as class="instance" with res_path pointing to this scene.

## Extra pixels added above the visual top of the ladder so the player
## can climb fully past a platform before exiting the ladder area.
const OVERSHOOT_TOP = 8.0

## Set to true to draw the collision area at runtime for debugging.
const DEBUG_DRAW = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_extend_collision_upward()

func _extend_collision_upward() -> void:
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is RectangleShape2D:
		# Duplicate so we don't modify the shared resource
		var rect: RectangleShape2D = shape_node.shape.duplicate()
		rect.size.y += OVERSHOOT_TOP
		shape_node.shape = rect
		# Shift upward so only the top extends, bottom stays the same
		shape_node.position.y -= OVERSHOOT_TOP / 2.0

func _draw() -> void:
	if not DEBUG_DRAW:
		return
	var shape_node = get_node_or_null("CollisionShape2D")
	if shape_node and shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape_node.shape
		var rect = Rect2(
			shape_node.position - rect_shape.size / 2.0,
			rect_shape.size
		)
		draw_rect(rect, Color(0, 1, 0, 0.50), true) # Green fill
		draw_rect(rect, Color(0, 1, 0, 0.8), false) # Green outline

func _on_body_entered(body: Node) -> void:
	if body.has_method("enter_ladder"):
		body.enter_ladder()

func _on_body_exited(body: Node) -> void:
	if body.has_method("exit_ladder"):
		body.exit_ladder()
