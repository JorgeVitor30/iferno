extends Node
## Autoload: monta a fonte pixel do jogo (gerada por tools/build_pixel_font.py)
## e põe ela como fonte padrão de tudo (Labels e textos desenhados em _draw()).
## É uma fonte de bitmap: só fica nítida em tamanhos múltiplos de SIZE
## (11 = normal, 22 = grande). Use Fx.SMALL / Fx.BIG nos textos.

const SIZE := 11
const TEX := preload("res://assets/fonts/pixel_font.png")
const META_PATH := "res://assets/fonts/pixel_font.json"

var font: FontFile

func _ready() -> void:
	font = _build()
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = SIZE
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = SIZE
	get_tree().root.theme = theme

func _build() -> FontFile:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	var img := TEX.get_image()
	var ascent := float(meta["ascent"])
	var height := float(meta["height"])
	var f := FontFile.new()
	f.fixed_size = SIZE
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.multichannel_signed_distance_field = false
	var sz := Vector2i(SIZE, 0)
	f.set_texture_image(0, sz, 0, img)
	f.set_cache_ascent(0, SIZE, ascent)
	f.set_cache_descent(0, SIZE, height - ascent)
	var glyphs: Dictionary = meta["glyphs"]
	for ch: String in glyphs:
		var g: Array = glyphs[ch]
		var x := float(g[0])
		var w := float(g[1])
		var code := ch.unicode_at(0)
		f.set_glyph_advance(0, SIZE, code, Vector2(w + 1.0, 0.0))
		f.set_glyph_offset(0, sz, code, Vector2(0.0, -ascent))
		f.set_glyph_size(0, sz, code, Vector2(w, height))
		f.set_glyph_uv_rect(0, sz, code, Rect2(x, 0.0, w, height))
		f.set_glyph_texture_idx(0, sz, code, 0)
	return f
