class_name Upgrades
extends RefCounted
## Upgrades da run (material escolar / vida de faculdade). Ficam guardados aqui
## (static) e passam de um andar pro outro; zeram quando o estudante reprova
## (morre) ou começa uma run nova no ônibus.
## A cada ROOMS_PER_PICK salas limpas (e sempre depois do chefe) aparece a
## escolha entre 3 (ver upgrade_pick.gd).

const ROOMS_PER_PICK := 2

## id -> categoria, nome, descrição, cor do ícone e máximo de vezes que pode pegar (0 = sem limite)
const DEFS := {
	"cafe": {"tag": "CONSUMÍVEL", "name": "CAFÉ DUPLO", "desc": "Cura 1 de vida e deixa\nmais rápido por 8s.", "color": Color("b5452f"), "max": 0},
	"calculadora": {"tag": "TIRO", "name": "CALCULADORA\nCIENTÍFICA", "desc": "Tiros atravessam\n+1 inimigo.", "color": Color("6a8ab0"), "max": 3},
	"grampeador": {"tag": "DANO", "name": "GRAMPEADOR", "desc": "+1 de dano, mas\natira 20% mais devagar.", "color": Color("d04040"), "max": 3},
	"mochila": {"tag": "DEFESA", "name": "MOCHILA PESADA", "desc": "+1 coração, mas\nanda 8% mais devagar.", "color": Color("4a7a4a"), "max": 3},
	"monitoria": {"tag": "MOBILIDADE", "name": "MONITORIA", "desc": "Espera do dodge\ncai pela metade.", "color": Color("e0b040"), "max": 2},
	"apostila": {"tag": "TIRO", "name": "APOSTILA", "desc": "+1 projétil por tiro\n(em leque).", "color": Color("e8e0d8"), "max": 3},
	"wifi": {"tag": "TIRO", "name": "WI-FI DA\nFACULDADE", "desc": "O sinal rebate: tiros\nricocheteiam +1 vez.", "color": Color("40b0d0"), "max": 3},
	"caneta": {"tag": "DANO", "name": "CANETA VERMELHA", "desc": "+15% de chance de\ncrítico (dano x2).", "color": Color("ff3a3a"), "max": 3},
	# Raros: só saem do baú da sala de prova surpresa.
	"energetico": {"tag": "RARO", "rare": true, "name": "ENERGÉTICO", "desc": "+25% tiros por seg.\n+10% velocidade.", "color": Color("7ad13a"), "max": 2},
	"bolsa": {"tag": "RARO", "rare": true, "name": "BOLSA INTEGRAL", "desc": "+2 corações e\ncura a vida toda.", "color": Color("ffd23f"), "max": 1},
	"cola": {"tag": "RARO", "rare": true, "name": "COLA DA PROVA", "desc": "+25% de crítico e o\ncrítico vira dano x3.", "color": Color("ff8ad8"), "max": 1},
	"carteirinha": {"tag": "RARO", "rare": true, "name": "CARTEIRINHA\nDE MONITOR", "desc": "Cada dodge solta 8\ntiros em volta de você.", "color": Color("9a7aff"), "max": 1},
}

static var taken := {} # id -> quantas vezes pegou
static var rooms_since_pick := 0

static func reset() -> void:
	taken.clear()
	rooms_since_pick = 0

static func count(id: String) -> int:
	return int(taken.get(id, 0))

static func is_rare(id: String) -> bool:
	return DEFS[id].get("rare", false)

## Sorteia até n opções comuns que ainda podem ser pegas.
static func roll(n: int = 3) -> Array[String]:
	return _roll(n, false)

## Sorteia opções raras (baú). Se faltar raro, completa com comuns.
static func roll_rare(n: int = 3) -> Array[String]:
	var out := _roll(n, true)
	if out.size() < n:
		out.append_array(_roll(n - out.size(), false))
	return out

static func _roll(n: int, rare: bool) -> Array[String]:
	var pool: Array[String] = []
	for id: String in DEFS:
		var mx: int = DEFS[id]["max"]
		if is_rare(id) == rare and (mx == 0 or count(id) < mx):
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, n)

## Uma sala foi limpa: devolve true se é hora de escolher upgrade.
static func room_cleared(boss_room: bool) -> bool:
	rooms_since_pick += 1
	if boss_room or rooms_since_pick >= ROOMS_PER_PICK:
		rooms_since_pick = 0
		return true
	return false

## Aplica os upgrades guardados nos números base do jogador (chamado no _ready dele).
static func apply_stats(p: Node) -> void:
	p.max_hp = p.base_max_hp + 2 * count("mochila") + 4 * count("bolsa")
	p.speed = p.base_speed * pow(0.92, count("mochila")) * pow(1.1, count("energetico"))
	p.fire_rate = p.base_fire_rate * pow(1.2, count("grampeador")) * pow(0.8, count("energetico"))
	p.roll_cooldown = p.base_roll_cooldown * pow(0.5, count("monitoria"))
	p.bullet_damage = 1 + count("grampeador")
	p.bullet_pierce = count("calculadora")
	p.bullet_count = 1 + count("apostila")
	p.bullet_bounces = count("wifi")
	p.crit_chance = 0.15 * count("caneta") + 0.25 * count("cola")
	p.crit_mult = 3 if count("cola") > 0 else 2
	p.roll_burst = count("carteirinha") > 0

