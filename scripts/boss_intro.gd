class_name BossIntro
extends Control
## Apresentação de chefe (~3s), igual pra todos os chefes: pausa o jogo, entra o
## estudante na esquerda e o chefe GRANDE na direita (destaque na cara dele),
## "VS" no meio, nome e descrição do chefe com um "tchan" e tremida.
## Depois sai de cena e chama `finished` (o HUD solta a música de chefe).
## Cada chefe só precisa preencher no _setup(): display_name, intro_subtitle,
## intro_color e (opcional) portrait_tex. Ver enemy.gd.

signal finished

const DURATION := 3.0
const PLAYER_TEX := preload("res://assets/sprites/student2/idle_s.png")
const PLAYER_CELL := Vector2(48, 48)

var boss_name := "CHEFE"
var subtitle := ""
var color := Color("ff5a4a")
var portrait: Texture2D

var _t := 0.0
var _left: TextureRect
var _right: TextureRect
var _name_l: Label
var _sub_l: Label
var _vs: Label
var _shake := 0.0
var _flash := 0.0
var _done := false
var _flash_rect := ColorRect.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# estudante (primeiro quadro do idle de frente), 3x
	var at := AtlasTexture.new()
	at.atlas = PLAYER_TEX
	at.region = Rect2(Vector2.ZERO, PLAYER_CELL)
	_left = _portrait(at, 3.0)
	_left.position = Vector2(-200, 120)
	# chefe: escala inteira pra caber ~230px de altura (pixel nítido)
	var ph := portrait.get_height() if portrait else 80
	# close: chefe bem grande (escala inteira) com as pernas saindo pela parte de baixo
	var sc := maxf(1.0, floorf(330.0 / ph))
	_right = _portrait(portrait, sc)
	_right.position = Vector2(700, 360 - _right.size.y + _right.size.y * 0.22)
	_vs = Fx.ui_label(self, "VS", 34, Color("fff4dc"), "black", 8)
	_vs.size = Vector2(120, 50)
	_vs.position = Vector2(200, 150)
	_vs.pivot_offset = _vs.size / 2.0
	_vs.scale = Vector2.ZERO
	_name_l = Fx.ui_label(self, boss_name, 34, color.lightened(0.25), "black", 8, HORIZONTAL_ALIGNMENT_RIGHT)
	_name_l.size = Vector2(360, 48)
	_name_l.position = Vector2(700, 30)
	_sub_l = Fx.ui_label(self, subtitle, 12, Color("e8e0d8"), "bold", 4, HORIZONTAL_ALIGNMENT_RIGHT)
	_sub_l.size = Vector2(360, 20)
	_sub_l.position = Vector2(100, 78)
	_sub_l.modulate.a = 0.0
	# flash branco por cima de tudo
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	add_child(_flash_rect)
	_run()

func _portrait(tex: Texture2D, s: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex:
		r.size = tex.get_size() * s
	add_child(r)
	return r

func _run() -> void:
	Sfx.play(self, "whoosh", 0.0)
	var tw := create_tween().set_parallel(true)
	# entram: estudante pela esquerda, chefe pela direita
	tw.tween_property(_left, "position:x", 40.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_right, "position:x", 640.0 - _right.size.x - 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	tw.tween_property(_vs, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.35)
	tw.tween_property(_name_l, "position:x", 100.0, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).set_delay(0.55)
	tw.tween_property(_sub_l, "modulate:a", 1.0, 0.3).set_delay(0.95)
	tw.tween_callback(_slam).set_delay(0.75)
	await get_tree().create_timer(DURATION - 0.4, true, false, true).timeout
	_leave()

## Nome bate na tela: flash branco, tremida e o "tchan".
func _slam() -> void:
	_flash = 1.0
	_shake = 6.0
	Sfx.play(self, "boss_sting", 0.0)

func _leave() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_left, "position:x", -220.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_property(_right, "position:x", 720.0, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(func():
		finished.emit()
		queue_free())

func _input(event: InputEvent) -> void:
	# dá pra pular depois de 1s (clique, espaço, enter)
	if _t > 1.0 and not _done and event.is_pressed() and (event is InputEventMouseButton
			or event.is_action("ui_accept") or event.is_action("dodge")):
		get_viewport().set_input_as_handled()
		_leave()

func _process(delta: float) -> void:
	_t += delta
	_shake = move_toward(_shake, 0.0, delta * 30.0)
	_flash = move_toward(_flash, 0.0, delta * 4.0)
	position = (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake).round()
	_flash_rect.color.a = _flash * 0.8
	queue_redraw()

func _draw() -> void:
	var o := -position
	draw_rect(Rect2(o, Vector2(640, 360)), Color(0.02, 0.0, 0.04, 0.82))
	# faixa diagonal do chefe (lado direito) na cor dele, com listras se mexendo
	var k := clampf(_t / 0.35, 0.0, 1.0)
	var x0 := lerpf(700.0, 300.0, 1.0 - pow(1.0 - k, 3.0))
	var band := PackedVector2Array([Vector2(x0 + 60, 0), Vector2(900, 0), Vector2(900, 360), Vector2(x0 - 60, 360)])
	draw_colored_polygon(band, color.darkened(0.55))
	for i in 14:
		var sx := fmod(i * 40.0 + _t * 120.0, 560.0) + x0 - 60.0
		draw_line(Vector2(sx + 60, 0), Vector2(sx - 60, 360), Color(color, 0.18), 10.0)
	draw_line(Vector2(x0 + 60, 0), Vector2(x0 - 60, 360), color.lightened(0.3), 3.0)
	# faixa do estudante (esquerda), azul
	var kl := clampf(_t / 0.3, 0.0, 1.0)
	var xl := lerpf(-80.0, 200.0, 1.0 - pow(1.0 - kl, 3.0))
	draw_colored_polygon(PackedVector2Array([Vector2(-200, 0), Vector2(xl + 40, 0), Vector2(xl - 40, 360), Vector2(-200, 360)]), Color("1c2a4a"))
	draw_line(Vector2(xl + 40, 0), Vector2(xl - 40, 360), Color("6a9aff"), 3.0)
	# brilho atrás do chefe
	if _right:
		var c := _right.position + _right.size / 2.0
		for i in 4:
			draw_circle(c, 130.0 - i * 26.0, Color(color, 0.06 + i * 0.03))
	# barras de cinema
	var bar := 28.0 * minf(_t / 0.25, 1.0)
	draw_rect(Rect2(o, Vector2(640, bar)), Color.BLACK)
	draw_rect(Rect2(o + Vector2(0, 360 - bar), Vector2(640, bar)), Color.BLACK)
