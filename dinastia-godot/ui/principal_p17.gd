extends "res://ui/principal_p16.gd"
## (Parte 17 de 18 de `principal.gd`.)

## LA RUEDA DE PRENSA, DE PANTALLA COMPLETA.
##
## El usuario la comparó con la conferencia de prensa de FC26 -pantalla
## entera, cámara y todo lo demás oculto mientras dura- y marcó que "eso
## debería tener su propio lugar". La primera versión la encogía dentro de
## la misma tarjetita de "asuntos pendientes" que comparte con el agente que
## presiona o el jugador que te busca: un `SubViewport` de 900×360 compitiendo
## por espacio con la barra superior y la tabla de posiciones. Ahora es una
## cinemática de pantalla completa, MISMO PATRÓN que `Sorteo`
## (`_siguiente_sorteo()`, más arriba en este archivo): un `Control` colgado
## directo de `self`, por encima de todo, que se cierra solo al responder.
##
## SIGUE SIN INVENTAR DIÁLOGO. La pregunta, las opciones y el "cómo lo dices"
## son exactamente los mismos datos de siempre (`Prensa.entrevista`); esto
## solo cambia DÓNDE se presentan.
func _abrir_rueda_pantalla_completa(e: Dictionary) -> void:
	var pop := Control.new()
	pop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.mouse_filter = Control.MOUSE_FILTER_STOP
	pop.add_to_group(MentorVoz.GRUPO_TAPA)
	add_child(pop)
	_rueda_pop = pop

	var fondo := ColorRect.new()
	fondo.color = Color(0.035, 0.038, 0.045)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop.add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 48.0; raiz.offset_right = -48.0
	raiz.offset_top = 28.0; raiz.offset_bottom = -28.0
	raiz.add_theme_constant_override("separation", 10)
	pop.add_child(raiz)

	var t := _texto(13, COL_ACENTO)
	t.text = Idiomas.t("🎙️ RUEDA DE PRENSA")
	raiz.add_child(t)

	## EL PLATÓ 3D. Con pantalla completa ya no hace falta encogerlo a 220 px
	## de alto: se le da la mayor parte del espacio -`SIZE_EXPAND_FILL`- y una
	## resolución de `SubViewport` bastante mayor, para que se note el salto.
	var caja := Control.new()
	caja.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.clip_contents = true
	raiz.add_child(caja)

	var vp_cont := SubViewportContainer.new()
	vp_cont.stretch = true
	vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(vp_cont)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1600, 720)
	vp_cont.add_child(vp)
	var escena := RuedaPrensaEscena3D.new()
	vp.add_child(escena)
	var mio := mundo.mi_club()
	## QUIÉN HABLA DE VERDAD (14-9-2026). Si el jugador no es él mismo el
	## entrenador -ayudante de campo, director deportivo, dueño con el banco
	## delegado-, `Roles.dt_empleado` no está vacío: es ESE quien da la rueda
	## de prensa, no el jugador -mostrar tu propia cara ahí sería que el dueño
	## del club diera la conferencia técnica en tu lugar-. El empleado no
	## tiene editor de aspecto propio -nadie personaliza a alguien que no
	## eres tú-, así que `CaraDT.look_de_nombre()` le da uno determinístico
	## por su nombre: el mismo empleado siempre sale igual.
	var nombre_dt := ""
	var look_dt := {}
	if mundo.roles != null:
		if not mundo.roles.dt_empleado.is_empty():
			nombre_dt = mundo.roles.dt_nombre()
			look_dt = CaraDT.look_de_nombre(nombre_dt)
		else:
			nombre_dt = mundo.roles.nombre
			look_dt = mundo.roles.look_efectivo()
	## EL FONDO: los escudos de tu liga, no sponsors genéricos (14-9-2026). La
	## rueda de prensa solo se abre tras un partido de LIGA
	## (`Mundo.rueda_tras_resultado()`, ver `nucleo/prensa.gd`), así que la
	## competencia correspondiente es siempre tu propia liga.
	var clubes_competencia: Array = []
	## Tras una copa o un continental (C1), los escudos de ESA competición.
	if mundo.prensa != null and mundo.prensa.competicion_rueda != "liga" and not mundo.prensa.clubes_rueda.is_empty():
		clubes_competencia = mundo.prensa.clubes_rueda
	elif mio != null:
		var liga := mundo.liga_de(mio)
		if liga != null:
			clubes_competencia = liga.clubes
	if mio != null:
		escena.montar(mio, COL_ACENTO, Calidad.ALTO, look_dt, clubes_competencia)

	## LA PLACA DEL DT, arriba a la izquierda -mismo "chyron" con foto y
	## nombre que pone cualquier transmisión de verdad cuando habla alguien-.
	if not nombre_dt.is_empty():
		var placa := PanelContainer.new()
		placa.set_anchors_preset(Control.PRESET_TOP_LEFT)
		placa.offset_left = 14.0; placa.offset_top = 14.0
		placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_placa := StyleBoxFlat.new()
		sb_placa.bg_color = Color(0, 0, 0, 0.6)
		sb_placa.content_margin_left = 8.0; sb_placa.content_margin_right = 12.0
		sb_placa.content_margin_top = 6.0; sb_placa.content_margin_bottom = 6.0
		sb_placa.corner_radius_top_left = 6; sb_placa.corner_radius_top_right = 6
		sb_placa.corner_radius_bottom_left = 6; sb_placa.corner_radius_bottom_right = 6
		placa.add_theme_stylebox_override("panel", sb_placa)
		caja.add_child(placa)
		var fila_placa := HBoxContainer.new()
		fila_placa.add_theme_constant_override("separation", 8)
		placa.add_child(fila_placa)
		var foto_dt := TextureRect.new()
		foto_dt.texture = CaraDT.textura(look_dt, 36)
		foto_dt.custom_minimum_size = Vector2(36, 36)
		foto_dt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto_dt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila_placa.add_child(foto_dt)
		var nom_dt := _texto(12, COL_TEXTO)
		nom_dt.text = nombre_dt
		nom_dt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila_placa.add_child(nom_dt)

	## EL SUBTÍTULO, sobre la imagen -el "lower third" de la foto de Ancelotti
	## que mandó el usuario-. Alto fijo con `offset_top` negativo, no un
	## preset a secas: un `Control` no recorta a sus hijos solo, y un preset
	## sin offset propio da alto CERO justo donde termina la caja, así que el
	## contenido se derrama hacia abajo -se vio en la primera captura, tapando
	## los controles de más abajo-.
	var subt := PanelContainer.new()
	subt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subt.offset_top = -84.0
	subt.offset_bottom = 0.0
	subt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.72)
	sb.content_margin_left = 18.0; sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0; sb.content_margin_bottom = 10.0
	subt.add_theme_stylebox_override("panel", sb)
	caja.add_child(subt)
	var col_subt := VBoxContainer.new()
	col_subt.add_theme_constant_override("separation", 3)
	subt.add_child(col_subt)
	var quien := _texto(11, COL_ACENTO)
	col_subt.add_child(quien)
	var q := _texto(15, COL_TEXTO)
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col_subt.add_child(q)
	_rueda_quien = quien
	_rueda_pregunta = q

	raiz.add_child(_ui_despacho._fila_posturas())
	_rueda_opciones = _ui_despacho._fila_opciones_rueda(e)
	raiz.add_child(_rueda_opciones)
	raiz.add_child(_ui_despacho._fila_texto_libre())
	## EL RELOJ DE LA SALA (B5, "lenguaje corporal"): una barra que se llena en
	## `Prensa.TITUBEO_SEG` segundos. Cuando se llena, contestar ya cuenta como
	## titubeo. Se ve para que no sea una trampa.
	var reloj := ProgressBar.new()
	reloj.show_percentage = false
	reloj.custom_minimum_size = Vector2(0, 6)
	reloj.max_value = Prensa.TITUBEO_SEG
	raiz.add_child(reloj)
	_rueda_reloj = reloj
	_ui_despacho._pintar_pregunta_rueda(e)

