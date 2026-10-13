extends Area2D


var perto_do_npc := false 

func _process(delta: float) -> void:
	if perto_do_npc and Input.is_action_just_pressed("talk"):
		DialogueManager.show_dialogue_balloon(load("res://Dialogos/DialogoPorta.dialogue"), "start")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("Pressione 'E' para falar")
		perto_do_npc = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		perto_do_npc = false
