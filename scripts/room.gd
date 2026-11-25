class_name Room
extends Node2D
## Uma sala do andar: monta chão, paredes (com vãos de porta), móveis e decoração,
## e cuida do combate: quando o jogador entra numa sala não liberada, as portas
## trancam e os inimigos aparecem em ondas. Mata todo mundo -> portas abrem.

signal entered(room: Room)
signal cleared_room(room: Room)

const FLOOR_TEX := preload("res://assets/tilesets/floor_tile.png")
const WALL_TEX := preload("res://assets/tilesets/wall_front.png")
const PROP := preload("res://scripts/prop.gd")
const DOOR := preload("res://scripts/door.gd")
const STAIRS := preload("res://scripts/stairs.gd")
const CAFE := preload("res://scripts/cafe.gd")
const ENEMIES := {
	"zelador": preload("res://scripts/enemies/zelador.gd"),
	"veterano": preload("res://scripts/enemies/veterano.gd"),
	"professor": preload("res://scripts/enemies/professor.gd"),
	"estagiario": preload("res://scripts/enemies/estagiario.gd"),
	"coordenadora": preload("res://scripts/enemies/coordenadora.gd"),
}
const COST := {"estagiario": 2, "zelador": 2, "veterano": 3, "professor": 3, "coordenadora": 8}

const FACE := 31.0   # altura da face da parede de cima
const CAP := 8.0     # espessura do topo escuro das paredes
const DOOR_W := 48.0 # largura dos vãos de porta e corredores
const CAP_COLOR := Color("1c1420")
const OUTLINE := Color("1a1020")

## Tipos de sala: tamanho do chão, cor do piso, inimigos mais comuns, frase ao trancar.
const KINDS := {
	"hall": {"size": Vector2(480, 304), "tint": Color(1.0, 0.97, 0.92), "pool": [],
		"lock": ""},
	"sala_aula": {"size": Vector2(496, 320), "tint": Color(1.0, 1.0, 1.0),
		"pool": ["professor", "estagiario", "estagiario", "zelador", "veterano"],
		"lock": "CHAMADA! NINGUÉM SAI!"},
	"biblioteca": {"size": Vector2(560, 352), "tint": Color(0.86, 0.72, 0.58),
		"pool": ["professor", "professor", "estagiario", "zelador"],
		"lock": "SILÊNCIO NA BIBLIOTECA!"},
	"laboratorio": {"size": Vector2(496, 320), "tint": Color(0.84, 0.94, 1.0),
		"pool": ["estagiario", "veterano", "veterano", "professor"],
		"lock": "EXPERIMENTO FORA DE CONTROLE!"},
	"cantina": {"size": Vector2(576, 336), "tint": Color(1.0, 0.9, 0.78),
		"pool": ["zelador", "zelador", "veterano", "estagiario"],
		"lock": "BRIGA NA FILA DO PF!"},
	"sala_prof": {"size": Vector2(432, 288), "tint": Color(0.9, 0.86, 1.0),
		"pool": ["professor", "professor", "estagiario", "veterano"],
		"lock": "REUNIÃO DE EMERGÊNCIA!"},
	"xerox": {"size": Vector2(432, 288), "tint": Color(0.9, 0.9, 0.92),
		"pool": ["estagiario", "estagiario", "professor", "zelador"],
		"lock": "PAPEL PRA TODO LADO!"},
	"escadaria": {"size": Vector2(528, 336), "tint": Color(0.8, 0.8, 0.88),
		"pool": ["professor", "zelador", "veterano", "estagiario"],
		"lock": "A COORDENAÇÃO BARROU A ESCADA!"},
}
const SUBJECTS := ["Cálculo I", "Física II", "Álgebra Linear", "Estatística", "Programação",
	"Química Orgânica", "Filosofia", "Economia", "Anatomia", "Direito Civil"]
