extends Area2D
## Projétil do jogador: anda reto, acerta a hurtbox dos inimigos, some ao bater
## em parede/móvel ou após lifetime.

@export var speed := 260.0
@export var lifetime := 1.5
@export var damage := 1

var direction := Vector2.RIGHT
var _done := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 8 # paredes/cenário e hurtbox dos inimigos
	body_entered.connect(func(_b):
		Fx.burst(get_parent(), position, Color("ff9a6a"), 3, 30.0, 1.0)
		queue_free())
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_area_entered(area: Area2D) -> void:
	if _done:
		return
	var enemy := area.get_parent()
	if enemy and enemy.has_method("take_damage"):
		_done = true
		enemy.take_damage(damage, direction)
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.0, Color("ff6b3d"))
