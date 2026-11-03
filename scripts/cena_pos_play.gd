extends Control

@onready var label: Label = $Texto/Label
@onready var continuar: Button = $Button2

var som := AudioStreamPlayer.new()
var tween: Tween
var terminou := false
var iniciando_fase := false

@export var fadeout_duration: float = 0.8

func _ready() -> void:
	continuar.visible = false
	label.visible_ratio = 0.0

	# Cria o player de áudio e toca em loop enquanto o texto aparece
	add_child(som)
	som.stream = load("res://assets/audio/sfx/toriel.mp3").duplicate()
	som.stream.loop = true
	som.volume_db = -12.0
	som.pitch_scale = 1.2
	som.play()

	tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, label.text.length() * 0.02)
	tween.finished.connect(_terminar)

func _terminar() -> void:
	terminou = true
	som.stop()
	continuar.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if iniciando_fase:
		return
	# Espaço ou Enter antes de acabar: mostra o texto inteiro
	if event.is_action_pressed("ui_accept") and not terminou:
		tween.kill()
		label.visible_ratio = 1.0
		_terminar()

func _on_button_2_pressed() -> void:
	if iniciando_fase:
		return
	iniciando_fase = true
	continuar.disabled = true
	som.stop()
	if tween != null and tween.is_valid():
		tween.kill()
	$bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fadeout := create_tween().set_parallel(true)
	for child in get_children():
		if child is CanvasItem and child != $bg_overlay:
			fadeout.tween_property(child, "modulate:a", 0.0, fadeout_duration)
	await fadeout.finished
	ArrivalSound.play_arrival()
	await ArrivalSound.finished
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
