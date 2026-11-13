class_name RutaReparto
extends RefCounted
## «TU JUEGO» A PANTALLA COMPLETA (13-11-2026, ejemplo del dueño): el reparto de
## los puntos que ganas al subir de nivel. Arriba tu media y los puntos por
## repartir; debajo, una columna por atributo con la cifra en grande y de dónde
## sale (tu estilo, lo que ya repartiste, el entreno y su tope) y su «SUBIR +2».

const E := preload("res://ui/carrera/ruta_estilo.gd")
const NOMBRES := {"rit": "Velocidad", "tir": "Tiro", "pas": "Pase", "reg": "Regate", "def": "Defensa", "fis": "Físico"}

static func nombre(attr: String) -> String:
	return Idiomas.t(String(NOMBRES.get(attr, attr.capitalize())))

static func pintar(ui: Variant, j: Jugador) -> Array:
	return [_cabecera(ui, j), _columnas(ui, j)]

## Las seis cifras en una fila, sin botones: lo que enseña la pestaña «Yo».
static func resumen(ui: Variant, j: Jugador) -> Control:
	var p := E.tarjeta()
	var g := GridContainer.new()
	g.columns = 3 if E.estrecho(ui) else 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	p.add_child(g)
	var foco := _foco(ui, j)
	for k: String in j.atributos:
		g.add_child(E.cifra(str(int(j.atributos[k])), nombre(k), E.ORO if k == foco else E.TEXTO, 34))
	return p

static func _foco(ui: Variant, j: Jugador) -> String:
	return String((CarreraPortero.focos_para(j).get(ui.carrera.foco, ["", ""]) as Array)[1])

static func _cabecera(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var puntos := int(CarreraRuta.asegurar(c)["puntos"])
	var p := E.tarjeta(E.ORO if puntos > 0 else Color(0, 0, 0, 0))
	var f := E.fila(16)
	p.add_child(f)
	f.add_child(E.cifra(str(j.ovr), j.pos_e, E.ORO, 54))
	(f.get_child(0) as Control).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var medio := E.columna(4)
	medio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	medio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(medio)
	medio.add_child(E.rotulo("PUNTOS POR REPARTIR", E.ORO if puntos > 0 else E.SUAVE))
	medio.add_child(E.lbl(13, E.SUAVE, "Cada punto sube 2 un atributo (o aprende un talento). Ganas uno cada vez que subes de nivel."))
	var chips := E.flujo()
	medio.add_child(chips)
	var forma := CarreraEstilo.forma(c, j)
	chips.add_child(E.chip(Idiomas.t("forma %+d") % forma, E.MENTA if forma > 0 else (E.CORAL if forma < 0 else E.SUAVE)))
	chips.add_child(E.chip(Idiomas.t("techo %d") % (CarreraRuta.techo(c, j) + CarreraRuta.MARGEN_TECHO), E.ORO))
	var fe := CarreraEstilo.ficha(c, ui.mundo)
	if fe.size() >= 2:
		chips.add_child(E.chip(Idiomas.t(String(fe[0])), E.CIELO))
	f.add_child(E.cifra(str(puntos), "", E.ORO if puntos > 0 else E.SUAVE, 54))
	(f.get_child(2) as Control).size_flags_horizontal = Control.SIZE_SHRINK_END
	return p

static func _columnas(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var g := GridContainer.new()
	g.columns = 2 if E.estrecho(ui) else 6
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var foco := _foco(ui, j)
	var fe := CarreraEstilo.ficha(c, ui.mundo)
	var del_estilo: Dictionary = fe[2] if fe.size() >= 3 else {}
	var pulidos: Dictionary = CarreraRuta.asegurar(c).get("pulidos", {})
	var tope := mini(99, j.ovr + CarreraRuta.TOPE_SOBRE_MEDIA)
	for k: String in j.atributos:
		var valor := int(j.atributos[k])
		var p := E.tarjeta(E.ORO if k == foco else Color(0, 0, 0, 0))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(p)
		var v := E.columna(3)
		p.add_child(v)
		v.add_child(E.rotulo(nombre(k).to_upper(), E.ORO if k == foco else E.CIELO))
		v.add_child(E.titulo(58, E.CORAL if valor >= tope else E.TEXTO, str(valor)))
		v.add_child(E.barra(float(valor), 99.0, E.ORO if k == foco else E.CIELO, 6))
		if int(del_estilo.get(k, 0)) != 0:
			v.add_child(E.lbl(12, E.CIELO, Idiomas.t("tu estilo %+d") % int(del_estilo[k]), true))
		if int(pulidos.get(k, 0)) != 0:
			v.add_child(E.lbl(12, E.MENTA, Idiomas.t("repartido %+d") % int(pulidos[k]), true))
		if k == foco:
			v.add_child(E.lbl(12, E.ORO, "▸ " + Idiomas.t("lo entrenas esta semana"), true))
		var lt := E.lbl(12, E.CORAL if valor >= tope else E.SUAVE, Idiomas.t("tope del entreno: %d") % tope, true)
		lt.tooltip_text = Idiomas.t("Ya está muy por encima del resto de tu juego: entrena otra cosa.") if valor >= tope else ""
		v.add_child(lt)
		if CarreraTalentos.puede_pulir(c, ui.mundo, k):
			var b := E.boton("SUBIR +2", E.ORO, func() -> void:
				CarreraTalentos.pulir(c, ui.mundo, k)
				ui._msg = Idiomas.t("Gastaste un punto de talento: %s +2.") % nombre(k)
				ui._pintar_semana(), 40)
			b.tooltip_text = Idiomas.t("Gasta un punto de talento en +2 a este atributo.")
			v.add_child(b)
	return g

## «Tu momento»: energía, relación, fama, ánimo y las cifras de la temporada.
static func momento(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta()
	var h := E.reparto(E.estrecho(ui), 18)
	p.add_child(h)
	var b := E.columna(5)
	h.add_child(b)
	b.add_child(E.rotulo("TU MOMENTO", E.CORAL))
	b.add_child(E.medidor("⚡ " + Idiomas.t("Energía"), c.energia, 100, E.MENTA, 140))
	b.add_child(E.medidor("🤝 " + Idiomas.t("Relación con el DT"), c.relacion_dt, 100, E.CORAL, 140))
	b.add_child(E.medidor("⭐ " + Idiomas.t("Fama"), c.fama, 100, E.ORO, 140))
	b.add_child(E.medidor("🙂 " + Idiomas.t("Ánimo"), j.moral, 100, E.CIELO, 140))
	var s: Dictionary = c.stats_temp
	var cif := E.fila(6)
	cif.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(cif)
	cif.add_child(E.cifra(str(int(s["pj"])), "partidos", E.TEXTO, 28))
	cif.add_child(E.cifra(str(int(s["goles"])), "goles", E.ORO, 28))
	cif.add_child(E.cifra(str(int(s["asist"])), "asist.", E.TEXTO, 28))
	cif.add_child(E.cifra(("%.1f" % c.nota_media()) if c.nota_media() > 0.0 else "—", "nota", E.MENTA, 28))
	return p
