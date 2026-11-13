class_name RutaSub
extends RefCounted
## LAS PANTALLAS DE DENTRO (13-11-2026, orden del dueño: interfaces menos
## llenas, repartidas en submenús a pantalla completa). Cada pestaña de La Ruta
## enseña lo esencial y unas TECLAS grandes; cada tecla abre su pantalla entera
## (`ui._sub`), con «Volver» arriba (y con el botón de cancelar del mando).

const E := preload("res://ui/carrera/ruta_estilo.gd")

## id -> [pestaña, icono, título, color]
const SUBS := {
	"entreno": ["hoy", "🎯", "ENTRENO DE LA SEMANA", "cielo"],
	"rival": ["hoy", "", "🥊 TU RIVAL", "coral"],
	"grada": ["hoy", "", "📣 LA GRADA", "cielo"],
	"juego": ["yo", "📊", "TU JUEGO", "oro"],
	"talentos": ["yo", "⭐", "TALENTOS", "oro"],
	"vida": ["yo", "🏠", "TU VIDA", "menta"],
	"temporadas": ["ruta", "📅", "TUS TEMPORADAS", "suave"],
	"palmares": ["ruta", "", "🏅 TU PALMARÉS", "oro"],
	"decisiones": ["ruta", "🧭", "TUS DECISIONES", "suave"],
}

static func _color(nombre: String) -> Color:
	match nombre:
		"cielo": return E.CIELO
		"coral": return E.CORAL
		"oro": return E.ORO
		"menta": return E.MENTA
	return E.SUAVE

static func _titulo(id: String) -> String:
	var d: Array = SUBS[id]
	return (String(d[1]) + "  " if String(d[1]) != "" else "") + Idiomas.t(String(d[2]))

## La pantalla abierta, si es de esta pestaña ("" si no hay ninguna).
static func abierta(ui: Variant) -> String:
	var id := String(ui._sub)
	return id if SUBS.has(id) and String(SUBS[id][0]) == String(ui._pestana) else ""

## Lo que cuenta cada tecla debajo de su nombre (una línea, ya traducida).
static func _detalle(ui: Variant, j: Jugador, id: String) -> String:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	match id:
		"entreno":
			var focos := CarreraPortero.focos_para(j)
			return Idiomas.t(String(focos[c.foco][0])) if focos.has(c.foco) else ""
		"rival":
			var o := CarreraRuta.rival(c, m)
			var d := CarreraRuta.duelo(c, m)
			return "%s · %d – %d" % [o.nombre, int(d[0]), int(d[1])] if o != null else ""
		"grada":
			return Idiomas.t("📱 %s seguidores") % E.miles(c.seguidores)
		"juego", "talentos":
			var puntos := int(CarreraRuta.asegurar(c)["puntos"])
			return E.plural(puntos, "%d punto por gastar", "%d puntos por gastar") % puntos
		"vida":
			return Eco.dinero(CarreraVida.ahorros(c))
		"temporadas":
			return str(m.anio)
	return ""

## Las teclas de una pestaña: en fila en el PC, una bajo otra en el teléfono.
static func teclas(ui: Variant, j: Jugador, pestana: String, en_columna := false, sin := "") -> Control:
	var caja := E.reparto(en_columna or E.estrecho(ui), 8)
	for id: String in SUBS:
		if String(SUBS[id][0]) != pestana or id == sin:
			continue
		var det := _detalle(ui, j, id)
		var col := _color(String(SUBS[id][3]))
		var b := E.boton(_titulo(id) + ("\n" + det if det != "" else "") , col, func() -> void:
			ui._sub = id
			ui._pintar_semana(), 62)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 15)
		if id in ["talentos", "juego"] and int(CarreraRuta.asegurar(ui.carrera)["puntos"]) > 0:
			b.text += "  ●"
		caja.add_child(b)
	return caja

## La pantalla entera: «Volver», el título y el contenido con su barra de desplazamiento.
static func pintar(ui: Variant, j: Jugador, club: Club) -> Control:
	var id := abierta(ui)
	var v := E.columna(10)
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var cab := E.fila(12)
	v.add_child(cab)
	var volver := E.boton("←  " + Idiomas.t("Volver"), E.SUAVE, func() -> void: cerrar(ui), 44)
	volver.name = "Volver"
	volver.set_meta("principal", true)   ## el foco del mando empieza aquí: desde «Volver» se baja a todo lo demás
	cab.add_child(volver)
	var tit := E.titulo(22 if E.estrecho(ui) else 28, E.TEXTO, _titulo(id))
	tit.clip_text = true
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(tit)
	var dentro := _contenido(ui, j, club, id)
	## El título ya está arriba: el rótulo igual de dentro de la tarjeta sobra (si comparte fila con una ficha, se vacía para no moverla).
	for tarjeta: Control in dentro:
		for l: Node in tarjeta.find_children("*", "Label", true, false):
			if (l as Label).text == String(SUBS[id][2]):
				(l as Label).text = ""
				(l as Label).visible = l.get_parent() is HBoxContainer
				break
	v.add_child(E.columnas(ui, dentro, []))
	return v

static func cerrar(ui: Variant) -> void:
	ui._sub = ""
	ui._pintar_semana()

static func _contenido(ui: Variant, j: Jugador, _club: Club, id: String) -> Array:
	match id:
		"entreno": return [RutaHoy._entreno(ui, j)]
		"rival": return [RutaCamino.duelo(ui, true)]
		"grada": return [RutaCamino.grada(ui, 14)]
		"juego": return RutaReparto.pintar(ui, j)
		"talentos": return [RutaYo._talentos(ui)]
		"vida": return [RutaVida.pintar(ui)]
		"temporadas": return [RutaCamino._temporadas(ui)]
		"palmares": return [RutaTemporada.palmares(ui)]
		"decisiones": return [RutaCamino._decisiones(ui.carrera)]
	return []
