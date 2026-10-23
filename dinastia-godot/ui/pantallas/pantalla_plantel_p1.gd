extends RefCounted
## [Capa 1/4 de `pantalla_plantel.gd`] _init, _pintar_plantel, _fichar_libre, _pintar_libres, _pintar_pizarron, _pintar_balon_parado … (+2)

## PLANTEL, TÁCTICA Y PARTIDO: la plantilla, los libres, la pizarra, el balón parado, la táctica, los rivales, el calendario, la copa y la negociación.
##
## Sale de `ui/principal.gd` (mapa de metas 15: el archivo pasaba de
## 15.000 líneas). `p` es la pantalla principal: sus ayudantes (`p._texto`,
## `p._boton`...), el mundo (`p.mundo`) y el repintado (`p._refrescar()`).

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _pintar_plantel(c: Club) -> void:
	PanelPlantel.pintar(p._lista_plantel, c, p.mundo, p._orden_plantel, p._orden_plantel_desc, p.COL_ACENTO,
		func(color: Color) -> Color: return p._color_de_paleta(color),
		func(g: GridContainer, j: Jugador, columnas: Array, colores: Array) -> void:
			p._fila_jugador(g, j, columnas, colores),
		func(clave: String) -> void:
			## Nombre y posición se leen de la A a la Z; los números, de mayor a
			## menor. Es lo que uno espera sin pensarlo.
			if p._orden_plantel == clave:
				p._orden_plantel_desc = not p._orden_plantel_desc
			else:
				p._orden_plantel = clave
				p._orden_plantel_desc = clave not in ["nombre", "pos"]
			p._refrescar())

func _fichar_libre(j: Jugador) -> void:
	var idx := p.mundo.libres.find(j)
	if idx < 0:
		return
	var r := p.mundo.fichar_libre(idx, p.mundo.mi_club())
	if r.has("error"):
		p._escribir("[color=#e05555]No se pudo: %s.[/color]" % String(r["error"]))
	elif r.get("rechazado", false):
		if r.get("expulsado", false):
			p._escribir("[color=#c9a227]%s rechaza tu oferta y decide esperar en otro sitio.[/color] Ya no está en el mercado de libres." % j.nombre)
		else:
			p._escribir("[color=#c9a227]%s rechaza tu oferta.[/color] Puedes volver a intentarlo." % j.nombre)
	else:
		Sonido.toca("fichaje")
		p._escribir("[color=#4caf6d]FICHADO LIBRE: %s.[/color] Sin traspaso, con la prima de fichaje ya pagada." % j.nombre)
	p._refrescar()

