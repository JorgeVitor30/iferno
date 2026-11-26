extends CanvasLayer
## Autoload: menu de pausa no ESC (em qualquer cena).
## Continuar, Opções (volumes e tela cheia), Voltar pro início e Sair do jogo.

const MAIN_SCENE := "res://scenes/main.tscn"
const GOLD := Color("ffd966")
const BG := Color("1a1026")
const BG_HOVER := Color("33204a")
const BORDER := Color("473955")

var _root: Control
var _panel: PanelContainer
var _pages := {}
var _open := false

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.06, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _box(BG, BORDER, 2, 8, 14))
	_panel.custom_minimum_size = Vector2(240, 0)
	_root.add_child(_panel)
	_pages["main"] = _main_page()
	_pages["options"] = _options_page()
	for p: Control in _pages.values():
		_panel.add_child(p)

# ---------------------------------------------------------------- montagem

func _box(bg: Color, border: Color, bw: int, radius: int, pad: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4 if pad > 0 else 0
	return sb

func _title(parent: Control, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Fx.ui_font("black"))
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", GOLD)
	parent.add_child(l)

func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 26)
	b.add_theme_font_override("font", Fx.ui_font("bold"))
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_color_override("font_color", Color("e8e0d8"))
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(Color("241634"), BORDER, 1, 5))
	b.add_theme_stylebox_override("hover", _box(BG_HOVER, GOLD, 1, 5))
	b.add_theme_stylebox_override("pressed", _box(Color("4a2e66"), GOLD, 1, 5))
	b.mouse_entered.connect(func():
		Sfx.play(self, "hover", 0.0)
		b.pivot_offset = b.size / 2.0
		b.create_tween().tween_property(b, "scale", Vector2(1.04, 1.04), 0.08))
	b.mouse_exited.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.08))
	b.pressed.connect(func():
		Sfx.play(self, "menu", 0.0)
		cb.call())
	parent.add_child(b)
	return b

func _vbox() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	return v

func _main_page() -> Control:
	var v := _vbox()
	_title(v, "PAUSADO")
	var sub := Label.new()
	sub.text = "Respira, o professor não tá vendo."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", Fx.ui_font("regular"))
	sub.add_theme_font_size_override("font_size", 8)
	sub.add_theme_color_override("font_color", Color("8a7a98"))
	v.add_child(sub)
	v.add_child(HSeparator.new())
	_button(v, "Continuar", close)
	_button(v, "Opções", func(): _show("options"))
	var back := _button(v, "Voltar pro início", _back_to_start)
	back.name = "Back"
	_button(v, "Sair do jogo", func(): get_tree().quit())
	return v

func _options_page() -> Control:
	var v := _vbox()
	_title(v, "OPÇÕES")
	v.add_child(HSeparator.new())
	_slider(v, "Volume geral", Settings.master, func(x: float): Settings.master = x)
	_slider(v, "Efeitos sonoros", Settings.sfx, func(x: float): Settings.sfx = x)
	_slider(v, "Música", Settings.music, func(x: float): Settings.music = x)
	var fs := CheckButton.new()
	fs.text = "Tela cheia"
	fs.focus_mode = Control.FOCUS_NONE
	fs.button_pressed = Settings.fullscreen
	fs.add_theme_font_override("font", Fx.ui_font("bold"))
	fs.add_theme_font_size_override("font_size", 10)
	fs.add_theme_color_override("font_color", Color("e8e0d8"))
	fs.add_theme_color_override("font_hover_color", GOLD)
	fs.add_theme_color_override("font_pressed_color", Color("e8e0d8"))
	fs.add_theme_color_override("font_hover_pressed_color", GOLD)
	fs.toggled.connect(func(on: bool):
		Settings.fullscreen = on
		Settings.apply()
		Settings.save())
	v.add_child(fs)
	v.add_child(HSeparator.new())
	_button(v, "Voltar", func(): _show("main"))
	return v

func _slider(parent: Control, text: String, value: float, setter: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", Fx.ui_font("bold"))
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color("c8bcd4"))
	var pct := Label.new()
	pct.text = "%d%%" % roundi(value * 100)
	pct.add_theme_font_override("font", Fx.ui_font("bold"))
	pct.add_theme_font_size_override("font_size", 9)
	pct.add_theme_color_override("font_color", GOLD)
	top.add_child(l)
	top.add_child(pct)
	row.add_child(top)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.focus_mode = Control.FOCUS_NONE
	var track := _box(Color("0e0718"), BORDER, 1, 3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", _box(Color("c8963a"), Color("c8963a"), 0, 3))
	s.add_theme_stylebox_override("grabber_area_highlight", _box(GOLD, GOLD, 0, 3))
	s.add_theme_icon_override("grabber", _knob(Color("fff4dc")))
	s.add_theme_icon_override("grabber_highlight", _knob(Color.WHITE))
	s.value_changed.connect(func(x: float):
		pct.text = "%d%%" % roundi(x * 100)
		setter.call(x)
		Settings.apply()
		Settings.save()
		Sfx.play(self, "hover", 0.0))
	row.add_child(s)
	parent.add_child(row)

## Bolinha do slider (desenhada numa imagem pequena).
func _knob(c: Color) -> Texture2D:
	var n := 12
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n / 2.0, y + 0.5 - n / 2.0).length()
			if d <= n / 2.0 - 0.5:
				img.set_pixel(x, y, Fx.OUTLINE if d > n / 2.0 - 2.0 else c)
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------- abrir/fechar

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _open:
		if _pages["options"].visible:
			_show("main")
		else:
			close()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused: # (com a mochila ou a escolha de upgrade aberta, quem cuida é elas)
		open()
		get_viewport().set_input_as_handled()

func open() -> void:
	_open = true
	get_tree().paused = true
	var in_run := get_tree().current_scene != null and get_tree().current_scene.scene_file_path != MAIN_SCENE
	(_pages["main"] as Control).get_node("Back").visible = in_run
	_show("main")
	_root.visible = true
	_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.12)
	Sfx.play(self, "menu", 0.0)

func close() -> void:
	_open = false
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.1)
	tw.tween_callback(func(): _root.visible = _open)

func _show(page: String) -> void:
	for k: String in _pages:
		(_pages[k] as Control).visible = k == page
	# recentraliza o painel com o tamanho novo e dá um pulinho
	_panel.reset_size()
	await get_tree().process_frame
	_panel.reset_size()
	_panel.position = ((Vector2(640, 360) - _panel.size) / 2.0).round()
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.94, 0.94)
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Desiste da run: volta pra frente da faculdade (zera andar e upgrades).
func _back_to_start() -> void:
	close()
	FloorLevel.floor_num = 1
	FloorLevel.carry_hp = -1
	Upgrades.reset()
	Wallet.reset()
	get_tree().change_scene_to_file(MAIN_SCENE)
