class_name RutaCabecera
extends RefCounted
## La cabecera de La Ruta: quién eres, tu capítulo y tu nivel, tus tres
## medidores y las pestañas (Hoy, Yo, Ruta).

const E := preload("res://ui/carrera/ruta_estilo.gd")
const PESTANAS := [["hoy", "HOY"], ["yo", "YO"], ["ruta", "RUTA"]]

static func pintar(ui: Variant, j: Jugador, club: Club) -> Control:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var angosto := E.estrecho(ui)
	var cab := E.fila(8 if angosto else 14)
	cab.add_child(E.escudo(club, 44 if angosto else 58))
	var tit := E.columna(-2)
	cab.add_child(tit)
	var nombre := E.titulo(26 if angosto else 38, E.TEXTO, j.nombre.to_upper())
	nombre.clip_text = true
	tit.add_child(nombre)
	var sub := E.fila(8)
	tit.add_child(sub)
	sub.add_child(E.chip(Idiomas.t(String(CarreraRuta.capitulo(c)[1])).to_upper(), E.ORO))
	if c.energia < 30:
		sub.add_child(E.chip(Idiomas.t("SIN PIERNAS"), E.CORAL))
	var texto := Idiomas.t("%s · %s · %d años · temporada %d, semana %d") % [Nombres.visible(club.nombre), j.pos_e, j.edad, m.anio, m.semana]
	## Con el aviso «SIN PIERNAS» al lado la línea larga se corta a 1280: va la corta.
	if angosto or ui.get_viewport_rect().size.x < (1500.0 if c.energia < 30 else 1000.0):
		texto = Idiomas.t("%s · %d años · sem. %d") % [j.pos_e, j.edad, m.semana]
	if angosto and c.energia < 30:   ## en el teléfono, con el aviso al lado, solo cabe lo justo
		texto = "%s · %d" % [j.pos_e, j.edad]
	var datos := E.lbl(13, E.SUAVE, texto, true)
	datos.clip_text = true
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(datos)
	cab.add_child(_nivel(c, angosto))
	if not angosto:
		cab.add_child(_medidores(c, 170.0))
		cab.add_child(pestanas(ui, false))
	var bg := E.boton("💾", E.CIELO, ui._guardar, 40)
	bg.tooltip_text = Idiomas.t("Guardar")
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(bg)
	var bm := E.boton("🏠", E.SUAVE, ui._salir, 40)
	bm.tooltip_text = Idiomas.t("Menú")
	bm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(bm)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not angosto:
		return cab
	var v := E.columna(8)
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.add_child(cab)
	v.add_child(_medidores(c, 0.0))
	return v

static func _nivel(c: CarreraJugador, angosto: bool) -> Control:
	var r := CarreraRuta.asegurar(c)
	var niv := E.fila(8)
	var falta := CarreraRuta.xp_para(int(r["nivel"]))
	niv.add_child(RutaAnillo.crear(float(r["xp"]) / float(falta), str(int(r["nivel"])), E.ORO, 46 if angosto else 58))
	if angosto:
		return niv
	var nv := E.columna(-2)
	nv.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	niv.add_child(nv)
	nv.add_child(E.titulo(18, E.ORO, Idiomas.t("NIVEL")))
	nv.add_child(E.lbl(12, E.SUAVE, "%d / %d XP" % [int(r["xp"]), falta], true))
	var libres := int(r["puntos"]) + CarreraHabilidad.puntos(c)   ## de talento y de habilidad
	if libres > 0:
		nv.add_child(E.lbl(12, E.MENTA, E.plural(libres, "%d punto libre", "%d puntos libres") % libres, true))
	return niv

## Energía, relación con el DT y fama: apilados (ancho) o en una fila (estrecho).
static func _medidores(c: CarreraJugador, ancho: float) -> Control:
	var med := E.reparto(ancho > 0.0, 3 if ancho > 0.0 else 12)
	med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ancho > 0.0:
		med.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		med.custom_minimum_size = Vector2(ancho, 0)
	for par: Array in [["⚡", c.energia, E.MENTA], ["🤝", c.relacion_dt, E.CORAL], ["⭐", c.fama, E.ORO]]:
		var f := E.fila(6)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		med.add_child(f)
		var ic := E.lbl(12, par[2], String(par[0]), true)
		ic.custom_minimum_size = Vector2(18, 0)
		f.add_child(ic)
		f.add_child(E.barra(float(par[1]), 100.0, par[2], 7))
		var n := E.lbl(12, E.TEXTO, str(int(par[1])), true)
		n.custom_minimum_size = Vector2(24, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		f.add_child(n)
	return med

## Las pestañas: píldoras en la cabecera o, en estrecho, una barra abajo.
static func pestanas(ui: Variant, barra: bool) -> Control:
	var c: CarreraJugador = ui.carrera
	var puntos := int(CarreraRuta.asegurar(c)["puntos"]) + CarreraHabilidad.puntos(c)
	var grupo := ButtonGroup.new()
	var tabs := E.fila(6 if barra else 4)
	tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for par2: Array in PESTANAS:
		var id := String(par2[0])
		var marca := ""
		if (id == "hoy" and not c.eventos.is_empty()) or (id == "yo" and puntos > 0):
			marca = " ●"
		var b := E.opcion(Idiomas.t(String(par2[1])) + marca, E.ORO, grupo, ui._pestana == id, func() -> void:
			ui._pestana = id
			ui._sub = ""
			ui._pintar_semana(), 52 if barra else 40)
		b.add_theme_font_override("font", E.titular())
		b.add_theme_font_size_override("font_size", 24 if barra else 20)
		if barra:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	return tabs

## El aviso de la semana, en una banda.
static func aviso(texto: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", E.caja(Color(E.CORAL, 0.12), 12, Color(E.CORAL, 0.35), 12))
	var l := E.lbl(14, E.TEXTO, texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p
