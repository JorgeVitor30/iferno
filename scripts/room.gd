class_name Room
extends Node2D
## Uma sala do andar: monta chão, paredes (com vãos de porta), móveis e decoração,
## e cuida do combate: quando o jogador entra numa sala não liberada, as portas
## trancam e os inimigos aparecem em ondas. Mata todo mundo -> portas abrem.

signal entered(room: Room)
signal cleared_room(room: Room)

const FLOOR_TEX := preload("res://assets/tilesets/clean/floor.png")
const WALL_TEX := preload("res://assets/tilesets/clean/wall.png")
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
	"prof_estatistica": preload("res://scripts/enemies/prof_estatistica.gd"),
}
const COST := {"estagiario": 2, "zelador": 2, "veterano": 3, "professor": 3, "coordenadora": 8}

const FACE := 48.0   # altura da face da parede de cima (parede alta = profundidade)
const CAP := 8.0     # espessura do topo escuro das paredes
const DOOR_W := 48.0 # largura dos vãos de porta e corredores
const CAP_COLOR := Color("150b1f")
const OUTLINE := Color("0b0612")
const MIN_SIZE := Vector2(496, 336)
const MAX_SIZE := Vector2(832, 512) # cabe na célula do andar com corredor sobrando

## Tipos de sala: tamanho base (sorteado em volta disso), cor do piso,
## inimigos mais comuns e frase ao trancar.
const KINDS := {
	"hall": {"size": Vector2(624, 400), "tint": Color(1.0, 0.98, 1.0), "pool": [],
		"lock": ""},
	"sala_aula": {"size": Vector2(640, 416), "tint": Color(1.0, 1.0, 1.0),
		"pool": ["professor", "estagiario", "estagiario", "zelador", "veterano"],
		"lock": "CHAMADA! NINGUÉM SAI!"},
	"biblioteca": {"size": Vector2(736, 464), "tint": Color(1.08, 0.94, 0.86),
		"pool": ["professor", "professor", "estagiario", "zelador"],
		"lock": "SILÊNCIO NA BIBLIOTECA!"},
	"laboratorio": {"size": Vector2(640, 416), "tint": Color(0.9, 1.0, 1.08),
		"pool": ["estagiario", "veterano", "veterano", "professor"],
		"lock": "EXPERIMENTO FORA DE CONTROLE!"},
	"cantina": {"size": Vector2(752, 432), "tint": Color(1.08, 0.97, 0.9),
		"pool": ["zelador", "zelador", "veterano", "estagiario"],
		"lock": "BRIGA NA FILA DO PF!"},
	"sala_prof": {"size": Vector2(560, 368), "tint": Color(1.0, 0.94, 1.06),
		"pool": ["professor", "professor", "estagiario", "veterano"],
		"lock": "REUNIÃO DE EMERGÊNCIA!"},
	"xerox": {"size": Vector2(560, 368), "tint": Color(0.96, 0.96, 1.0),
		"pool": ["estagiario", "estagiario", "professor", "zelador"],
		"lock": "PAPEL PRA TODO LADO!"},
	"informatica": {"size": Vector2(672, 416), "tint": Color(0.88, 0.94, 1.1),
		"pool": ["estagiario", "estagiario", "veterano", "professor"],
		"lock": "O SISTEMA CAIU!"},
	"banheiro": {"size": Vector2(544, 352), "tint": Color(0.86, 1.02, 1.06),
		"pool": ["zelador", "zelador", "veterano", "estagiario"],
		"lock": "INTERDITADO PRA LIMPEZA!"},
	"auditorio": {"size": Vector2(832, 496), "tint": Color(0.92, 0.86, 1.0),
		"pool": [], "lock": "PROVA FINAL!"},
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
var elite_room := false       # a coordenadora aparece na última onda
var entities: Node2D          # onde vão móveis, inimigos, portas (y-sort)

var _waves: Array = []
var _wave := 0
var _alive := 0
var _active := false
var _doors: Array[Node2D] = []
var _footprints: Array[Rect2] = []
var _board_text := ""
var _clearing := 40.0        # raio do espaço livre no meio (sorteado)
var _swap := false           # inverte esquerda/direita da decoração
var _rug := false

func setup(g: Vector2i, k: String, center: Vector2, lvl: int, ents: Node2D) -> void:
	grid = g
	kind = k
	floor_level = lvl
	entities = ents
	var size: Vector2 = KINDS[k]["size"]
	if k != "auditorio" and k != "hall":
		# Tamanho sorteado em passos de 32px em volta do tamanho base
		size += Vector2(randi_range(-3, 3), randi_range(-2, 2)) * 32.0
		size = size.clamp(MIN_SIZE, MAX_SIZE)
	# Sem arredondar: o centro do chão tem que bater com o centro da célula,
	# senão as portas de salas vizinhas não ficam alinhadas com o corredor.
	rect = Rect2(center - size / 2.0, size)
	match k:
		"hall": title = "PORTARIA"
		"sala_aula": title = "SALA %d · %s" % [floor_level * 100 + randi_range(1, 30), SUBJECTS.pick_random()]
		"biblioteca": title = "BIBLIOTECA"
		"laboratorio": title = ["LABORATÓRIO DE QUÍMICA", "LABORATÓRIO DE BIOLOGIA", "LAB. DE FÍSICA"].pick_random()
		"cantina": title = ["CANTINA", "RESTAURANTE UNIVERSITÁRIO", "LANCHONETE"].pick_random()
		"sala_prof": title = "SALA DOS PROFESSORES"
		"xerox": title = "XEROX"
		"informatica": title = "LAB. DE INFORMÁTICA %d" % randi_range(1, 4)
		"banheiro": title = ["BANHEIRO MASCULINO", "BANHEIRO FEMININO"].pick_random()
		"auditorio": title = "AUDITÓRIO · ESTATÍSTICA"
	_board_text = BOARD_TEXTS.pick_random()
	_clearing = randf_range(50.0, 120.0)
	_swap = randf() < 0.5
	_rug = randf() < 0.5
	cleared = k == "hall"

func is_boss_room() -> bool:
	return kind == "auditorio"

func has_side(s: Vector2i) -> bool:
	return sides.has(s)

## Monta tudo. Chamar depois de preencher `sides`.
func build() -> void:
	z_index = -10
	var r := rect
	var tint: Color = KINDS[kind]["tint"]
	# cada sala com o piso um pouquinho diferente
	tint = tint * Color(randf_range(0.97, 1.03), randf_range(0.97, 1.03), randf_range(0.97, 1.03))
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
	Fx.tiled(self, tex, r, tint)

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
	var outer := Rect2(r.position.x - CAP, r.position.y - FACE - CAP, r.size.x + CAP * 2, r.size.y + FACE + CAP * 2)
	draw_rect(outer, CAP_COLOR)
	draw_rect(outer, Fx.CAP_RIM, false, 2.0) # quina de fora pegando um pouco de luz
	if kind == "hall":
		# Porta de vidro da entrada principal (por onde o jogador chegou)
		var cx := r.get_center().x
		draw_rect(Rect2(cx - 34, r.end.y, 68, CAP), Color("5a8ab0"))
		draw_rect(Rect2(cx - 1, r.end.y, 2, CAP), OUTLINE)
		draw_rect(Rect2(cx - 30, r.end.y + 2, 10, 2), Color("bfe3ff"))

# ---------------------------------------------------------------- móveis

## Caminhos que precisam ficar livres: de cada porta até o meio, mais um
## espaço aberto no centro (tamanho sorteado) pra dar pra lutar.
func _lane_blocked(fp: Rect2) -> bool:
	var c := rect.get_center()
	var r := rect
	var lanes: Array[Rect2] = [Rect2(c - Vector2(_clearing, _clearing * 0.7), Vector2(_clearing * 2, _clearing * 1.4))]
	for s in sides:
		match s:
			Vector2i.LEFT: lanes.append(Rect2(r.position.x, c.y - 44, c.x - r.position.x, 88))
			Vector2i.RIGHT: lanes.append(Rect2(c.x, c.y - 44, r.end.x - c.x, 88))
			Vector2i.UP: lanes.append(Rect2(c.x - 46, r.position.y, 92, c.y - r.position.y))
			Vector2i.DOWN: lanes.append(Rect2(c.x - 46, c.y, 92, r.end.y - c.y))
	for lane in lanes:
		if lane.intersects(fp):
			return true
	return false

func _prop(k: String, base: Vector2, ignore_lanes: bool = false) -> bool:
	base = base.round()
	var fp: Rect2 = PROP.footprint(k, base)
	var solid := Rect2(fp.position.x, base.y - 12, fp.size.x, 12)
	if not rect.grow(-6).encloses(Rect2(solid.position.x, base.y - 2, solid.size.x, 2)):
		return false
	if not ignore_lanes and _lane_blocked(solid):
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

func _grid(k: String, x0: float, y0: float, x1: float, y1: float, step: Vector2, chance: float = 1.0, stagger: float = 0.0) -> void:
	var y := y0
	var row := 0
	while y <= y1:
		var x := x0 + (stagger if row % 2 == 1 else 0.0)
		while x <= x1:
			if randf() <= chance:
				_prop(k, Vector2(x, y))
			x += step.x
		y += step.y
		row += 1

## Joga `count` objetos sorteados em lugares aleatórios da sala.
func _scatter(kinds: Array, count: int, top_margin: float = 50.0) -> void:
	for i in count:
		for tries in 12:
			var p := Vector2(randf_range(rect.position.x + 16, rect.end.x - 16),
				randf_range(rect.position.y + top_margin, rect.end.y - 10))
			if _prop(kinds.pick_random(), p):
				break

## Objetos encostados na parede de cima, em posições sorteadas.
func _along_top(kinds: Array, count: int) -> void:
	for i in count:
		for tries in 12:
			var k: String = kinds.pick_random()
			var y := rect.position.y + (22.0 if k in ["armarios", "estante", "cabine", "vending", "pilar"] else 34.0)
			if _prop(k, Vector2(randf_range(rect.position.x + 50, rect.end.x - 50), y)):
				break

func _furnish(cx: float, cy: float) -> void:
	# Espaçamentos pensados pros móveis em tamanho real (sprites de assets/props/clean).
	var r := rect
	var L := r.position.x
	var T := r.position.y
	var R := r.end.x
	var B := r.end.y
	var v := randi() % 3 # variação do layout
	match kind:
		"hall":
			_prop("balcao", Vector2(cx + (170 if _swap else -170), T + 90))
			_prop("vending", Vector2(R - 50 if not _swap else L + 50, T + 30))
			_prop("bebedouro", Vector2(L + 36 if not _swap else R - 36, T + 30))
			for x in [L + 26, R - 26]:
				_prop("vaso", Vector2(x, B - 12), true)
			# linha de catracas com passagem no meio
			var x := L + 80
			while x < R - 70:
				if absf(x - cx) > 56:
					_prop("catraca", Vector2(x, B - 110), true)
				x += 32
			_scatter(["vaso", "lixeira"], 2)
		"sala_aula":
			_prop("mesa_prof", Vector2(L + r.size.x * (0.75 if _swap else 0.25), T + 56))
			match v:
				0: # fileiras
					_grid("carteira", L + 50, T + 130, R - 40, B - 24, Vector2(60, 60))
				1: # grupos de 4 carteiras
					var y := T + 140.0
					while y < B - 60:
						var x := L + 80.0
						while x < R - 80:
							for o: Vector2 in [Vector2(-20, 0), Vector2(20, 0), Vector2(-20, 38), Vector2(20, 38)]:
								_prop("carteira", Vector2(x, y) + o)
							x += 150
						y += 130
				2: # em U, colado nas paredes
					_grid("carteira", L + 40, B - 24, R - 40, B - 24, Vector2(50, 50))
					_grid("carteira", L + 30, T + 140, L + 30, B - 80, Vector2(50, 56))
					_grid("carteira", R - 30, T + 140, R - 30, B - 80, Vector2(50, 56))
					_prop("pilar", Vector2(cx - 160, cy + 20))
					_prop("pilar", Vector2(cx + 160, cy + 20))
			_scatter(["vaso", "lixeira"], randi_range(0, 2))
		"biblioteca":
			match v:
				0: # fileiras de estantes
					_grid("estante", L + 60, T + 110, R - 50, B - 30, Vector2(90, 130))
				1: # colunas de estantes (corredores verticais)
					_grid("estante", L + 50, T + 110, R - 50, B - 20, Vector2(150, 90))
				2: # estantes nas paredes + mesas de leitura no meio
					_along_top(["estante"], 6)
					_grid("mesa_cantina", L + 100, T + 170, R - 100, B - 30, Vector2(170, 110))
			_prop("mesa_prof", Vector2(cx + (-140 if _swap else 140), T + 52))
			_scatter(["vaso", "pilha_papel", "lixeira"], randi_range(1, 4))
		"laboratorio":
			_along_top(["armarios"], 2)
			match v:
				0:
					_grid("bancada", L + 70, T + 150, R - 60, B - 24, Vector2(130, 110))
				1: # bancadas desencontradas
					_grid("bancada", L + 70, T + 140, R - 60, B - 24, Vector2(170, 100), 1.0, 85.0)
				2: # ilhas grandes (duas bancadas juntas)
					_grid("bancada", L + 90, T + 160, R - 90, B - 60, Vector2(200, 130))
					_grid("bancada", L + 90, T + 210, R - 90, B - 10, Vector2(200, 130))
			_scatter(["lixeira", "pilha_papel"], randi_range(0, 2))
		"cantina":
			_along_top(["vending", "vending", "cafeteira", "bebedouro"], randi_range(2, 4))
			match v:
				0:
					_grid("mesa_cantina", L + 90, T + 140, R - 80, B - 24, Vector2(170, 90))
				1:
					_grid("mesa_cantina", L + 80, T + 140, R - 80, B - 24, Vector2(200, 84), 1.0, 100.0)
				2:
					_scatter(["mesa_cantina"], 7, 120.0)
			_scatter(["lixeira", "vaso"], randi_range(1, 3))
		"sala_prof":
			_along_top(["sofa", "cafeteira", "estante", "armarios", "vending"], 3)
			if v == 0:
				_grid("mesa_cantina", L + 90, T + 160, R - 90, B - 30, Vector2(180, 120))
			else:
				_scatter(["mesa_prof", "sofa", "mesa_cantina"], 4, 110.0)
			_scatter(["vaso", "pilha_papel"], randi_range(1, 3))
		"xerox":
			if v != 1:
				var x := L + 40
				while x < R - 30:
					_prop("copiadora", Vector2(x, T + 30))
					x += randf_range(64, 90)
			else:
				_grid("copiadora", L + 70, T + 140, R - 60, B - 30, Vector2(120, 100))
			_scatter(["pilha_papel"], randi_range(6, 12), 90.0)
		"informatica":
			match v:
				0:
					_grid("pc", L + 44, T + 120, R - 40, B - 20, Vector2(56, 70))
				1: # fileiras longas
					_grid("pc", L + 40, T + 130, R - 40, B - 20, Vector2(50, 100))
				2: # PCs nas paredes
					_grid("pc", L + 40, T + 32, R - 40, T + 32, Vector2(56, 40))
					_grid("pc", L + 40, B - 16, R - 40, B - 16, Vector2(56, 40))
					_scatter(["pc"], 4, 120.0)
			_scatter(["lixeira", "pilha_papel"], randi_range(0, 2))
		"banheiro":
			# cabines numa parede, pias na outra
			var x := L + 36.0
			while x < R - 34:
				_prop("cabine", Vector2(x, T + 22))
				x += 52
			_grid("pia", L + 40, B - 16, R - 40, B - 16, Vector2(48, 30))
			for i in randi_range(2, 5):
				var d: Node2D = preload("res://scripts/decal.gd").new()
				d.kind = "agua"
				d.color = Color("7ec8e3")
				d.position = Vector2(randf_range(L + 20, R - 20), randf_range(T + 90, B - 50))
				entities.add_child(d)
			_scatter(["lixeira"], 1)
		"auditorio":
			# Palco em cima (o chefe fica lá), plateia embaixo
			_prop("pulpito", Vector2(cx + (110 if _swap else -110), T + 80))
			_grid("poltronas", L + 70, cy + 90, R - 70, B - 14, Vector2(126, 46))
			_prop("pilar", Vector2(L + 40, cy + 20), true)
			_prop("pilar", Vector2(R - 40, cy + 20), true)
	# Pilar no meio do caminho em salas grandes (cobertura extra)
	if kind not in ["hall", "auditorio", "banheiro"] and r.size.x >= 700 and randf() < 0.5:
		_prop("pilar", Vector2(cx + randf_range(-220, 220), cy + randf_range(-60, 100)))

# ---------------------------------------------------------------- decoração desenhada

## Sombra das paredes no chão (dá a sensação de altura/profundidade).
static func draw_wall_shadow(n: CanvasItem, r: Rect2, top: bool = true, sides: bool = true) -> void:
	if top:
		n.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 6), Color(0, 0, 0, 0.32))
		n.draw_rect(Rect2(r.position.x, r.position.y + 6, r.size.x, 6), Color(0, 0, 0, 0.2))
		n.draw_rect(Rect2(r.position.x, r.position.y + 12, r.size.x, 6), Color(0, 0, 0, 0.1))
	if sides:
		n.draw_rect(Rect2(r.position.x, r.position.y, 4, r.size.y), Color(0, 0, 0, 0.25))
		n.draw_rect(Rect2(r.position.x + 4, r.position.y, 4, r.size.y), Color(0, 0, 0, 0.12))
		n.draw_rect(Rect2(r.end.x - 4, r.position.y, 4, r.size.y), Color(0, 0, 0, 0.3))
		n.draw_rect(Rect2(r.end.x - 8, r.position.y, 4, r.size.y), Color(0, 0, 0, 0.15))

