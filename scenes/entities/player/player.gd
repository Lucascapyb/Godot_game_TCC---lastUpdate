extends CharacterBody2D
@export var agent: NavigationAgent2D
@export var anim_tree: AnimationTree
@export var speed: float = 8
var state_machine
var follow_mouse : bool = false

func _ready():
	state_machine = anim_tree.get("parameters/playback")
	if GameState.has_saved_position:
		global_position = GameState.player_position

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			follow_mouse = event.pressed

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			GameState.save_player_position(global_position)
			get_tree().change_scene_to_file("res://scenes/MonitorScene.tscn")

func _physics_process(_delta):
	if follow_mouse:
		var click_position = get_global_mouse_position()
		agent.target_position = click_position

	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		state_machine.travel("Idle")
		return

	var next_position = agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: Vector2):
	anim_tree.set("parameters/Idle/blend_position", direction)
	anim_tree.set("parameters/Run/blend_position", direction)

	if direction.length() > 0.1:
		state_machine.travel("Run")
	else:
		state_machine.travel("Idle")
