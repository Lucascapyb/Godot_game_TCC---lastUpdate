extends Node2D

@onready var wall: StaticBody2D = $Porta

# Arraste aqui o TileMapLayer onde as portas estão pintadas
@export var door_layer: TileMapLayer

const DOOR_CELLS: Array[Vector2i] = [
	Vector2i(29, -44), # porta da direita
	Vector2i(29, -43), # porta da esquerda
]
const OPEN_SOURCE_ID := 233
const OPEN_ATLAS_COORDS := Vector2i(5, 1)

var aberta := false

func _process(_delta: float) -> void:
	if Global.passagem_liberada and Global.key_red and Global.key_blue and not aberta:
		abrir_porta()

func abrir_porta() -> void:
	aberta = true
	if wall != null:
		wall.queue_free()
		wall = null
	for cell in DOOR_CELLS:
		door_layer.set_cell(cell, OPEN_SOURCE_ID, OPEN_ATLAS_COORDS, 0)
