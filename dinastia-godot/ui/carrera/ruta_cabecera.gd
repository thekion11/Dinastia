class_name RutaCabecera
extends RefCounted
## La cabecera de La Ruta: quién eres, tu capítulo y tu nivel, tus tres
## medidores y las pestañas (Hoy, Yo, Ruta).

const E := preload("res://ui/carrera/ruta_estilo.gd")
const PESTANAS := [["hoy", "HOY"], ["yo", "YO"], ["ruta", "RUTA"]]

static func pintar(ui: Variant, j: Jugador, club: Club) -> Control:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var r := CarreraRuta.asegurar(c)
	var cab := E.fila(14)
	cab.add_child(E.escudo(club, 58))
	var tit := E.columna(-2)
	cab.add_child(tit)
	var nombre := E.titulo(38, E.TEXTO, j.nombre.to_upper())
	nombre.clip_text = true
	tit.add_child(nombre)
	var sub := E.fila(8)
	tit.add_child(sub)
	sub.add_child(E.chip(Idiomas.t(String(CarreraRuta.capitulo(c)[1])).to_upper(), E.ORO))
	var datos := E.lbl(13, E.SUAVE, Idiomas.t("%s · %s · %d años · temporada %d, semana %d") % [Nombres.visible(club.nombre), j.pos_e, j.edad, m.anio, m.semana], true)
	datos.clip_text = true
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.add_child(datos)
	## El nivel.
	var niv := E.fila(8)
	cab.add_child(niv)
	var falta := CarreraRuta.xp_para(int(r["nivel"]))
	niv.add_child(RutaAnillo.crear(float(r["xp"]) / float(falta), str(int(r["nivel"])), E.ORO, 58))
	var nv := E.columna(-2)
	nv.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	niv.add_child(nv)
	nv.add_child(E.titulo(18, E.ORO, Idiomas.t("NIVEL")))
	nv.add_child(E.lbl(12, E.SUAVE, "%d / %d XP" % [int(r["xp"]), falta], true))
	if int(r["puntos"]) > 0:
		nv.add_child(E.lbl(12, E.MENTA, Idiomas.t("%d punto(s) libres") % int(r["puntos"]), true))
	## Los medidores.
	var med := E.columna(3)
	med.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	med.custom_minimum_size = Vector2(170, 0)
	cab.add_child(med)
	for par: Array in [["⚡", c.energia, E.MENTA], ["🤝", c.relacion_dt, E.CORAL], ["⭐", c.fama, E.ORO]]:
		var f := E.fila(6)
		med.add_child(f)
		var ic := E.lbl(12, par[2], String(par[0]), true)
		ic.custom_minimum_size = Vector2(18, 0)
		f.add_child(ic)
		f.add_child(E.barra(float(par[1]), 100.0, par[2], 7))
		var n := E.lbl(12, E.TEXTO, str(int(par[1])), true)
		n.custom_minimum_size = Vector2(24, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		f.add_child(n)
	## Las pestañas.
	var grupo := ButtonGroup.new()
	var tabs := E.fila(4)
	tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(tabs)
	for par2: Array in PESTANAS:
		var id := String(par2[0])
		var aviso := ""
		if id == "hoy" and not c.eventos.is_empty():
			aviso = " ●"
		elif id == "yo" and int(r["puntos"]) > 0:
			aviso = " ●"
		var b := E.opcion(Idiomas.t(String(par2[1])) + aviso, E.ORO, grupo, ui._pestana == id, func() -> void:
			ui._pestana = id
			ui._pintar_semana(), 40)
		b.add_theme_font_override("font", E.titular())
		b.add_theme_font_size_override("font_size", 20)
		tabs.add_child(b)
	var bg := E.boton("💾", E.CIELO, ui._guardar, 40)
	bg.tooltip_text = Idiomas.t("Guardar")
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(bg)
	var bm := E.boton("🏠", E.SUAVE, ui._salir, 40)
	bm.tooltip_text = Idiomas.t("Menú")
	bm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(bm)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return cab

## El aviso de la semana, en una banda.
static func aviso(texto: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", E.caja(Color(E.CORAL, 0.12), 12, Color(E.CORAL, 0.35), 12))
	var l := E.lbl(14, E.TEXTO, texto)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p
