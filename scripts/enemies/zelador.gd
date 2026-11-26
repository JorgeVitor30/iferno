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
	sprite_tex = preload("res://assets/sprites/enemies/zelador.png")
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
			alert = true
			if _t <= 0.0:
				alert = false
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

func _draw_overlay() -> void:
	if _state == State.SWING:
		var a := _dir.angle()
		draw_arc(Vector2(0, -14), 22.0, a - 1.2, a + 1.2, 10, Color(1, 1, 1, 0.75), 3.0)
		draw_arc(Vector2(0, -14), 18.0, a - 1.0, a + 1.0, 8, Color(WATER, 0.8), 2.0)

func _draw_body() -> void:
	# uniforme azul, boné com aba, bigode e esfregão (o ângulo muda com o golpe)
	var b := draw_person(UNIFORM, CAP.darkened(0.25), Color("4a3428"))
	ob(-4, -15 + b, 8, 2)
	fb(-4, -15 + b, 8, 2, CAP)
	fb(-3, -15 + b, 4, 1, CAP.lightened(0.2))
	fb(3, -13 + b, 3, 1, CAP.darkened(0.2)) # aba
	fb(1, -9 + b, 3, 1, Color("4a3428"))    # bigode
	fb(-2, -6 + b, 2, 1, Color("e8dcc0"))   # crachá no bolso
	var ang := deg_to_rad(65.0)
	var sh := 0.0
	if _state == State.WINDUP:
		ang = deg_to_rad(-135.0)
		sh = float(int(anim_t * 30.0) % 2)
	elif _state == State.SWING:
		ang = deg_to_rad(25.0)
		draw_arc(Vector2(0, -7), 12.0, deg_to_rad(-120), deg_to_rad(40), 8, Color(1, 1, 1, 0.7), 2.0)
	var hand := Vector2(3 + sh, -5 + b)
	var tip := hand + Vector2.from_angle(ang) * 10.0
	draw_line(hand - Vector2.from_angle(ang) * 2.0, tip, Fx.OUTLINE, 2.5)
	draw_line(hand - Vector2.from_angle(ang) * 2.0, tip, Color("9a7048"), 1.0)
	var mh := tip.round()
	ob(mh.x - 2, mh.y - 1, 4, 3)
	fb(mh.x - 2, mh.y - 1, 4, 3, Color("a8a2b4"))
	fb(mh.x - 2, mh.y + 1, 4, 1, Color("7a7488"))
	draw_front_arm(UNIFORM, b, 2.0 if _state == State.WINDUP else 0.0)
	alert = _state == State.WINDUP
