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
	var bob := draw_person(BLAZER, Color("3a3440"), Color("d8d4cc"))
	# careca no topo + cabelo branco dos lados
	draw_rect(Rect2(-3, -31 + bob, 6, 2), SKIN)
	# óculos
	draw_rect(Rect2(1, -27 + bob, 4, 3), Fx.OUTLINE)
	draw_rect(Rect2(2, -26 + bob, 2, 1), Color("bfe3ff"))
	# camisa e gravata
	draw_rect(Rect2(-1, -20 + bob, 4, 6), Color("e8e4dc"))
	draw_rect(Rect2(0, -19 + bob, 2, 6), Color("c0392b"))
	# pilha de provas na mão
	var raise := 6.0 if _windup > 0.0 else 0.0
	var stack := Rect2(5, -16 + bob - raise, 8, 6)
	draw_rect(stack.grow(1.0), Fx.OUTLINE)
	draw_rect(stack, Color("f4efe2"))
	draw_rect(Rect2(6, -14 + bob - raise, 6, 1), Color("9a9aa8"))
	draw_rect(Rect2(10, -12 + bob - raise, 2, 2), Color("e0382f"))
	draw_front_arm(BLAZER, bob, raise)
