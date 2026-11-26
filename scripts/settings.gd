extends Node
## Autoload: configurações do jogador (volume e tela cheia), salvas em user://settings.cfg.
## Cria os canais de áudio "SFX" e "Music" (Sfx.play toca no "SFX").

const PATH := "user://settings.cfg"

var master := 0.8
var sfx := 0.8
var music := 0.6
var fullscreen := false

func _ready() -> void:
	for bus in ["SFX", "Music"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		master = cfg.get_value("audio", "master", master)
		sfx = cfg.get_value("audio", "sfx", sfx)
		music = cfg.get_value("audio", "music", music)
		fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	apply()

func apply() -> void:
	_set_volume("Master", master)
	_set_volume("SFX", sfx)
	_set_volume("Music", music)
	var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if fs != fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "music", music)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)

func _set_volume(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, v <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))
