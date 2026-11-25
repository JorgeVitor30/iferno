class_name FloorLevel
extends Node2D
## Um andar da faculdade gerado na hora: salas numa grade ligadas por corredores.
## Começa na portaria (onde o ônibus deixa o jogador), termina na escadaria
## (a sala mais longe), guardada pela coordenadora. Subir a escada = próximo andar.

const CELL := Vector2(784, 560) # distância entre os centros de salas vizinhas
const CORRIDOR_TINT := Color(0.9, 0.88, 0.84)
const FLOOR_TEX := preload("res://assets/tilesets/floor_tile.png")
const WALL_TEX := preload("res://assets/tilesets/wall_front.png")
const FLOOR_NAMES := ["ENTRADA DA FACULDADE", "BLOCO DE AULAS", "BIBLIOTECA CENTRAL", "LABORATÓRIOS", "REITORIA"]
const ROOM_POOL := ["sala_aula", "sala_aula", "sala_aula", "biblioteca", "laboratorio", "cantina", "sala_prof", "xerox"]
const POSTERS := ["FESTA SEXTA!", "DCE", "MONITORIA", "VENDE-SE APOSTILA", "INTERCÂMBIO", "ESTÁGIO!", "CHAPA 2"]

static var floor_num := 1
static var carry_hp := -1 # vida que o jogador leva pro próximo andar

@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var hud: CanvasLayer = $HUD

var rooms := {} # Vector2i -> Room
var current_room: Room
var _shake := 0.0
var _cam: Camera2D
var _last_hp := 0
var _leaving := false

static func floor_name(n: int) -> String:
	return FLOOR_NAMES[mini(n - 1, FLOOR_NAMES.size() - 1)]

func _ready() -> void:
	add_to_group("shaker")
	add_to_group("level")
	_generate()
	var hall: Room = rooms[Vector2i.ZERO]
	player.position = Vector2(hall.rect.get_center().x, hall.rect.end.y - 36)
	_cam = player.get_node("Camera2D")
	_cam.reset_smoothing()
	if carry_hp > 0:
		player.hp = mini(carry_hp, player.max_hp)
	_last_hp = player.hp
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	hud.setup(self)
	hud.set_health(player.hp, player.max_hp)
	_on_room_entered(hall)
	hud.intro("%dº ANDAR" % floor_num, floor_name(floor_num))

# ---------------------------------------------------------------- geração

func _generate() -> void:
	var count := mini(7 + floor_num * 2, 15)
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	var links: Array = []
	var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
	var guard := 0
	while cells.size() < count and guard < 5000:
		guard += 1
		var from: Vector2i = cells.pick_random()
		var to: Vector2i = from + dirs.pick_random()
		if to.y > 0 or cells.has(to):
			continue # nada abaixo da portaria
		if from == Vector2i.ZERO and to != Vector2i.UP:
			continue # da portaria só se sobe (atrás dela é a rua)
		cells.append(to)
		links.append([from, to])
	# Alguns atalhos extras pra não ficar só uma árvore
	for c in cells:
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.UP]:
			var nb := c + d
			if c == Vector2i.ZERO or nb == Vector2i.ZERO or not cells.has(nb):
				continue
			if _linked(links, c, nb) or randf() > 0.2:
				continue
			links.append([c, nb])
	var far := _farthest(cells, links)
	var pool: Array = []
	for c in cells:
		var k := "hall"
		if c == far:
			k = "escadaria"
		elif c != Vector2i.ZERO:
			if pool.is_empty():
				pool = ROOM_POOL.duplicate()
				pool.shuffle()
			k = pool.pop_back()
		var room := Room.new()
		room.setup(c, k, Vector2(c) * CELL, floor_num, entities)
		room.entered.connect(_on_room_entered)
		room.cleared_room.connect(func(_r: Room): hud.refresh_map())
		rooms[c] = room
	for l: Array in links:
		var a: Vector2i = l[0]
		var b: Vector2i = l[1]
		(rooms[a] as Room).sides.append(b - a)
		(rooms[b] as Room).sides.append(a - b)
	for room: Room in rooms.values():
		add_child(room)
		room.build()
	for l: Array in links:
		_build_corridor(rooms[l[0]], rooms[l[1]])
	_add_background()

func _linked(links: Array, a: Vector2i, b: Vector2i) -> bool:
	for l: Array in links:
		if (l[0] == a and l[1] == b) or (l[0] == b and l[1] == a):
			return true
	return false

## Sala mais longe da portaria (em número de portas) vira a escadaria.
func _farthest(cells: Array[Vector2i], links: Array) -> Vector2i:
	var dist := {Vector2i.ZERO: 0}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for l: Array in links:
			var other: Vector2i
			if l[0] == c:
				other = l[1]
			elif l[1] == c:
				other = l[0]
			else:
				continue
			if not dist.has(other):
				dist[other] = dist[c] + 1
				queue.append(other)
	var far := Vector2i.ZERO
	for c: Vector2i in dist:
		if dist[c] > dist[far] or (dist[c] == dist[far] and c.y < far.y):
			far = c
	return far

