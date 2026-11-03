extends CanvasLayer

@onready var line_edit: LineEdit = $Control/VBoxContainer/LineEdit
@onready var label: Label = $Control/VBoxContainer/ScrollContainer/Label
@onready var scroll: ScrollContainer = $Control/VBoxContainer/ScrollContainer

const CODIGO_CORRETO := "9 7 2 6"
const MAX_TENTATIVAS := 3
const TEMPO_BLOQUEIO := 10.0
const PASSO_ROLAGEM := 60

var tentativas_restantes := MAX_TENTATIVAS
var blocked_until := 0
const STATE_ID := "symbols"


func _ready() -> void:
	# Garante que o terminal continue recebendo input com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	line_edit.text_submitted.connect(_on_text_submitted)
	var saved: Dictionary = GameState.terminals.get(STATE_ID, {})
	tentativas_restantes = int(saved.get("attempts", MAX_TENTATIVAS))
	blocked_until = int(saved.get("blocked_until", 0))
	label.text = str(saved.get("text", label.text))
	line_edit.placeholder_text = "Digite a sequência e pressione Enter"
	_update_terminal()

func _save_terminal() -> void:
	GameState.terminals[STATE_ID] = {"attempts": tentativas_restantes, "blocked_until": blocked_until, "text": label.text}

func _process(_delta: float) -> void:
	_update_terminal()

func _update_terminal() -> void:
	if blocked_until > 0 and Time.get_ticks_msec() >= blocked_until:
		blocked_until = 0
		tentativas_restantes = MAX_TENTATIVAS
		label.text += "\nTERMINAL LIBERADO."
		_save_terminal()
	line_edit.editable = blocked_until == 0 and not Global.key_red



func abrir() -> void:
	show()
	line_edit.grab_focus()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll.scroll_vertical -= PASSO_ROLAGEM
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll.scroll_vertical += PASSO_ROLAGEM
			get_viewport().set_input_as_handled()

	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_PAGEUP:
			scroll.scroll_vertical -= PASSO_ROLAGEM * 3
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_PAGEDOWN:
			scroll.scroll_vertical += PASSO_ROLAGEM * 3
			get_viewport().set_input_as_handled()


func _on_text_submitted(texto: String) -> void:
	if not line_edit.editable or texto.strip_edges() == "":
		return

	label.text += "\n> " + texto

	if texto.replace(" ", "") == CODIGO_CORRETO.replace(" ", ""):
		label.text += "\nCÓDIGO CORRETO"
		coletar_chave_vermelha()
		tentativas_restantes = MAX_TENTATIVAS
	else:
		tentativas_restantes -= 1
		if tentativas_restantes > 0:
			label.text += "\nCÓDIGO ERRADO. TENTATIVAS RESTANTES: %d" % tentativas_restantes
		else:
			_bloquear_terminal()

	_save_terminal()
	_update_terminal()
	line_edit.clear()
	await _rolar_para_baixo()


func _bloquear_terminal() -> void:
	blocked_until = Time.get_ticks_msec() + int(TEMPO_BLOQUEIO * 1000)
	label.text += "\nMUITAS TENTATIVAS INVÁLIDAS. TERMINAL BLOQUEADO POR %d SEGUNDOS." % int(TEMPO_BLOQUEIO)
	line_edit.editable = false


func _rolar_para_baixo() -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	if visible:
		line_edit.grab_focus()


func coletar_chave_vermelha() -> void:
	if not Global.key_red:
		Global.key_red = true
		label.text += "\nChave vermelha coletada!"
	else:
		label.text += "\n(chave já coletada)"


func _on_button_2_pressed() -> void:
	hide()
	get_tree().paused = false
