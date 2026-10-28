extends CanvasLayer

@onready var counter: Label = $Panel/Margin/Counter

func _ready() -> void:
	update_counter()

func _process(_delta: float) -> void:
	update_counter()

func update_counter() -> void:
	var key_count := int(Global.key_red) + int(Global.key_blue)
	counter.text = "Chaves: %d/2" % key_count
