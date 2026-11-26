class_name UpgradePick
extends Control
## Tela de escolha de upgrade: pausa o jogo e mostra 3 cartas.
## Escolhe com o mouse (clique) ou com as teclas 1, 2 e 3.
## Criada pelo HUD (hud.gd -> show_upgrades) e se apaga sozinha depois da escolha.

signal picked(id: String)

const CARD := Vector2(164, 200)
const GAP := 16.0
const TOP := 82.0

var options: Array[String] = []
var title_text := "ESCOLHA UM UPGRADE"
var _cards: Array[UpgradeCard] = []
var _hover := -1
var _t := 0.0
var _ready_t := 0.45 # ignora cliques logo que abre (evita escolher sem querer atirando)
var _done := false
var _title: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title = Fx.ui_label(self, title_text, 22, Color("ffd966"), "black", 6)
	_title.position = Vector2(0, 30)
	_title.size = Vector2(640, 26)
	var hint := Fx.ui_label(self, "Clique ou aperte 1, 2, 3", 8, Color("8a7a98"), "semibold")
	hint.position = Vector2(0, TOP + CARD.y + 16)
	hint.size = Vector2(640, 14)
	var total := options.size() * CARD.x + (options.size() - 1) * GAP
	var x0 := roundf((640.0 - total) / 2.0)
	for i in options.size():
		var c := UpgradeCard.new()
		c.id = options[i]
		c.key = i + 1
		c.size = CARD
		c.base_pos = Vector2(x0 + i * (CARD.x + GAP), TOP)
		c.position = c.base_pos + Vector2(0, 40)
		c.modulate.a = 0.0
		add_child(c)
		_cards.append(c)
		# entrada em sequência, de baixo pra cima
		var tw := c.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_property(c, "position:y", TOP, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "modulate:a", 1.0, 0.2)
		tw.tween_callback(func(): c.entered = true)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)

func _process(delta: float) -> void:
	_t += delta
	_ready_t -= delta
	var m := get_local_mouse_position()
	var h := -1
	for i in _cards.size():
		if Rect2(_cards[i].base_pos - Vector2(0, 8), CARD + Vector2(0, 8)).has_point(m):
			h = i
	if h != _hover and not _done:
		_hover = h
		for i in _cards.size():
			_cards[i].set_hover(i == h)
		if h >= 0:
			Sfx.play(self, "hover", 0.0)
	_title.position.y = 30 + roundf(sin(_t * 2.5) * 1.5)
	queue_redraw()

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
	# carta escolhida pisca e sobe; as outras afundam
	for j in _cards.size():
		var c := _cards[j]
		var tw := c.create_tween()
		if j == i:
			c.chosen = true
			tw.tween_property(c, "position:y", TOP - 14, 0.18).set_ease(Tween.EASE_OUT)
		else:
			tw.tween_property(c, "position:y", TOP + 30, 0.18)
			tw.parallel().tween_property(c, "modulate:a", 0.0, 0.15)
	var tw2 := create_tween()
	tw2.tween_interval(0.3)
	tw2.tween_property(self, "modulate:a", 0.0, 0.18)
	tw2.tween_callback(queue_free)

func _draw() -> void:
	# fundo escurecido com vinheta em degraus
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.03, 0.01, 0.06, 0.7))
	for i in 4:
		var g := 6.0 + i * 8.0
		draw_rect(Rect2(0, 0, 640, g), Color(0, 0, 0, 0.12))
		draw_rect(Rect2(0, 360 - g, 640, g), Color(0, 0, 0, 0.12))
	# enfeite do título: linhas com losango nas pontas
	var y := 64.0
	for side: float in [-1.0, 1.0]:
		var x_in := 320.0 + side * 132.0
		var x_out := 320.0 + side * 230.0
		draw_rect(Rect2(minf(x_in, x_out), y, absf(x_out - x_in), 1), Color("6a4a2a"))
		draw_rect(Rect2(x_out - 2, y - 2, 5, 5), Color("ffd966"))
		draw_rect(Rect2(x_out - 1, y - 1, 3, 3), Color("6a4a2a"))


