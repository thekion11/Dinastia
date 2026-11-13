class_name RutaHoy
extends RefCounted
## «HOY»: la pantalla de la semana de La Ruta. A la izquierda el día de partido
## (con sus retos) y el entreno; a la derecha lo que hay que decidir, las
## ofertas, el duelo con tu rival y lo que dice la grada.

const E := preload("res://ui/carrera/ruta_estilo.gd")

static func pintar(ui: Variant, j: Jugador, club: Club) -> Control:
	var cols := E.fila(14)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc)
	var izq := E.columna(12)
	sc.add_child(izq)
	if not ui.carrera.convocatoria.is_empty():
		izq.add_child(_seleccion(ui))
	izq.add_child(_partido(ui, j, club))
	izq.add_child(_entreno(ui, j))
	var sc2 := ScrollContainer.new()
	sc2.custom_minimum_size = Vector2(390, 0)
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cols.add_child(sc2)
	var der := E.columna(12)
	sc2.add_child(der)
	der.add_child(_decision(ui))
	for o: Control in _ofertas(ui):
		der.add_child(o)
	der.add_child(RutaCamino.duelo(ui, false))
	der.add_child(RutaCamino.grada(ui, 3))
	return cols

# ---------------------------------------------------------------- el partido

static func _seleccion(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta(E.ORO, E.TINTA.lerp(E.ORO, 0.08))
	var v := E.columna(6)
	p.add_child(v)
	v.add_child(E.rotulo("🌎 FECHA FIFA · ¡CONVOCADO!", E.ORO))
	v.add_child(E.titulo(30, E.TEXTO, "%s  vs  %s" % [String(c.convocatoria["nombre"]), String(c.convocatoria["rival"])]))
	v.add_child(E.lbl(13, E.SUAVE, Idiomas.t("Partidos con la selección: %d  ·  goles: %d") % [c.caps, c.goles_sel], true))
	var f := E.fila(8)
	v.add_child(f)
	var b := E.boton("🎮  JUGAR CON LA SELECCIÓN", E.ORO, ui._jugar_seleccion, 48, true)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f.add_child(b)
	f.add_child(E.boton("⏩  Simular", E.CIELO, ui._simular_seleccion, 48))
	return p

static func _equipo(cl: Club, derecha: bool) -> Control:
	var h := E.fila(12)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.alignment = BoxContainer.ALIGNMENT_END if derecha else BoxContainer.ALIGNMENT_BEGIN
	var n := E.titulo(30, E.TEXTO, Nombres.visible(cl.nombre))
	n.clip_text = true
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if derecha else HORIZONTAL_ALIGNMENT_RIGHT
	if derecha:
		h.add_child(E.escudo(cl, 72))
		h.add_child(n)
	else:
		h.add_child(n)
		h.add_child(E.escudo(cl, 72))
	return h

static func _partido(ui: Variant, j: Jugador, club: Club) -> Control:
	var m: Mundo = ui.mundo
	var c: CarreraJugador = ui.carrera
	var tono := E.de_club(club)
	var p := E.tarjeta(tono, E.TINTA.lerp(tono, 0.10))
	var v := E.columna(10)
	p.add_child(v)
	if not m.temporada_en_curso():
		v.add_child(E.rotulo("FIN DE TEMPORADA", E.legible(tono)))
		v.add_child(E.titulo(34, E.TEXTO, "La temporada terminó."))
		if c.toca_retirarse(m):
			v.add_child(E.boton("👟  Colgar las botas", E.ORO, ui._pintar_retiro, 52, true))
		else:
			v.add_child(E.boton("🗓  Empezar la temporada siguiente", E.ORO, ui._nueva_temporada, 52, true))
		return p
	var par: Array = ui._partido_de_la_semana(club)
	var copa := not par.is_empty() and CarreraCopa.es_copa(m, par)
	var cab := E.fila(8)
	v.add_child(cab)
	var rot := E.rotulo("DÍA DE PARTIDO" if not par.is_empty() else "SEMANA SIN PARTIDO", E.legible(tono))
	rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(rot)
	if par.is_empty():
		v.add_child(E.titulo(30, E.TEXTO, "Tu club descansa esta jornada."))
		v.add_child(E.boton("⏩  Pasar la semana", E.CIELO, func() -> void: ui._cerrar_semana({}), 50))
		return p
	var titular := c.es_titular(m)
	var disponible := j.disponible()
	if copa:
		cab.add_child(E.chip("🏆 %s · %s" % [m.copa.nombre, Idiomas.t(m.copa.nombre_de_ronda())], E.ORO))
	cab.add_child(E.chip(Idiomas.t("EN CASA") if par[0] == club else Idiomas.t("DE VISITA"), E.SUAVE))
	cab.add_child(E.chip(Idiomas.t("TITULAR") if titular else (Idiomas.t("AL BANCO") if disponible else Idiomas.t("FUERA")), E.MENTA if titular else E.CORAL))
	var duelo := E.fila(14)
	v.add_child(duelo)
	duelo.add_child(_equipo(par[0], false))
	duelo.add_child(E.titulo(26, E.legible(tono), "VS"))
	duelo.add_child(_equipo(par[1], true))
	if copa:
		v.add_child(E.lbl(12, E.SUAVE, "Partido único: si hay empate, prórroga y penales.", true))
	## Los retos del partido.
	var rv := E.columna(4)
	v.add_child(rv)
	rv.add_child(E.rotulo("RETOS DEL PARTIDO"))
	for reto: Dictionary in CarreraRuta.retos(c, m):
		var def: Array = CarreraRuta.RETOS[String(reto["id"])]
		var hecho := bool(reto.get("hecho", false))
		var fr := E.fila(8)
		rv.add_child(fr)
		fr.add_child(E.lbl(15, E.MENTA if hecho else E.SUAVE, "✔" if hecho else "○", true))
		var lt := E.lbl(15, E.SUAVE if hecho else E.TEXTO, String(def[0]), true)
		lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fr.add_child(lt)
		var premio := int(float(int(def[1])) * (1.5 if CarreraRuta.tiene(c, "sangre_fria") else 1.0))
		fr.add_child(E.titulo(18, E.ORO, "+%d XP" % premio))
	var bot := E.fila(8)
	v.add_child(bot)
	if titular:
		var bj := E.boton("🎮  JUGAR EL PARTIDO", E.ORO, ui._jugar_partido, 56, true)
		bj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bot.add_child(bj)
	elif disponible:
		var bb := E.boton("🪑  IR AL BANCO (puedes entrar)", E.ORO, ui._ir_al_banco, 56, true)
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bot.add_child(bb)
	var bs := E.boton("⏩  Simular la semana", E.CIELO, func() -> void: ui._cerrar_semana({}), 56)
	if not titular and not disponible:
		bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(bs)
	return p

# ---------------------------------------------------------------- el entreno

static func _entreno(ui: Variant, j: Jugador) -> Control:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var p := E.tarjeta()
	var v := E.columna(8)
	p.add_child(v)
	var cab := E.fila(8)
	v.add_child(cab)
	var rot := E.rotulo("ENTRENO DE LA SEMANA", E.CIELO)
	rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(rot)
	var toque := CarreraRuta.toque_de_la_semana(c, m)
	if toque >= 0.0:
		cab.add_child(E.chip(Idiomas.t("TOQUE PERFECTO") if toque >= 0.85 else (Idiomas.t("BUEN TOQUE") if toque >= 0.5 else Idiomas.t("TOQUE FLOJO")),
			E.MENTA if toque >= 0.85 else (E.ORO if toque >= 0.5 else E.CORAL)))
	var ff := E.flujo()
	v.add_child(ff)
	var grupo := ButtonGroup.new()
	var focos := CarreraPortero.focos_para(j)
	for f: String in focos:
		var attr := String(focos[f][1])
		var txt := Idiomas.t(String(focos[f][0])) + ("  %d" % int(j.atributos.get(attr, 0)) if attr != "" and j.atributos.has(attr) else "")
		ff.add_child(E.opcion(txt, E.CIELO, grupo, c.foco == f, func() -> void: c.foco = f, 36))
	if toque < 0.0 and c.entreno_semana != m.anio * 60 + m.semana:
		var bt := E.boton("🎯  EL TOQUE: juega el entreno (perfecto = mejora asegurada)", E.MENTA, func() -> void: RutaToque.abrir(ui), 44)
		v.add_child(bt)
	v.add_child(E.rotulo("EL RESTO DE LA SEMANA"))
	var fa := E.flujo()
	v.add_child(fa)
	var grupo_a := ButtonGroup.new()
	var explica := E.lbl(12, E.SUAVE, String(CarreraAgenda.AGENDAS[c.agenda][1]), true)
	for a: String in CarreraAgenda.AGENDAS:
		fa.add_child(E.opcion(String(CarreraAgenda.AGENDAS[a][0]), E.ORO, grupo_a, c.agenda == a, func() -> void:
			c.agenda = a
			explica.text = Idiomas.t(String(CarreraAgenda.AGENDAS[a][1])), 36))
	v.add_child(explica)
	return p

# ---------------------------------------------------------------- decisiones

## Una decisión cada vez (la más antigua), con cuántas quedan.
static func _decision(ui: Variant) -> Control:
	var c: CarreraJugador = ui.carrera
	var p := E.tarjeta(E.CORAL if not c.eventos.is_empty() else Color(0, 0, 0, 0))
	var v := E.columna(8)
	p.add_child(v)
	if c.eventos.is_empty():
		v.add_child(E.rotulo("TE TOCA DECIDIR"))
		v.add_child(E.lbl(14, E.SUAVE, "Nada pendiente. Entrena y juega."))
		return p
	var e: Dictionary = c.eventos[0]
	var cab := E.fila(8)
	v.add_child(cab)
	var rot := E.rotulo("TE TOCA DECIDIR", E.CORAL)
	rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(rot)
	if c.eventos.size() > 1:
		cab.add_child(E.chip(Idiomas.t("+%d en espera") % (c.eventos.size() - 1), E.CORAL))
	var tit := E.titulo(26, E.TEXTO, Idiomas.t(String(e["titulo"])))
	tit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tit)
	var txt := E.lbl(14, E.SUAVE, String(e["texto"]))
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(txt)
	var ops: Array = e["opciones"]
	for k in ops.size():
		var op := k
		var b := E.boton(String(ops[k]["texto"]), E.CORAL, func() -> void:
			ui._msg = Idiomas.t("Decidiste: ") + Idiomas.t(c.resolver(ui.mundo, 0, op))
			ui._pintar_semana(), 42)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
	return p