## `vLibres()`/`nuevoLibre()`/`ficharLibre()` del HTML: futbolistas sin club,
## sin traspaso -solo prima de fichaje y sueldo-. A diferencia del comparador
## y de la lista de objetivos del mercado, el HTML enseña aquí la media Y la
## proyección sin tapar nada -son jugadores disponibles de verdad, no un rival
## que hay que ojear-, así que la fila los muestra directos también.
func _pintar_libres(c: Club) -> void:
	p._limpiar(p._lista_libres)
	if p.mundo.libres.is_empty():
		p.mundo.generar_libres()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("MERCADO DE AGENTES LIBRES  ·  sin traspaso, solo prima de fichaje y sueldo")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_libres.add_child(t)

	## HFlow y no HBox (etapa 1): con 14 posiciones la fila era más ancha que
	## la columna y empujaba la ficha del jugador fuera de la pantalla.
	var filtros := HFlowContainer.new()
	filtros.add_theme_constant_override("h_separation", 6)
	filtros.add_theme_constant_override("v_separation", 6)
	p._lista_libres.add_child(filtros)
	var b_todos := Button.new()
	b_todos.text = Idiomas.t("Todos")
	b_todos.toggle_mode = true
	b_todos.button_pressed = p._libres_filtro == "todos"
	b_todos.pressed.connect(func() -> void: p._libres_filtro = "todos"; _pintar_libres(c))
	filtros.add_child(b_todos)
	for dem: String in Datos.posd().keys():
		var bd := Button.new()
		bd.text = dem
		bd.toggle_mode = true
		bd.button_pressed = p._libres_filtro == dem
		bd.pressed.connect(func() -> void: p._libres_filtro = dem; _pintar_libres(c))
		filtros.add_child(bd)
	p._lista_libres.add_child(HSeparator.new())

	if p.mundo.roles != null and not p.mundo.roles.puede_fichar():
		var av := p._texto(12, Principal.COL_SUAVE)
		av.text = String(p.mundo.roles.motivo_bloqueo("fichar"))
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_libres.add_child(av)
		p._lista_libres.add_child(HSeparator.new())

	var lista := p.mundo.libres.filter(func(j: Jugador) -> bool:
		return p._libres_filtro == "todos" or j.pos_e == p._libres_filtro)
	if lista.is_empty():
		var nada := p._texto(12, Principal.COL_SUAVE)
		nada.text = Idiomas.t("No hay agentes libres de ese puesto ahora mismo.")
		p._lista_libres.add_child(nada)
		return
	for j: Jugador in lista:
		var motivo_bloqueo := p._motivo_fichaje_bloqueado(j)
		var factor_agente := 1.0
		if p.mundo.prensa != null:
			factor_agente = float(p.mundo.prensa.agente_de(j).get("f", 1.0))
		var prima := int(round(float(j.sueldo) * 6.0 * factor_agente))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_libres.add_child(fila)
		var retrato := TextureRect.new()
		retrato.texture = Cara.textura(j, "#2b6b45", "#ffffff", 30)
		retrato.custom_minimum_size = Vector2(30, 30)
		retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(retrato)
		var b_nom := Button.new()
		b_nom.text = "%s  (%s)" % [j.nombre, j.pos_e]
		b_nom.flat = true
		b_nom.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_nom.pressed.connect(func() -> void: p._ver_ficha(j))
		fila.add_child(b_nom)
		var med := p._texto(14, Principal.COL_TEXTO)
		med.text = "%d / %d" % [j.ovr, j.pot]
		fila.add_child(med)
		var boton := Button.new()
		boton.text = Idiomas.t("Ofrecer contrato")
		boton.disabled = motivo_bloqueo != "" or prima > c.saldo
		boton.pressed.connect(func() -> void: _fichar_libre(j))
		fila.add_child(boton)
		var det := p._texto(11, Principal.COL_SUAVE)
		det.text = Idiomas.t("%d años · %s · pide %s/sem · prima %s%s") % [
			j.edad, j.pais, p._dinero(j.sueldo), p._dinero(prima),
			Idiomas.t("  ·  ya dijo que no una vez") if j.rechazos_libre > 0 else ""]
		p._lista_libres.add_child(det)
		if j.motivo_libre != "":
			var mot := p._texto(11, Principal.COL_SUAVE)
			mot.text = j.motivo_libre + "."
			mot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p._lista_libres.add_child(mot)
		p._lista_libres.add_child(HSeparator.new())

