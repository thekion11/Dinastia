extends "res://ui/pantallas/pantalla_club_vida_p2.gd"
## (Parte 3 de 4 de `pantalla_club_vida.gd`.)

func _pintar_entrenamiento(c: Club) -> void:
	p._limpiar(p._lista_entren)
	var e := p.mundo.entrenamiento
	if e == null:
		return
	_pintar_ambiente_y_horario()
	_pintar_pretemporada(c, e)
	_pintar_mentorias(c, e)
	_pintar_entrenamiento_individual(c, e)
	_pintar_amistosos(c)

	## LA ROTACIÓN Y EL VIDEOANÁLISIS. Los dos son preparación: se deciden antes
	## de saber cómo va el partido, que es lo que los diferencia de todo lo demás
	## de esta pantalla.
	p._lista_entren.add_child(HSeparator.new())
	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = Idiomas.t("🔁 ROTACIÓN Y VIDEOANÁLISIS")
	p._lista_entren.add_child(tr)
	var fila_r := HBoxContainer.new()
	fila_r.add_theme_constant_override("separation", 8)
	p._lista_entren.add_child(fila_r)
	var et_r := p._texto(12, Principal.COL_TEXTO)
	et_r.text = Idiomas.t("Rotación automática")
	et_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	et_r.tooltip_text = Idiomas.t("En las semanas cargadas, los que lleguen por debajo de %d de físico dejan sitio a los frescos de su puesto.") % Mundo.FISICO_PARA_TITULAR
	fila_r.add_child(et_r)
	var b_r := Button.new()
	b_r.text = "SÍ" if p.mundo.rotacion_activa else "NO"
	b_r.pressed.connect(func() -> void:
		p.mundo.rotacion_activa = not p.mundo.rotacion_activa
		p._refrescar())
	fila_r.add_child(b_r)
	if not p._modo_experto:
		var ex_r := p._texto(10, Principal.COL_SUAVE)
		ex_r.text = Idiomas.t("Con liga, copa y continental en la misma quincena, el plantel llega a treinta de físico y no hay forma de evitarlo alineando a mano cada jornada.")
		ex_r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ex_r)

	var b_v := Button.new()
	b_v.text = Idiomas.t("📽️ Videoanálisis del rival de esta semana") if p.mundo.puede_analizar() \
		else "📽️ Videoanálisis (hecho hace poco)"
	b_v.add_theme_font_size_override("font_size", 11)
	b_v.disabled = not p.mundo.puede_analizar()
	b_v.tooltip_text = Idiomas.t("Cuesta dos de físico a todo el plantel y da un empujón para ESTE partido. Contra un rival mejor que tú vale más.")
	b_v.pressed.connect(func() -> void:
		var p_local := p.mundo.analizar_rival()
		if p_local != "":
			p._escribir("[color=#e05555]No se puede: %s.[/color]" % p_local)
		p._refrescar())
	p._lista_entren.add_child(b_v)
	if p.mundo.bono_analisis > 1.0:
		p._dato("Lección hecha", "+%d%% para el próximo partido" % int(round((p.mundo.bono_analisis - 1.0) * 100.0)),
			Principal.COL_VERDE, p._lista_entren)

	## Lo primero, el resumen de lo que le estás haciendo al plantel esta semana.
	## Es el único número honesto del menú: todo lo demás son etiquetas bonitas.
	var carga: Dictionary = e.carga()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PLAN DE LA SEMANA")
	p._lista_entren.add_child(t)
	var res := p._texto(12, Principal.COL_ROJO if float(carga["riesgo"]) > 9.0 else (Principal.COL_ORO if float(carga["riesgo"]) > 7.0 else Principal.COL_VERDE))
	res.text = Idiomas.t("Físico %+.1f  ·  progreso %+.1f  ·  riesgo de lesión %.1f  ·  moral %+.1f") % [
		float(carga["fis"]), float(carga["ovr"]), float(carga["riesgo"]), float(carga["moral"])]
	res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_entren.add_child(res)

	_perilla_texto(p._lista_entren, "Foco", Entrenamiento.FOCOS, e.foco,
		func(k: String) -> void:
			e.fijar_foco(k)
			p._refrescar())
	_perilla_texto(p._lista_entren, "Intensidad", Entrenamiento.INTENSIDADES, e.intensidad,
		func(k: String) -> void:
			e.fijar_intensidad(k)
			p._refrescar())

	## Los días de la semana. Cada uno con su bloque, y se cambia pulsando.
	p._lista_entren.add_child(HSeparator.new())
	var dias: Array = e.nombres_de_dias()
	var catalogo: Array = e.bloques()
	for i in e.dias.size():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila)
		var dia := p._texto(11, Principal.COL_SUAVE)
		dia.text = String(dias[i]) if i < dias.size() else Idiomas.t("Día %d") % (i + 1)
		dia.custom_minimum_size = Vector2(80, 0)
		fila.add_child(dia)
		var b := OptionButton.new()
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for k in catalogo.size():
			var f: Array = catalogo[k]
			b.add_item("%s  %s" % [String(f[2]), String(f[1])])
			b.set_item_metadata(k, String(f[0]))
			if String(f[0]) == e.dias[i]:
				b.select(k)
		b.item_selected.connect(func(idx: int) -> void:
			e.fijar_dia(i, String(b.get_item_metadata(idx)))
			p._refrescar())
		fila.add_child(b)

	## Y el árbol de habilidades del jugador seleccionado. Va aquí y no en la
	## ficha porque es una decisión de entrenamiento, no un dato del jugador.
	p._lista_entren.add_child(HSeparator.new())
	var t2 := p._texto(11, Principal.COL_SUAVE)
	if p._seleccionado == null:
		t2.text = Idiomas.t("HABILIDADES  ·  elige un jugador en el plantel")
		p._lista_entren.add_child(t2)
		return
	var j := p._seleccionado
	t2.text = (Idiomas.t("HABILIDADES DE %s  ·  %d punto") if e.puntos(j) == 1 else Idiomas.t("HABILIDADES DE %s  ·  %d puntos")) % [
		j.nombre.to_upper(), e.puntos(j)]
	p._lista_entren.add_child(t2)
	var suyas: Array = e.habilidades(j)
	if not suyas.is_empty():
		var ya := p._texto(12, Principal.COL_VERDE)
		var nombres: Array[String] = []
		for k: String in suyas:
			nombres.append(e.nombre_habilidad(k))
		ya.text = Idiomas.t("Ya sabe: ") + ", ".join(nombres)
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ya)
	for clave: String in e.disponibles(j):
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 8)
		p._lista_entren.add_child(fila2)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = e.nombre_habilidad(clave)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila2.add_child(nom)
		var motivo := e.motivo(j, clave)
		if motivo == "":
			var b2 := Button.new()
			b2.text = Idiomas.t("Aprender")
			b2.add_theme_font_size_override("font_size", 11)
			b2.pressed.connect(func() -> void: _aprender(j, clave))
			fila2.add_child(b2)
		else:
			## Se dice POR QUÉ no puede, no solo que no puede: sin el motivo, el
			## jugador prueba a ciegas y el árbol parece roto.
			var no := p._texto(11, Principal.COL_SUAVE)
			no.text = motivo
			fila2.add_child(no)

