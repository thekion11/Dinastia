extends "res://ui/pantallas/pantalla_club_vida_p1.gd"
## [Capa 2/4 de `pantalla_club_vida.gd`] _pintar_obras, _elegir_pretemporada, _pintar_pretemporada, _pintar_mentorias, _pintar_entrenamiento_individual, _pintar_ambiente_y_horario … (+3)

## Las obras del club, dentro de la pestaña Club.
##
## Se enseña el nivel, lo que hace, lo que cuesta y —si está en marcha— cuántas
## semanas faltan. Ese último dato es el que hace que el sistema tenga sentido:
## las obras no son instantáneas a propósito, así que hay que poder ver en qué
## punto va cada una para decidir qué se empieza después.
func _pintar_obras(c: Club) -> void:
	p._lista_club.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("OBRAS  ·  %d niveles construidos  ·  aforo %s") % [
		p.mundo.obras.construido(), p._miles(c.estadio_aforo)]
	p._lista_club.add_child(t)
	if not p.mundo.obras.obras.is_empty():
		for k: String in p.mundo.obras.obras:
			var falta := int(p.mundo.obras.obras[k])
			var l := p._texto(12, Principal.COL_ORO)
			l.text = (Idiomas.t("  En obra: %s  —  %d semana") if falta == 1 else Idiomas.t("  En obra: %s  —  %d semanas")) % [
				String(Instalaciones.CATALOGO[k][0]), falta]
			p._lista_club.add_child(l)
	for clave: String in Instalaciones.CATALOGO:
		var datos: Array = Instalaciones.CATALOGO[clave]
		var n := p.mundo.obras.nivel(clave)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_club.add_child(fila)
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  %s" % ["*".repeat(n) + ".".repeat(p.mundo.obras.maximo(clave) - n), String(datos[0])]
		if n > 0:
			nom.tooltip_text = Trabajadores.texto_de(c, clave)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		if p.mundo.obras.en_obra(clave):
			var enc := p._texto(11, Principal.COL_ORO)
			enc.text = Idiomas.t("en obra")
			fila.add_child(enc)
		elif n >= p.mundo.obras.maximo(clave):
			var tope := p._texto(11, Principal.COL_VERDE)
			tope.text = Idiomas.t("al máximo")
			fila.add_child(tope)
		else:
			var precio := p.mundo.obras.coste(clave, c.rep)
			var b := Button.new()
			b.text = Idiomas.t("Construir  %s  (%d sem)") % [p._dinero(precio), p.mundo.obras.semanas_de(clave)]
			b.add_theme_font_size_override("font_size", 11)
			b.disabled = precio > c.saldo or (p.mundo.roles != null and not p.mundo.roles.puede_construir())
			b.pressed.connect(func() -> void: _empezar_obra(clave))
			fila.add_child(b)
		var que := p._texto(11, Principal.COL_SUAVE)
		que.text = "    " + String(datos[1])
		if n > 0 and p.mundo.trabajadores != null:
			## El equipo entero, con habilidad y ánimo (26-9-2026).
			que.text += "\n    👥 " + p.mundo.trabajadores.texto_equipo(c, p.mundo.obras, clave).replace("\n", "\n    👥 ")
		que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_club.add_child(que)

func _elegir_pretemporada(clave: String, c: Club) -> void:
	var err := p.mundo.entrenamiento.elegir_pretemporada(clave, c, p.mundo.anio, p.mundo.semana)
	if err != "":
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
	else:
		p._escribir("[color=#4caf6d][b]Pretemporada elegida.[/b][/color] El plantel arranca el año con ella.")
	p._refrescar()