func _draw_floor_decor(n: Node2D) -> void:
	var r := rect
	var c := r.get_center()
	draw_wall_shadow(n, r)
	if _rug and kind in ["biblioteca", "sala_prof", "sala_aula", "xerox"]:
		var rug := Rect2(c.x - 70, c.y - 46, 140, 92)
		var hue := fmod(float(grid.x * 37 + grid.y * 91) / 100.0, 1.0)
		var base := Color.from_hsv(absf(hue), 0.35, 0.3)
		n.draw_rect(rug, base)
		n.draw_rect(rug.grow(-3), base.lightened(0.2))
		n.draw_rect(rug.grow(-10), base)
	match kind:
		"hall":
			# tapete vermelho da porta até o meio
			n.draw_rect(Rect2(c.x - 22, c.y - 40, 44, r.end.y - c.y + 40), Color("4a1e2a"))
			n.draw_rect(Rect2(c.x - 20, c.y - 40, 40, r.end.y - c.y + 40), Color("6e2a3a"))
			n.draw_rect(Rect2(c.x - 30, r.end.y - 14, 60, 12), Color("4a4040")) # capacho
			Fx.text(n, Vector2(c.x - 30, r.end.y - 5), "BEM-VINDO", Color("c8b8a0"), 7, 60, HORIZONTAL_ALIGNMENT_CENTER)
		"laboratorio":
			_stripes(n, c.y + (30 if _swap else -40))
		"banheiro":
			# azulejo xadrez
			var y := r.position.y
			while y < r.end.y:
				var x := r.position.x + (16.0 if int((y - r.position.y) / 16.0) % 2 == 1 else 0.0)
				while x < r.end.x:
					n.draw_rect(Rect2(x, y, minf(16, r.end.x - x), minf(16, r.end.y - y)), Color(0.6, 0.9, 1.0, 0.05))
					x += 32
				y += 16
		"auditorio":
			# palco de madeira em cima
			var stage := Rect2(r.position.x, r.position.y, r.size.x, 150)
			n.draw_rect(stage, Color("4e3640"))
			var y2 := stage.position.y + 8
			while y2 < stage.end.y:
				n.draw_rect(Rect2(stage.position.x, y2, stage.size.x, 2), Color("3e2a34"))
				y2 += 8
			n.draw_rect(Rect2(stage.position.x, stage.end.y, stage.size.x, 4), Color("241820"))
			# tapete do corredor da plateia
			n.draw_rect(Rect2(c.x - 20, stage.end.y + 4, 40, r.end.y - stage.end.y - 4), Color("4a2232"))

