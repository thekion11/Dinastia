class_name PantallaPlantel
extends RefCounted
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
	t.text = "MERCADO DE AGENTES LIBRES  ·  sin traspaso, solo prima de fichaje y sueldo"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_libres.add_child(t)

	var filtros := HBoxContainer.new()
	filtros.add_theme_constant_override("separation", 6)
	p._lista_libres.add_child(filtros)
	var b_todos := Button.new()
	b_todos.text = "Todos"
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
		nada.text = "No hay agentes libres de ese puesto ahora mismo."
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
		boton.text = "Ofrecer contrato"
		boton.disabled = motivo_bloqueo != "" or prima > c.saldo
		boton.pressed.connect(func() -> void: _fichar_libre(j))
		fila.add_child(boton)
		var det := p._texto(11, Principal.COL_SUAVE)
		det.text = "%d años · %s · pide %s/sem · prima %s%s" % [
			j.edad, j.pais, p._dinero(j.sueldo), p._dinero(prima),
			"  ·  ya dijo que no una vez" if j.rechazos_libre > 0 else ""]
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
		ex.text = "En rojo, el que juega fuera de su puesto: rinde por debajo aunque su media diga otra cosa."
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
	t.text = "BALÓN PARADO"
	p._lista_tactica.add_child(t)
	if not p._modo_experto:
		var ex := p._texto(10, Principal.COL_SUAVE)
		ex.text = "El número es cuánto le va esa jugada a ESTE once: depende de si tienes gente con las habilidades que pide."
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
	tp.text = "PLANES SEGÚN EL MARCADOR"
	p._lista_tactica.add_child(tp)
	if not p._modo_experto:
		var ep := p._texto(10, Principal.COL_SUAVE)
		ep.text = "Se aplican solos en el minuto 60, sin que tengas que estar mirando."
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
	t.text = "ROLES DEL ONCE"
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
	res.text = "Efecto sobre el equipo:  ataque ×%.3f   ·   defensa ×%.3f" % [float(b["att"]), float(b["def"])]
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
	tr.text = "📊 LO QUE TE HA FUNCIONADO"
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
		ex.text = "Puntos por partido con cada dibujo, desde que llevas el club. No dice cuál es el mejor del juego: dice cuál le sienta bien a ESTA plantilla."
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_tactica.add_child(ex)