func _build_corridor(a: Room, b: Room) -> void:
	if a.grid.x > b.grid.x or a.grid.y > b.grid.y:
		var tmp := a
		a = b
		b = tmp
	var w := Room.DOOR_W
	var face := Room.FACE
	var cap := Room.CAP
	var n := Node2D.new()
	n.z_index = -9
	var caps := Rect2()
	var floor_r := Rect2()
	var face_r := Rect2()
	var walls: Array[Rect2] = []
	if a.grid.y == b.grid.y:
		var cy := a.rect.get_center().y
		var x0 := a.rect.end.x
		var x1 := b.rect.position.x
		caps = Rect2(x0, cy - w / 2 - face - cap, x1 - x0, w + face + cap * 2)
		floor_r = Rect2(x0, cy - w / 2, x1 - x0, w)
		face_r = Rect2(x0 + cap, cy - w / 2 - face, x1 - x0 - cap * 2, face)
		walls = [Rect2(x0, cy - w / 2 - face - cap, x1 - x0, face + cap), Rect2(x0, cy + w / 2, x1 - x0, cap)]
	else:
		var cx := a.rect.get_center().x
		var y0 := a.rect.end.y
		var y1 := b.rect.position.y
		caps = Rect2(cx - w / 2 - cap, y0, w + cap * 2, y1 - y0)
		floor_r = Rect2(cx - w / 2, y0, w, y1 - y0)
		walls = [Rect2(cx - w / 2 - cap, y0, cap, y1 - y0), Rect2(cx + w / 2, y0, cap, y1 - y0)]
	n.draw.connect(func(): n.draw_rect(caps, Room.CAP_COLOR))
	add_child(n)
	_tiled(n, FLOOR_TEX, floor_r, CORRIDOR_TINT)
	if face_r.size.x > 0.0:
		_tiled(n, WALL_TEX, face_r, Color(0.92, 0.92, 0.92))
		if face_r.size.x > 120.0 and randf() < 0.7:
			var text: String = POSTERS.pick_random()
			var px := face_r.get_center().x + randf_range(-30, 30)
			var pcol := Color.from_hsv(randf(), 0.45, 0.85)
			var deco := Node2D.new()
			deco.draw.connect(func():
				var pw := text.length() * 5.0 + 8.0
				var pr := Rect2(px - pw / 2.0, face_r.position.y + 7, pw, 13)
				deco.draw_rect(pr.grow(1), Room.OUTLINE)
				deco.draw_rect(pr, pcol)
				Fx.text(deco, Vector2(pr.position.x, pr.position.y + 10), text, Room.OUTLINE, 7, pw, HORIZONTAL_ALIGNMENT_CENTER))
			n.add_child(deco)
	for r in walls:
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = r.size
		col.shape = box
		body.position = r.get_center()
		body.add_child(col)
		n.add_child(body)

func _tiled(parent: Node, tex: Texture2D, r: Rect2, tint: Color) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size)
	s.position = r.position
	s.modulate = tint
	parent.add_child(s)

## Fundo escuro atrás de tudo (num nó com z bem baixo).
func _add_background() -> void:
	var bounds := Rect2()
	for c: Vector2i in rooms:
		bounds = bounds.merge(Rect2(Vector2(c) * CELL - CELL, CELL * 2))
	var bg := Node2D.new()
	bg.z_index = -20
	bg.draw.connect(func(): bg.draw_rect(bounds.grow(400), Color("0d0910")))
	add_child(bg)

# ---------------------------------------------------------------- jogo

func _on_room_entered(room: Room) -> void:
	room.visited = true
	if current_room != room:
		current_room = room
		hud.set_title(room.title)
	hud.refresh_map()

func _on_health_changed(hp: int, max_hp: int) -> void:
	hud.set_health(hp, max_hp)
	if hp < _last_hp:
		shake(5.0)
		hud.hurt_flash()
	_last_hp = hp

func _on_player_died() -> void:
	hud.banner("REPROVADO!", Color("ff5a4a"))
	floor_num = 1
	carry_hp = -1

func next_floor() -> void:
	if _leaving:
		return
	_leaving = true
	carry_hp = player.hp
	floor_num += 1
	player.set_physics_process(false)
	hud.banner("SUBINDO...", Color("3fd17a"))
	await hud.fade_out()
	get_tree().reload_current_scene()

func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

func _process(delta: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	_shake = move_toward(_shake, 0.0, delta * 25.0)
	_cam.offset = (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake).round()
