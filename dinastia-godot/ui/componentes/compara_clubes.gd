class_name ComparaClubes
extends RefCounted
## TU CLUB FRENTE A OTRO (2-11-2026, M-294): en la ficha de un club ajeno, una tabla de tres columnas con lo que
## decide un partido o una negociación: reputación, media del once y de la plantilla, sueldos, valor del plantel,
## aforo y socios. La flecha dice quién sale ganando en cada fila (más sueldo no es «mejor»: se marca neutro).

## [rótulo, Callable(club) -> float, formato, ¿más es mejor? (1 sí, 0 neutro)]
static func filas() -> Array:
	return [
		["Reputación", func(c: Club) -> float: return float(c.rep), "%d", 1],
		["Media del mejor once", func(c: Club) -> float: return _media_once(c), "%.1f", 1],
		["Media de la plantilla", func(c: Club) -> float: return c.media(), "%.1f", 1],
		["Valor del plantel", func(c: Club) -> float: return _valor(c), "dinero", 1],
		["Sueldos por semana", func(c: Club) -> float: return float(c.masa_salarial()), "dinero", 0],
		["Aforo", func(c: Club) -> float: return float(c.estadio_aforo), "miles", 1],
		["Socios", func(c: Club) -> float: return float(c.socios), "miles", 1],
	]

static func _media_once(c: Club) -> float:
	var once := c.once()
	if once.is_empty():
		return 0.0
	var s := 0.0
	for j: Jugador in once:
		s += float(j.ovr)
	return s / float(once.size())

static func _valor(c: Club) -> float:
	var s := 0.0
	for j: Jugador in c.plantilla:
		s += float(j.valor)
	return s

static func _fmt(v: float, formato: String) -> String:
	match formato:
		"dinero": return Cesiones.dinero(int(v))
		"miles": return _miles(int(v))
	return formato % (int(v) if formato == "%d" else v)

static func _miles(n: int) -> String:
	var t := str(absi(n))
	var out := ""
	while t.length() > 3:
		out = "." + t.right(3) + out
		t = t.left(t.length() - 3)
	return ("-" if n < 0 else "") + t + out

static func pintar(padre: Node, mio: Club, otro: Club, col_suave: Color, col_texto: Color, col_bien: Color, col_mal: Color) -> void:
	if mio == null or otro == null or mio == otro:
		return
	var t := Label.new()
	t.text = Idiomas.t("TU CLUB FRENTE A %s") % otro.nombre.to_upper()
	t.add_theme_font_size_override("font_size", 11)
	t.add_theme_color_override("font_color", col_suave)
	padre.add_child(t)
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	padre.add_child(g)
	for enc in ["", mio.nombre, otro.nombre]:
		g.add_child(_celda(String(enc), col_suave, enc != ""))
	for f: Array in filas():
		var a: float = (f[1] as Callable).call(mio)
		var b: float = (f[1] as Callable).call(otro)
		var ca := col_texto
		var cb := col_texto
		if int(f[3]) == 1 and not is_equal_approx(a, b):
			ca = col_bien if a > b else col_mal
			cb = col_bien if b > a else col_mal
		g.add_child(_celda(Idiomas.t(String(f[0])), col_suave, false))
		g.add_child(_celda(_fmt(a, String(f[2])) + ("  ▲" if ca == col_bien else ""), ca, true))
		g.add_child(_celda(_fmt(b, String(f[2])) + ("  ▲" if cb == col_bien else ""), cb, true))

static func _celda(texto: String, color: Color, derecha: bool) -> Label:
	var l := Label.new()
	l.text = texto
	l.clip_text = true
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", color)
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		l.clip_text = false   ## el rótulo pide su ancho; las cifras se reparten el resto
	return l
