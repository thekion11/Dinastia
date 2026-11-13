class_name RutaCamino
extends RefCounted
## «RUTA»: el camino de Promesa a Leyenda, el duelo con tu rival, tus
## temporadas, lo que decidiste y lo que dice la grada.

const E := preload("res://ui/carrera/ruta_estilo.gd")

static func pintar(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var cols := E.fila(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc)
	var izq := E.columna(12)
	sc.add_child(izq)
	izq.add_child(_capitulos(c))
	izq.add_child(_temporadas(ui))
	var sc2 := ScrollContainer.new()
	sc2.custom_minimum_size = Vector2(390, 0)
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc2)
	var der := E.columna(12)
	sc2.add_child(der)
	der.add_child(duelo(ui, true))
	der.add_child(grada(ui, 8))
	der.add_child(_decisiones(c))
	return cols

## El camino: los siete capítulos como estaciones de una línea.
static func _capitulos(c: CarreraJugador) -> Control:
	var p := E.tarjeta(E.ORO)
	var v := E.columna(10)
	p.add_child(v)
	var actual := CarreraRuta.capitulo(c)
	var sig := CarreraRuta.capitulo_siguiente(c)
	v.add_child(E.rotulo("TU RUTA", E.ORO))
	v.add_child(E.titulo(44, E.TEXTO, Idiomas.t(String(actual[1])).to_upper()))
	v.add_child(E.lbl(14, E.SUAVE, String(actual[2])))
	var linea := E.fila(4)
	v.add_child(linea)
	var nivel := CarreraRuta.nivel(c)
	for i in CarreraRuta.CAPITULOS.size():
		var cap: Array = CarreraRuta.CAPITULOS[i]
		var hecho := nivel >= int(cap[0])
		var es_actual := String(cap[1]) == String(actual[1])
		var est := E.columna(2)
		linea.add_child(est)
		var hasta := int(CarreraRuta.CAPITULOS[i + 1][0]) if i + 1 < CarreraRuta.CAPITULOS.size() else int(cap[0])
		var b := E.barra(float(nivel - int(cap[0])), float(maxi(1, hasta - int(cap[0]))), E.ORO if hecho else E.SUAVE, 6)
		if not hecho:
			b.value = 0
		est.add_child(b)
		var l := E.lbl(12, E.ORO if es_actual else (E.TEXTO if hecho else E.SUAVE), Idiomas.t(String(cap[1])), true)
		l.clip_text = true
		est.add_child(l)
		est.add_child(E.lbl(11, E.SUAVE, Idiomas.t("nivel %d") % int(cap[0]), true))
	if not sig.is_empty():
		v.add_child(E.lbl(13, E.SUAVE, Idiomas.t("Siguiente capítulo: %s, al llegar al nivel %d.") % [Idiomas.t(String(sig[1])), int(sig[0])], true))
	var r := CarreraRuta.asegurar(c)
	var cif := E.fila(8)
	v.add_child(cif)
	cif.add_child(E.cifra(str(c.pj_carrera), "partidos"))
	cif.add_child(E.cifra(str(c.goles_carrera), "goles", E.ORO))
	cif.add_child(E.cifra(str(c.caps), "con la selección"))
	cif.add_child(E.cifra(str(int(r["mejor_racha"])), "mejor racha", E.CORAL))
	cif.add_child(E.cifra(str(int(r["duelos_ganados"])), "duelos ganados", E.MENTA))
	return p

static func _temporadas(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta()
	var v := E.columna(6)
	p.add_child(v)
	v.add_child(E.rotulo("TUS TEMPORADAS"))
	var s: Dictionary = c.stats_temp
	var filas: Array = [[Idiomas.t("Ahora"), Nombres.visible(c.club(ui.mundo).nombre), int(s["pj"]), int(s["goles"]), int(s["asist"]), c.nota_media()]]
	for i in range(c.temporadas.size() - 1, -1, -1):
		var t: Dictionary = c.temporadas[i]
		filas.append([str(int(t["anio"])), Nombres.visible(String(t["club"])), int(t["pj"]), int(t["goles"]), int(t["asist"]), float(t["nota"])])
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 4)
	v.add_child(g)
	for cab: String in ["Año", "Club", "PJ", "Goles", "Asist.", "Nota"]:
		g.add_child(E.lbl(12, E.SUAVE, cab, true))
	for f: Array in filas:
		g.add_child(E.lbl(14, E.ORO, String(f[0]), true))
		var club := E.lbl(14, E.TEXTO, String(f[1]), true)
		club.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(club)
		g.add_child(E.lbl(14, E.TEXTO, str(f[2]), true))
		g.add_child(E.lbl(14, E.TEXTO, str(f[3]), true))
		g.add_child(E.lbl(14, E.TEXTO, str(f[4]), true))
		g.add_child(E.lbl(14, E.TEXTO, ("%.2f" % float(f[5])) if float(f[5]) > 0.0 else "—", true))
	return p

