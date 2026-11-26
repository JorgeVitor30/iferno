extends StaticBody2D
## Baú da sala de prova surpresa: aparece depois das 5 rodadas.
## Encostou -> abre (tampa pula, moedinhas voam) e o andar oferece 3 upgrades raros.

const OUT := Color("0b0612")
const WOOD := Color("7a4038")
const WOOD_L := Color("a0583f")
const WOOD_D := Color("4e2628")
const GOLD := Color("ffd23f")
const GOLD_D := Color("b8862a")

var _t := 0.0
var _open := false
var _lid := 0.0     # 0 = fechado, 1 = aberto
var _appear := 0.0  # animação de surgir
var _glow: Sprite2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(36, 10)
	col.shape = box
	col.position = Vector2(0, -5)
	add_child(col)
	# área de toque um pouco maior que o corpo
	var touch := Area2D.new()
	touch.collision_layer = 0
	touch.collision_mask = 2
	var tc := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 30.0
	tc.shape = c
	tc.position = Vector2(0, -8)
	touch.add_child(tc)
	touch.body_entered.connect(_on_touch)
	add_child(touch)
	_glow = Fx.glow(self, Vector2(0, -14), 34.0, GOLD, 0.7)
	Fx.burst(get_parent(), position + Vector2(0, -10), GOLD, 20, 90.0, 2.0)
	Sfx.play(self, "pick", 0.0)

func _on_touch(body: Node2D) -> void:
	if _open or _appear < 1.0 or not body.is_in_group("player"):
		return
	_open = true
	Sfx.play(self, "chest", 0.0)
	Fx.shake(self, 3.0)
	Fx.burst(get_parent(), position + Vector2(0, -20), GOLD, 26, 120.0, 2.0, 200.0)
	Fx.burst(get_parent(), position + Vector2(0, -20), Color.WHITE, 10, 80.0, 1.5)
	create_tween().tween_property(self, "_lid", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.45).timeout
	get_tree().call_group("level", "open_chest")

func _process(delta: float) -> void:
	_t += delta
	_appear = minf(_appear + delta * 2.5, 1.0)
	if _glow:
		_glow.modulate.a = (0.35 if _open else 0.7) + sin(_t * 4.0) * 0.12
	queue_redraw()

## Retângulo com contorno de 1px (unidades de tela; o baú é desenhado em 2x).
func _b(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x * 2 - 1, y * 2 - 1, w * 2 + 2, h * 2 + 2), OUT)
	draw_rect(Rect2(x * 2, y * 2, w * 2, h * 2), c)

func _f(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x * 2, y * 2, w * 2, h * 2), c)

func _draw() -> void:
	Fx.contact_shadow(self, Vector2(2, 1), 24.0, 1.4)
	# surge de baixo pra cima com um quique
	var pop := 1.0 - pow(1.0 - _appear, 3.0)
	var bob := 0.0 if _open else roundf(sin(_t * 3.0) * 0.5)
	draw_set_transform(Vector2(0, (1.0 - pop) * 10.0 + bob))
	# corpo (unidades de arte: 20x10, origem no meio da base)
	_b(-10, -10, 20, 10, WOOD)
	_f(-10, -10, 20, 1, WOOD_L)
	_f(-10, -2, 20, 2, WOOD_D)
	_f(7, -9, 3, 7, WOOD_D)           # lado na sombra
	_b(-10, -10, 2, 10, GOLD_D)       # cantoneiras
	_b(8, -10, 2, 10, GOLD_D)
	if _open:
		# interior brilhando
		_f(-8, -11, 16, 2, GOLD)
	# tampa: abre pra trás (sobe e achata)
	var ly := -15.0 - _lid * 6.0
	var lh := 6.0 - _lid * 3.0
	_b(-11, ly, 22, lh, WOOD)
	_f(-11, ly, 22, 1, WOOD_L)
	_b(-11, ly, 2, lh, GOLD_D)
	_b(9, ly, 2, lh, GOLD_D)
	if not _open:
		# fechadura
		_b(-2, -11, 4, 4, GOLD)
		_f(-0.5, -10, 1, 2, OUT)
		# brilhinho passando
		var sx := fmod(_t * 14.0, 40.0) - 12.0
		if sx > -10 and sx < 10:
			_f(sx, -9, 1, 7, Color(1, 1, 1, 0.35))
	draw_set_transform(Vector2.ZERO)
	if not _open and _appear >= 1.0:
		Fx.text(self, Vector2(-40, -42 + roundf(sin(_t * 4.0) * 1.5)), "ABRIR", GOLD, Fx.SMALL, 80, HORIZONTAL_ALIGNMENT_CENTER)
