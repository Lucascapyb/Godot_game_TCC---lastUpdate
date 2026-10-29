extends AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = preload("res://assets/audio/sfx/586241__beetlemuse__isolophobia.wav")
	finished.connect(play_menu)

func play_menu() -> void:
	# Both menu scenes can request playback without restarting the track.
	if not playing:
		play()
