extends Enemy
## CHEFE: Professor de Estatística. Guarda a escada do andar.
## Visual: topete castanho, óculos redondos enormes, bigodão, gravata borboleta,
## camisa azul-clara com manga dobrada, suspensório e calça com barra dobrada.
## Bem maior que o estudante (~2,8x) e desenhado no tamanho nativo (pixel nítido).
##
## Golpes (todos de estatística/matemática, anunciados em cima da cabeça):
##   y = log(x)         filetes de giz que andam em curvas logarítmicas fechando no jogador
##   CURVA NORMAL       leque de provas em forma de sino (as do meio chegam antes)
##   CALCULADORA        arremessa calculadoras que explodem num anel de números
##   HISTOGRAMA         barras sobem do chão em volta do jogador (sempre deixa uma brecha)
##   DISPERSÃO          pontos de gráfico caem em volta do jogador e soltam giz
##   REGRESSÃO LINEAR   avisa com uma reta e dispara uma rajada de giz por ela
##   DESVIO PADRÃO      anéis de bolinhas, cada um girado meio passo
##   AMOSTRA ALEATÓRIA  rajada de bolinhas em direções sorteadas
##   SILÊNCIO!!         se o jogador fica colado nele, solta um anel rápido de giz
##
## "Inteligência": mira onde o jogador VAI estar (lê a velocidade dele), escolhe o golpe
## pela distância, não repete os mesmos golpes, mantém distância e anda de lado.
## Mas sempre avisa antes (pose + nome do golpe) e para pra "limpar os óculos"
## de tempos em tempos, uma janela pra bater sem medo.
## Fases: 66% chama monitores; 33% fica furioso (rosto vermelho, mais rápido, golpes em dupla).

const SKIN_B := Color("f2c49a")
const SKIN_B_SHADE := Color("e0a882")
const HAIR := Color("6a4a42")
const HAIR_LIGHT := Color("8a6a5a")
const SHIRT := Color("c9dde6")
const SHIRT_SHADE := Color("a6c0cc")
const CUFF := Color("94b4c2")
const PANTS := Color("1d4a58")
const PANTS_LIGHT := Color("2f6a7a")
const SUSP := Color("8a5a30")
const TIE := Color("2a6878")
const SHOE := Color("6a3a1e")
const MUST := Color("5a3a2a")
const CHALK := Color("fff4b0")
const MINIONS := {
	"estagiario": preload("res://scripts/enemies/estagiario.gd"),
	"zelador": preload("res://scripts/enemies/zelador.gd"),
}
const NAMES := {
	"log": "y = log(x)!",
	"normal": "CURVA NORMAL!",
	"calc": "CALCULADORA!",
	"histo": "HISTOGRAMA!",
	"disp": "DISPERSÃO!",
	"regressao": "REGRESSÃO LINEAR!",
	"desvio": "DESVIO PADRÃO!",
	"amostra": "AMOSTRA ALEATÓRIA!",
	"bronca": "SILÊNCIO!!",
}

var arena := Rect2() # chão da sala (passado pela sala antes de entrar na árvore)

var _phase := 1
var _cd := 2.0
var _windup := 0.0
var _next := ""
var _recent: Array[String] = []
var _attacks_since_break := 0
var _break_t := 0.0
var _timeline: Array = [] # [[tempo, Callable], ...] — golpe em andamento
var _tl_t := 0.0
var _pose := "hips"      # hips | raise | point | glasses
var _held := "giz"       # o que tem na mão levantada
var _line_from := Vector2.ZERO # reta da regressão (aviso)
var _line_dir := Vector2.ZERO
var _line_t := 0.0
var _close_t := 0.0      # quanto tempo o jogador tá colado
var _pvel := Vector2.ZERO
var _plast := Vector2.ZERO
var _strafe := 1.0
var _strafe_t := 0.0
var _blink_t := 2.0
var _talk_t := 0.0
var _look := Vector2.ZERO
var _steam_t := 0.0
var _spawned_minions: Array[Enemy] = []

