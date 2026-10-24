extends "res://ui/principal_p11.gd"
## [Capa 13/19 de `principal.gd`] _al_elegir_club, _llenar_selector, _tomar_club, _pintar_elegir_club, _abrir_elegir_club, _modo_simulacion … (+10)

func _al_elegir_club(indice: int) -> void:
	mundo.tomar_el_mando(String(_selector.get_item_metadata(indice)))
	## tomar_el_mando() crea una Seleccion nueva -la del pais de este club-, asi
	## que hay que volver a engancharle el aviso de noticias.
	_conectar_noticias()
	_seleccionado = null
	_refrescar()

func _llenar_selector() -> void:
	_selector.clear()
	var i := 0
	for l in mundo.ligas:
		for c in l.clubes:
			_selector.add_item("%s  ·  %s" % [c.nombre, l.nombre])
			_selector.set_item_metadata(i, c.id)
			if c.id == mundo.mi_club_id:
				_selector.select(i)
			i += 1

func _tomar_club(id: String) -> void:
	mundo.tomar_el_mando(id)
	_conectar_noticias()
	_seleccionado = null
	_llenar_selector()
	if _dlg_club != null and is_instance_valid(_dlg_club):
		_dlg_club.queue_free()
		_dlg_club = null
	_escribir("[color=#3fa06a][b]Tomas el mando de %s.[/b][/color] %s" % [
		mundo.mi_club().nombre, mundo.directiva.objetivo if mundo.directiva != null else ""])
	_refrescar()

func _pintar_elegir_club(col: VBoxContainer) -> void:
	for h in col.get_children():
		h.queue_free()

	var t := _texto(14, COL_ACENTO)
	t.text = Idiomas.t("¿DÓNDE QUIERES EMPEZAR?")
	col.add_child(t)

	## Los países que tienen liga, con cuántos clubes hay en cada uno.
	var por_pais := {}
	for l: Liga in mundo.ligas:
		por_pais[l.pais] = int(por_pais.get(l.pais, 0)) + l.clubes.size()
	var nombres: Dictionary = Datos.tabla("PAIS_SELECCION")

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	col.add_child(flow)
	for p: String in por_pais:
		var pais := p
		var b := Button.new()
		b.text = "%s  (%d)" % [String(nombres.get(pais, pais)) if nombres != null else pais, int(por_pais[pais])]
		b.add_theme_font_size_override("font_size", 11)
		b.toggle_mode = true
		b.button_pressed = _pais_elegido == pais
		b.clip_text = true
		b.custom_minimum_size = Vector2(120, 26)
		b.pressed.connect(func() -> void:
			_pais_elegido = pais
			_pintar_elegir_club(col))
		flow.add_child(b)

	if _pais_elegido == "":
		return

	## EL MAPA. Se pinta con el color del club que ya diriges, para que el país
	## no sea un dibujo suelto sino EL sitio donde está tu club.
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fila)

	var marco := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = _pal_panel()
	estilo.border_color = COL_ACENTO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 10
	estilo.content_margin_right = 10
	estilo.content_margin_top = 10
	estilo.content_margin_bottom = 10
	marco.add_theme_stylebox_override("panel", estilo)
	marco.custom_minimum_size = Vector2(240, 0)
	fila.add_child(marco)
	var colm := VBoxContainer.new()
	colm.add_theme_constant_override("separation", 6)
	marco.add_child(colm)
	var tn := _texto(13, COL_TEXTO)
	tn.text = String(nombres.get(_pais_elegido, _pais_elegido)) if nombres != null else _pais_elegido
	tn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colm.add_child(tn)
	var lienzo := Control.new()
	lienzo.custom_minimum_size = Vector2(200, 240)
	colm.add_child(lienzo)
	var pol := MapaPais.poligono(_pais_elegido, Vector2(200, 240))
	if pol.size() >= 3:
		var forma := Polygon2D.new()
		forma.polygon = pol
		forma.color = COL_ACENTO
		lienzo.add_child(forma)
		## El contorno por encima, más claro: una silueta plana se lee como una
		## mancha, y con borde se reconoce el país.
		var borde := Line2D.new()
		borde.points = pol
		borde.closed = true
		borde.width = 2.0
		borde.default_color = COL_TEXTO
		lienzo.add_child(borde)
	else:
		var sin := _texto(10, COL_SUAVE)
		sin.text = Idiomas.t("(sin silueta para este país)")
		colm.add_child(sin)

	## LOS CLUBES DEL PAÍS, con lo que de verdad se compara al elegir: escudo,
	## reputación, división y aforo.
	var lista := ScrollContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fila.add_child(lista)
	var colc := VBoxContainer.new()
	colc.add_theme_constant_override("separation", 3)
	colc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_child(colc)

	var clubes: Array[Club] = []
	for l2: Liga in mundo.ligas:
		if l2.pais == _pais_elegido:
			for c2: Club in l2.clubes:
				clubes.append(c2)
	clubes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	for c3: Club in clubes:
		var club := c3
		var f := HBoxContainer.new()
		f.add_theme_constant_override("separation", 8)
		colc.add_child(f)
		var esc := TextureRect.new()
		esc.texture = Escudo.textura(club, 26)
		esc.custom_minimum_size = Vector2(26, 26)
		esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		f.add_child(esc)
		var b2 := Button.new()
		var mio := club.id == mundo.mi_club_id
		b2.text = "%s%s" % ["★ " if mio else "", club.nombre]
		b2.flat = true
		b2.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b2.add_theme_font_size_override("font_size", 13)
		b2.add_theme_color_override("font_color", _color_de_paleta(COL_ORO if mio else COL_TEXTO))
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.clip_text = true
		b2.pressed.connect(func() -> void:
			_tomar_club(club.id))
		f.add_child(b2)
		var d := _texto(11, COL_SUAVE)
		d.text = Idiomas.t("D%d  ·  rep %d  ·  %s butacas") % [club.division, club.rep, _miles(club.estadio_aforo)]
		d.custom_minimum_size = Vector2(190, 0)
		f.add_child(d)

