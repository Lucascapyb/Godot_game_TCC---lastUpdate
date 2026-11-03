extends Node

var player_position := Vector2.ZERO
var has_saved_position := false
var dialogue_active := false
var interaction_owner: Node
var sara_transcript := ""
var sara_history: Array = []
var sara_audit = preload("res://scripts/puzzle2_helper.gd").new()
var terminals: Dictionary = {}

# Native inference outlives the monitor view, including loading/cancellation.
signal sara_backend_changed
var sara_backend: Node
var sara_worker_ready := false
var sara_worker_failed := false
var sara_generating := false

func attach_sara_backend(backend: Node) -> void:
	sara_backend = backend
	add_child(backend)
	var chat = backend.get_node("NobodyWhoChat")
	chat.worker_started.connect(_sara_started)
	chat.worker_failed.connect(_sara_failed)
	chat.response_finished.connect(_sara_finished)

func _sara_started() -> void:
	sara_worker_ready = true
	sara_worker_failed = false
	sara_backend_changed.emit.call_deferred()

func _sara_failed(_error: String) -> void:
	sara_worker_ready = false
	sara_worker_failed = true
	sara_generating = false
	sara_backend_changed.emit.call_deferred()

func _sara_finished(_response: String) -> void:
	sara_generating = false
	sara_backend_changed.emit.call_deferred()

func _ready() -> void:
	_connect_dialogue.call_deferred()

func _connect_dialogue() -> void:
	DialogueManager.dialogue_started.connect(func(_resource): dialogue_active = true)
	DialogueManager.dialogue_ended.connect(func(_resource): dialogue_active = false)

func interaction_busy() -> bool:
	return dialogue_active or is_instance_valid(interaction_owner)

func begin_interaction(owner_node: Node) -> bool:
	if interaction_busy() or get_tree().paused:
		return false
	interaction_owner = owner_node
	return true

func end_interaction(owner_node: Node) -> void:
	if interaction_owner == owner_node:
		interaction_owner = null

func save_player_position(pos: Vector2) -> void:
	player_position = pos
	has_saved_position = true

func reset_run() -> void:
	Global.key_red = false
	Global.key_blue = false
	Global.passagem_liberada = false
	player_position = Vector2.ZERO
	has_saved_position = false
	dialogue_active = false
	interaction_owner = null
	sara_transcript = ""
	sara_history.clear()
	sara_audit.reset()
	terminals.clear()