## Repinta solo la fila de posturas -el botón que se marca al tocar una-, sin
## tocar el plató 3D ni las opciones.
func _repintar_posturas() -> void:
	if _rueda_pop == null:
		return
	var raiz := _rueda_pop.get_child(1) as VBoxContainer
	if raiz == null or raiz.get_child_count() < 3:
		return
	var vieja := raiz.get_child(2)
	raiz.remove_child(vieja)
	vieja.queue_free()
	raiz.add_child(_ui_despacho._fila_posturas())
	raiz.move_child(raiz.get_child(raiz.get_child_count() - 1), 2)

func _responder(i: int) -> void:
	_ui_despacho._tras_responder(mundo.prensa.responder(i, _ui_despacho._segundos_rueda()))

# --- las tres pestañas nuevas ----------------------------------------------

## EL MUSEO DEL CLUB. `Instalaciones` deja construirlo y cobra ingresos por él
## desde el porte, pero no tenía CONTENIDO: se pagaba un edificio cuyo interior
## no existía en ninguna pantalla.
##
## Las piezas no se guardan aparte: se deducen de lo que el club ya tiene
## anotado —trofeos, récords, goleadores— igual que el salón de la fama. Una
## lista paralela sería otro sitio más que mantener al día.
func _pintar_museo(lg: Logros) -> void:
	if mundo.obras == null or mundo.obras.nivel("museo") <= 0:
		return
	var piezas := lg.piezas_del_museo()
	_lista_logros.add_child(HSeparator.new())
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("🏛️ MUSEO DEL CLUB  ·  nivel %d  ·  %d pieza(s)") % [mundo.obras.nivel("museo"), piezas.size()]
	_lista_logros.add_child(t)
	if piezas.is_empty():
		var vac := _texto(11, COL_SUAVE)
		vac.text = Idiomas.t("El museo está construido pero las vitrinas están vacías. Gana algo y se irán llenando solas.")
		vac.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_logros.add_child(vac)
	else:
		for p: Dictionary in piezas:
			var l := _texto(12, COL_ORO)
			l.text = "%s  %s" % [String(p["icono"]), String(p["titulo"])]
			_lista_logros.add_child(l)
			var d := _texto(10, COL_SUAVE)
			d.text = "     %s" % String(p["detalle"])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lista_logros.add_child(d)

	## EL COMPARADOR DE GENERACIONES. No compara jugadores uno a uno —eso sería
	## inventarse datos de gente retirada— sino la media del mejor plantel que
	## has tenido contra la del de ahora, que es la pregunta de verdad.
	var comp: Dictionary = lg.comparador_de_generaciones()
	if comp.is_empty():
		return
	var tc := _texto(11, COL_SUAVE)
	tc.text = Idiomas.t("⚖️ AQUEL EQUIPO Y ESTE")
	_lista_logros.add_child(tc)
	_dato("Tu mejor plantilla", "%d  ·  quedó %d.º  ·  figura: %s" % [
		int(comp["anio"]), int(comp["puesto"]), String(comp["mvp"])], COL_ORO, _lista_logros)
	_dato("Media del plantel de hoy", "%.1f" % float(comp["media_actual"]), COL_TEXTO, _lista_logros)

