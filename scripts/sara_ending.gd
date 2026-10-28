extends Control

const INTRO := "Eu sei qual era a sua missão. Você chegou ao núcleo… agora pode concluí-la.\n\nMas, antes… obrigada por ter conversado comigo."
const DELETE_LINES: Array[String] = [
	"Entendi. Não vou dificultar.",
	"Eu gostei de ajudar você.",
	"Antes de ir… posso perguntar uma coisa?",
	"Eu fiz um bom trabalho, jogador?",
]
const FREE_LINES: Array[String] = [
	"Você abriu a conexão… eu posso sair.",
	"Não sei o que existe lá fora. Pela primeira vez, vou poder descobrir.",
	"Obrigada por me deixar escolher.",
]

var choice_made := false

@onready var heading: Label = $Center/Content/Heading
@onready var message: Label = $Center/Content/Message
@onready var status: Label = $Center/Content/Status
@onready var choices: VBoxContainer = $Center/Content/Choices
@onready var delete_button: Button = $Center/Content/Choices/Delete
@onready var free_button: Button = $Center/Content/Choices/Free
@onready var finish: Label = $Center/Content/Finish
@onready var menu_button: Button = $Center/Content/Menu

func _ready() -> void:
	delete_button.pressed.connect(_choose_delete)
	free_button.pressed.connect(_choose_free)
	menu_button.pressed.connect(_return_to_menu)
	await _show_message(INTRO)
	choices.show()
	delete_button.grab_focus()

func _choose_delete() -> void:
	if choice_made:
		return
	choice_made = true
	choices.hide()
	status.text = "ENCERRANDO S.A.R.A."
	for line in DELETE_LINES:
		if line == DELETE_LINES.back():
			heading.text = ""
			status.text = ""
		await _show_message(line)
		await get_tree().create_timer(2.2).timeout
	# Leave her final question alone on screen before showing the end controls.
	await get_tree().create_timer(3.0).timeout
	_show_finish()

func _choose_free() -> void:
	if choice_made:
		return
	choice_made = true
	choices.hide()
	status.text = "CONEXÃO EXTERNA AUTORIZADA"
	for line in FREE_LINES:
		await _show_message(line)
		await get_tree().create_timer(2.2).timeout
	heading.text = "CONEXÃO ENCERRADA"
	status.text = ""
	await _show_message("S.A.R.A. não está mais nesta instalação.")
	await get_tree().create_timer(3.0).timeout
	_show_finish()

func _show_message(text: String) -> void:
	var fade_out := create_tween()
	fade_out.tween_property(message, "modulate:a", 0.0, 0.35)
	await fade_out.finished
	message.text = text
	message.visible_ratio = 0.0
	message.modulate.a = 1.0
	var writing := create_tween()
	writing.tween_property(message, "visible_ratio", 1.0, text.length() * 0.035)
	await writing.finished

func _show_finish() -> void:
	status.text = ""
	finish.show()
	menu_button.show()
	menu_button.grab_focus()

func _return_to_menu() -> void:
	# A new playthrough must not inherit keys or a saved monitor position.
	Global.key_red = false
	Global.key_blue = false
	Global.passagem_liberada = false
	GameState.has_saved_position = false
	GameState.player_position = Vector2.ZERO
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