## LA FEDERACIÓN: el reglamento vigente y la votación pendiente.
## `vFederacion()` del HTML tiene cuatro bloques y en Godot solo se veía uno
## (reglamento y votación). Los otros tres estaban ESCRITOS Y CORRIENDO en
## `federacion.gd` desde hace tiempo, sin una sola línea que los enseñara:
## `requisitos_licencia()`/`auditoria_anual()` (te pueden denegar la licencia y
## dejarte sin cupo internacional), `casos`/`apelar()` (el tribunal) y
## `controles` (antidopaje). El caso más sangrante: al abrir un caso, el propio
## motor emite la noticia "Puedes apelar desde Federación" -una pantalla que no
## existía-. Le prometía al jugador algo que no podía cumplir.
## EL HISTORIAL DE LA FEDERACIÓN: cómo has votado y cómo te tratan los árbitros.
## `Federacion` guardaba las dos cosas desde el porte —`votos` y
## `enojo_arbitral`— y no se veían por ningún lado, así que el jugador no podía
## saber por qué le pitaban cada vez peor.
func _pintar_historial_federacion(f: Federacion) -> void:
	p._lista_fed.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("RELACIÓN CON EL ARBITRAJE")
	p._lista_fed.add_child(t)
	## El enojo arbitral sube cada vez que apelas y pierdes, y baja la
	## probabilidad de que te acojan la siguiente. Es un coste ACUMULADO y
	## escondido: verlo es lo que hace que apelar sea una decisión y no un botón.
	var e := f.enojo_arbitral
	p._dato("Apelaciones perdidas acumuladas", str(e),
		Principal.COL_ROJO if e >= 3 else (Principal.COL_ORO if e > 0 else Principal.COL_VERDE), p._lista_fed)
	var frase := p._texto(11, Principal.COL_SUAVE)
	if e == 0:
		frase.text = Idiomas.t("El tribunal no tiene nada anotado contra el club. Las apelaciones salen a precio normal.")
	elif e < 3:
		frase.text = Idiomas.t("Ya han quedado constancias de que el club recurre. Cada apelación nueva es un poco más difícil.")
	else:
		frase.text = Idiomas.t("El tribunal considera que el club abusa del recurso: apelar ahora sale muy caro y casi nunca prospera.")
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_fed.add_child(frase)
	p._dato("Peso político en la asamblea", str(f.aliados),
		Principal.COL_VERDE if f.aliados > 0 else (Principal.COL_ROJO if f.aliados < 0 else Principal.COL_SUAVE), p._lista_fed)

	if f.votos.is_empty():
		return
	p._lista_fed.add_child(HSeparator.new())
	var tv := p._texto(11, Principal.COL_SUAVE)
	tv.text = Idiomas.t("HISTORIAL DE VOTACIONES")
	p._lista_fed.add_child(tv)
	for i in mini(8, f.votos.size()):
		var v: Dictionary = f.votos[i]
		var paso := bool(v.get("pasa", false))
		var vote_a := bool(v.get("vote_a", false))
		## Lo interesante no es si la moción pasó, sino si TÚ estabas del lado
		## que ganó: eso es lo que mide tu peso real en la liga.
		var acerte := paso == vote_a
		p._dato(String(v.get("t", "")),
			"%s  ·  %s" % ["aprobada" if paso else "rechazada", Idiomas.t("votaste a favor") if vote_a else Idiomas.t("votaste en contra")],
			Principal.COL_VERDE if acerte else Principal.COL_SUAVE, p._lista_fed)

