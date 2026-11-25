extends Enemy
## Estagiário (à distância, fraco): corre meio desesperado e joga
## aviõezinhos de papel que vão virando atrás do jogador.

const POLO := Color("4f9a5a")

var _cd := 1.0
var _wander := Vector2.ZERO
var _wander_t := 0.0
var _throw_anim := 0.0

func _setup() -> void:
	sprite_tex = preload("res://assets/sprites/enemies/estagiario.png")
	display_name = "Estagiário"
	max_hp = 4 + floor_level
	speed = 56.0 + floor_level * 3.0
	hit_color = POLO
	drop_chance = 0.08
	_cd = randf_range(0.8, 1.8)
	lines = ["Desculpa!", "Só cumpro ordens!", "Meu chefe mandou!", "Estágio não remunerado...", "Tô no 3º café!"]
	death_lines = ["Fui efetivado... no chão", "Me demiti!", "Até o RH..."]

func _think(delta: float) -> Vector2:
	var to := to_player()
	var d := to.length()
	_cd -= delta
	_throw_anim = maxf(_throw_anim - delta, 0.0)
	_wander_t -= delta
	if _wander_t <= 0.0:
		_wander_t = randf_range(0.4, 1.0)
		_wander = Vector2.from_angle(randf() * TAU)
	if _cd <= 0.0 and d < 280.0:
		_cd = randf_range(1.3, 1.9) - floor_level * 0.1
		_throw_anim = 0.25
		_squash = Vector2(1.2, 0.85)
		shoot("aviao", to, 85.0 + floor_level * 5.0, 1.4 + floor_level * 0.2)
	var dir := to.normalized()
	var want := _wander
	if d < 80.0:
		want -= dir * 1.5
	elif d > 160.0:
		want += dir
	return want.normalized() * speed

func _draw_body() -> void:
	# polo verde, cabelo bagunçado, crachá azul, olheira e aviãozinho de papel
	var b := draw_person(POLO, Color("4a4658"), Color("8a5a2a"))
	fb(-4, -15 + b, 1, 1, Color("8a5a2a"))
	fb(0, -15 + b, 1, 1, Color("8a5a2a"))
	fb(-1, -6 + b, 2, 2, Color("e0d8d0"))      # crachá
	fb(-1, -7 + b, 2, 1, Color("3f6fd1"))
	fb(2, -10 + b, 1, 1, Color("8a6aa8"))      # olheira
	var raise := 3.0 if _throw_anim > 0.0 else 0.0
	if raise == 0.0:
		var p := Vector2(5, -6 + b)
		draw_colored_polygon(PackedVector2Array([p + Vector2(3, 0), p + Vector2(-2, -2), p + Vector2(-2, 2)]), Fx.OUTLINE)
		draw_colored_polygon(PackedVector2Array([p + Vector2(2, 0), p + Vector2(-1, -1), p + Vector2(-1, 1)]), PAPER)
	draw_front_arm(POLO, b, raise)
