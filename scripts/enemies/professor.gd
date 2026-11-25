extends Enemy
## Professor (à distância): mantém distância, anda de lado e arremessa
## um leque de provas corrigidas (com nota vermelha).

const BLAZER := Color("7a5236")

var _cd := 1.5
var _windup := 0.0
var _strafe := 1.0
var _strafe_t := 0.0

func _setup() -> void:
	display_name = "Professor"
	max_hp = 7 + floor_level
	speed = 32.0 + floor_level * 2.0
	hit_color = Color("f4efe2")
	drop_chance = 0.15
	_cd = randf_range(1.2, 2.2)
	lines = ["Prova surpresa!", "Isso cai na prova!", "Silêncio!", "Nota zero!", "Chamada!", "Celular guardado!"]
	death_lines = ["Aula dispensada...", "Vou pedir licença...", "Reprovado... eu?"]

func _think(delta: float) -> Vector2:
	var to := to_player()
	var d := to.length()
	_strafe_t -= delta
	if _strafe_t <= 0.0:
		_strafe_t = randf_range(1.0, 2.0)
		_strafe = -_strafe
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_throw(to)
		return Vector2.ZERO
	_cd -= delta
	if _cd <= 0.0 and d < 260.0:
		_windup = 0.45
		_squash = Vector2(0.85, 1.15)
		alert = true
		return Vector2.ZERO
	var dir := to.normalized()
	var want := dir.orthogonal() * _strafe * 0.8
	if d < 100.0:
		want -= dir
	elif d > 180.0:
		want += dir
	return want.normalized() * speed

func _throw(to: Vector2) -> void:
	alert = false
	_cd = randf_range(1.8, 2.4) - floor_level * 0.1
	_squash = Vector2(1.2, 0.85)
	var n := 3 + mini(floor_level - 1, 2)
	var spread := deg_to_rad(16.0)
	var base := to.angle() - spread * (n - 1) / 2.0
	for i in n:
		shoot("prova", Vector2.from_angle(base + spread * i), 105.0 + floor_level * 5.0)

func _on_death() -> void:
	spawn_decal("papel", Color.WHITE)

func _draw_body() -> void:
	# blazer marrom, careca com cabelo branco dos lados, óculos, gravata e pilha de provas
	var b := draw_person(BLAZER, Color("2e2a36"), Color("c8c4bc"))
	fb(-2, -14 + b, 4, 1, SKIN)                 # careca
	fb(-1, -14 + b, 1, 1, Color("fff0e0"))
	ob(1, -11 + b, 3, 1)
	fb(1, -11 + b, 3, 1, Color("bfe3ff"))       # óculos
	fb(-1, -7 + b, 2, 3, Color("e0d8d0"))       # camisa
	fb(0, -7 + b, 1, 3, Color("c0383a"))        # gravata
	var raise := 3.0 if _windup > 0.0 else 0.0
	bb(3, -7 + b - raise, 4, 3, PAPER)
	fb(5, -6 + b - raise, 1, 1, Color("e0382f"))
	draw_front_arm(BLAZER, b, raise)
