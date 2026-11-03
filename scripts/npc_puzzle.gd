extends Area2D

@export_file("*.dialogue") var dialogue_path: String

var perto_do_npc := false
var ocupado := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not perto_do_npc or ocupado or get_tree().paused:
		return
	if event.is_action_pressed("talk") and not event.is_echo():
		get_viewport().set_input_as_handled()
		iniciar_dialogo()

func iniciar_dialogo() -> void:
	if ocupado:
		return
	var dialogue := load(dialogue_path) as DialogueResource
	if dialogue == null:
		push_error("Não foi possível carregar o diálogo: %s" % dialogue_path)
		return
	if not GameState.begin_interaction(self):
		return
	ocupado = true
	DialogueManager.show_dialogue_balloon(dialogue, "start")
	await DialogueManager.dialogue_ended
	GameState.end_interaction(self)
	ocupado = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		perto_do_npc = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		perto_do_npc = false
