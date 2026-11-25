extends StaticBody2D
## Móvel/objeto de cenário das salas, desenhado em _draw() (placeholder até ter sprite).
## A origem é o meio da base (onde encosta no chão); só uma faixa na base é sólida,
## assim o jogador passa "atrás" da parte de cima e serve de cobertura contra tiros de papel.

const OUTLINE := Color("1a1020")
const WOOD := Color("b5835a")
const WOOD_LIGHT := Color("d4a373")
const WOOD_DARK := Color("7a5236")
const METAL := Color("9aa0ae")

## tamanho visual (largura, altura) e faixa sólida (largura, altura) de cada tipo
const KINDS := {
	"carteira": [Vector2(18, 16), Vector2(18, 6)],
	"mesa_prof": [Vector2(46, 22), Vector2(46, 10)],
	"estante": [Vector2(40, 38), Vector2(40, 10)],
	"bancada": [Vector2(52, 22), Vector2(52, 10)],
	"mesa_cantina": [Vector2(64, 18), Vector2(64, 8)],
	"sofa": [Vector2(44, 20), Vector2(44, 10)],
	"cafeteira": [Vector2(22, 26), Vector2(20, 8)],
	"vending": [Vector2(24, 40), Vector2(24, 10)],
	"copiadora": [Vector2(32, 28), Vector2(32, 10)],
	"pilha_papel": [Vector2(14, 14), Vector2(14, 6)],
	"balcao": [Vector2(84, 24), Vector2(84, 10)],
	"catraca": [Vector2(12, 20), Vector2(10, 6)],
	"vaso": [Vector2(14, 26), Vector2(10, 6)],
	"bebedouro": [Vector2(12, 22), Vector2(12, 6)],
	"armarios": [Vector2(48, 40), Vector2(48, 8)],
}

var kind := "carteira"
var _t := 0.0
var _seed := 0
var _animated := false

func _ready() -> void:
	_seed = int(position.x * 7 + position.y * 13)
	_t = randf() * 5.0
	var spec: Array = KINDS[kind]
	var solid: Vector2 = spec[1]
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = solid
	col.shape = rect
	col.position = Vector2(0, -solid.y / 2.0)
	add_child(col)
	_animated = kind in ["bancada", "cafeteira", "vending", "copiadora"]
	set_process(_animated)

## Retângulo que ocupa visualmente (pra não nascer inimigo em cima).
static func footprint(k: String, base: Vector2) -> Rect2:
	var s: Vector2 = KINDS[k][0]
	return Rect2(base - Vector2(s.x / 2.0, s.y), s)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _o(r: Rect2, c: Color) -> void:
	draw_rect(r.grow(1.0), OUTLINE)
	draw_rect(r, c)