## EL DESPACHO DEL ENTRENADOR: el plan de la semana y el árbol de habilidades.
## `vEntrenoPlus()` del HTML, la parte que faltaba: la PRETEMPORADA y la
## CONCENTRACIÓN de la semana. `Entrenamiento.elegir_pretemporada()` estaba
## escrita entera -con su coste, sus efectos de físico y base, y su riesgo de
## romper a alguien- y no la llamaba ninguna pantalla; `concentracion` lo mismo:
## el proceso semanal ya la cobraba y daba +3 de físico, pero no había forma de
## encenderla. Dos decisiones de gestión escritas y apagadas.
func _pintar_pretemporada(c: Club, e: Entrenamiento) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("PRETEMPORADA")
	p._lista_entren.add_child(t)
	if e.pretemporada != "":
		var hecha := p._texto(12, Principal.COL_VERDE)
		var nombre_p := e.pretemporada
		for fila: Array in e.pretemporadas():
			if String(fila[0]) == e.pretemporada:
				nombre_p = String(fila[1])
		hecha.text = Idiomas.t("Ya hecha este año: %s. La próxima, la temporada que viene.") % nombre_p
		hecha.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(hecha)
	else:
		for fila: Array in e.pretemporadas():
			var clave := String(fila[0])
			var coste := Eco.escalar(float(fila[2]), float(c.rep)) if float(fila[2]) > 0.0 else 0
			var fila_p := HBoxContainer.new()
			fila_p.add_theme_constant_override("separation", 8)
			p._lista_entren.add_child(fila_p)
			var lp := p._texto(12, Principal.COL_TEXTO)
			lp.text = String(fila[1])
			lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fila_p.add_child(lp)
			var bp := Button.new()
			bp.text = Idiomas.t("Elegir") if coste == 0 else Idiomas.t("Elegir  %s") % p._dinero(coste)
			bp.add_theme_font_size_override("font_size", 11)
			bp.disabled = coste > c.saldo
			bp.pressed.connect(func() -> void: _elegir_pretemporada(clave, c))
			fila_p.add_child(bp)
			var dp := p._texto(10, Principal.COL_SUAVE)
			dp.text = String(fila[3])
			dp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_entren.add_child(dp)

	## La concentración: se paga cada semana y da físico. Es un grifo abierto,
	## así que se enseña lo que cuesta al lado del interruptor.
	var fila_c := HBoxContainer.new()
	fila_c.add_theme_constant_override("separation", 8)
	p._lista_entren.add_child(fila_c)
	var lc := p._texto(12, Principal.COL_TEXTO if e.concentracion else Principal.COL_SUAVE)
	lc.text = Idiomas.t("Concentrar al plantel cada semana  ·  %s") % p._dinero(Eco.escalar(Entrenamiento.COSTE_CONCENTRACION, float(c.rep)))
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila_c.add_child(lc)
	var bc := Button.new()
	bc.text = "SÍ" if e.concentracion else "NO"
	bc.add_theme_font_size_override("font_size", 11)
	bc.pressed.connect(func() -> void:
		e.concentracion = not e.concentracion
		p._refrescar())
	fila_c.add_child(bc)
	var dc := p._texto(10, Principal.COL_SUAVE)
	dc.text = Idiomas.t("Hotel y trabajo aislado toda la semana: tres puntos de físico para todos, todas las semanas que la dejes puesta.")
	dc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_entren.add_child(dc)
	p._lista_entren.add_child(HSeparator.new())

