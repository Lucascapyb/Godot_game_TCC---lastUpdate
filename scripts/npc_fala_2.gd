extends Area2D

var perto_do_npc := false
var ocupado := false

var som_telefone := AudioStreamPlayer.new()

func _ready() -> void:
	som_telefone.stream = load("res://assets/audio/sfx/phone_ring.mp3")
	som_telefone.volume_db = -10.0  # ajuste aqui: 0 = original, valores negativos = mais baixo
	add_child(som_telefone)

func _process(delta: float) -> void:
	if perto_do_npc and not ocupado and Input.is_action_just_pressed("talk"):
		iniciar_dialogo()

func iniciar_dialogo() -> void:
	ocupado = true

	som_telefone.play()
	await som_telefone.finished

	DialogueManager.show_dialogue_balloon(load("res://Dialogos/dialogo_NPC_2.dialogue"), "start")
	await DialogueManager.dialogue_ended

	ocupado = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("Pressione 'E' para falar")
		perto_do_npc = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		perto_do_npc = false
