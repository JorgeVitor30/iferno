extends Enemy
## Zelador (corpo a corpo): chega perto, levanta o esfregão e dá uma esfregada em arco.
## Vai deixando pocinhas pelo chão e, quando cai, sobra a plaquinha de piso molhado.

enum State { CHASE, WINDUP, SWING, REST }

const UNIFORM := Color("3d6bb3")
const CAP := Color("24467e")
const WATER := Color("7ec8e3")

var _state := State.CHASE
var _t := 0.0
var _dir := Vector2.RIGHT
var _puddle_cd := 1.5

func _setup() -> void:
	display_name = "Zelador"
	max_hp = 7 + floor_level
	speed = 44.0 + floor_level * 3.0
	contact_damage = false
	hit_color = UNIFORM
	drop_chance = 0.12
	lines = ["Acabei de limpar!", "Ô, o piso!", "Sai da frente!", "Tá tudo molhado!", "Quem sujou isso?!"]
	death_lines = ["Meu esfregão...", "Vou bater o ponto...", "Hora extra não..."]

func _think(delta: float) -> Vector2:
	var to := to_player()
	_t -= delta
	_puddle_cd -= delta
	if _puddle_cd <= 0.0 and is_moving():
		_puddle_cd = randf_range(1.2, 2.4)
		spawn_decal("agua", WATER, position + Vector2(-facing * 6, 0))
	match _state:
		State.CHASE:
			if to.length() < 32.0:
				_state = State.WINDUP
				_t = 0.45 - floor_level * 0.03
				_dir = to.normalized()
				_squash = Vector2(0.85, 1.15)
			return to.normalized() * speed
		State.WINDUP:
			if _t <= 0.0:
				_state = State.SWING
				_t = 0.2
				_swing()
			return Vector2.ZERO
		State.SWING:
			if _t <= 0.0:
				_state = State.REST
				_t = 0.55
			return _dir * 40.0
		State.REST:
			if _t <= 0.0:
				_state = State.CHASE
			return to.normalized() * speed * 0.3
	return Vector2.ZERO

func _swing() -> void:
	_squash = Vector2(1.25, 0.85)
	Fx.shake(self, 1.5)
	Fx.burst(get_parent(), global_position + _dir * 20.0 + Vector2(0, -8), WATER, 10, 80.0)
	var to := to_player()
	if to.length() < 40.0 and to.normalized().dot(_dir) > 0.2:
		hurt_player()

func _on_death() -> void:
	spawn_decal("agua", WATER)
	spawn_decal("placa", Color.WHITE, position + Vector2(10, 4))

func _draw_body() -> void:
	var bob := draw_person(UNIFORM, CAP.darkened(0.2), Color("4a3428"))
	# boné
	draw_rect(Rect2(-6, -33 + bob, 11, 4), Fx.OUTLINE)
	draw_rect(Rect2(-5, -32 + bob, 9, 3), CAP)
	draw_rect(Rect2(3, -30 + bob, 5, 2), CAP.darkened(0.2)) # aba
	# bigode
	draw_rect(Rect2(1, -23 + bob, 4, 1), Color("4a3428"))
	# bolso com nome
	draw_rect(Rect2(-3, -17 + bob, 4, 3), Color("e8dcc0"))
	# esfregão: o ângulo muda com o estado
	var ang := deg_to_rad(65.0) + sin(anim_t * 8.0) * 0.08
	var shake := 0.0
	if _state == State.WINDUP:
		ang = deg_to_rad(-135.0)
		shake = float(int(anim_t * 40.0) % 2)
	elif _state == State.SWING:
		ang = deg_to_rad(25.0)
		draw_arc(Vector2(0, -14), 24.0, deg_to_rad(-120), deg_to_rad(40), 10, Color(1, 1, 1, 0.75), 3.0)
		draw_arc(Vector2(0, -14), 20.0, deg_to_rad(-90), deg_to_rad(30), 8, Color(WATER, 0.8), 2.0)
	var hand := Vector2(6 + shake, -13 + bob)
	var tip := hand + Vector2.from_angle(ang) * 20.0
	var back := hand - Vector2.from_angle(ang) * 4.0
	draw_line(back, tip, Fx.OUTLINE, 4.0)
	draw_line(back, tip, Color("b08850"), 2.0)
	var head := Rect2(tip - Vector2(4, 3), Vector2(8, 6))
	draw_rect(head.grow(1.0), Fx.OUTLINE)
	draw_rect(head, Color("c8c8d0"))
	draw_rect(Rect2(head.position.x, head.end.y - 2, 8, 2), Color("9a9aa8"))
	draw_front_arm(UNIFORM, bob, 4.0 if _state == State.WINDUP else 0.0)
	alert = _state == State.WINDUP
