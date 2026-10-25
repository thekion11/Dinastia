class_name CompeticionFilas
extends RefCounted
## LAS FILAS DE LA FICHA DE COMPETICIÓN (25-10-2026): tabla, cabecera, partido y
## leyenda de zonas, como funciones puras que reciben datos y pintan.
##
## POR QUÉ FILAS Y NO UN `GridContainer`: la rejilla alineaba bien las cifras,
## pero una celda no sabe que es parte de una fila, así que no había forma de
## poner FONDO a la fila de tu club ni rayar la tabla para seguir una línea con
## la vista (con 20 clubes, del nombre a los puntos hay medio metro de pantalla).
## Cada fila es ahora un panel con su fondo y las columnas tienen ANCHO FIJO, que
## es lo que mantiene la alineación que antes daba la rejilla.

const ANCHO_PUESTO := 30.0
const ANCHO_CIFRA := 44.0
const ANCHO_BARRA := 4.0
const ALTO_FILA := 28.0
const ESCUDO := 20

## El fondo de la fila de tu club: el verde de la casa, translúcido, con borde.
## Antes tu club solo cambiaba el COLOR del texto, y ese verde era casi el mismo
## que el de las zonas de arriba: no se distinguía "voy cuarto" de "soy yo".
static func estilo_fila(propia: bool, par: bool) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	if propia:
		e.bg_color = Color(Tema.ACENTO, 0.22)
		e.border_color = Color(Tema.ACENTO, 0.85)
		e.set_border_width_all(1)
	else:
		e.bg_color = Color(1, 1, 1, 0.035) if par else Color(0, 0, 0, 0)
	e.set_corner_radius_all(4)
	e.content_margin_left = 0
	e.content_margin_right = 8
	return e