const BOARD_TEXTS := ["PROVA HOJE!", "LISTA 7 P/ ONTEM", "F = m . a", "TRABALHO EM GRUPO",
	"NÃO VAI CAIR NA PROVA", "x = -b +- raiz(D) / 2a", "CHAMADA: 3 FALTAS = DP"]
const CLEAR_TEXTS := ["AULA DISPENSADA!", "APROVADO!", "PASSOU RASPANDO!", "MATÉRIA ELIMINADA!"]

var grid := Vector2i.ZERO
var kind := "sala_aula"
var rect := Rect2()          # chão andável
var sides: Array[Vector2i] = [] # lados com porta
var title := ""
var floor_level := 1
var cleared := false
var visited := false
var entities: Node2D          # onde vão móveis, inimigos, portas (y-sort)

var _waves: Array = []
var _wave := 0
var _alive := 0
var _active := false
var _doors: Array[Node2D] = []
var _footprints: Array[Rect2] = []
var _board_text := ""

func setup(g: Vector2i, k: String, center: Vector2, lvl: int, ents: Node2D) -> void:
	grid = g
	kind = k
	floor_level = lvl
	entities = ents
	var size: Vector2 = KINDS[k]["size"]
	# Sem arredondar: o centro do chão tem que bater com o centro da célula,
	# senão as portas de salas vizinhas não ficam alinhadas com o corredor.
	rect = Rect2(center - size / 2.0, size)
	match k:
		"hall": title = "PORTARIA"
		"sala_aula": title = "SALA %d · %s" % [floor_level * 100 + randi_range(1, 30), SUBJECTS.pick_random()]
		"biblioteca": title = "BIBLIOTECA"
		"laboratorio": title = "LABORATÓRIO DE QUÍMICA"
		"cantina": title = "CANTINA"
		"sala_prof": title = "SALA DOS PROFESSORES"
		"xerox": title = "XEROX"
		"escadaria": title = "ESCADARIA"
	_board_text = BOARD_TEXTS.pick_random()
	cleared = k == "hall"

func has_side(s: Vector2i) -> bool:
	return sides.has(s)

## Monta tudo. Chamar depois de preencher `sides`.
func build() -> void:
	z_index = -10
	var r := rect
	var tint: Color = KINDS[kind]["tint"]
	_tiled(FLOOR_TEX, r, tint)
	var cx := r.get_center().x
	var cy := r.get_center().y
	var face := Rect2(r.position.x, r.position.y - FACE, r.size.x, FACE)
	if has_side(Vector2i.UP):
		_tiled(WALL_TEX, Rect2(face.position.x, face.position.y, cx - DOOR_W / 2.0 - face.position.x, FACE), Color.WHITE)
		_tiled(WALL_TEX, Rect2(cx + DOOR_W / 2.0, face.position.y, face.end.x - cx - DOOR_W / 2.0, FACE), Color.WHITE)
	else:
		_tiled(WALL_TEX, face, Color.WHITE)
	# Decoração do chão (tapetes) e da parede (quadro, relógio, cartazes)
	var floor_decor := Node2D.new()
	floor_decor.draw.connect(_draw_floor_decor.bind(floor_decor))
	add_child(floor_decor)
	var wall_decor := Node2D.new()
	wall_decor.z_index = 2 # por cima dos corredores
	wall_decor.draw.connect(_draw_wall_decor.bind(wall_decor))
	add_child(wall_decor)
	_build_walls(cx, cy)
	_build_doors(cx, cy)
	_furnish(cx, cy)
	_plan_waves()
	# Gatilho: entrar de verdade na sala (não só pisar no vão da porta)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size - Vector2(40, 40)
	col.shape = shape
	col.position = r.get_center()
	area.add_child(col)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _tiled(tex: Texture2D, r: Rect2, tint: Color) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size)
	s.position = r.position
	s.modulate = tint
	add_child(s)

func _wall(r: Rect2) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = r.size
	col.shape = box
	body.position = r.get_center()
	body.add_child(col)
	add_child(body)

