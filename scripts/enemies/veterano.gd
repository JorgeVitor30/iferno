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
	# camiseta branca suja de tinta, bandana, pintura de guerra e balde de tinta
	var b := draw_person(Color("d8d4cc"), Color("2e4a78"), Color("2a1a14"))
	if _state == State.DASH:
		b -= 1.0
	fb(-2, -6 + b, 2, 1, _paint)
	fb(0, -4 + b, 2, 1, _paint)
	fb(0, -10 + b, 3, 1, _paint)      # pintura no rosto
	fb(-4, -13 + b, 8, 1, Color("c0383a")) # bandana
	fb(-6, -13 + b, 2, 1, Color("c0383a"))
	var lift := 2.0 if _state == State.AIM else 0.0
	bb(3, -6 + b - lift, 4, 4, Color("8a8498"))
	fb(3, -6 + b - lift, 4, 1, _paint)
	draw_front_arm(Color("d8d4cc"), b, lift)
	if _state == State.TIRED:
		var y := -17.0 + b - fmod(anim_t * 10.0, 3.0)
		fb(-4, y, 1, 1, Color("6de2f1"))
		fb(4, y + 1, 1, 1, Color("6de2f1"))
