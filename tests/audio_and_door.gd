extends SceneTree
var checks := 0
var failures: Array[String] = []
var state
func _initialize():
    run.call_deferred()
func check(ok: bool, label: String):
    checks += 1
    print("CHECK ", label, ": ", ok)
    if not ok: failures.append(label)
func wait_seconds(seconds: float):
    await create_timer(seconds).timeout
func run():
    state = root.get_node("GameState")
    state.reset_run()
    var map = load("res://scenes/GameScene.tscn").instantiate()
    root.add_child(map)
    current_scene = map
    await wait_seconds(0.15)
    var lighting = map.get_node("IluminacaoInstalacao")
    lighting.set_physics_process(false)
    lighting.initialized = true
    lighting.inside = true
    await wait_seconds(1.8)
    var music = state.phase_music
    var music_id = music.get_instance_id()
    check(music.get_parent() == state, "persistent_parent")
    check(music.suspense.playing, "indoor_music_started")
    var targets = ["puzle_2_poster", "puzle_2_cracha", "puzle_2_TelaRegistro", "PC_puzle_2"]
    for target in targets:
        var before = music.suspense.get_playback_position()
        map.get_node(target).abrir_puzzle()
        await wait_seconds(0.4)
        check(paused, target + "_pauses_game")
        check(music.suspense.playing and not music.suspense.stream_paused, target + "_music_active")
        check(music.suspense.get_playback_position() > before + 0.1, target + "_music_advances")
        paused = false
        for ui in ["Tela_Poster", "Tela_Cracha", "Tela_Registro", "Puzle2_codigo"]:
            map.get_node(ui).hide()
    for ui in ["puzleOne", "PuzleoneCode", "PauseMenu"]:
        var before = music.suspense.get_playback_position()
        map.get_node(ui).show()
        paused = true
        await wait_seconds(0.4)
        check(music.suspense.get_playback_position() > before + 0.1, ui + "_music_advances")
        paused = false
        map.get_node(ui).hide()
    var tile = map.get_node("walls").tile_set.get_source(233).get_tile_data(Vector2i(5, 1), 0)
    check(tile.z_index == 0 and tile.y_sort_origin == 64, "door_sorted_at_base")
    var before = music.suspense.get_playback_position()
    var monitor = Node2D.new()
    monitor.scene_file_path = "res://scenes/MonitorScene.tscn"
    root.add_child(monitor)
    current_scene = monitor
    map.queue_free()
    await wait_seconds(0.4)
    check(is_instance_valid(state.phase_music) and music.suspense.get_playback_position() > before + 0.1, "chat_scene_music_persists")
    map = load("res://scenes/GameScene.tscn").instantiate()
    root.add_child(map)
    current_scene = map
    monitor.queue_free()
    await wait_seconds(0.1)
    lighting = map.get_node("IluminacaoInstalacao")
    lighting.set_physics_process(false)
    lighting.initialized = true
    lighting.inside = true
    await wait_seconds(0.2)
    check(state.phase_music.get_instance_id() == music_id, "return_reuses_same_music_player")
    check(music.suspense.get_playback_position() > before, "return_keeps_music_position")
    var balloon = load("res://Dialogos/balloon.tscn").instantiate()
    root.add_child(balloon)
    balloon.start(load("res://Dialogos/Moveis.dialogue"), "estante_1")
    await wait_seconds(0.2)
    check(balloon.dialogue_label.is_typing and balloon.typing_voice.playing, "dialogue_voice_while_typing")
    check(is_equal_approx(balloon.typing_voice.pitch_scale, 0.85), "dialogue_voice_lower_pitch")
    balloon.dialogue_label.skip_typing()
    await wait_seconds(0.1)
    check(not balloon.typing_voice.playing, "dialogue_voice_stops_on_skip")
    balloon.queue_free()
    var menu = Node.new()
    menu.scene_file_path = "res://scenes/title_screen.tscn"
    root.add_child(menu)
    current_scene = menu
    map.queue_free()
    await wait_seconds(0.1)
    check(not is_instance_valid(state.phase_music), "music_stops_at_title")
    print("AUDIO_DOOR_TEST: ", checks, " checks, ", failures.size(), " failures ", failures)
    quit(0 if failures.is_empty() else 1)
