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

@export var ending_music_volume_db: float = -24.0
@export var voice_volume_db: float = -12.0

var ending_music: AudioStreamPlayer
var voice: AudioStreamPlayer

@onready var heading: Label = $Center/Content/Heading
@onready var message: Label = $Center/Content/Message
@onready var status: Label = $Center/Content/Status
@onready var choices: VBoxContainer = $Center/Content/Choices
@onready var delete_button: Button = $Center/Content/Choices/Delete
@onready var free_button: Button = $Center/Content/Choices/Free
@onready var finish: Label = $Center/Content/Finish
@onready var menu_button: Button = $Center/Content/Menu

func _ready() -> void:
	ending_music = AudioStreamPlayer.new()
	ending_music.name = "EndingMusic"
	ending_music.volume_db = ending_music_volume_db
	add_child(ending_music)
	voice = AudioStreamPlayer.new()
	voice.name = "SaraVoice"
	var voice_stream := preload("res://assets/audio/sfx/toriel.mp3").duplicate() as AudioStreamMP3
	voice_stream.loop = true
	voice.stream = voice_stream
	voice.volume_db = voice_volume_db
	voice.pitch_scale = 1.2
	add_child(voice)
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
	_play_ending_music(preload("res://assets/audio/music/Triste.mp3"))
	status.text = "ENCERRANDO S.A.R.A."
	for line in DELETE_LINES:
		if line == DELETE_LINES.back():
			heading.text = ""
			status.text = ""
		await _show_message(line)
		await get_tree().create_timer(2.2).timeout
	# Hold her final question before displaying the system's deletion notice.
	await get_tree().create_timer(3.0).timeout
	var deletion_notice := create_tween()
	deletion_notice.tween_property(message, "modulate:a", 0.0, 0.35)
	await deletion_notice.finished
	message.text = "Arquivos S.A.R.A. deletados com sucesso"
	message.visible_ratio = 1.0
	message.modulate.a = 1.0
	_show_finish()

func _choose_free() -> void:
	if choice_made:
		return
	choice_made = true
	choices.hide()
	_play_ending_music(preload("res://assets/audio/music/Paz.mp3"))
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
	voice.stop()
	var fade_out := create_tween()
	fade_out.tween_property(message, "modulate:a", 0.0, 0.35)
	await fade_out.finished
	message.text = text
	message.visible_ratio = 0.0
	message.modulate.a = 1.0
	voice.play()
	var writing := create_tween()
	writing.tween_property(message, "visible_ratio", 1.0, text.length() * 0.035)
	await writing.finished
	voice.stop()

func _play_ending_music(track: AudioStreamMP3) -> void:
	var looped_track := track.duplicate() as AudioStreamMP3
	looped_track.loop = true
	ending_music.stream = looped_track
	ending_music.volume_db = ending_music_volume_db
	ending_music.play()

func _show_finish() -> void:
	status.text = ""
	status.hide()
	$Center.offset_top = 270.0
	$Center.offset_bottom = -20.0
	$Center/Content.add_theme_constant_override("separation", 20)
	$GameLogo.show()
	finish.show()
	menu_button.show()
	$Center/Content/Credits.show()
	menu_button.grab_focus()

func _return_to_menu() -> void:
	voice.stop()
	ending_music.stop()
	GameState.reset_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