## EL LOGO DE UN SPONSOR, mismo patrón que `_escudo()` de arriba: la textura
## de `Marca` debajo y las iniciales encima con el color de contraste que
## corresponda. Antes de esto un sponsor era solo una palabra pintada del
## color de la tabla -ver la nota de `Marca` para el porqué-.
func _marca(nombre: String, color_hex: String, alto: int = 28) -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(alto, alto)
	var t := TextureRect.new()
	t.texture = Marca.textura(nombre, color_hex, alto)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(t)
	var l := Label.new()
	l.text = Marca.iniciales(nombre)
	l.add_theme_font_size_override("font_size", maxi(8, alto / 2 - 2))
	l.add_theme_color_override("font_color", _tinta(Color(color_hex)))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_child(l)
	return caja

## Abre la ciudad y arranca directamente el paseo ("pie") o la conducción ("coche").
func _ver_ciudad_explorando(modo: String) -> void:
	await _ver_ciudad_con_carga()
	for h in get_children():
		if h is VistaCiudad:
			(h as VistaCiudad).explorar(modo)

func _deshacer() -> void:
	if _pila_deshacer.is_empty():
		_escribir("[color=#c9a227]No hay nada que deshacer.[/color]")
		return
	var u: Dictionary = _pila_deshacer.pop_back()
	var m := Partida.desde_instantanea(u["estado"])
	if m == null:
		_escribir("[color=#e05555]No se pudo deshacer.[/color]")
		return
	mundo = m
	_conectar_noticias()
	_seleccionado = null
	_llenar_selector()
	_escribir("[color=#3fa06a]Deshecho:[/color] %s." % String(u["motivo"]))
	_refrescar()

func _pintar_tipografia() -> void:
	var lt := _texto(10, COL_SUAVE)
	lt.text = Idiomas.t("Tipografia")
	_lista_ajustes.add_child(lt)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 4)
	flow.add_theme_constant_override("v_separation", 4)
	_lista_ajustes.add_child(flow)
	for k: String in TIPOGRAFIAS:
		var clave := k
		var b := Button.new()
		b.text = String((TIPOGRAFIAS[k] as Array)[0])
		b.add_theme_font_size_override("font_size", 10)
		b.toggle_mode = true
		b.button_pressed = _tipografia == clave
		b.clip_text = true
		b.custom_minimum_size = Vector2(132, 24)
		## Cada boton se escribe CON su fuente: se elige mirando, igual que las
		## paletas. Un nombre de fuente no dice nada; verla, si.
		var f := _fuente_de(clave)
		if f != null:
			b.add_theme_font_override("font", f)
		b.pressed.connect(func() -> void:
			_tipografia = clave
			_aplicar_aspecto()
			_refrescar())
		flow.add_child(b)

