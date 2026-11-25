extends Area2D
## Escada pro próximo andar. Só aparece depois que o chefe do andar cai.
## Origem no meio da base dos degraus.

signal climbed

const OUTLINE := Color("1a1020")

var _t := 0.0
var _used := false

func _ready() -> void:
	z_index = -4 # fica no chão, embaixo do jogador
	collision_layer = 0
	collision_mask = 2
	var col := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 20)
	col.shape = r
	col.position = Vector2(0, -22)
	add_child(col)
	body_entered.connect(_on_body_entered)
	scale = Vector2(0.1, 0.1)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	_used = true
	climbed.emit()

func _draw() -> void:
	# Buraco escuro + degraus subindo (mais claros lá em cima)
	draw_rect(Rect2(-26, -50, 52, 50), OUTLINE)
	for i in 6:
		var y := -8.0 - i * 7.0
		var c := Color("6a6478").lerp(Color("c8c4d4"), i / 5.0)
		draw_rect(Rect2(-24, y - 6, 48, 6), c)
		draw_rect(Rect2(-24, y, 48, 1), c.darkened(0.4))
	draw_rect(Rect2(-26, -50, 2, 50), Color("8a90a0"))
	draw_rect(Rect2(24, -50, 2, 50), Color("8a90a0"))
	# Seta pulando
	var bob := roundf(sin(_t * 5.0) * 3.0)
	var a := Vector2(0, -66 + bob)
	draw_colored_polygon(PackedVector2Array([a + Vector2(0, -8), a + Vector2(-8, 2), a + Vector2(8, 2)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([a + Vector2(0, -6), a + Vector2(-6, 1), a + Vector2(6, 1)]), Color("3fd17a"))
	Fx.text(self, Vector2(-50, -78 + bob), "PRÓXIMO ANDAR", Color("3fd17a"), 8, 100, HORIZONTAL_ALIGNMENT_CENTER)
