extends Node2D
## Área inicial ("frente da faculdade"): sala com objetos de cenário e o ônibus.
## Entrar no ônibus começa a run.
## Estilo 3/4: a parede de cima mostra a face frontal; laterais e de baixo só o topo escuro.

const FLOOR_TEX := preload("res://assets/tilesets/clean/outdoor.png")
const WALL_TEX := preload("res://assets/tilesets/clean/wall.png")
const PROP := preload("res://scripts/prop.gd")
const RUN_SCENE := "res://scenes/floor.tscn" # 1º andar: entrada da faculdade

const ROOM := Rect2(24, 112, 912, 408)  # área de chão andável (maior que a tela: a câmera segue o jogador)
const WALL_FACE_H := 96.0              # fachada alta do prédio (2 tiles de parede de 48)
const CAP := 8.0                       # espessura do topo escuro das paredes
const CAP_COLOR := Color("150b1f")
const ROAD := Rect2(24, 144, 912, 64)  # rua onde o ônibus para

# Objetos de cenário (tipos de prop.gd) e a posição da base (onde encosta no chão).
const PROPS := [
	["arvore", Vector2(100, 300)],
	["arvore", Vector2(860, 300)],
	["arvore", Vector2(80, 470)],
	["arvore", Vector2(880, 470)],
	["poste", Vector2(300, 238)],
	["poste", Vector2(660, 238)],
	["lixeira", Vector2(700, 242)],
	["mesa_piquenique", Vector2(260, 360)],
	["mesa_piquenique", Vector2(700, 360)],
	["banco", Vector2(240, 470)],
	["banco", Vector2(720, 470)],
	["vaso", Vector2(400, 244)],
	["vaso", Vector2(560, 244)],
]
const FENCE_Y := 505.0     # cerca embaixo, com uma abertura no meio
const FENCE_GAP := 96.0

@onready var player: CharacterBody2D = $Entities/Player

func _ready() -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = int(ROOM.position.x - CAP - 16)
	cam.limit_top = int(ROOM.position.y - WALL_FACE_H - CAP - 16)
	cam.limit_right = int(ROOM.end.x + CAP + 16)
	cam.limit_bottom = int(ROOM.end.y + CAP + 16)
	cam.reset_smoothing()
	player.can_shoot = false # arma só dentro da faculdade
	player.health_changed.connect($HUD/HealthBar.set_health)
	$HUD/HealthBar.set_health(player.hp, player.max_hp)
	$Entities/Bus.boarded.connect(_on_bus_boarded)
	$Entities/Bus.position = Vector2(480, 190) # na rua
	Fx.setup_lighting(self, player, Color(0.55, 0.55, 0.72)) # noite

	_add_background()
	var floor_spr := Fx.tiled(self, FLOOR_TEX, ROOM)
	floor_spr.z_index = -8
	var wall_spr := Fx.tiled(self, WALL_TEX, Rect2(ROOM.position.x, ROOM.position.y - WALL_FACE_H, ROOM.size.x, WALL_FACE_H))
	wall_spr.z_index = -7
	var r := ROOM
	# Colisões: a de cima cobre a face da parede, as outras ficam no topo escuro.
	_add_wall(Rect2(r.position.x - CAP, r.position.y - WALL_FACE_H - CAP, r.size.x + CAP * 2, WALL_FACE_H + CAP))
	_add_wall(Rect2(r.position.x - CAP, r.end.y, r.size.x + CAP * 2, CAP))
	_add_wall(Rect2(r.position.x - CAP, r.position.y - WALL_FACE_H, CAP, r.size.y + WALL_FACE_H))
	_add_wall(Rect2(r.end.x, r.position.y - WALL_FACE_H, CAP, r.size.y + WALL_FACE_H))

	for p in PROPS:
		var prop: StaticBody2D = PROP.new()
		prop.kind = p[0]
		prop.position = p[1]
		$Entities.add_child(prop)
	_add_scenery()
	var mid := ROOM.get_center().x
	_add_fence(ROOM.position.x, mid - FENCE_GAP / 2.0)
	_add_fence(mid + FENCE_GAP / 2.0, ROOM.end.x)

func _add_fence(x0: float, x1: float) -> void:
	# Grade de metal escura, desenhada em pixel grosso.
	var body := StaticBody2D.new()
	body.position = Vector2(x0, FENCE_Y)
	var w := x1 - x0
	var art := Node2D.new()
	art.draw.connect(func():
		var c := Color("3e3a4e")
		var hl := Color("5c5670")
		art.draw_rect(Rect2(0, -26, w, 4), Fx.OUTLINE)
		art.draw_rect(Rect2(0, -24, w, 2), hl)
		art.draw_rect(Rect2(0, -10, w, 4), Fx.OUTLINE)
		art.draw_rect(Rect2(0, -8, w, 2), c)
		var x := 2.0
		while x < w - 2:
			art.draw_rect(Rect2(x - 2, -30, 6, 30), Fx.OUTLINE)
			art.draw_rect(Rect2(x, -28, 2, 28), c)
			art.draw_rect(Rect2(x, -30, 2, 2), hl)
			x += 12.0)
	body.add_child(art)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 6)
	col.shape = rect
	col.position = Vector2(w / 2.0, -3)
	body.add_child(col)
	$Entities.add_child(body)

