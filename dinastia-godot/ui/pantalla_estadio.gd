class_name PantallaEstadio
extends "res://ui/pantalla_estadio_p1.gd"
## (Parte 2 de 2 de `pantalla_estadio.gd`.)

func _panel_gol() -> Control:
	if partido == null:
		return null
	var c := _base("")
	_fondo_gol = ColorRect.new()
	_fondo_gol.color = Color(0.08, 0.42, 0.24)
	_fondo_gol.position = Vector2(0, 12)
	_fondo_gol.size = Vector2(ANCHO, ALTO - 12)
	c.add_child(_fondo_gol)
	var g := _etiqueta("¡GOOOL!", 116, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	g.position = Vector2(0, 60)
	g.size = Vector2(ANCHO, 140)
	c.add_child(g)
	_lbl_gol_autor = _etiqueta("", 52, COL_AMBAR, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_gol_autor.position = Vector2(48, 212)
	_lbl_gol_autor.size = Vector2(ANCHO - 96, 66)
	c.add_child(_lbl_gol_autor)
	_lbl_gol_min = _etiqueta("", 28, Color(1, 1, 1, 0.82), HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_gol_min.position = Vector2(48, 288)
	_lbl_gol_min.size = Vector2(ANCHO - 96, 40)
	c.add_child(_lbl_gol_min)
	_lbl_gol_marcador = _etiqueta("0 - 0", 72, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_gol_marcador.position = Vector2(48, 344)
	_lbl_gol_marcador.size = Vector2(ANCHO - 96, 96)
	c.add_child(_lbl_gol_marcador)
	return c

## LOS CRUCES DE LA RONDA (26-9-2026): en una copa no hay tabla, y enseñar la
## de la liga en un partido de copa era mentirle al estadio. Hasta seis cruces;
## el de los dos que están jugando, resaltado.
func _panel_cruces() -> Control:
	var filas: Array = datos.get("cruces", [])
	if filas.is_empty():
		return null
	var c := _base("CRUCES  ·  " + String(datos.get("liga", "")).to_upper())
	var y := 96.0
	for i in mini(6, filas.size()):
		var par: Array = filas[i]
		var txt := "%s   vs   %s" % [String(par[0]), String(par[1])]
		var es_este := casa != null and (String(par[0]) == casa.nombre or String(par[1]) == casa.nombre)
		var fila := _fila_tabla("", txt, "", "", _color_casa() if es_este else COL_TINTA, 28)
		fila.position = Vector2(48, y)
		fila.size = Vector2(ANCHO - 96, 44)
		c.add_child(fila)
		y += 52.0
	_pie(c)
	return c

## Qué paneles entran en la rotación. Se recalcula cuando cae el primer gol
## (antes de eso, el panel de goleadores del partido estaría vacío).
func _rehacer_orden() -> void:
	_orden.clear()
	if partido != null:
		_orden.append(Pagina.MARCADOR)
		_orden.append(Pagina.ESTADISTICAS)
		if not _goles.is_empty():
			_orden.append(Pagina.GOLES)
	else:
		_orden.append(Pagina.BIENVENIDA)
	if not (datos.get("tabla", []) as Array).is_empty():
		_orden.append(Pagina.TABLA)
	if not (datos.get("cruces", []) as Array).is_empty():
		_orden.append(Pagina.CRUCES)
	if not (datos.get("goleadores", []) as Array).is_empty():
		_orden.append(Pagina.PICHICHI)

## Público a propósito: la prueba de captura fuerza cada panel en vez de
## esperar siete segundos de reloj real por cada uno.
func mostrar(p: int) -> void:
	for k: int in _paneles:
		var c: Control = _paneles[k]
		if c != null:
			c.visible = (k == p)
	pagina_visible = p
	render_target_update_mode = SubViewport.UPDATE_ONCE

func _casa_es_local() -> bool:
	return partido == null or casa == null or partido.local == casa

func _par_stat(clave: String, val_local: int, val_visita: int, soy_local: bool) -> void:
	var a: Label = _lbl_stats.get(clave + "_a")
	var b: Label = _lbl_stats.get(clave + "_b")
	if a != null:
		a.text = str(val_local if soy_local else val_visita)
	if b != null:
		b.text = str(val_visita if soy_local else val_local)

func _refrescar_stats() -> void:
	if _lbl_stats.is_empty() or partido == null:
		return
	var soy_local := _casa_es_local()
	_par_stat("remates", partido.remates_local, partido.remates_visita, soy_local)
	_par_stat("arco", partido.tiros_puerta_local, partido.tiros_puerta_visita, soy_local)
	_par_stat("corners", partido.corners_local, partido.corners_visita, soy_local)
	_par_stat("faltas", partido.faltas_local, partido.faltas_visita, soy_local)

## Repinta solo lo que cambia con el partido. Barato a propósito: se llama en
## cada frame y no crea ni destruye nada, solo reescribe texto.
func refrescar() -> void:
	if partido == null:
		return
	if _lbl_marcador != null:
		_lbl_marcador.text = "%d - %d" % [partido.goles_local, partido.goles_visita]
	if _lbl_reloj != null:
		_lbl_reloj.text = "%d'" % partido.minuto
	var pos_l := clampf(partido.posesion_local, 0.0, 100.0)
	## `posesion_local` es siempre la del LOCAL. Si el dueño del recinto juega
	## de visita -un estadio neutral, una final-, hay que darle la vuelta o la
	## pantalla anunciaría la posesión del rival con el escudo de casa.
	var pos_casa := pos_l if _casa_es_local() else 100.0 - pos_l
	if _lbl_pos_casa != null:
		_lbl_pos_casa.text = "%d%%" % int(round(pos_casa))
	if _lbl_pos_rival != null:
		_lbl_pos_rival.text = "%d%%" % int(round(100.0 - pos_casa))
	if _barra_pos != null:
		_barra_pos.size.x = maxf(4.0, 720.0 * pos_casa / 100.0)
	_refrescar_stats()

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = COL_FONDO
	fondo.position = Vector2.ZERO
	fondo.size = Vector2(ANCHO, ALTO)
	add_child(fondo)

	## La franja de arriba lleva el color del club de casa: es lo único de la
	## pantalla que cambia de estadio a estadio, y basta para que no se vean
	## todas iguales. NO se usa como fondo -ese fue el bug del 22-9: un club de
	## camiseta negra daba una pantalla negra con el texto perdido encima-.
	var acento := ColorRect.new()
	acento.color = _color_casa()
	acento.position = Vector2.ZERO
	acento.size = Vector2(ANCHO, 12)
	add_child(acento)

	_paneles[Pagina.MARCADOR] = _panel_marcador()
	_paneles[Pagina.ESTADISTICAS] = _panel_estadisticas()
	_paneles[Pagina.GOLES] = _panel_goles()
	_paneles[Pagina.TABLA] = _panel_tabla()
	_paneles[Pagina.PICHICHI] = _panel_pichichi()
	_paneles[Pagina.BIENVENIDA] = _panel_bienvenida()
	_paneles[Pagina.GOL] = _panel_gol()
	_paneles[Pagina.CRUCES] = _panel_cruces()
	for k: int in _paneles:
		var c: Control = _paneles[k]
		if c == null:
			continue
		## Cada panel recorta lo suyo. Es el candado contra el bug de la
		## primera pasada: un `Label` con texto más ancho que su hueco empuja
		## al contenedor y se sale del lienzo; con `clip_contents` lo peor que
		## puede pasar es que se corte por el borde del panel, nunca que
		## desborde la pantalla.
		c.clip_contents = true
		c.visible = false
		add_child(c)

	_rehacer_orden()
	mostrar(_orden[0] if not _orden.is_empty() else Pagina.MARCADOR)
	refrescar()

## `p` puede ser null: entonces la pantalla se queda en modo "bienvenida" +
## tabla + goleadores, que es lo que enseña un estadio el día que no se juega.
func montar(club_casa: Club, club_rival: Club, p: Partido, d: Dictionary,
		recinto: String = "") -> void:
	casa = club_casa
	rival = club_rival
	partido = p
	datos = d
	nombre_recinto = recinto
	size = Vector2i(ANCHO, ALTO)
	## A RITMO DE MARCADOR, NO DE FOTOGRAMA (25-9-2026). Con `UPDATE_ALWAYS`
	## la pantalla entera se volvía a dibujar 60 veces por segundo para
	## enseñar un minuto que cambia cada segundo y un panel que rota cada
	## siete. Ahora se dibuja al cambiar de panel y cuatro veces por segundo
	## (`_process()`), que es de sobra para el reloj.
	render_target_update_mode = SubViewport.UPDATE_ONCE
	transparent_bg = false
	## Aquí dentro solo hay `Control`s. Sin esto el viewport arrastra toda la
	## maquinaria 3D en cada repintado -y se repinta en cada frame- para no
	## dibujar nada.
	disable_3d = true
	_construir()

func _process(delta: float) -> void:
	_t_redibujo += delta
	if _t_redibujo >= SEG_REDIBUJO:
		_t_redibujo = 0.0
		render_target_update_mode = SubViewport.UPDATE_ONCE
	## BUG REAL, ENCONTRADO CON LA PRUEBA DE CAPTURA (23-9-2026): este
	## `refrescar()` estaba DESPUÉS del `return` del corte de gol, así que
	## durante los 6,5 s del "¡GOOOL!" el marcador de debajo no se enteraba del
	## gol -y al volver a la rotación seguía diciendo el resultado anterior
	## hasta el siguiente frame-. La prueba lo cazó pidiendo "1 - 0" y leyendo
	## "0 - 0". Va lo primero y sin condiciones: es barato (solo reescribe
	## texto) y así no hay ningún camino que se lo salte.
	refrescar()
	if _gol_restante > 0.0:
		_gol_restante -= delta
		if _gol_restante <= 0.0:
			_rehacer_orden()
			_idx = 0
			_t = 0.0
			mostrar(_orden[0] if not _orden.is_empty() else Pagina.MARCADOR)
		return
	if _orden.size() > 1:
		_t += delta
		var tope := SEG_MARCADOR if _orden[_idx] == Pagina.MARCADOR else SEG_PANEL
		if _t >= tope:
			_t = 0.0
			_idx = (_idx + 1) % _orden.size()
			mostrar(_orden[_idx])

## Los últimos seis, de más nuevo a más viejo: en un 5-4 no caben los nueve y
## lo que importa es lo que acaba de pasar.
func _repintar_goles() -> void:
	if _caja_goles == null:
		return
	for h in _caja_goles.get_children():
		h.queue_free()
	var desde: int = maxi(0, _goles.size() - 6)
	for i in range(_goles.size() - 1, desde - 1, -1):
		var g: Dictionary = _goles[i]
		var fila := HBoxContainer.new()
		fila.custom_minimum_size = Vector2(0, 52)
		fila.add_theme_constant_override("separation", 18)
		var min_l := _etiqueta("%d'" % int(g["min"]), 32, COL_AMBAR, HORIZONTAL_ALIGNMENT_RIGHT)
		min_l.custom_minimum_size = Vector2(80, 48)
		fila.add_child(min_l)
		var nom := _etiqueta(String(g["autor"]).to_upper(), 32,
			COL_TINTA if bool(g["casa"]) else COL_SUAVE)
		nom.custom_minimum_size = Vector2(540, 48)
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nom)
		var eq := _etiqueta(String(g["abrev"]), 30,
			_color_casa() if bool(g["casa"]) else COL_SUAVE, HORIZONTAL_ALIGNMENT_RIGHT)
		eq.custom_minimum_size = Vector2(110, 48)
		fila.add_child(eq)
		_caja_goles.add_child(fila)

# --- el corte a "¡GOL!" -----------------------------------------------------

## Lo llama `VistaEstadio._al_gol()`. El marcador que se pinta ya viene subido
## -esta pantalla nunca cuenta goles por su cuenta, solo enseña los de
## `Partido`-, así que se lee después de que el simulador haya hecho lo suyo.
func al_gol(club_gol: Club, autor: Jugador, minuto: int) -> void:
	var de_casa := club_gol == casa
	_goles.append({
		"min": minuto,
		"autor": autor.nombre if autor != null else "—",
		"abrev": abreviatura(club_gol),
		"casa": de_casa,
	})
	_repintar_goles()
	if _lbl_gol_autor != null:
		_lbl_gol_autor.text = (autor.nombre if autor != null else Idiomas.t("GOL")).to_upper()
	if _lbl_gol_min != null:
		_lbl_gol_min.text = Idiomas.t("MINUTO %d  ·  %s") % [minuto, abreviatura(club_gol)]
	if _lbl_gol_marcador != null and partido != null:
		_lbl_gol_marcador.text = "%d - %d" % [partido.goles_local, partido.goles_visita]
	if _fondo_gol != null:
		## Verde si anota la casa, rojo si la sufre. Es el mismo criterio que ya
		## usa el cartel 2D de `estadio.gd`, para que la pantalla y el HUD no se
		## contradigan en el mismo instante.
		_fondo_gol.color = Color(0.08, 0.42, 0.24) if de_casa else Color(0.40, 0.10, 0.12)
	_gol_restante = SEG_GOL
	mostrar(Pagina.GOL)
	## Y el marcador de debajo, ya: quien mire la pantalla justo cuando se
	## apaga el "¡GOOOL!" tiene que ver el resultado nuevo, no el de antes.
	refrescar()
