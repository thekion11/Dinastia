extends "res://ui/pantallas/pantalla_plantel_p1.gd"
## (Parte 2 de 4 de `pantalla_plantel.gd`.)

func _pintar_tactica(c: Club) -> void:
	p._limpiar(p._lista_tactica)
	## El pizarrón va PRIMERO: es lo que se viene a mirar aquí. Las perillas y los
	## interruptores se tocan una vez cada varias semanas; el once se mira cada
	## domingo.
	_pintar_pizarron(c)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("FORMACIÓN")
	p._lista_tactica.add_child(t)
	var forms: Dictionary = Datos.tabla("FORMS")
	var fila_f: HBoxContainer = null
	var i_f := 0
	for nombre_f: String in forms.keys():
		if i_f % 5 == 0:
			fila_f = HBoxContainer.new()
			fila_f.add_theme_constant_override("separation", 4)
			p._lista_tactica.add_child(fila_f)
		var bf := Button.new()
		bf.text = nombre_f
		bf.toggle_mode = true
		bf.button_pressed = c.tactica.formacion == nombre_f
		bf.add_theme_font_size_override("font_size", 11)
		bf.pressed.connect(func() -> void:
			c.tactica.formacion = nombre_f
			## Cambiar de dibujo invalida el once elegido: las ranuras son otras.
			c.limpiar_once()
			p._refrescar())
		fila_f.add_child(bf)
		i_f += 1
	p._lista_tactica.add_child(HSeparator.new())

	## Las seis perillas, con los mismos tres niveles que usa el partido en vivo.
	var perillas := [
		["Mentalidad", "mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"]],
		["Presión", "presion", ["Baja", "Media", "Alta"]],
		["Ritmo", "ritmo", ["Lento", "Medio", "Alto"]],
		["Línea", "linea", ["Baja", "Media", "Adelantada"]],
		["Amplitud", "amplitud", ["Estrecha", "Media", "Abierta"]],
	]
	var tp := p._texto(11, Principal.COL_SUAVE)
	tp.text = Idiomas.t("PIZARRA")
	p._lista_tactica.add_child(tp)
	for p_local: Array in perillas:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila)
		var et := p._texto(12, Principal.COL_SUAVE)
		et.text = String(p_local[0])
		et.custom_minimum_size = Vector2(90, 0)
		fila.add_child(et)
		var prop := String(p_local[1])
		var opciones: Array = p_local[2]
		for n in opciones.size():
			var b := Button.new()
			b.text = String(opciones[n])
			b.toggle_mode = true
			b.button_pressed = int(c.tactica.get(prop)) == n
			b.add_theme_font_size_override("font_size", 11)
			var valor := n
			b.pressed.connect(func() -> void:
				c.tactica.set(prop, valor)
				p._refrescar())
			fila.add_child(b)

	## Los cuatro interruptores. Hasta esta tanda tampoco se guardaban.
	var interruptores := [
		["Salida corta", "salida_corta"], ["Marca al hombre", "marca_al_hombre"],
		["Trampa del fuera de juego", "fuera_de_juego"], ["Tiro lejano", "tiro_lejano"],
	]
	for it: Array in interruptores:
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila2)
		var et2 := p._texto(12, Principal.COL_SUAVE)
		et2.text = String(it[0])
		et2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(et2)
		var prop2 := String(it[1])
		var b2 := Button.new()
		b2.text = "SÍ" if bool(c.tactica.get(prop2)) else "NO"
		b2.add_theme_font_size_override("font_size", 11)
		b2.pressed.connect(func() -> void:
			c.tactica.set(prop2, not bool(c.tactica.get(prop2)))
			p._refrescar())
		fila2.add_child(b2)
	p._lista_tactica.add_child(HSeparator.new())

	_pintar_roles_tacticos(c)
	_pintar_balon_parado(c)

	## `vNormas()` del HTML: el reglamento interno. Va aquí, en Táctica, porque
	## son decisiones del mismo tipo -cómo se dirige al grupo- y ninguna de las
	## dos daba para pestaña propia.
	var tn := p._texto(11, Principal.COL_SUAVE)
	tn.text = Idiomas.t("REGLAMENTO INTERNO")
	p._lista_tactica.add_child(tn)
	for norma: Array in Mundo.NORMAS_DEF:
		var clave := String(norma[0])
		var activa := bool(p.mundo.normas.get(clave, false))
		var fila_n := HBoxContainer.new()
		fila_n.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila_n)
		var en := p._texto(12, Principal.COL_TEXTO if activa else Principal.COL_SUAVE)
		en.text = String(norma[1])
		en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_n.add_child(en)
		var bn := Button.new()
		bn.text = "SÍ" if activa else "NO"
		bn.add_theme_font_size_override("font_size", 11)
		bn.pressed.connect(func() -> void:
			p.mundo.normas[clave] = not bool(p.mundo.normas.get(clave, false))
			p._refrescar())
		fila_n.add_child(bn)
		var dn := p._texto(11, Principal.COL_SUAVE)
		dn.text = String(norma[2])
		dn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(dn)
	p._lista_tactica.add_child(HSeparator.new())

	## EL ONCE. Se marca con un botón por jugador: los once primeros marcados
	## salen. Si el once no llega a once o alguien se lesiona, `Club.once()` se
	## vuelve al automático solo -su propia red de seguridad-, así que aquí no
	## hace falta impedir nada, solo contarlo.
	var to := p._texto(11, Principal.COL_SUAVE)
	to.text = Idiomas.t("EL ONCE  ·  %d de 11 elegidos%s") % [
		c.once_elegido.size(),
		"" if c.once_elegido.size() == 11 else Idiomas.t("   (con menos de once manda el automático)")]
	p._lista_tactica.add_child(to)
	## ALINEACIÓN INDEBIDA A LA VISTA (M-246, 20-10): si el once elegido se salta
	## la ley de cupos del país, se avisa aquí, en la pizarra, antes del partido
	## (y no solo con la multa de la federación después).
	var manual: Array[Jugador] = c._once_manual()
	var infr: Array = LeyesPais.infracciones_once(c, manual) if manual.size() == 11 else []
	if not infr.is_empty():
		var partes: Array[String] = []
		for i: Dictionary in infr:
			partes.append(String(i["texto"]))
		var av := p._texto(12, Color(1.0, 0.45, 0.35))
		av.text = Idiomas.t("⚠ ALINEACIÓN INDEBIDA (ley de %s): %s") % [c.pais, "; ".join(partes)] + "\n" + Idiomas.t(
			"→ el ayudante cambiará a quien haga falta (cumples la ley)" if c.ley_politica != "incumplir"
			else "→ saldrá así y la federación multará (decidiste incumplir)")
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(av)
	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 6)
	p._lista_tactica.add_child(fila_b)
	p._boton("Que lo arme el ayudante", func() -> void:
		c.limpiar_once()
		p._refrescar(), fila_b)
	p._boton("Vaciar", func() -> void:
		c.once_elegido.clear()
		p._refrescar(), fila_b)

	var g := GridContainer.new()
	g.columns = 7
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	p._lista_tactica.add_child(g)
	for enc in ["", "", "NOMBRE", "POS", "MED", "FORMA", "ESTADO"]:
		p._celda(g, enc, Principal.COL_SUAVE, enc in ["MED", "FORMA"], 11)
	var orden := c.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var dentro := c.once_elegido.has(j.id)
		var b := Button.new()
		b.text = "✔" if dentro else "＋"
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = not j.disponible() and not dentro
		b.pressed.connect(func() -> void:
			if dentro:
				c.once_elegido.erase(j.id)
			elif c.once_elegido.size() < 11:
				c.once_elegido.append(j.id)
			p._refrescar())
		g.add_child(b)
		g.add_child(p._retrato(j, 22))
		var col := p.COL_ACENTO if dentro else (Principal.COL_ROJO if not j.disponible() else Principal.COL_TEXTO)
		p._celda(g, j.nombre, col, false, 12)
		p._celda(g, j.pos_e, Principal.COL_SUAVE, false, 11)
		p._celda(g, str(j.ovr), col, true, 12)
		p._celda(g, str(j.forma), Principal.COL_SUAVE, true, 11)
		var estado := "listo"
		if j.lesion > 0:
			estado = "lesionado %d sem" % j.lesion
		elif j.suspension > 0:
			estado = "sancionado %d" % j.suspension
		p._celda(g, estado, Principal.COL_ROJO if not j.disponible() else Principal.COL_SUAVE, false, 11)

	## Al final del todo: la moda de la era y la tabla de lo que te funciona. Van
	## abajo porque son lectura, no mandos: el pizarron y las perillas primero.
	_pintar_moda_tactica(c)

