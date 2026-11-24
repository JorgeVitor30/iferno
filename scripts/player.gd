extends CharacterBody2D
## Jogador: WASD anda, mouse mira, botão esquerdo atira, espaço/botão direito = dodge roll.

const BULLET := preload("res://scenes/bullet.tscn")

@export var speed := 90.0
@export var roll_speed := 190.0
@export var roll_time := 0.35
@export var fire_rate := 0.15

var _roll_timer := 0.0
var _roll_dir := Vector2.ZERO
var _fire_cd := 0.0

func is_rolling() -> bool:
	return _roll_timer > 0.0 # use isso pra invencibilidade no roll

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_fire_cd -= delta
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
	queue_redraw()

func _shoot() -> void:
	_fire_cd = fire_rate
	var dir := (get_global_mouse_position() - global_position).normalized()
	var b := BULLET.instantiate()
	b.global_position = global_position + dir * 8.0
	b.direction = dir
	get_parent().add_child(b)

func _draw() -> void:
	var body_color := Color("e8c170", 0.5 if is_rolling() else 1.0)
	draw_circle(Vector2.ZERO, 5.0, body_color)
	var aim := get_local_mouse_position().normalized()
	draw_line(aim * 4.0, aim * 10.0, Color.WHITE, 2.0)