func _apelar_caso(id_caso: String) -> void:
	var r := p.mundo.federacion.apelar(id_caso, p.mundo.mi_club(),
		p.mundo.roles.prestigio if p.mundo.roles != null else 50)
	p._escribir("[color=#c9a227][b]⚖️ Apelación.[/b][/color] %s" % r)
	p._anotar("⚖️ Apelación.", r)
	p._refrescar()

func _pintar_licencia_y_tribunal(c: Club, f: Federacion) -> void:
	var col_lic := Principal.COL_VERDE
	if f.licencia == "condicional":
		col_lic = Principal.COL_ORO
	elif f.licencia == "denegada":
		col_lic = Principal.COL_ROJO
	var tl := p._texto(11, Principal.COL_SUAVE)
	tl.text = Idiomas.t("LICENCIA DE CLUB")
	p._lista_fed.add_child(tl)
	var est := p._texto(14, col_lic)
	est.text = f.licencia.to_upper()
	p._lista_fed.add_child(est)
	var cumple := 0
	var reqs := f.requisitos_licencia(c, p.mundo.obras)
	for r: Dictionary in reqs:
		var ok := bool(r["ok"])
		if ok:
			cumple += 1
		p._dato("%s  %s" % ["✅" if ok else "❌", String(r["t"])], String(r["det"]),
			Principal.COL_VERDE if ok else Principal.COL_ROJO, p._lista_fed)
	var resumen := p._texto(11, Principal.COL_SUAVE)
	resumen.text = Idiomas.t("Cumples %d de %d requisitos. Uno o dos incumplimientos son un aviso y te dejan sin cupo internacional; tres o más, multa y licencia denegada.") % [cumple, reqs.size()]
	resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_fed.add_child(resumen)
	p._lista_fed.add_child(HSeparator.new())

	var tt := p._texto(11, Principal.COL_SUAVE)
	tt.text = Idiomas.t("TRIBUNAL DE DISCIPLINA")
	p._lista_fed.add_child(tt)
	if f.casos.is_empty():
		var sin := p._texto(12, Principal.COL_SUAVE)
		sin.text = Idiomas.t("Sin expedientes abiertos. Tampoco te has metido en líos.")
		p._lista_fed.add_child(sin)
	else:
		for caso: Dictionary in f.casos:
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 8)
			p._lista_fed.add_child(fila)
			var firme := String(caso.get("estado", "firme")) == "firme"
			var l := p._texto(12, Principal.COL_TEXTO if firme else Principal.COL_SUAVE)
			l.text = Idiomas.t("%s  ·  %s  ·  %d fecha(s)  ·  %s") % [
				String(caso.get("nombre", "?")), String(caso.get("motivo", "")),
				int(caso.get("fechas", 0)), String(caso.get("estado", ""))]
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila.add_child(l)
			## Apelar una vez por caso, como manda `apelar()`: el segundo intento
			## lo rechaza ella misma, pero un botón que no se puede pulsar dice
			## la verdad mejor que un mensaje de error.
			if firme and not bool(caso.get("apelado", false)):
				var id_caso := String(caso.get("id", ""))
				p._boton("Apelar", func() -> void: _apelar_caso(id_caso), fila)
	p._lista_fed.add_child(HSeparator.new())

	if not f.controles.is_empty():
		var tc := p._texto(11, Principal.COL_SUAVE)
		tc.text = Idiomas.t("CONTROLES ANTIDOPAJE")
		p._lista_fed.add_child(tc)
		for i in mini(6, f.controles.size()):
			var ctrl: Dictionary = f.controles[f.controles.size() - 1 - i]
			var positivo := bool(ctrl.get("positivo", false))
			p._dato("%s  (S%d/%d)" % [String(ctrl.get("nombre", "?")), int(ctrl.get("semana", 0)), int(ctrl.get("anio", 0))],
				"POSITIVO" if positivo else "negativo", Principal.COL_ROJO if positivo else Principal.COL_VERDE, p._lista_fed)
		p._lista_fed.add_child(HSeparator.new())

