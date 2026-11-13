class_name RutaLogros
extends RefCounted
## LOS LOGROS DE LA RUTA EN PANTALLA (13-11-2026): la vitrina de insignias
## (ganadas en oro; las que faltan, apagadas y con cómo se ganan) y los AVISOS
## de la semana, cada uno en su ficha (antes iban todos seguidos en una banda
## roja que parecía un error), con el logro recién ganado en oro y con sonido.

const E := preload("res://ui/carrera/ruta_estilo.gd")
const A_LA_VISTA := 2

static func cuenta(c: CarreraJugador) -> String:
	return "%d / %d" % [CarreraLogros.ganados(c).size(), CarreraLogros.LOGROS.size()]

static func pintar(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta(E.ORO)
	var v := E.columna(10)
	p.add_child(v)
	var cab := E.fila(12)
	v.add_child(cab)
	cab.add_child(E.cifra(cuenta(c), "logros", E.ORO, 44))
	(cab.get_child(0) as Control).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var nota := E.lbl(13, E.SUAVE, "Son tuyos y de esta carrera: cada uno da experiencia una sola vez.")
	nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nota.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(nota)
	var g := GridContainer.new()
	g.columns = 1 if E.estrecho(ui) else 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	## Primero los ganados.
	for ganado: bool in [true, false]:
		for id: String in CarreraLogros.LOGROS:
			if CarreraLogros.tiene(c, id) == ganado:
				g.add_child(_insignia(id, ganado))
	return p

static func _insignia(id: String, ganado: bool) -> Control:
	var def: Array = CarreraLogros.LOGROS[id]
	var caja := PanelContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_stylebox_override("panel", E.caja(Color(E.ORO, 0.14) if ganado else E.TINTA2, 12, Color(E.ORO, 0.8 if ganado else 0.12), 10))
	var f := E.fila(10)
	caja.add_child(f)
	var ico := E.lbl(26, E.TEXTO, String(def[0]) if ganado else "🔒")
	ico.custom_minimum_size = Vector2(36, 0)
	ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(ico)
	var t := E.columna(0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f.add_child(t)
	t.add_child(E.lbl(15, E.ORO if ganado else E.SUAVE, String(def[1]), true))
	var d := E.lbl(12, E.TEXTO if ganado else E.SUAVE, String(def[2]))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(d)
	var xp := E.lbl(13, E.ORO if ganado else E.SUAVE, "+%d XP" % int(def[3]), true)
	xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(xp)
	return caja

## Los avisos de la semana: una ficha por noticia y, en oro, los logros recién ganados.
static func avisos(texto: String, nuevos: Array) -> Control:
	var caja := E.columna(6)   ## una por fila: en un contenedor de flujo el texto con salto de línea se plegaba letra a letra
	for id: String in nuevos:
		if CarreraLogros.LOGROS.has(id):
			caja.add_child(_ficha(CarreraLogros.texto(id), E.ORO))
	## Como mucho DOS noticias a la vista (los logros, siempre); el resto, tras «ver más».
	var resto: Array = []
	for trozo: String in texto.split("·", false):
		if trozo.strip_edges() == "":
			continue
		var f := _ficha(trozo.strip_edges(), E.CIELO)
		caja.add_child(f)
		if caja.get_child_count() - nuevos.size() > A_LA_VISTA:
			f.visible = false
			resto.append(f)
	if not resto.is_empty():
		var mas := E.boton(E.plural(resto.size(), "Ver %d aviso más", "Ver %d avisos más") % resto.size(), E.CIELO, Callable(), 30)
		mas.pressed.connect(func() -> void:
			for f2: Control in resto:
				f2.visible = true
			mas.visible = false)
		caja.add_child(mas)
	if not nuevos.is_empty():
		E.son("logro")
	return caja

static func _ficha(texto: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", E.caja(Color(col, 0.12), 12, Color(col, 0.45), 10))
	var l := E.lbl(14, E.TEXTO, texto, true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p