## Rua, fachada com janelas acesas e placa da faculdade (tudo à noite).
func _add_scenery() -> void:
	var deco := Node2D.new()
	deco.z_index = -5
	deco.draw.connect(func():
		# rua de asfalto com faixa amarela tracejada e meio-fio
		deco.draw_rect(ROAD, Color("1d1c26"))
		deco.draw_rect(Rect2(ROAD.position.x, ROAD.end.y, ROAD.size.x, 4), Color("4a4458"))
		deco.draw_rect(Rect2(ROAD.position.x, ROAD.position.y - 4, ROAD.size.x, 4), Color("4a4458"))
		var x := ROAD.position.x + 8
		while x < ROAD.end.x:
			deco.draw_rect(Rect2(x, ROAD.get_center().y - 2, 16, 4), Color("c8a040"))
			x += 40)
	add_child(deco)
	var facade := Node2D.new()
	facade.z_index = -6
	facade.draw.connect(func():
		var top := ROOM.position.y - WALL_FACE_H
		# janelas acesas (algumas apagadas) na fachada
		var i := 0
		var x := ROOM.position.x + 40
		while x < ROOM.end.x - 40:
			var lit := (i * 7) % 5 != 0
			for wy in [top + 10, top + 52]:
				var lit2 := lit if wy == top + 10 else (i * 3) % 4 != 0
				var win := Rect2(x, wy, 24, 22)
				facade.draw_rect(win.grow(2), Fx.OUTLINE)
				facade.draw_rect(win, Color("f0c878") if lit2 else Color("2a2440"))
				if lit2:
					facade.draw_rect(Rect2(win.position.x, win.position.y, 24, 2), Color("fce6bd"))
					facade.draw_rect(Rect2(win.position.x + 11, win.position.y, 2, 22), Color("c89a58"))
				facade.draw_rect(Rect2(win.position.x - 2, win.end.y + 2, 28, 2), Color("56476b")) # peitoril
			x += 64
			i += 1
		# placa da faculdade no meio
		var c := ROOM.get_center().x
		var sign := Rect2(c - 60, top + 34, 120, 16)
		facade.draw_rect(sign.grow(2), Fx.OUTLINE)
		facade.draw_rect(sign, Color("2a1f38"))
		Fx.text(facade, Vector2(sign.position.x, sign.position.y + 13), "FACULDADE IFERNO", Color("ffd966"), 11, sign.size.x, HORIZONTAL_ALIGNMENT_CENTER))
	add_child(facade)
	# luz quente saindo das janelas
	var x2 := ROOM.position.x + 52
	var j := 0
	while x2 < ROOM.end.x - 40:
		if (j * 7) % 5 != 0:
			Fx.glow(self, Vector2(x2, ROOM.position.y - WALL_FACE_H + 22), 22.0, Color("ffb060"), 0.35)
			Fx.glow(self, Vector2(x2, ROOM.position.y - WALL_FACE_H + 64), 22.0, Color("ffb060"), 0.3)
		x2 += 64
		j += 1

func _on_bus_boarded(_who: Node2D) -> void:
	# Jogador some dentro do ônibus, ônibus arranca, tela escurece e começa a run.
	FloorLevel.floor_num = 1
	FloorLevel.carry_hp = -1
	Upgrades.reset()
	Wallet.reset()
	player.hide()
	player.set_physics_process(false)
	player.set_process(false)
	player.get_node("Camera2D").reparent(self) # câmera fica parada vendo o ônibus sair
	# fom-fom + motor arrancando
	Sfx.play(self, "door", 0.0)
	get_tree().create_timer(0.15).timeout.connect(func(): Sfx.play(self, "horn", 0.0))
	get_tree().create_timer(0.42).timeout.connect(func(): Sfx.play(self, "horn", 0.0))
	get_tree().create_timer(0.55).timeout.connect(func(): Sfx.play(self, "engine", 0.0))
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property($HUD/Fade, "color:a", 1.0, 0.8)
	tw.tween_callback(func(): get_tree().change_scene_to_file(RUN_SCENE))

func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.get_center()
	body.add_child(shape)
	add_child(body)

## Fundo + topo escuro das paredes, atrás de tudo.
func _add_background() -> void:
	var bg := Node2D.new()
	bg.z_index = -10
	bg.draw.connect(func():
		bg.draw_rect(ROOM.grow(200), Fx.BG)
		var outer := Rect2(ROOM.position.x - CAP, ROOM.position.y - WALL_FACE_H - CAP,
			ROOM.size.x + CAP * 2, ROOM.size.y + WALL_FACE_H + CAP * 2)
		bg.draw_rect(outer, CAP_COLOR)
		bg.draw_rect(outer, Fx.CAP_RIM, false, 2.0))
	add_child(bg)
