extends Control
## Placeholder da run: aparece depois de entrar no ônibus. Enter/Esc volta pra área inicial.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