## `vDesafios()` del HTML: el puntaje de la carrera y los ocho desafíos. Se
## eligen al empezar la partida y no cambian, pero hasta hoy, una vez dentro,
## no había forma de recordar cuáles llevabas ni de ver para qué servían -el
## multiplicador es la única razón de elegir uno duro-.
func _pintar_desafios() -> void:
	p._limpiar(p._lista_desafios)
	var p_local := p.mundo.puntaje_carrera()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PUNTAJE DE CARRERA")
	p._lista_desafios.add_child(t)
	var total := p._texto(22, Principal.COL_ORO)
	total.text = p._miles(int(p_local["total"]))
	p._lista_desafios.add_child(total)
	var mult := p._texto(12, Principal.COL_SUAVE)
	mult.text = Idiomas.t("%s de base  ×  %.2f de multiplicador") % [p._miles(int(p_local["base"])), float(p_local["multiplicador"])]
	p._lista_desafios.add_child(mult)
	p._lista_desafios.add_child(HSeparator.new())

	var td := p._texto(11, Principal.COL_SUAVE)
	td.text = Idiomas.t("DE DÓNDE SALE")
	p._lista_desafios.add_child(td)
	p._dato("Títulos  (× 1.000)", "%d  →  %s" % [int(p_local["titulos"]), p._miles(int(p_local["titulos"]) * 1000)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Prestigio  (× 40)", "%d  →  %s" % [int(p_local["prestigio"]), p._miles(int(p_local["prestigio"]) * 40)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Logros  (× 300)", "%d  →  %s" % [int(p_local["logros"]), p._miles(int(p_local["logros"]) * 300)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Temporadas  (× 120)", "%d  →  %s" % [int(p_local["temporadas"]), p._miles(int(p_local["temporadas"]) * 120)], Principal.COL_TEXTO, p._lista_desafios)
	p._lista_desafios.add_child(HSeparator.new())

	var tt := p._texto(11, Principal.COL_SUAVE)
	tt.text = Idiomas.t("LOS OCHO DESAFÍOS")
	p._lista_desafios.add_child(tt)
	var tabla: Variant = Datos.tabla("DESAFIOS")
	if not (tabla is Array):
		return
	for fila: Array in (tabla as Array):
		var clave := String(fila[0])
		var activo := p.mundo.desafios.has(clave)
		var fila_ui := HBoxContainer.new()
		fila_ui.add_theme_constant_override("separation", 8)
		p._lista_desafios.add_child(fila_ui)
		var nom := p._texto(12, Principal.COL_VERDE if activo else Principal.COL_SUAVE)
		nom.text = "%s %s%s" % [String(fila[2]), String(fila[1]), Idiomas.t("   ✓ activo") if activo else ""]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_ui.add_child(nom)
		var x := p._texto(12, Principal.COL_ORO if activo else Principal.COL_SUAVE)
		x.text = "×%.2f" % float(fila[4])
		fila_ui.add_child(x)
		var desc := p._texto(11, Principal.COL_SUAVE)
		desc.text = String(fila[3])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_desafios.add_child(desc)
	if not p.mundo.fin_partida.is_empty():
		p._lista_desafios.add_child(HSeparator.new())
		var fin := p._texto(12, Principal.COL_ROJO)
		fin.text = Idiomas.t("💀 Partida marcada como terminada: cayó la primera derrota con el desafío del invicto activo (semana %d de %d). Puedes seguir jugando, pero el desafío está perdido.") % [
			int(p.mundo.fin_partida.get("semana", 0)), int(p.mundo.fin_partida.get("anio", 0))]
		fin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_desafios.add_child(fin)

## `vFichaClub()`: el plantel de un club cualquiera, con lo que se sabe de él.
## Las medias de los ajenos pasan por el mismo filtro de ojeo que el resto del
## juego -si no lo has visto jugar, no sabes exactamente cuánto vale-.
## `vRivalidades()`: el mapa de a quién le tienes ganas y por qué. No hay un
## contador nuevo detrás: la rivalidad se DEDUCE del cara a cara que `Logros` ya
## lleva partido a partido, más los clásicos de origen. Un contador aparte sería
## otra cosa que mantener al día y que puede desincronizarse.
func _pintar_rivalidades() -> void:
	if p.mundo.logros == null:
		return
	var lista := p.mundo.logros.rivalidades()
	if lista.is_empty():
		return
	p._lista_clubes.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🔥 MAPA DE RIVALIDADES")
	p._lista_clubes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = Idiomas.t("La rivalidad no se declara: se construye. Sube con cada cruce y, sobre todo, con cada derrota.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_clubes.add_child(ex)
	for i in mini(8, lista.size()):
		var f: Dictionary = lista[i]
		var c: Club = f["club"]
		var v := int(f["valor"])
		var h: Dictionary = f["h2h"]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_clubes.add_child(fila)
		fila.add_child(p._escudo(c, 22))
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  ·  %s" % [c.nombre, String(f["nivel"])]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.clip_text = true
		fila.add_child(nom)
		## El cara a cara en crudo, que es lo que justifica el número: quien mira
		## esto quiere saber si le gana o le pierde, no solo cuánto le odia.
		var hh := p._texto(11, Principal.COL_SUAVE)
		hh.text = "%d PJ  ·  %d-%d-%d  ·  %d:%d" % [
			int(h["pj"]), int(h["pg"]), int(h["pe"]), int(h["pp"]), int(h["gf"]), int(h["gc"])]
		hh.custom_minimum_size = Vector2(150, 0)
		fila.add_child(hh)
		var val := p._texto(13, Principal.COL_ROJO if v >= 60 else Principal.COL_ORO)
		val.text = str(v)
		val.custom_minimum_size = Vector2(30, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(val)

## "Es el Superclásico" / "Es el Clásico Universitario" / "Es un clásico tuyo".
func _frase_clasico(a: Club, b: Club) -> String:
	var n := HistoriaClub.nombre_clasico(a.nombre, b.nombre)
	if n == "":
		return "Es un clásico tuyo"
	return "Es " + n if n.begins_with("el ") else "Es el " + n

## C4: la historia del club (generada en la base ficticia, real con el pack).
func _historia_de(club: Club) -> Dictionary:
	var del_pais: Array = []
	for o: Club in p.mundo.clubes.values():
		if o.pais == club.pais:
			del_pais.append(o)
	return HistoriaClub.de(club, del_pais)

func _pintar_ficha_club(club: Club) -> void:
	var t := p._texto(13, Principal.COL_ORO)
	t.text = Idiomas.t("%s  ·  reputación %d  ·  aforo %s") % [club.nombre, club.rep, p._miles(club.estadio_aforo)]
	p._lista_clubes.add_child(t)
	var hi_c := _historia_de(club)
	for linea: String in ["📜 " + HistoriaClub.resumen(hi_c), HistoriaClub.texto_historia(hi_c), HistoriaClub.texto_clasicos(hi_c)]:
		if linea.strip_edges() == "":
			continue
		var hist := p._texto(11, Principal.COL_TEXTO)
		hist.text = linea
		hist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_clubes.add_child(hist)
	var sub := p._texto(11, Principal.COL_SUAVE)
	sub.text = Idiomas.t("%d jugadores  ·  media %.1f  ·  masa salarial %s/sem") % [
		club.plantilla.size(), club.media(), p._dinero(club.masa_salarial())]
	p._lista_clubes.add_child(sub)
	## LO QUE FALTABA DE `vFichaClub()`: la media del MEJOR ONCE, la forma, quién
	## lo entrena y si es clásico tuyo. Mirar la ficha de un rival es prepararse
	## un partido, y la media de la plantilla entera engaña —incluye a los nueve
	## suplentes que no van a jugar—.
	var once := club.once()
	var media_once := 0.0
	for j2 in once:
		media_once += float(j2.ovr)
	if not once.is_empty():
		media_once /= float(once.size())
	p._dato("Media del mejor once", "%.1f" % media_once, Principal.COL_TEXTO, p._lista_clubes)
	if p.mundo.roles != null and club == p.mundo.mi_club() and not p.mundo.roles.dt_empleado.is_empty():
		p._dato("Entrenador", p.mundo.roles.dt_nombre(), Principal.COL_TEXTO, p._lista_clubes)
	## El aviso de clásico: cambia cómo se juega ese partido -aforo, ánimo,
	## presión- y por eso tiene que verse aquí y no solo el día del choque.
	if club != p.mundo.mi_club() and p.mundo.es_clasico(p.mundo.mi_club(), club):
		var cl := p._texto(12, Principal.COL_ORO)
		cl.text = Idiomas.t("⚔️  %s: estadio lleno, prensa encima y el doble de presión.") % _frase_clasico(p.mundo.mi_club(), club)
		cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_clubes.add_child(cl)
	var g := GridContainer.new()
	g.columns = 7
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	p._lista_clubes.add_child(g)
	## Los AÑOS DE CONTRATO son la columna que convierte una plantilla ajena en
	## una lista de la compra: al que le queda uno se le puede precontratar.
	for enc in ["NOMBRE", "POS", "EDAD", "MED", "GOLES", "VALOR", "CONTR."]:
		p._celda(g, enc, Principal.COL_SUAVE, enc in ["EDAD", "MED", "GOLES", "VALOR", "CONTR."], 11)
	var orden := club.plantilla.duplicate()
	orden.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	for j: Jugador in orden:
		var med := str(j.ovr) if club == p.mundo.mi_club() else (
			p.mundo.ojeadores.ovr_texto(j) if p.mundo.ojeadores != null else str(j.ovr))
		p._fila_jugador(g, j,
			[j.nombre, j.pos_e, str(j.edad), med, str(j.goles), p._dinero(j.valor),
				"%d año%s" % [j.anios_contrato, "" if j.anios_contrato == 1 else "s"]],
			[Principal.COL_TEXTO, Principal.COL_SUAVE, Principal.COL_SUAVE, Principal.COL_TEXTO,
				Principal.COL_VERDE if j.goles > 0 else Principal.COL_SUAVE, Principal.COL_SUAVE,
				Principal.COL_ORO if j.anios_contrato <= 1 else Principal.COL_SUAVE])
	p._lista_clubes.add_child(HSeparator.new())

## `vGoleadores()`: la tabla de artilleros del país elegido. Se arma recorriendo
## las plantillas, que es donde viven los goles: no hace falta un registro
## aparte que mantener al día.
func _pintar_goleadores(pais: String) -> void:
	var todos: Array[Jugador] = []
	for l in p.mundo.ligas:
		if l.pais != pais:
			continue
		for club: Club in l.clubes:
			for j: Jugador in club.plantilla:
				if j.goles > 0:
					todos.append(j)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("GOLEADORES  ·  %s") % pais
	p._lista_clubes.add_child(t)
	if todos.is_empty():
		var nada := p._texto(12, Principal.COL_SUAVE)
		nada.text = Idiomas.t("Todavía no hay goles en esta liga.")
		p._lista_clubes.add_child(nada)
		return
	todos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.goles > b.goles)
	var g := GridContainer.new()
	g.columns = 5
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	p._lista_clubes.add_child(g)
	for enc in ["#", "", "JUGADOR", "CLUB", "GOLES"]:
		p._celda(g, enc, Principal.COL_SUAVE, enc == "GOLES", 11)
	for i in mini(15, todos.size()):
		var j: Jugador = todos[i]
		var suyo: Club = p.mundo.clubes.get(j.club_id)
		p._celda(g, str(i + 1), Principal.COL_SUAVE, false, 11)
		g.add_child(p._retrato(j, 22))
		var b := Button.new()
		b.text = j.nombre
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void: p._ver_ficha(j))
		g.add_child(b)
		p._celda(g, suyo.nombre if suyo else "—", Principal.COL_SUAVE, false, 11)
		p._celda(g, str(j.goles), Principal.COL_VERDE, true, 12)
