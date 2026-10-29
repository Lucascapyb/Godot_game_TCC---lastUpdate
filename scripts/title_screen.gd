extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MenuMusic.play_menu()


func _on_start_btn_pressed() -> void:
	MenuMusic.stop()
	get_tree().change_scene_to_file("res://scenes/Cena_pos_play.tscn")


func _on_credit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/creditos.tscn")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
