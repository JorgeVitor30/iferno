extends Control
## Minimapa no canto de cima à direita. Mostra as salas visitadas e as vizinhas
## (que dá pra ver pela porta). Amarelo = onde está, vermelho = ainda tem inimigo,
## verde piscando = escadaria.

const ROOM_PX := Vector2(12, 8)
const GAP := 4.0
const OUTLINE := Color("1a1020")

var level: Node # FloorLevel

func _process(_delta: float) -> void:
	queue_redraw() # pisca a sala atual

func _draw() -> void:
	if level == null:
		return
	var rooms: Dictionary = level.rooms
	if rooms.is_empty():
		return
	var lo := Vector2i(999, 999)
	var hi := Vector2i(-999, -999)
	for g: Vector2i in rooms:
		lo = Vector2i(mini(lo.x, g.x), mini(lo.y, g.y))
		hi = Vector2i(maxi(hi.x, g.x), maxi(hi.y, g.y))
	var step := ROOM_PX + Vector2(GAP, GAP)
	var total := Vector2(hi - lo + Vector2i.ONE) * step - Vector2(GAP, GAP)
	var origin := Vector2(640 - 8 - total.x, 8)
	draw_rect(Rect2(origin - Vector2(4, 4), total + Vector2(8, 8)), Color(0.05, 0.03, 0.07, 0.6))
	var blink := int(Time.get_ticks_msec() / 250) % 2 == 0
	# corredores
	for g: Vector2i in rooms:
		var r: Room = rooms[g]
		if not _known(r, rooms):
			continue
		var c := origin + Vector2(g - lo) * step + ROOM_PX / 2.0
		for s: Vector2i in r.sides:
			if r.visited:
				draw_line(c, c + Vector2(s) * step / 2.0, Color("8a8098"), 2.0)
	# salas
	for g: Vector2i in rooms:
		var r: Room = rooms[g]
		if not _known(r, rooms):
			continue
		var p := origin + Vector2(g - lo) * step
		var col := Color("4a4058")
		if r.visited:
			col = Color("c8c0d8") if r.cleared else Color("d94a4a")
		if r == level.current_room:
			col = Color("ffd966") if blink else Color("c8a040")
		draw_rect(Rect2(p, ROOM_PX).grow(1), OUTLINE)
		draw_rect(Rect2(p, ROOM_PX), col)
		if r.kind == "escadaria":
			draw_rect(Rect2(p + Vector2(4, 2), Vector2(4, 4)), Color("3fd17a") if blink or r.visited else OUTLINE)

func _known(r: Room, rooms: Dictionary) -> bool:
	if r.visited:
		return true
	for s: Vector2i in r.sides:
		var nb: Room = rooms.get(r.grid + s)
		if nb and nb.visited:
			return true
	return false