## `vTactica()` del HTML: el pizarrón FUERA del partido. Hasta hoy la táctica
## solo se podía tocar EN VIVO, con el reloj corriendo, y el once lo armaba
## siempre el automático: `Club.fijar_once()` existía y no la llamaba ninguna
## pantalla, así que la decisión más básica de un manager -a quién saco- no se
## podía tomar antes de jugar. Y `once_elegido` ni siquiera se guardaba.
## El bloque de roles de `vTacticaAvanzada()`: qué papel le pides a cada titular
## dentro del dibujo. El sistema entero -tabla `ROLES`, aptitud por atributos,
## bonificador agregado y guardado- estaba escrito en `Vestuario` desde hace
## tanto que casi lo doy por muerto: `bonus_roles()` no aparecía en ningún grep
## fuera de su propio archivo. Y sin embargo VIVE, porque `factores()` lo llama
## ahí dentro y `Mundo.aplicar_bonificadores()` lleva el resultado al club. Lo
## único que faltaba era esto: la pantalla para elegirlos.
##
## La aptitud es lo que hace que la decisión importe. No se mide contra el resto
## del plantel sino contra la propia media del jugador: un central de 80 con 90
## de marca es un gran central marcador y un mal central de salida, y el mismo
## número te dice las dos cosas.
## EL PIZARRÓN, de `vTactica()`. La lista de once nombres dice QUIÉN juega; el
## pizarrón dice CÓMO están puestos, que es una información distinta y la que de
## verdad se mira al montar un equipo.
##
## Las coordenadas no se inventan: la tabla `FORMS` que exportó el HTML trae la
## posición de cada ranura en porcentaje del campo (`[puesto, x, y]`), así que
## el dibujo sale de los mismos datos que usa el motor para armar el once. Si un
## día cambia una formación, el pizarrón cambia con ella sin tocar nada aquí.
func _pintar_pizarron(c: Club) -> void:
	## La pizarra con fichas de jugador (cara, anillo, puesto, apellido): ver
	## `ui/componentes/pizarra_tactica.gd`.
	PizarraTactica.pintar(p._lista_tactica, c, p._ver_ficha)

	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("En rojo, el que juega fuera de su puesto: rinde por debajo aunque su media diga otra cosa.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(ex)
	p._lista_tactica.add_child(HSeparator.new())

## LAS JUGADAS ENSAYADAS Y LOS PLANES, de `vTacticaAvanzada()`.
##
## Lo que hace que elegir importe es la EFECTIVIDAD: cada jugada pide unas
## habilidades concretas y el número dice si tienes a la gente para ella. Poner
## "todos al área" sin un cabeceador es tirar los córners a la nada, y aquí se
## ve antes de hacerlo.
func _pintar_balon_parado(c: Club) -> void:
	var once := c.once()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("BALÓN PARADO")
	p._lista_tactica.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("El número es cuánto le va esa jugada a ESTE once: depende de si tienes gente con las habilidades que pide.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(ex)

	for bloque in [["Córners", Tactica.CORNERS, c.tactica.corner, "corner"],
			["Tiros libres", Tactica.LIBRES, c.tactica.libre, "libre"]]:
		var tb := p._texto(11, p.COL_ACENTO)
		tb.text = String(bloque[0]).to_upper()
		p._lista_tactica.add_child(tb)
		var lista: Array = bloque[1]
		var actual := String(bloque[2])
		var prop := String(bloque[3])
		for f: Array in lista:
			var clave := String(f[0])
			var ef := Tactica.efectividad(once, f[3], p.mundo.entrenamiento)
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 6)
			p._lista_tactica.add_child(fila)
			var b := Button.new()
			b.text = String(f[1])
			b.toggle_mode = true
			b.button_pressed = clave == actual
			b.add_theme_font_size_override("font_size", 11)
			b.clip_text = true
			b.custom_minimum_size = Vector2(160, 0)
			b.tooltip_text = String(f[2])
			b.pressed.connect(func() -> void:
				c.tactica.set(prop, clave)
				p._refrescar())
			fila.add_child(b)
			var e := p._texto(11, Principal.COL_VERDE if ef >= 1.1 else (Principal.COL_ROJO if ef < 0.95 else Principal.COL_SUAVE))
			e.text = "×%.2f" % ef
			e.custom_minimum_size = Vector2(44, 0)
			fila.add_child(e)
			var d := p._texto(10, Principal.COL_SUAVE)
			d.text = String(f[2])
			d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			d.clip_text = true
			fila.add_child(d)

	## LOS PLANES. Se aplican solos en el minuto 60 según cómo vaya el marcador.
	## En el 60 y no antes: cambiar el plan en el 20 no es un plan, es
	## nerviosismo.
	var tp := p._texto(11, p.COL_ACENTO)
	tp.text = Idiomas.t("PLANES SEGÚN EL MARCADOR")
	p._lista_tactica.add_child(tp)
	if not p._modo_experto:
		var ep := p._texto(10, Principal.COL_SUAVE)
		ep.text = Idiomas.t("Se aplican solos en el minuto 60, sin que tengas que estar mirando.")
		ep.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(ep)
	for par in [["Si voy perdiendo", "plan_perdiendo"], ["Si voy ganando", "plan_ganando"]]:
		var prop2 := String(par[1])
		var fila2 := HBoxContainer.new()
		fila2.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila2)
		var et := p._texto(12, Principal.COL_SUAVE)
		et.text = String(par[0])
		et.custom_minimum_size = Vector2(120, 0)
		fila2.add_child(et)
		for f2: Array in Tactica.PLANES:
			var clave2 := String(f2[0])
			var b2 := Button.new()
			b2.text = String(f2[1])
			b2.toggle_mode = true
			b2.button_pressed = String(c.tactica.get(prop2)) == clave2
			b2.add_theme_font_size_override("font_size", 11)
			b2.clip_text = true
			b2.tooltip_text = String(f2[2])
			b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b2.pressed.connect(func() -> void:
				c.tactica.set(prop2, clave2)
				p._refrescar())
			fila2.add_child(b2)
	p._lista_tactica.add_child(HSeparator.new())

