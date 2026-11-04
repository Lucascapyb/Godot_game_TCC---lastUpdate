extends Node

## Floor sources used by the installation and the S.A.R.A. room.
const INDOOR_FLOORS: Array[int] = [413, 13]
const OUTDOOR_FLOORS: Array[int] = [36, 68]

@export var indoor_light_multiplier: float = 3.0
@export var transition_duration: float = 0.8

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var ground: TileMapLayer = get_parent().get_node("Ground")
@onready var light: PointLight2D = player.get_node("PointLight2D")

var outdoor_light_scale: float
var inside := false
var initialized := false
var last_cell := Vector2i(2147483647, 2147483647)
var transition: Tween

func _ready() -> void:
	outdoor_light_scale = light.texture_scale
	# Wait for the player's saved position to be restored after a puzzle.
	_update_zone.call_deferred()

func _physics_process(_delta: float) -> void:
	_update_zone()

func _update_zone() -> void:
	var cell := ground.local_to_map(ground.to_local(player.global_position))
	if initialized and cell == last_cell:
		return
	last_cell = cell
	var source := ground.get_cell_source_id(cell)
	# Keep the current lighting over gaps or decorative tiles at the doorway.
	if source not in INDOOR_FLOORS and source not in OUTDOOR_FLOORS:
		return
	var now_inside := source in INDOOR_FLOORS
	if initialized and now_inside == inside:
		return
	inside = now_inside
	if inside:
		GameState.entered_installation = true
	var target_scale := outdoor_light_scale * indoor_light_multiplier if inside else outdoor_light_scale
	if not initialized:
		initialized = true
		light.texture_scale = target_scale
		return
	if transition != null and transition.is_valid():
		transition.kill()
	transition = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(light, "texture_scale", target_scale, transition_duration)
