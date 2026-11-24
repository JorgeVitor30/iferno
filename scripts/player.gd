extends CharacterBody2D
## Jogador: WASD anda, mouse mira, botão esquerdo atira, espaço/botão direito = dodge roll.

const BULLET := preload("res://scenes/bullet.tscn")

signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp := 6
@export var invuln_time := 0.8 # invencibilidade depois de tomar hit

@export var speed := 90.0
@export var accel := 900.0     # quão rápido chega na velocidade máxima
@export var friction := 1100.0 # quão rápido para ao soltar as teclas
@export var walk_tilt_deg := 3.0 # quanto o boneco ginga pros lados ao andar
@export var roll_speed := 190.0
@export var roll_time := 0.35
@export var fire_rate := 0.15

var _roll_timer := 0.0
var _roll_dir := Vector2.ZERO
var _fire_cd := 0.0
var _invuln_timer := 0.0
var hp := 0
const SPRITE_Y := 2.0 # pé do sprite (pivô da gingada)

# 8 direções a partir de 5 vistas desenhadas; as da esquerda espelham as da direita.
# Índice = ângulo do mouse em fatias de 45°, começando na direita e girando no sentido horário.
const CELL := Vector2i(32, 44) # tamanho de cada quadro (ver tools/build_student_sheets.py)
const VIEWS := ["s", "se", "e", "ne", "n"]
const DIR_TO_VIEW := [
	["e", false], ["se", false], ["s", false], ["se", true],
	["e", true], ["ne", true], ["n", false], ["ne", false],
]
const ANIM_FPS := {"idle": 8.0, "walk": 12.0}

var _view := "s"

func _ready() -> void:
	hp = max_hp
	health_changed.emit(hp, max_hp)
	$Sprite2D.sprite_frames = _build_frames()
	$Sprite2D.play("idle_s")

## Monta as animações idle_<vista> e walk_<vista> a partir das folhas em assets/sprites/student/.
func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	for kind in ANIM_FPS:
		for view in VIEWS:
			var anim := "%s_%s" % [kind, view]
			var tex: Texture2D = load("res://assets/sprites/student/%s.png" % anim)
			sf.add_animation(anim)
			sf.set_animation_speed(anim, ANIM_FPS[kind])
			sf.set_animation_loop(anim, true)
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
	if hp == 0:
		_die()

func _die() -> void:
	set_physics_process(false)
	$Sprite2D.modulate = Color(1, 0.3, 0.3)
	died.emit()
	# Por enquanto: reinicia a sala depois de 1s.
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func is_rolling() -> bool:
	return _roll_timer > 0.0 # use isso pra invencibilidade no roll

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_fire_cd -= delta
	_invuln_timer = max(_invuln_timer - delta, 0.0)
	if Input.is_action_just_pressed("debug_hit"): # H = tomar dano (teste)
		take_damage()
	if is_rolling():
		_roll_timer -= delta
		velocity = _roll_dir * roll_speed
	else:
		var rate := accel if input != Vector2.ZERO else friction
		velocity = velocity.move_toward(input * speed, rate * delta)
		if Input.is_action_just_pressed("dodge") and input != Vector2.ZERO:
			_roll_timer = roll_time
			_roll_dir = input.normalized()
		elif Input.is_action_pressed("shoot") and _fire_cd <= 0.0:
			_shoot()
	move_and_slide()

func _shoot() -> void:
	_fire_cd = fire_rate
	var dir := (get_global_mouse_position() - global_position).normalized()
	var b := BULLET.instantiate()
	b.global_position = global_position + Vector2(0, -15) + dir * 12.0
	b.direction = dir
	get_parent().add_child(b)

func _process(delta: float) -> void:
	var aim := (get_global_mouse_position() - global_position).normalized()
	var spr: AnimatedSprite2D = $Sprite2D
	# Olha pro mouse: escolhe a mais próxima das 8 direções.
	var dir := wrapi(roundi(aim.angle() / (PI / 4.0)), 0, 8)
	_view = DIR_TO_VIEW[dir][0]
	spr.flip_h = DIR_TO_VIEW[dir][1]
	# Andando: animação de andar na direção que olha + leve gingada. Parado: idle ofegante.
	var moving := velocity.length() > 10.0 and not is_rolling()
	if hp > 0:
		_play_keep_phase(spr, ("walk_" if moving else "idle_") + _view)
	if moving:
		spr.speed_scale = clampf(velocity.length() / speed, 0.5, 1.2)
		# 8 quadros = 2 passos: a gingada vai e volta duas vezes por ciclo
		var count := spr.sprite_frames.get_frame_count(spr.animation)
		var ph := (spr.frame + spr.frame_progress) / count * TAU * 2.0
		spr.rotation = sin(ph) * deg_to_rad(walk_tilt_deg)
	else:
		spr.rotation = lerp_angle(spr.rotation, 0.0, minf(delta * 20.0, 1.0))
		spr.speed_scale = 1.0
	# Arma atrás do corpo quando mira pra cima.
	$Gun.z_index = -1 if aim.y < -0.3 else 0
	$Dust.emitting = moving
	if hp > 0:
		var blink := _invuln_timer > 0.0 and int(_invuln_timer * 20.0) % 2 == 0
		$Sprite2D.modulate.a = 0.5 if is_rolling() or blink else 1.0
	# "Arma" placeholder: linha saindo da altura da mão.
	var hand := Vector2(0, -15)
	$Gun.points = PackedVector2Array([hand + aim * 4.0, hand + aim * 12.0])

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
	# Sombra no pé
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.35))
