class_name Enemy
extends CharacterBody2D
## Base dos inimigos da faculdade. Cada tipo herda daqui e implementa:
##   _setup()      -> números (vida, velocidade) e falas
##   _think(delta) -> devolve a velocidade desejada (IA)
##   _draw_body()  -> desenho do boneco (origem nos pés, olhando pra direita)
## Placeholders desenhados em _draw() até existirem sprites.

signal died(enemy: Enemy)

const BULLET := preload("res://scripts/enemy_bullet.gd")
const DECAL := preload("res://scripts/decal.gd")
const CAFE := preload("res://scripts/cafe.gd")
const OUTLINE := Color("1a1020")
const SKIN := Color("f0b48a")
const SKIN_SHADE := Color("c98f68")
const PAPER := Color("e0d8d0")
const SPAWN_TIME := 0.8
const SPEED_MULTIPLIER := 1.3

var max_hp := 5
var speed := 40.0
var contact_damage := true
var drop_chance := 0.1
var body_scale := 1.0
# Tamanho "em pixels de verdade" (sem escala): bonecos grandes desenhados no tamanho nativo
# mudam isso no _setup() em vez de usar body_scale (que borra o pixel).
var hurt_size := Vector2(22, 50) # hurtbox (onde o tiro acerta)
var col_radius := 5.0            # círculo do pé (bate em parede)
var head_y := 54.0               # altura da cabeça (balão de fala, "!")
## Sprite do SpriteCook (de frente). Se tiver, desenha ele em vez do boneco em código,
## animado aqui: passo, respiração, achatamento e virar pro lado do jogador.
var sprite_tex: Texture2D
var shadow_r := 9.0
var elite := false
var boss := false # chefe do andar: barra de vida no HUD, não é empurrado por tiro
var display_name := ""
var lines: PackedStringArray = []
var death_lines: PackedStringArray = []
var hit_color := PAPER # cor dos pedacinhos quando leva tiro
var floor_level := 1   # andar atual: inimigos ficam mais bravos nos andares de cima

var hp := 0
var player: Node2D
var facing := 1.0 # 1 = direita, -1 = esquerda
var anim_t := 0.0
var dead := false
var alert := false # mostra "!" em cima da cabeça (aviso de ataque)
var _flash := 0.0
var _knock := Vector2.ZERO
var _spawn_t := SPAWN_TIME
var _squash := Vector2.ONE
var _bubble_cd := 0.0
var _hurtbox := Area2D.new()
var _col := CollisionShape2D.new()

func _ready() -> void:
	add_to_group("enemy")
	_setup()
	hp = max_hp
	anim_t = randf() * 10.0
	collision_layer = 4      # camada 3: inimigos
	collision_mask = 1 | 4   # batem em parede e uns nos outros (não no jogador)
	var c := CircleShape2D.new()
	c.radius = col_radius * body_scale
	_col.shape = c
	add_child(_col)
	# Hurtbox do tamanho do corpo: é nela que o tiro do jogador acerta.
	_hurtbox.collision_layer = 8
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.monitorable = false
	var hb := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = hurt_size * body_scale
	hb.shape = r
	hb.position = Vector2(0, -hurt_size.y / 2.0) * body_scale
	_hurtbox.add_child(hb)
	add_child(_hurtbox)
	player = get_tree().get_first_node_in_group("player") as Node2D
	_bubble_cd = randf_range(5.0, 12.0)

func _setup() -> void:
	pass

func _think(_delta: float) -> Vector2:
	return Vector2.ZERO

func _draw_body() -> void:
	pass

func _on_death() -> void:
	pass

func is_spawning() -> bool:
	return _spawn_t > 0.0

func _physics_process(delta: float) -> void:
	anim_t += delta
	if dead:
		return
	_flash = maxf(_flash - delta, 0.0)
	modulate = Color(6, 6, 6) if _flash > 0.0 else Color.WHITE
	if _spawn_t > 0.0:
		_spawn_t -= delta
		if _spawn_t <= 0.0:
			_hurtbox.set_deferred("monitorable", true)
			_squash = Vector2(0.6, 1.5)
			Fx.burst(get_parent(), global_position + Vector2(0, -12), PAPER, 14, 80.0, 2.0)
		queue_redraw()
		return
	var want := Vector2.ZERO
	if _player_ok():
		want = _think(delta)
		facing = -1.0 if player.global_position.x < global_position.x else 1.0
	_knock = _knock.move_toward(Vector2.ZERO, 700.0 * delta)
	velocity = want * SPEED_MULTIPLIER + _knock
	move_and_slide()
	_squash = _squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	if contact_damage and _player_ok() and to_player().length() < (col_radius + 7.0) * body_scale:
		hurt_player()
	_bubble_cd -= delta
	if _bubble_cd <= 0.0 and lines.size() > 0:
		_bubble_cd = randf_range(16.0, 30.0) # falam bem de vez em quando
		say(lines[randi() % lines.size()])
	queue_redraw()

