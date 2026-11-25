extends CanvasLayer
## HUD do andar: vida, nome da sala, contador de inimigos, faixas de aviso
## ("CHAMADA! NINGUÉM SAI!", "AULA DISPENSADA!"), minimapa e fade.
## As salas falam com o HUD pelo grupo "hud" (banner, set_counter).

const OUTLINE := Color("1a1020")
const MINIMAP := preload("res://scripts/minimap.gd")

@onready var health_bar: Control = $HealthBar
@onready var fade: ColorRect = $Fade

var _title := Label.new()
var _counter := Label.new()
var _banner := Label.new()
var _hurt := ColorRect.new()
var _map: Control
var _boss_bar: BossBar
var _banner_tw: Tween
var _title_tw: Tween

func _ready() -> void:
	add_to_group("hud")
	_hurt.color = Color(0.85, 0.1, 0.1, 0.0)
	_hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hurt.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_hurt)
	move_child(_hurt, 0)
	_style(_title, 10, Color("f4e4c0"))
	_title.position = Vector2(0, 6)
	_title.size = Vector2(640, 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_style(_counter, 9, Color("ff9a8a"))
	_counter.position = Vector2(8, 20)
	_counter.visible = false
	add_child(_counter)
	_style(_banner, 20, Color.WHITE)
	_banner.position = Vector2(0, 92)
	_banner.size = Vector2(640, 30)
	_banner.pivot_offset = Vector2(320, 15)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	add_child(_banner)
	move_child(fade, get_child_count() - 1) # fade por cima de tudo

func _style(l: Label, size: int, color: Color) -> void:
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 5 if size >= 16 else 4)

func setup(level: Node) -> void:
	_map = MINIMAP.new()
	_map.level = level
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_map)
	move_child(fade, get_child_count() - 1)

func set_health(hp: int, max_hp: int) -> void:
	health_bar.set_health(hp, max_hp)

func refresh_map() -> void:
	if _map:
		_map.queue_redraw()

## Nome do andar na entrada, com fade do preto.
func intro(top: String, sub: String) -> void:
	fade.color.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.6)
	banner(top + "\n" + sub, Color("ffd966"), 2.4)

func fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.7)
	await tw.finished

func set_title(t: String) -> void:
	_title.text = t
	if _title_tw:
		_title_tw.kill()
	_title.modulate.a = 1.0
	_title_tw = create_tween()
	_title_tw.tween_interval(2.5)
	_title_tw.tween_property(_title, "modulate:a", 0.35, 0.6)

## n < 0 esconde o contador.
func set_counter(n: int) -> void:
	_counter.visible = n >= 0
	_counter.text = "INIMIGOS: %d" % n
	if n >= 0:
		_counter.scale = Vector2(1.3, 1.3)
		create_tween().tween_property(_counter, "scale", Vector2.ONE, 0.15)

## Faixa grande no meio da tela que "pula" e some.
func banner(text: String, color: Color, hold: float = 1.2) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.size = Vector2(640, 30)
	_banner.position.y = 80 if text.contains("\n") else 92
	if _banner_tw:
		_banner_tw.kill()
	_banner.modulate.a = 1.0
	_banner.scale = Vector2(1.8, 1.8)
	_banner.rotation = deg_to_rad(randf_range(-3, 3))
	_banner_tw = create_tween()
	_banner_tw.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tw.tween_interval(hold)
	_banner_tw.tween_property(_banner, "modulate:a", 0.0, 0.4)

## Barra de vida do chefe embaixo da tela. Some sozinha quando ele cai.
func show_boss(enemy: Node) -> void:
	if _boss_bar == null:
		_boss_bar = BossBar.new()
		add_child(_boss_bar)
		move_child(fade, get_child_count() - 1)
	_boss_bar.track(enemy)

func hurt_flash() -> void:
	_hurt.color.a = 0.35
	create_tween().tween_property(_hurt, "color:a", 0.0, 0.3)