## Pega o upgrade: guarda e já aplica no jogador.
static func take(id: String, p: Node) -> void:
	taken[id] = count(id) + 1
	var old_max: int = p.max_hp
	apply_stats(p)
	if p.max_hp > old_max:
		p.heal(p.max_hp - old_max) # coração novo já vem cheio
	if id == "bolsa":
		p.heal(p.max_hp)
	if id == "cafe":
		p.heal(1)
		p.speed_boost(8.0)
	p.health_changed.emit(p.hp, p.max_hp)

## Ícone 16x16 de pixel art (desenhado em código; origem no canto de cima/esquerda).
static func draw_icon(ci: CanvasItem, id: String, at: Vector2, s: float = 1.0) -> void:
	var o := Fx.OUTLINE
	var c: Color = DEFS[id]["color"]
	var r := func(x: float, y: float, w: float, h: float, col: Color) -> void:
		ci.draw_rect(Rect2(at + Vector2(x, y) * s, Vector2(w, h) * s), col)
	match id:
		"cafe":
			r.call(3, 2, 10, 13, o); r.call(4, 3, 8, 11, Color("f2ede4")); r.call(9, 3, 3, 11, Color("d2c9bc"))
			r.call(4, 7, 8, 4, c); r.call(2, 1, 12, 3, o); r.call(3, 2, 10, 1, Color("4a3a32"))
			r.call(5, 4, 1, 3, Color.WHITE)
		"calculadora":
			r.call(3, 1, 10, 14, o); r.call(4, 2, 8, 12, c); r.call(5, 3, 6, 3, Color("b0e0a0"))
			for yy in 3:
				for xx in 3:
					r.call(5 + xx * 2, 7 + yy * 2, 1, 1, Color("e8e0d8"))
		"grampeador":
			r.call(1, 9, 14, 5, o); r.call(2, 10, 12, 3, Color("3a3848"))
			r.call(1, 5, 14, 5, o); r.call(2, 6, 12, 3, c); r.call(2, 6, 12, 1, c.lightened(0.3))
		"mochila":
			r.call(3, 3, 10, 12, o); r.call(4, 4, 8, 10, c); r.call(5, 9, 6, 4, c.darkened(0.25))
			r.call(6, 1, 4, 3, o); r.call(7, 2, 2, 1, c); r.call(4, 4, 8, 1, c.lightened(0.25))
		"monitoria":
			r.call(2, 2, 12, 12, o); r.call(3, 3, 10, 10, c); r.call(7, 4, 2, 5, o); r.call(7, 8, 4, 2, o)
		"apostila":
			r.call(2, 2, 12, 13, o); r.call(3, 3, 10, 11, c); r.call(3, 3, 2, 11, Color("6a5a8a"))
			for yy in 4:
				r.call(6, 5 + yy * 2, 6, 1, Color("8a8090"))
		"wifi":
			r.call(7, 12, 2, 2, c)
			r.call(5, 9, 6, 1, c); r.call(4, 10, 1, 1, c); r.call(11, 10, 1, 1, c)
			r.call(3, 6, 10, 1, c); r.call(2, 7, 1, 1, c); r.call(13, 7, 1, 1, c)
			r.call(2, 3, 12, 1, c); r.call(1, 4, 1, 1, c); r.call(14, 4, 1, 1, c)
		"energetico":
			r.call(4, 2, 8, 13, o); r.call(5, 3, 6, 11, c); r.call(5, 6, 6, 4, Color("1a1a2a"))
			r.call(7, 7, 2, 2, c.lightened(0.4)); r.call(5, 1, 6, 2, Color("b0b0c0")); r.call(6, 3, 1, 3, Color.WHITE)
		"bolsa":
			# saco de dinheiro com cifrão
			r.call(3, 5, 10, 10, o); r.call(4, 6, 8, 8, c); r.call(6, 2, 4, 4, o); r.call(7, 3, 2, 2, c)
			r.call(7, 7, 2, 6, Color("8a5a10")); r.call(6, 8, 4, 1, Color("8a5a10")); r.call(6, 11, 4, 1, Color("8a5a10"))
		"cola":
			# papelzinho dobrado com rabiscos
			r.call(3, 3, 10, 11, o); r.call(4, 4, 8, 9, Color("f2ede4")); r.call(10, 4, 2, 2, c)
			for yy in 3:
				r.call(5, 6 + yy * 2, 5 - yy, 1, Color("3a6ad0"))
		"carteirinha":
			r.call(1, 4, 14, 9, o); r.call(2, 5, 12, 7, c); r.call(3, 6, 4, 5, Color("f0b48a"))
			r.call(8, 6, 5, 1, Color.WHITE); r.call(8, 8, 4, 1, Color.WHITE); r.call(8, 10, 5, 1, Color.WHITE)
		"caneta":
			for i in 10:
				r.call(2 + i, 12 - i, 3, 3, o)
			for i in 9:
				r.call(3 + i, 12 - i, 1, 1, c)
			r.call(2, 13, 2, 2, Color("ff9a9a"))
