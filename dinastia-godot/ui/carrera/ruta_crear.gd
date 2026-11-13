class_name RutaCrear
extends RefCounted
## EL COMIENZO DE LA RUTA, en dos pasos: quién eres (nombre, puesto, pie) y
## quién te ficha (tres clubes modestos de tres países te ofrecen contrato).
## También la despedida: el retiro y el banquillo.

const E := preload("res://ui/carrera/ruta_estilo.gd")
const LINEAS := [["ATAQUE", ["DC", "ED", "EI"], "ff5a7a"], ["MEDIO", ["MCO", "MC", "MCD"], "ffc93c"],
	["DEFENSA", ["LD", "LI", "DFC"], "5ab8ff"], ["PORTERÍA", ["POR"], "4ee6b0"]]

## El marco de estas pantallas: centrado, y con desplazamiento si no cabe
## (un teléfono tumbado tiene menos de 400 px de alto).
static func _marco(ui: Variant, ancho: float) -> VBoxContainer:
	var vista: Vector2 = ui.get_viewport_rect().size
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui._cuerpo.add_child(sc)
	var centro := CenterContainer.new()
	centro.custom_minimum_size = vista
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(centro)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	centro.add_child(m)
	var v := E.columna(12)
	v.custom_minimum_size = Vector2(minf(ancho, vista.x - 32.0), 0)
	m.add_child(v)
	return v

static func pintar(ui: Variant) -> void:
	ui._limpiar()
	var v := _marco(ui, 860.0)
	v.add_child(E.rotulo("MODO JUGADOR", E.ORO))
	v.add_child(E.titulo(40 if E.estrecho(ui) else 60, E.TEXTO, "TU RUTA EMPIEZA AQUÍ"))
	v.add_child(E.lbl(15, E.SUAVE, "Tienes 17 años y un sueño. Los partidos los juegas tú; lo demás -el DT, la grada, las ofertas, la selección- depende de lo que hagas y de lo que decidas. De promesa a leyenda."))
	var p := E.tarjeta(E.ORO)
	v.add_child(p)
	var pv := E.columna(10)
	p.add_child(pv)
	pv.add_child(E.rotulo("TU NOMBRE"))
	ui._campo_nombre = LineEdit.new()
	ui._campo_nombre.text = ui.nombre_pedido if ui.nombre_pedido != "" else "Tomás Aravena"
	ui._campo_nombre.custom_minimum_size = Vector2(0, 44)
	ui._campo_nombre.max_length = 28
	ui._campo_nombre.add_theme_font_size_override("font_size", 20)
	ui._campo_nombre.add_theme_stylebox_override("normal", E.caja(E.TINTA2, 12, E.BORDE, 12))
	ui._campo_nombre.add_theme_stylebox_override("focus", E.caja(E.TINTA2, 12, E.ORO, 12))
	pv.add_child(ui._campo_nombre)
	pv.add_child(E.rotulo("TU PUESTO"))
	var lineas := GridContainer.new()
	lineas.columns = 2 if E.estrecho(ui) else 4
	lineas.add_theme_constant_override("h_separation", 10)
	lineas.add_theme_constant_override("v_separation", 10)
	pv.add_child(lineas)
	var posd: Dictionary = Datos.tabla("POSD")
	var grupo := ButtonGroup.new()
	for linea: Array in LINEAS:
		var col := Color(String(linea[2]))
		var lv := E.columna(5)
		lineas.add_child(lv)
		lv.add_child(E.lbl(12, col, String(linea[0]), true))
		for pe: String in linea[1]:
			var nombre := Idiomas.t(String((posd.get(pe, {}) as Dictionary).get("n", pe)))
			var bp := E.opcion("%s · %s" % [pe, nombre], col, grupo, pe == ui._puesto, func() -> void: ui._puesto = pe, 36)
			bp.clip_text = true
			lv.add_child(bp)
	pv.add_child(E.rotulo("TU PIE"))
	var pie := E.fila(6)
	pv.add_child(pie)
	var gp := ButtonGroup.new()
	for par: Array in [["Diestro", false], ["Zurdo", true]]:
		var zurdo: bool = par[1]
		pie.add_child(E.opcion(String(par[0]), E.CIELO, gp, zurdo == ui._zurdo, func() -> void: ui._zurdo = zurdo, 36))
	v.add_child(E.boton("⚽  BUSCAR CLUB", E.ORO, ui._buscar_club, 56, true))
	var abajo := E.fila(8)
	v.add_child(abajo)
	var guardada: Mundo = Partida.cargar(ui.GUARDADO) if ui._hay_guardada() else null
	if guardada != null and guardada.carrera_jugador != null:
		var j := guardada.carrera_jugador.jugador(guardada)
		var bc := E.boton(Idiomas.t("▶  Continuar la carrera de %s") % (j.nombre if j != null else Idiomas.t("tu jugador")), E.MENTA, func() -> void:
			ui.mundo = guardada
			ui.carrera = guardada.carrera_jugador
			ui._pintar_semana(), 44)
		bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		abajo.add_child(bc)
	abajo.add_child(E.boton("◂  Volver al menú", E.SUAVE, ui._salir, 44))
	Idiomas.traducir_arbol(ui._cuerpo)
	E.enfocar(ui._cuerpo)

