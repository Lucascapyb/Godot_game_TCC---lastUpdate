extends AudioStreamPlayer

@export var arrival_volume_db: float = -18.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = preload("res://assets/audio/sfx/old-car-driving.mp3")

func play_arrival() -> void:
	volume_db = arrival_volume_db
	play()
