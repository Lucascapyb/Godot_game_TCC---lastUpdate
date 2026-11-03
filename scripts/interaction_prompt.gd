extends CanvasLayer

var dialogue_active := false

@onready var prompt: Label = $Label

func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _process(_delta: float) -> void:
	prompt.visible = false
	if get_tree().paused or GameState.interaction_busy():
		return
	var nearby_player := false
	for node in get_tree().get_nodes_in_group("interactables"):
		if not node is Area2D:
			continue
		# Busy NPCs include the phone sound before the dialogue opens.
		if node.get("ocupado") == true or node.get("opening_ending") == true:
			return
		for body in node.get_overlapping_bodies():
			if body is CharacterBody2D and body.name == "Player":
				nearby_player = true
	prompt.visible = nearby_player

func _on_dialogue_started(_resource: DialogueResource) -> void:
	dialogue_active = true
	prompt.hide()

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	dialogue_active = false