## Paso 2: tres clubes te ofrecen tu primer contrato.
static func pintar_ofertas(ui: Variant, clubes: Array) -> void:
	ui._limpiar()
	var m: Mundo = ui.mundo
	var j: Jugador = ui.carrera.jugador(m)
	var v := _marco(ui, 1040.0)
	v.add_child(E.rotulo("TU PRIMER CONTRATO", E.ORO))
	v.add_child(E.titulo(38 if E.estrecho(ui) else 60, E.TEXTO, "TRES CLUBES TE QUIEREN"))
	v.add_child(E.lbl(15, E.SUAVE, Idiomas.t("%s, tres ojeadores te vieron en el torneo juvenil. Ninguno es un grande: aquí se empieza desde abajo. Elige dónde empieza tu ruta.") % j.nombre))
	var angosto := E.estrecho(ui)
	var f := E.reparto(angosto, 10 if angosto else 14)
	v.add_child(f)
	var paises: Dictionary = Selecciones._tabla_paises()
	for cl: Club in clubes:
		var tono := E.de_club(cl)
		var p := E.tarjeta(tono, E.TINTA.lerp(tono, 0.12))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.add_child(p)
		var pv := E.columna(8)
		p.add_child(pv)
		var esc := E.escudo(cl, 52 if angosto else 96)
		esc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pv.add_child(esc)
		var n := E.titulo(30, E.TEXTO, Nombres.visible(cl.nombre))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		pv.add_child(n)
		var liga := CarreraRuta._liga_de(m, cl)
		var donde := E.lbl(13, E.SUAVE, "%s · %s" % [Idiomas.t(String(paises.get(cl.pais, cl.pais))), Nombres.visible(liga.nombre) if liga != null else ""], true)
		donde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		donde.clip_text = true
		pv.add_child(donde)
		## Cuántos de tu línea te ganan hoy el puesto: lo difícil que es jugar.
		var delante := 0
		for o: Jugador in cl.plantilla:
			if o != j and o.pos == j.pos and o.media_en(o.pos_e) > j.media_en(j.pos_e):
				delante += 1
		var cif := E.fila(4)
		pv.add_child(cif)
		cif.add_child(E.cifra(str(cl.rep), "prestigio", E.legible(tono), 30))
		cif.add_child(E.cifra(str(delante), "por delante de ti", E.CORAL if delante >= 3 else E.MENTA, 30))
		pv.add_child(E.boton("FIRMAR", tono, func() -> void: ui._firmar(cl), 48, true))
	v.add_child(E.lbl(12, E.SUAVE, "«Por delante de ti»: los de tu línea que hoy te ganan el puesto. Menos competencia, más minutos; más prestigio, más escaparate."))
	Idiomas.traducir_arbol(ui._cuerpo)
	E.enfocar(ui._cuerpo)

## EL RETIRO (MEGAPLAN fase 3): tu carrera en una página y, si quieres, el
## banquillo. Una vida entera en una partida: dirigirás en el mismo mundo.
static func pintar_retiro(ui: Variant) -> void:
	ui._limpiar()
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var j := c.jugador(m)
	var v := _marco(ui, 900.0)
	v.add_child(E.rotulo("EL ÚLTIMO PARTIDO", E.ORO))
	v.add_child(E.titulo(34 if E.estrecho(ui) else 56, E.TEXTO, Idiomas.t("👟 %s CUELGA LAS BOTAS") % (j.nombre.to_upper() if j != null else "")))
	var cif := E.fila(8)
	v.add_child(cif)
	cif.add_child(E.cifra(str(c.temporadas.size()), "temporadas"))
	cif.add_child(E.cifra(str(c.pj_carrera), "partidos"))
	cif.add_child(E.cifra(str(c.goles_carrera), "goles", E.ORO))
	cif.add_child(E.cifra(str(c.caps), "con la selección"))
	cif.add_child(E.cifra(str(CarreraRuta.nivel(c)), Idiomas.t(String(CarreraRuta.capitulo(c)[1])), E.MENTA))
	var clubes: Array = c.clubes_pasados.duplicate()
	var actual := c.club(m)
	if actual != null and not clubes.has(actual.nombre):
		clubes.append(actual.nombre)
	v.add_child(E.lbl(15, E.SUAVE, Idiomas.t("Clubes: %s") % ", ".join(clubes.map(func(x: Variant) -> String: return Nombres.visible(String(x))))
		+ ("  ·  " + Idiomas.t("fuiste capitán") if c.capitan else "")))
	var p := E.tarjeta(E.CORAL)
	v.add_child(p)
	var pv := E.columna(8)
	p.add_child(pv)
	pv.add_child(E.rotulo(Idiomas.t("TE OFRECEN EL BANQUILLO") + ("" if c.licencia else "  " + Idiomas.t("(harás el curso acelerado de la licencia)")), E.CORAL))
	pv.add_child(E.lbl(13, E.SUAVE, "Dirigirás en este mismo mundo, con tu carrera de jugador como currículum. Se abre como tu partida de entrenador (la que tuvieras se guarda como respaldo)."))
	var ofertas: Array = c.ofertas_de_banquillo(m)
	if ofertas.is_empty():
		pv.add_child(E.lbl(15, E.TEXTO, "Ningún club te ofrece el banquillo por ahora."))
	for cl: Club in ofertas:
		pv.add_child(E.boton(Idiomas.t("📋  Dirigir a %s (reputación %d)") % [Nombres.visible(cl.nombre), cl.rep], E.ORO, func() -> void: ui._ser_entrenador(cl), 46))
	v.add_child(E.boton("🏠  Retirarme del fútbol (volver al menú)", E.SUAVE, ui._retiro_final, 44))
	Idiomas.traducir_arbol(ui._cuerpo)
	E.enfocar(ui._cuerpo)
