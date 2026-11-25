extends Enemy
## CHEFE (provisório): Professor de Estatística. Guarda a escada do andar.
## O design final do chefe ainda vai ser definido; isto é um placeholder jogável.
## Ataques (em ciclo, cada um anunciado em cima da cabeça):
##   CURVA NORMAL       leque de provas com velocidade em forma de sino (o meio chega antes)
##   AMOSTRA ALEATÓRIA  rajada de bolinhas em direções/velocidades sorteadas
##   DESVIO PADRÃO      três anéis de bolinhas, cada um girado meio passo
## Abaixo de 50% de vida: fica mais rápido e chama os monitores (estagiários) uma vez.

const SUIT := Color("3a5a4a")
const MINION := preload("res://scripts/enemies/estagiario.gd")
const ATTACKS := ["CURVA NORMAL!", "AMOSTRA ALEATÓRIA!", "DESVIO PADRÃO!"]

var _cd := 2.0
var _windup := 0.0
var _attack := 0
var _spray_left := 0
var _spray_t := 0.0
var _rings_left := 0
var _ring_t := 0.0
var _phase2 := false
var _minions: Array[Enemy] = []
var _home := Vector2.ZERO
var _move_t := 0.0

func _setup() -> void:
	display_name = "PROF. DE ESTATÍSTICA"
	boss = true
	body_scale = 1.5
	max_hp = 140 + (floor_level - 1) * 50
	speed = 26.0
	hit_color = SUIT
	drop_chance = 1.0
	lines = ["Média 7. Você tem 3,2.", "Isso é trivial!", "Arredonda pra baixo!",
		"A chance de você passar é 3%!", "Correlação não é causalidade!"]
	death_lines = ["...dentro da margem de erro."]
	_home = position

func _think(delta: float) -> Vector2:
	var to := to_player()
	if not _phase2 and hp <= max_hp / 2:
		_enter_phase2()
	# rajada aleatória em andamento
	if _spray_left > 0:
		_spray_t -= delta
		if _spray_t <= 0.0:
			_spray_t = 0.06
			_spray_left -= 1
			var a := to.angle() + randf_range(-1.1, 1.1)
			shoot("bolinha", Vector2.from_angle(a), randf_range(60.0, 125.0))
		return Vector2.ZERO
	if _rings_left > 0:
		_ring_t -= delta
		if _ring_t <= 0.0:
			_ring_t = 0.38
			_rings_left -= 1
			var n := 14 + floor_level * 2
			var off := (_rings_left % 2) * PI / n + to.angle()
			for i in n:
				shoot("bolinha", Vector2.from_angle(off + i * TAU / n), 70.0)
		return Vector2.ZERO
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_fire(to)
		return Vector2.ZERO
	_cd -= delta
	if _cd <= 0.0:
		_windup = 0.55 if not _phase2 else 0.4
		alert = true
		_squash = Vector2(0.85, 1.2)
		Fx.float_text(get_parent(), global_position + Vector2(0, -62), ATTACKS[_attack % ATTACKS.size()], Color("ffd966"), 11)
		return Vector2.ZERO
	# Anda de um lado pro outro perto da lousa, de olho no jogador.
	_move_t += delta
	var target := _home + Vector2(sin(_move_t * 0.6) * 140.0, sin(_move_t * 1.1) * 30.0)
	var to_target := target - global_position
	if to_target.length() < 4.0:
		return Vector2.ZERO
	return to_target.normalized() * speed * (1.4 if _phase2 else 1.0)

func _fire(to: Vector2) -> void:
	alert = false
	_squash = Vector2(1.25, 0.8)
	Fx.shake(self, 2.5)
	match _attack % ATTACKS.size():
		0:
			# Curva normal: 17 provas, as do meio mais rápidas -> a frente do leque vira um sino.
			var n := 17
			var spread := deg_to_rad(120.0)
			for i in n:
				var x := (i - (n - 1) / 2.0) / ((n - 1) / 2.0) # -1..1
				var bell := exp(-(x * x) / (2.0 * 0.35 * 0.35))
				var dir := to.rotated(-spread / 2.0 + spread * i / (n - 1))
				shoot("prova", dir, 55.0 + 85.0 * bell)
		1:
			_spray_left = 22 if not _phase2 else 32
			_spray_t = 0.0
		2:
			_rings_left = 3 if not _phase2 else 4
			_ring_t = 0.0
	_attack += 1
	_cd = (1.5 if not _phase2 else 1.0)

func _enter_phase2() -> void:
	_phase2 = true
	say("Monitoria obrigatória!")
	Fx.shake(self, 6.0)
	get_tree().call_group("hud", "banner", "ELE FICOU BRAVO!", Color("ff5a4a"))
	for i in 2:
		var m: Enemy = MINION.new()
		m.floor_level = floor_level
		m.position = position + Vector2(-50 + i * 100, 30)
		get_parent().add_child(m)
		_minions.append(m)

func _on_death() -> void:
	# Leva os monitores junto e dá aquele slow-motion de vitória.
	for m in _minions:
		if is_instance_valid(m) and not m.dead:
			m.take_damage(999, Vector2.ZERO)
	spawn_decal("papel", Color.WHITE)
	spawn_decal("papel", Color.WHITE, position + Vector2(14, 6))
	spawn_decal("papel", Color.WHITE, position + Vector2(-12, 4))
	Engine.time_scale = 0.25
	get_tree().create_timer(0.9, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func _draw_body() -> void:
	var bob := draw_person(SUIT, Color("2a2a30"), Color("b8b4ac"))
	# careca brilhando + cabelo só dos lados
	draw_rect(Rect2(-3, -31 + bob, 7, 3), SKIN)
	draw_rect(Rect2(-1, -31 + bob, 2, 1), Color("fff0e0"))
	# barba grisalha
	draw_rect(Rect2(-1, -23 + bob, 6, 4), Color("b8b4ac"))
	draw_rect(Rect2(2, -22 + bob, 2, 1), Color("7a5a5a")) # boca
	# óculos fundo de garrafa
	draw_rect(Rect2(0, -28 + bob, 6, 4), Fx.OUTLINE)
	draw_rect(Rect2(1, -27 + bob, 4, 2), Color("dff4ff"))
	# camisa xadrez aparecendo + gravata borboleta
	draw_rect(Rect2(-1, -20 + bob, 4, 7), Color("d8c8a0"))
	draw_rect(Rect2(-1, -20 + bob, 4, 2), Color("c0392b"))
	# calculadora gigante na mão
	var raise := 7.0 if _windup > 0.0 or _spray_left > 0 or _rings_left > 0 else 0.0
	var calc := Rect2(6, -19 + bob - raise, 9, 12)
	draw_rect(calc.grow(1.0), Fx.OUTLINE)
	draw_rect(calc, Color("4a4a58"))
	draw_rect(Rect2(7, -18 + bob - raise, 7, 3), Color("a8d8a0"))
	for r in 3:
		for c in 3:
			draw_rect(Rect2(7 + c * 2.4, -14 + r * 2.4 + bob - raise, 1.6, 1.6), Color("c8c8d0"))
	draw_front_arm(SUIT, bob, raise)