## Parede horizontal ou vertical com um vão no meio (se tiver porta).
func _wall_with_gap(r: Rect2, has_gap: bool, horizontal: bool, center: float) -> void:
	if not has_gap:
		_wall(r)
		return
	var h := DOOR_W / 2.0
	if horizontal:
		_wall(Rect2(r.position.x, r.position.y, center - h - r.position.x, r.size.y))
		_wall(Rect2(center + h, r.position.y, r.end.x - center - h, r.size.y))
	else:
		_wall(Rect2(r.position.x, r.position.y, r.size.x, center - h - r.position.y))
		_wall(Rect2(r.position.x, center + h, r.size.x, r.end.y - center - h))

func _build_walls(cx: float, cy: float) -> void:
	var r := rect
	_wall_with_gap(Rect2(r.position.x - CAP, r.position.y - FACE - CAP, r.size.x + CAP * 2, FACE + CAP),
		has_side(Vector2i.UP), true, cx)
	_wall_with_gap(Rect2(r.position.x - CAP, r.end.y, r.size.x + CAP * 2, CAP),
		has_side(Vector2i.DOWN), true, cx)
	_wall_with_gap(Rect2(r.position.x - CAP, r.position.y - FACE, CAP, r.size.y + FACE),
		has_side(Vector2i.LEFT), false, cy)
	_wall_with_gap(Rect2(r.end.x, r.position.y - FACE, CAP, r.size.y + FACE),
		has_side(Vector2i.RIGHT), false, cy)

func _build_doors(cx: float, cy: float) -> void:
	var r := rect
	var h := DOOR_W / 2.0
	for s in sides:
		var gap := Rect2()
		match s:
			Vector2i.UP: gap = Rect2(cx - h, r.position.y - FACE - CAP, DOOR_W, FACE + CAP)
			Vector2i.DOWN: gap = Rect2(cx - h, r.end.y, DOOR_W, CAP)
			Vector2i.LEFT: gap = Rect2(r.position.x - CAP, cy - h, CAP, DOOR_W)
			Vector2i.RIGHT: gap = Rect2(r.end.x, cy - h, CAP, DOOR_W)
		var d: Node2D = DOOR.new()
		d.setup(gap, s)
		entities.add_child(d)
		_doors.append(d)

func _draw() -> void:
	# Topo escuro de todas as paredes em volta da sala
	var r := rect
	draw_rect(Rect2(r.position.x - CAP, r.position.y - FACE - CAP, r.size.x + CAP * 2, r.size.y + FACE + CAP * 2), CAP_COLOR)
	if kind == "hall":
		# Porta de vidro da entrada principal (por onde o jogador chegou)
		var cx := r.get_center().x
		draw_rect(Rect2(cx - 34, r.end.y, 68, CAP), Color("5a8ab0"))
		draw_rect(Rect2(cx - 1, r.end.y, 2, CAP), OUTLINE)
		draw_rect(Rect2(cx - 30, r.end.y + 2, 10, 2), Color("bfe3ff"))

# ---------------------------------------------------------------- móveis

func _lane_blocked(fp: Rect2) -> bool:
	var c := rect.get_center()
	# Cruz livre no meio (caminho entre as portas e espaço pra lutar)
	if fp.end.x > c.x - 40 and fp.position.x < c.x + 40:
		return true
	if fp.end.y > c.y - 36 and fp.position.y < c.y + 36:
		return true
	return false

func _prop(k: String, base: Vector2, ignore_lanes: bool = false) -> bool:
	base = base.round()
	var fp: Rect2 = PROP.footprint(k, base)
	var solid := Rect2(fp.position.x, base.y - 12, fp.size.x, 12)
	if not rect.grow(-6).encloses(Rect2(solid.position.x, base.y - 2, solid.size.x, 2)):
		return false
	if not ignore_lanes and _lane_blocked(Rect2(fp.position.x, base.y - 12, fp.size.x, 12)):
		return false
	for other in _footprints:
		if other.grow(4).intersects(fp):
			return false
	var p: StaticBody2D = PROP.new()
	p.kind = k
	p.position = base
	entities.add_child(p)
	_footprints.append(fp)
	return true

