extends Control
## Barra de vida em segmentos (1 segmento = 1 hit).

const SEG_SIZE := Vector2(12, 7)
const GAP := 2.0
const PAD := 2.0
const COLOR_FULL := Color("d94a4a")
const COLOR_SHINE := Color("ff8a7a")
const COLOR_EMPTY := Color("3a2230")
const COLOR_FRAME := Color("0d0910")
const COLOR_BORDER := Color("e8dcc0")

var max_hp := 6
var hp := 6

func set_health(new_hp: int, new_max: int) -> void:
	hp = new_hp
	max_hp = new_max
	queue_redraw()

func _draw() -> void:
	var w := PAD * 2 + max_hp * SEG_SIZE.x + (max_hp - 1) * GAP
	var h := PAD * 2 + SEG_SIZE.y
	draw_rect(Rect2(-1, -1, w + 2, h + 2), COLOR_BORDER)
	draw_rect(Rect2(0, 0, w, h), COLOR_FRAME)
	for i in max_hp:
		var pos := Vector2(PAD + i * (SEG_SIZE.x + GAP), PAD)
		if i < hp:
			draw_rect(Rect2(pos, SEG_SIZE), COLOR_FULL)
			draw_rect(Rect2(pos, Vector2(SEG_SIZE.x, 2)), COLOR_SHINE)
		else:
			draw_rect(Rect2(pos, SEG_SIZE), COLOR_EMPTY)
