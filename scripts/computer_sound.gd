extends AudioStreamPlayer

@export var opening_volume_db: float = -18.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = preload("res://assets/audio/sfx/fnaf-open-camera-sound.mp3")

func play_open() -> void:
	volume_db = opening_volume_db
	play()
