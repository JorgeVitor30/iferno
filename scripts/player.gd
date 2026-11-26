extends CharacterBody2D
## Jogador: WASD anda, mouse mira, botão esquerdo atira, espaço/botão direito = dodge roll.

const BULLET := preload("res://scenes/bullet.tscn")

signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp := 6
@export var invuln_time := 0.8 # invencibilidade depois de tomar hit

@export var speed := 117.0 # velocidade original aumentada em 30%
@export var accel := 900.0     # quão rápido chega na velocidade máxima
@export var friction := 1100.0 # quão rápido para ao soltar as teclas
@export var walk_tilt_deg := 0.0 # (desligado: girar pixel art borra; a gingada virou 1px de sobe-e-desce)
@export var roll_distance := 64.0 # quanto o dodge anda (o boneco tem ~39px de altura)
@export var roll_time := 0.45     # duração do dodge (invencível o tempo todo)
@export var roll_cooldown := 0.4  # espera depois do dodge antes de poder rolar de novo
@export var roll_hop := 5.0       # altura do pulinho no meio do dodge, em pixels
@export var fire_rate := 0.15

# Números base (antes dos upgrades). Upgrades.apply_stats() recalcula os de cima a partir deles.
var base_max_hp := 0
var base_speed := 0.0
var base_fire_rate := 0.0
var base_roll_cooldown := 0.0
# Tiro (mexido pelos upgrades)
var bullet_damage := 1
var bullet_pierce := 0     # quantos inimigos extras o tiro atravessa
var bullet_count := 1      # projéteis por tiro (em leque)
var bullet_bounces := 0   # quantas vezes o tiro ricocheteia na parede (Wi-Fi)
var crit_chance := 0.0
var crit_mult := 2         # quanto o crítico multiplica (Cola da Prova: 3)
var roll_burst := false    # Carteirinha de Monitor: dodge solta tiros em volta
var _boost := 0.0          # tempo restante do Café Duplo
## Na frente da faculdade (antes do ônibus) o estudante ainda não tem arma.
var can_shoot := true

var _roll_timer := 0.0
var _roll_dir := Vector2.ZERO
var _roll_cd := 0.0
var _fire_cd := 0.0
var _invuln_timer := 0.0
var hp := 0
const SPRITE_Y := 2.0 # pé do sprite (pivô da gingada)

# 8 direções a partir de 5 vistas desenhadas; as da esquerda espelham as da direita.
# Índice = ângulo do mouse em fatias de 45°, começando na direita e girando no sentido horário.
const CELL := Vector2i(48, 48) # tamanho de cada quadro (ver tools/build_student_sheets.py)
# Estudante novo (SpriteCook top-down): vistas de frente (s), costas (n) e lado (e);
# a esquerda espelha a direita e as diagonais usam a vista de lado.
const VIEWS := ["s", "e", "n"]
const DIR_TO_VIEW := [
	["e", false], ["e", false], ["s", false], ["e", true],
	["e", true], ["e", true], ["n", false], ["e", false],
]
const SPRITE_DIR := "res://assets/sprites/student2"
const ANIM_FPS := {"idle": 8.0, "walk": 12.0, "roll": 20.0}
const ANIM_LOOP := {"idle": true, "walk": true, "roll": false}

var _view := "s"

func _ready() -> void:
	add_to_group("player")
	# Camadas de colisão: 1 = paredes/cenário, 2 = jogador, 3 = inimigos, 4 = hurtbox dos inimigos.
	collision_layer = 2
	collision_mask = 1
	base_max_hp = max_hp
	base_speed = speed
	base_fire_rate = fire_rate
	base_roll_cooldown = roll_cooldown
	Upgrades.apply_stats(self)
	hp = max_hp
	health_changed.emit(hp, max_hp)
	$Sprite2D.sprite_frames = _build_frames()
	$Sprite2D.play("idle_s")
	$Gun.default_color = Color("3a3848")
	$Gun.width = 3.0
	$Dust.color = Color(0.55, 0.5, 0.65, 0.8)

