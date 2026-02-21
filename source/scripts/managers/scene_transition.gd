extends Node

## SceneTransition - Autoload singleton.
## Carries portal spawn information between scene changes.
## Register this in Godot: Project > Project Settings > Autoload
##   Name: SceneTransition
##   Path: res://source/scripts/managers/scene_transition.gd

var next_spawn: String = "left"   # "left" or "right"