func _bono_staff(c: Club) -> void:
	var liga := p._liga_de(c)
	var puesto := 1
	var tabla := liga.tabla()
	for fila: Dictionary in tabla:
		if fila["club"] == c:
			break
		puesto += 1
	var r := p.mundo.staff.repartir_bono(c, p.mundo.anio, puesto, tabla.size())
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	else:
		Sonido.toca("moneda")
		p._escribir("[color=#4caf6d][b]Bono al cuerpo técnico.[/b][/color] %s repartidos entre %d escalón(es) yendo %d.º: la moral del plantel sube %d puntos." % [
			p._dinero(int(r["coste"])), int(r["escalones"]), puesto, int(r["moral"])])
		p._anotar("Bono al cuerpo técnico.", "%s repartidos. La moral del plantel sube %d puntos." % [
			p._dinero(int(r["coste"])), int(r["moral"])])
	p._refrescar()

func _renovar(j: Jugador, con_clausula: bool) -> void:
	var r := p.mundo.cantera.renovar(j, con_clausula)
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo renovar: %s.[/color]" % String(r["error"]))
	else:
		p._escribir("[color=#4caf6d]RENOVADO: %s.[/color] %d temporadas a %s/sem%s." % [
			j.nombre, int(r["anios"]), p._dinero(int(r["sueldo"])),
			" con cláusula de %s" % p._dinero(int(r["clausula"])) if con_clausula else ""])
		Sonido.toca("fichaje")
	p._refrescar()

## C15: EL GOBIERNO DEL PAÍS. Partidos y personas inventados; la estructura
## del Estado y los plazos, reales.
func _pintar_gobierno(c: Club) -> void:
	if p.mundo.politica == null:
		return
	var g := p.mundo.politica.gobierno(c.pais, p.mundo.anio)
	var pos: Array = Politica.POSTURAS[String(g["postura"])]
	var l := p._texto(12, Principal.COL_TEXTO)
	var prox := int(g["proxima"])
	l.text = Idiomas.t("🗳️ Gobierno de %s: %s (%s) · prioridad: %s%s") % [c.pais, String(g["lider"]), String(g["partido"]),
		String(pos[0]).to_lower(), (Idiomas.t(" · elecciones en %d") % prox) if prox > 0 else Idiomas.t(" · sin elecciones nacionales")]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.tooltip_text = String(pos[1])
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	p._lista_fed.add_child(l)
	var b := Button.new()
	b.text = Idiomas.t("🧑‍🏫 ¿Cómo funciona el Estado aquí?")
	b.add_theme_font_size_override("font_size", 13)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void:
		MentorVoz.decir(p, p.mundo, "Cómo se gobierna %s" % c.pais, Politica.explicacion(c.pais)))
	p._lista_fed.add_child(b)
	p._lista_fed.add_child(HSeparator.new())

func _responder_encuesta(indice: int) -> void:
	var r := p.mundo.hinchada.responder_encuesta(indice)
	if r.has("error"):
		return
	var d_animo := int(r["animo"])
	if p.mundo.prensa != null:
		p.mundo.prensa.sumar_animo(d_animo)
	if bool(r["acerto"]):
		p._escribir("[color=#4caf6d][b]📊 Hiciste lo que pedía la mayoría.[/b][/color] El ánimo sube %d y los socios se sienten escuchados." % d_animo)
	else:
		p._escribir("[color=#e05555][b]📊 Fuiste por otro lado.[/b][/color] El ánimo baja %d: la gente había votado otra cosa." % absi(d_animo))
	p._refrescar()
