extends Area2D

## Falling fork projectile — spawned by Nini's cast skill.
## Falls with slight horizontal drift for a rain effect.
## Damages the first enemy it contacts, then disappears.

const FALL_SPEED = 300.0
const DRIFT_SPEED = 60.0  # horizontal movement in facing direction
const DAMAGE_MULTIPLIER = 1
const LIFETIME = 2.0

var _damage: int = 1
var _lifetime_timer: float = 0.0
var _drift_dir: float = 0.0  # +1 right, -1 left, 0 straight

func _ready() -> void:
	_damage = SaveManager.get_attack_power() * DAMAGE_MULTIPLIER
	area_entered.connect(_on_hit_area)
	body_entered.connect(_on_hit_body)

## Called by Nini before adding to tree to set horizontal drift direction.
func set_drift(dir: float) -> void:
	_drift_dir = dir
	# Point the fork tip in the direction of travel (diagonal fall).
	# Fork sprite has tip UP at rotation 0; atan2 + PI/2 rotates tip to match velocity.
	rotation = atan2(FALL_SPEED, DRIFT_SPEED * dir) + PI / 2.0

func _physics_process(delta: float) -> void:
	position.y += FALL_SPEED * delta
	position.x += DRIFT_SPEED * _drift_dir * delta
	_lifetime_timer += delta
	if _lifetime_timer >= LIFETIME:
		queue_free()

func _on_hit_area(area: Area2D) -> void:
	var target = _find_damageable(area)
	if target:
		target.take_damage(_damage, self)
		queue_free()

func _on_hit_body(body: Node) -> void:
	var target = _find_damageable(body)
	if target:
		target.take_damage(_damage, self)
		queue_free()

func _find_damageable(node: Node) -> Node:
	var current = node
	while current and current != get_tree().root:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null