func _player_ok() -> bool:
	return is_instance_valid(player) and player.visible and player.get("hp") > 0

func to_player() -> Vector2:
	return player.global_position - global_position

func hurt_player() -> void:
	if player.has_method("take_damage"):
		player.take_damage(1)

func take_damage(amount: int = 1, dir: Vector2 = Vector2.ZERO, crit: bool = false) -> void:
	if dead or _spawn_t > 0.0:
		return
	hp -= amount
	_flash = 0.07
	if amount < 100: # (o chefe "apaga" os ajudantes com 999: esse não mostra número)
		_damage_number(amount, crit)
	if hp > 0:
		Sfx.play(self, "crit" if crit else "hit")
	if crit:
		Fx.shake(self, 2.0)
	_knock = dir * (0.0 if boss else 40.0 if elite else 110.0)
	_squash = Vector2(1.3, 0.75)
	Fx.burst(get_parent(), global_position + Vector2(0, -hurt_size.y * 0.5) * body_scale, hit_color, 4, 55.0, 1.5)
	if hp <= 0:
		_die()

## Número de dano subindo da cabeça (crítico: amarelo e grande).
func _damage_number(amount: int, crit: bool) -> void:
	var pos := global_position + Vector2(randf_range(-8, 8), -hurt_size.y * body_scale - 4)
	if crit:
		Fx.float_text(get_parent(), pos, "%d!" % amount, Color("ffd966"), Fx.BIG)
	else:
		Fx.float_text(get_parent(), pos, str(amount), Color("f4e4c0"), Fx.SMALL)

func _die() -> void:
	Sfx.play(self, "kill", 0.12)
	dead = true
	_col.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitorable", false)
	died.emit(self)
	_on_death()
	var parent := get_parent()
	var big := elite or boss
	Fx.shake(self, 10.0 if boss else 5.0 if elite else 2.0)
	Fx.burst(parent, global_position + Vector2(0, -14), PAPER, 40 if big else 18, 140.0 if boss else 110.0, 2.5)
	Fx.burst(parent, global_position + Vector2(0, -14), hit_color, 10, 90.0, 2.0)
	if death_lines.size() > 0:
		Fx.float_text(parent, global_position + Vector2(0, -head_y) * body_scale,
			death_lines[randi() % death_lines.size()], Color("ffd966"))
	if randf() < drop_chance:
		var cafe: Node2D = CAFE.new()
		cafe.position = position
		parent.call_deferred("add_child", cafe)
	# Animação de morte: pulinho, achata e some.
	_squash = Vector2(1.4, 0.6)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.2), 0.18).set_delay(0.05)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.18).set_delay(0.05)
	tw.tween_callback(queue_free)

## Balão de fala rápido em cima da cabeça.
func say(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.z_index = 25
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	l.add_theme_font_size_override("font_size", Fx.SMALL)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_constant_override("outline_size", 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(140, 12)
	l.position = Vector2(-70, -(head_y + 14.0) * body_scale)
	l.scale = Vector2(0.2, 0.2)
	l.pivot_offset = Vector2(70, 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)

## Atira um projétil de papel (sai do chão embaixo da mão e voa na altura da mão).
func shoot(kind: String, dir: Vector2, spd: float, homing: float = 0.0) -> void:
	var b: Area2D = BULLET.new()
	b.kind = kind
	b.direction = dir.normalized()
	b.speed = spd
	b.homing = homing
	b.position = position + dir.normalized() * 8.0
	get_parent().add_child(b)

func spawn_decal(kind: String, color: Color, pos: Vector2 = position) -> void:
	var d: Node2D = DECAL.new()
	d.kind = kind
	d.color = color
	d.position = pos
	get_parent().add_child(d)

# ---------------------------------------------------------------- desenho

func _draw() -> void:
	# Sombra
	Fx.contact_shadow(self, Vector2(0, 2), (shadow_r + 3.0) * body_scale, 1.6)
	if _spawn_t > 0.0:
		draw_set_transform(Vector2.ZERO)
		_draw_spawn()
		return
	# Estilo clean: o corpo é desenhado em unidades de arte (1 unidade = 2px, Fx.ART).
	if sprite_tex:
		_draw_sprite()
	else:
		var s := _squash * body_scale * Fx.ART
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(s.x * facing, s.y))
		_draw_body()
	draw_set_transform(Vector2.ZERO)
	_draw_overlay()
	if alert and int(anim_t * 12.0) % 3 != 0:
		Fx.text(self, Vector2(-3, -(head_y + 2.0) * body_scale - 4), "!", Color("ff5a4a"), 14)
	if elite:
		_draw_elite_bar()

## Sprite com animação procedural (sem girar: pixel art girado borra).
func _draw_sprite() -> void:
	var bob := 0.0
	if is_moving():
		bob = -1.0 if int(anim_t * 8.0) % 2 == 0 else 0.0
	elif fmod(anim_t, 1.4) < 0.7:
		bob = -1.0
	var s := _squash * body_scale
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(s.x * facing, s.y))
	var sz := sprite_tex.get_size()
	draw_texture(sprite_tex, Vector2(-floorf(sz.x / 2.0), -sz.y), _sprite_tint())

