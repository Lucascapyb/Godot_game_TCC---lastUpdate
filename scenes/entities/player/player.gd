extends CharacterBody2D
@export var agent: NavigationAgent2D
@export var anim_tree: AnimationTree
@export var speed: float = 8
@export var vision_light: PointLight2D  
var state_machine
var follow_mouse : bool = false
var facing_direction := Vector2.DOWN  

@export var footstep_volume_db: float = -18.0
@export var footstep_interval: float = 0.28

var footstep_player: AudioStreamPlayer
var footstep_cooldown := 0.0

func _ready():
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "Footsteps"
	footstep_player.stream = preload("res://assets/audio/sfx/8-bit-foot-steps.mp3")
	footstep_player.volume_db = footstep_volume_db
	add_child(footstep_player)
	state_machine = anim_tree.get("parameters/playback")
	if GameState.has_saved_position:
		global_position = GameState.player_position

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			follow_mouse = event.pressed

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			ComputerSound.play_open()
			GameState.save_player_position(global_position)
			get_tree().change_scene_to_file("res://scenes/MonitorScene.tscn")

func _physics_process(delta):
	if follow_mouse:
		var click_position = get_global_mouse_position()
		agent.target_position = click_position

	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		state_machine.travel("Idle")
		_stop_footsteps()
		return

	var next_position = agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	velocity = direction * speed
	var previous_position := global_position
	move_and_slide()
	_update_footsteps(delta, global_position.distance_squared_to(previous_position) > 0.01)
	_update_animation(direction)

func _update_footsteps(delta: float, moved: bool) -> void:
	if not moved:
		_stop_footsteps()
		return
	footstep_cooldown -= delta
	if footstep_cooldown <= 0.0:
		footstep_player.volume_db = footstep_volume_db
		footstep_player.play()
		footstep_cooldown = maxf(footstep_interval, 0.05)

func _stop_footsteps() -> void:
	footstep_cooldown = 0.0
	if footstep_player.playing:
		footstep_player.stop()

func _update_animation(direction: Vector2):
	anim_tree.set("parameters/Idle/blend_position", direction)
	anim_tree.set("parameters/Run/blend_position", direction)

	if direction.length() > 0.1:
		state_machine.travel("Run")
		facing_direction = direction  # NOVO
		vision_light.rotation = facing_direction.angle()  # NOVO
	else:
		state_machine.travel("Idle")
