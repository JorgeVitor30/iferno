extends Node2D
## Porta de uma sala. Aberta é só um vão na parede. Quando a sala tranca,
## desce uma grade de aço com fita zebrada de "INTERDITADO" e vira parede sólida.
## A origem do nó fica embaixo do vão (pra ordenar certo com o jogador).

const OUTLINE := Color("1a1020")
const BAR := Color("8a90a0")
const BAR_LIGHT := Color("c8ccd8")
const TAPE_Y := Color("ffd23f")

var gap := Rect2()      # vão em coordenadas globais
var side := Vector2i.UP # em qual parede da sala a porta está
var _amount := 0.0      # 0 = aberta, 1 = fechada
var _body := StaticBody2D.new()
var _col := CollisionShape2D.new()

func setup(r: Rect2, wall_side: Vector2i) -> void:
	gap = r
	side = wall_side
	position = Vector2(r.position.x, r.end.y)
	var rect := RectangleShape2D.new()
	rect.size = r.size
	_col.shape = rect
	_col.position = Vector2(r.size.x / 2.0, -r.size.y / 2.0)
	_col.disabled = true
	_body.add_child(_col)
	add_child(_body)

func close() -> void:
	_col.set_deferred("disabled", false)
	var tw := create_tween()
	tw.tween_property(self, "_amount", 1.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): Fx.burst(get_parent(), position + Vector2(gap.size.x / 2.0, -2), Color("b8b0a0"), 10, 50.0))

func open() -> void:
	_col.set_deferred("disabled", true)
	create_tween().tween_property(self, "_amount", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)

func _process(_delta: float) -> void:
	if _amount > 0.0 or _amount != _last:
		queue_redraw()
	_last = _amount

var _last := -1.0

func _draw() -> void:
	if _amount <= 0.0:
		return
	var w := gap.size.x
	var h := gap.size.y
	if side == Vector2i.LEFT or side == Vector2i.RIGHT:
		# Porta na parede lateral (vista de cima): grade em pé ocupando o vão.
		var hh := h * _amount
		draw_rect(Rect2(-1, -h - 1, w + 2, hh + 2), OUTLINE)
		draw_rect(Rect2(0, -h, w, hh), BAR)
		var y := -h + 2.0
		while y < -h + hh - 2:
			draw_rect(Rect2(1, y, w - 2, 2), BAR_LIGHT)
			y += 6.0
		_tape(Rect2(-2, -h + hh / 2.0 - 3, w + 4, 6))
		return
	# Porta em cima/embaixo: grade de barras descendo do alto.
	var tall := maxf(h, 30.0)
	var top := -tall
	var hh2 := tall * _amount
	draw_rect(Rect2(-1, top - 1, w + 2, 4), OUTLINE)
	draw_rect(Rect2(0, top, w, 2), BAR)
	var x := 2.0
	while x < w - 2:
		draw_rect(Rect2(x - 1, top, 4, hh2 + 1), OUTLINE)
		draw_rect(Rect2(x, top, 2, hh2), BAR)
		draw_rect(Rect2(x, top, 1, hh2), BAR_LIGHT)
		x += 6.0
	if _amount > 0.6:
		_tape(Rect2(-3, top + tall * 0.45, w + 6, 7))

## Fita zebrada amarela e preta.
func _tape(r: Rect2) -> void:
	draw_rect(r.grow(1.0), OUTLINE)
	draw_rect(r, TAPE_Y)
	var x := r.position.x
	var i := 0
	while x < r.end.x:
		if i % 2 == 0:
			var w := minf(4.0, r.end.x - x)
			draw_rect(Rect2(x, r.position.y, w, r.size.y), OUTLINE)
		x += 4.0
		i += 1
