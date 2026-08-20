extends Node

# Autoload singleton -- persists across scene changes (unlike regular
# nodes, which get destroyed when change_scene_to_file() runs).
var player_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false

func save_player_position(pos: Vector2) -> void:
	player_position = pos
	has_saved_position = true
