extends Enemy
## Veterano do trote (corpo a corpo, rápido): mira, avisa com uma linha
## e dispara numa investida com o balde de tinta, sujando o chão no caminho.
## Depois da investida fica ofegante por um tempo (janela pra punir).

enum State { APPROACH, AIM, DASH, TIRED }

const PAINTS := [Color("ff4fa3"), Color("3fd17a"), Color("ffd23f"), Color("4fb3ff")]

var _state := State.APPROACH
var _t := 0.0
var _cd := 1.0
var _dir := Vector2.RIGHT
var _splat_cd := 0.0
var _paint := Color.WHITE
var _hit_this_dash := false

func _setup() -> void:
	display_name = "Veterano"
	max_hp = 5 + floor_level
	speed = 60.0 + floor_level * 4.0
	contact_damage = false
	_paint = PAINTS[randi() % PAINTS.size()]
	hit_color = _paint
	drop_chance = 0.1
	lines = ["BIXO!", "Trote!", "Vem cá, calouro!", "Tinta neles!", "Passa a careca!"]
	death_lines = ["Vou me formar ano que vem...", "8º ano de curso...", "Isso não é trote!"]

func _think(delta: float) -> Vector2:
	var to := to_player()
	_t -= delta
	_cd -= delta
	match _state:
		State.APPROACH:
			if _cd <= 0.0 and to.length() < 140.0:
				_state = State.AIM
				_t = 0.55
				_squash = Vector2(1.2, 0.8)
				alert = true
				return Vector2.ZERO
			# chega meio de lado, não reto
			var side := to.orthogonal().normalized() * sin(anim_t * 2.0) * 0.5
			return (to.normalized() + side).normalized() * speed
		State.AIM:
			_dir = to.normalized()
			if _t <= 0.0:
				_state = State.DASH
				_t = 0.36
				_hit_this_dash = false
				alert = false
				if randf() < 0.25:
					say("UUUH!")
			return Vector2.ZERO
		State.DASH:
			_splat_cd -= delta
			if _splat_cd <= 0.0:
				_splat_cd = 0.05
				spawn_decal("tinta", _paint)
			if not _hit_this_dash and to.length() < 14.0:
				_hit_this_dash = true
				hurt_player()
			if _t <= 0.0:
				_state = State.TIRED
				_t = 0.8
				_squash = Vector2(1.3, 0.7)
				Fx.burst(get_parent(), global_position + Vector2(0, -4), _paint, 8, 60.0)
			return _dir * (250.0 + floor_level * 10.0)
		State.TIRED:
			if _t <= 0.0:
				_state = State.APPROACH
				_cd = randf_range(0.8, 1.6)
			return Vector2.ZERO
	return Vector2.ZERO

func _on_death() -> void:
	spawn_decal("tinta", _paint)
	Fx.burst(get_parent(), global_position + Vector2(0, -12), _paint, 16, 120.0, 2.5)

func _draw_overlay() -> void:
	# Linha tracejada mostrando pra onde ele vai investir.
	if _state == State.AIM:
		var a := 0.4 + 0.5 * float(int(anim_t * 16.0) % 2)
		for i in 8:
			var p0 := _dir * (12.0 + i * 14.0)
			draw_line(p0, p0 + _dir * 7.0, Color(1, 0.3, 0.3, a), 2.0)

func _draw_body() -> void:
	var bob := draw_person(Color("e8e4dc"), Color("3a5a8a"), Color("2a1a14"))
	if _state == State.DASH:
		bob -= 2.0
	# Manchas de tinta na camiseta e pintura de guerra no rosto
	draw_rect(Rect2(-4, -17 + bob, 3, 2), _paint)
	draw_rect(Rect2(1, -13 + bob, 4, 2), _paint)
	draw_rect(Rect2(-2, -11 + bob, 2, 2), _paint.darkened(0.2))
	draw_rect(Rect2(0, -24 + bob, 5, 1), _paint)
	draw_rect(Rect2(-1, -22 + bob, 5, 1), _paint)
	# Bandana
	draw_rect(Rect2(-5, -29 + bob, 10, 2), Color("d94a4a"))
	draw_rect(Rect2(-8, -29 + bob, 3, 1), Color("d94a4a"))
	# Balde de tinta na mão da frente
	var lift := 3.0 if _state == State.AIM else 0.0
	var bucket := Rect2(5, -12 + bob - lift, 7, 7)
	draw_rect(bucket.grow(1.0), Fx.OUTLINE)
	draw_rect(bucket, Color("b8b8c4"))
	draw_rect(Rect2(bucket.position, Vector2(7, 2)), _paint)
	draw_front_arm(Color("e8e4dc"), bob, lift)
	if _state == State.TIRED:
		# gotinhas de suor
		var y := -32.0 + bob - fmod(anim_t * 20.0, 6.0)
		draw_rect(Rect2(-8, y, 2, 2), Color("7ec8e3"))
		draw_rect(Rect2(7, y + 3, 2, 2), Color("7ec8e3"))