func _setup() -> void:
	sprite_tex = preload("res://assets/sprites/enemies/prof_estatistica.png")
	display_name = "PROF. DE ESTATÍSTICA"
	boss = true
	max_hp = 520 + (floor_level - 1) * 160
	speed = 34.0
	hit_color = SHIRT
	drop_chance = 1.0
	hurt_size = Vector2(38, 80)
	col_radius = 12.0
	head_y = 86.0
	shadow_r = 18.0
	lines = ["A média da turma é 3,2.", "Isso é trivial!", "Arredonda pra baixo!",
		"Sua chance de passar: 3%.", "Correlação não é causalidade!", "Vai cair na prova, hein!",
		"Desvio padrão de vocês: enorme!", "Quem colou vai ver!"]
	death_lines = ["...dentro da margem de erro."]

func say(text: String) -> void:
	_talk_t = 1.2
	super.say(text)

# ---------------------------------------------------------------- IA

func _think(delta: float) -> Vector2:
	var to := to_player()
	_track_player(delta)
	_check_phase()
	_blink_t -= delta
	if _blink_t < -0.12:
		_blink_t = randf_range(2.0, 4.5)
	_talk_t = maxf(_talk_t - delta, 0.0)
	_line_t = maxf(_line_t - delta, 0.0)
	_look = _look.lerp(to.normalized() * 2.0, minf(delta * 8.0, 1.0))
	_close_t = _close_t + delta if to.length() < 70.0 else 0.0

	# Golpe em andamento: roda a linha do tempo dele
	if not _timeline.is_empty():
		_tl_t += delta
		for i in range(_timeline.size() - 1, -1, -1):
			if _tl_t >= _timeline[i][0]:
				var f: Callable = _timeline[i][1]
				_timeline.remove_at(i)
				f.call()
		if _timeline.is_empty():
			_pose = "hips"
		return _strafe_vec(to) * 0.3
	# Pausa pra limpar os óculos (janela pro jogador)
	if _break_t > 0.0:
		_break_t -= delta
		if _break_t <= 0.0:
			_pose = "hips"
		return Vector2.ZERO
	# Preparando o golpe
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			alert = false
			_start(_next)
		return Vector2.ZERO
	_cd -= delta
	if _cd <= 0.0:
		if _attacks_since_break >= (4 if _phase < 3 else 5):
			_take_break()
			return Vector2.ZERO
		_next = _choose(to.length())
		_windup = [0.0, 0.6, 0.5, 0.38][_phase]
		_pose = "raise"
		_held = "calc" if _next == "calc" else "giz"
		alert = true
		_squash = Vector2(0.92, 1.08)
		Fx.float_text(get_parent(), global_position + Vector2(0, -head_y - 18), NAMES[_next], Color("ffd966"), 12)
		return Vector2.ZERO
	return _move(to)

## Velocidade do jogador (suavizada), pra mirar onde ele vai estar.
func _track_player(delta: float) -> void:
	var p := player.global_position
	if delta > 0.0 and _plast != Vector2.ZERO:
		_pvel = _pvel.lerp((p - _plast) / delta, minf(delta * 6.0, 1.0))
	_plast = p

func _predict(flight_speed: float, amount: float = 0.75) -> Vector2:
	var p := player.global_position
	var t := global_position.distance_to(p) / maxf(flight_speed, 1.0)
	return p + _pvel * t * amount

func _check_phase() -> void:
	var frac := float(hp) / max_hp
	if _phase == 1 and frac <= 0.66:
		_phase = 2
		say("Hm. Outlier detectado.")
		get_tree().call_group("hud", "banner", "MONITORIA OBRIGATÓRIA!", Color("ffd966"))
		_summon(["estagiario", "estagiario"])
	elif _phase == 2 and frac <= 0.33:
		_phase = 3
		speed = 44.0
		say("AGORA É PROVA FINAL!")
		Fx.shake(self, 8.0)
		get_tree().call_group("hud", "banner", "ELE FICOU FURIOSO!", Color("ff5a4a"))
		_summon(["zelador", "estagiario"])