## El duelo con tu rival: dos marcadores y quién va ganando.
static func duelo(ui: Variant, grande: bool) -> Control:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var o := CarreraRuta.rival(c, m)
	var p := E.tarjeta(E.CORAL if grande else Color(0, 0, 0, 0))
	var v := E.columna(6)
	p.add_child(v)
	v.add_child(E.rotulo("🥊 TU RIVAL", E.CORAL))
	if o == null:
		v.add_child(E.lbl(14, E.SUAVE, "Todavía no tienes rival en tu liga."))
		return p
	var cl: Club = m.clubes.get(o.club_id)
	var d := CarreraRuta.duelo(c, m)
	var f := E.fila(10)
	v.add_child(f)
	if cl != null:
		f.add_child(E.escudo(cl, 40))
	var t := E.columna(0)
	f.add_child(t)
	t.add_child(E.titulo(24, E.TEXTO, o.nombre))
	t.add_child(E.lbl(12, E.SUAVE, Idiomas.t("%s · %d años · media %d · %s") % [o.pos_e, o.edad, o.ovr, Nombres.visible(cl.nombre) if cl != null else ""], true))
	var mar := E.fila(8)
	v.add_child(mar)
	mar.add_child(E.cifra(str(int(d[0])), "tú", E.MENTA if int(d[0]) >= int(d[1]) else E.TEXTO, 38))
	mar.add_child(E.cifra(str(int(d[1])), "tu rival", E.CORAL if int(d[1]) > int(d[0]) else E.TEXTO, 38))
	var tot := float(maxi(1, int(d[0]) + int(d[1])))
	v.add_child(E.barra(float(d[0]), tot, E.MENTA, 8))
	if grande:
		v.add_child(E.lbl(12, E.SUAVE, "Cada gol vale 3, cada asistencia 2 y suma el doble de tu nota media. Quien gane la temporada se lleva experiencia y fama."))
	return p

static func grada(ui: Variant, cuantas: int) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta()
	var v := E.columna(6)
	p.add_child(v)
	v.add_child(E.rotulo("📣 LA GRADA", E.CIELO))
	var g: Array = CarreraRuta.asegurar(c)["grada"]
	if g.is_empty():
		v.add_child(E.lbl(14, E.SUAVE, "La grada todavía no sabe quién eres. Sal y cuéntaselo."))
	for i in range(g.size() - 1, maxi(-1, g.size() - 1 - cuantas), -1):
		var linea: Dictionary = g[i]
		var l := E.lbl(13, E.TEXTO if i == g.size() - 1 else E.SUAVE, "%s  %s" % [String(linea.get("icono", "")), CarreraRuta.texto_grada(linea)])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	v.add_child(E.lbl(12, E.SUAVE, Idiomas.t("📱 %s seguidores") % E.miles(c.seguidores), true))
	return p

static func _decisiones(c: CarreraJugador) -> Control:
	var p := E.tarjeta()
	var v := E.columna(4)
	p.add_child(v)
	v.add_child(E.rotulo("TUS DECISIONES"))
	if c.historial.is_empty():
		v.add_child(E.lbl(14, E.SUAVE, "Aún no has decidido nada."))
	for i in range(c.historial.size() - 1, maxi(-1, c.historial.size() - 9), -1):
		var h: Dictionary = c.historial[i]
		var l := E.lbl(12, E.SUAVE, "%d/%d · %s → %s" % [int(h["anio"]), int(h["semana"]), Idiomas.t(String(h["titulo"])), Idiomas.t(String(h["eleccion"]))])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	return p
