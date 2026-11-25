extends Enemy
## Estagiário (à distância, fraco): corre meio desesperado e joga
## aviõezinhos de papel que vão virando atrás do jogador.

const POLO := Color("4f9a5a")

var _cd := 1.0
var _wander := Vector2.ZERO
var _wander_t := 0.0
var _throw_anim := 0.0

func _setup() -> void:
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
	var bob := draw_person(POLO, Color("6a6a78"), Color("8a5a2a"))
	# cabelo bagunçado
	draw_rect(Rect2(-6, -33 + bob, 3, 2), Color("8a5a2a"))
	draw_rect(Rect2(0, -33 + bob, 3, 2), Color("8a5a2a"))
	# crachá pendurado
	draw_line(Vector2(-3, -20 + bob), Vector2(0, -15 + bob), Color("3f6fd1"), 1.0)
	draw_line(Vector2(3, -20 + bob), Vector2(0, -15 + bob), Color("3f6fd1"), 1.0)
	draw_rect(Rect2(-2, -15 + bob, 4, 4), Color("f4efe2"))
	draw_rect(Rect2(-1, -14 + bob, 2, 1), Color("3f6fd1"))
	# olheira
	draw_rect(Rect2(2, -24 + bob, 2, 1), Color("9a7aa8"))
	var raise := 7.0 if _throw_anim > 0.0 else 0.0
	if raise == 0.0:
		# aviãozinho pronto na mão
		var p := Vector2(9, -14 + bob)
		draw_colored_polygon(PackedVector2Array([p + Vector2(5, 0), p + Vector2(-4, -3), p + Vector2(-4, 3)]), Fx.OUTLINE)
		draw_colored_polygon(PackedVector2Array([p + Vector2(4, 0), p + Vector2(-3, -2), p + Vector2(-3, 2)]), PAPER)
	draw_front_arm(POLO, bob, raise)
