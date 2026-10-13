extends CanvasLayer

signal voltar_pressed

func _on_button_2_pressed() -> void:
	voltar_pressed.emit()
