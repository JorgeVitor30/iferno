class_name Fx
extends RefCounted
## Efeitos reutilizáveis: pedacinhos voando, texto flutuante, tremida de tela.
## Tudo estático: chame Fx.burst(...), Fx.float_text(...), Fx.shake(...).

const OUTLINE := Color("0b0612") # contorno quase preto (estilo clean)
const PAPER := Color("e8e0d8")
## Escala da arte do mundo: cada pixel de arte vira 2x2 na tela (pixel "gordo",
## estilo clean). O HUD continua em 1x pra texto ficar legível.
const ART := 2.0
## Paleta base do estilo (tirada da referência)
const BG := Color("0e0718")
const CAP := Color("150b1f")
const CAP_RIM := Color("2a1f38")
const SMALL := 11 # tamanho normal da fonte pixel (ver scripts/pixel_font.gd)
const BIG := 22   # 2x, pra faixas grandes

## A fonte pixel só fica nítida em múltiplos do tamanho base: arredonda pra 11 ou 22.
static func px(size: int) -> int:
	return BIG if size >= 18 else SMALL

## Largura do texto na fonte do jogo.
static func text_width(s: String, size: int = SMALL) -> float:
	return ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px(size)).x

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
	var px_size := 2.0 if size < 2.6 else 4.0 # pixel grosso, sempre 2 ou 4
	p.scale_amount_min = px_size
	p.scale_amount_max = px_size
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
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	l.add_theme_font_size_override("font_size", px(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(120, 14)
	l.position = pos - Vector2(60, 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 18.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tw.tween_callback(l.queue_free)

static var _glow_tex: Texture2D

## Brilho de luz (soma de cor, em anéis "degrau" pra combinar com pixel art).
## Bom pra máquina de refrigerante, telas, poste, cafeteira...
static func glow(parent: Node, pos: Vector2, radius: float, color: Color, strength: float = 1.0) -> Sprite2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		g.offsets = PackedFloat32Array([0.0, 0.35, 0.65, 0.95])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.42), Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_glow_tex = t
	var s := Sprite2D.new()
	s.texture = _glow_tex
	s.position = pos
	s.scale = Vector2.ONE * (radius * 2.0 / 32.0)
	s.modulate = Color(color, color.a * strength)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.z_index = 1
	parent.add_child(s)
	return s

## Chão/parede repetindo uma textura de pixel grosso (desenhada em escala ART).
static func tiled(parent: Node, tex: Texture2D, r: Rect2, tint: Color = Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size / ART)
	s.scale = Vector2(ART, ART)
	s.position = r.position
	s.modulate = tint
	parent.add_child(s)
	return s

## Retângulo com contorno escuro de 1px, luz e sombra (cara de pixel art).
static func orect(ci: CanvasItem, r: Rect2, color: Color) -> void:
	ci.draw_rect(r.grow(1.0), OUTLINE)
	ci.draw_rect(r, color)
	bevel(ci, r, color)

## Luz em cima/esquerda, sombra embaixo/direita e uma textura pontilhada (dithering)
## na metade de baixo. Deixa os desenhos com a mesma densidade de detalhe do
## protagonista (que tem sombreado e textura), em vez de blocos de cor chapada.
static func bevel(ci: CanvasItem, r: Rect2, c: Color, dither: bool = false) -> void:
	r = Rect2(r.position.round(), r.size.round())
	if r.size.x < 3.0 or r.size.y < 3.0:
		return
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), c.lightened(0.2))
	ci.draw_rect(Rect2(r.position.x, r.position.y + 1, 1, r.size.y - 1), c.lightened(0.1))
	ci.draw_rect(Rect2(r.position.x + 1, r.end.y - 1, r.size.x - 1, 1), c.darkened(0.3))
	ci.draw_rect(Rect2(r.end.x - 1, r.position.y + 1, 1, r.size.y - 2), c.darkened(0.18))
	if not dither or r.size.x < 6.0 or r.size.y < 6.0:
		return
	# pontilhado: mais denso perto da base, some no meio (degradê em pixel art)
	var d := c.darkened(0.12)
	var x0 := int(r.position.x) + 1
	var x1 := int(r.end.x) - 1
	var y1 := int(r.end.y) - 1
	var mid := int(r.position.y + r.size.y * 0.5)
	for y in range(mid, y1):
		var dense := y >= int(r.end.y - r.size.y * 0.25)
		for x in range(x0, x1):
			if posmod(x + y, 2) == 0 and (dense or posmod(x, 4) == posmod(y, 4)):
				ci.draw_rect(Rect2(x, y, 1, 1), d)

## Texto pequeno desenhado direto num _draw().
static func text(ci: CanvasItem, pos: Vector2, s: String, color: Color, size: int = 8,
		width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(ThemeDB.fallback_font, pos.round(), s, align, width, px(size), color)