static func etiqueta(txt: String, tam: int, color: Color, derecha: bool = false, ancho: float = 0.0) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if ancho > 0.0:
		l.custom_minimum_size = Vector2(ancho, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func escudo(c: Club, tam: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Escudo.textura(c, tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## La cabecera: las mismas columnas y anchos que las filas, para que «PTS» quede
## exactamente encima de los puntos.
static func cabecera(padre: Node, cifras: Array) -> void:
	## Dentro del MISMO panel que las filas (transparente): así los márgenes
	## coinciden al píxel y las siglas caen encima de sus cifras.
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", estilo_fila(false, false))
	caja.set_meta("cabecera", true)
	padre.add_child(caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	caja.add_child(h)
	var hueco := Control.new()
	hueco.custom_minimum_size = Vector2(ANCHO_BARRA, 0)
	h.add_child(hueco)
	h.add_child(etiqueta("#", 11, Tema.SUAVE, true, ANCHO_PUESTO))
	var club := etiqueta(sigla("CLUB"), 11, Tema.SUAVE)
	club.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	club.custom_minimum_size = Vector2(float(ESCUDO) + 140.0, 0)
	h.add_child(club)
	for t: String in cifras:
		var l := etiqueta(sigla(t), 11, Tema.SUAVE, true, ANCHO_CIFRA)
		## Las siglas no se explican solas en todos los idiomas: el tooltip sí.
		l.tooltip_text = Idiomas.t(_sigla_larga(t))
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(l)

## LAS SIGLAS DE LA TABLA, SIN CHOCAR CON NADA. «G», «E» y «P» no se pueden
## dar de alta tal cual en el diccionario: una «E» suelta también es la tecla
## de acción del explorador, y traducirla a «D» (draw) rompería ese rótulo. Se
## buscan con un prefijo propio; en castellano se dejan como están. Sin esto, en
## inglés salía «P G E P»: PJ ya era «P» y la P de perdidos seguía siendo «P».
static func sigla(t: String) -> String:
	if Idiomas.idioma == "es":
		return t
	var clave := "Sigla de tabla: " + t
	var r := Idiomas.t(clave)
	return r if r != clave else Idiomas.t(t)

static func _sigla_larga(t: String) -> String:
	match t:
		"PJ": return "Partidos jugados"
		"G": return "Ganados"
		"E": return "Empatados"
		"P": return "Perdidos"
		"GF": return "Goles a favor"
		"GC": return "Goles en contra"
		"DG": return "Diferencia de goles"
		"PTS": return "Puntos"
	return t

## Una fila de tabla. `cifras` ya vienen como texto; la última (los puntos) se
## pinta un punto más grande, porque es la que ordena la tabla.
static func fila_tabla(padre: Node, puesto: int, c: Club, cifras: Array, propia: bool,
		par: bool, zona: Dictionary) -> PanelContainer:
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", estilo_fila(propia, par))
	caja.custom_minimum_size = Vector2(0, ALTO_FILA)
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	caja.add_child(h)
	## La barra de zona, pegada al borde izquierdo: color y tooltip.
	var barra := ColorRect.new()
	barra.custom_minimum_size = Vector2(ANCHO_BARRA, 0)
	barra.color = CompeticionZonas.COLORES.get(String(zona.get("zona", "")), Color(0, 0, 0, 0))
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(barra)
	if not zona.is_empty():
		caja.tooltip_text = String(zona.get("texto", ""))
	var col_texto := Tema.TEXTO
	var col_puesto: Color = CompeticionZonas.COLORES.get(String(zona.get("zona", "")), Tema.SUAVE)
	h.add_child(etiqueta(str(puesto), 13, col_puesto, true, ANCHO_PUESTO))
	var nombre := HBoxContainer.new()
	nombre.add_theme_constant_override("separation", 8)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre.custom_minimum_size = Vector2(float(ESCUDO) + 140.0, 0)
	h.add_child(nombre)
	nombre.add_child(escudo(c, ESCUDO))
	var nom := etiqueta(Nombres.visible(c.nombre), 14, col_texto)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## Un nombre largo se corta con «…» en vez de empujar las cifras fuera.
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nom.clip_text = true
	nombre.add_child(nom)
	for i in cifras.size():
		var ultima := i == cifras.size() - 1
		var col := Tema.TEXTO if ultima or propia else Color(Tema.TEXTO, 0.82)
		h.add_child(etiqueta(String(cifras[i]), 15 if ultima else 14, Tema.ORO if ultima and propia else col, true, ANCHO_CIFRA))
	return caja

## La leyenda de las zonas que de verdad aparecen en esta tabla (si en Segunda
## no hay descenso, no se explica el rojo).
static func leyenda(padre: Node, zonas: Dictionary) -> void:
	var hay := {}
	for v: Dictionary in zonas.values():
		hay[String(v["zona"])] = true
	if hay.is_empty():
		return
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 16)
	f.add_theme_constant_override("v_separation", 4)
	padre.add_child(f)
	f.add_child(etiqueta(Idiomas.t("Si la liga terminara hoy:"), 11, Tema.SUAVE))
	for z: String in CompeticionZonas.ORDEN:
		if not hay.has(z):
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		f.add_child(h)
		var cuadro := ColorRect.new()
		cuadro.color = CompeticionZonas.COLORES[z]
		cuadro.custom_minimum_size = Vector2(10, 10)
		cuadro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(cuadro)
		h.add_child(etiqueta(CompeticionZonas.nombre_zona(z), 11, Tema.TEXTO))

## Un partido: «local [escudo] marcador [escudo] visita», con ancho fijo y
## centrado (si los nombres se estiran, los escudos acaban en los bordes, lejos
## del marcador al que pertenecen). El tuyo, con el fondo de tu club.
static func fila_partido(padre: Node, local: Club, visita: Club, gl: int, gv: int,
		mio: Club, extra: String = "") -> void:
	var tuyo := mio != null and (local == mio or visita == mio)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", estilo_fila(tuyo, false))
	padre.add_child(caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(h)
	var jugado := gl >= 0
	## El ganador en blanco y el que pierde apagado: se lee la jornada de un
	## vistazo sin comparar números.
	var col_l := Tema.TEXTO if not jugado or gl >= gv else Tema.SUAVE
	var col_v := Tema.TEXTO if not jugado or gv >= gl else Tema.SUAVE
	## Hueco gemelo del texto extra de la derecha: sin él, el marcador queda
	## descentrado respecto al de las filas de encima.
	var gemelo := Control.new()
	gemelo.custom_minimum_size = Vector2(150.0, 0)
	h.add_child(gemelo)
	var nl := etiqueta(Nombres.visible(local.nombre), 13, col_l, true, 240.0)
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nl.clip_text = true
	h.add_child(nl)
	h.add_child(escudo(local, 18))
	var marc := etiqueta(Idiomas.t("vs") if not jugado else "%d - %d" % [gl, gv], 13,
		Tema.ORO if jugado else Tema.SUAVE, false, 64.0)
	marc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(marc)
	h.add_child(escudo(visita, 18))
	var nv := etiqueta(Nombres.visible(visita.nombre), 13, col_v, false, 240.0)
	nv.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nv.clip_text = true
	h.add_child(nv)
	## Penales, «pasa X»...: al lado, en pequeño, sin mover el marcador.
	var ex := etiqueta(extra, 11, Tema.SUAVE, false, 150.0)
	ex.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ex.clip_text = true
	h.add_child(ex)

## Un rótulo de sección.
static func titulo(padre: Node, txt: String, color: Color, tam: int) -> Label:
	var l := etiqueta(txt, tam, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padre.add_child(l)
	return l
