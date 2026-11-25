extends Node2D
## Ônibus da área inicial: fica com o motor ligado (tremendo e soltando fumaça).
## Quando o jogador entra pela porta, emite `boarded` e o ônibus arranca.
## A origem do nó é o meio da base do ônibus (onde as rodas tocam o chão).

signal boarded(player: Node2D)

const TEX := preload("res://assets/props/bus.png")

@export var door_x := 60.0          # centro da porta, relativo ao meio do ônibus
@export var exhaust := Vector2(-94, -10) # saída do escapamento, relativa à origem
@export var idle_shake_interval := 0.07 # o motor "pula" 1px nesse ritmo

var _sprite := Sprite2D.new()
var _smoke := CPUParticles2D.new()
var _shake_t := 0.0
var _leaving := false
var _drive_speed := 0.0

func _ready() -> void:
	var size := TEX.get_size()
	_sprite.texture = TEX
	_sprite.centered = false
	_sprite.offset = Vector2(-size.x / 2.0, -size.y)
	add_child(_sprite)
	_add_body(size)
	_add_door()
	_setup_smoke()

func _add_body(size: Vector2) -> void:
	# Só a faixa de baixo é sólida: o jogador pode passar "atrás" do teto.
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x - 10, 22)
	col.shape = rect
	col.position = Vector2(0, -11)
	body.add_child(col)
	add_child(body)

func _add_door() -> void:
	var door := Area2D.new()
	door.collision_mask = 2 # camada do jogador
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 10)
	col.shape = rect
	door.position = Vector2(door_x, 4)
	door.add_child(col)
	door.body_entered.connect(_on_door_body_entered)
	add_child(door)

func _setup_smoke() -> void:
	# Fumaça: bolinhas cinzas que saem pra trás, sobem, crescem e somem.
	_smoke.texture = _make_puff_texture()
	_smoke.position = exhaust
	_smoke.amount = 22
	_smoke.lifetime = 1.8
	_smoke.direction = Vector2(-1, -0.25)
	_smoke.spread = 18.0
	_smoke.initial_velocity_min = 20.0
	_smoke.initial_velocity_max = 32.0
	_smoke.gravity = Vector2(0, -16)
	_smoke.damping_min = 6.0
	_smoke.damping_max = 10.0
	_smoke.scale_amount_min = 1.4
	_smoke.scale_amount_max = 2.2
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.4))
	grow.add_point(Vector2(1, 1.0))
	_smoke.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(0.42, 0.42, 0.46, 0.95))
	fade.set_color(1, Color(0.75, 0.75, 0.78, 0.0))
	_smoke.color_ramp = fade
	add_child(_smoke)

## Bolinha de 7px com borda dura (pra continuar com cara de pixel art).
func _make_puff_texture() -> Texture2D:
	var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	for x in 7:
		for y in 7:
			if Vector2(x - 3, y - 3).length() <= 3.2:
				img.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	# Motor ligado: o corpo do ônibus pula 1px pra cima e pra baixo.
	_shake_t += delta
	var interval := idle_shake_interval * (0.5 if _leaving else 1.0)
	if _shake_t >= interval:
		_shake_t = 0.0
		_sprite.position.y = -1.0 if _sprite.position.y == 0.0 else 0.0
		_sprite.position.x = (randi() % 3 - 1) if _leaving else 0.0
	if _leaving:
		_drive_speed += 140.0 * delta
		position.x += _drive_speed * delta

func _on_door_body_entered(body: Node2D) -> void:
	if _leaving or not body.is_in_group("player"):
		return
	_leaving = true
	_smoke.speed_scale = 2.0
	boarded.emit(body)
