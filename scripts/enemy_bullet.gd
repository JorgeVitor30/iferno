extends Area2D
## Projétil de papel dos inimigos. A posição do nó é no chão (sombra);
## o desenho voa uns pixels acima, na altura da mão.
##   "prova"   folha de prova girando (com nota vermelha)
##   "aviao"   aviãozinho de papel que vai virando atrás do jogador
##   "bolinha" papel amassado
##   "giz"     pontinho de giz (os ataques de gráfico/função do professor de estatística)
##   "digito"  um número voando (sai da calculadora)
##   "calculadora" calculadora girando que explode em números quando chega no alvo
## `curve` faz o projétil andar numa curva em vez de reto: "log" segue y = a·ln(1 + x/k).
## Durante o dodge roll o jogador atravessa o papel sem tomar dano.

const OUTLINE := Color("1a1020")
const PAPER := Color("f4efe2")
const HEIGHT := 11.0

var kind := "bolinha"
var direction := Vector2.RIGHT
var speed := 100.0
var homing := 0.0 # rad/s que o aviãozinho consegue virar
var lifetime := 4.0
var curve := ""          # "" = reto, "log" = curva logarítmica
var curve_amp := 0.0     # quanto a curva abre pro lado (pode ser negativo)
var explode_dist := -1.0 # calculadora: explode depois de andar isso
var digit := "7"
var _t := 0.0
var _origin := Vector2.ZERO
var _dist := 0.0
var _spin := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # paredes e jogador
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	col.shape = c
	add_child(col)
	body_entered.connect(_on_body_entered)
	_spin = randf() * TAU
	_origin = position
	if kind == "calculadora":
		c.radius = 6.0
	if kind == "digito":
		digit = str(randi() % 10)

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		_pop()
		return
	if homing > 0.0 and _t > 0.25:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p and p.visible:
			var want := (p.global_position - global_position).angle()
			var a := rotate_toward(direction.angle(), want, homing * delta)
			direction = Vector2.from_angle(a)
	_dist += speed * delta
	if curve == "log":
		# anda ao longo da reta e desvia pro lado seguindo o logaritmo
		var side := direction.orthogonal()
		position = _origin + direction * _dist + side * curve_amp * log(1.0 + _dist / 40.0)
	else:
		position += direction * speed * delta
	if explode_dist > 0.0 and _dist >= explode_dist:
		_pop()
		return
	_spin += delta * (14.0 if kind == "prova" else 9.0)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("is_rolling") and body.is_rolling():
			return # desviou!
		body.take_damage(1)
	_pop()

func _pop() -> void:
	if kind == "calculadora":
		_explode()
	Fx.burst(get_parent(), position + Vector2(0, -HEIGHT), PAPER if kind != "giz" else Color("fff4b0"), 5, 45.0, 1.5)
	queue_free()

## Calculadora estoura num anel de números.
func _explode() -> void:
	var parent := get_parent()
	if parent == null:
		return
	Fx.burst(parent, position + Vector2(0, -HEIGHT), Color("4a4a58"), 14, 90.0, 2.5)
	Fx.shake(self, 2.0)
	var n := 10
	var off := randf() * TAU
	for i in n:
		var b: Area2D = (get_script() as GDScript).new()
		b.kind = "digito"
		b.direction = Vector2.from_angle(off + i * TAU / n)
		b.speed = 85.0
		b.lifetime = 3.0
		b.position = position + b.direction * 6.0
		parent.call_deferred("add_child", b)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 3.5, Color(0, 0, 0, 0.3))
	var up := Vector2(0, -HEIGHT)
	match kind:
		"prova":
			draw_set_transform(up, _spin, Vector2.ONE)
			draw_rect(Rect2(-4, -5, 8, 10), OUTLINE)
			draw_rect(Rect2(-3, -4, 6, 8), PAPER)
			draw_rect(Rect2(-2, -2, 4, 1), Color("9a9aa8"))
			draw_rect(Rect2(-2, 0, 4, 1), Color("9a9aa8"))
			draw_rect(Rect2(0, 2, 2, 2), Color("e0382f")) # nota vermelha
		"aviao":
			draw_set_transform(up, direction.angle(), Vector2.ONE)
			var pts := PackedVector2Array([Vector2(6, 0), Vector2(-5, -5), Vector2(-3, 0), Vector2(-5, 5)])
			var outline := PackedVector2Array([Vector2(8, 0), Vector2(-6, -7), Vector2(-4, 0), Vector2(-6, 7)])
			draw_colored_polygon(outline, OUTLINE)
			draw_colored_polygon(pts, PAPER)
			draw_line(Vector2(-3, 0), Vector2(5, 0), Color("b8b4c8"), 1.0)
		"giz":
			draw_set_transform(up)
			draw_circle(Vector2.ZERO, 4.0, OUTLINE)
			draw_circle(Vector2.ZERO, 3.0, Color("fff4b0"))
			draw_rect(Rect2(-1, -2, 1, 1), Color.WHITE)
		"digito":
			draw_set_transform(up)
			draw_rect(Rect2(-4, -6, 9, 11), OUTLINE)
			draw_rect(Rect2(-3, -5, 7, 9), Color("a8d8a0"))
			draw_string(ThemeDB.fallback_font, Vector2(-3, 3), digit, HORIZONTAL_ALIGNMENT_CENTER, 7, 9, OUTLINE)
		"calculadora":
			draw_set_transform(up - Vector2(0, 4), _spin * 0.6, Vector2.ONE)
			draw_rect(Rect2(-7, -10, 14, 20), OUTLINE)
			draw_rect(Rect2(-6, -9, 12, 18), Color("4a4a58"))
			draw_rect(Rect2(-5, -8, 10, 5), Color("a8d8a0"))
			for r in 3:
				for cc in 3:
					draw_rect(Rect2(-5 + cc * 3.5, -1 + r * 3.2, 2.5, 2.2), Color("d8d8e0") if (r + cc) % 3 != 0 else Color("ff8a4a"))
		_:
			draw_set_transform(up, _spin, Vector2.ONE)
			draw_circle(Vector2.ZERO, 4.5, OUTLINE)
			draw_circle(Vector2.ZERO, 3.5, PAPER)
			draw_rect(Rect2(-2, -1, 1, 1), Color("a8a4b8"))
			draw_rect(Rect2(1, 1, 1, 1), Color("a8a4b8"))
			draw_rect(Rect2(0, -2, 1, 1), Color("ff7a6a"))
