extends Node2D
## Área inicial ("frente da faculdade"): sala com objetos de cenário e o ônibus.
## Entrar no ônibus começa a run.
## Estilo 3/4: a parede de cima mostra a face frontal; laterais e de baixo só o topo escuro.

const FLOOR_TEX := preload("res://assets/tilesets/floor_tile.png")
const WALL_TEX := preload("res://assets/tilesets/wall_front.png")
const FENCE_TEX := preload("res://assets/props/fence.png")
const RUN_SCENE := "res://scenes/run.tscn"

const ROOM := Rect2(24, 56, 912, 464)  # área de chão andável (maior que a tela: a câmera segue o jogador)
const WALL_FACE_H := 31.0              # altura da face da parede de cima
const CAP := 8.0                       # espessura do topo escuro das paredes
const CAP_COLOR := Color("1c1420")

# Objetos de cenário: textura, posição da base (onde encosta no chão) e tamanho da parte sólida.
const PROPS := [
	["tree", Vector2(110, 190), Vector2(20, 10)],
	["tree", Vector2(850, 190), Vector2(20, 10)],
	["tree", Vector2(80, 420), Vector2(20, 10)],
	["tree", Vector2(880, 420), Vector2(20, 10)],
	["lamp", Vector2(340, 160), Vector2(10, 6)],
	["lamp", Vector2(620, 160), Vector2(10, 6)],
	["trash", Vector2(650, 168), Vector2(20, 8)],
	["table", Vector2(250, 330), Vector2(66, 22)],
	["table", Vector2(710, 330), Vector2(66, 22)],
	["bench", Vector2(230, 460), Vector2(34, 10)],
	["bench", Vector2(730, 460), Vector2(34, 10)],
]
const FENCE_Y := 505.0     # cerca embaixo, com uma abertura no meio
const FENCE_GAP := 96.0

@onready var player: CharacterBody2D = $Entities/Player

func _ready() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = int(ROOM.position.x - CAP - 16)
	cam.limit_top = int(ROOM.position.y - WALL_FACE_H - CAP - 16)
	cam.limit_right = int(ROOM.end.x + CAP + 16)
	cam.limit_bottom = int(ROOM.end.y + CAP + 16)
	cam.reset_smoothing()
	player.health_changed.connect($HUD/HealthBar.set_health)
	$HUD/HealthBar.set_health(player.hp, player.max_hp)
	$Entities/Bus.boarded.connect(_on_bus_boarded)

	_add_tiled_sprite(FLOOR_TEX, ROOM)
	_add_tiled_sprite(WALL_TEX, Rect2(ROOM.position.x, ROOM.position.y - WALL_FACE_H, ROOM.size.x, WALL_FACE_H))
	var r := ROOM
	# Colisões: a de cima cobre a face da parede, as outras ficam no topo escuro.
	_add_wall(Rect2(r.position.x - CAP, r.position.y - WALL_FACE_H - CAP, r.size.x + CAP * 2, WALL_FACE_H + CAP))
	_add_wall(Rect2(r.position.x - CAP, r.end.y, r.size.x + CAP * 2, CAP))
	_add_wall(Rect2(r.position.x - CAP, r.position.y - WALL_FACE_H, CAP, r.size.y + WALL_FACE_H))
	_add_wall(Rect2(r.end.x, r.position.y - WALL_FACE_H, CAP, r.size.y + WALL_FACE_H))

	for p in PROPS:
		_add_prop(load("res://assets/props/%s.png" % p[0]), p[1], p[2])
	var mid := ROOM.get_center().x
	_add_fence(ROOM.position.x, mid - FENCE_GAP / 2.0)
	_add_fence(mid + FENCE_GAP / 2.0, ROOM.end.x)

## Objeto com a base na posição dada; só um retângulo na base é sólido,
## assim o jogador pode passar "atrás" da copa da árvore, por exemplo.
func _add_prop(tex: Texture2D, base: Vector2, solid: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = base
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.offset = Vector2(-floorf(tex.get_width() / 2.0), -tex.get_height())
	body.add_child(spr)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = solid
	col.shape = rect
	col.position = Vector2(0, -solid.y / 2.0)
	body.add_child(col)
	$Entities.add_child(body)

func _add_fence(x0: float, x1: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x0, FENCE_Y)
	var spr := Sprite2D.new()
	spr.texture = FENCE_TEX
	spr.centered = false
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, x1 - x0, FENCE_TEX.get_height())
	spr.offset = Vector2(0, -FENCE_TEX.get_height())
	body.add_child(spr)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(x1 - x0, 6)
	col.shape = rect
	col.position = Vector2((x1 - x0) / 2.0, -3)
	body.add_child(col)
	$Entities.add_child(body)

func _on_bus_boarded(_who: Node2D) -> void:
	# Jogador some dentro do ônibus, ônibus arranca, tela escurece e começa a run.
	player.hide()
	player.set_physics_process(false)
	player.set_process(false)
	player.get_node("Camera2D").reparent(self) # câmera fica parada vendo o ônibus sair
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property($HUD/Fade, "color:a", 1.0, 0.8)
	tw.tween_callback(func(): get_tree().change_scene_to_file(RUN_SCENE))

func _add_tiled_sprite(tex: Texture2D, rect: Rect2) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, rect.size)
	s.position = rect.position
	add_child(s)
	move_child(s, 0) # desenha antes de tudo

func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)

func _draw() -> void:
	# Fundo + topo escuro das paredes (desenhado atrás do chão e da face).
	draw_rect(ROOM.grow(200), Color("0d0910"))
	var outer := Rect2(ROOM.position.x - CAP, ROOM.position.y - WALL_FACE_H - CAP,
		ROOM.size.x + CAP * 2, ROOM.size.y + WALL_FACE_H + CAP * 2)
	draw_rect(outer, CAP_COLOR)
