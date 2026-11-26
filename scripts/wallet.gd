class_name Wallet
extends RefCounted
## Moedas da run. Caem automaticamente ao matar inimigos (pouquinho de cada vez,
## pra ir juntando) e são gastas na lojinha da tia (uma por andar).
## Passam de andar; zeram quando o estudante reprova ou começa run nova.

## Quanto cada tipo de inimigo dá.
const PER_ENEMY := 1
const PER_ELITE := 4
const PER_BOSS := 12

static var coins := 0

static func reset() -> void:
	coins = 0

static func add(ctx: Node, n: int) -> void:
	coins += n
	if ctx and ctx.is_inside_tree():
		ctx.get_tree().call_group("hud", "refresh_coins", true)

static func can_pay(n: int) -> bool:
	return coins >= n

static func spend(ctx: Node, n: int) -> bool:
	if coins < n:
		return false
	coins -= n
	if ctx and ctx.is_inside_tree():
		ctx.get_tree().call_group("hud", "refresh_coins", false)
	return true

## Moedinha de pixel art (8x8 em unidades de tela * s). Origem no centro.
static func draw_coin(ci: CanvasItem, c: Vector2, s: float = 1.0, shine: bool = true) -> void:
	var r := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		ci.draw_rect(Rect2(c + Vector2(x, y) * s, Vector2(w, h) * s), col)
	r.call(-3, -4, 6, 8, Fx.OUTLINE)
	r.call(-4, -3, 8, 6, Fx.OUTLINE)
	r.call(-3, -3, 6, 6, Color("ffd23f"))
	r.call(-2, -3, 4, 1, Color("ffe98a"))
	r.call(1, -2, 2, 5, Color("c8962a"))
	r.call(-1, -2, 1, 4, Color("c8962a"))
	if shine:
		r.call(-2, -2, 1, 1, Color.WHITE)
