extends Enemy
## Coordenadora (elite surpresa em salas comuns): bem mais vida, barra de vida em cima
## e um ciclo de ataques de bullet-hell com papel:
##   1) anel de bolinhas de papel
##   2) espiral de bolinhas (3 rajadas girando)
##   3) leque de provas mirado no jogador

const BLAZER := Color("6b3fa0")

var _cd := 1.6
var _attack := 0
var _burst_left := 0
var _burst_t := 0.0
var _burst_ang := 0.0
var _windup := 0.0

func _setup() -> void:
	display_name = "COORDENADORA"
	elite = true
	body_scale = 1.25
	max_hp = 28 + floor_level * 8
	speed = 24.0
	hit_color = BLAZER
	drop_chance = 1.0
	lines = ["Jubilado!", "Falta não abonada!", "Cadê o atestado?", "Reunião AGORA!", "Trancamento negado!"]
	death_lines = ["Protocolo aceito...", "Vou abrir um processo..."]

func _think(delta: float) -> Vector2:
	var to := to_player()
	if _burst_left > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst_t = 0.13
			_burst_left -= 1
			_burst_ang += 0.22
			var arms := 5 + floor_level # andar 1: 6 braços na espiral
			for i in arms:
				shoot("bolinha", Vector2.from_angle(_burst_ang + i * TAU / arms), 75.0)
		return Vector2.ZERO
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_fire()
		return Vector2.ZERO
	_cd -= delta
	if _cd <= 0.0:
		_windup = 0.6
		alert = true
		_squash = Vector2(0.85, 1.2)
		return Vector2.ZERO
	# anda devagar mantendo uma distância média
	var d := to.length()
	var want := to.normalized() * (1.0 if d > 120.0 else -0.6)
	want += to.orthogonal().normalized() * sin(anim_t * 0.7) * 0.6
	return want.normalized() * speed

func _fire() -> void:
	alert = false
	_squash = Vector2(1.25, 0.8)
	Fx.shake(self, 2.0)
	match _attack % 3:
		0:
			var n := 10 + floor_level * 2
			var off := randf() * TAU
			for i in n:
				shoot("bolinha", Vector2.from_angle(off + i * TAU / n), 80.0)
		1:
			_burst_left = 6 + floor_level * 2
			_burst_t = 0.0
			_burst_ang = randf() * TAU
		2:
			var to := to_player()
			for i in 5:
				shoot("prova", to.rotated(deg_to_rad(-24.0 + i * 12.0)), 120.0)
	_attack += 1
	_cd = 1.6 - minf(floor_level * 0.1, 0.5)

func _on_death() -> void:
	spawn_decal("papel", Color.WHITE)
	spawn_decal("papel", Color.WHITE, position + Vector2(10, 4))

func _draw_body() -> void:
	var bob := draw_person(BLAZER, Color("2a2030"), Color("3a2418"))
	# coque
	draw_rect(Rect2(-9, -33 + bob, 5, 5), Fx.OUTLINE)
	draw_rect(Rect2(-8, -32 + bob, 3, 3), Color("3a2418"))
	# óculos vermelhos
	draw_rect(Rect2(1, -27 + bob, 5, 3), Color("c0392b"))
	draw_rect(Rect2(2, -26 + bob, 3, 1), Color("bfe3ff"))
	# broche dourado e colar
	draw_rect(Rect2(-3, -18 + bob, 2, 2), Color("ffd23f"))
	draw_rect(Rect2(-1, -20 + bob, 4, 1), Color("f4efe2"))
	# prancheta
	var raise := 6.0 if _windup > 0.0 else 0.0
	var board := Rect2(5, -18 + bob - raise, 9, 11)
	draw_rect(board.grow(1.0), Fx.OUTLINE)
	draw_rect(board, Color("b08850"))
	draw_rect(Rect2(6, -16 + bob - raise, 7, 8), Color("f4efe2"))
	draw_rect(Rect2(8, -19 + bob - raise, 3, 2), Color("9a9aa8"))
	for i in 3:
		draw_rect(Rect2(7, -15 + i * 2 + bob - raise, 5, 1), Color("9a9aa8"))
	draw_front_arm(BLAZER, bob, raise)
