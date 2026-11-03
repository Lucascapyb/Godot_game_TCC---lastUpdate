extends Area2D

@onready var puzzle_ui: CanvasLayer = get_parent().get_node("Tela_Cracha")

var player_in_range := false


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false


func _process(_delta: float) -> void:
	if player_in_range and not GameState.interaction_busy() and not get_tree().paused and Input.is_action_just_pressed("talk"):
		abrir_puzzle()


func abrir_puzzle() -> void:
	get_tree().paused = true
	puzzle_ui.show()
