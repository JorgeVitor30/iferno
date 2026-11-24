extends Node2D
## Sala de teste no estilo 3/4 (tipo top-down com paredes "em pé").
## A parede de cima mostra a face frontal; laterais e de baixo mostram só o topo escuro.

const FLOOR_TEX := preload("res://assets/tilesets/floor_tile.png")
const WALL_TEX := preload("res://assets/tilesets/wall_front.png")

const ROOM := Rect2(24, 56, 912, 464)  # área de chão andável (maior que a tela: a câmera segue o jogador)
const WALL_FACE_H := 31.0              # altura da face da parede de cima
const CAP := 8.0                       # espessura do topo escuro das paredes
const CAP_COLOR := Color("1c1420")

func _ready() -> void:
	$Player.position = ROOM.get_center()
	var cam: Camera2D = $Player/Camera2D
	cam.limit_left = int(ROOM.position.x - CAP - 16)
	cam.limit_top = int(ROOM.position.y - WALL_FACE_H - CAP - 16)
	cam.limit_right = int(ROOM.end.x + CAP + 16)
	cam.limit_bottom = int(ROOM.end.y + CAP + 16)
	cam.reset_smoothing()
	$Player.health_changed.connect($HUD/HealthBar.set_health)
	$HUD/HealthBar.set_health($Player.hp, $Player.max_hp)
	_add_tiled_sprite(FLOOR_TEX, ROOM)
	_add_tiled_sprite(WALL_TEX, Rect2(ROOM.position.x, ROOM.position.y - WALL_FACE_H, ROOM.size.x, WALL_FACE_H))

	var r := ROOM
	# Colisões: a de cima cobre a face da parede, as outras ficam no topo escuro.
	_add_wall(Rect2(r.position.x - CAP, r.position.y - WALL_FACE_H - CAP, r.size.x + CAP * 2, WALL_FACE_H + CAP))
	_add_wall(Rect2(r.position.x - CAP, r.end.y, r.size.x + CAP * 2, CAP))
	_add_wall(Rect2(r.position.x - CAP, r.position.y - WALL_FACE_H, CAP, r.size.y + WALL_FACE_H))
	_add_wall(Rect2(r.end.x, r.position.y - WALL_FACE_H, CAP, r.size.y + WALL_FACE_H))

func _add_tiled_sprite(tex: Texture2D, rect: Rect2) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, rect.size)
	s.position = rect.position
	add_child(s)
	move_child(s, 0) # desenha antes do jogador

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
