extends StaticBody2D
## Tia da lojinha: velhinha narigudona, parada atrás do balcão.
## Fala sozinha de vez em quando e reage quando o estudante compra (ou não tem dinheiro).
## Desenhada em código (placeholder até ter sprite).

const OUT := Color("0b0612")
const SKIN := Color("e8a982")
const SKIN_D := Color("c47e5e")
const NOSE := Color("d98a6a")
const HAIR := Color("c8c4d0")
const HAIR_D := Color("8e8a9a")
const DRESS := Color("7a3a6a")
const DRESS_D := Color("562a4c")
const APRON := Color("e8e0d0")
const APRON_D := Color("b8ae9c")

const IDLE_LINES := ["Vai levar o quê, meu filho?", "Tá barato, tá barato!", "Fiado só amanhã!",
	"Coração fresquinho, saiu agora!", "Aceito moedinha, viu?", "No meu tempo era tudo mais barato...",
	"Estuda, menino, estuda!", "Leva dois que eu faço desconto. Mentira."]
const THANKS := ["Obrigada, volte sempre!", "Ótima escolha, querido!", "Isso, gasta mesmo!", "Deus te abençoe!"]
const BROKE := ["Sem dinheiro não dá, né?", "Vai juntar moedinha, vai!", "Aqui não é fiado não!"]
const FULL := ["Tá com a vida cheia, meu bem.", "Guarda pra depois, tá inteiro!"]

var _t := 0.0
var _talk_cd := 2.0
var _bubble: Label
var _mouth := 0.0 # mexe a boca enquanto fala

func _ready() -> void:
	add_to_group("shopkeeper")
	collision_layer = 1
	collision_mask = 0
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20, 8)
	col.shape = box
	col.position = Vector2(0, -4)
	add_child(col)

func _process(delta: float) -> void:
	_t += delta
	_mouth = maxf(_mouth - delta, 0.0)
	_talk_cd -= delta
	if _talk_cd <= 0.0:
		_talk_cd = randf_range(5.0, 9.0)
		# só puxa conversa se o estudante estiver por perto
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p and p.global_position.distance_to(global_position) < 260.0:
			say(IDLE_LINES.pick_random())
	queue_redraw()

func react(kind: String) -> void:
	match kind:
		"thanks": say(THANKS.pick_random())
		"broke": say(BROKE.pick_random())
		"full": say(FULL.pick_random())
	_talk_cd = randf_range(5.0, 8.0)

## Balão de fala em cima da cabeça.
func say(text: String) -> void:
	if _bubble and is_instance_valid(_bubble):
		_bubble.queue_free()
	var l := Label.new()
	l.text = text
	l.z_index = 25
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	l.add_theme_font_size_override("font_size", Fx.SMALL)
	l.add_theme_color_override("font_color", Color("fff4dc"))
	l.add_theme_color_override("font_outline_color", OUT)
	l.add_theme_constant_override("outline_size", 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(220, 12)
	l.position = Vector2(-110, -70)
	l.pivot_offset = Vector2(110, 12)
	l.scale = Vector2(0.2, 0.2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	_bubble = l
	_mouth = 1.2
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------- desenho (unidades de arte = 2px)

func _b(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x - 0.5, y - 0.5, w + 1, h + 1), OUT)
	draw_rect(Rect2(x, y, w, h), c)

func _f(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func _draw() -> void:
	Fx.contact_shadow(self, Vector2(0, -1), 12.0, 1.5, 4.0)
	# respiração: o tronco sobe 1px de vez em quando
	var breath := -1.0 if fmod(_t, 2.2) < 1.1 else 0.0
	draw_set_transform(Vector2(0, breath), 0.0, Vector2(2, 2))
	# vestido e avental (corpo de 14x13, origem nos pés)
	_b(-7, -14, 14, 14, DRESS)
	_f(3, -13, 3, 13, DRESS_D)
	_b(-5, -12, 10, 11, APRON)
	_f(2, -11, 3, 10, APRON_D)
	_f(-3, -7, 6, 2, APRON_D) # bolso
	# braços cruzados na frente
	_b(-7, -11, 14, 3, DRESS)
	_f(-6, -10, 3, 1, SKIN)
	_f(3, -10, 3, 1, SKIN)
	# cabeça
	_b(-5, -23, 10, 9, SKIN)
	_f(2, -22, 3, 8, SKIN_D)
	# cabelo grisalho com coque
	_b(-6, -25, 12, 4, HAIR)
	_b(-6, -23, 2, 5, HAIR)
	_b(4, -23, 2, 5, HAIR)
	_b(-3, -28, 6, 4, HAIR)
	_f(-2, -27, 2, 1, Color.WHITE)
	_f(1, -27, 2, 3, HAIR_D)
	_f(-6, -22, 12, 1, HAIR_D)
	# óculos redondinhos
	_f(-4, -20, 3, 2, OUT)
	_f(1, -20, 3, 2, OUT)
	_f(-3, -20, 1, 1, Color("bfe6ff"))
	_f(2, -20, 1, 1, Color("bfe6ff"))
	_f(-1, -20, 2, 1, OUT)
	# narigão (sai pra frente e pra baixo)
	_b(-1, -19, 3, 4, NOSE)
	_f(1, -16, 2, 1, NOSE.darkened(0.2))
	_f(-1, -19, 1, 1, NOSE.lightened(0.25))
	# verruga
	_f(-4, -17, 1, 1, Color("8a4a3a"))
	# boca (mexe quando fala)
	var open := _mouth > 0.0 and int(_t * 10.0) % 2 == 0
	_f(-1, -15, 2, 1 if not open else 2, Color("6a2a2a"))
	draw_set_transform(Vector2.ZERO)
