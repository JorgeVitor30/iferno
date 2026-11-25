class_name Fx
extends RefCounted
## Efeitos reutilizáveis: pedacinhos voando, texto flutuante, tremida de tela.
## Tudo estático: chame Fx.burst(...), Fx.float_text(...), Fx.shake(...).

const OUTLINE := Color("1a1020")
const PAPER := Color("f4efe2")

## Treme a câmera (quem escuta é o nó no grupo "shaker", ver floor.gd).
static func shake(ctx: Node, strength: float = 3.0) -> void:
	if ctx.is_inside_tree():
		ctx.get_tree().call_group("shaker", "shake", strength)

## Explosão de quadradinhos (papel, água, tinta...). O nó se apaga sozinho.
static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 10,
		speed: float = 60.0, size: float = 2.0, gravity: float = 140.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 5
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(amount, 1)
	p.lifetime = 0.55
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, gravity)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.damping_min = 30.0
	p.damping_max = 70.0
	p.scale_amount_min = maxf(size * 0.6, 1.0)
	p.scale_amount_max = size
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	fade.add_point(0.7, color)
	p.color_ramp = fade
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

## Texto que sobe e some (dano, cura, falas curtas).
static func float_text(parent: Node, pos: Vector2, text: String, color: Color, size: int = 10) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var l := Label.new()
	l.text = text
	l.z_index = 30
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(120, 14)
	l.position = pos - Vector2(60, 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 18.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.tween_callback(l.queue_free)

## Retângulo com contorno escuro de 1px (cara de pixel art).
static func orect(ci: CanvasItem, r: Rect2, color: Color) -> void:
	ci.draw_rect(r.grow(1.0), OUTLINE)
	ci.draw_rect(r, color)

## Texto pequeno desenhado direto num _draw().
static func text(ci: CanvasItem, pos: Vector2, s: String, color: Color, size: int = 8,
		width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos, s, align, width, size, color)
