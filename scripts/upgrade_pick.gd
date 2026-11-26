class_name UpgradePick
extends Control
## Tela de escolha de upgrade: pausa o jogo e mostra 3 cartas.
## Escolhe com o mouse (clique) ou com as teclas 1, 2 e 3.
## Criada pelo HUD (hud.gd -> show_upgrades) e se apaga sozinha depois da escolha.

signal picked(id: String)

const CARD := Vector2(156, 176)
const LINE := 19.0 # altura de uma linha da fonte pixel
const GAP := 14.0
const TOP := 86.0
const FILL := Color("1d1229")
const FILL_HOVER := Color("2a1c3a")

var options: Array[String] = []
var _hover := -1
var _labels: Array[Label] = []
var _t := 0.0
var _ready_t := 0.35 # ignora cliques logo que abre (evita escolher sem querer atirando)
var _done := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var title := _label("ESCOLHA UM UPGRADE", Fx.BIG, Color("ffd966"))
	title.position = Vector2(0, 40)
	title.size = Vector2(640, 26)
	var hint := _label("CLIQUE OU APERTE 1, 2, 3", Fx.SMALL, Color("9a8aa8"))
	hint.position = Vector2(0, TOP + CARD.y + 10)
	hint.size = Vector2(640, 14)
	for i in options.size():
		var id := options[i]
		var d: Dictionary = Upgrades.DEFS[id]
		var r := _card_rect(i)
		var name_l := _label(d["name"], Fx.SMALL, d["color"].lightened(0.35))
		name_l.position = Vector2(r.position.x, r.position.y + 56)
		name_l.size = Vector2(r.size.x, LINE)
		var name_lines := String(d["name"]).count("\n") + 1
		var desc_l := _label(d["desc"], Fx.SMALL, Color("e8e0d8"))
		desc_l.position = Vector2(r.position.x, name_l.position.y + name_lines * LINE + 6)
		desc_l.size = Vector2(r.size.x, LINE)
		_labels.append(name_l)
		_labels.append(desc_l)
		var mx: int = d["max"]
		if mx > 0:
			var lvl := _label("%d/%d" % [Upgrades.count(id), mx], Fx.SMALL, Color("6a5a7a"))
			lvl.position = Vector2(r.position.x, r.end.y - 18)
			lvl.size = Vector2(r.size.x - 8, 14)
			lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_labels.append(lvl)
		var key := _label(str(i + 1), Fx.SMALL, Color("6a5a7a"))
		key.position = Vector2(r.position.x + 8, r.end.y - 18)
		key.size = Vector2(20, 14)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_labels.append(key)
		for l in _labels:
			if not l.has_meta("card"):
				l.set_meta("card", i)
				l.set_meta("y", l.position.y)
	# entra de baixo com fade
	modulate.a = 0.0
	position.y = 12
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(self, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Fx.OUTLINE)
	l.add_theme_constant_override("outline_size", 4 if size >= Fx.BIG else 2)
	add_child(l)
	return l

func _card_rect(i: int) -> Rect2:
	var total := options.size() * CARD.x + (options.size() - 1) * GAP
	var x0 := roundf((640.0 - total) / 2.0)
	var r := Rect2(Vector2(x0 + i * (CARD.x + GAP), TOP), CARD)
	if i == _hover:
		r.position.y -= 4
	return r

func _process(delta: float) -> void:
	_t += delta
	_ready_t -= delta
	var m := get_local_mouse_position()
	var h := -1
	for i in options.size():
		var r := _card_rect(i)
		r.position.y = TOP - 4
		r.size.y += 4
		if r.has_point(m):
			h = i
	if h != _hover:
		_set_hover(h)
	queue_redraw()

func _set_hover(h: int) -> void:
	_hover = h
	if h >= 0:
		Sfx.play(self, "hover", 0.0)
	# textos acompanham o cartão que sobe
	for l in _labels:
		l.position.y = float(l.get_meta("y")) - (4.0 if int(l.get_meta("card")) == h else 0.0)

func _input(event: InputEvent) -> void:
	if _done or _ready_t > 0.0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _hover >= 0:
		_choose(_hover)
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode - KEY_1
		if k >= 0 and k < options.size():
			_choose(k)
	else:
		return
	get_viewport().set_input_as_handled()

func _choose(i: int) -> void:
	_done = true
	Sfx.play(self, "upgrade", 0.0)
	picked.emit(options[i])
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)

func _draw() -> void:
	draw_rect(Rect2(-position, Vector2(640, 360)), Color(0.03, 0.01, 0.06, 0.72))
	for i in options.size():
		var id := options[i]
		var c: Color = Upgrades.DEFS[id]["color"]
		var r := _card_rect(i)
		var hov := i == _hover
		# moldura: contorno escuro + borda na cor do item (pisca de leve no hover)
		draw_rect(r.grow(2), Fx.OUTLINE)
		var border := c if hov else Color("473955")
		if hov and int(_t * 6.0) % 2 == 0:
			border = c.lightened(0.3)
		draw_rect(r.grow(1), border)
		draw_rect(r, FILL_HOVER if hov else FILL)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(1, 1, 1, 0.08))
		# ícone 2x num "pedestal"
		var ic := Vector2(r.get_center().x - 16, r.position.y + 12)
		draw_rect(Rect2(ic - Vector2(4, 4), Vector2(40, 40)), Color(0, 0, 0, 0.25))
		Upgrades.draw_icon(self, id, ic, 2.0)
