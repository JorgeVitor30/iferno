extends Node2D
## Área de perigo no chão (ataques de gráfico do professor de estatística).
## Primeiro pisca um aviso vermelho; depois "sobe" o gráfico e quem estiver em cima toma dano.
##   "barra"  coluna de histograma (retângulo)
##   "ponto"  ponto de gráfico de dispersão (círculo), que ainda solta 4 gizes ao estourar
## Rolar (dodge) na hora do golpe também livra.

const OUTLINE := Color("1a1020")
const WARN := Color(1.0, 0.25, 0.25)
const CHALK := Color("fff4b0")

var kind := "barra"
var size := Vector2(28, 120) # barra: largura x altura da área (origem = meio da base)
var radius := 12.0           # ponto
var warn_time := 0.9
var color := Color("6ab0e0")
var _t := 0.0
var _struck := false
const RISE := 0.35 # quanto tempo a barra fica de pé depois do golpe

func _ready() -> void:
	z_index = -4

func _process(delta: float) -> void:
	_t += delta
	if not _struck and _t >= warn_time:
		_struck = true
		_strike()
	if _t >= warn_time + RISE:
		queue_free()
	queue_redraw()

func _area_has(p: Vector2) -> bool:
	if kind == "barra":
		return Rect2(position - Vector2(size.x / 2.0, size.y), size).grow(3).has_point(p)
	return position.distance_to(p) <= radius + 4.0

func _strike() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.visible and _area_has(player.position):
		if not (player.has_method("is_rolling") and player.is_rolling()):
			player.take_damage(1)
	var parent := get_parent()
	if kind == "barra":
		Fx.burst(parent, position + Vector2(0, -size.y / 2.0), color, 10, 70.0, 2.0)
	else:
		Fx.burst(parent, position, CHALK, 8, 60.0, 2.0)
		for i in 4:
			var b: Area2D = preload("res://scripts/enemy_bullet.gd").new()
			b.kind = "giz"
			b.direction = Vector2.from_angle(PI / 4.0 + i * PI / 2.0)
			b.speed = 70.0
			b.lifetime = 2.0
			b.position = position + b.direction * 4.0
			parent.call_deferred("add_child", b)

func _draw() -> void:
	if not _struck:
		var blink := 0.25 + 0.25 * float(int(_t * 12.0) % 2)
		var grow := clampf(_t / warn_time, 0.0, 1.0)
		if kind == "barra":
			var r := Rect2(-size.x / 2.0, -size.y, size.x, size.y)
			draw_rect(r, Color(WARN, blink * 0.6))
			draw_rect(r, Color(WARN, 0.9), false, 1.0)
			# o "enchimento" mostra quanto falta pro golpe
			draw_rect(Rect2(r.position.x, r.end.y - r.size.y * grow, r.size.x, r.size.y * grow), Color(WARN, 0.25))
		else:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, radius, Color(WARN, blink * 0.6))
			draw_arc(Vector2.ZERO, radius * grow, 0.0, TAU, 16, Color(WARN, 0.9), 1.0)
			draw_set_transform(Vector2.ZERO)
			draw_line(Vector2(-4, -4), Vector2(4, 4), Color(WARN, 0.9), 2.0)
			draw_line(Vector2(-4, 4), Vector2(4, -4), Color(WARN, 0.9), 2.0)
		return
	var k := 1.0 - (_t - warn_time) / RISE # some aos poucos
	if kind == "barra":
		# barra de histograma subindo (desenhada em pé, com sombra no chão)
		var h := size.y * minf((_t - warn_time) / 0.08, 1.0)
		var r := Rect2(-size.x / 2.0, -h, size.x, h)
		draw_rect(Rect2(-size.x / 2.0, -size.y, size.x, size.y), Color(0, 0, 0, 0.25 * k))
		draw_rect(r.grow(1), Color(OUTLINE, k))
		draw_rect(r, Color(color, k))
		draw_rect(Rect2(r.position.x, r.position.y, 3, r.size.y), Color(color.lightened(0.35), k))
		draw_rect(Rect2(r.end.x - 3, r.position.y, 3, r.size.y), Color(color.darkened(0.3), k))
	else:
		draw_circle(Vector2(0, -2), radius * 0.6, Color(OUTLINE, k))
		draw_circle(Vector2(0, -2), radius * 0.45, Color(CHALK, k))
