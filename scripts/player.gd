extends CharacterBody2D
## Jogador: WASD anda, mouse mira, botão esquerdo atira, espaço/botão direito = dodge roll.

const BULLET := preload("res://scenes/bullet.tscn")

signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp := 6
@export var invuln_time := 0.8 # invencibilidade depois de tomar hit

@export var speed := 90.0
@export var roll_speed := 190.0
@export var roll_time := 0.35
@export var fire_rate := 0.15

var _roll_timer := 0.0
var _roll_dir := Vector2.ZERO
var _fire_cd := 0.0
var _invuln_timer := 0.0
var hp := 0

func _ready() -> void:
	hp = max_hp
	health_changed.emit(hp, max_hp)

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
		velocity = input * speed
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

func _process(_delta: float) -> void:
	var aim := (get_global_mouse_position() - global_position).normalized()
	$Sprite2D.flip_h = aim.x < 0.0
	# Parado: idle ofegante. Andando: segura o 1º quadro (até termos animação de andar).
	if velocity.is_zero_approx():
		$Sprite2D.play("idle")
	else:
		$Sprite2D.pause()
		$Sprite2D.frame = 0
	if hp > 0:
		var blink := _invuln_timer > 0.0 and int(_invuln_timer * 20.0) % 2 == 0
		$Sprite2D.modulate.a = 0.5 if is_rolling() or blink else 1.0
	# "Arma" placeholder: linha saindo da altura da mão.
	var hand := Vector2(0, -15)
	$Gun.points = PackedVector2Array([hand + aim * 4.0, hand + aim * 12.0])

func _draw() -> void:
	# Sombra no pé
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.35))