func _grid(k: String, x0: float, y0: float, x1: float, y1: float, step: Vector2, chance: float = 1.0) -> void:
	var y := y0
	while y <= y1:
		var x := x0
		while x <= x1:
			if randf() <= chance:
				_prop(k, Vector2(x, y))
			x += step.x
		y += step.y

func _furnish(cx: float, cy: float) -> void:
	var r := rect
	var L := r.position.x
	var T := r.position.y
	var R := r.end.x
	var B := r.end.y
	match kind:
		"hall":
			_prop("balcao", Vector2(cx - 130, T + 70))
			_prop("vending", Vector2(R - 40, T + 30))
			_prop("bebedouro", Vector2(L + 30, T + 28))
			for x in [L + 20, R - 20]:
				_prop("vaso", Vector2(x, B - 10), true)
			# linha de catracas com passagem no meio
			var x := L + 60
			while x < R - 50:
				if absf(x - cx) > 44:
					_prop("catraca", Vector2(x, B - 80), true)
				x += 20
		"sala_aula":
			_prop("mesa_prof", Vector2(L + r.size.x * 0.25, T + 40))
			_prop("vaso", Vector2(R - 18, T + 26))
			_grid("carteira", L + 34, T + 92, R - 30, B - 20, Vector2(40, 42))
		"biblioteca":
			_grid("estante", L + 48, T + 60, R - 40, B - 30, Vector2(70, 88))
			_prop("vaso", Vector2(L + 16, B - 10))
			_prop("vaso", Vector2(R - 16, B - 10))
			_prop("mesa_prof", Vector2(cx + 100, T + 34))
		"laboratorio":
			_prop("armarios", Vector2(L + 40, T + 14))
			_prop("armarios", Vector2(R - 40, T + 14))
			_grid("bancada", L + 50, T + 100, R - 48, B - 24, Vector2(92, 76))
		"cantina":
			_prop("vending", Vector2(L + 30, T + 26))
			_prop("vending", Vector2(L + 60, T + 26))
			_prop("cafeteira", Vector2(R - 40, T + 30))
			_grid("mesa_cantina", L + 56, T + 90, R - 56, B - 24, Vector2(108, 62))
		"sala_prof":
			_prop("sofa", Vector2(L + 50, T + 34))
			_prop("cafeteira", Vector2(R - 40, T + 30))
			_prop("estante", Vector2(R - 90, T + 24))
			_grid("mesa_cantina", L + 60, T + 110, R - 60, B - 30, Vector2(120, 90))
			_prop("vaso", Vector2(L + 16, B - 10))
		"xerox":
			var x := L + 30
			while x < R - 20:
				_prop("copiadora", Vector2(x, T + 26))
				x += 44
			for i in 10:
				_prop("pilha_papel", Vector2(randf_range(L + 20, R - 20), randf_range(T + 70, B - 16)))
		"escadaria":
			_prop("armarios", Vector2(L + 36, T + 14))
			_prop("armarios", Vector2(R - 36, T + 14))
			for i in 6:
				_prop("pilha_papel", Vector2(randf_range(L + 20, R - 20), randf_range(T + 70, B - 16)))
			_prop("vaso", Vector2(L + 16, B - 10))
			_prop("vaso", Vector2(R - 16, B - 10))

# ---------------------------------------------------------------- decoração desenhada

