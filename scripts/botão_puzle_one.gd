extends Area2D

@onready var puzzle_ui: CanvasLayer = get_parent().get_node("puzleOne")

var player_in_range := false


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false


func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("talk"):
		abrir_puzzle()


func abrir_puzzle() -> void:
	if puzzle_ui.visible:
		return
	ComputerSound.play_open()
	get_tree().paused = true
	puzzle_ui.show()