func _summon(kinds: Array) -> void:
	for i in kinds.size():
		var m: Enemy = MINIONS[kinds[i]].new()
		m.floor_level = floor_level
		m.position = position + Vector2(-60 + i * 120, 24)
		get_parent().add_child(m)
		_spawned_minions.append(m)

## Escolhe o golpe pela distância, sem repetir os dois últimos.
func _choose(dist: float) -> String:
	if _close_t > 1.1:
		_close_t = 0.0
		return "bronca"
	var pool: Array[String] = ["log", "normal", "calc", "histo", "desvio"]
	if _phase >= 2:
		pool += ["disp", "regressao", "amostra"]
	var weighted: Array[String] = []
	for a in pool:
		if a in _recent:
			continue
		var w := 2
		if dist > 200.0 and a in ["calc", "regressao", "log", "histo"]:
			w = 4 # longe: golpes de alcance
		elif dist < 110.0 and a in ["desvio", "amostra", "normal", "disp"]:
			w = 4 # perto: golpes que cobrem área
		for i in w:
			weighted.append(a)
	var pick: String = weighted.pick_random() if not weighted.is_empty() else "normal"
	_recent.append(pick)
	if _recent.size() > 2:
		_recent.pop_front()
	return pick

func _take_break() -> void:
	_attacks_since_break = 0
	_break_t = 1.7 if _phase < 3 else 1.2
	_pose = "glasses"
	say(["Hm... deixa eu limpar os óculos.", "Cadê meu café...", "Peraí, errei a conta."].pick_random())

func _strafe_vec(to: Vector2) -> Vector2:
	return to.orthogonal().normalized() * _strafe * speed

## Mantém uma distância boa, anda de lado e não encosta nas paredes.
func _move(to: Vector2) -> Vector2:
	_strafe_t -= get_physics_process_delta_time()
	if _strafe_t <= 0.0:
		_strafe_t = randf_range(1.2, 2.4)
		_strafe = -_strafe
	var d := to.length()
	var dir := to.normalized()
	var want := dir.orthogonal() * _strafe
	if d < 120.0:
		want -= dir * 1.2
	elif d > 210.0:
		want += dir
	if arena.size != Vector2.ZERO:
		var safe := arena.grow(-60)
		if not safe.has_point(global_position):
			want += (arena.get_center() - global_position).normalized() * 1.5
	return want.normalized() * speed

# ---------------------------------------------------------------- golpes

func _at(t: float, f: Callable) -> void:
	_timeline.append([t, f])

func _start(a: String) -> void:
	_attacks_since_break += 1
	_timeline.clear()
	_tl_t = 0.0
	_pose = "point"
	_squash = Vector2(1.12, 0.9)
	match a:
		"log": _atk_log()
		"normal": _atk_normal()
		"calc": _atk_calc()
		"histo": _atk_histo()
		"disp": _atk_disp()
		"regressao": _atk_regressao()
		"desvio": _atk_desvio()
		"amostra": _atk_amostra()
		"bronca": _atk_bronca()
	# Furioso: às vezes emenda um segundo golpe rápido
	if _phase == 3 and a != "bronca" and randf() < 0.45:
		var extra: String = ["normal", "desvio", "disp"].pick_random()
		var end := 0.0
		for e: Array in _timeline:
			end = maxf(end, e[0])
		_at(end + 0.35, func(): Fx.float_text(get_parent(), global_position + Vector2(0, -head_y - 18), NAMES[extra], Color("ff9a6a"), 12))
		_at(end + 0.6, func(): _start_extra(extra))
	_cd = [0.0, 1.5, 1.2, 0.9][_phase]