func _abrir_elegir_club() -> void:
	if _dlg_club != null and is_instance_valid(_dlg_club):
		## Fuera del árbol YA, no al final del cuadro: si no, durante ese cuadro
		## hay dos ventanas exclusivas y Godot se queja (visto en el recorrido).
		_dlg_club.exclusive = false
		_dlg_club.hide()
		if _dlg_club.get_parent() != null:
			_dlg_club.get_parent().remove_child(_dlg_club)
		_dlg_club.queue_free()
	_dlg_club = Window.new()
	_dlg_club.title = Idiomas.t("Elegir club")
	_dlg_club.size = Vector2i(880, 620)
	_dlg_club.transient = true
	_dlg_club.exclusive = true
	_dlg_club.close_requested.connect(func() -> void:
		_dlg_club.queue_free()
		_dlg_club = null)
	add_child(_dlg_club)
	var fondo := ColorRect.new()
	fondo.color = _pal_fondo()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dlg_club.add_child(fondo)
	var caja := MarginContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override("margin_left", 14)
	caja.add_theme_constant_override("margin_right", 14)
	caja.add_theme_constant_override("margin_top", 12)
	caja.add_theme_constant_override("margin_bottom", 12)
	_dlg_club.add_child(caja)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	caja.add_child(col)
	_pais_elegido = mundo.mi_club().pais if mundo.mi_club() != null else ""
	_pintar_elegir_club(col)
	_dlg_club.popup_centered()