func _draw() -> void:
	var s: Vector2 = KINDS[kind][0]
	# sombra
	draw_rect(Rect2(-s.x / 2.0 + 1, -3, s.x, 4), Color(0, 0, 0, 0.25))
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	match kind:
		"carteira":
			_o(Rect2(-9, -16, 18, 6), WOOD_LIGHT)
			draw_rect(Rect2(-9, -11, 18, 1), WOOD)
			_o(Rect2(-8, -9, 2, 9), METAL)
			_o(Rect2(6, -9, 2, 9), METAL)
			if rng.randf() < 0.6:
				draw_rect(Rect2(rng.randi_range(-7, 2), -15, 5, 3), Color("f4efe2"))
			if rng.randf() < 0.3:
				draw_rect(Rect2(rng.randi_range(-6, 4), -15, 1, 4), Color("3f6fd1")) # caneta
		"mesa_prof":
			_o(Rect2(-23, -22, 46, 8), WOOD_LIGHT)
			_o(Rect2(-23, -14, 46, 14), WOOD)
			draw_rect(Rect2(-21, -12, 42, 1), WOOD_DARK)
			_o(Rect2(-16, -26, 10, 4), Color("f4efe2")) # provas
			_o(Rect2(10, -26, 4, 4), Color("d93a3a"))   # maçã
			draw_rect(Rect2(12, -28, 1, 2), Color("3f8a3a"))
		"estante":
			_o(Rect2(-20, -38, 40, 38), WOOD_DARK)
			for shelf in 3:
				var y := -35 + shelf * 12
				var x := -18
				while x < 17:
					var w := rng.randi_range(2, 4)
					var h := rng.randi_range(7, 10)
					var col := Color.from_hsv(rng.randf(), 0.55, rng.randf_range(0.55, 0.85))
					draw_rect(Rect2(x, y + 10 - h, w, h), col)
					x += w + (1 if rng.randf() < 0.3 else 0)
				draw_rect(Rect2(-19, y + 10, 38, 2), WOOD)
		"bancada":
			_o(Rect2(-26, -22, 52, 6), Color("e8e8f0"))
			_o(Rect2(-26, -16, 52, 16), Color("6a8aa8"))
			draw_rect(Rect2(-24, -14, 23, 12), Color("5a7a98"))
			draw_rect(Rect2(1, -14, 23, 12), Color("5a7a98"))
			# frascos borbulhando
			var cols := [Color("3fd17a"), Color("b04fff"), Color("4fb3ff")]
			for i in 3:
				var x := -18 + i * 14
				var c: Color = cols[(i + _seed) % 3]
				_o(Rect2(x, -30, 6, 8), Color(c, 0.9))
				draw_rect(Rect2(x + 2, -33, 2, 3), Color("d8e8f0"))
				var by := -26.0 - fmod(_t * 12.0 + i * 3.0, 10.0)
				draw_rect(Rect2(x + 2 + (i % 2), by, 1, 1), Color(1, 1, 1, 0.8))
		"mesa_cantina":
			_o(Rect2(-32, -18, 64, 8), Color("d8d0c0"))
			draw_rect(Rect2(-32, -11, 64, 1), Color("a8a090"))
			_o(Rect2(-30, -10, 2, 10), METAL)
			_o(Rect2(28, -10, 2, 10), METAL)
			# bandejas com PF (arroz, feijão, salada)
			for i in 2:
				var x := -24 + i * 30
				_o(Rect2(x, -20, 16, 6), Color("8a8a98"))
				draw_rect(Rect2(x + 1, -19, 5, 3), Color("f4efe2"))
				draw_rect(Rect2(x + 6, -19, 5, 3), Color("6a3a20"))
				draw_rect(Rect2(x + 11, -19, 4, 3), Color("4f9a3a"))
		"sofa":
			_o(Rect2(-22, -20, 44, 8), Color("8a3a3a"))
			_o(Rect2(-22, -12, 44, 12), Color("a84a4a"))
			_o(Rect2(-24, -16, 4, 16), Color("8a3a3a"))
			_o(Rect2(20, -16, 4, 16), Color("8a3a3a"))
			draw_rect(Rect2(-1, -11, 1, 10), Color("7a2a2a"))
		"cafeteira":
			_o(Rect2(-11, -12, 22, 12), WOOD)
			_o(Rect2(-6, -26, 12, 14), Color("3a3440"))
			draw_rect(Rect2(-4, -22, 8, 5), Color("5a3420"))
			draw_rect(Rect2(3, -25, 2, 2), Color("ff4a4a") if int(_t * 2.0) % 2 == 0 else Color("6a2a2a"))
			for i in 2:
				var y := -28.0 - fmod(_t * 8.0 + i * 5.0, 10.0)
				draw_rect(Rect2(-2 + i * 3, y, 1, 2), Color(1, 1, 1, 0.5))
		"vending":
			_o(Rect2(-12, -40, 24, 40), Color("c0392b"))
			_o(Rect2(-9, -36, 13, 26), Color("1a2a40"))
			for row in 4:
				for c in 3:
					var col := Color.from_hsv(fmod(row * 0.27 + c * 0.13, 1.0), 0.7, 0.9)
					draw_rect(Rect2(-8 + c * 4, -35 + row * 6, 3, 4), col)
			var glow := 0.6 + 0.4 * float(int(_t * 3.0) % 7 != 0)
			draw_rect(Rect2(-9, -36, 13, 1), Color(0.6, 0.9, 1.0, glow))
			draw_rect(Rect2(6, -30, 4, 6), Color("1a1020"))
			draw_rect(Rect2(-9, -8, 13, 4), Color("1a1020"))
			Fx.text(self, Vector2(-11, -38), "COLA", Color("f4efe2"), 6)
		"copiadora":
			_o(Rect2(-16, -22, 32, 22), Color("c8c8d0"))
			_o(Rect2(-16, -28, 32, 6), Color("e8e8f0"))
			draw_rect(Rect2(-14, -12, 28, 1), Color("9a9aa8"))
			draw_rect(Rect2(10, -20, 3, 2), Color("3fd17a") if int(_t * 4.0) % 2 == 0 else Color("1f5a3a"))
			# folha saindo
			var out := fmod(_t * 6.0, 8.0)
			draw_rect(Rect2(-20 - out, -17, 8, 3), Color("f4efe2"))
		"pilha_papel":
			for i in 3:
				var off := rng.randi_range(-1, 1)
				_o(Rect2(-7 + off, -4 - i * 4, 14, 3), Color("f4efe2"))
				draw_rect(Rect2(-7 + off, -4 - i * 4 + 2, 14, 1), Color("b8b4c8"))
		"balcao":
			_o(Rect2(-42, -24, 84, 6), WOOD_LIGHT)
			_o(Rect2(-42, -18, 84, 18), WOOD)
			draw_rect(Rect2(-40, -15, 80, 2), WOOD_DARK)
			Fx.text(self, Vector2(-42, -5), "RECEPÇÃO", Color("f4e4c0"), 7, 84, HORIZONTAL_ALIGNMENT_CENTER)
			_o(Rect2(16, -34, 14, 10), Color("2a2a38")) # monitor
			draw_rect(Rect2(17, -33, 12, 7), Color("4fb3ff"))
			_o(Rect2(-30, -28, 8, 4), Color("f4efe2"))
		"catraca":
			_o(Rect2(-5, -20, 10, 20), METAL)
			draw_rect(Rect2(-4, -18, 8, 2), Color("3fd17a"))
			_o(Rect2(5, -12, 7, 2), Color("d8d8e0"))
		"vaso":
			var lc := Color("3f8a3a")
			draw_circle(Vector2(0, -18), 8.0, OUTLINE)
			draw_circle(Vector2(0, -18), 7.0, lc)
			draw_circle(Vector2(-3, -20), 3.0, lc.lightened(0.2))
			draw_circle(Vector2(3, -16), 2.0, lc.darkened(0.2))
			_o(Rect2(-5, -9, 10, 9), Color("b0603a"))
			draw_rect(Rect2(-5, -9, 10, 2), Color("c8784a"))
		"bebedouro":
			_o(Rect2(-6, -22, 12, 22), Color("d8d8e0"))
			draw_rect(Rect2(-5, -21, 10, 4), Color("9aa0ae"))
			draw_rect(Rect2(-1, -24, 2, 2), Color("7ec8e3"))
		"armarios":
			for i in 4:
				var x := -24 + i * 12
				var c := Color("5a7aa8") if i % 2 == 0 else Color("4a6a98")
				_o(Rect2(x, -40, 11, 40), c)
				for v in 3:
					draw_rect(Rect2(x + 3, -36 + v * 2, 5, 1), c.darkened(0.35))
				draw_rect(Rect2(x + 8, -20, 1, 3), Color("d8d8e0"))