func _stripes(n: Node2D, y: float) -> void:
	var x := rect.position.x + 8
	var i := 0
	while x < rect.end.x - 8:
		n.draw_rect(Rect2(x, y, 8, 4), Color("ffd23f") if i % 2 == 0 else Color("2a2030"))
		x += 8
		i += 1

func _draw_wall_decor(n: Node2D) -> void:
	var r := rect
	var fy := r.position.y - FACE
	var left := r.position.x + r.size.x * 0.25
	var right := r.position.x + r.size.x * 0.75
	if _swap:
		var tmp := left
		left = right
		right = tmp
	var mid := r.get_center().x
	var center_free := not has_side(Vector2i.UP)
	match kind:
		"hall":
			_banner(n, mid if center_free else left, fy, "BEM-VINDO, CALOURO!")
			_clock(n, right, fy)
		"sala_aula":
			_blackboard(n, left, fy, _board_text)
			if grid.x % 2 == 0:
				_clock(n, right, fy)
			else:
				_plaque(n, right, fy, "PROIBIDO CELULAR", Color("5a2a2a"))
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
		"informatica":
			_plaque(n, left, fy, "PROIBIDO COMER", Color("5a2a2a"))
			_plaque(n, right, fy, "WI-FI: senha123", Color("2a3a5a"))
		"banheiro":
			_plaque(n, left, fy, "LAVE AS MÃOS", Color("2a4a5a"))
			_plaque(n, right, fy, "NÃO JOGUE PAPEL NO VASO", Color("5a2a2a"))
		"auditorio":
			_bell_board(n, mid if center_free else left, fy)
			_plaque(n, right if not center_free else mid + 200.0, fy, "MÉDIA = 7", Color("5a2a2a"))

