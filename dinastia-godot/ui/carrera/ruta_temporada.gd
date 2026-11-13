class_name RutaTemporada
extends RefCounted
## EL CIERRE DE TEMPORADA, en pantalla: tus números del año, el duelo con tu
## rival y los premios que te llevaste (`CarreraPremios`). Se enseña una vez.

const E := preload("res://ui/carrera/ruta_estilo.gd")

static func pintar(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var t: Dictionary = CarreraRuta.asegurar(c)["temporada"]
	t["visto"] = true
	var velo := ColorRect.new()
	velo.color = Color(0.01, 0.02, 0.06, 0.92)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	velo.add_child(sc)
	var vista: Vector2 = ui.get_viewport_rect().size
	var centro := CenterContainer.new()
	centro.custom_minimum_size = vista
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(centro)
	var p := E.tarjeta(E.ORO)
	p.custom_minimum_size = Vector2(minf(820.0, vista.x - 24.0), 0)
	centro.add_child(p)
	var v := E.columna(10)
	p.add_child(v)
	v.add_child(E.rotulo(Idiomas.t("FIN DE LA TEMPORADA %d") % int(t.get("anio", 0)), E.ORO))
	v.add_child(E.titulo(34 if E.estrecho(ui) else 48, E.TEXTO, Idiomas.t("TU AÑO EN %s") % Nombres.visible(String(t.get("club", ""))).to_upper()))
	var cif := E.fila(6)
	v.add_child(cif)
	cif.add_child(E.cifra(str(int(t.get("pj", 0))), "partidos"))
	cif.add_child(E.cifra(str(int(t.get("goles", 0))), "goles", E.ORO))
	cif.add_child(E.cifra(str(int(t.get("asist", 0))), "asist."))
	cif.add_child(E.cifra(("%.2f" % float(t.get("nota", 0.0))) if float(t.get("nota", 0.0)) > 0.0 else "—", "nota", E.MENTA))
	cif.add_child(E.cifra("%+d" % int(t.get("sube", 0)), "tu media", E.MENTA if int(t.get("sube", 0)) > 0 else E.SUAVE))
	## El duelo.
	var d: Array = t.get("duelo", [0, 0]) if t.get("duelo") is Array else [0, 0]
	if String(t.get("rival", "")) != "" and d.size() == 2:
		var gano := bool(t.get("gano_duelo", false))
		var fr := E.fila(8)
		v.add_child(fr)
		fr.add_child(E.chip("🥊 " + (Idiomas.t("DUELO GANADO") if gano else Idiomas.t("DUELO PERDIDO")), E.MENTA if gano else E.CORAL))
		var ld := E.lbl(14, E.TEXTO, Idiomas.t("%d a %d contra %s") % [int(d[0]), int(d[1]), String(t["rival"])], true)
		ld.clip_text = true
		ld.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fr.add_child(ld)
	## Los premios.
	v.add_child(E.rotulo("TUS PREMIOS"))
	var premios: Array = t.get("premios", []) if t.get("premios") is Array else []
	var copas: Array = t.get("trofeos", []) if t.get("trofeos") is Array else []
	for tr: Variant in copas:
		var ft := E.fila(10)
		v.add_child(ft)
		ft.add_child(E.titulo(26, E.ORO, "🏆"))
		var nt := E.lbl(16, E.TEXTO, Idiomas.t("Campeón: %s") % Nombres.visible(String((tr as Dictionary).get("nombre", ""))), true)
		nt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nt.clip_text = true
		ft.add_child(nt)
		ft.add_child(E.titulo(20, E.ORO, "+%d XP" % int((tr as Dictionary).get("xp", 0))))
	if premios.is_empty() and copas.is_empty():
		v.add_child(E.lbl(14, E.SUAVE, "Este año no cayó ninguno. El próximo, a por ellos."))
	for id: Variant in premios:
		if not CarreraPremios.PREMIOS.has(String(id)):
			continue
		var def: Array = CarreraPremios.PREMIOS[String(id)]
		var f := E.fila(10)
		v.add_child(f)
		f.add_child(E.titulo(26, E.ORO, "🏅"))
		var tv := E.columna(0)
		f.add_child(tv)
		tv.add_child(E.lbl(16, E.TEXTO, String(def[0]), true))
		var por := E.lbl(12, E.SUAVE, String(def[1]))
		por.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tv.add_child(por)
		if int(def[2]) > 0:
			f.add_child(E.titulo(20, E.ORO, "+%d XP" % int(def[2])))
	if int(t.get("niveles", 0)) > 0:
		v.add_child(E.lbl(14, E.MENTA, Idiomas.t("Los premios te suben a nivel %d.") % CarreraRuta.nivel(c), true))
	v.add_child(E.boton("SEGUIR  ▸", E.ORO, func() -> void: ui._pintar_semana(), 52, true))
	E.entrada(velo)
	return velo

## El palmarés personal (para «Ruta»): cada premio con las veces que lo ganaste.
static func palmares(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta()
	var v := E.columna(6)
	p.add_child(v)
	v.add_child(E.rotulo("🏅 TU PALMARÉS", E.ORO))
	var veces := CarreraPremios.palmares(c)
	var fl := E.flujo(6)
	v.add_child(fl)
	for id: String in CarreraPremios.PREMIOS:
		var n := int(veces.get(id, 0))
		var texto := Idiomas.t(String(CarreraPremios.PREMIOS[id][0])) + (" ×%d" % n if n > 1 else "")
		var ch := E.chip(texto, E.ORO if n > 0 else E.SUAVE)
		ch.modulate.a = 1.0 if n > 0 else 0.55
		ch.tooltip_text = Idiomas.t(String(CarreraPremios.PREMIOS[id][1]))
		fl.add_child(ch)
	return p