## MENTORÍAS: un veterano apadrina a un chico. Es lo que hace que un jugador de
## 33 que ya no es titular siga valiendo para algo -y la única forma de que un
## canterano crezca más rápido de lo que le toca-.
func _pintar_mentorias(c: Club, e: Entrenamiento) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("MENTORÍAS  ·  %d de %d") % [e.mentorias.size(), Entrenamiento.MAX_MENTORIAS]
	p._lista_entren.add_child(t)
	for i in e.mentorias.size():
		var m: Dictionary = e.mentorias[i]
		var maestro := p.mundo.jugador_por_id(String(m["maestro"]))
		var pupilo := p.mundo.jugador_por_id(String(m["pupilo"]))
		if maestro == null or pupilo == null:
			continue
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_entren.add_child(fila)
		## Las dos caras, maestro y pupilo: la pareja se entiende de un vistazo.
		fila.add_child(p._retrato(maestro, 24))
		fila.add_child(p._retrato(pupilo, 24))
		var l := p._texto(12, Principal.COL_TEXTO)
		l.text = Idiomas.t("%s (%d) → %s (%d)  ·  %d semanas, +%d de media") % [
			maestro.nombre, maestro.ovr, pupilo.nombre, pupilo.ovr,
			int(m["semanas"]), int(m["subidas"])]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(l)
		var idx := i
		p._boton("Romper", func() -> void:
			e.romper_mentoria(idx)
			p._refrescar(), fila)
	## Para crear una hace falta elegir dos: se usa el jugador seleccionado en la
	## ficha como una de las dos mitades, que es la forma de no inventar un
	## selector nuevo en una pantalla que ya tiene bastante.
	if e.mentorias.size() < Entrenamiento.MAX_MENTORIAS:
		if p._seleccionado == null or p._seleccionado.club_id != c.id:
			var pista := p._texto(11, Principal.COL_SUAVE)
			pista.text = Idiomas.t("Para crear una: pulsa en el plantel a un veterano (%d+ años y %d+ de media) o a un chico (hasta %d), y aquí aparecerá con quién emparejarlo.") % [
				Entrenamiento.MENTOR_EDAD, Entrenamiento.MENTOR_MEDIA, Entrenamiento.PUPILO_EDAD]
			pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_entren.add_child(pista)
		else:
			var sel := p._seleccionado
			var es_mentor := e.puede_ser_mentor(sel)
			var es_pupilo := e.puede_ser_pupilo(sel)
			if not es_mentor and not es_pupilo:
				var no := p._texto(11, Principal.COL_SUAVE)
				no.text = Idiomas.t("%s no puede ser ni maestro (%d+ años y %d+ de media) ni pupilo (hasta %d años).") % [
					sel.nombre, Entrenamiento.MENTOR_EDAD, Entrenamiento.MENTOR_MEDIA, Entrenamiento.PUPILO_EDAD]
				no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p._lista_entren.add_child(no)
			else:
				var papel := "maestro" if es_mentor else "pupilo"
				var tp := p._texto(11, Principal.COL_SUAVE)
				tp.text = Idiomas.t("%s puede ser %s. Empareja con:") % [sel.nombre, papel]
				p._lista_entren.add_child(tp)
				for otro: Jugador in c.plantilla:
					var vale := e.puede_ser_pupilo(otro) if es_mentor else e.puede_ser_mentor(otro)
					if not vale or otro == sel:
						continue
					var fila2 := HBoxContainer.new()
					fila2.add_theme_constant_override("separation", 8)
					p._lista_entren.add_child(fila2)
					var l2 := p._texto(12, Principal.COL_SUAVE)
					l2.text = Idiomas.t("%s  ·  %d años  ·  media %d") % [otro.nombre, otro.edad, otro.ovr]
					l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					fila2.add_child(l2)
					var maestro_f: Jugador = sel if es_mentor else otro
					var pupilo_f: Jugador = otro if es_mentor else sel
					p._boton("Emparejar", func() -> void:
						var err := e.crear_mentoria(maestro_f, pupilo_f)
						if err != "":
							p._escribir("[color=#e05555]No se pudo: %s.[/color]" % err)
						p._refrescar(), fila2)
	p._lista_entren.add_child(HSeparator.new())

