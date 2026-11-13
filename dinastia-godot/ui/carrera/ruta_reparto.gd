class_name RutaReparto
extends RefCounted
## «TU JUEGO» A PANTALLA COMPLETA (13-11-2026, ejemplo del dueño): el reparto de
## los puntos de habilidad que ganas al subir de nivel (`CarreraHabilidad`). Arriba
## tu media y tus puntos; debajo, una columna por habilidad con la cifra en grande,
## cuánto pesa en tu puesto y lo que cuesta subirla un punto; y al final tu media
## en cada puesto, con la opción de entrenar otro.

const E := preload("res://ui/carrera/ruta_estilo.gd")
const NOMBRES := {"rit": "Velocidad", "tir": "Tiro", "pas": "Pase", "reg": "Regate", "def": "Defensa", "fis": "Físico"}

static func nombre(attr: String) -> String:
	return Idiomas.t(String(NOMBRES.get(attr, attr.capitalize())))

static func pintar(ui: Variant, j: Jugador) -> Array:
	return [_cabecera(ui, j), _columnas(ui, j), _puestos(ui, j)]

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

## Arriba del todo: la media general en grande, quién eres y los puntos que te quedan.
static func _cabecera(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var puntos := CarreraHabilidad.puntos(c)
	var p := E.tarjeta(E.ORO if puntos > 0 else Color(0, 0, 0, 0))
	var f := E.fila(18)
	p.add_child(f)
	var media := E.titulo(64 if E.estrecho(ui) else 92, E.ORO, str(j.ovr))
	media.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(media)
	var medio := E.columna(3)
	medio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	medio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	f.add_child(medio)
	medio.add_child(E.rotulo(Idiomas.t("MEDIA GENERAL") + "  ·  " + j.pos_e, E.ORO))
	var nom := E.titulo(22 if E.estrecho(ui) else 34, E.TEXTO, j.nombre.to_upper())
	nom.clip_text = true
	medio.add_child(nom)
	var chips := E.flujo()
	medio.add_child(chips)
	var forma := CarreraEstilo.forma(c, j)
	chips.add_child(E.chip(Idiomas.t("forma %+d") % forma, E.MENTA if forma > 0 else (E.CORAL if forma < 0 else E.SUAVE)))
	chips.add_child(E.chip(Idiomas.t("techo %d") % (CarreraRuta.techo(c, j) + CarreraRuta.MARGEN_TECHO), E.ORO))
	var fe := CarreraEstilo.ficha(c, ui.mundo)
	if fe.size() >= 2:
		chips.add_child(E.chip(Idiomas.t(String(fe[0])), E.CIELO))
	var caja := E.cifra(str(puntos), "puntos de habilidad", E.ORO if puntos > 0 else E.SUAVE, 44 if E.estrecho(ui) else 58)
	caja.size_flags_horizontal = Control.SIZE_SHRINK_END
	caja.tooltip_text = Idiomas.t("Ganas %d cada vez que subes de nivel. Subir un punto cuesta más cuanto más alta está la habilidad, cuanto menos pesa en tu puesto y cuanto más nivel tienes.") % CarreraHabilidad.PUNTOS_POR_NIVEL
	f.add_child(caja)
	return p

const CLASES := {"clave": "clave en tu puesto", "util": "útil en tu puesto", "ajena": "pesa poco en tu puesto"}

## Una columna por ZONA: su promedio en grande y, debajo, sus habilidades con lo que cuesta subir cada una.
static func _columnas(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var g := GridContainer.new()
	g.columns = 1 if E.estrecho(ui) else 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var foco := _foco(ui, j)
	var d := CarreraHabilidad.detalle(c, j)
	var pulidos: Dictionary = CarreraRuta.asegurar(c).get("pulidos", {})
	for zona: String in j.atributos:
		var clase := CarreraHabilidad.clase(j, zona)
		var tono: Color = E.MENTA if clase == "clave" else (E.CIELO if clase == "util" else E.SUAVE)
		var p := E.tarjeta(tono if clase == "clave" else Color(0, 0, 0, 0))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.size_flags_vertical = Control.SIZE_FILL
		g.add_child(p)
		var v := E.columna(4)
		p.add_child(v)
		var cab := E.cifra(str(int(j.atributos[zona])), nombre(zona), E.TEXTO, 52)
		v.add_child(cab)
		var cl := E.lbl(11, tono, ("▸ " + Idiomas.t("lo entrenas esta semana")) if zona == foco else Idiomas.t(String(CLASES[clase])), true)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cl.clip_text = true
		v.add_child(cl)
		for par: Array in CarreraHabilidad.de_zona(zona):
			var hab := String(par[0])
			var fila := E.fila(4)
			v.add_child(fila)
			var ln := E.lbl(12, E.SUAVE, String(par[1]) if CarreraHabilidad.DETALLE.has(zona) else nombre(zona), true)
			ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ln.clip_text = true
			fila.add_child(ln)
			var subido := int(pulidos.get(hab, 0))
			fila.add_child(E.lbl(14, E.MENTA if subido > 0 else E.TEXTO, str(int(d.get(hab, 0))), true))
			if int(d.get(hab, 0)) >= 99:
				continue
			var precio := CarreraHabilidad.coste(c, j, hab)
			var b := E.boton("＋ %d" % precio, E.ORO, func() -> void:
				if CarreraHabilidad.subir(c, ui.mundo, hab):
					E.son("confirmar")
				ui._pintar_semana(), 26)
			b.custom_minimum_size.x = 50
			b.disabled = not CarreraHabilidad.puede_subir(c, ui.mundo, hab)
			b.tooltip_text = E.plural(precio, "Cuesta %d punto de habilidad.", "Cuesta %d puntos de habilidad.") % precio
			fila.add_child(b)
	return g

## «Tu puesto»: con las mismas habilidades, tu media cambia según dónde juegues; y se puede entrenar otro.
static func _puestos(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta()
	var v := E.columna(8)
	p.add_child(v)
	v.add_child(E.rotulo("TU PUESTO Y TU MEDIA", E.CIELO))
	v.add_child(E.lbl(13, E.SUAVE, "Tu media sale de tus habilidades y de tu puesto: con las mismas habilidades vales más o menos según dónde juegues. Entrenar otro puesto cuesta puntos y unas semanas de adaptación."))
	var g := GridContainer.new()
	g.columns = 3 if E.estrecho(ui) else 6
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	var lista: Array = CarreraHabilidad.puestos(j)
	lista.sort_custom(func(x: String, y: String) -> bool: return CarreraHabilidad.media_en(j, x) > CarreraHabilidad.media_en(j, y))
	for pe: String in lista:
		var media := CarreraHabilidad.media_en(j, pe)
		var mio: bool = pe == j.pos_e
		var caja := PanelContainer.new()
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caja.add_theme_stylebox_override("panel", E.caja(Color(E.ORO, 0.14) if mio else E.TINTA2, 12, Color(E.ORO, 0.8) if mio else Color(E.CIELO, 0.2), 8))
		var cv := E.columna(2)
		caja.add_child(cv)
		cv.add_child(E.cifra(str(media), pe, E.ORO if mio else (E.MENTA if media > j.ovr else E.TEXTO), 30))
		if mio:
			cv.add_child(E.lbl(12, E.ORO, "tu puesto", true))
			(cv.get_child(1) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			var precio := CarreraHabilidad.coste_puesto(c, j, pe)
			var b := E.boton(Idiomas.t("Entrenar · %d") % precio, E.CIELO, func() -> void:
				var res := CarreraHabilidad.cambiar(c, ui.mundo, pe)
				if not res.is_empty():
					E.son("sesion_tactica")
					ui._msg = Idiomas.t("Ahora juegas de %s: media %d. Te adaptarás en %d semanas.") % [pe, int(res["despues"]), int(res["semanas"])]
				ui._pintar_semana(), 32)
			b.disabled = not CarreraHabilidad.puede_cambiar(c, ui.mundo, pe)
			cv.add_child(b)
		g.add_child(caja)
	return p

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