## Monta as animações idle_<vista> e walk_<vista> a partir das folhas em assets/sprites/student/.
func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	for kind in ANIM_FPS:
		for view in VIEWS:
			var anim := "%s_%s" % [kind, view]
			var path := "%s/%s.png" % [SPRITE_DIR, anim]
			if not ResourceLoader.exists(path):
				continue # vista ainda não gerada: _start_roll_anim() cai no andar
			var tex: Texture2D = load(path)
			sf.add_animation(anim)
			sf.set_animation_speed(anim, ANIM_FPS[kind])
			sf.set_animation_loop(anim, ANIM_LOOP[kind])
			for i in tex.get_width() / CELL.x:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * CELL.x, 0, CELL.x, CELL.y)
				sf.add_frame(anim, at)
	return sf

func take_damage(amount: int = 1) -> void:
	if hp <= 0 or is_rolling() or _invuln_timer > 0.0:
		return
	hp = max(hp - amount, 0)
	_invuln_timer = invuln_time
	health_changed.emit(hp, max_hp)
	Fx.burst(get_parent(), global_position + Vector2(0, -16), Color("e0383f"), 8, 70.0, 2.0)
	if hp == 0:
		_die()
	else:
		Sfx.play(self, "hurt")

func heal(amount: int = 1) -> void:
	if hp <= 0:
		return
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)

## Café Duplo: anda mais rápido por um tempo.
func speed_boost(time: float) -> void:
	_boost = time

## Trava o tiro um instante (ex.: o clique que escolheu o upgrade não vira tiro).
func hold_fire(time: float) -> void:
	_fire_cd = maxf(_fire_cd, time)

func _die() -> void:
	Sfx.play(self, "die", 0.0)
	set_physics_process(false)
	$Sprite2D.modulate = Color(1, 0.3, 0.3)
	died.emit()
	# Reprovou: volta pra frente da faculdade e recomeça a run.
	await get_tree().create_timer(1.6).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func is_rolling() -> bool:
	return _roll_timer > 0.0 # use isso pra invencibilidade no roll

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_fire_cd -= delta
	_roll_cd = maxf(_roll_cd - delta, 0.0)
	_invuln_timer = max(_invuln_timer - delta, 0.0)
	_boost = maxf(_boost - delta, 0.0)
	var max_speed := speed * (1.35 if _boost > 0.0 else 1.0)
	if Input.is_action_just_pressed("debug_hit"): # H = tomar dano (teste)
		take_damage()
	if is_rolling():
		# Impulso que perde força até parar: anda exatamente roll_distance.
		var t := 1.0 - _roll_timer / roll_time
		velocity = _roll_dir * (2.0 * roll_distance / roll_time) * (1.0 - t)
		_roll_timer -= delta
		if _roll_timer <= 0.0:
			_roll_cd = roll_cooldown
	else:
		var rate := accel if input != Vector2.ZERO else friction
		velocity = velocity.move_toward(input * max_speed, rate * delta)
		if Input.is_action_just_pressed("dodge") and input != Vector2.ZERO and _roll_cd <= 0.0:
			_roll_timer = roll_time
			_roll_dir = input.normalized()
			Sfx.play(self, "roll")
			if roll_burst:
				_burst_shot(8)
			_start_roll_anim()
		elif can_shoot and Input.is_action_pressed("shoot") and _fire_cd <= 0.0:
			_shoot()
	move_and_slide()

func _shoot() -> void:
	_fire_cd = fire_rate
	Sfx.play(self, "shoot")
	var aim := (get_global_mouse_position() - global_position).normalized()
	# Apostila: mais projéteis em leque, 10° entre eles, centrados na mira.
	var spread := deg_to_rad(10.0)
	for i in bullet_count:
		var dir := aim.rotated((i - (bullet_count - 1) / 2.0) * spread)
		var b := BULLET.instantiate()
		b.global_position = global_position + Vector2(0, -15) + dir * 12.0
		b.direction = dir
		var crit := randf() < crit_chance
		b.damage = bullet_damage * (crit_mult if crit else 1)
		b.crit = crit
		b.pierce = bullet_pierce
		b.bounces = bullet_bounces
		get_parent().add_child(b)

## Tiros em todas as direções (Carteirinha de Monitor).
func _burst_shot(n: int) -> void:
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * i / n)
		var b := BULLET.instantiate()
		b.global_position = global_position + Vector2(0, -15) + dir * 10.0
		b.direction = dir
		b.damage = bullet_damage
		b.pierce = bullet_pierce
		b.bounces = bullet_bounces
		get_parent().add_child(b)

