extends Area2D
## Projétil do jogador: anda reto, acerta a hurtbox dos inimigos, some ao bater
## em parede/móvel ou após lifetime. Os upgrades mexem em dano, crítico,
## quantos inimigos atravessa (pierce) e quantas vezes ricocheteia na parede.

@export var speed := 260.0
@export var lifetime := 1.5
@export var damage := 1

var direction := Vector2.RIGHT
var crit := false
var pierce := 0      # inimigos extras que atravessa (Calculadora Científica)
var bounces := 0     # ricochetes que ainda restam (Wi-Fi da faculdade: o sinal rebate)

var _done := false
var _hit: Array[Node] = [] # quem já levou esse tiro (pra não acertar duas vezes)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 8 # hurtbox dos inimigos (paredes/cenário: raio em _physics_process)
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
	var step := direction * speed * delta
	# Parede/móvel no caminho? Ricocheteia (se ainda pode) ou some.
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		if bounces > 0:
			bounces -= 1
			var n: Vector2 = hit["normal"]
			direction = direction.bounce(n).normalized()
			global_position = hit["position"] + n * 2.0
			_hit.clear() # depois de rebater pode acertar de novo quem já levou
			Sfx.play(self, "bounce")
			Fx.burst(get_parent(), position, Color("6de2f1"), 3, 30.0, 1.0)
			queue_redraw()
			return
		Fx.burst(get_parent(), hit["position"], Color("ff9a6a"), 3, 30.0, 1.0)
		queue_free()
		return
	position += step

func _draw() -> void:
	var core := Color("ff5a5a") if crit else Color("6de2f1") if bounces > 0 else Color("ff9a3d")
	var s := 4.0 if crit else 3.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), Color("0b0612"))
	draw_rect(Rect2(-s + 1, -s + 1, s * 2 - 2, s * 2 - 2), core)
	draw_rect(Rect2(-1, -1, 2, 2), Color("ffe08a"))