func _draw_floor_decor(n: Node2D) -> void:
	var r := rect
	var c := r.get_center()
	match kind:
		"hall":
			# tapete vermelho da porta até o meio
			n.draw_rect(Rect2(c.x - 22, c.y - 40, 44, r.end.y - c.y + 40), Color("8a2a2a"))
			n.draw_rect(Rect2(c.x - 20, c.y - 40, 40, r.end.y - c.y + 40), Color("b83a3a"))
			n.draw_rect(Rect2(c.x - 30, r.end.y - 14, 60, 12), Color("4a4040")) # capacho
			Fx.text(n, Vector2(c.x - 30, r.end.y - 5), "BEM-VINDO", Color("c8b8a0"), 7, 60, HORIZONTAL_ALIGNMENT_CENTER)
		"biblioteca", "sala_prof":
			var rug := Rect2(c.x - 70, c.y - 46, 140, 92)
			n.draw_rect(rug, Color("5a2a4a"))
			n.draw_rect(rug.grow(-3), Color("7a3a5a"))
			n.draw_rect(rug.grow(-10), Color("5a2a4a"))
		"laboratorio":
			# faixa de segurança no chão
			var y := c.y + 30
			var x := r.position.x + 8
			var i := 0
			while x < r.end.x - 8:
				n.draw_rect(Rect2(x, y, 8, 4), Color("ffd23f") if i % 2 == 0 else Color("2a2030"))
				x += 8
				i += 1

func _draw_wall_decor(n: Node2D) -> void:
	var r := rect
	var fy := r.position.y - FACE
	var left := r.position.x + r.size.x * 0.25
	var right := r.position.x + r.size.x * 0.75
	var mid := r.get_center().x
	var center_free := not has_side(Vector2i.UP)
	match kind:
		"hall":
			_banner(n, mid if center_free else left, fy, "BEM-VINDO, CALOURO!")
			_clock(n, right, fy)
		"sala_aula":
			_blackboard(n, left, fy, _board_text)
			_clock(n, right, fy)
		"biblioteca":
			_plaque(n, left, fy, "SILÊNCIO", Color("2a3a5a"))
			_plaque(n, right, fy, "DEVOLVA OS LIVROS", Color("5a2a2a"))
		"laboratorio":
			_periodic(n, left, fy)
			_hazard(n, right, fy)
		"cantina":
			_menu(n, left, fy)
			_clock(n, right, fy)
		"sala_prof":
			_cork(n, left, fy)
			_plaque(n, right, fy, "SALA DOS PROFESSORES", Color("3a2a4a"))
		"xerox":
			_plaque(n, left, fy, "XEROX  R$0,25", Color("2a4a3a"))
			_plaque(n, right, fy, "NÃO TIRAMOS CÓPIA DE LIVRO", Color("5a2a2a"))
		"escadaria":
			_exit_sign(n, left, fy)
			_plaque(n, right, fy, "%dº ANDAR" % (floor_level + 1), Color("2a3a5a"))

