class_name LogoCompeticion
extends RefCounted
## EL LOGO DE CADA COMPETICIÓN, generado por código (26-10, pedido del dueño),
## con el mismo método que `Escudo`: un SVG que se rasteriza y se guarda en
## caché. Cada tipo tiene su forma (la liga un escudo con franja, la copa un
## medallón con estrellas, la continental una estrella de ocho puntas, el
## mundial un globo con meridianos...) y sus colores salen de
## `CompeticionInfo.colores()`. Las siglas van APARTE, en un `Label` encima
## (`control()`): el rasterizador de SVG de Godot no dibuja texto.

static var _cache: Dictionary = {}

static func textura(nombre: String, alto_px: int = 64) -> Texture2D:
	var clave := "%s_%d_%s" % [nombre, alto_px, str(Datos.base_real)]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(nombre), float(alto_px) / 100.0) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[clave] = tex
	return tex

## Logo listo para meter en la interfaz: la forma y las siglas encima.
static func control(nombre: String, alto: int = 48) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = textura(nombre, alto * 2)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	l.text = CompeticionInfo.siglas(nombre)
	l.add_theme_font_size_override("font_size", maxi(8, int(alto * 0.26)))
	l.add_theme_color_override("font_color", CompeticionInfo.colores(nombre)[1])
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", maxi(2, alto / 16))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(l)
	return caja

static func _hex(c: Color) -> String:
	return "#" + c.to_html(false)

## El SVG (lienzo de 100×100) según el tipo.
static func svg_de(nombre: String) -> String:
	var cs := CompeticionInfo.colores(nombre)
	var c1 := _hex(cs[0])
	var c2 := _hex(cs[1])
	var oscuro := _hex(cs[0].darkened(0.45))
	var cuerpo := ""
	match CompeticionInfo.tipo_de(nombre):
		"liga":
			cuerpo = ('<path d="M50 4 L92 18 L86 66 Q78 86 50 97 Q22 86 14 66 L8 18Z" fill="%s" stroke="%s" stroke-width="5"/>' +
				'<rect x="12" y="40" width="76" height="16" fill="%s" opacity=".85"/>') % [c1, c2, oscuro]
		"copa":
			cuerpo = '<circle cx="50" cy="50" r="45" fill="%s" stroke="%s" stroke-width="5"/>' % [c1, c2]
			for i in 8:
				var a := TAU * float(i) / 8.0 - PI / 2.0
				cuerpo += _estrella(50.0 + cos(a) * 36.0, 50.0 + sin(a) * 36.0, 5.0, c2)
		"supercopa":
			cuerpo = ('<path d="M50 3 L97 50 L50 97 L3 50Z" fill="%s" stroke="%s" stroke-width="5"/>' % [c1, c2]) + _estrella(50, 20, 8, c2)
		"continental":
			cuerpo = '<path d="%s" fill="%s"/>' % [_puntas(8, 48.0, 36.0), c2]
			cuerpo += '<circle cx="50" cy="50" r="34" fill="%s"/>' % c1
			cuerpo += '<circle cx="50" cy="50" r="28" fill="none" stroke="%s" stroke-width="2"/>' % c2
		"continental2":
			cuerpo = ('<rect x="5" y="5" width="90" height="90" rx="20" fill="%s" stroke="%s" stroke-width="5"/>' +
				'<path d="M22 72 L50 28 L78 72" fill="none" stroke="%s" stroke-width="7" opacity=".55"/>') % [c1, c2, c2]
		"mundial_clubes", "mundial_sel":
			cuerpo = '<circle cx="50" cy="50" r="45" fill="%s" stroke="%s" stroke-width="5"/>' % [c1, c2]
			cuerpo += ('<ellipse cx="50" cy="50" rx="18" ry="40" fill="none" stroke="%s" stroke-width="2.5" opacity=".7"/>' +
				'<line x1="10" y1="50" x2="90" y2="50" stroke="%s" stroke-width="2.5" opacity=".7"/>' +
				'<path d="M16 32 Q50 24 84 32 M16 68 Q50 76 84 68" fill="none" stroke="%s" stroke-width="2" opacity=".6"/>') % [c2, c2, c2]
			if CompeticionInfo.tipo_de(nombre) == "mundial_sel":
				cuerpo += _laurel(c2)
		_:
			cuerpo = ('<path d="M50 4 L90 26 L90 74 L50 96 L10 74 L10 26Z" fill="%s" stroke="%s" stroke-width="5"/>') % [c1, c2]
			cuerpo += _laurel(c2)
	return '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">%s</svg>' % cuerpo

static func _estrella(x: float, y: float, r: float, col: String) -> String:
	var d := ""
	for i in 10:
		var a := TAU * float(i) / 10.0 - PI / 2.0
		var rr := r if i % 2 == 0 else r * 0.45
		d += ("M" if i == 0 else "L") + "%.1f %.1f " % [x + cos(a) * rr, y + sin(a) * rr]
	return '<path d="%sZ" fill="%s"/>' % [d, col]

static func _puntas(n: int, r1: float, r2: float) -> String:
	var d := ""
	for i in n * 2:
		var a := TAU * float(i) / float(n * 2) - PI / 2.0
		var r := r1 if i % 2 == 0 else r2
		d += ("M" if i == 0 else "L") + "%.1f %.1f " % [50.0 + cos(a) * r, 50.0 + sin(a) * r]
	return d + "Z"

## Dos ramas de laurel abajo (torneos de selecciones).
static func _laurel(col: String) -> String:
	var s := ""
	for lado in [-1.0, 1.0]:
		for i in 4:
			var x: float = 50.0 + lado * (14.0 + float(i) * 7.0)
			var y := 86.0 - float(i) * 8.0
			s += '<ellipse cx="%.1f" cy="%.1f" rx="5" ry="2.4" fill="%s" transform="rotate(%d %.1f %.1f)"/>' % [
				x, y, col, int(lado * -40.0), x, y]
	return s
