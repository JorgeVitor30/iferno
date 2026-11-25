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
	display_name = "PROF. DE ESTATÍSTICA"
	boss = true
	max_hp = 520 + (floor_level - 1) * 160
	speed = 34.0
	hit_color = SHIRT
	drop_chance = 1.0
	hurt_size = Vector2(36, 104)
	col_radius = 13.0
	head_y = 110.0
	shadow_r = 20.0
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

func _o(r: Rect2, c: Color, dither: bool = true) -> void:
	draw_rect(r.grow(1.0), Fx.OUTLINE)
	draw_rect(r, c)
	Fx.bevel(self, r, c, dither)

func _draw_overlay() -> void:
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
			var y := -112.0 - fmod(_steam_t * 30.0 + i * 8.0, 24.0)
			var x := -12.0 + i * 12.0 + sin(_steam_t * 4.0 + i) * 2.0
			var al := 1.0 - (-112.0 - y) / 24.0
			draw_rect(Rect2(x, y, 4, 4), Color(1, 1, 1, 0.6 * al))

func _draw_body() -> void:
	var walking := is_moving()
	var step := 0
	if walking:
		step = 1 if int(anim_t * 7.0) % 2 == 0 else -1
	var bob := 0.0
	if walking:
		bob = -1.0 if step != 0 and int(anim_t * 14.0) % 2 == 0 else 0.0
	else:
		bob = -1.0 if sin(anim_t * 2.4) > 0.3 else 0.0
	var angry := _phase == 3
	var skin := SKIN_B.lerp(Color("ff7a6a"), 0.3) if angry else SKIN_B
	var skin_sh := SKIN_B_SHADE.lerp(Color("e05a4a"), 0.3) if angry else SKIN_B_SHADE
	var lift_l := 2.0 if step == 1 else 0.0
	var lift_r := 2.0 if step == -1 else 0.0

	# --- pernas e sapatos
	_o(Rect2(-12, -36 - lift_l, 9, 31), PANTS)
	_o(Rect2(3, -36 - lift_r, 9, 31), PANTS)
	draw_rect(Rect2(-5, -34 - lift_l, 2, 26), PANTS.darkened(0.25))
	draw_rect(Rect2(3, -34 - lift_r, 2, 26), PANTS.darkened(0.25))
	_o(Rect2(-12, -11 - lift_l, 9, 5), PANTS_LIGHT) # barra dobrada
	_o(Rect2(3, -11 - lift_r, 9, 5), PANTS_LIGHT)
	_o(Rect2(-15, -5 - lift_l, 12, 5), SHOE)
	_o(Rect2(3, -5 - lift_r, 12, 5), SHOE)
	draw_rect(Rect2(-14, -5 - lift_l, 6, 1), SHOE.lightened(0.25))
	draw_rect(Rect2(4, -5 - lift_r, 6, 1), SHOE.lightened(0.25))

	var u := bob # tudo daqui pra cima balança junto
	# --- cintura (calça alta) e camisa
	_o(Rect2(-15, -43 + u, 30, 8), PANTS)
	_o(Rect2(-16, -67 + u, 32, 25), SHIRT)
	# xadrezinho bem leve na camisa
	for sy in range(-65, -44, 4):
		draw_rect(Rect2(-15, sy + u, 30, 1), Color(SHIRT_SHADE, 0.45))
	for sx in range(-14, 15, 4):
		draw_rect(Rect2(sx, -66 + u, 1, 23), Color(SHIRT_SHADE, 0.35))
	draw_rect(Rect2(8, -67 + u, 8, 25), SHIRT_SHADE)
	for by in [-62, -56, -50]:
		draw_rect(Rect2(-1, by + u, 2, 2), Color("8aa4b0"))
	# suspensórios
	draw_rect(Rect2(-10, -67 + u, 4, 30), SUSP)
	draw_rect(Rect2(6, -67 + u, 4, 30), SUSP)
	draw_rect(Rect2(-10, -67 + u, 1, 30), SUSP.lightened(0.2))
	draw_rect(Rect2(6, -67 + u, 1, 30), SUSP.lightened(0.2))
	draw_rect(Rect2(-10, -39 + u, 4, 3), Color("d8c8a0")) # presilhas
	draw_rect(Rect2(6, -39 + u, 4, 3), Color("d8c8a0"))

	# --- braço esquerdo (sempre na cintura)
	_arm_hip(-1.0, u, skin)
	# --- braço direito depende da pose
	match _pose:
		"raise":
			_o(Rect2(16, -73 + u, 7, 10), SHIRT)
			_o(Rect2(16, -64 + u, 8, 4), CUFF)
			_o(Rect2(18, -86 + u, 5, 13), skin)
			_o(Rect2(17, -92 + u, 7, 6), skin)
			_held_item(Vector2(20, -94 + u))
		"point":
			_o(Rect2(16, -66 + u, 10, 7), SHIRT)
			_o(Rect2(25, -66 + u, 4, 8), CUFF)
			_o(Rect2(29, -64 + u, 9, 5), skin)
			_o(Rect2(37, -65 + u, 5, 6), skin)
			draw_rect(Rect2(41, -64 + u, 3, 2), skin) # dedo apontando
		"glasses":
			_o(Rect2(16, -66 + u, 7, 12), SHIRT)
			_o(Rect2(16, -55 + u, 8, 4), CUFF)
			_o(Rect2(13, -78 + u, 5, 23), skin)
			_o(Rect2(5, -86 + u, 8, 5), Color("f4efe2")) # paninho limpando a lente
		_:
			_arm_hip(1.0, u, skin)

	# --- pescoço e gravata borboleta
	_o(Rect2(-4, -71 + u, 8, 5), skin_sh)
	_o(Rect2(-9, -72 + u, 8, 7), TIE)
	_o(Rect2(1, -72 + u, 8, 7), TIE)
	_o(Rect2(-2, -71 + u, 4, 5), TIE.darkened(0.3))
	draw_rect(Rect2(-8, -71 + u, 2, 1), TIE.lightened(0.3))

	# --- cabeça
	_o(Rect2(-19, -89 + u, 5, 10), skin) # orelhas
	_o(Rect2(14, -89 + u, 5, 10), skin)
	draw_rect(Rect2(-18, -86 + u, 2, 5), skin_sh)
	draw_rect(Rect2(16, -86 + u, 2, 5), skin_sh)
	_o(Rect2(-15, -99 + u, 30, 28), skin, false)
	draw_rect(Rect2(-15, -75 + u, 30, 4), skin_sh)
	# cabelo com topete pro lado
	_o(Rect2(-16, -105 + u, 32, 10), HAIR)
	_o(Rect2(-6, -110 + u, 21, 7), HAIR)
	draw_rect(Rect2(-6, -103 + u, 21, 2), HAIR) # junta o topete (cobre o contorno de dentro)
	draw_rect(Rect2(-2, -108 + u, 11, 2), HAIR_LIGHT)
	draw_rect(Rect2(-12, -103 + u, 6, 1), HAIR_LIGHT)
	_o(Rect2(-16, -97 + u, 4, 11), HAIR) # costeletas
	_o(Rect2(12, -97 + u, 4, 9), HAIR)
	# sobrancelhas (bravo: inclinadas pra dentro)
	var brow := Color("4a3028")
	if angry:
		draw_rect(Rect2(-12, -94 + u, 3, 2), brow)
		draw_rect(Rect2(-9, -93 + u, 4, 2), brow)
		draw_rect(Rect2(5, -93 + u, 4, 2), brow)
		draw_rect(Rect2(9, -94 + u, 3, 2), brow)
	else:
		draw_rect(Rect2(-12, -94 + u, 7, 2), brow)
		draw_rect(Rect2(5, -94 + u, 7, 2), brow)
	# óculos redondos enormes
	var blink := _blink_t < 0.0 and _pose != "glasses"
	for ex: float in [-7.0, 7.0]:
		var c := Vector2(ex, -85 + u)
		draw_circle(c, 7.5, Fx.OUTLINE)
		draw_circle(c, 6.5, Color("3a3a44"))
		draw_circle(c, 5.5, Color("fbfbf8") if not blink else skin)
		if blink:
			draw_rect(Rect2(c.x - 4, c.y, 8, 1), Fx.OUTLINE)
		else:
			var pp := (c + _look * Vector2(facing, 1.0) - Vector2(2, 2)).round()
			draw_rect(Rect2(pp, Vector2(4, 4)), Color("2a3a4a"))
			draw_rect(Rect2(pp + Vector2(1, 0), Vector2(1, 1)), Color.WHITE)
		draw_rect(Rect2(c.x - 4, c.y - 4, 2, 1), Color(1, 1, 1, 0.8)) # brilho da lente
	draw_rect(Rect2(-1, -86 + u, 2, 2), Color("3a3a44")) # ponte
	# nariz
	_o(Rect2(-2, -81 + u, 4, 5), Color("eab48c") if not angry else skin_sh)
	# bigodão (mexe quando fala)
	var m := 0.0
	if _talk_t > 0.0:
		m = -1.0 if int(_talk_t * 14.0) % 2 == 0 else 0.0
	_o(Rect2(-11, -76 + u + m, 22, 5), MUST)
	_o(Rect2(-15, -78 + u + m, 5, 3), MUST)
	_o(Rect2(10, -78 + u + m, 5, 3), MUST)
	draw_rect(Rect2(-16, -80 + u + m, 2, 2), MUST)
	draw_rect(Rect2(14, -80 + u + m, 2, 2), MUST)
	draw_rect(Rect2(-9, -76 + u + m, 18, 1), MUST.lightened(0.2))
	# boca
	if angry or _talk_t > 0.0:
		_o(Rect2(-3, -71 + u, 6, 2 if not angry else 3), Color("7a2a2a"))
	else:
		draw_rect(Rect2(-3, -71 + u, 6, 1), Color("9a4a3a"))