## Lousa grande com a curva normal desenhada (sala do chefe).
func _bell_board(n: Node2D, x: float, fy: float) -> void:
	var b := Rect2(x - 70, fy + 2, 140, 26)
	n.draw_rect(b.grow(2), Color("7a5236"))
	n.draw_rect(b, Color("2a4a3a"))
	var prev := Vector2.ZERO
	for i in 61:
		var t := (i - 30) / 12.0
		var p := Vector2(b.position.x + 10 + i * 2.0, b.end.y - 4 - 18.0 * exp(-t * t / 2.0))
		if i > 0:
			n.draw_line(prev, p, Color("e8f0e0"), 1.0)
		prev = p
	n.draw_line(Vector2(b.position.x + 8, b.end.y - 4), Vector2(b.end.x - 8, b.end.y - 4), Color("a8c0a0"), 1.0)
	Fx.text(n, Vector2(b.position.x + 4, b.position.y + 9), "P(passar)=3%", Color("ffd966"), 7)

func _blackboard(n: Node2D, x: float, fy: float, text: String) -> void:
	var bw := maxf(104.0, Fx.text_width(text) + 12.0)
	var b := Rect2(x - bw / 2.0, fy + 4, bw, 20)
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
	var w := maxf(Fx.text_width(text) + 10.0, 40.0)
	var b := Rect2(x - w / 2.0, fy + 8, w, 12)
	n.draw_rect(b.grow(1), OUTLINE)
	n.draw_rect(b, bg)
	Fx.text(n, Vector2(b.position.x, b.position.y + 9), text, Color("f4e4c0"), 7, w, HORIZONTAL_ALIGNMENT_CENTER)