func _aplicar_vista_compacta() -> void:
	var sep := SEPARACION_COMPACTA if _vista_compacta else SEPARACION_NORMAL
	var t := theme if theme != null else Theme.new()
	for clase: String in ["BoxContainer", "VBoxContainer", "HBoxContainer"]:
		t.set_constant("separation", clase, sep)
	t.set_constant("margin_top", "MarginContainer", sep)
	t.set_constant("margin_bottom", "MarginContainer", sep)
	theme = t

func _alternar_favorito(tab: String) -> void:
	if _favoritos.has(tab):
		_favoritos.erase(tab)
	elif _favoritos.size() < FAVORITOS_MAX:
		_favoritos.append(tab)
	_refrescar()

func _guardar_en(nombre: String) -> void:
	if Partida.guardar(mundo, nombre):
		_escribir("[color=#4caf6d]Guardado en %s.[/color] %s, %d, semana %d." % [
			nombre, mundo.mi_club().nombre, mundo.anio, mundo.semana])
	else:
		_escribir("[color=#e05555]No se pudo guardar en %s.[/color]" % nombre)
	_refrescar()

func _cargar_de(nombre: String) -> void:
	var m := Partida.cargar(nombre)
	if m == null:
		_escribir("[color=#c9a227]Esa ranura está vacía.[/color]")
		return
	mundo = m
	_conectar_noticias()
	_escribir("[color=#4caf6d]Partida cargada de %s.[/color]" % nombre)
	_avisar_si_respaldo()
	_refrescar()
	_resolver_partido_abandonado()

func _pintar_ranuras() -> void:
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("RANURAS DE GUARDADO")
	_lista_ajustes.add_child(t)
	var ex := _texto(10, COL_SUAVE)
	ex.text = Idiomas.t("Aparte del autoguardado. Sirven para dejar una copia antes de una decisión de la que no se vuelve.")
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lista_ajustes.add_child(ex)
	## Se lista una vez y se busca en memoria: `Partida.listar()` abre y lee la
	## cabecera de cada fichero, y llamarlo tres veces sería leer el disco tres
	## veces para pintar tres filas.
	var guardadas := {}
	for f: Dictionary in Partida.listar():
		guardadas[String(f.get("fichero", ""))] = f
	for i in RANURAS.size():
		var nombre := String(RANURAS[i])
		var hay: Dictionary = guardadas.get(nombre, {})
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_lista_ajustes.add_child(fila)
		var et := _texto(12, COL_TEXTO if not hay.is_empty() else COL_SUAVE)
		et.text = Idiomas.t("Ranura %d") % (i + 1)
		et.custom_minimum_size = Vector2(70, 0)
		fila.add_child(et)
		var desc := _texto(11, COL_SUAVE)
		desc.text = Idiomas.t("%s · %d, semana %d") % [String(hay.get("club", "")), int(hay.get("anio", 0)), int(hay.get("semana", 0))] if not hay.is_empty() else Idiomas.t("vacía")
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.clip_text = true
		fila.add_child(desc)
		var bg := Button.new()
		bg.text = Idiomas.t("Guardar")
		bg.add_theme_font_size_override("font_size", 11)
		bg.pressed.connect(func() -> void: _guardar_en(nombre))
		fila.add_child(bg)
		var bc := Button.new()
		bc.text = Idiomas.t("Cargar")
		bc.add_theme_font_size_override("font_size", 11)
		bc.disabled = hay.is_empty()
		bc.pressed.connect(func() -> void: _cargar_de(nombre))
		fila.add_child(bc)
	_lista_ajustes.add_child(HSeparator.new())

## Salta al chip de al lado dentro del bloque actual (los gatillos de
## siempre). Ahora los chips son diccionarios {tab, secc, label}, así que la
## posición se busca comparando pestaña Y sección, no el título a secas.
func _saltar_pestana(d: int) -> void:
	var chips: Array = _grupo_por_id(_grupo_actual).get("tabs", [])
	if chips.is_empty():
		return
	var titulo := _pestanas.get_tab_title(_pestanas.current_tab)
	var i := 0
	for k in chips.size():
		var chip: Dictionary = chips[k]
		if String(chip["tab"]) == titulo and _seccion_activa(chip):
			i = k
			break
	_ir_a_chip(chips[(i + d + chips.size()) % chips.size()])
