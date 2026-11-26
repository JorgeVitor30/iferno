extends Node
## Atalhos globais (autoload): funcionam em qualquer cena.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		Settings.fullscreen = not fs
		Settings.apply()
		Settings.save()
