class_name Sfx
extends RefCounted
## Efeitos sonoros do jogo; usa assets/sfx/<nome>.wav/.ogg quando disponíveis.
## Sons sem arquivo correspondente são sintetizados e ficam em cache.
## Uso: Sfx.play(self, "hit").

## nome -> [freq inicial, freq final, duração, volume, ruído (0..1), forma ("sin"/"sq")]
const DEFS := {
	"shoot": [760.0, 220.0, 0.07, 0.16, 0.0, "sin"],
	"roll": [180.0, 90.0, 0.14, 0.12, 0.3, "sin"],
	"hit": [320.0, 120.0, 0.06, 0.22, 0.6, "sq"],
	"crit": [900.0, 300.0, 0.10, 0.2, 0.3, "sq"],
	"kill": [520.0, 60.0, 0.22, 0.26, 0.5, "sq"],
	"hurt": [240.0, 70.0, 0.25, 0.35, 0.4, "sq"],
	"die": [300.0, 40.0, 0.9, 0.35, 0.3, "sq"],
	"pick": [600.0, 1200.0, 0.12, 0.18, 0.0, "sin"],
	"upgrade": [440.0, 1320.0, 0.35, 0.2, 0.0, "sq"],
	"hover": [1000.0, 1000.0, 0.03, 0.08, 0.0, "sq"],
}
const MIN_GAP := 0.035 # não toca o mesmo som duas vezes em menos tempo que isso

static var _cache := {}
static var _last := {}

static func play(ctx: Node, name: String, pitch_jitter: float = 0.06) -> void:
	if ctx == null or not ctx.is_inside_tree():
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -1.0)) < MIN_GAP:
		return
	_last[name] = now
	var stream := _stream(name)
	if stream == null:
		return
	var a := AudioStreamPlayer.new()
	a.stream = stream
	a.volume_db = -2.0
	a.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	a.process_mode = Node.PROCESS_MODE_ALWAYS # toca mesmo com o jogo pausado (tela de upgrade)
	a.finished.connect(a.queue_free)
	# Fica na raiz: o som continua mesmo se quem tocou sumir (inimigo morrendo).
	ctx.get_tree().root.add_child(a)
	a.play()

static func _stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var s: AudioStream = null
	for ext in ["wav", "ogg"]:
		var path := "res://assets/sfx/%s.%s" % [name, ext]
		if ResourceLoader.exists(path):
			s = load(path)
			break
	if s == null and DEFS.has(name):
		s = _synth(DEFS[name])
	_cache[name] = s
	return s

static func _synth(d: Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var count := int(stream.mix_rate * float(d[2]))
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise_amt: float = d[4]
	var square: bool = d[5] == "sq"
	for i in count:
		var t := float(i) / float(count)
		phase += TAU * lerpf(d[0], d[1], t) / stream.mix_rate
		var tone := sin(phase)
		if square:
			tone = signf(tone) * 0.6
		var v := lerpf(tone, randf_range(-1.0, 1.0), noise_amt)
		var env := (1.0 - t) * (1.0 - t)
		var value := int(clampf(v * env * float(d[3]) * 32767.0, -32768.0, 32767.0))
		data.encode_s16(i * 2, value)
	stream.data = data
	return stream