func _pintar_tactica(c: Club) -> void:
	p._limpiar(p._lista_tactica)
	## El pizarrón va PRIMERO: es lo que se viene a mirar aquí. Las perillas y los
	## interruptores se tocan una vez cada varias semanas; el once se mira cada
	## domingo.
	_pintar_pizarron(c)
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "FORMACIÓN"
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
	tp.text = "PIZARRA"
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
	tn.text = "REGLAMENTO INTERNO"
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
	to.text = "EL ONCE  ·  %d de 11 elegidos%s" % [
		c.once_elegido.size(),
		"" if c.once_elegido.size() == 11 else "   (con menos de once manda el automático)"]
	p._lista_tactica.add_child(to)
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
	t.text = "PUNTAJE DE CARRERA"
	p._lista_desafios.add_child(t)
	var total := p._texto(22, Principal.COL_ORO)
	total.text = p._miles(int(p_local["total"]))
	p._lista_desafios.add_child(total)
	var mult := p._texto(12, Principal.COL_SUAVE)
	mult.text = "%s de base  ×  %.2f de multiplicador" % [p._miles(int(p_local["base"])), float(p_local["multiplicador"])]
	p._lista_desafios.add_child(mult)
	p._lista_desafios.add_child(HSeparator.new())

	var td := p._texto(11, Principal.COL_SUAVE)
	td.text = "DE DÓNDE SALE"
	p._lista_desafios.add_child(td)
	p._dato("Títulos  (× 1.000)", "%d  →  %s" % [int(p_local["titulos"]), p._miles(int(p_local["titulos"]) * 1000)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Prestigio  (× 40)", "%d  →  %s" % [int(p_local["prestigio"]), p._miles(int(p_local["prestigio"]) * 40)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Logros  (× 300)", "%d  →  %s" % [int(p_local["logros"]), p._miles(int(p_local["logros"]) * 300)], Principal.COL_TEXTO, p._lista_desafios)
	p._dato("Temporadas  (× 120)", "%d  →  %s" % [int(p_local["temporadas"]), p._miles(int(p_local["temporadas"]) * 120)], Principal.COL_TEXTO, p._lista_desafios)
	p._lista_desafios.add_child(HSeparator.new())

	var tt := p._texto(11, Principal.COL_SUAVE)
	tt.text = "LOS OCHO DESAFÍOS"
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
		nom.text = "%s %s%s" % [String(fila[2]), String(fila[1]), "   ✓ activo" if activo else ""]
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
		fin.text = "💀 Partida marcada como terminada: cayó la primera derrota con el desafío del invicto activo (semana %d de %d). Puedes seguir jugando, pero el desafío está perdido." % [
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
	t.text = "🔥 MAPA DE RIVALIDADES"
	p._lista_clubes.add_child(t)
	var ex := p._texto(10, Principal.COL_SUAVE)
	ex.text = "La rivalidad no se declara: se construye. Sube con cada cruce y, sobre todo, con cada derrota."
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
	t.text = "%s  ·  reputación %d  ·  aforo %s" % [club.nombre, club.rep, p._miles(club.estadio_aforo)]
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
	sub.text = "%d jugadores  ·  media %.1f  ·  masa salarial %s/sem" % [
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
		cl.text = "⚔️  %s: estadio lleno, prensa encima y el doble de presión." % _frase_clasico(p.mundo.mi_club(), club)
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
	t.text = "GOLEADORES  ·  %s" % pais
	p._lista_clubes.add_child(t)
	if todos.is_empty():
		var nada := p._texto(12, Principal.COL_SUAVE)
		nada.text = "Todavía no hay goles en esta liga."
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

## `vPremios()` del HTML: la gala de fin de año. El acta la calcula entera
## `Logros.premios_temporada()` desde hace tiempo -equipo ideal, mejor joven,
## mejor entrenador, fair play, club más popular, mejor hinchada, mejor
## estadio- y hasta hoy no se veía en ningún sitio: se calculaba, se guardaba y
## ahí moría. Esto es solo la vitrina de lo que ya se entregaba a puerta
## cerrada.
func _pintar_premios() -> void:
	p._limpiar(p._lista_premios)
	var lg := p.mundo.logros
	if lg == null or lg.premios.is_empty():
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = "Las galas se celebran al cerrar cada temporada. Todavía no hay ninguna."
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_premios.add_child(vacio)
		return
	for acta: Dictionary in lg.premios:
		var t := p._texto(13, Principal.COL_ORO)
		t.text = "GALA %d" % int(acta.get("anio", 0))
		p._lista_premios.add_child(t)
		## Lo que se llevó TU club va primero y en verde: es lo que el jugador
		## viene a mirar. Si no ganó nada, se dice, en vez de dejar un hueco.
		var ganados: Array = acta.get("ganados", [])
		if ganados.is_empty():
			var nada := p._texto(12, Principal.COL_SUAVE)
			nada.text = "Tu club se fue de vacío esta temporada."
			p._lista_premios.add_child(nada)
		else:
			for premio in ganados:
				var g := p._texto(12, Principal.COL_VERDE)
				g.text = "🏆  %s" % String(premio)
				g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p._lista_premios.add_child(g)
		## `str()` y no `String()`: es la trampa 37 del proyecto -el constructor
		## `String()` revienta con tipos que `str()` traga sin quejarse-.
		p._dato("🎩 Mejor entrenador", str(acta.get("dt", "—")), Principal.COL_VERDE if bool(acta.get("dt_es_mio", false)) else Principal.COL_TEXTO, p._lista_premios)
		p._dato("🌱 Mejor joven", str(acta.get("joven", "—")), Principal.COL_TEXTO, p._lista_premios)
		p._dato("🤝 Fair Play", str(acta.get("fairplay", "—")), Principal.COL_VERDE if bool(acta.get("fairplay_es_mio", false)) else Principal.COL_TEXTO, p._lista_premios)
		p._dato("❤️ Club más popular", str(acta.get("popular", "—")), Principal.COL_TEXTO, p._lista_premios)
		p._dato("📣 Mejor hinchada", str(acta.get("hinchada", "—")), Principal.COL_VERDE if bool(acta.get("hinchada_es_mia", false)) else Principal.COL_TEXTO, p._lista_premios)
		p._dato("🏟️ Mejor estadio", str(acta.get("estadio", "—")), Principal.COL_VERDE if bool(acta.get("estadio_es_mio", false)) else Principal.COL_TEXTO, p._lista_premios)
		var ti := p._texto(11, Principal.COL_SUAVE)
		ti.text = "EQUIPO IDEAL"
		p._lista_premios.add_child(ti)
		var ideal := p._texto(12, Principal.COL_TEXTO)
		## `acta["ideal"]` es un ARRAY de nombres, no un texto: `String()` de un
		## array no existe y reventaba en silencio al cerrar la temporada.
		var once_ideal: Array = acta.get("ideal", [])
		ideal.text = ", ".join(PackedStringArray(once_ideal)) if not once_ideal.is_empty() else "—"
		ideal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_premios.add_child(ideal)
		p._lista_premios.add_child(HSeparator.new())

## `vPrevia()` del HTML: la pantalla de antes del partido. Todo lo que enseña
## es DERIVADO -no toca ni guarda nada-, así que se puede repintar cuantas veces
## haga falta sin consecuencias. Usa el mismo emparejamiento que `_dirigir()`
## (la copa manda sobre la liga) para no enseñar un rival y jugar contra otro.
## LOS JUEGOS MENTALES de `vPrevia()`. `Prensa` ENCIENDE dos banderas —el sobre
## con el informe del rival y la promesa hecha en conferencia— y hasta ahora no
## las apagaba nadie: `consumir_dato_del_rival()` y `consumir_presion()` estaban
## escritas, probadas y sin una sola llamada en todo el proyecto. Pagabas 80.000
## por espiar al rival y no pasaba absolutamente nada.
##
## Aquí es donde tienen que cobrarse las dos: en la previa, que es el momento en
## que la información sirve para algo.
func _pintar_juegos_mentales(rival: Club) -> void:
	if p.mundo.prensa == null:
		return
	var p_local := p.mundo.prensa
	## EL NODO «LECTURA» DEL ARBOL da el informe del rival SIEMPRE, sin tener que
	## comprarlo. `ve_tactica_rival()` estaba escrita y no la llamaba nadie: la
	## habilidad que existe para leer al rival no leia nada.
	var por_arbol := p.mundo.entrenamiento != null and p.mundo.entrenamiento.ve_tactica_rival()
	if not p_local.dato_del_rival and not p_local.presion_prometida and not por_arbol:
		return
	var t := p._texto(11, Principal.COL_ORO)
	t.text = "🎭 JUEGOS MENTALES"
	p._lista_partido.add_child(t)
	if p_local.dato_del_rival or por_arbol:
		## El informe del rival: el once que va a sacar y sus dos bajas. Se
		## consume al MIRAR la previa, no al jugar: lo que compraste fue saberlo
		## antes de decidir tu alineación, y si se gastara al pitido inicial
		## llegaría tarde para lo único que sirve.
		var e := p._texto(12, Principal.COL_VERDE)
		e.text = "📄 Informe reservado: sabes con qué sale %s." % rival.nombre
		p._lista_partido.add_child(e)
		var once := rival.once()
		var media := 0.0
		for j in once:
			media += float(j.ovr)
		if not once.is_empty():
			media /= float(once.size())
		p._dato("Once probable del rival", "media %.1f" % media, Principal.COL_TEXTO, p._lista_partido)
		var nombres: Array[String] = []
		for j2 in once:
			nombres.append("%s (%s)" % [j2.nombre, j2.pos_e])
		var l := p._texto(11, Principal.COL_SUAVE)
		l.text = ", ".join(nombres)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_partido.add_child(l)
		var bajas: Array[String] = []
		for j3 in rival.plantilla:
			if j3.lesion > 0 or j3.suspension > 0:
				bajas.append(j3.nombre)
		if not bajas.is_empty():
			p._dato("Bajas del rival", ", ".join(bajas), Principal.COL_VERDE, p._lista_partido)
		## EXTENSIÓN TÁCTICA (22-9-2026, Fase 3 del ROADMAP: "extender el
		## espionaje... a información táctica"). Mismo informe, más datos: con
		## qué mentalidad/presión/línea sale el rival, no solo su once. Lee
		## `rival.tactica` directo -el mismo dial que decide `multiplicador_
		## ataque()`/`multiplicador_defensa()` en el partido real, así que esto
		## nunca puede quedar desincronizado de lo que de verdad va a pasar-.
		##
		## CAVEAT HONESTO, no escondido: ningún club de la IA cambia su
		## `tactica` fuera de un partido en curso (`Tactica.plan_para()`, según
		## el marcador) o de un DT EMPLEADO en TU propio club
		## (`Roles.aplicar_directrices()`, que nunca toca un rival). Así que
		## para casi cualquier rival esto va a leer "Equilibrada / Media /
		## Media" siempre -el valor de fábrica de `Tactica`-, partido tras
		## partido. Es dato real y no inventado -si mañana algún club de la IA
		## sale con una mentalidad propia, este informe la va a leer
		## corectamente sin tocar una línea más-, pero se documenta la
		## limitación en vez de venderlo como más dinámico de lo que es: darle
		## personalidad táctica real a la IA tocaría el balance de CADA
		## partido de la liga (multiplicador_ataque/defensa), una decisión de
		## diseño más grande que esta pantalla, no tomada hoy sin que el
		## usuario la pida.
		var tact := rival.tactica
		## `: String =`, no `:=` -indexar un Array literal sin tipar no deja
		## que el analizador infiera el tipo ("Cannot infer the type... doesn't
		## have a set type"), un error de PARSEO real que se lleva puesto todo
		## `principal.gd` -no solo esta función-. Ya documentado una vez en
		## `ui/escudo.gd` (ver LEEME.md, "GENERADOR DE ESCUDOS, SEGUNDA
		## TANDA"), y esta vez lo atrapó `captura_previa.gd` con pantalla real
		## -el banco headless no carga `principal.gd`, así que "0 fallos" no
		## lo vio-.
		var ment_nombre: String = ["Defensiva", "Equilibrada", "Ofensiva"][tact.mentalidad]
		var nivel_nombre := ["Baja", "Media", "Alta"]
		p._dato("Mentalidad del rival", ment_nombre, Principal.COL_TEXTO, p._lista_partido)
		p._dato("Presión del rival", nivel_nombre[tact.presion], Principal.COL_TEXTO, p._lista_partido)
		p._dato("Línea defensiva del rival", nivel_nombre[tact.linea], Principal.COL_TEXTO, p._lista_partido)
		p_local.consumir_dato_del_rival()
	if p_local.presion_prometida:
		var pr := p._texto(12, Principal.COL_ORO)
		pr.text = "🗣️ Prometiste ganar en rueda de prensa. Si no ganas, la hinchada te lo va a cobrar."
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p._lista_partido.add_child(pr)
	p._lista_partido.add_child(HSeparator.new())

func _pintar_partido(c: Club) -> void:
	p._limpiar(p._lista_partido)
	if not p.mundo.temporada_en_curso():
		var fin := p._texto(13, Principal.COL_SUAVE)
		fin.text = "La temporada está terminada. Pulsa «Temporada siguiente»."
		p._lista_partido.add_child(fin)
		return
	var par := p.mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	if not es_copa:
		par = p.mundo.proximo_partido()
	if par.is_empty():
		var descansa := p._texto(13, Principal.COL_SUAVE)
		descansa.text = "Tu club descansa esta jornada."
		p._lista_partido.add_child(descansa)
		return

	var local: Club = par[0]
	var visita: Club = par[1]
	var de_local := local == c
	var rival: Club = visita if de_local else local

	var cab := p._texto(11, Principal.COL_SUAVE)
	cab.text = p.mundo.copa.nombre.to_upper() if es_copa else "JORNADA %d  ·  %s" % [
		p._liga_de(c).jornada_actual, p._liga_de(c).nombre]
	p._lista_partido.add_child(cab)
	var vs := p._texto(17, Principal.COL_TEXTO)
	vs.text = "%s   vs   %s" % [local.nombre, visita.nombre]
	p._lista_partido.add_child(vs)
	var donde := p._texto(12, Principal.COL_SUAVE)
	donde.text = "Juegas de %s  ·  %s" % ["LOCAL" if de_local else "VISITA", rival.nombre]
	p._lista_partido.add_child(donde)
	if p.mundo.es_clasico(c, rival):
		var clasico := p._texto(13, Principal.COL_ORO)
		var nom_cl := HistoriaClub.nombre_clasico(c.nombre, rival.nombre)
		clasico.text = "🔥 ¡%s!" % (nom_cl.to_upper() if nom_cl != "" else "ES CLÁSICO")
		p._lista_partido.add_child(clasico)
	## LA FRASE DE LA PARED, justo antes de salir. Es lo que el HTML prometia
	## en la pantalla del club por dentro -"se lee en el tunel antes de cada
	## partido"- y no cumplia en ninguna parte.
	if p.mundo.club_dentro != null and p.mundo.club_dentro.frase != "":
		var fr := p._texto(13, Color(p.mundo.club_dentro.color_ct2(c)))
		fr.text = "«%s»" % p.mundo.club_dentro.frase
		fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p._lista_partido.add_child(fr)
		var fr2 := p._texto(10, Principal.COL_SUAVE)
		fr2.text = "En la pared del túnel"
		fr2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p._lista_partido.add_child(fr2)
	p._lista_partido.add_child(HSeparator.new())

	_pintar_juegos_mentales(rival)

	var arb := Previa.arbitro_de(rival.id, p.mundo.semana)
	var con_el := p.mundo.federacion.texto_arbitro(String(arb["nombre"])) if p.mundo.federacion != null else ""
	p._dato("👨‍⚖️ Árbitro", "%s — %s%s" % [String(arb["nombre"]), String(arb["descripcion"]), ("  ·  " + con_el) if con_el != "" else ""], Principal.COL_SUAVE, p._lista_partido)
	var dtr := Previa.dt_de(rival)
	p._dato("🎩 DT rival", "%s — %s" % [String(dtr["nombre"]), String(dtr["descripcion"])], Principal.COL_SUAVE, p._lista_partido)
	p._lista_partido.add_child(HSeparator.new())

	## Las fuerzas salen de un `Partido` de mentira, montado solo para medir: es
	## el mismo cálculo que usará el de verdad, así que lo que dice la previa es
	## lo que va a pasar en el campo.
	var medidor := Partido.new(local, visita)
	medidor.preparar()
	var f_local := medidor.fuerza(medidor.once_local, local)
	var f_visita := medidor.fuerza(medidor.once_visita, visita)
	var f_mia: Dictionary = f_local if de_local else f_visita
	var f_suya: Dictionary = f_visita if de_local else f_local
	var ti := p._texto(11, Principal.COL_SUAVE)
	ti.text = "INFORME"
	p._lista_partido.add_child(ti)
	p._dato("Tu ataque vs su defensa", "%d / %d" % [int(round(f_mia["ata"])), int(round(f_suya["def"]))], Principal.COL_TEXTO, p._lista_partido)
	p._dato("Tu defensa vs su ataque", "%d / %d" % [int(round(f_mia["def"])), int(round(f_suya["ata"]))], Principal.COL_TEXTO, p._lista_partido)

	var cuo := Previa.cuotas(f_mia, f_suya, de_local)
	var tc := p._texto(11, Principal.COL_SUAVE)
	tc.text = "🎰 CASA DE APUESTAS"
	p._lista_partido.add_child(tc)
	p._dato("Ganas tú", "%.2f" % float(cuo["cuota_gano"]), Principal.COL_TEXTO, p._lista_partido)
	p._dato("Empate", "%.2f" % float(cuo["cuota_empate"]), Principal.COL_SUAVE, p._lista_partido)
	p._dato("Gana %s" % rival.nombre, "%.2f" % float(cuo["cuota_pierdo"]), Principal.COL_TEXTO, p._lista_partido)
	var lectura := p._texto(11, Principal.COL_SUAVE)
	var p_gano: float = cuo["p_gano"]
	var p_pierdo: float = cuo["p_pierdo"]
	var p_empate: float = cuo["p_empate"]
	if p_gano > p_pierdo + 0.08 and p_gano > p_empate:
		lectura.text = "Las cuotas te tienen como favorito: si el resultado no acompaña, la prensa y la hinchada lo van a leer peor de lo normal."
	elif p_pierdo > p_gano + 0.08 and p_pierdo > p_empate:
		lectura.text = "Vas de underdog en las apuestas: sumar acá se festeja como una machada."
	else:
		lectura.text = "Cuotas parejas: partido de pronóstico cerrado, sin favorito claro para las casas."
	lectura.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p._lista_partido.add_child(lectura)

	## El informe del rival no es gratis: en el HTML pide la habilidad `lectura`
	## del DT o haberlo espiado. Aquí lo abre la sala de vídeo -`Instalaciones.
	## lectura_del_rival()`, que ya existía y no la miraba nadie-: si has
	## construido el análisis, ves su plan; si no, no.
	if p.mundo.obras.lectura_del_rival() > 0:
		p._lista_partido.add_child(HSeparator.new())
		var tv := p._texto(11, Principal.COL_SUAVE)
		tv.text = "👁️ INFORME DEL RIVAL  (sala de vídeo)"
		p._lista_partido.add_child(tv)
		p._dato("Sistema previsto", rival.tactica.formacion, Principal.COL_TEXTO, p._lista_partido)
		p._dato("Mentalidad", ["Defensiva", "Equilibrada", "Ofensiva"][rival.tactica.mentalidad], Principal.COL_TEXTO, p._lista_partido)
		p._dato("Punto débil", "la última línea" if f_suya["def"] < f_suya["ata"] else "la generación de juego", Principal.COL_TEXTO, p._lista_partido)

	## `vAlineacion()` del HTML: los dos onces tal como van a salir, con su
	## ranura en la formación y su dorsal. El `medidor` de arriba ya los tiene
	## armados -es el mismo `preparar()` que usará el partido de verdad-, así
	## que enseñarlos no cuesta ni un cálculo más.
	p._lista_partido.add_child(HSeparator.new())
	var ta := p._texto(11, Principal.COL_SUAVE)
	ta.text = "LOS ONCES"
	p._lista_partido.add_child(ta)
	var g := GridContainer.new()
	g.columns = 4
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 12)
	p._lista_partido.add_child(g)
	p._celda(g, "", Principal.COL_SUAVE)
	p._celda(g, "%s  (%s)" % [local.nombre, local.tactica.formacion], p.COL_ACENTO if de_local else Principal.COL_TEXTO, false, 12)
	p._celda(g, "", Principal.COL_SUAVE)
	p._celda(g, "%s  (%s)" % [visita.nombre, visita.tactica.formacion], Principal.COL_TEXTO if de_local else p.COL_ACENTO, false, 12)
	for i in maxi(medidor.once_local.size(), medidor.once_visita.size()):
		if i < medidor.once_local.size():
			var jl: Jugador = medidor.once_local[i]
			g.add_child(p._retrato(jl, 22))
			p._celda(g, "%s  %s" % [jl.pos_e, jl.nombre], Principal.COL_TEXTO, false, 11)
		else:
			p._celda(g, "", Principal.COL_SUAVE)
			p._celda(g, "", Principal.COL_SUAVE)
		if i < medidor.once_visita.size():
			var jv: Jugador = medidor.once_visita[i]
			g.add_child(p._retrato(jv, 22))
			p._celda(g, "%s  %s" % [jv.pos_e, jv.nombre], Principal.COL_TEXTO, false, 11)
		else:
			p._celda(g, "", Principal.COL_SUAVE)
			p._celda(g, "", Principal.COL_SUAVE)

	p._lista_partido.add_child(HSeparator.new())
	p._selector_modo_partido(p._lista_partido)
	p._boton("▶ Jugar el partido", p._dirigir, p._lista_partido)

## `vCalendario` -pantalla nueva, sin equivalente en el HTML-: el usuario la
## pidió después de ver una referencia de otro manager (grilla con los
## próximos partidos marcados, escudo del rival, desde la que se simula de
## corrido o se salta el partido entero sin dirigirlo). En vez de inventar un
## sistema de fechas nuevo, lee el mismo `Liga.calendario` que ya arma la
## temporada entera desde el sorteo.
## C13: lo que viene en el calendario del país (fiestas, memoria, festividades)
## y el gran torneo del año, si lo hay.
func _pintar_proximas_fechas(c: Club) -> void:
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = "PRÓXIMAS FECHAS EN %s" % c.pais
	p._lista_calendario.add_child(t)
	for f: Dictionary in Calendario.proximas(c.pais, p.mundo.anio, p.mundo.semana, 5):
		var l := p._texto(12, Principal.COL_ROJO if String(f["tipo"]) == "memoria" else Principal.COL_TEXTO)
		var faltan := int(f["faltan"])
		var cuando := "%d de %s" % [int(f["dia"]), Principal.MESES_LARGOS[int(f["mes"]) - 1]]
		## "11 de septiembre" ya es la fecha: no repetirla.
		var nom := String(f["nombre"])
		l.text = "%s %s%s  (%s)" % [Calendario.icono(String(f["tipo"])), cuando,
			"" if nom == cuando else " · " + nom, "esta semana" if faltan < 7 else "en %d días" % faltan]
		l.tooltip_text = String(f["texto"])
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		p._lista_calendario.add_child(l)
	for tor: Dictionary in Calendario.torneos(p.mundo.anio):
		var sedes: Array = tor["sedes"]
		var l2 := p._texto(12, Principal.COL_ORO)
		l2.text = "🌍 %s %d: del %d/%d al %d/%d%s" % [String(tor["nombre"]), p.mundo.anio,
			int(tor["desde"][1]), int(tor["desde"][0]), int(tor["hasta"][1]), int(tor["hasta"][0]),
			(" · sede: " + ", ".join(sedes)) if not sedes.is_empty() else ""]
		p._lista_calendario.add_child(l2)
	p._lista_calendario.add_child(HSeparator.new())

func _pintar_calendario(c: Club) -> void:
	p._limpiar(p._lista_calendario)
	if not p.mundo.temporada_en_curso():
		var fin := p._texto(13, Principal.COL_SUAVE)
		fin.text = "La temporada está terminada. Pulsa «Temporada siguiente»."
		p._lista_calendario.add_child(fin)
		return

	_pintar_proximas_fechas(c)
	## PRÓXIMO PARTIDO, con el MISMO orden que usa `_dirigir()` -copa antes que
	## liga-: mostrar aquí un partido distinto del que se juega al pulsar el
	## botón sería peor que no mostrar nada.
	var tp := p._texto(11, Principal.COL_SUAVE)
	tp.text = "PRÓXIMO PARTIDO"
	p._lista_calendario.add_child(tp)
	var par := p.mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	if not es_copa:
		par = p.mundo.proximo_partido()
	if par.is_empty():
		var descansa := p._texto(13, Principal.COL_SUAVE)
		descansa.text = "Tu club descansa esta jornada."
		p._lista_calendario.add_child(descansa)
	else:
		var local: Club = par[0]
		var visita: Club = par[1]
		var de_local := local == c
		var rival: Club = visita if de_local else local
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		p._lista_calendario.add_child(fila)
		fila.add_child(p._escudo(rival, 36))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(info)
		var nom := p._texto(15, Principal.COL_TEXTO)
		nom.text = rival.nombre
		info.add_child(nom)
		var sub := p._texto(11, Principal.COL_SUAVE)
		sub.text = "%s  ·  %s" % [
			p.mundo.copa.nombre if es_copa else p._liga_de(c).nombre,
			"Local" if de_local else "Visitante"]
		info.add_child(sub)
		## Si además hay ronda continental esta misma semana -`CONTI_EN` no
		## evita que caiga junto a una jornada normal, ver nota en el LEEME-,
		## se avisa aparte: el botón de abajo dirige lo mismo que dirigiría
		## `_dirigir()`, nunca el continental, así que mostrarlo como "el
		## próximo partido" habría sido mentir.
		var mi_conti := p.mundo.mi_continental()
		if Continental.toca_ronda(p.mundo.semana) >= 0 and mi_conti != null and mi_conti.en_curso():
			var av := p._texto(10, Principal.COL_ORO)
			av.text = "También hay ronda de %s esta semana." % Continental.nombre_conti(mi_conti.clave)
			av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(av)
		if p.mundo.es_clasico(c, rival):
			var clasico := p._texto(12, Principal.COL_ORO)
			var nom_cl2 := HistoriaClub.nombre_clasico(c.nombre, rival.nombre)
			clasico.text = "🔥 ¡%s!" % (nom_cl2 if nom_cl2 != "" else "Es clásico")
			p._lista_calendario.add_child(clasico)
		var filab := HBoxContainer.new()
		filab.add_theme_constant_override("separation", 6)
		p._lista_calendario.add_child(filab)
		p._selector_modo_partido(p._lista_calendario)
		p._lista_calendario.move_child(filab, p._lista_calendario.get_child_count() - 1)
		p._boton("▶ Jugar el partido", p._dirigir, filab)

	p._lista_calendario.add_child(HSeparator.new())
	p._boton("⏭⏭ Simular toda la temporada", p._jugar_temporada, p._lista_calendario)
	p._lista_calendario.add_child(HSeparator.new())

	## EL CALENDARIO DE LIGA COMPLETO. Se recorre `Liga.calendario` a mano -no
	## `emparejamiento_de()`, que solo conoce la jornada ACTUAL- desde hoy
	## hasta el final: son datos que ya existen enteros desde que se sorteó la
	## temporada, así que enseñarlos no inventa nada nuevo, solo lo hace
	## visible.
	var liga := p._liga_de(c)
	var tl := p._texto(11, Principal.COL_SUAVE)
	tl.text = "CALENDARIO DE %s" % liga.nombre.to_upper()
	p._lista_calendario.add_child(tl)
	for i in range(liga.jornada_actual, liga.calendario.size()):
		var jornada: Array = liga.calendario[i]
		for pareja: Array in jornada:
			var loc: Club = pareja[0]
			var vis: Club = pareja[1]
			if loc != c and vis != c:
				continue
			var de_loc := loc == c
			var riv: Club = vis if de_loc else loc
			var actual := i == liga.jornada_actual
			var fj := HBoxContainer.new()
			fj.add_theme_constant_override("separation", 8)
			p._lista_calendario.add_child(fj)
			var lj := p._texto(11, Principal.COL_ORO if actual else Principal.COL_SUAVE)
			lj.text = "J%d" % (i + 1)
			lj.custom_minimum_size = Vector2(34, 0)
			fj.add_child(lj)
			fj.add_child(p._escudo(riv, 20))
			var nj := p._texto(12, Principal.COL_TEXTO if actual else Principal.COL_SUAVE)
			nj.text = "%s  (%s)" % [riv.nombre, "L" if de_loc else "V"]
			nj.clip_text = true
			nj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fj.add_child(nj)
			break

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

func _abrir_negociacion(j: Jugador) -> void:
	var motivo := p.mundo.mercado.abrir_negociacion(j)
	if motivo != "":
		p._escribir("[color=#e05555]No se pudo abrir la mesa: %s.[/color]" % motivo)
		return
	p._negociacion_ultimo = {}
	p._ir_a_pestana("Mercado")
	p._refrescar()

func _cancelar_negociacion() -> void:
	p.mundo.mercado.cerrar_negociacion()
	p._negociacion_ultimo = {}
	p._refrescar()

## El estado de la copa: en qué ronda va, quién sigue vivo y cómo cayó cada
## eliminatoria. Se pinta al revés que la liga -de la ronda más reciente hacia
## atrás- porque lo que interesa es lo que acaba de pasar.
func _pintar_copa(mio: Club) -> void:
	p._limpiar(p._lista_copa)
	if p.mundo.copa == null:
		var vacio := p._texto(12, Principal.COL_SUAVE)
		vacio.text = "La copa se sortea al empezar la temporada."
		p._lista_copa.add_child(vacio)
		return
	var c := p.mundo.copa
	var cab := p._texto(14, Principal.COL_ORO)
	if c.campeon != null:
		cab.text = "%s — campeón: %s" % [c.nombre, c.campeon.nombre]
	elif c.en_curso():
		cab.text = "%s — %s  (%d equipos vivos)" % [c.nombre, c.nombre_de_ronda(), c.vivos.size()]
	else:
		cab.text = c.nombre
	p._lista_copa.add_child(cab)

	if c.en_curso():
		var cruce := c.emparejamiento_de(mio)
		var estado := p._texto(12, Principal.COL_VERDE if not cruce.is_empty() else Principal.COL_ROJO)
		if not cruce.is_empty():
			estado.text = "Te toca: %s  vs  %s" % [cruce[0].nombre, cruce[1].nombre]
		else:
			estado.text = "%s ya está eliminado." % mio.nombre
		p._lista_copa.add_child(estado)

	for i in range(c.historial.size() - 1, -1, -1):
		var ronda: Dictionary = c.historial[i]
		p._lista_copa.add_child(HSeparator.new())
		var t := p._texto(11, Principal.COL_SUAVE)
		t.text = String(ronda["ronda"]).to_upper()
		p._lista_copa.add_child(t)
		var g := GridContainer.new()
		g.columns = 3
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		p._lista_copa.add_child(g)
		for r: Dictionary in ronda["resultados"]:
			var mio_juega: bool = r["local"] == mio or r["visita"] == mio
			var col := p.COL_ACENTO if mio_juega else Principal.COL_TEXTO
			p._celda(g, String(r["local"].nombre), col if r["pasa"] == r["local"] else Principal.COL_SUAVE)
			var marcador := "%d-%d" % [r["gl"], r["gv"]]
			if not r["penales"].is_empty():
				marcador += "  (%d-%d pen.)" % [r["penales"][0], r["penales"][1]]
			p._celda(g, marcador, col, true)
			p._celda(g, String(r["visita"].nombre), col if r["pasa"] == r["visita"] else Principal.COL_SUAVE)
