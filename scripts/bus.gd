extends Node2D
## Ônibus da área inicial: fica com o motor ligado (tremendo e soltando fumaça).
## Quando o jogador entra pela porta, emite `boarded` e o ônibus arranca.
## A origem do nó é o meio da base do ônibus (onde as rodas tocam o chão).

signal boarded(player: Node2D)

const SIZE := Vector2(212, 96) # tamanho na tela (desenhado em pixel grosso, 106x48 de arte)

@export var door_x := 60.0          # centro da porta, relativo ao meio do ônibus
@export var exhaust := Vector2(-94, -10) # saída do escapamento, relativa à origem
@export var idle_shake_interval := 0.07 # o motor "pula" 1px nesse ritmo

var _sprite := Node2D.new() # o desenho do ônibus (treme com o motor)
var _smoke := CPUParticles2D.new()
var _shake_t := 0.0
var _leaving := false
var _drive_speed := 0.0

func _ready() -> void:
	var size := SIZE
	_sprite.draw.connect(_draw_bus)
	add_child(_sprite)
	Fx.glow(_sprite, Vector2(100, -30), 30.0, Color("fce6bd"), 0.6) # farol
	Fx.glow(_sprite, Vector2(0, -60), 70.0, Color("ffb060"), 0.25)  # luz de dentro
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

## Ônibus verde no estilo clean (unidades de arte, 2px cada). Origem = meio da base.
func _draw_bus() -> void:
	var c := _sprite
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var o := Fx.OUTLINE
	var green := Color("2f7a5a")
	var green_l := Color("4a9a6a")
	var green_d := Color("1f5a42")
	c.draw_rect(Rect2(-50, -1, 100, 2), Color(0, 0, 0, 0.35))      # sombra
	c.draw_rect(Rect2(-54, -46, 108, 42), o)
	c.draw_rect(Rect2(-53, -45, 106, 40), green)
	c.draw_rect(Rect2(-53, -45, 106, 2), green_l)
	c.draw_rect(Rect2(-53, -12, 106, 7), green_d)                   # saia
	c.draw_rect(Rect2(-53, -20, 106, 2), Color("e0d8d0"))           # faixa
	# janelas iluminadas
	var x := -48
	while x < 22:
		c.draw_rect(Rect2(x - 1, -40, 12, 14), o)
		c.draw_rect(Rect2(x, -39, 10, 12), Color("f0c878"))
		c.draw_rect(Rect2(x, -39, 10, 2), Color("fce6bd"))
		x += 14
	# porta (onde o jogador entra) e para-brisa
	c.draw_rect(Rect2(26, -40, 14, 35), o)
	c.draw_rect(Rect2(27, -39, 12, 33), Color("2a3a4a"))
	c.draw_rect(Rect2(32, -39, 1, 33), o)
	c.draw_rect(Rect2(43, -40, 9, 20), o)
	c.draw_rect(Rect2(44, -39, 8, 18), Color("6aa8c8"))
	c.draw_rect(Rect2(44, -39, 8, 2), Color("bfe3ff"))
	c.draw_rect(Rect2(50, -14, 3, 3), Color("fce6bd"))               # farol
	# letreiro
	c.draw_rect(Rect2(-30, -45, 40, 4), o)
	# rodas
	for wx in [-34, 30]:
		c.draw_circle(Vector2(wx, -4), 6.0, o)
		c.draw_circle(Vector2(wx, -4), 4.5, Color("2a2838"))
		c.draw_circle(Vector2(wx, -4), 1.5, Color("8a8498"))
	c.draw_set_transform(Vector2.ZERO)
	Fx.text(c, Vector2(-60, -82), "CAMPUS", Color("ffd966"), 11, 80, HORIZONTAL_ALIGNMENT_CENTER)

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