## Uma carta de upgrade (desenhada em código, com os textos como Labels filhos).
class UpgradeCard extends Control:
	const NAME_Y := 96.0
	const NAME_LINE := 13.0
	var id := ""
	var key := 1
	var base_pos := Vector2.ZERO
	var chosen := false
	var entered := false # terminou a animação de entrada
	var _hover := false
	var _t := 0.0
	var _lift := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d: Dictionary = Upgrades.DEFS[id]
		var c: Color = d["color"]
		var tag := Fx.ui_label(self, d["tag"], 7, c.lightened(0.55), "bold")
		tag.position = Vector2(0, 76)
		tag.size = Vector2(size.x, 15)
		var name_l := Fx.ui_label(self, d["name"], 11, Color("fff4dc"), "black")
		name_l.position = Vector2(0, NAME_Y)
		name_l.size = Vector2(size.x, NAME_LINE)
		name_l.add_theme_constant_override("line_spacing", -3)
		var desc := Fx.ui_label(self, d["desc"], 8, Color("c8bcd4"), "semibold")
		desc.position = Vector2(0, _desc_y())
		desc.size = Vector2(size.x, 12)
		var k := Fx.ui_label(self, str(key), 8, Color("fff4dc"), "bold")
		k.position = Vector2(6, size.y - 21)
		k.size = Vector2(14, 14)

	## Onde começa a descrição (depende de quantas linhas o nome tem).
	func _desc_y() -> float:
		var lines := String(Upgrades.DEFS[id]["name"]).count("\n") + 1
		return NAME_Y + lines * NAME_LINE + 10.0

	func set_hover(on: bool) -> void:
		_hover = on
		var tw := create_tween()
		tw.tween_property(self, "_lift", 8.0 if on else 0.0, 0.12).set_ease(Tween.EASE_OUT)

	func _process(delta: float) -> void:
		_t += delta
		if entered and not chosen:
			position.y = base_pos.y - roundf(_lift)
		queue_redraw()

	func _draw() -> void:
		var d: Dictionary = Upgrades.DEFS[id]
		var c: Color = d["color"]
		var r := Rect2(Vector2.ZERO, size)
		var white := chosen and int(_t * 16.0) % 2 == 0
		# sombra embaixo (fica maior quando a carta sobe)
		draw_rect(Rect2(4, size.y + 2 + _lift, size.x - 4, 4), Color(0, 0, 0, 0.35))
		# moldura
		draw_rect(r.grow(2), Fx.OUTLINE)
		var rare := Upgrades.is_rare(id)
		var idle := Color("473955")
		if rare: # raro: moldura dourada que brilha
			idle = Color("b8862a").lerp(Color("ffd23f"), 0.5 + sin(_t * 4.0) * 0.5)
		var border := Color.WHITE if white else (c if _hover else idle)
		draw_rect(r.grow(1), border)
		draw_rect(r, Color("1a1026"))
		# cabeçalho na cor do item com pontilhado
		var head := Rect2(2, 2, size.x - 4, 68)
		var hc := c.darkened(0.55)
		draw_rect(head, hc)
		for y in range(int(head.position.y), int(head.end.y), 2):
			for x in range(int(head.position.x) + (y / 2) % 2 * 2, int(head.end.x), 4):
				draw_rect(Rect2(x, y, 1, 1), hc.lightened(0.12))
		draw_rect(Rect2(head.position.x, head.end.y, head.size.x, 1), c.darkened(0.2))
		draw_rect(Rect2(head.position.x, head.position.y, head.size.x, 1), hc.lightened(0.3))
		# brilho atrás do ícone (anéis) e ícone 3x flutuando
		var center := Vector2(size.x / 2.0, 36)
		var pulse := 1.0 + (0.25 if _hover else 0.0) + sin(_t * 3.0) * 0.08
		for i in 3:
			draw_circle(center, (30.0 - i * 8.0) * pulse, Color(c, 0.08 + i * 0.05))
		var bob := roundf(sin(_t * 3.0 + key) * (2.0 if _hover else 1.0))
		Upgrades.draw_icon(self, id, center - Vector2(24, 24 - bob), 3.0)
		# etiqueta da categoria
		var tw := Fx.ui_width(d["tag"], 7, "bold") + 12.0
		var tag_r := Rect2(size.x / 2.0 - tw / 2.0, 76, tw, 15)
		draw_rect(tag_r.grow(1), Fx.OUTLINE)
		draw_rect(tag_r, c.darkened(0.6))
		# divisória com losango
		var dy := _desc_y() - 5.0
		draw_rect(Rect2(20, dy, size.x - 40, 1), Color("3a2c48"))
		draw_rect(Rect2(size.x / 2.0 - 2, dy - 2, 5, 5), c)
		# tecla
		draw_rect(Rect2(5, size.y - 22, 16, 17), Fx.OUTLINE)
		draw_rect(Rect2(6, size.y - 21, 14, 15), Color("3a2c48"))
		# nível: quadradinhos (cheio = já tem, piscando = o que vai ganhar)
		var mx: int = d["max"]
		if mx > 0:
			var n := Upgrades.count(id)
			for i in mx:
				var px := size.x - 12.0 - (mx - 1 - i) * 10.0
				var pr := Rect2(px - 3, size.y - 17, 7, 7)
				draw_rect(pr.grow(1), Fx.OUTLINE)
				var col := Color("2a1f38")
				if i < n:
					col = c
				elif i == n and int(_t * 4.0) % 2 == 0:
					col = c.lightened(0.4)
				draw_rect(pr, col)
		if rare:
			# cantoneiras douradas
			for p: Vector2 in [Vector2(-2, -2), Vector2(size.x - 4, -2), Vector2(-2, size.y - 4), Vector2(size.x - 4, size.y - 4)]:
				draw_rect(Rect2(p, Vector2(6, 6)), Fx.OUTLINE)
				draw_rect(Rect2(p + Vector2(1, 1), Vector2(4, 4)), Color("ffd23f"))
		if white:
			draw_rect(r, Color(1, 1, 1, 0.25))