func _blackboard(n: Node2D, x: float, fy: float, text: String) -> void:
	var b := Rect2(x - 52, fy + 4, 104, 20)
	n.draw_rect(b.grow(2), Color("7a5236"))
	n.draw_rect(b, Color("2a4a3a"))
	Fx.text(n, Vector2(b.position.x, b.position.y + 13), text, Color("e8f0e0"), 8, b.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	n.draw_rect(Rect2(b.position.x, b.end.y + 2, b.size.x, 2), Color("b08850"))
	n.draw_rect(Rect2(b.position.x + 10, b.end.y + 1, 4, 1), Color("f4efe2")) # giz

func _clock(n: Node2D, x: float, fy: float) -> void:
	var c := Vector2(x, fy + 13)
	n.draw_circle(c, 7.0, OUTLINE)
	n.draw_circle(c, 6.0, Color("f4efe2"))
	var t := Time.get_ticks_msec() / 1000.0
	n.draw_line(c, c + Vector2.from_angle(t * 0.5 - PI / 2) * 4.0, OUTLINE, 1.0)
	n.draw_line(c, c + Vector2.from_angle(t * 0.05 - PI / 2) * 3.0, OUTLINE, 1.0)

func _plaque(n: Node2D, x: float, fy: float, text: String, bg: Color) -> void:
	var w := maxf(text.length() * 5.0 + 10.0, 40.0)
	var b := Rect2(x - w / 2.0, fy + 8, w, 12)
	n.draw_rect(b.grow(1), OUTLINE)
	n.draw_rect(b, bg)
	Fx.text(n, Vector2(b.position.x, b.position.y + 9), text, Color("f4e4c0"), 7, w, HORIZONTAL_ALIGNMENT_CENTER)

func _banner(n: Node2D, x: float, fy: float, text: String) -> void:
	var w := 130.0
	var b := Rect2(x - w / 2.0, fy + 5, w, 15)
	n.draw_rect(b.grow(1), OUTLINE)
	n.draw_rect(b, Color("b83a3a"))
	n.draw_rect(Rect2(b.position.x, b.end.y - 2, w, 2), Color("8a2a2a"))
	Fx.text(n, Vector2(b.position.x, b.position.y + 11), text, Color("ffd966"), 8, w, HORIZONTAL_ALIGNMENT_CENTER)

func _periodic(n: Node2D, x: float, fy: float) -> void:
	var b := Rect2(x - 30, fy + 5, 60, 20)
	n.draw_rect(b.grow(1), OUTLINE)
	n.draw_rect(b, Color("f4efe2"))
	for row in 4:
		for col in 12:
			if row == 0 and col > 0 and col < 11:
				continue
			var hue := fmod(col * 0.08 + row * 0.05, 1.0)
			n.draw_rect(Rect2(b.position.x + 2 + col * 4.7, b.position.y + 2 + row * 4.4, 4, 3.5), Color.from_hsv(hue, 0.5, 0.9))

func _hazard(n: Node2D, x: float, fy: float) -> void:
	var p := Vector2(x, fy + 4)
	n.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -1), p + Vector2(-12, 21), p + Vector2(12, 21)]), OUTLINE)
	n.draw_colored_polygon(PackedVector2Array([p + Vector2(0, 2), p + Vector2(-9, 19), p + Vector2(9, 19)]), Color("ffd23f"))
	n.draw_rect(Rect2(x - 1, fy + 9, 2, 6), OUTLINE)
	n.draw_rect(Rect2(x - 1, fy + 17, 2, 2), OUTLINE)

func _menu(n: Node2D, x: float, fy: float) -> void:
	var b := Rect2(x - 36, fy + 3, 72, 24)
	n.draw_rect(b.grow(2), Color("7a5236"))
	n.draw_rect(b, Color("2a2a30"))
	Fx.text(n, Vector2(b.position.x + 3, b.position.y + 9), "PF ..... R$18", Color("ffd966"), 7)
	Fx.text(n, Vector2(b.position.x + 3, b.position.y + 18), "SUCO ... R$6", Color("f4efe2"), 7)

func _cork(n: Node2D, x: float, fy: float) -> void:
	var b := Rect2(x - 32, fy + 4, 64, 22)
	n.draw_rect(b.grow(2), Color("7a5236"))
	n.draw_rect(b, Color("c8945a"))
	var cols := [Color("ffd966"), Color("ff9aa8"), Color("9ad8ff"), Color("f4efe2"), Color("b8f0a0")]
	for i in 6:
		var p := Vector2(b.position.x + 3 + i * 10, b.position.y + 3 + (i % 2) * 8)
		n.draw_rect(Rect2(p, Vector2(8, 8)), cols[i % cols.size()])
		n.draw_rect(Rect2(p + Vector2(3, 0), Vector2(2, 2)), Color("d93a3a"))

func _exit_sign(n: Node2D, x: float, fy: float) -> void:
	var b := Rect2(x - 22, fy + 8, 44, 13)
	n.draw_rect(b.grow(1), OUTLINE)
	n.draw_rect(b, Color("2a9a4a"))
	Fx.text(n, Vector2(b.position.x, b.position.y + 10), "SAÍDA", Color("f4efe2"), 8, 44, HORIZONTAL_ALIGNMENT_CENTER)

