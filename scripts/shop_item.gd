extends Node2D
## Item à venda na lojinha da tia: fica flutuando em cima de um banquinho com o preço.
## Chegou perto: aparece "[E] COMPRAR" e o nome. Apertou E: paga com moedas.
## Tipos (por enquanto): "vida" (1 coração), "meia_vida", "buff" (upgrade escolhido
## e mostrado) e "buff_aleatorio" (upgrade surpresa, mais barato).

const OUT := Color("0b0612")
const PRICES := {"vida": 10, "meia_vida": 6, "buff": 18, "buff_aleatorio": 12}
const NAMES := {"vida": "VIDA (1 CORAÇÃO)", "meia_vida": "MEIA VIDA", "buff_aleatorio": "UPGRADE SURPRESA"}
const REACH := 30.0

var kind := "vida"
var buff_id := "" # pro tipo "buff": qual upgrade está à venda
var price := 10
var _t := 0.0
var _near := false
var _sold := false

func _ready() -> void:
	price = PRICES[kind]
	if kind == "buff" and buff_id == "":
		buff_id = _random_buff()
	_t = randf() * 3.0

## Upgrade comum sorteado (sem o café, que é coisa de usar na hora).
func _random_buff() -> String:
	for id in Upgrades.roll(4):
		if id != "cafe":
			return id
	return "cafe"

func item_name() -> String:
	if kind == "buff":
		return String(Upgrades.DEFS[buff_id]["name"]).replace("\n", " ")
	return NAMES[kind]

func _process(delta: float) -> void:
	_t += delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	_near = not _sold and p != null and p.global_position.distance_to(global_position + Vector2(0, -6)) < REACH
	if _near and Input.is_action_just_pressed("interact"):
		_buy(p)
	queue_redraw()

func _buy(p: Node) -> void:
	var tia := get_tree().get_first_node_in_group("shopkeeper")
	if kind in ["vida", "meia_vida"] and p.hp >= p.max_hp:
		if tia:
			tia.react("full")
		Sfx.play(self, "hover", 0.0)
		return
	if not Wallet.spend(self, price):
		if tia:
			tia.react("broke")
		Sfx.play(self, "hurt", 0.0)
		Fx.float_text(get_parent(), global_position + Vector2(0, -40), "SEM MOEDAS!", Color("ff8a7a"))
		return
	_sold = true
	Sfx.play(self, "pick", 0.0)
	Fx.burst(get_parent(), global_position + Vector2(0, -26), Color("ffd23f"), 14, 80.0)
	var text := item_name()
	match kind:
		"vida":
			p.heal(2)
		"meia_vida":
			p.heal(1)
		"buff", "buff_aleatorio":
			var id := buff_id
			if kind == "buff_aleatorio":
				id = _random_buff()
				text = String(Upgrades.DEFS[id]["name"]).replace("\n", " ")
			Upgrades.take(id, p)
			Sfx.play(self, "upgrade", 0.0)
			get_tree().call_group("hud", "refresh_upgrades")
	Fx.float_text(get_parent(), global_position + Vector2(0, -44), text + "!", Color("ffd966"))
	if tia:
		tia.react("thanks")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

# ---------------------------------------------------------------- desenho

func _draw() -> void:
	# banquinho (pedestal) com toalhinha
	Fx.contact_shadow(self, Vector2(1, -3), 14.0, 1.2, 4.0)
	draw_rect(Rect2(-13, -14, 26, 14), OUT)
	draw_rect(Rect2(-12, -13, 24, 12), Color("5a3a30"))
	draw_rect(Rect2(-12, -13, 24, 2), Color("7a5040"))
	draw_rect(Rect2(6, -11, 6, 10), Color("4a2e28"))
	draw_rect(Rect2(-14, -17, 28, 5), OUT)
	draw_rect(Rect2(-13, -16, 26, 3), Color("e8e0d0"))
	draw_rect(Rect2(-13, -14, 26, 1), Color("c84a4a"))
	# item flutuando
	var bob := roundf(sin(_t * 3.0) * 2.0)
	var c := Vector2(0, -32 + bob)
	if _near:
		for i in 3:
			draw_circle(c, 14.0 - i * 4.0, Color(1, 0.85, 0.3, 0.07 + i * 0.04))
	match kind:
		"vida":
			_heart(c, 1.0)
		"meia_vida":
			_heart(c, 0.5)
		"buff":
			Upgrades.draw_icon(self, buff_id, c - Vector2(8, 8), 1.0)
		"buff_aleatorio":
			draw_rect(Rect2(c - Vector2(8, 8), Vector2(16, 16)), OUT)
			draw_rect(Rect2(c - Vector2(7, 7), Vector2(14, 14)), Color("9a7aff"))
			draw_rect(Rect2(c - Vector2(7, 7), Vector2(14, 2)), Color("c0a8ff"))
			Fx.text(self, c + Vector2(-8, 6), "?", Color.WHITE, Fx.SMALL, 16, HORIZONTAL_ALIGNMENT_CENTER)
	# preço: moedinha + número
	var label := str(price)
	var w := Fx.text_width(label) + 12.0
	var pos := Vector2(-w / 2.0, 12)
	Wallet.draw_coin(self, pos + Vector2(3, -4), 1.0)
	var col := Color("ffd966") if Wallet.can_pay(price) else Color("ff8a7a")
	Fx.text(self, pos + Vector2(9, 0), label, col, Fx.SMALL)
	# chegou perto: nome + tecla
	if _near:
		var y := -54.0
		Fx.text(self, Vector2(-90, y), item_name(), Color("fff4dc"), Fx.SMALL, 180, HORIZONTAL_ALIGNMENT_CENTER)
		Fx.text(self, Vector2(-90, y + 12), "[E] COMPRAR", Color("ffd966"), Fx.SMALL, 180, HORIZONTAL_ALIGNMENT_CENTER)

## Coraçãozinho de pixel (inteiro ou metade).
func _heart(c: Vector2, fill: float) -> void:
	const SHAPE := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
	var s := 2.0
	var o := c - Vector2(7, 6) * s / 2.0 - Vector2(0, 0)
	for y in SHAPE.size():
		var row: String = SHAPE[y]
		for x in row.length():
			if row[x] != "#":
				continue
			var r := Rect2(o + Vector2(x, y) * s, Vector2(s, s))
			draw_rect(r.grow(1), OUT)
	for y in SHAPE.size():
		var row: String = SHAPE[y]
		for x in row.length():
			if row[x] != "#":
				continue
			var col := Color("e0383f") if x < 7 * fill else Color("3a2236")
			if y == 1 and (x == 1 or x == 4) and x < 7 * fill:
				col = Color("ffb0a8")
			draw_rect(Rect2(o + Vector2(x, y) * s, Vector2(s, s)), col)
