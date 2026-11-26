class_name Inventory
extends Control
## Mochila (TAB): pausa o jogo e mostra os números do estudante e os upgrades pegos.
## Abre/fecha com TAB (ou ESC pra fechar). Criada pelo HUD (hud.gd).

const PANEL := Rect2(40, 34, 560, 292)
const SPLIT := 236.0 # largura da coluna de números
const GOOD := Color("7ee08a")
const BAD := Color("ff8a7a")

var player: Node
var floor_text := ""
var _t := 0.0
var _closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	modulate.a = 0.0
	position.y = 8
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(self, "position:y", 0.0, 0.15).set_ease(Tween.EASE_OUT)

func _lbl(text: String, pos: Vector2, color: Color, size: int = Fx.SMALL,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, w: float = 200.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, 14)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Fx.OUTLINE)
	l.add_theme_constant_override("outline_size", 4 if size >= Fx.BIG else 2)
	add_child(l)
	return l

## Linhas de números: [nome, valor em texto, comparação com o base (+1 melhor, -1 pior, 0 igual)]
func _stats() -> Array:
	var p := player
	var cmp := func(v: float, base: float, higher_better: bool = true) -> int:
		if is_equal_approx(v, base):
			return 0
		return 1 if (v > base) == higher_better else -1
	return [
		["VIDA", "%d / %d" % [p.hp, p.max_hp], cmp.call(float(p.max_hp), float(p.base_max_hp))],
		["VELOCIDADE", "%d%%" % roundi(p.speed / p.base_speed * 100.0), cmp.call(p.speed, p.base_speed)],
		["DANO", str(p.bullet_damage), cmp.call(float(p.bullet_damage), 1.0)],
		["TIROS POR SEG.", "%.1f" % (1.0 / p.fire_rate), cmp.call(1.0 / p.fire_rate, 1.0 / p.base_fire_rate)],
		["PROJÉTEIS", str(p.bullet_count), cmp.call(float(p.bullet_count), 1.0)],
		["ATRAVESSA", str(p.bullet_pierce), cmp.call(float(p.bullet_pierce), 0.0)],
		["RICOCHETE", str(p.bullet_bounces), cmp.call(float(p.bullet_bounces), 0.0)],
		["CRÍTICO", "%d%%" % roundi(p.crit_chance * 100.0), cmp.call(p.crit_chance, 0.0)],
		["ESPERA DO DODGE", "%.2fs" % p.roll_cooldown, cmp.call(p.roll_cooldown, p.base_roll_cooldown, false)],
	]

func _build() -> void:
	_lbl("MOCHILA", Vector2(PANEL.position.x, PANEL.position.y + 8), Color("ffd966"), Fx.BIG,
		HORIZONTAL_ALIGNMENT_CENTER, PANEL.size.x)
	_lbl(floor_text, Vector2(PANEL.position.x + 12, PANEL.position.y + 10), Color("8a7a98"))
	_lbl("TAB FECHA", Vector2(PANEL.end.x - 112, PANEL.position.y + 10), Color("8a7a98"),
		Fx.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, 100)
	# coluna da esquerda: números
	var x := PANEL.position.x + 16
	var y := PANEL.position.y + 50
	_lbl("ESTUDANTE", Vector2(x, y), Color("c8bcd4"))
	y += 24
	for st: Array in _stats():
		var col := Color("e8e0d8")
		if st[2] > 0:
			col = GOOD
		elif st[2] < 0:
			col = BAD
		_lbl(st[0], Vector2(x, y), Color("9a8aa8"))
		_lbl(st[1], Vector2(x, y), col, Fx.SMALL, HORIZONTAL_ALIGNMENT_RIGHT, SPLIT - 32)
		y += 21
	# coluna da direita: upgrades
	var rx := PANEL.position.x + SPLIT + 16
	var ry := PANEL.position.y + 50
	_lbl("UPGRADES", Vector2(rx, ry), Color("c8bcd4"))
	ry += 24
	var ids := _owned()
	if ids.is_empty():
		_lbl("Nada ainda. Limpe salas pra\nganhar upgrades!", Vector2(rx, ry + 6), Color("6a5a7a"), Fx.SMALL,
			HORIZONTAL_ALIGNMENT_LEFT, 300)
	for id in ids:
		var d: Dictionary = Upgrades.DEFS[id]
		var n := Upgrades.count(id)
		var title := String(d["name"]).replace("\n", " ") + ("  x%d" % n if n > 1 else "")
		_lbl(title, Vector2(rx + 40, ry), (d["color"] as Color).lightened(0.4), Fx.SMALL, HORIZONTAL_ALIGNMENT_LEFT, 280)
		_lbl(String(d["desc"]).replace("\n", " "), Vector2(rx + 40, ry + 15), Color("b0a4bc"), Fx.SMALL,
			HORIZONTAL_ALIGNMENT_LEFT, 290)
		ry += 34

## Upgrades que ficam (o café é na hora).
func _owned() -> Array[String]:
	var ids: Array[String] = []
	for id: String in Upgrades.taken:
		if id != "cafe":
			ids.append(id)
	return ids

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("inventory") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	_closing = true
	Sfx.play(self, "menu", 0.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(func():
		get_tree().paused = false
		queue_free())

func _draw() -> void:
	draw_rect(Rect2(-position, Vector2(640, 360)), Color(0.03, 0.01, 0.06, 0.72))
	var p := PANEL
	draw_rect(Rect2(p.position + Vector2(4, 4), p.size), Color(0, 0, 0, 0.4)) # sombra
	draw_rect(p.grow(2), Fx.OUTLINE)
	draw_rect(p.grow(1), Color("473955"))
	draw_rect(p, Color("1a1026"))
	# faixa do título
	draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 36), Color("241634"))
	draw_rect(Rect2(p.position.x, p.position.y + 36, p.size.x, 1), Color("473955"))
	# divisória entre as colunas
	draw_rect(Rect2(p.position.x + SPLIT, p.position.y + 46, 1, p.size.y - 58), Color("3a2c48"))
	# sublinhado das seções
	draw_rect(Rect2(p.position.x + 16, p.position.y + 67, SPLIT - 32, 1), Color("3a2c48"))
	draw_rect(Rect2(p.position.x + SPLIT + 16, p.position.y + 67, p.size.x - SPLIT - 32, 1), Color("3a2c48"))
	# ícones dos upgrades
	var ry := p.position.y + 74
	for id in _owned():
		var c: Color = Upgrades.DEFS[id]["color"]
		var at := Vector2(p.position.x + SPLIT + 16, ry)
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(34, 34)), Fx.OUTLINE)
		draw_rect(Rect2(at, Vector2(32, 32)), c.darkened(0.6))
		Upgrades.draw_icon(self, id, at, 2.0)
		ry += 34
