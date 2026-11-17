class_name FondoCine
extends Control
## EL FONDO DE LAS PANTALLAS DE LA MAQUETA (17-11-2026): degradado diagonal del color del evento a casi negro, las franjas inclinadas de las pantallas de evento
## (`.rayos`: blancas al 7 %, 30 px cada 90 px a 115°), una viñeta y, opcionalmente, luces desenfocadas (bokeh) que flotan despacio.
## Modos: «evento» (degradado de `color`), «dual» (dos colores, izquierda y derecha, como la previa) y «noche» (azul noche con dos haces rojos, como el menú y el resultado).

enum Modo { EVENTO, DUAL, NOCHE }
var modo: Modo = Modo.EVENTO
var color := Color("27a9b8")
var color_b := Color("1f8a4c")   ## el segundo color del modo «dual»
var franjas := true
var bokeh := false
var _t := 0.0
var _luces: Array = []
static var _vineta: GradientTexture2D

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 18:
		var r := RandomNumberGenerator.new()
		r.seed = 7000 + i
		_luces.append({"x": r.randf(), "y": r.randf(), "r": 8.0 + r.randf() * 36.0, "o": 0.05 + r.randf() * 0.16, "f": 0.05 + r.randf() * 0.1, "c": i % 3})

func _ready() -> void:
	set_process(bokeh and not Animar.reducidas())

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var s := size
	var r := Rect2(Vector2.ZERO, s)
	match modo:
		Modo.EVENTO:
			var oscuro := Color("08101e")
			var a := Color(color, 0.95)
			var m := a.lerp(oscuro, 0.55)
			draw_polygon(PackedVector2Array([r.position, Vector2(s.x, 0), s, Vector2(0, s.y)]), PackedColorArray([a, m, oscuro, m]))
		Modo.DUAL:
			draw_rect(r, Color("070b16"))
			var izq := Color(color, 0.92)
			var der := Color(color_b, 0.92)
			var oscuro2 := Color("0a0f1c")
			draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x * 0.5, 0), Vector2(s.x * 0.5, s.y), Vector2(0, s.y)]), PackedColorArray([izq, izq.lerp(oscuro2, 0.8), izq.lerp(oscuro2, 0.8), izq]))
			draw_polygon(PackedVector2Array([Vector2(s.x * 0.5, 0), Vector2(s.x, 0), s, Vector2(s.x * 0.5, s.y)]), PackedColorArray([der.lerp(oscuro2, 0.8), der, der, der.lerp(oscuro2, 0.8)]))
		Modo.NOCHE:
			draw_rect(r, Color("0b1330"))
			var rojo := Color(ROJO_NOCHE, 0.9)
			draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x * 0.22, 0), Vector2(s.x * 0.05, s.y * 0.55), Vector2(0, s.y * 0.6)]), PackedColorArray([rojo, rojo, rojo, rojo]))
			draw_polygon(PackedVector2Array([Vector2(0, s.y), Vector2(0, s.y * 0.5), Vector2(s.x * 0.2, s.y)]), PackedColorArray([rojo, rojo, rojo]))
			draw_polygon(PackedVector2Array([Vector2(s.x, 0), Vector2(s.x * 0.92, 0), Vector2(s.x, s.y * 0.3)]), PackedColorArray([rojo, rojo, rojo]))
			draw_polygon(PackedVector2Array([Vector2(s.x, s.y), Vector2(s.x * 0.8, s.y), Vector2(s.x, s.y * 0.35)]), PackedColorArray([rojo, rojo, rojo]))
			draw_polygon(PackedVector2Array([Vector2(s.x * 0.2, 0), Vector2(s.x * 0.25, 0), Vector2(s.x * 0.07, s.y * 0.6), Vector2(s.x * 0.04, s.y * 0.6)]), PackedColorArray([Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.16)]))
	if franjas and modo != Modo.NOCHE:
		var inclina := s.y * 0.4663
		var x := -inclina
		while x < s.x + 30.0:
			draw_polygon(PackedVector2Array([Vector2(x + inclina, 0), Vector2(x + inclina + 30.0, 0), Vector2(x + 30.0, s.y), Vector2(x, s.y)]), PackedColorArray([Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.07)]))
			x += 90.0
	if bokeh:
		for l: Dictionary in _luces:
			var cc: Color = [Color.WHITE, color, Color("ffd98a")][int(l["c"])]
			var px := fposmod(float(l["x"]) + sin(_t * float(l["f"]) + float(l["y"]) * 6.0) * 0.03, 1.0) * s.x
			var py := fposmod(float(l["y"]) - _t * float(l["f"]) * 0.02, 1.0) * s.y
			draw_circle(Vector2(px, py), float(l["r"]) * s.y / 540.0, Color(cc, float(l["o"])))
	if modo != Modo.NOCHE:
		draw_texture_rect(_vineta_tex(), r, false)

const ROJO_NOCHE := Color("7a1128")

static func _vineta_tex() -> GradientTexture2D:
	if _vineta == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.45, 1.0])
		g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.7)])
		_vineta = GradientTexture2D.new()
		_vineta.gradient = g
		_vineta.fill = GradientTexture2D.FILL_RADIAL
		_vineta.fill_from = Vector2(0.5, 0.5)
		_vineta.fill_to = Vector2(1.0, 0.5)
		_vineta.width = 256
		_vineta.height = 256
	return _vineta
