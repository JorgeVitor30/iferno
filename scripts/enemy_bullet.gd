extends Area2D
## Projétil de papel dos inimigos. A posição do nó é no chão (sombra);
## o desenho voa uns pixels acima, na altura da mão.
##   "prova"   folha de prova girando (com nota vermelha)
##   "aviao"   aviãozinho de papel que vai virando atrás do jogador
##   "bolinha" papel amassado
## Durante o dodge roll o jogador atravessa o papel sem tomar dano.

const OUTLINE := Color("1a1020")
const PAPER := Color("f4efe2")
const HEIGHT := 11.0

var kind := "bolinha"
var direction := Vector2.RIGHT
var speed := 100.0
var homing := 0.0 # rad/s que o aviãozinho consegue virar
var lifetime := 4.0
var _t := 0.0
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
	position += direction * speed * delta
	_spin += delta * (14.0 if kind == "prova" else 9.0)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("is_rolling") and body.is_rolling():
			return # desviou!
		body.take_damage(1)
	_pop()

func _pop() -> void:
	Fx.burst(get_parent(), position + Vector2(0, -HEIGHT), PAPER, 5, 45.0, 1.5)
	queue_free()

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
		_:
			draw_set_transform(up, _spin, Vector2.ONE)
			draw_circle(Vector2.ZERO, 4.5, OUTLINE)
			draw_circle(Vector2.ZERO, 3.5, PAPER)
			draw_rect(Rect2(-2, -1, 1, 1), Color("a8a4b8"))
			draw_rect(Rect2(1, 1, 1, 1), Color("a8a4b8"))
			draw_rect(Rect2(0, -2, 1, 1), Color("ff7a6a"))
