extends Control
## Vida em corações de pixel art. Cada coração = 2 de vida (tem meio coração).
## Perdeu vida: o coração treme e pisca branco. Ganhou: dá um pulinho.
## Com pouca vida, o último coração fica batendo.

const OUTLINE := Color("1a1020")
const RED := Color("e0383f")
const RED_DARK := Color("a01f35")
const SHINE := Color("ffb0a8")
const EMPTY := Color("3a2236")
const EMPTY_DARK := Color("2a1828")
const GAP := 2.0
## Desenho do coração (13x11): # = preenchido
const SHAPE := [
	"..###...###..",
	".#####.#####.",
	"#############",
	"#############",
	"#############",
	".###########.",
	"..#########..",
	"...#######...",
	"....#####....",
	".....###.....",
	"......#......",
]
const W := 13
const H := 11

var max_hp := 6
var hp := 6
var _shake: Array[float] = []
var _pop: Array[float] = []
var _t := 0.0
var _started := false
var _filled := {} # pixels do formato, pra desenhar o contorno

func _ready() -> void:
	for y in H:
		for x in W:
			if SHAPE[y][x] == "#":
				_filled[Vector2i(x, y)] = true

func _hearts() -> int:
	return ceili(max_hp / 2.0)

func set_health(new_hp: int, new_max: int) -> void:
	var old := hp if _started else new_hp # primeira vez: sem animação
	_started = true
	hp = new_hp
	max_hp = new_max
	_shake.resize(_hearts())
	_pop.resize(_hearts())
	for i in _hearts():
		var lo := i * 2
		var hi := lo + 2
		# coração afetado pela mudança de vida
		if new_hp < old and lo < old and hi > new_hp:
			_shake[i] = 0.45
		elif new_hp > old and lo < new_hp and hi > old:
			_pop[i] = 0.3
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	for i in _shake.size():
		_shake[i] = maxf(_shake[i] - delta, 0.0)
		_pop[i] = maxf(_pop[i] - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var low := hp > 0 and hp <= 2
	for i in _hearts():
		var fill := clampi(hp - i * 2, 0, 2) # 0 vazio, 1 metade, 2 cheio
		var origin := Vector2(i * (W + GAP), 0)
		var sc := 1.0
		var flash := false
		if i < _shake.size() and _shake[i] > 0.0:
			origin += Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)).round()
			flash = int(_shake[i] * 20.0) % 2 == 0
		if i < _pop.size() and _pop[i] > 0.0:
			sc = 1.0 + _pop[i]
		# batimento no último coração quando a vida tá baixa
		if low and i == int((hp - 1) / 2.0):
			var beat := fmod(_t * 1.6, 1.0)
			sc *= 1.0 + 0.18 * maxf(0.0, sin(beat * TAU * 2.0)) * (1.0 if beat < 0.5 else 0.0)
		_draw_heart(origin, sc, fill, flash)

func _draw_heart(origin: Vector2, sc: float, fill: int, flash: bool) -> void:
	var center := Vector2(W / 2.0, H / 2.0)
	draw_set_transform(origin + center + Vector2(1, 1), 0.0, Vector2(sc, sc))
	# sombra
	for p: Vector2i in _filled:
		draw_rect(Rect2(Vector2(p) - center + Vector2(1, 1), Vector2.ONE), Color(0, 0, 0, 0.45))
	# contorno
	for p: Vector2i in _filled:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not _filled.has(p + d):
				draw_rect(Rect2(Vector2(p + d) - center, Vector2.ONE), OUTLINE)
	# preenchimento
	for p: Vector2i in _filled:
		var full := fill == 2 or (fill == 1 and p.x <= 6)
		var c := (RED if full else EMPTY)
		if flash:
			c = Color.WHITE
		elif full:
			if p.y >= 7 or p.x + p.y >= 15:
				c = RED_DARK # sombra embaixo/direita
			if (p.y == 1 and (p.x == 2 or p.x == 3)) or (p.y == 2 and p.x == 1):
				c = SHINE # brilho
		elif p.y >= 7 or p.x + p.y >= 15:
			c = EMPTY_DARK
		draw_rect(Rect2(Vector2(p) - center, Vector2.ONE), c)
	draw_set_transform(Vector2.ZERO)
