extends Node

## Reads enemy spawn points from Tiled object groups and instantiates enemies.
## Attach to a level scene. Finds spawn markers under the TiledMap node.
## NOTE: Level 1-1 uses direct CakeMonster instances instead of this spawner.

const CAKE_MONSTER = preload("res://enemies/cake_monster/cake_monster.tscn")
const SCONE_MONSTER = preload("res://enemies/scone_monster/scone_monster.tscn")

@export var tiled_map_path: NodePath = "../TiledMap"

func _ready() -> void:
	# Wait for the Tiled map to be fully imported and ready
	await get_tree().process_frame
	_spawn_enemies()

func _spawn_enemies() -> void:
	var tiled_map = get_node_or_null(tiled_map_path)
	if not tiled_map:
		return

	# Search for object group nodes that contain spawn points
	_find_spawn_groups(tiled_map)

func _find_spawn_groups(node: Node) -> void:
	# YATI imports object groups as Node2D with point objects as children
	for child in node.get_children():
		var name_lower = child.name.to_lower()
		if "enemy_spawn" in name_lower:
			var enemy_scene = _get_enemy_scene(name_lower)
			if enemy_scene:
				_spawn_from_group(child, enemy_scene)
		else:
			# Recurse into children
			_find_spawn_groups(child)

func _get_enemy_scene(group_name: String) -> PackedScene:
	if "scone" in group_name:
		return SCONE_MONSTER
	# Default all spawn points to cake monster
	return CAKE_MONSTER

func _spawn_from_group(group: Node, enemy_scene: PackedScene) -> void:
	for marker in group.get_children():
		var enemy = enemy_scene.instantiate()
		# Spawn at the marker's global position
		add_child(enemy)
		enemy.global_position = marker.global_position
