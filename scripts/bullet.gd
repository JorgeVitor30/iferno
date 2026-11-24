extends Area2D
## Projétil simples: anda reto, some ao bater em algo ou após lifetime.

@export var speed := 260.0
@export var lifetime := 1.5

var direction := Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(func(_b): queue_free())
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.0, Color("ff6b3d"))
