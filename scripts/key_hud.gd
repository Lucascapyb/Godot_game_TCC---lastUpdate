extends CanvasLayer

@onready var counter: Label = $Panel/Margin/Counter
@onready var tutorial: PanelContainer = $Tutorial
@onready var tutorial_text: Label = $Tutorial/Margin/Text
@onready var player: CharacterBody2D = get_parent().get_node("Player")

var initial_position: Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initial_position = player.global_position
	update_counter()
	var floating := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	floating.tween_property(tutorial, "offset_top", -216.0, 1.4)
	floating.parallel().tween_property(tutorial, "offset_bottom", -116.0, 1.4)
	floating.tween_property(tutorial, "offset_top", -210.0, 1.4)
	floating.parallel().tween_property(tutorial, "offset_bottom", -110.0, 1.4)
	update_visibility()

func _process(_delta: float) -> void:
	update_counter()
	update_visibility()

func update_visibility() -> void:
	visible = not get_tree().paused and not GameState.interaction_busy()
	if not visible:
		return
	if player.global_position.distance_squared_to(initial_position) > 16.0:
		GameState.movement_tutorial_completed = true
	if GameState.entered_installation and not GameState.opened_sara_monitor:
		tutorial_text.text = "Pressione Espaço para conversar com a S.A.R.A."
		tutorial.show()
	elif not GameState.movement_tutorial_completed:
		tutorial_text.text = "Clique com o botão direito do mouse para andar."
		tutorial.show()
	else:
		tutorial.hide()

func update_counter() -> void:
	var key_count := int(Global.key_red) + int(Global.key_blue)
	counter.text = "Chaves: %d/2" % key_count
