extends Node

const SILENT_DB := -65.0

@export var music_volume_db: float = -24.0
@export var outdoor_volume_db: float = -20.0
@export var crossfade_duration: float = 1.5

@onready var lighting: Node = get_parent().get_node("IluminacaoInstalacao")

var ambient: AudioStreamPlayer
var suspense: AudioStreamPlayer
var initialized := false
var inside := false
var crossfade: Tween

func _ready() -> void:
	ambient = _create_player("Exterior", preload("res://assets/audio/sfx/yt._ambient.mp3"))
	suspense = _create_player("Interior", preload("res://assets/audio/sfx/musica suspense.mp3"))

func _create_player(player_name: String, track: AudioStreamMP3) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	var looped_track := track.duplicate() as AudioStreamMP3
	looped_track.loop = true
	player.stream = looped_track
	player.volume_db = SILENT_DB
	add_child(player)
	return player

func _process(_delta: float) -> void:
	# Share the lighting's zone decision, including its doorway handling.
	if not lighting.initialized:
		return
	if not initialized:
		initialized = true
		inside = lighting.inside
		var initial_track := suspense if inside else ambient
		initial_track.volume_db = music_volume_db if inside else outdoor_volume_db
		initial_track.play()
	elif inside != lighting.inside:
		inside = lighting.inside
		_change_track()

func _change_track() -> void:
	if crossfade != null and crossfade.is_valid():
		crossfade.kill()
	var incoming := suspense if inside else ambient
	var outgoing := ambient if inside else suspense
	if not incoming.playing:
		incoming.volume_db = SILENT_DB
		incoming.play()
	crossfade = create_tween().set_parallel(true)
	var target_volume := music_volume_db if inside else outdoor_volume_db
	crossfade.tween_property(incoming, "volume_db", target_volume, crossfade_duration)
	crossfade.tween_property(outgoing, "volume_db", SILENT_DB, crossfade_duration)
	crossfade.chain().tween_callback(outgoing.stop)
