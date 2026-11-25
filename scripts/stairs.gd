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
	r.size = Vector2(60, 30)
	col.shape = r
	col.position = Vector2(0, -30)
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
	# Buraco escuro + degraus subindo (mais claros lá em cima), com corrimão
	var w := 72.0
	var h := 76.0
	draw_rect(Rect2(-w / 2 - 2, -h - 2, w + 4, h + 4), OUTLINE)
	draw_rect(Rect2(-w / 2, -h, w, h), Color("140c1c"))
	for i in 8:
		var y := -6.0 - i * 9.0
		var c := Color("4a3d5a").lerp(Color("a89ab8"), i / 7.0)
		draw_rect(Rect2(-w / 2 + 3, y - 7, w - 6, 7), c)
		draw_rect(Rect2(-w / 2 + 3, y - 7, w - 6, 1), c.lightened(0.25))
		draw_rect(Rect2(-w / 2 + 3, y, w - 6, 2), c.darkened(0.45))
	for side: float in [-1.0, 1.0]:
		var x := side * (w / 2 - 2)
		draw_rect(Rect2(x - 2, -h, 4, h), Color("5c5670"))
		draw_rect(Rect2(x - 2, -h, 1, h), Color("8a8498"))
	# luz de saída lá em cima
	draw_rect(Rect2(-w / 2 + 3, -h, w - 6, 4), Color(0.6, 1.0, 0.7, 0.35))
	# Seta pulando
	var bob := roundf(sin(_t * 5.0) * 3.0)
	var a := Vector2(0, -h - 18 + bob)
	draw_colored_polygon(PackedVector2Array([a + Vector2(0, -10), a + Vector2(-10, 3), a + Vector2(10, 3)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([a + Vector2(0, -8), a + Vector2(-8, 2), a + Vector2(8, 2)]), Color("3fd17a"))
	Fx.text(self, Vector2(-60, -h - 32 + bob), "PRÓXIMO ANDAR", Color("3fd17a"), 11, 120, HORIZONTAL_ALIGNMENT_CENTER)
