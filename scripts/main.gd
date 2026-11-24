extends Node2D
## Sala de teste: chão + paredes com colisão (placeholder até termos tileset).

const ROOM := Rect2(16, 16, 448, 238)
const WALL := 8.0

func _ready() -> void:
	var r := ROOM
	_add_wall(Rect2(r.position.x - WALL, r.position.y - WALL, r.size.x + WALL * 2, WALL)) # cima
	_add_wall(Rect2(r.position.x - WALL, r.end.y, r.size.x + WALL * 2, WALL))           # baixo
	_add_wall(Rect2(r.position.x - WALL, r.position.y, WALL, r.size.y))                 # esquerda
	_add_wall(Rect2(r.end.x, r.position.y, WALL, r.size.y))                             # direita

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(480, 270)), Color("1a1020"))
	draw_rect(ROOM.grow(WALL), Color("4a2c3a"))
	draw_rect(ROOM, Color("2b1d2e"))
