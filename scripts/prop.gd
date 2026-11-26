extends StaticBody2D
## Móvel/objeto de cenário, desenhado em _draw() no estilo "clean escuro":
## pixel GROSSO (tudo é desenhado em unidades de arte e ampliado 2x), poucos tons,
## contorno quase preto, luz em cima e sombra embaixo, e brilho em quem acende.
## A origem é o meio da base (onde encosta no chão); só uma faixa na base é sólida,
## assim o jogador passa "atrás" da parte de cima e o móvel serve de cobertura.

const A := 2.0 # 1 unidade de arte = 2 px na tela (Fx.ART)
const OUT := Color("0b0612")
const WOOD := Color("7a4038")
const WOOD_L := Color("96543f")
const WOOD_D := Color("5a2e2c")
const METAL := Color("5c5670")
const METAL_L := Color("7a7490")
const METAL_D := Color("3e3a4e")
const PAPER := Color("e0d8d0")
const PAPER_D := Color("b0a8b4")
const LEAF := Color("2f7a4a")
const LEAF_L := Color("4a9a5a")
const LEAF_D := Color("1f5a3a")
const POT := Color("4a3d5a")
const POT_L := Color("5e4f72")
const RED := Color("c0383a")
const RED_D := Color("8a2830")
const RED_L := Color("e0584a")
const CYAN := Color("6de2f1")
const WARM := Color("fce6bd")
const CLOTH := Color("7a3a52")
const CLOTH_L := Color("964a66")

## tamanho na tela (largura, altura) e faixa sólida (largura, altura) de cada tipo
## tamanho na tela (largura, altura) = tamanho do sprite, e faixa sólida (largura, altura)
## na base. Gerado a partir de assets/props/clean/ (tools/build_clean_props.py).
const KINDS := {
	"carteira": [Vector2(36, 36), Vector2(32, 12)],
	"mesa_prof": [Vector2(72, 43), Vector2(65, 14)],
	"estante": [Vector2(64, 79), Vector2(58, 22)],
	"bancada": [Vector2(87, 50), Vector2(78, 16)],
	"mesa_cantina": [Vector2(120, 44), Vector2(108, 14)],
	"sofa": [Vector2(76, 39), Vector2(68, 12)],
	"cafeteira": [Vector2(44, 52), Vector2(40, 17)],
	"vending": [Vector2(44, 76), Vector2(40, 22)],
	"copiadora": [Vector2(56, 56), Vector2(50, 18)],
	"pilha_papel": [Vector2(15, 16), Vector2(14, 6)],
	"balcao": [Vector2(127, 51), Vector2(114, 16)],
	"catraca": [Vector2(24, 40), Vector2(14, 8)],
	"vaso": [Vector2(28, 52), Vector2(14, 8)],
	"bebedouro": [Vector2(24, 44), Vector2(16, 8)],
	"armarios": [Vector2(79, 79), Vector2(71, 22)],
	"pc": [Vector2(48, 48), Vector2(43, 15)],
	"cabine": [Vector2(48, 78), Vector2(43, 22)],
	"pia": [Vector2(39, 44), Vector2(35, 14)],
	"pilar": [Vector2(40, 104), Vector2(32, 14)],
	"lixeira": [Vector2(22, 31), Vector2(16, 8)],
	"poltronas": [Vector2(111, 39), Vector2(100, 12)],
	"pulpito": [Vector2(44, 60), Vector2(40, 19)],
	"arvore": [Vector2(96, 127), Vector2(20, 10)],
	"poste": [Vector2(32, 127), Vector2(10, 6)],
	"banco": [Vector2(64, 36), Vector2(58, 12)],
	"mesa_piquenique": [Vector2(96, 52), Vector2(86, 17)],
}

var kind := "carteira"
var tex: Texture2D # sprite com cara de 3D (SpriteCook); se não tiver, desenha em código
var _t := 0.0
var _seed := 0

func _ready() -> void:
	_seed = absi(int(position.x * 7 + position.y * 13))
	_t = randf() * 5.0
	var spec: Array = KINDS[kind]
	var solid: Vector2 = spec[1]
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = solid
	col.shape = rect
	col.position = Vector2(0, -solid.y / 2.0)
	add_child(col)
	var path := "res://assets/props/clean/%s.png" % kind
	if ResourceLoader.exists(path):
		tex = load(path)
	set_process(tex == null and kind in ["bancada", "cafeteira", "vending", "copiadora", "pc", "catraca"])
	_add_glows()