func _start_extra(a: String) -> void:
	match a:
		"normal": _atk_normal(_tl_t)
		"desvio": _atk_desvio(_tl_t)
		"disp": _atk_disp(_tl_t)

func _atk_log() -> void:
	# Filetes de giz em curvas logarítmicas: metade abre pra um lado, metade pro outro,
	# e as curvas fecham perto de onde o jogador vai estar.
	var bursts := 6 + _phase * 2
	for i in bursts:
		_at(i * 0.12, func():
			var aim := (_predict(115.0, 0.5) - global_position).normalized()
			var amp := randf_range(16.0, 34.0)
			for sgn in [-1.0, 1.0]:
				var dir := aim.rotated(-sgn * 0.42)
				var b := _bullet("giz", dir, 115.0)
				b.curve = "log"
				b.curve_amp = amp * sgn
				b.lifetime = 3.2)

func _atk_normal(t0: float = 0.0) -> void:
	_at(t0, func():
		var aim := _predict(100.0) - global_position
		var n := 15 + _phase * 2
		var spread := deg_to_rad(110.0)
		for i in n:
			var x := (i - (n - 1) / 2.0) / ((n - 1) / 2.0)
			var bell := exp(-(x * x) / (2.0 * 0.33 * 0.33))
			_bullet("prova", aim.rotated(-spread / 2.0 + spread * i / (n - 1)), 50.0 + 90.0 * bell)
		Fx.shake(self, 2.0))

func _atk_calc() -> void:
	var count := _phase
	for i in count:
		_at(i * 0.4, func():
			var target := _predict(140.0, 0.9) + Vector2(randf_range(-24, 24), randf_range(-24, 24)) * float(i)
			var dir := target - global_position
			var b := _bullet("calculadora", dir, 140.0)
			b.explode_dist = clampf(dir.length(), 60.0, 320.0)
			b.lifetime = 4.0)

func _atk_histo() -> void:
	# Barras do histograma em volta do jogador, com uma brecha garantida perto dele.
	var p := player.global_position
	var n := 5 + _phase * 2
	var gap_at := randi_range(-1, 1) # qual barra fica de fora (a brecha)
	_at(0.0, func():
		for i in n:
			var idx := i - n / 2
			if idx == gap_at:
				continue
			var hz: Node2D = HAZARD.new()
			hz.kind = "barra"
			hz.size = Vector2(30, randf_range(70.0, 150.0))
			hz.position = Vector2(p.x + idx * 36.0, p.y + randf_range(14.0, 40.0))
			hz.warn_time = 1.0 - _phase * 0.08 + absi(idx) * 0.05
			hz.color = Color.from_hsv(0.55 + idx * 0.04, 0.5, 0.9)
			get_parent().add_child(hz))

func _atk_disp(t0: float = 0.0) -> void:
	_at(t0, func():
		var p := _predict(200.0, 0.6)
		var n := 6 + _phase * 3
		for i in n:
			var hz: Node2D = HAZARD.new()
			hz.kind = "ponto"
			hz.radius = 11.0
			var off := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(30.0, 120.0)
			hz.position = p + off
			if arena.size != Vector2.ZERO:
				hz.position = hz.position.clamp(arena.position + Vector2(8, 8), arena.end - Vector2(8, 8))
			hz.warn_time = 0.8 + i * 0.05
			get_parent().add_child(hz))

func _atk_regressao() -> void:
	# Avisa com uma reta (linha de tendência) e dispara giz rápido por ela.
	var lines_n := 1 if _phase < 3 else 3
	_at(0.0, func():
		_line_from = global_position
		_line_dir = (_predict(240.0, 0.6) - global_position).normalized()
		_line_t = 0.65)
	for k in 18:
		_at(0.65 + k * 0.04, func():
			for j in lines_n:
				_bullet("giz", _line_dir.rotated((j - (lines_n - 1) / 2.0) * 0.4), 240.0))