## `🎓 ENTRENAMIENTO INDIVIDUAL` del HTML: trabajo específico de cinco a nueve
## semanas para que un jugador aprenda una habilidad de verdad -no puntos de
## entrenador, una habilidad del catálogo `ESPECIALES`-. El motor
## (`asignar_individual`/`plan_de`/`especial`, resuelto cada semana en
## `_trabajo_individual()`) llevaba escrito desde siempre; esta pantalla es la
## que le faltaba.
func _pintar_entrenamiento_individual(c: Club, e: Entrenamiento) -> void:
	p._lista_entren.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🎓 ENTRENAMIENTO INDIVIDUAL  (%d/%d)") % [e.individual.size(), Entrenamiento.MAX_INDIVIDUALES]
	p._lista_entren.add_child(t)
	var intro := p._texto(10, Principal.COL_SUAVE)
	intro.text = Idiomas.t("Trabajo específico para un jugador concreto. En cinco a nueve semanas aprende una habilidad nueva de verdad.")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_entren.add_child(intro)
	## Los que ya tienen plan, con su progreso -igual que el HTML, arriba de la
	## lista de asignar-.
	for j: Jugador in c.plantilla:
		var plan := e.plan_de(j)
		if plan.is_empty():
			continue
		var esp := e.especial(String(plan.get("clave", "")))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_entren.add_child(fila)
		var et := p._texto(11, Principal.COL_TEXTO)
		et.text = "%s — %s" % [j.nombre, String(esp[1]) if esp.size() > 1 else String(plan["clave"])]
		et.clip_text = true
		et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(et)
		var sem := p._texto(11, Principal.COL_SUAVE)
		sem.text = Idiomas.t("%d sem") % int(plan.get("semanas", 0))
		fila.add_child(sem)
		var bc := Button.new()
		bc.text = Idiomas.t("Cancelar")
		bc.add_theme_font_size_override("font_size", 11)
		bc.pressed.connect(func() -> void:
			p.mundo.entrenamiento.asignar_individual(j, String(plan["clave"]))
			p._refrescar())
		fila.add_child(bc)
	## A quién asignar: los catorce con más margen hasta su potencial -no solo
	## los jóvenes, cualquiera que todavía pueda crecer-, igual que `vEntreno()`.
	var tg := p._texto(11, Principal.COL_SUAVE)
	tg.text = Idiomas.t("ASIGNAR A UN JUGADOR")
	p._lista_entren.add_child(tg)
	var candidatos := c.plantilla.duplicate()
	candidatos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return (b.pot - b.ovr) < (a.pot - a.ovr))
	var lleno := e.individual.size() >= Entrenamiento.MAX_INDIVIDUALES
	for j: Jugador in candidatos.slice(0, 14):
		var plan_j := e.plan_de(j)
		var fila_j := HBoxContainer.new()
		fila_j.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila_j)
		var nom := p._texto(11, Principal.COL_SUAVE)
		nom.text = Idiomas.t("%s  (%d años · %d→%d)") % [j.nombre, j.edad, j.ovr, j.pot]
		nom.clip_text = true
		nom.custom_minimum_size = Vector2(170, 0)
		fila_j.add_child(nom)
		var flow_j := HFlowContainer.new()
		flow_j.add_theme_constant_override("h_separation", 4)
		flow_j.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_j.add_child(flow_j)
		for esp2: Array in e.especiales():
			var clave2 := String(esp2[0])
			var be := Button.new()
			be.text = String(esp2[1])
			be.tooltip_text = String(esp2[2]) if esp2.size() > 2 else ""
			be.add_theme_font_size_override("font_size", 10)
			be.toggle_mode = true
			be.button_pressed = (String(plan_j.get("clave", "")) == clave2)
			be.disabled = lleno and plan_j.is_empty()
			be.pressed.connect(func() -> void:
				p.mundo.entrenamiento.asignar_individual(j, clave2)
				p._refrescar())
			flow_j.add_child(be)

## LA ESTACIÓN, EL CLIMA Y EL HORARIO, de `vEntrenoPlus()`. Tres cosas pequeñas
## que juntas hacen que una temporada no sean cuarenta y dos semanas iguales.
##
## El horario es la única que es una DECISIÓN, y de las buenas: cuanto más paga
## la televisión, menos gente va al estadio. No hay opción correcta —depende de
## si te falta caja o te sobra— y eso es exactamente lo que se busca.
func _pintar_ambiente_y_horario() -> void:
	var est := p.mundo.estacion()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("LA SEMANA")
	p._lista_entren.add_child(t)
	p._dato("Estación", "%s %s" % [String(est[1]), String(est[0]).capitalize()], Principal.COL_TEXTO, p._lista_entren)
	p._dato("Tiempo previsto", p.mundo.clima().capitalize(), Principal.COL_TEXTO, p._lista_entren)

	var th := p._texto(11, Principal.COL_SUAVE)
	th.text = Idiomas.t("HORARIO DEL PARTIDO EN CASA")
	p._lista_entren.add_child(th)
	for h: Array in Mundo.HORARIOS:
		var clave := String(h[0])
		var elegido := p.mundo.horario == clave
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila)
		var b := Button.new()
		b.text = "%s  ·  %s" % [String(h[1]), String(h[2])]
		b.toggle_mode = true
		b.button_pressed = elegido
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		b.custom_minimum_size = Vector2(200, 0)
		b.pressed.connect(func() -> void:
			p.mundo.horario = clave
			p._refrescar())
		fila.add_child(b)
		## Los dos números que importan, uno al lado del otro: es la única forma
		## de que la decisión se vea como lo que es, un intercambio.
		var pub := p._texto(11, Principal.COL_VERDE if float(h[3]) >= 1.0 else Principal.COL_ROJO)
		pub.text = Idiomas.t("público ×%.2f") % float(h[3])
		pub.custom_minimum_size = Vector2(90, 0)
		fila.add_child(pub)
		var tv := p._texto(11, Principal.COL_VERDE if float(h[4]) > 1.0 else Principal.COL_SUAVE)
		tv.text = "TV ×%.2f" % float(h[4])
		tv.custom_minimum_size = Vector2(70, 0)
		fila.add_child(tv)
		var d := p._texto(10, Principal.COL_SUAVE)
		d.text = String(h[5])
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.clip_text = true
		## La nota de cada horario es una frase completa ("El horario de la
		## tarde..."), y en una columna angosta se corta a media palabra sin
		## avisar -encontrado con una captura real, queja del usuario ("se
		## siente recortada")-. El tooltip es la frase entera, como ya manda
		## la regla de "clip_text siempre con su texto de repuesto".
		d.tooltip_text = String(h[5])
		fila.add_child(d)
	p._lista_entren.add_child(HSeparator.new())

