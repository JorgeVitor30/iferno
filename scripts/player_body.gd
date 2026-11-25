extends Node2D
## Desenho do estudante no estilo "clean": bonequinho compacto de cabeça grande
## (cabelo castanho fofo, moletom azul-marinho, mochila roxa), pixel GROSSO (2x).
## Fica como filho do Sprite2D do jogador (que ficou invisível), assim herda o
## pulinho do dodge e as piscadas/cor de dano que o player.gd já aplica nele.
## 8 direções a partir de 5 vistas (s, se, e, ne, n); as da esquerda espelham.

const A := 2.0
const OUT := Color("0b0612")
const HAIR := Color("5a3226")
const HAIR_L := Color("7a4636")
const HAIR_D := Color("3a1d26")
const SKIN := Color("f0b48a")
const SKIN_D := Color("d08a6a")
const HOOD := Color("2c2f5a")
const HOOD_L := Color("3c4274")
const HOOD_D := Color("1e2042")
const PACK := Color("6a4a8a")
const PACK_L := Color("8a64aa")
const PANTS := Color("1c1830")
const GUN := Color("2a2838")
const GUN_L := Color("5a5670")

var player: CharacterBody2D
var view := "s"
var flip := false
var _t := 0.0

func _ready() -> void:
	player = get_parent().get_parent() as CharacterBody2D

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _o(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), OUT)

func _f(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

func _draw() -> void:
	if player == null:
		return
	var rolling: bool = player.is_rolling()
	var aim: Vector2 = (player.get_global_mouse_position() - player.global_position).normalized()
	# sombra (fica no chão mesmo no pulinho: compensa a posição do pai)
	var hop: float = -(get_parent() as Node2D).position.y + 2.0
	draw_set_transform(Vector2(0, hop), 0.0, Vector2(A, A * 0.5))
	draw_circle(Vector2.ZERO, 4.5, Color(0, 0, 0, 0.35))
	if rolling:
		_draw_roll()
		return
	var moving: bool = player.velocity.length() > 10.0
	var step := 0
	if moving:
		step = 1 if int(_t * 8.0) % 2 == 0 else -1
	var bob := 0.0
	if not moving and fmod(_t, 1.2) < 0.6:
		bob = 1.0 # respirando (ofegante)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-A if flip else A, A))
	var gun_behind := aim.y < -0.3
	if gun_behind:
		_draw_gun(aim)
	_draw_figure(step, bob)
	if not gun_behind:
		_draw_gun(aim)

func _draw_figure(step: int, bob: float) -> void:
	var b := bob
	var lift_l := 1.0 if step == 1 else 0.0
	var lift_r := 1.0 if step == -1 else 0.0
	var back := view == "n" or view == "ne"
	var side := view == "e"
	# --- contornos (tudo junto, depois preenche: as peças "grudam")
	_o(-3, -2 - lift_l, 2, 2)
	_o(1, -2 - lift_r, 2, 2)
	_o(-3, -7 + b, 6, 5)
	_o(-4, -15 + b, 8, 8)
	_o(-5, -13 + b, 10, 5)
	if side:
		_o(-4, -7 + b, 2, 4) # mochila de lado
	# --- pernas
	_f(-3, -2 - lift_l, 2, 2, PANTS)
	_f(1, -2 - lift_r, 2, 2, PANTS)
	# --- corpo (moletom)
	_f(-3, -7 + b, 6, 5, HOOD)
	_f(-3, -7 + b, 6, 1, HOOD_L)
	_f(2, -6 + b, 1, 4, HOOD_D)
	if back:
		# mochila
		_f(-2, -7 + b, 4, 4, PACK)
		_f(-2, -7 + b, 4, 1, PACK_L)
	elif side:
		_f(-4, -7 + b, 2, 4, PACK)
		_f(-4, -7 + b, 2, 1, PACK_L)
		_f(1, -4 + b, 1, 1, SKIN) # mão
	else:
		_f(-1, -5 + b, 2, 2, HOOD_D) # bolso do moletom
		_f(-3, -3 + b, 1, 1, SKIN)    # mãos
		_f(2, -3 + b, 1, 1, SKIN)
	# --- cabeça: cabelo fofo grande
	_f(-4, -15 + b, 8, 8, HAIR)
	_f(-5, -13 + b, 10, 5, HAIR)
	_f(-3, -15 + b, 4, 1, HAIR_L)
	_f(-4, -14 + b, 2, 1, HAIR_L)
	_f(-5, -9 + b, 10, 1, HAIR_D)
	# rosto (depende da vista)
	match view:
		"s":
			_f(-3, -11 + b, 6, 3, SKIN)
			_f(-3, -9 + b, 6, 1, SKIN_D)
			_f(-2, -11 + b, 1, 1, OUT)
			_f(1, -11 + b, 1, 1, OUT)
			_f(-3, -12 + b, 6, 1, HAIR) # franja
		"se":
			_f(-1, -11 + b, 5, 3, SKIN)
			_f(-1, -9 + b, 5, 1, SKIN_D)
			_f(0, -11 + b, 1, 1, OUT)
			_f(3, -11 + b, 1, 1, OUT)
			_f(-1, -12 + b, 4, 1, HAIR)
		"e":
			_f(1, -11 + b, 3, 3, SKIN)
			_f(1, -9 + b, 3, 1, SKIN_D)
			_f(3, -11 + b, 1, 1, OUT)
			_f(4, -10 + b, 1, 1, SKIN)  # nariz
		"ne":
			_f(3, -11 + b, 1, 2, SKIN)  # pontinha da bochecha
		_:
			pass # "n": só cabelo

## Arminha na mão, apontando pra mira (em passos de 45° pra não borrar).
func _draw_gun(aim: Vector2) -> void:
	var a := snappedf(aim.angle(), PI / 4.0)
	var dir := Vector2.from_angle(a)
	if flip:
		dir.x = -dir.x
	var hand := Vector2(1.5, -4.5)
	var p := hand + dir * 2.5
	var q := hand + dir * 5.5
	draw_line(p, q, OUT, 3.0)
	draw_line(p, q, GUN, 1.5)
	draw_rect(Rect2((q - Vector2(0.5, 0.5)).round(), Vector2(1, 1)), GUN_L)

## Dodge: vira uma bolinha (cabelo + moletom) girando de 90 em 90 graus.
func _draw_roll() -> void:
	var t: float = 1.0 - player._roll_timer / player.roll_time
	var turns := int(t * 4.0)
	var dirx := -1.0 if player._roll_dir.x < 0.0 else 1.0
	draw_set_transform(Vector2(0, -8), dirx * turns * PI / 2.0, Vector2(A, A))
	draw_circle(Vector2.ZERO, 4.5, OUT)
	draw_circle(Vector2.ZERO, 3.5, HOOD)
	draw_rect(Rect2(-4, -4, 8, 4), HAIR)
	draw_rect(Rect2(-3, -4, 4, 1), HAIR_L)
	draw_rect(Rect2(-1, 1, 3, 2), PACK)