func _atk_desvio(t0: float = 0.0) -> void:
	var rings := 2 + _phase
	for r in rings:
		_at(t0 + r * 0.36, func():
			var n := 14 + _phase * 2
			var off := (r % 2) * PI / n + to_player().angle()
			for i in n:
				_bullet("bolinha", Vector2.from_angle(off + i * TAU / n), 72.0))

func _atk_amostra() -> void:
	var shots := 18 + _phase * 6
	for i in shots:
		_at(i * 0.05, func():
			var a := to_player().angle() + randf_range(-1.0, 1.0)
			_bullet("bolinha" if i % 3 != 0 else "digito", Vector2.from_angle(a), randf_range(60.0, 130.0)))

func _atk_bronca() -> void:
	_at(0.0, func():
		say("SILÊNCIO!!")
		Fx.shake(self, 5.0)
		var n := 22
		var off := randf() * TAU
		for i in n:
			_bullet("giz", Vector2.from_angle(off + i * TAU / n), 135.0)
		_squash = Vector2(1.3, 0.75))

const HAZARD := preload("res://scripts/hazard.gd")

## Projétil saindo da mão (o nó fica no chão embaixo dela).
func _bullet(kind: String, dir: Vector2, spd: float) -> Area2D:
	var b: Area2D = BULLET.new()
	b.kind = kind
	b.direction = dir.normalized()
	b.speed = spd
	b.position = position + Vector2(18 * facing, 2) + dir.normalized() * 10.0
	get_parent().add_child(b)
	return b