static func _ofertas(ui: Variant) -> Array:
	var c: CarreraJugador = ui.carrera
	var m: Mundo = ui.mundo
	var out: Array = []
	for i in c.ofertas.size():
		var o: Dictionary = c.ofertas[i]
		var cl: Club = m.clubes.get(String(o["club_id"]))
		if cl == null:
			continue
		var p := E.tarjeta(E.ORO)
		var v := E.columna(6)
		p.add_child(v)
		v.add_child(E.rotulo("✈ OFERTA", E.ORO))
		var f := E.fila(10)
		v.add_child(f)
		f.add_child(E.escudo(cl, 44))
		var t := E.columna(0)
		f.add_child(t)
		t.add_child(E.titulo(24, E.TEXTO, Nombres.visible(cl.nombre)))
		t.add_child(E.lbl(13, E.SUAVE, Idiomas.t("%s/sem · %d sem para decidir") % [Eco.dinero(int(o["sueldo"])), int(o["semanas"])], true))
		var k := i
		## Cambiar de club no tiene vuelta: doble toque (idea 1027).
		var bo := E.boton("Fichar", E.ORO, Callable(), 40)
		DobleToque.conectar(bo, Idiomas.t("¿Fichar por %s? Toca otra vez") % Nombres.visible(cl.nombre), func() -> void:
			if c.aceptar_oferta(m, k):
				ui._msg = Idiomas.t("¡Fichaste por %s!") % Nombres.visible(c.club(m).nombre)
			ui._pintar_semana())
		v.add_child(bo)
		out.append(p)
	return out
