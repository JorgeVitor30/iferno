class_name BossBar
extends Control
## Barra de vida do chefe, embaixo da tela: nome em cima, barra com moldura
## e um "rastro" branco que desce devagar mostrando o dano que acabou de levar.

const OUTLINE := Color("1a1020")
const FRAME := Color("8a7aa0")
const FRAME_DARK := Color("4a3d5a")
const FILL := Color("d94a4a")
const FILL_DARK := Color("a02a3a")
const TRAIL := Color("fff0d0")
const BAR := Rect2(170, 334, 300, 9)

var _enemy: Node
var _shown := 0.0  # vida mostrada (0..1)
var _trail := 0.0  # rastro branco
var _appear := 0.0
var _filling := false
var _name := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func track(enemy: Node) -> void:
	_enemy = enemy
	_name = enemy.display_name
	_shown = 0.0
	_trail = 0.0
	_appear = 0.0
	_filling = true
	visible = true

func _process(delta: float) -> void:
	if not visible:
		return
	var target := 0.0
	if is_instance_valid(_enemy) and not _enemy.dead:
		target = float(_enemy.hp) / float(_enemy.max_hp)
		_appear = minf(_appear + delta * 2.0, 1.0)
		# enche no começo, depois acompanha a vida
		if _filling:
			_shown = minf(_shown + delta * 1.2, target)
			_filling = _shown < target
		else:
			_shown = target
	else:
		_shown = 0.0
		_appear = maxf(_appear - delta * 1.5, 0.0)
		if _appear <= 0.0:
			visible = false
	_trail = move_toward(_trail, _shown, delta * 0.35) if _trail > _shown else _shown
	queue_redraw()

func _draw() -> void:
	var off := Vector2(0, (1.0 - _appear) * 30.0) # sobe do pé da tela
	var r := Rect2(BAR.position + off, BAR.size)
	# nome
	Fx.ui_text(self, Vector2(r.position.x, r.position.y - 4), _name, FRAME, 9, r.size.x, HORIZONTAL_ALIGNMENT_CENTER, "black")
	# moldura
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size + Vector2(4, 4)), Color(0, 0, 0, 0.4))
	draw_rect(r.grow(3), OUTLINE)
	draw_rect(r.grow(2), FRAME_DARK)
	draw_rect(r.grow(1), FRAME)
	draw_rect(r, OUTLINE)
	var inner := r.grow(-1)
	draw_rect(inner, Color("3a2236"))
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * _trail, inner.size.y)), TRAIL)
	var fill := Rect2(inner.position, Vector2(inner.size.x * _shown, inner.size.y))
	draw_rect(fill, FILL)
	draw_rect(Rect2(fill.position.x, fill.end.y - 2, fill.size.x, 2), FILL_DARK)
	draw_rect(Rect2(fill.position.x, fill.position.y, fill.size.x, 1), Color("ff9a8a"))
	# marquinha dos 50% (quando ele fica bravo)
	draw_rect(Rect2(inner.position.x + inner.size.x * 0.5, inner.position.y - 1, 1, inner.size.y + 2), FRAME)
	# cantinhos
	for p in [r.position - Vector2(4, 4), Vector2(r.end.x + 1, r.position.y - 4), Vector2(r.position.x - 4, r.end.y + 1), r.end + Vector2(1, 1)]:
		draw_rect(Rect2(p, Vector2(3, 3)), FRAME)
