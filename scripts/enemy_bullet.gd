extends Area2D
## Projétil de papel dos inimigos. A posição do nó é no chão (sombra);
## o desenho voa uns pixels acima, na altura da mão.
##   "prova"   folha de prova girando (com nota vermelha)
##   "aviao"   aviãozinho de papel que vai virando atrás do jogador
##   "bolinha" papel amassado
##   "giz"     pontinho de giz (os ataques de gráfico/função do professor de estatística)
##   "digito"  um número voando (sai da calculadora)
##   "calculadora" calculadora girando que explode em números quando chega no alvo
## `curve` faz o projétil andar numa curva em vez de reto: "log" segue y = a·ln(1 + x/k).
## Durante o dodge roll o jogador atravessa o papel sem tomar dano.

const OUTLINE := Color("0b0612")
const PAPER := Color("e8e0d8")
const HEIGHT := 11.0

var kind := "bolinha"
var direction := Vector2.RIGHT
var speed := 100.0
var homing := 0.0 # rad/s que o aviãozinho consegue virar
var lifetime := 4.0
var curve := ""          # "" = reto, "log" = curva logarítmica
var curve_amp := 0.0     # quanto a curva abre pro lado (pode ser negativo)
var explode_dist := -1.0 # calculadora: explode depois de andar isso
var digit := "7"
var _t := 0.0
var _origin := Vector2.ZERO
var _dist := 0.0
var _spin := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # paredes e jogador
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	col.shape = c
	add_child(col)
	body_entered.connect(_on_body_entered)
	_spin = randf() * TAU
	_origin = position
	if kind == "calculadora":
		c.radius = 6.0
	if kind == "digito":
		digit = str(randi() % 10)

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		_pop()
		return
	if homing > 0.0 and _t > 0.25:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p and p.visible:
			var want := (p.global_position - global_position).angle()
			var a := rotate_toward(direction.angle(), want, homing * delta)
			direction = Vector2.from_angle(a)
	_dist += speed * delta
	if curve == "log":
		# anda ao longo da reta e desvia pro lado seguindo o logaritmo
		var side := direction.orthogonal()
		position = _origin + direction * _dist + side * curve_amp * log(1.0 + _dist / 40.0)
	else:
		position += direction * speed * delta
	if explode_dist > 0.0 and _dist >= explode_dist:
		_pop()
		return
	_spin += delta * (14.0 if kind == "prova" else 9.0)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("is_rolling") and body.is_rolling():
			return # desviou!
		body.take_damage(1)
	_pop()

func _pop() -> void:
	if kind == "calculadora":
		_explode()
	Fx.burst(get_parent(), position + Vector2(0, -HEIGHT), PAPER if kind != "giz" else Color("fff4b0"), 5, 45.0, 1.5)
	queue_free()

## Calculadora estoura num anel de números.
func _explode() -> void:
	var parent := get_parent()
	if parent == null:
		return
	Fx.burst(parent, position + Vector2(0, -HEIGHT), Color("4a4a58"), 14, 90.0, 2.5)
	Fx.shake(self, 2.0)
	var n := 10
	var off := randf() * TAU
	for i in n:
		var b: Area2D = (get_script() as GDScript).new()
		b.kind = "digito"
		b.direction = Vector2.from_angle(off + i * TAU / n)
		b.speed = 85.0
		b.lifetime = 3.0
		b.position = position + b.direction * 6.0
		parent.call_deferred("add_child", b)

# ---------------------------------------------------------------- desenho
# Sprites dos projéteis em pixel art 1x (detalhados), montados de mapas de pixels
# uma vez só e guardados como textura.