## Retângulo que ocupa visualmente (pra não nascer inimigo em cima).
static func footprint(k: String, base: Vector2) -> Rect2:
	var s: Vector2 = KINDS[k][0]
	return Rect2(base - Vector2(s.x / 2.0, s.y), s)

func _add_glows() -> void:
	match kind:
		"vending": Fx.glow(self, Vector2(0, -50), 44.0, Color("ff9a6a"), 0.8)
		"pc": Fx.glow(self, Vector2(0, -34), 22.0, CYAN, 0.55)
		"cafeteira": Fx.glow(self, Vector2(2, -38), 16.0, Color("ff7a5a"), 0.45)
		"copiadora": Fx.glow(self, Vector2(10, -40), 12.0, Color("6aff9a"), 0.45)
		"poste": Fx.glow(self, Vector2(0, -116), 60.0, Color("ffb060"), 0.4)
		"bancada": Fx.glow(self, Vector2(0, -40), 30.0, Color("9a6aff"), 0.45)
		"balcao": Fx.glow(self, Vector2(-30, -42), 18.0, CYAN, 0.5)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

# ---------------------------------------------------------------- pincéis (em unidades de arte)

## Bloco com volume (2.5D): contorno fino de 1px, topo iluminado, lado direito
## na sombra, quina esquerda pegando luz e base escura (luz vem de cima/esquerda).
func _b(x: float, y: float, w: float, h: float, c: Color, light: bool = true) -> void:
	draw_rect(Rect2(x - 0.5, y - 0.5, w + 1, h + 1), OUT)
	draw_rect(Rect2(x, y, w, h), c)
	if light and h >= 2:
		draw_rect(Rect2(x, y, w, 1), c.lightened(0.22))
		draw_rect(Rect2(x, y + 1, w, 0.5), c.lightened(0.1))
	if w >= 3 and h >= 2:
		draw_rect(Rect2(x + w - 1, y + (1 if light else 0), 1, h - (1 if light else 0)), c.darkened(0.25))
		draw_rect(Rect2(x, y, 0.5, h), c.lightened(0.12))
	if h >= 3:
		draw_rect(Rect2(x, y + h - 1, w, 1), c.darkened(0.35))

## Retângulo chapado (sem contorno).
func _f(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)

## Sombra no chão: escurecido na base + sombra projetada pra direita/baixo
## (proporcional à altura do objeto), que é o que dá a sensação de volume.
func _shadow(w: float, h: float = 8.0) -> void:
	var len := clampf(h * 0.35, 2.0, 9.0)
	var x0 := -w / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(x0 + 1, -1), Vector2(x0 + w, -1),
		Vector2(x0 + w + len, len * 0.45), Vector2(x0 + 1 + len, len * 0.45)]), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(x0, -1.5, w, 2), Color(0, 0, 0, 0.35))