func _banner(n: Node2D, x: float, fy: float, text: String) -> void:
	var w := maxf(130.0, Fx.text_width(text) + 14.0)
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
	var b := Rect2(x - 44, fy + 3, 88, 24)
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
	if is_boss_room():
		_waves.append(["prof_estatistica"])
		return
	var pool: Array = KINDS[kind]["pool"]
	# Orçamento de "custo" de inimigos: andar 1 dá ~5-6 inimigos em 1 a 3 ondas.
	var budget := 9 + floor_level * 3 + randi_range(0, 4)
	var n_waves := 1 if budget < 10 else randi_range(2, 3 if budget >= 14 else 2)
	var left := budget
	for w in n_waves:
		var part := left if w == n_waves - 1 else int(budget / float(n_waves))
		_waves.append(_make_wave(pool, part))
		left -= part
	if elite_room:
		(_waves[_waves.size() - 1] as Array).append("coordenadora")

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
	if is_boss_room():
		get_tree().call_group("hud", "banner", "PROF. DE ESTATÍSTICA
PROVA FINAL - MÉDIA 7", Color("ff5a4a"), 2.0)
		await get_tree().create_timer(1.2).timeout
	else:
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
		if t == "prof_estatistica":
			e.position = Vector2(rect.get_center().x, rect.position.y + 130) # no palco
			e.set("arena", rect)
		e.died.connect(_on_enemy_died)
		entities.add_child(e)
		_alive += 1
		if e.boss:
			get_tree().call_group("hud", "show_boss", e)
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
	if is_boss_room():
		get_tree().call_group("hud", "banner", "APROVADO EM ESTATÍSTICA!
A ESCADA ESTÁ LIBERADA", Color("3fd17a"), 2.0)
	else:
		get_tree().call_group("hud", "banner", CLEAR_TEXTS.pick_random(), Color("3fd17a"))
	if randf() < 0.4 or is_boss_room():
		var cafe: Node2D = CAFE.new()
		cafe.position = rect.get_center() + Vector2(0, 50)
		entities.add_child(cafe)
	# Só o chefe libera a escada pro próximo andar.
	if is_boss_room():
		var st: Area2D = STAIRS.new()
		st.position = Vector2(rect.position.x + rect.size.x * 0.78, rect.position.y + 96)
		st.climbed.connect(func(): get_tree().call_group("level", "next_floor"))
		entities.add_child(st)
	cleared_room.emit(self)