const MAPS := {
	"prova": [
		"OOOOOOOOOO..",
		"OWWWWWWWWfO.",
		"OWHHHHHHWffO",
		"OWWWWWWWWWWO",
		"OWLLLLLLWWWO",
		"OWWWWWWWWWWO",
		"OWLLLLLWWWWO",
		"OWWWWWWWWWWO",
		"OWLLLLLLLWWO",
		"OWWWWWWWWWWO",
		"OWLLLWWRRRWO",
		"OWWWWWWRWRWO",
		"OWWWWWWRRRWO",
		"OWSSSSSSSSSO",
		"OOOOOOOOOOOO",
	],
	"calculadora": [
		"OOOOOOOOOOOO",
		"OBBBBBBBBBBO",
		"OBGGGGGGGGBO",
		"OBGDGDDGDGBO",
		"OBGGGGGGGGBO",
		"OBBBBBBBBBBO",
		"OBKKBKKBKKBO",
		"OBKKBKKBKKBO",
		"OBBBBBBBBBBO",
		"OBKKBKKBKKBO",
		"OBKKBKKBKKBO",
		"OBBBBBBBBBBO",
		"OBKKBKKBEEBO",
		"OBKKBKKBEEBO",
		"OBBBBBBBBBBO",
		"OSSSSSSSSSSO",
		"OOOOOOOOOOOO",
	],
	"bolinha": [
		"..OOOOOO..",
		".OWWWSWWO.",
		"OWWSWWWWSO",
		"OWWWWWSWWO",
		"OSWWWWWWWO",
		"OWWSWWWSWO",
		"OWWWWSWWWO",
		"OWSWWWWWSO",
		".OWWWSWWO.",
		"..OOOOOO..",
	],
	"aviao": [
		"OO..............",
		"OWOO............",
		"OWWWOOO.........",
		"OWWWWWWOOOO.....",
		"OSSSSSSSSSSOOOOO",
		"OWWWWWWOOOO.....",
		"OWWWOOO.........",
		"OWOO............",
		"OO..............",
	],
}
const PAL := {
	"O": Color("0b0612"), "W": Color("f2ede4"), "f": Color("cfc6b8"), "H": Color("6a6278"),
	"L": Color("a8a0b0"), "R": Color("d9363e"), "S": Color("d2c9bc"), "B": Color("3e3e4c"),
	"G": Color("9fd89a"), "D": Color("2a4a2a"), "K": Color("c8c8d4"), "E": Color("ff8a3a"),
}
static var _tex := {}

static func _texture(kind_name: String) -> Texture2D:
	if _tex.has(kind_name):
		return _tex[kind_name]
	var rows: Array = MAPS[kind_name]
	var img := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if PAL.has(ch):
				img.set_pixel(x, y, PAL[ch])
	var t := ImageTexture.create_from_image(img)
	_tex[kind_name] = t
	return t

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 4.5, Color(0, 0, 0, 0.35))
	var up := Vector2(0, -HEIGHT)
	# Gira só em passos (90° ou 45°): pixel art girado livremente desmancha.
	var spin90 := snappedf(_spin, PI / 2.0)
	match kind:
		"prova", "calculadora", "bolinha":
			var t := _texture(kind)
			draw_set_transform(up - (Vector2(0, 3) if kind == "calculadora" else Vector2.ZERO), spin90, Vector2.ONE)
			draw_texture(t, -(t.get_size() / 2.0).floor())
		"aviao":
			var t2 := _texture("aviao")
			draw_set_transform(up, snappedf(direction.angle(), PI / 4.0), Vector2.ONE)
			draw_texture(t2, -(t2.get_size() / 2.0).floor())
		"giz":
			draw_set_transform(up)
			draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.88, 0.5, 0.35))
			draw_circle(Vector2.ZERO, 3.5, Color("0b0612"))
			draw_circle(Vector2.ZERO, 2.6, Color("ffe08a"))
			draw_rect(Rect2(-1, -2, 2, 2), Color("fffbe8"))
		"digito":
			draw_set_transform(up)
			draw_rect(Rect2(-5, -7, 11, 13), OUTLINE)
			draw_rect(Rect2(-4, -6, 9, 11), Color("9fd89a"))
			draw_rect(Rect2(-4, -6, 9, 1), Color("c8f0c0"))
			Fx.text(self, Vector2(-4, 3), digit, Color("1f3a1f"), Fx.SMALL, 9, HORIZONTAL_ALIGNMENT_CENTER)
		_:
			var t3 := _texture("bolinha")
			draw_set_transform(up, spin90, Vector2.ONE)
			draw_texture(t3, -(t3.get_size() / 2.0).floor())