## El modo elegido para una competición (se guarda por separado: la copa en 3D
## y la liga en resumen, por ejemplo). Por defecto, 3D completo, que es lo que
## hacía "Dirigir" hasta hoy.
func _modo_simulacion(comp: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return "completo"
	return String(cfg.get_value(SECCION_SIMULACION, comp, "completo"))

## La competición del partido de esta semana, con el mismo orden que
## `_dirigir()`: copa, después continental, después liga.
func _competicion_de_la_semana() -> String:
	if not mundo.partido_de_copa().is_empty():
		return "copa"
	if mundo.mi_continental() != null and not mundo.partido_continental().is_empty():
		return "conti"
	return "liga"

## Apunta el partido dirigido y lo pone al día (goles y cada 5'): si se cierra
## el juego a medias, al cargar se completa desde ahí (`PartidoPendiente`).
func _apuntar_partido_en_curso(p: Partido) -> void:
	PartidoPendiente.abrir(mundo, p)
	p.gol.connect(func(_c: Club, _a: Jugador, _m: int, _s: Jugador) -> void: PartidoPendiente.actualizar(mundo, p))
	p.minuto_jugado.connect(func(mi: int) -> void:
		if mi % 5 == 0:
			PartidoPendiente.actualizar(mundo, p))

func _seguir_tras_partido(p: Partido) -> void:
	PartidoPendiente.cerrar()
	mundo.avanzar_semana(p)
	_escribir("[color=#3fa06a]J%d  %s %d-%d %s[/color]" % [
		mundo.liga_de(mundo.mi_club()).jornada_actual,
		p.local.nombre, p.goles_local, p.goles_visita, p.visita.nombre])
	## (17-10: tras un partido dirigido no se autoguardaba; ahora sí, como al
	## avanzar la semana sin jugarlo.)
	_autoguardar_si_toca()
	_refrescar()

## Se avanza la semana con el partido ya jugado en la mano. Si se avanzara sin
## él, la jornada se volvería a simular por dentro y en la tabla aparecería un
## marcador distinto del que se acaba de ver. Lo usan todos los modos.
func _cerrar_partido_dirigido(p: Partido) -> void:
	PartidoPendiente.actualizar(mundo, p)
	## A PIE DE CAMPO (B5): antes de volver al despacho, una pregunta con el
	## partido todavía caliente. No en "instantáneo": quien lo eligió quiere el
	## resultado y nada más.
	if mundo.prensa != null and _modo_simulacion(_competicion_de_la_semana()) != "instantaneo":
		var mio := mundo.mi_club()
		var local := p.local == mio
		var gf := p.goles_local if local else p.goles_visita
		var gc := p.goles_visita if local else p.goles_local
		var pie := PieDeCampo.mostrar(self, mundo.prensa, gf > gc, gf == gc, gf, gc)
		pie.cerrado.connect(func() -> void: _seguir_tras_partido(p))
		return
	_seguir_tras_partido(p)

## El estadio del local, con el cielo del día (no el que se eligió en el
## diseñador: el clima lo pone la ciudad).
func _perfil_con_clima(p: Partido) -> Dictionary:
	var perfil := mundo.perfil_estadio_de(p.local).duplicate()
	if not p.clima_info.is_empty():
		perfil["clima"] = String(p.clima_info["clave"])
	return perfil

## Abre el partido de esta jornada en directo. Al terminar, el resultado que
## salga en la pantalla es el que va a la tabla: el mundo simula el resto de la
## jornada pero NO vuelve a jugar el tuyo.
func _dirigir() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada.[/color]")
		return
	## Si esta semana hay copa, manda la copa: es la que se juega a un solo
	## partido y la que se puede perder para siempre.
	var par := mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	## SI NO HAY COPA, ¿HAY CONTINENTAL? Hasta esta tanda `_dirigir()` nunca
	## miraba esto: `partido_continental()` no existía, así que un partido de
	## Libertadores/Champions/etc. jamás se podía dirigir en vivo -se
	## auto-simulaba solo, sin que el jugador se enterara de que existía esa
	## fecha-. El motor de abajo (`Continental.jugar_ronda(ya_jugado)`) ya
	## sabía recibirlo; solo faltaba esta puerta.
	var conti: Continental = null
	if not es_copa:
		conti = mundo.mi_continental()
		par = mundo.partido_continental()
		if par.is_empty():
			conti = null
	if conti == null and not es_copa:
		par = mundo.proximo_partido()
	if par.is_empty():
		_escribir("[color=#8ea595]Tu club descansa esta jornada.[/color]")
		return
	## La eliminatoria -penales, sin revancha- es la copa siempre, y el
	## continental solo cuando ya salió de la fase de grupos.
	var es_eliminatoria := es_copa or (conti != null and not conti.en_fase_de_grupos())
	if es_copa:
		_escribir("[color=#c9a227]%s — %s.[/color]" % [mundo.copa.nombre, mundo.copa.nombre_de_ronda()])
	elif conti != null:
		_escribir("[color=#c9a227]%s — %s.[/color]" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()])
	var p := Partido.new(par[0], par[1])
	## EL TIEMPO DE LA CIUDAD (plan maestro C1): el mismo que se juega y el
	## mismo cielo que se ve. Sale del país del local y la época del año.
	var info_clima := Clima.del_partido(p.local.pais, mundo.semana, mundo.anio, p.local.id + p.visita.id)
	p.fijar_clima(info_clima)
	_escribir("[color=#8ea595]%s Parte del tiempo: %s.[/color]" % [Clima.icono(info_clima), String(info_clima["texto"])])
	var consejo := Clima.consejo(info_clima, p.local == mundo.mi_club())
	if consejo != "":
		MentorVoz.decir(self, mundo, "%s %s" % [Clima.icono(info_clima), String(info_clima["texto"])], consejo)
	## El nodo «Bloque» del arbol hace que lo que dices desde el banquillo pegue
	## un 50% mas. En este motor eso es la arenga.
	if mundo.entrenamiento != null:
		p._factor_arenga = mundo.entrenamiento.factor_instrucciones()
	## CÓMO SE MIRA (25-9-2026, plan maestro B2). Los cinco modos juegan el
	## MISMO `Partido` con los mismos `simular_minuto()`: solo cambia la vista.
	var modo := _modo_simulacion(_competicion_de_la_semana())
	if modo == "instantaneo" or modo == "resumen":
		p.preparar()
		p.fijar_hinchada(mundo.mi_club(), mundo.prensa.animo if mundo.prensa != null else 60)
		_apuntar_partido_en_curso(p)
		var res := ResumenPartido.mostrar(self, p, mundo.mi_club(), es_eliminatoria, modo == "resumen")
		res.cerrado.connect(func() -> void:
			res.queue_free()
			_cerrar_partido_dirigido(p))
		return
	## EL INFORME DEL RIVAL (17-10-2026) antes de salir a jugar, como en FM/FC.
	## Sin pantalla (banco) o con SIN_INFORME_RIVAL no se enseña.
	if InformeRival.activo and DisplayServer.get_name() != "headless" and OS.get_environment("SIN_INFORME_RIVAL") == "":
		var inf := InformeRival.mostrar(self, p, mundo.mi_club(), mundo.liga_de(p.visita if p.local == mundo.mi_club() else p.local), mundo)
		await inf.cerrado
		inf.queue_free()
	_apuntar_partido_en_curso(p)
	var vivo := PartidoVivo.new()
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vivo)
	## El perfil del ESTADIO LOCAL -que puede ser el tuyo o el del rival, según
	## quién juegue en casa-, no siempre "el tuyo": `perfil_estadio_de()` ya
	## decide sola cuándo corresponde tu diseño y cuándo el genérico por hash.
	## El BALÓN sí es siempre el tuyo -`Comercial` es tu departamento comercial,
	## el rival no tiene uno propio en este juego-.
	## Lo de la PANTALLA GIGANTE va antes de `abrir()`: `PartidoVivo` abre el
	## visor 3D de entrada, así que asignarlo después llegaría tarde.
	vivo.datos_pantalla = _datos_pantalla_estadio(p.local, "copa" if es_copa else ("conti" if conti != null else "liga"))
	_fundido_entrada()
	vivo.abrir(p, mundo.mi_club(), mundo.vestuario, es_eliminatoria, mundo.roles,
		_velocidad_partido, _perfil_con_clima(p),
		Comercial.color_balon(mundo.comercial.balon, mundo.mi_club()))
	vivo.cerrado.connect(func() -> void:
		vivo.queue_free()
		_cerrar_partido_dirigido(p))

