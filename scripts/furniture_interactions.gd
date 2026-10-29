extends Node

const DESCRIPTION_PATH := "res://Dialogos/Moveis.dialogue"

@export var interaction_radius: float = 170.0

@onready var props: TileMapLayer = get_parent().get_node("Props")
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var prompt_controller: CanvasLayer = get_parent().get_node("InteractionPrompt")

var ocupado := false
var furniture: Array[Area2D] = []

func _ready() -> void:
	for cell in props.get_used_cells():
		var kind := _furniture_kind(props.get_cell_source_id(cell), props.get_cell_atlas_coords(cell))
		if kind.is_empty():
			continue
		var area := Area2D.new()
		area.name = "Movel_%s_%s" % [cell.x, cell.y]
		area.collision_layer = 0
		area.collision_mask = 1
		add_child(area)
		area.global_position = props.to_global(props.map_to_local(cell))
		area.add_to_group("interactables")
		area.add_to_group("furniture_interactions")
		var variant := absi(cell.x * 31 + cell.y * 17) % 4 + 1
		area.set_meta("dialogue_cue", "%s_%d" % [kind, variant])
		var shape := CircleShape2D.new()
		shape.radius = interaction_radius
		var collision := CollisionShape2D.new()
		collision.shape = shape
		area.add_child(collision)
		furniture.append(area)

func _unhandled_input(event: InputEvent) -> void:
	if ocupado or get_tree().paused or prompt_controller.dialogue_active:
		return
	if not event.is_action_pressed("talk") or event.is_echo():
		return
	# Existing NPCs and puzzle terminals always keep priority over scenery.
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is Area2D and not node.is_in_group("furniture_interactions"):
			if node.overlaps_body(player):
				return
	var nearest: Area2D
	var nearest_distance := INF
	for area in furniture:
		if not area.overlaps_body(player):
			continue
		var distance := player.global_position.distance_squared_to(area.global_position)
		if distance < nearest_distance:
			nearest = area
			nearest_distance = distance
	if nearest == null:
		return
	get_viewport().set_input_as_handled()
	var dialogue := load(DESCRIPTION_PATH) as DialogueResource
	if dialogue == null:
		push_error("Não foi possível carregar as descrições dos móveis.")
		return
	ocupado = true
	DialogueManager.show_dialogue_balloon(dialogue, str(nearest.get_meta("dialogue_cue")))
	await DialogueManager.dialogue_ended
	ocupado = false

func _furniture_kind(source: int, atlas: Vector2i) -> String:
	if source != 143:
		return ""
	if atlas.y == 0 or (atlas.y == 1 and atlas.x < 8):
		return "estante"
	if atlas.y == 2:
		return "estante" if atlas.x < 4 else "balcao"
	if atlas.y == 3:
		return "estante" if atlas.x >= 8 else "balcao"
	if atlas.y == 4 or (atlas.y == 5 and atlas.x < 4):
		return "estante"
	if atlas.y == 6 and atlas.x >= 8 or atlas.y == 7:
		return "balcao"
	if atlas.y == 9 and atlas.x >= 4 or atlas.y == 10 and (atlas.x < 4 or atlas.x >= 8):
		return "mesa"
	if atlas.y == 11 and atlas.x < 4 or atlas.y == 10 and atlas.x >= 4 and atlas.x < 8:
		return "banco"
	return ""