func _on_death() -> void:
	_timeline.clear()
	for m in _spawned_minions:
		if is_instance_valid(m) and not m.dead:
			m.take_damage(999, Vector2.ZERO)
	for i in 5:
		spawn_decal("papel", Color.WHITE, position + Vector2(randf_range(-24, 24), randf_range(-6, 8)))
	Engine.time_scale = 0.25
	get_tree().create_timer(1.0, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

# ---------------------------------------------------------------- desenho

func _sprite_tint() -> Color:
	return Color(1.0, 0.72, 0.68) if _phase == 3 else Color.WHITE # vermelho de raiva

func _draw_overlay() -> void:
	# giz/calculadora na mão levantada enquanto prepara o golpe
	if _pose == "raise":
		var hp := Vector2(18 * facing, -62)
		if _held == "calc":
			draw_rect(Rect2(hp + Vector2(-5, -14), Vector2(10, 14)), Fx.OUTLINE)
			draw_rect(Rect2(hp + Vector2(-4, -13), Vector2(8, 12)), Color("4a4a58"))
			draw_rect(Rect2(hp + Vector2(-3, -12), Vector2(6, 3)), Color("a8d8a0"))
		else:
			draw_rect(Rect2(hp + Vector2(-2, -10), Vector2(4, 10)), Fx.OUTLINE)
			draw_rect(Rect2(hp + Vector2(-1, -9), Vector2(2, 8)), Color("e0d8d0"))
			if int(anim_t * 10.0) % 2 == 0:
				draw_rect(Rect2(hp + Vector2(-4, -14), Vector2(8, 1)), CHALK)
				draw_rect(Rect2(hp + Vector2(0, -18), Vector2(1, 8)), CHALK)
	elif _pose == "glasses":
		draw_rect(Rect2(Vector2(-6, -70), Vector2(8, 4)), Color("e0d8d0")) # limpando os óculos
	# Aviso da regressão linear: reta tracejada piscando
	if _line_t > 0.0:
		var a := 0.35 + 0.5 * float(int(_line_t * 16.0) % 2)
		var from := _line_from - global_position + Vector2(0, -50)
		for i in 26:
			var p0 := from + _line_dir * (20.0 + i * 16.0)
			draw_line(p0, p0 + _line_dir * 9.0, Color(1, 0.3, 0.3, a), 2.0)
	if _phase == 3:
		# fumacinha de raiva saindo da cabeça
		_steam_t += get_process_delta_time()
		for i in 3:
			var y := -12.0 - fmod(_steam_t * 30.0 + i * 8.0, 24.0)
			var x := -12.0 + i * 12.0 + sin(_steam_t * 4.0 + i) * 2.0
			var al := 1.0 - (-12.0 - y) / 24.0
			draw_rect(Rect2(x, y - 76, 4, 4), Color(1, 1, 1, 0.6 * al))

func _draw_body() -> void:
	# Desenhado em unidades de arte (2px cada), de frente, ~51 unidades de altura.
	var walking := is_moving()
	var step := 0
	if walking:
		step = 1 if int(anim_t * 6.0) % 2 == 0 else -1
	var u := 0.0
	if not walking and fmod(anim_t, 1.4) < 0.7:
		u = 1.0
	var angry := _phase == 3
	var skin := SKIN_B.lerp(Color("ff7a6a"), 0.3) if angry else SKIN_B
	var skin_sh := SKIN_B_SHADE.lerp(Color("e05a4a"), 0.3) if angry else SKIN_B_SHADE
	var ll := 1.0 if step == 1 else 0.0
	var lr := 1.0 if step == -1 else 0.0
	# --- pernas e sapatos
	bb(-6, -14 - ll, 4, 12, PANTS)
	bb(2, -14 - lr, 4, 12, PANTS)
	fb(-6, -5 - ll, 4, 2, PANTS_LIGHT)   # barra dobrada
	fb(2, -5 - lr, 4, 2, PANTS_LIGHT)
	bb(-7, -2 - ll, 5, 2, SHOE)
	bb(2, -2 - lr, 5, 2, SHOE)
	# --- cintura, camisa xadrezinha e suspensório
	bb(-7, -17 + u, 14, 3, PANTS)
	bb(-8, -29 + u, 16, 12, SHIRT)
	fb(5, -28 + u, 3, 10, SHIRT_SHADE)
	for i in 3:
		fb(0, -26 + i * 3 + u, 1, 1, Color("8aa4b0"))
	fb(-5, -29 + u, 2, 13, SUSP)
	fb(3, -29 + u, 2, 13, SUSP)
	fb(-5, -17 + u, 2, 1, Color("d8c8a0"))
	fb(3, -17 + u, 2, 1, Color("d8c8a0"))
	# --- braços
	_arm_hip(-1.0, u, skin)
	match _pose:
		"raise":
			bb(8, -32 + u, 3, 4, SHIRT)
			bb(9, -38 + u, 2, 6, skin)
			bb(8, -41 + u, 4, 3, skin)
			_held_item(Vector2(10, -42 + u))
		"point":
			bb(8, -29 + u, 5, 3, SHIRT)
			bb(13, -29 + u, 2, 4, CUFF)
			bb(15, -28 + u, 4, 2, skin)
			bb(19, -29 + u, 2, 3, skin)
		"glasses":
			bb(8, -29 + u, 3, 6, SHIRT)
			bb(6, -37 + u, 2, 10, skin)
			bb(2, -40 + u, 4, 2, Color("e0d8d0")) # paninho limpando a lente
		_:
			_arm_hip(1.0, u, skin)
	# --- pescoço e gravata borboleta
	bb(-2, -31 + u, 4, 2, skin_sh)
	bb(-5, -32 + u, 4, 3, TIE)
	bb(1, -32 + u, 4, 3, TIE)
	bb(-1, -31 + u, 2, 2, TIE.darkened(0.3))
	# --- cabeça
	bb(-10, -41 + u, 2, 4, skin)
	bb(8, -41 + u, 2, 4, skin)
	bb(-8, -46 + u, 16, 14, skin)
	fb(-8, -34 + u, 16, 2, skin_sh)
	# cabelo com topete pro lado
	bb(-9, -49 + u, 18, 5, HAIR)
	bb(-3, -51 + u, 11, 3, HAIR)
	fb(-3, -49 + u, 11, 1, HAIR)
	fb(-1, -50 + u, 6, 1, HAIR_LIGHT)
	fb(-7, -48 + u, 4, 1, HAIR_LIGHT)
	bb(-9, -45 + u, 2, 5, HAIR)
	bb(7, -45 + u, 2, 4, HAIR)
	# sobrancelhas
	var brow := Color("4a3028")
	if angry:
		fb(-6, -45 + u, 2, 1, brow)
		fb(-4, -44 + u, 2, 1, brow)
		fb(2, -44 + u, 2, 1, brow)
		fb(4, -45 + u, 2, 1, brow)
	else:
		fb(-6, -44 + u, 3, 1, brow)
		fb(3, -44 + u, 3, 1, brow)
	# óculos redondos enormes
	var blink := _blink_t < 0.0 and _pose != "glasses"
	for ex: float in [-3.5, 3.5]:
		var cc := Vector2(ex, -40 + u)
		draw_circle(cc, 3.9, Fx.OUTLINE)
		draw_circle(cc, 3.2, Color("3a3a44"))
		draw_circle(cc, 2.5, Color("f4f2ee") if not blink else skin)
		if blink:
			fb(cc.x - 2, cc.y, 4, 1, Fx.OUTLINE)
		else:
			var pp := (cc + (_look * 0.5).round() * Vector2(facing, 1.0) - Vector2(1, 1)).floor()
			fb(pp.x, pp.y, 2, 2, Color("2a3a4a"))
	fb(-1, -40 + u, 2, 1, Color("3a3a44"))
	# nariz, bigodão (mexe quando fala) e boca
	bb(-1, -38 + u, 2, 2, skin_sh)
	var m := 0.0
	if _talk_t > 0.0 and int(_talk_t * 12.0) % 2 == 0:
		m = -1.0
	bb(-5, -36 + u + m, 10, 2, MUST)
	fb(-7, -37 + u + m, 2, 1, MUST)
	fb(5, -37 + u + m, 2, 1, MUST)
	fb(-8, -38 + u + m, 1, 1, MUST)
	fb(7, -38 + u + m, 1, 1, MUST)
	fb(-4, -36 + u + m, 8, 1, MUST.lightened(0.2))
	if angry or _talk_t > 0.0:
		bb(-1, -33 + u, 2, 1, Color("7a2a2a"))

func _arm_hip(side: float, u: float, skin: Color) -> void:
	# mão na cintura, igual à referência
	var x := 8.0 if side > 0.0 else -11.0
	bb(x, -29 + u, 3, 6, SHIRT)
	bb(x - (0.0 if side > 0.0 else 1.0), -23 + u, 4, 2, CUFF)
	bb(x, -21 + u, 3, 2, skin)
	bb(6.0 if side > 0.0 else -9.0, -19 + u, 3, 3, skin)

func _held_item(p: Vector2) -> void:
	if _held == "calc":
		bb(p.x - 3, p.y - 8, 6, 8, Color("4a4a58"))
		fb(p.x - 2, p.y - 7, 4, 2, Color("a8d8a0"))
		fb(p.x - 2, p.y - 4, 1, 1, Color("d8d8e0"))
		fb(p.x, p.y - 4, 1, 1, Color("d8d8e0"))
		fb(p.x - 2, p.y - 2, 1, 1, Color("d8d8e0"))
		fb(p.x, p.y - 2, 1, 1, Color("ff8a4a"))
	else:
		bb(p.x - 0.5, p.y - 4, 1, 4, Color("e0d8d0")) # giz
		if int(anim_t * 10.0) % 2 == 0:
			fb(p.x - 2, p.y - 6, 4, 1, CHALK)
			fb(p.x - 0.5, p.y - 8, 1, 4, CHALK)