func _jugar_temporada() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada ya está terminada.[/color]")
		return
	var t0 := Time.get_ticks_msec()
	mundo.jugar_temporada()
	var t := _liga_de(mundo.mi_club()).tabla()
	var puesto := 1
	for fila: Dictionary in t:
		if fila["club"] == mundo.mi_club():
			break
		puesto += 1
	_escribir("[color=#3fa06a]Temporada %d completa en %d ms.[/color] Campeón: [b]%s[/b]. Acabas [b]%d.º[/b]." % [
		mundo.anio, Time.get_ticks_msec() - t0, t[0]["club"].nombre, puesto])
	_autoguardar_si_toca()
	_refrescar()

## Una fila de jugador que se puede pulsar. El botón va en la primera celda y
## ocupa el ancho: así toda la fila responde al clic sin tener que inventar un
## control nuevo ni capturar eventos a mano.
## EL RETRATO DE UN JUGADOR, EN UN SOLO SITIO. Antes cada pantalla lo montaba
## por su cuenta -cuatro trozos de código casi iguales- y por eso la mayoría
## simplemente no lo ponía: en cantera, enfermería, camarín, contratos,
## selección o el árbol genealógico un futbolista era una línea de texto.
##
## Y eso se notaba justo donde más duele: un jugador REAL con su foto de verdad
## encontrada en Commons aparecía con foto en el plantel y sin ella en la
## enfermería, como si fuera otra persona. `Cara.textura()` ya resuelve foto real
## primero y dibujo procedural después; lo único que faltaba era llamarla desde
## todas partes.
func _retrato(j: Jugador, tam: int = 26) -> TextureRect:
	var equipo: Club = mundo.clubes.get(j.club_id)
	var r := TextureRect.new()
	r.texture = Cara.textura(j, equipo.color1 if equipo else "#2b6b45",
		equipo.color2 if equipo else "#ffffff", tam)
	r.custom_minimum_size = Vector2(tam, tam)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _nombres(clubes: Array) -> String:
	var l: Array[String] = []
	for c: Club in clubes:
		l.append(c.nombre)
	return ", ".join(l)

func _nombres_jugadores(l: Array[Jugador]) -> String:
	var n: Array[String] = []
	for j in l:
		n.append(j.nombre)
	return ", ".join(n)