func _draw() -> void:
	if tex:
		# sprite 3D: sombra projetada no chão + imagem com a base no ponto de origem
		var sz := tex.get_size()
		# sombra de contato colada na base (+ um pouco pra direita/baixo, luz vem de cima/esquerda)
		var solid: Vector2 = KINDS[kind][1]
		var base_w := maxf(solid.x, sz.x * 0.6)
		draw_rect(Rect2(-base_w / 2.0 + 2, -solid.y * 0.6, base_w, solid.y * 0.6 + 3), Color(0, 0, 0, 0.22))
		Fx.contact_shadow(self, Vector2(2, 1), base_w * 0.58, 1.1)
		draw_texture(tex, Vector2(-floorf(sz.x / 2.0), -sz.y + 1))
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(A, A))
	var s: Vector2 = KINDS[kind][0] / A
	_shadow(s.x, s.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var blink := int(_t * 3.0) % 2 == 0
	match kind:
		"carteira":
			_b(-4, -8, 9, 3, WOOD_L)
			_f(-4, -5, 1, 5, METAL_D)
			_f(4, -5, 1, 5, METAL_D)
			if rng.randf() < 0.6:
				_f(rng.randi_range(-3, 1), -8, 3, 1, PAPER)
		"mesa_prof":
			_b(-11, -11, 23, 3, WOOD_L)
			_b(-11, -8, 23, 8, WOOD, false)
			_f(-9, -6, 19, 1, WOOD_D)
			_b(-8, -13, 5, 2, PAPER)   # provas
			_b(6, -13, 2, 2, RED)      # maçã
		"estante":
			_b(-10, -19, 20, 19, WOOD_D, false)
			for shelf in 3:
				var y := -17 + shelf * 6
				var x := -8
				while x < 8:
					var w := rng.randi_range(1, 2)
					var col := [RED, Color("3a6a9a"), Color("4a8a5a"), Color("c8963a"), CLOTH][rng.randi() % 5] as Color
					_f(x, y + 5 - rng.randi_range(3, 4), w, 5, col)
					x += w + (1 if rng.randf() < 0.25 else 0)
				_f(-9, y + 5, 18, 1, WOOD)
		"bancada":
			_b(-13, -11, 26, 3, Color("8a8498"))
			_b(-13, -8, 26, 8, METAL, false)
			_f(0, -7, 1, 6, METAL_D)
			var cols := [Color("4ad18a"), Color("9a6aff"), Color("4ab3ff")]
			for i in 3:
				var x := -9 + i * 7
				var c: Color = cols[(i + _seed) % 3]
				_b(x, -15, 3, 4, c)
				_f(x + 1, -16, 1, 1, PAPER_D)
				if int(_t * 4.0 + i) % 3 == 0:
					_f(x + 1, -18, 1, 1, Color(1, 1, 1, 0.8)) # bolha
		"mesa_cantina":
			_b(-16, -9, 32, 3, Color("8a7a88"))
			_f(-15, -6, 1, 6, METAL_D)
			_f(14, -6, 1, 6, METAL_D)
			for i in 2:
				var x := -12 + i * 15
				_b(x, -10, 8, 2, METAL_L)
				_f(x + 1, -10, 2, 1, PAPER)
				_f(x + 3, -10, 2, 1, Color("6a3a20"))
				_f(x + 5, -10, 2, 1, LEAF_L)
		"sofa":
			_b(-11, -10, 22, 4, CLOTH)
			_b(-11, -6, 22, 6, CLOTH_L)
			_b(-12, -8, 2, 8, CLOTH)
			_b(10, -8, 2, 8, CLOTH)
		"cafeteira":
			_b(-5, -6, 11, 6, WOOD)
			_b(-3, -13, 6, 7, METAL_D)
			_f(-2, -11, 4, 2, Color("3a2018"))
			_f(1, -12, 1, 1, RED_L if blink else RED_D)
			if int(_t * 2.0) % 2 == 0:
				_f(-1, -15, 1, 1, Color(1, 1, 1, 0.5))
				_f(0, -16, 1, 1, Color(1, 1, 1, 0.35))
		"vending":
			_b(-6, -20, 12, 20, RED)
			_f(-6, -20, 12, 1, RED_L)
			_f(-5, -18, 7, 12, Color("101830"))         # vidro
			var can := [Color("4ab3ff"), RED_L, Color("4ad18a"), Color("ffb04a")]
			for row in 3:
				for c in 2:
					_f(-4 + c * 3, -17 + row * 4, 2, 2, can[(row + c) % 4])
			_f(3, -17, 2, 3, WARM)   # copinho iluminado
			_f(3, -12, 2, 1, OUT)
			_f(3, -10, 2, 1, OUT)
			_f(-4, -4, 7, 2, OUT)                       # saída da bebida
		"copiadora":
			_b(-8, -11, 16, 11, Color("8a8498"))
			_b(-8, -14, 16, 3, Color("a8a2b4"))
			_f(-7, -6, 14, 1, METAL_D)
			_f(5, -10, 1, 1, Color("6aff9a") if blink else Color("1f5a3a"))
			var out := fmod(_t * 3.0, 4.0)
			_f(-10 - out, -8, 3, 1, PAPER)
		"pilha_papel":
			for i in 3:
				_b(-3 + (i % 2), -2 - i * 2, 6, 1, PAPER, false)
		"balcao":
			_b(-21, -12, 42, 3, WOOD_L)
			_b(-21, -9, 42, 9, WOOD, false)
			_f(-19, -7, 38, 1, WOOD_D)
			_b(8, -17, 7, 5, METAL_D)                  # monitor
			_f(9, -16, 5, 3, CYAN)
			_b(-15, -14, 4, 2, PAPER)
		"catraca":
			_b(-2, -10, 5, 10, METAL)
			_f(-1, -9, 3, 1, Color("4ad18a") if blink else Color("2a8a4a"))
			_b(3, -6, 3, 1, METAL_L)
		"vaso":
			# folhas pontudas (igual à referência) + vaso arroxeado
			_f(-4, -12, 8, 5, OUT)
			_f(-3, -13, 6, 1, OUT)
			_f(-3, -12, 6, 4, LEAF)
			_f(-2, -13, 1, 1, LEAF_L)
			_f(1, -13, 1, 1, LEAF_L)
			_f(-4, -9, 2, 2, LEAF_D)
			_f(2, -10, 2, 2, LEAF_D)
			_f(-1, -11, 2, 1, LEAF_L)
			_b(-3, -6, 6, 6, POT)
			_f(-3, -6, 6, 1, POT_L)
		"bebedouro":
			_b(-3, -11, 6, 11, Color("8a8498"))
			_f(-2, -10, 4, 2, METAL_D)
			_f(0, -12, 1, 1, CYAN)
		"armarios":
			for i in 4:
				var x := -12 + i * 6
				var c := Color("3e4a78") if i % 2 == 0 else Color("36406a")
				_b(x, -20, 5, 20, c)
				_f(x + 1, -18, 3, 1, c.darkened(0.35))
				_f(x + 1, -16, 3, 1, c.darkened(0.35))
				_f(x + 4, -10, 1, 2, METAL_L)
		"pc":
			_b(-6, -7, 13, 3, METAL)
			_f(-6, -4, 1, 4, METAL_D)
			_f(6, -4, 1, 4, METAL_D)
			_b(-4, -13, 8, 6, Color("1a1a28"))
			_f(-3, -12, 6, 4, Color("12303a"))
			for l in 2:
				var lw := 2 + (_seed + l * 3 + int(_t * 2.0)) % 4
				_f(-3, -12 + l * 2, lw, 1, CYAN)
		"cabine":
			_b(-7, -21, 14, 21, Color("3a5a6a"))
			_f(-6, -19, 12, 18, Color("324e5e"))
			if _seed % 3 == 0:
				_f(-6, -19, 5, 18, OUT)                 # porta aberta
			else:
				_f(3, -11, 2, 1, RED)                   # ocupado
		"pia":
			_b(-5, -7, 10, 3, Color("a8a2b4"))
			_f(-3, -7, 6, 1, METAL_D)
			_b(-1, -9, 1, 2, METAL_L)
			_b(-2, -4, 4, 4, Color("8a8498"))
			_b(-4, -12, 8, 3, Color("4a7a9a"))           # espelho
		"pilar":
			_b(-5, -26, 10, 26, Color("4a3d5a"))
			_f(-5, -26, 10, 2, Color("5e4f72"))
			_f(2, -24, 2, 22, Color("3e3250"))
		"lixeira":
			_b(-3, -7, 6, 7, Color("2f6a4a"))
			_f(-1, -8, 2, 1, PAPER)
		"poltronas":
			for i in 4:
				var x := -14 + i * 7
				_b(x, -10, 6, 4, CLOTH)
				_b(x, -6, 6, 3, CLOTH_L)
			_f(-14, -2, 28, 2, METAL_D)
		"pulpito":
			_b(-6, -12, 13, 3, WOOD_L)
			_b(-5, -9, 11, 9, WOOD, false)
			_f(-4, -7, 9, 1, WOOD_D)
			_b(-1, -16, 1, 4, METAL_D)                 # microfone
			_b(-2, -17, 3, 1, OUT)
		"arvore":
			_b(-2, -12, 4, 12, WOOD_D)
			draw_circle(Vector2(0, -22), 12.0, OUT)
			draw_circle(Vector2(0, -22), 11.0, LEAF_D)
			draw_circle(Vector2(-2, -24), 8.0, LEAF)
			draw_circle(Vector2(-4, -27), 3.0, LEAF_L)
			draw_circle(Vector2(5, -18), 3.0, LEAF)
		"poste":
			_b(-1, -28, 2, 28, METAL_D)
			_b(-3, -31, 6, 3, METAL)
			_f(-2, -28, 4, 1, WARM)
			_b(-2, -1, 4, 1, METAL_D)
		"banco":
			_b(-9, -8, 18, 2, WOOD_L)
			_b(-9, -5, 18, 2, WOOD)
			_f(-8, -3, 1, 3, METAL_D)
			_f(7, -3, 1, 3, METAL_D)
		"mesa_piquenique":
			_b(-14, -13, 28, 4, WOOD_L)
			_f(-12, -9, 2, 5, WOOD_D)
			_f(10, -9, 2, 5, WOOD_D)
			_b(-14, -4, 28, 2, WOOD)
	draw_set_transform(Vector2.ZERO)
