extends Area2D
## Projétil do jogador: anda reto, acerta a hurtbox dos inimigos, some ao bater
## em parede/móvel ou após lifetime. Os upgrades mexem em dano, crítico,
## quantos inimigos atravessa (pierce) e se persegue o inimigo (homing).

@export var speed := 260.0
@export var lifetime := 1.5
@export var damage := 1

var direction := Vector2.RIGHT
var crit := false
var pierce := 0      # inimigos extras que atravessa (Calculadora Científica)
var homing := 0.0    # força da curva atrás do inimigo (Wi-Fi da faculdade)
const HOMING_RANGE := 150.0

var _done := false
var _hit: Array[Node] = [] # quem já levou esse tiro (pra não acertar duas vezes)

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
	if enemy == null or not enemy.has_method("take_damage") or _hit.has(enemy):
		return
	_hit.append(enemy)
	enemy.take_damage(damage, direction, crit)
	if pierce > 0:
		pierce -= 1
		return
	_done = true
	queue_free()

func _physics_process(delta: float) -> void:
	if homing > 0.0:
		var target := _nearest_enemy()
		if target:
			var want := (target.global_position + Vector2(0, -14) - global_position).normalized()
			var ang := direction.angle_to(want)
			direction = direction.rotated(clampf(ang, -homing * delta, homing * delta))
	position += direction * speed * delta

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := HOMING_RANGE
	for e: Node2D in get_tree().get_nodes_in_group("enemy"):
		if e.dead or e.is_spawning() or _hit.has(e):
			continue
		var d := e.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _draw() -> void:
	var core := Color("ff5a5a") if crit else Color("ff9a3d")
	var s := 4.0 if crit else 3.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), Color("0b0612"))
	draw_rect(Rect2(-s + 1, -s + 1, s * 2 - 2, s * 2 - 2), core)
	draw_rect(Rect2(-1, -1, 2, 2), Color("ffe08a"))
