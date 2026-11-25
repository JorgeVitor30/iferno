extends Area2D
## Copinho de café: cura 1 de vida. Só pega se não estiver com a vida cheia.

const OUTLINE := Color("1a1020")

var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	col.shape = c
	add_child(col)
	body_entered.connect(_try_pick)
	_t = randf() * 5.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	# Se o jogador ficar parado em cima com a vida cheia e depois tomar dano, pega na hora.
	for b in get_overlapping_bodies():
		_try_pick(b)

func _try_pick(body: Node2D) -> void:
	if not body.is_in_group("player") or not body.has_method("heal"):
		return
	if body.hp >= body.max_hp or body.hp <= 0:
		return
	body.heal(1)
	Fx.float_text(get_parent(), position + Vector2(0, -20), "+1 CAFÉ!", Color("ffd966"))
	Fx.burst(get_parent(), position + Vector2(0, -8), Color("8a5a3a"), 8, 50.0)
	queue_free()

func _draw() -> void:
	var bob := roundf(sin(_t * 4.0) * 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -4 + bob))
	# copo
	draw_rect(Rect2(-5, -11, 10, 11), OUTLINE)
	draw_rect(Rect2(-4, -10, 8, 9), Color("f4efe2"))
	draw_rect(Rect2(-4, -7, 8, 3), Color("b5452f")) # cinta
	draw_rect(Rect2(-4, -10, 8, 1), Color("5a3420")) # café
	# fumacinha
	for i in 3:
		var y := -13.0 - fmod(_t * 10.0 + i * 4.0, 12.0)
		var x := roundf(sin(_t * 3.0 + i) * 2.0) - 2 + i * 2
		draw_rect(Rect2(x, y, 1, 2), Color(1, 1, 1, 0.6 * (1.0 - (-13.0 - y) / 12.0)))
