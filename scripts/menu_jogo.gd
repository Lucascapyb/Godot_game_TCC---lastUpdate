extends CanvasLayer

@onready var menu_buttons: Control = $MainConteiner/HBoxContainer/VBoxContainer # ajuste pro caminho real
@onready var controles_overlay: CanvasLayer = $Controles  # a instância que você acabou de criar

func _ready() -> void:
	visible = false
	controles_overlay.visible = false
	controles_overlay.voltar_pressed.connect(_on_controles_voltar)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Config") and not event.is_echo():
		if GameState.interaction_busy():
			return
		if visible:
			_on_voltar_pressed()
			get_viewport().set_input_as_handled()
			return
		if get_tree().paused:
			return
		get_viewport().set_input_as_handled()
		visible = true
		get_tree().paused = true

func _on_sair_pressed() -> void:
	get_tree().quit()

func _on_voltar_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_controles_pressed() -> void:
	menu_buttons.visible = false
	controles_overlay.visible = true

func _on_controles_voltar() -> void:
	controles_overlay.visible = false
	menu_buttons.visible = true

func _on_voltar_pressed() -> void:
	controles_overlay.visible = false
	menu_buttons.visible = true
	get_tree().paused = false
	visible = false