# ---------------------------------------------------------------- combate

func _plan_waves() -> void:
	_waves.clear()
	if kind == "hall":
		return
	var pool: Array = KINDS[kind]["pool"]
	# Orçamento de "custo" de inimigos: andar 1 dá ~5-6 inimigos em 2 ondas.
	var budget := 9 + floor_level * 3 + randi_range(0, 3)
	if kind == "escadaria":
		_waves.append(_make_wave(pool, 6 + floor_level * 2))
		_waves.append(["coordenadora", "estagiario", "zelador"])
		return
	if budget >= 10:
		var first := budget / 2
		_waves.append(_make_wave(pool, first))
		_waves.append(_make_wave(pool, budget - first))
	else:
		_waves.append(_make_wave(pool, budget))

func _make_wave(pool: Array, budget: int) -> Array:
	var wave: Array = []
	var guard := 0
	while budget > 0 and guard < 50:
		guard += 1
		var t: String = pool.pick_random()
		var c: int = COST[t]
		if c <= budget or (wave.is_empty() and guard > 20):
			wave.append(t)
			budget -= c
	return wave

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	visited = true
	entered.emit(self)
	if cleared or _active or _waves.is_empty():
		return
	_active = true
	for d in _doors:
		d.close()
	Fx.shake(self, 4.0)
	get_tree().call_group("hud", "banner", KINDS[kind]["lock"], Color("ff5a4a"))
	await get_tree().create_timer(0.5).timeout
	_spawn_wave(0)

func _spawn_wave(i: int) -> void:
	_wave = i
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for t: String in _waves[i]:
		var e: Enemy = ENEMIES[t].new()
		e.floor_level = floor_level
		e.position = _spawn_point(player)
		e.died.connect(_on_enemy_died)
		entities.add_child(e)
		_alive += 1
	_update_counter()

func _spawn_point(player: Node2D) -> Vector2:
	var inner := rect.grow(-28)
	inner.position.y += 16 # não nascer colado na parede de cima
	inner.size.y -= 16
	for i in 60:
		var p := Vector2(randf_range(inner.position.x, inner.end.x), randf_range(inner.position.y, inner.end.y))
		if player and p.distance_to(player.global_position) < 120.0:
			continue
		var ok := true
		for fp in _footprints:
			if fp.grow(10).has_point(p):
				ok = false
				break
		if ok:
			return p
	return rect.get_center()

func _remaining() -> int:
	var n := _alive
	for j in range(_wave + 1, _waves.size()):
		n += (_waves[j] as Array).size()
	return n

func _update_counter() -> void:
	get_tree().call_group("hud", "set_counter", _remaining())

func _on_enemy_died(_e: Enemy) -> void:
	_alive -= 1
	_update_counter()
	if _alive > 0:
		return
	if _wave + 1 < _waves.size():
		get_tree().call_group("hud", "banner", "ONDA %d/%d" % [_wave + 2, _waves.size()], Color("ffd966"))
		await get_tree().create_timer(1.0).timeout
		_spawn_wave(_wave + 1)
	else:
		_clear()

func _clear() -> void:
	cleared = true
	_active = false
	for d in _doors:
		d.open()
	get_tree().call_group("hud", "set_counter", -1)
	get_tree().call_group("hud", "banner", CLEAR_TEXTS.pick_random(), Color("3fd17a"))
	if randf() < 0.4 or kind == "escadaria":
		var cafe: Node2D = CAFE.new()
		cafe.position = rect.get_center() + Vector2(0, 50)
		entities.add_child(cafe)
	if kind == "escadaria":
		var st: Area2D = STAIRS.new()
		st.position = Vector2(rect.position.x + rect.size.x * 0.75, rect.position.y + 56)
		st.climbed.connect(func(): get_tree().call_group("level", "next_floor"))
		entities.add_child(st)
	cleared_room.emit(self)