## Cor aplicada no sprite (ex.: chefe vermelho de raiva).
func _sprite_tint() -> Color:
	return Color.WHITE

## Desenho que não espelha com o boneco (mira, linhas de aviso...).
func _draw_overlay() -> void:
	pass

## Redemoinho de folhas antes do inimigo aparecer (aviso pro jogador).
func _draw_spawn() -> void:
	var t := 1.0 - _spawn_t / SPAWN_TIME
	var rad := lerpf(22.0, 4.0, t) * body_scale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, rad, 0.0, TAU, 20, Color(1, 0.35, 0.3, 0.4 + t * 0.5), 2.0)
	draw_set_transform(Vector2.ZERO)
	for i in 6:
		var a := anim_t * 7.0 + i * TAU / 6.0
		var p := Vector2(cos(a) * rad, sin(a) * rad * 0.5 - 6.0 - t * 10.0)
		draw_rect(Rect2(p.round() - Vector2(2, 2), Vector2(4, 5)), OUTLINE)
		draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 3)), PAPER)
	if int(anim_t * 10.0) % 2 == 0:
		Fx.text(self, Vector2(-2, -26), "!", Color("ff5a4a"), 14)

func _draw_elite_bar() -> void:
	var w := 34.0
	var y := -(head_y + 12.0) * body_scale
	draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 5), OUTLINE)
	draw_rect(Rect2(-w / 2, y, w * float(hp) / max_hp, 3), Color("d94a4a"))
	Fx.text(self, Vector2(-w / 2 - 20, y - 3), display_name, Color("ffd966"), 8, w + 40, HORIZONTAL_ALIGNMENT_CENTER)

func is_moving() -> bool:
	return velocity.length() > 6.0

## --- pincéis em unidades de arte (dentro de _draw_body) ---
func ob(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x - 0.5, y - 0.5, w + 1, h + 1), Fx.OUTLINE) # contorno fino (1px)

func fb(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

## Bloco com contorno, luz em cima e sombra embaixo.
func bb(x: float, y: float, w: float, h: float, c: Color) -> void:
	ob(x, y, w, h)
	fb(x, y, w, h, c)
	if h >= 2:
		fb(x, y, w, 1, c.lightened(0.18))
	if h >= 3:
		fb(x, y + h - 1, w, 1, c.darkened(0.3))

## Bonequinho chibi (mesmo molde do estudante): cabeça grande, corpo compacto,
## olhando pra direita (o _draw espelha). ~14 unidades de altura = 28px.
## Retorna o balanço vertical (passo/respiração) pra desenhar acessórios junto.
func draw_person(outfit: Color, pants: Color, hair: Color, skin: Color = SKIN) -> float:
	var step := 0
	var bob := 0.0
	if is_moving():
		step = 1 if int(anim_t * 8.0) % 2 == 0 else -1
	elif fmod(anim_t, 1.3) < 0.65:
		bob = 1.0 # respira
	var ll := 1.0 if step == 1 else 0.0
	var lr := 1.0 if step == -1 else 0.0
	var b := bob
	# contornos primeiro (as peças grudam)
	ob(-3, -2 - ll, 2, 2)
	ob(1, -2 - lr, 2, 2)
	ob(-3, -7 + b, 6, 5)
	ob(-4, -14 + b, 8, 7)
	# pernas
	fb(-3, -2 - ll, 2, 2, pants)
	fb(1, -2 - lr, 2, 2, pants)
	# corpo
	fb(-3, -7 + b, 6, 5, outfit)
	fb(-3, -7 + b, 6, 1, outfit.lightened(0.18))
	fb(2, -6 + b, 1, 4, outfit.darkened(0.28))
	fb(-3, -3 + b, 1, 1, skin)
	# cabeça: rosto de lado com cabelo atrás/em cima
	fb(-4, -14 + b, 8, 7, skin)
	fb(-4, -8 + b, 8, 1, skin.darkened(0.15))
	fb(-4, -14 + b, 8, 2, hair)
	fb(-4, -12 + b, 3, 3, hair)
	fb(-3, -14 + b, 4, 1, hair.lightened(0.2))
	fb(2, -11 + b, 1, 1, Fx.OUTLINE) # olho
	return bob

## Braço/mão da frente segurando algo (raise = levanta, em unidades).
func draw_front_arm(outfit: Color, bob: float, raise: float = 0.0, skin: Color = SKIN) -> void:
	var y := -6 + bob - raise
	ob(2, y, 2, 3)
	fb(2, y, 2, 2, outfit.darkened(0.1))
	fb(2, y + 2, 2, 1, skin)