func _pintar_roles_tacticos(c: Club) -> void:
	var v := p.mundo.vestuario
	if v == null:
		return
	var once: Array = c.once()
	if once.is_empty():
		return
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("ROLES DEL ONCE")
	p._lista_tactica.add_child(t)
	var tabla := v.tabla_roles_tacticos()
	for j: Jugador in once:
		var actual := v.rol_tactico(j)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_tactica.add_child(fila)
		fila.add_child(p._retrato(j, 22))
		var nom := p._texto(12, Principal.COL_TEXTO)
		nom.text = "%s  %s" % [j.pos_e, j.nombre]
		nom.custom_minimum_size = Vector2(150, 0)
		fila.add_child(nom)
		## Solo los roles de SU línea: ofrecer "pivote" a un portero no es una
		## opción, es ruido que alarga el desplegable a dieciséis entradas.
		var op := OptionButton.new()
		op.add_theme_font_size_override("font_size", 11)
		op.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claves: Array = v.roles_de_grupo(Datos.grupo(j.pos_e))
		claves.sort()
		var elegido := 0
		for n in claves.size():
			var clave := String(claves[n])
			op.add_item(String((tabla[clave] as Array)[0]), n)
			if clave == actual:
				elegido = n
		op.selected = elegido
		var jug := j
		var lista := claves
		op.item_selected.connect(func(idx: int) -> void:
			v.fijar_rol_tactico(jug, String(lista[idx]))
			p._refrescar())
		fila.add_child(op)
		## El número que justifica todo el bloque: por debajo de 1,00 le estás
		## pidiendo algo que no sabe hacer.
		var apt := v.aptitud_rol(j, actual)
		var ap := p._texto(12, Principal.COL_VERDE if apt >= 1.02 else (Principal.COL_ROJO if apt < 0.95 else Principal.COL_SUAVE))
		ap.text = "%.2f" % apt
		ap.custom_minimum_size = Vector2(38, 0)
		fila.add_child(ap)

	## El efecto agregado, que es lo que de verdad llega al partido. Un once
	## entero de llegadores suma mucho ataque y regala la espalda: sin este
	## resumen, esa consecuencia no se ve en ninguna parte.
	var b: Dictionary = v.bonus_roles(once)
	var res := p._texto(11, Principal.COL_SUAVE)
	res.text = Idiomas.t("Efecto sobre el equipo:  ataque ×%.3f   ·   defensa ×%.3f") % [float(b["att"]), float(b["def"])]
	p._lista_tactica.add_child(res)
	p._lista_tactica.add_child(HSeparator.new())

## LA MODA TÁCTICA Y LO QUE TE FUNCIONA A TI.
##
## Arriba, qué se lleva este año y qué pasó de moda: sin esto, el mejor dibujo
## del juego lo sería para siempre. Abajo, la tabla que contesta la única
## pregunta que de verdad importa —«¿me funciona a mí el 4-3-3?»—, que no la
## puede contestar ninguna otra pantalla porque depende de TU plantilla.
func _pintar_moda_tactica(c: Club) -> void:
	p._lista_tactica.add_child(HSeparator.new())
	var e := p.mundo.era_actual()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "📈 %s" % String(e[1]).to_upper()
	p._lista_tactica.add_child(t)
	var d := p._texto(11, Principal.COL_SUAVE)
	d.text = String(e[4])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_tactica.add_child(d)
	p._dato("Se lleva", ", ".join(e[2]), Principal.COL_VERDE, p._lista_tactica)
	p._dato("Pasó de moda", ", ".join(e[3]), Principal.COL_ROJO, p._lista_tactica)
	var mio_f := c.tactica.formacion if c.tactica != null else ""
	var f := p.mundo.factor_moda(mio_f)
	p._dato("Tu dibujo (%s)" % mio_f,
		"de moda: +5%" if f > 1.0 else ("pasado de moda: −5%" if f < 1.0 else "ni una cosa ni otra"),
		Principal.COL_VERDE if f > 1.0 else (Principal.COL_ROJO if f < 1.0 else Principal.COL_SUAVE), p._lista_tactica)

	var rank := p.mundo.ranking_tactico()
	if rank.is_empty():
		return
	p._lista_tactica.add_child(HSeparator.new())
	var tr := p._texto(11, Principal.COL_SUAVE)
	tr.text = Idiomas.t("📊 LO QUE TE HA FUNCIONADO")
	p._lista_tactica.add_child(tr)
	var g := GridContainer.new()
	g.columns = 5
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p._lista_tactica.add_child(g)
	for cab: String in ["Dibujo", "PJ", "G-E-P", "Goles", "Pts/partido"]:
		p._celda(g, cab, Principal.COL_SUAVE, cab != "Dibujo" and cab != "G-E-P")
	for fila: Dictionary in rank:
		var es_mio := String(fila["formacion"]) == mio_f
		p._celda(g, "%s%s" % ["▸ " if es_mio else "", String(fila["formacion"])],
			Principal.COL_ORO if es_mio else Principal.COL_TEXTO, false)
		p._celda(g, str(int(fila["pj"])), Principal.COL_SUAVE, true)
		p._celda(g, "%d-%d-%d" % [int(fila["pg"]), int(fila["pe"]), int(fila["pp"])], Principal.COL_SUAVE, false)
		p._celda(g, "%d:%d" % [int(fila["gf"]), int(fila["gc"])], Principal.COL_SUAVE, true)
		p._celda(g, "%.2f" % float(fila["ppp"]),
			Principal.COL_VERDE if float(fila["ppp"]) >= 1.7 else (Principal.COL_ROJO if float(fila["ppp"]) < 1.0 else Principal.COL_TEXTO), true)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = Idiomas.t("Puntos por partido con cada dibujo, desde que llevas el club. No dice cuál es el mejor del juego: dice cuál le sienta bien a ESTA plantilla.")
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(ex)
