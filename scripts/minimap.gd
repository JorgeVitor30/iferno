extends Control
## Minimapa no canto de cima à direita, num painel com moldura.
## Mostra as salas visitadas e as vizinhas (vistas pela porta, com "?").
## Cores: amarelo = onde você está, vermelho = ainda tem inimigo, claro = liberada.
## Ícones: porta na portaria, caveira na sala do chefe, triângulo de perigo na sala de desafio.

const CELL := Vector2(14, 10)
const GAP := 5.0
const PAD := 6.0
const OUTLINE := Color("1a1020")
const PANEL := Color(0.08, 0.05, 0.1, 0.78)
const FRAME := Color("8a7aa0")
const FRAME_DARK := Color("4a3d5a")
const LINK := Color("8a8098")
const C_UNKNOWN := Color("4a4058")
const C_CLEARED := Color("d8d0e4")
const C_DANGER := Color("d94a4a")
const C_HERE := Color("ffd966")

var level: Node # FloorLevel

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if level == null:
		return
	var rooms: Dictionary = level.rooms
	if rooms.is_empty():
		return
	# Só a parte conhecida do mapa entra no painel (o resto é surpresa).
	var lo := Vector2i(999, 999)
	var hi := Vector2i(-999, -999)
	for g: Vector2i in rooms:
		if _known(rooms[g], rooms):
			lo = Vector2i(mini(lo.x, g.x), mini(lo.y, g.y))
			hi = Vector2i(maxi(hi.x, g.x), maxi(hi.y, g.y))
	if lo.x > hi.x:
		return
	var step := CELL + Vector2(GAP, GAP)
	var inner := Vector2(hi - lo + Vector2i.ONE) * step - Vector2(GAP, GAP)
	inner = inner.max(Vector2(48, 20))
	var panel := Rect2(Vector2(640 - 8 - inner.x - PAD * 2, 6), inner + Vector2(PAD * 2, PAD * 2 + 9))
	_draw_panel(panel)
	var origin := panel.position + Vector2(PAD, PAD + 9)
	var t := Time.get_ticks_msec() / 1000.0
	var blink := fmod(t, 0.6) < 0.4
	# corredores entre salas conhecidas
	for g: Vector2i in rooms:
		var r: Room = rooms[g]
		if not r.visited:
			continue
		var c := origin + Vector2(g - lo) * step + CELL / 2.0
		for s: Vector2i in r.sides:
			var a := c + Vector2(s) * (CELL / 2.0)
			var b := c + Vector2(s) * (CELL / 2.0 + Vector2(GAP, GAP))
			draw_line(a, b, OUTLINE, 4.0)
			draw_line(a, b, LINK, 2.0)
	# salas
	for g: Vector2i in rooms:
		var r: Room = rooms[g]
		if not _known(r, rooms):
			continue
		var rect := Rect2(origin + Vector2(g - lo) * step, CELL)
		var here: bool = r == level.current_room
		var col := C_UNKNOWN
		if r.visited:
			col = C_CLEARED if r.cleared else C_DANGER
		if here:
			col = C_HERE
		draw_rect(rect.grow(1), OUTLINE)
		draw_rect(rect, col)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), col.lightened(0.35))  # brilho em cima
		draw_rect(Rect2(rect.position.x, rect.end.y - 2, rect.size.x, 2), col.darkened(0.3)) # sombra embaixo
		var mid := rect.get_center().floor()
		if r.is_challenge() and not r.cleared:
			_trap(mid, blink or r.visited) # sala de prova surpresa: aparece mesmo sem visitar
		elif not r.visited:
			Fx.text(self, Vector2(rect.position.x, rect.end.y - 2), "?", Color("a898b8"), 8, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		elif r.kind == "hall":
			draw_rect(Rect2(mid + Vector2(-2, -3), Vector2(4, 6)), OUTLINE) # porta
			draw_rect(Rect2(mid + Vector2(0, 0), Vector2(1, 1)), col)
		if r.is_boss_room():
			_skull(mid, blink or r.visited)
		if here and blink:
			# bolinha do jogador
			draw_rect(Rect2(mid + Vector2(-2, -2), Vector2(4, 4)), OUTLINE)
			draw_rect(Rect2(mid + Vector2(-1, -1), Vector2(2, 2)), Color.WHITE)
	# nome do andar no topo do painel
	Fx.ui_text(self, panel.position + Vector2(0, 11), "%dº ANDAR" % level.floor_num, FRAME, 8,
		panel.size.x, HORIZONTAL_ALIGNMENT_CENTER, "bold")

## Ícone de armadilha: triângulo de perigo laranja com "!".
func _trap(mid: Vector2, bright: bool) -> void:
	var c := Color("ffb04a") if bright else Color("c07a2a")
	for i in 5:
		draw_rect(Rect2(mid + Vector2(-i - 1, -3 + i), Vector2(i * 2 + 2, 1)), OUTLINE)
	for i in 4:
		draw_rect(Rect2(mid + Vector2(-i, -2 + i), Vector2(i * 2, 1)), c)
	draw_rect(Rect2(mid + Vector2(-5, 2), Vector2(10, 1)), OUTLINE)
	draw_rect(Rect2(mid + Vector2(0, -1), Vector2(1, 1)), OUTLINE)

## Painel com moldura dupla e cantinhos (pra combinar com os corações).
func _draw_panel(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.4)) # sombra
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, FRAME_DARK)
	draw_rect(r.grow(-1), FRAME)
	draw_rect(r.grow(-2), OUTLINE)
	draw_rect(r.grow(-3), PANEL)
	for p in [r.position, Vector2(r.end.x - 3, r.position.y), Vector2(r.position.x, r.end.y - 3), r.end - Vector2(3, 3)]:
		draw_rect(Rect2(p, Vector2(3, 3)), FRAME)
		draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 1)), OUTLINE)
	draw_line(r.position + Vector2(4, 13), Vector2(r.end.x - 4, r.position.y + 13), FRAME_DARK, 1.0)

func _skull(c: Vector2, lit: bool) -> void:
	var bone := Color("f4efe2") if lit else Color("8a7a88")
	draw_rect(Rect2(c + Vector2(-4, -4), Vector2(8, 7)), OUTLINE)
	draw_rect(Rect2(c + Vector2(-3, -3), Vector2(6, 4)), bone)
	draw_rect(Rect2(c + Vector2(-2, 1), Vector2(4, 1)), bone)
	draw_rect(Rect2(c + Vector2(-2, -2), Vector2(1, 2)), OUTLINE)
	draw_rect(Rect2(c + Vector2(1, -2), Vector2(1, 2)), OUTLINE)

func _known(r: Room, rooms: Dictionary) -> bool:
	if r.visited or r.is_challenge(): # a sala de desafio aparece no mapa desde o começo
		return true
	for s: Vector2i in r.sides:
		var nb: Room = rooms.get(r.grid + s)
		if nb and nb.visited:
			return true
	return false