## LA PRETEMPORADA. Tres formas de llegar a la primera jornada, y hay que elegir
## una: el triangular en casa es gratis y da poco, la gira internacional cuesta
## y se paga sola si el club es grande, y los amistosos con la cantera dan menos
## forma al primer equipo y el doble a los chicos.
##
## Existe porque el hueco entre temporadas era un botón de «siguiente» donde no
## pasaba nada, y llegar a la primera jornada con el plantel frío no se podía
## evitar de ninguna manera.
func _pintar_amistosos(c: Club) -> void:
	p._lista_entren.add_child(HSeparator.new())
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("🧳 PRETEMPORADA")
	p._lista_entren.add_child(t)
	if p.mundo.amistoso_hecho:
		var ya := p._texto(11, Principal.COL_VERDE)
		ya.text = Idiomas.t("✔ Pretemporada jugada. La próxima, al empezar el año que viene.")
		ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ya)
		return
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Una por temporada. No da puntos: da FORMA, que es lo que le falta a un plantel que lleva un mes parado.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_entren.add_child(ex)
	for a: Array in Mundo.AMISTOSOS:
		var clave := String(a[0])
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_entren.add_child(fila)
		var n := p._texto(12, Principal.COL_TEXTO)
		n.text = String(a[1])
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		fila.add_child(n)
		var f := p._texto(11, Principal.COL_ORO)
		f.text = Idiomas.t("+%d forma") % int(a[3])
		f.custom_minimum_size = Vector2(78, 0)
		fila.add_child(f)
		var b := Button.new()
		var coste := Eco.escalar(float(a[2]), float(c.rep)) if float(a[2]) > 0.0 else 0
		b.text = Idiomas.t("gratis") if coste == 0 else p._dinero(coste)
		b.add_theme_font_size_override("font_size", 11)
		b.disabled = coste > c.saldo
		b.custom_minimum_size = Vector2(104, 0)
		b.pressed.connect(func() -> void:
			var p_local := p.mundo.jugar_amistosos(clave)
			if p_local != "":
				p._escribir("[color=#e05555]No se pudo: %s.[/color]" % p_local)
			p._refrescar())
		fila.add_child(b)

## Una perilla de tres o más opciones a partir de un diccionario clave -> [nombre, ...].
func _perilla_texto(padre: VBoxContainer, etiqueta: String, catalogo: Dictionary,
		actual: String, al_cambiar: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	padre.add_child(h)
	var l := p._texto(11, Principal.COL_SUAVE)
	l.text = etiqueta
	l.custom_minimum_size = Vector2(80, 0)
	h.add_child(l)
	for k: String in catalogo:
		var datos: Array = catalogo[k]
		var b := Button.new()
		b.text = String(datos[0])
		b.toggle_mode = true
		b.button_pressed = (k == actual)
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: al_cambiar.call(k))
		h.add_child(b)

func _aprender(j: Jugador, clave: String) -> void:
	var problema := p.mundo.entrenamiento.aprender(j, clave)
	if problema != "":
		p._escribir("[color=#e05555]No puede aprenderla: %s.[/color]" % problema)
		return
	p._escribir("[color=#4caf6d]%s aprende %s.[/color]" % [
		j.nombre, p.mundo.entrenamiento.nombre_habilidad(clave)])
	p._refrescar()
