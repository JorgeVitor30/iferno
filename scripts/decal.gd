extends Node2D
## Marcas no chão que os inimigos deixam: poça d'água, mancha de tinta,
## plaquinha de "piso molhado" (essa fica em pé), papéis espalhados.

const OUTLINE := Color("1a1020")

var kind := "tinta"
var color := Color.WHITE
var _seed := 0

func _ready() -> void:
	_seed = randi()
	if kind != "placa":
		z_index = -5 # embaixo de todo mundo, em cima do piso
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	match kind:
		"tinta", "agua":
			# bolhas em pixel grosso (unidades de 2px)
			var c := Color(color, 0.8 if kind == "tinta" else 0.4)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
			draw_rect(Rect2(-3, -1, 6, 2), c)
			draw_rect(Rect2(-2, -2, 4, 4), c)
			for i in 3:
				var p := Vector2(rng.randi_range(-5, 4), rng.randi_range(-2, 1))
				draw_rect(Rect2(p, Vector2(rng.randi_range(1, 2), 1)), c)
			if kind == "agua":
				draw_rect(Rect2(-2, -1, 1, 1), Color(1, 1, 1, 0.5))
		"papel":
			for i in 3:
				var p := Vector2(rng.randf_range(-8, 8), rng.randf_range(-4, 4)).round()
				draw_set_transform(p, rng.randf_range(-0.6, 0.6), Vector2.ONE)
				draw_rect(Rect2(-3, -2, 6, 4), Color("f4efe2"))
				draw_rect(Rect2(-2, -1, 4, 1), Color("b8b4c8"))
		"placa":
			# Cavalete amarelo de "CUIDADO PISO MOLHADO"
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
			draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
			draw_set_transform(Vector2.ZERO)
			var pts := PackedVector2Array([Vector2(-6, 0), Vector2(-3, -16), Vector2(3, -16), Vector2(6, 0)])
			var out := PackedVector2Array([Vector2(-7, 1), Vector2(-4, -17), Vector2(4, -17), Vector2(7, 1)])
			draw_colored_polygon(out, OUTLINE)
			draw_colored_polygon(pts, Color("ffd23f"))
			draw_rect(Rect2(-1, -12, 2, 5), OUTLINE) # "!"
			draw_rect(Rect2(-1, -5, 2, 2), OUTLINE)