func _arm_hip(side: float, u: float, skin: Color) -> void:
	# mão na cintura, igual à referência
	var x := 16.0 if side > 0.0 else -23.0
	_o(Rect2(x, -66 + u, 7, 13), SHIRT)
	_o(Rect2(x + (0.0 if side > 0.0 else -1.0), -54 + u, 8, 4), CUFF)
	_o(Rect2(x + (1.0 if side > 0.0 else 1.0), -50 + u, 5, 8), skin)
	_o(Rect2(13.0 if side > 0.0 else -19.0, -44 + u, 6, 6), skin)

func _held_item(p: Vector2) -> void:
	if _held == "calc":
		_o(Rect2(p.x - 6, p.y - 16, 12, 16), Color("4a4a58"))
		draw_rect(Rect2(p.x - 5, p.y - 15, 10, 4), Color("a8d8a0"))
		for r in 3:
			for c in 3:
				draw_rect(Rect2(p.x - 5 + c * 3.5, p.y - 10 + r * 3.0, 2.5, 2.0), Color("d8d8e0"))
	else:
		# giz brilhando
		_o(Rect2(p.x - 1, p.y - 9, 3, 9), Color("f4efe2"))
		if int(anim_t * 10.0) % 2 == 0:
			draw_rect(Rect2(p.x - 3, p.y - 12, 7, 1), CHALK)
			draw_rect(Rect2(p.x, p.y - 15, 1, 7), CHALK)
