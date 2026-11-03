extends Area2D

var opening_ending := false

func _unhandled_input(event: InputEvent) -> void:
	if GameState.interaction_busy() or get_tree().paused or opening_ending or not event.is_action_pressed("talk") or event.is_echo():
		return
	if not _player_is_near():
		return
	get_viewport().set_input_as_handled()
	opening_ending = true
	ComputerSound.play_open()
	var error := get_tree().change_scene_to_file("res://scenes/sara_ending.tscn")
	if error != OK:
		opening_ending = false
		push_error("Não foi possível abrir o encerramento da S.A.R.A.: %s" % error)

func _player_is_near() -> bool:
	for body in get_overlapping_bodies():
		if body is CharacterBody2D and body.name == "Player":
			return true
	return false