func _process(delta: float) -> void:
	queue_redraw()
	var aim := (get_global_mouse_position() - global_position).normalized()
	var spr: AnimatedSprite2D = $Sprite2D
	if is_rolling():
		# Durante o dodge: animação de rolar na direção do movimento + pulinho em arco.
		var t := 1.0 - _roll_timer / roll_time
		spr.position.y = SPRITE_Y - round(sin(t * PI) * roll_hop)
		spr.rotation = 0.0
		$Dust.emitting = true
		$Gun.visible = false
		_update_blink()
		return
	spr.position.y = SPRITE_Y
	$Gun.visible = can_shoot
	# Olha pro mouse: escolhe a mais próxima das 8 direções.
	var dir := _dir_index(aim)
	_view = DIR_TO_VIEW[dir][0]
	spr.flip_h = DIR_TO_VIEW[dir][1]
	# Andando: animação de andar na direção que olha + leve gingada. Parado: idle ofegante.
	var moving := velocity.length() > 10.0 and not is_rolling()
	if hp > 0:
		_play_keep_phase(spr, ("walk_" if moving else "idle_") + _view)
	if moving:
		spr.speed_scale = clampf(velocity.length() / speed, 0.5, 1.2)
		# 8 quadros = 2 passos: a gingada vai e volta duas vezes por ciclo
		# Sem girar o sprite: girar pixel art desmancha os pixels e fica borrado.
		# A gingada agora é só 1px de sobe-e-desce, no ritmo dos passos.
		var count := spr.sprite_frames.get_frame_count(spr.animation)
		var ph := (spr.frame + spr.frame_progress) / count * TAU * 2.0
		spr.position.y = SPRITE_Y
		spr.rotation = 0.0
	else:
		spr.rotation = 0.0
		spr.speed_scale = 1.0
	# Arma atrás do corpo quando mira pra cima.
	$Gun.z_index = -1 if aim.y < -0.3 else 0
	$Dust.emitting = moving
	_update_blink()
	# "Arma" placeholder: linha saindo da altura da mão.
	var hand := Vector2(0, -15)
	$Gun.points = PackedVector2Array([hand + aim * 4.0, hand + aim * 12.0])

func _dir_index(v: Vector2) -> int:
	return wrapi(roundi(v.angle() / (PI / 4.0)), 0, 8)

func _update_blink() -> void:
	if hp > 0:
		var blink := _invuln_timer > 0.0 and int(_invuln_timer * 20.0) % 2 == 0
		$Sprite2D.modulate.a = 0.4 if blink else 1.0

func _start_roll_anim() -> void:
	var spr: AnimatedSprite2D = $Sprite2D
	var dir := _dir_index(_roll_dir)
	var view: String = DIR_TO_VIEW[dir][0]
	spr.flip_h = DIR_TO_VIEW[dir][1]
	spr.rotation = 0.0
	var anim := "roll_" + view
	if not spr.sprite_frames.has_animation(anim):
		anim = "walk_" + view
	spr.play(anim)
	spr.frame = 0
	# encaixa a animação inteira na duração do dodge
	var frames := spr.sprite_frames.get_frame_count(anim)
	spr.speed_scale = frames / (roll_time * spr.sprite_frames.get_animation_speed(anim))

## Troca de animação sem reiniciar o passo (ex.: girar o mouse enquanto anda).
func _play_keep_phase(spr: AnimatedSprite2D, anim: String) -> void:
	if spr.animation == anim:
		if not spr.is_playing():
			spr.play(anim)
		return
	var same_kind := String(spr.animation).get_slice("_", 0) == anim.get_slice("_", 0)
	var frame := spr.frame
	var progress := spr.frame_progress
	spr.play(anim)
	if same_kind:
		spr.set_frame_and_progress(frame, progress)

func _draw() -> void:
	# Sombra no pé (some um pouco no pulinho do dodge)
	var lift := absf($Sprite2D.position.y - SPRITE_Y)
	Fx.contact_shadow(self, Vector2(0, 1), 11.0 - lift * 0.5, 1.7 - lift * 0.12)
