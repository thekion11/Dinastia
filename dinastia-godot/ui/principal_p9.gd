extends "res://ui/principal_p8.gd"
## [Capa 9/19 de `principal.gd`] _traducir_pantalla, _refrescar, _avanzar_semana, _avanzar_dia, _pintar_dias, _exit_tree … (+1)

## LA MÚSICA. Seis piezas sintetizadas, como todo el audio del juego: ni un solo
## fichero, ni una licencia de terceros que arrastrar en el paquete.
##
## Va aparte del mezclador de efectos a propósito. La música se apaga entera
## mucho más a menudo que los efectos —hay gente que juega a esto con un podcast
## de fondo—, y tenerla en el mismo grupo obligaba a bajar el silbato para no oír
## el arpegio.
## RECORRE LA PANTALLA Y TRADUCE. Ver la explicación larga en `nucleo/idiomas.gd`.
##
## Solo toca `Label`, `Button` y `OptionButton`, que es donde vive el esqueleto
## de la interfaz. NO toca `RichTextLabel` -ahí va la narración, que sigue en
## castellano- ni `LineEdit` -ahí escribe el usuario-.
##
## Guarda en metadatos del propio nodo el texto castellano original (`_i18n_src`)
## y lo último que ESTA función escribió (`_i18n_out`): si el texto actual
## coincide con lo último que ella misma puso, nadie lo tocó desde entonces y
## usa el castellano guardado como fuente; si NO coincide, es que un repintado
## puso texto castellano fresco (nombre de jugador, cifra...) y lo adopta como
## la nueva fuente. SIN esto, un nodo que se construye UNA sola vez y nunca se
## repinta -"Guardar"/"Cargar"/"Otro mundo" de la fila de acciones, tooltips-
## se quedaba pegado en el último idioma elegido para siempre, sin volver al
## castellano al cambiar de vuelta: bug real, sospechado el 10-9-2026 en una
## captura ("Save"/"Load"/"New world" seguían en inglés tras forzar `idioma="es"`)
## y confirmado y corregido aquí el 12-9-2026.
func _traducir_pantalla(n: Node) -> void:
	if n == self:
		if Idiomas.idioma == "es" and not _traduccion_activa:
			return
		if Idiomas.idioma != "es":
			_traduccion_activa = true
	if n is Label:
		var l := n as Label
		var actual := l.text
		var fue_mio: bool = l.has_meta("_i18n_out") and String(l.get_meta("_i18n_out")) == actual
		var base: String = String(l.get_meta("_i18n_src")) if fue_mio else actual
		var nuevo := base if Idiomas.idioma == "es" else Idiomas.t(base)
		l.set_meta("_i18n_src", base)
		l.set_meta("_i18n_out", nuevo)
		l.text = nuevo
	elif n is OptionButton:
		## El desplegable, por dentro: cada entrada por separado. El texto del
		## botón lo pinta Godot con la entrada elegida, así que no hay que tocarlo.
		var ob := n as OptionButton
		var outs: Array = ob.get_meta("_i18n_out") if ob.has_meta("_i18n_out") else []
		var srcs: Array = ob.get_meta("_i18n_src") if ob.has_meta("_i18n_src") else []
		var nuevos_src: Array = []
		var nuevos_out: Array = []
		for i in ob.item_count:
			var actual_i := ob.get_item_text(i)
			var fue_mio_i: bool = i < outs.size() and String(outs[i]) == actual_i
			var base_i: String = String(srcs[i]) if (fue_mio_i and i < srcs.size()) else actual_i
			var nuevo_i := base_i if Idiomas.idioma == "es" else Idiomas.t(base_i)
			ob.set_item_text(i, nuevo_i)
			nuevos_src.append(base_i)
			nuevos_out.append(nuevo_i)
		ob.set_meta("_i18n_src", nuevos_src)
		ob.set_meta("_i18n_out", nuevos_out)
	elif n is Button:
		var b := n as Button
		var actual2 := b.text
		var fue_mio2: bool = b.has_meta("_i18n_out") and String(b.get_meta("_i18n_out")) == actual2
		var base2: String = String(b.get_meta("_i18n_src")) if fue_mio2 else actual2
		var nuevo2 := base2 if Idiomas.idioma == "es" else Idiomas.t(base2)
		b.set_meta("_i18n_src", base2)
		b.set_meta("_i18n_out", nuevo2)
		## Si el boton repartia ancho por el largo de su rotulo -la fila de
		## acciones-, el reparto se rehace con el rotulo NUEVO: "Temporada
		## siguiente" y "Next season" no piden lo mismo.
		if nuevo2 != actual2 and b.size_flags_stretch_ratio != 1.0:
			b.size_flags_stretch_ratio = clampf(float(nuevo2.length()) / 12.0, 0.95, 1.9)
		b.text = nuevo2
	elif n is LineEdit:
		## El texto de ayuda del campo ("🔎 Buscar..."), no lo que escribe el jugador.
		var le := n as LineEdit
		var actual_ph := le.placeholder_text
		if actual_ph != "":
			var fue_mio_ph: bool = le.has_meta("_i18n_ph_out") and String(le.get_meta("_i18n_ph_out")) == actual_ph
			var base_ph: String = String(le.get_meta("_i18n_ph_src")) if fue_mio_ph else actual_ph
			var nuevo_ph := base_ph if Idiomas.idioma == "es" else Idiomas.t(base_ph)
			le.set_meta("_i18n_ph_src", base_ph)
			le.set_meta("_i18n_ph_out", nuevo_ph)
			le.placeholder_text = nuevo_ph
	if n.has_method("get_tooltip_text") and n is Control:
		var ctrl := n as Control
		var actual_tip := ctrl.tooltip_text
		if actual_tip != "":
			var fue_mio_tip: bool = ctrl.has_meta("_i18n_tip_out") and String(ctrl.get_meta("_i18n_tip_out")) == actual_tip
			var base_tip: String = String(ctrl.get_meta("_i18n_tip_src")) if fue_mio_tip else actual_tip
			var nuevo_tip := base_tip if Idiomas.idioma == "es" else Idiomas.t(base_tip)
			ctrl.set_meta("_i18n_tip_src", base_tip)
			ctrl.set_meta("_i18n_tip_out", nuevo_tip)
			ctrl.tooltip_text = nuevo_tip
	for h in n.get_children():
		_traducir_pantalla(h)

func _refrescar() -> void:
	var c := mundo.mi_club()
	## Los objetivos, fijos en el borde derecho (PanelObjetivos).
	if not is_instance_valid(_panel_obj):
		_panel_obj = PanelObjetivos.crear(self, mundo.roles.modo_actual() if mundo.roles != null else "dt")
		add_child(_panel_obj)
	_panel_obj.refrescar()
	## Tu personaje 3D, a mano para la banda de cualquier estadio (la vista
	## del partido no tiene el mundo delante).
	PersonajeDT.del_usuario = mundo.roles.aspecto_3d()
	PersonajeDT.club_usuario = c.id if c != null else ""
	## El edificio del club (estadio 2.0) también necesita saber del mundo.
	if c != null:
		EdificioClub.ctx = _contexto_edificio(c)
		EdificioClub.mundo_ref = weakref(mundo)
	## Entrenadora: si tu personaje es mujer, toda la interfaz te trata como tal.
	Genero.fijar(String(PersonajeDT.aspecto(PersonajeDT.del_usuario)["cuerpo"]) == "female")
	var liga := _liga_de(c)
	var acento_antes := COL_ACENTO
	COL_ACENTO = _acento_de(c)
	## El acento sale de la identidad del club y tine tambien el tema -pestana
	## activa, boton pulsado, barras-. Al cambiar de club o de colores hay que
	## rehacerlo; comparando primero, para no reconstruir un Theme entero en cada
	## refresco cuando no ha cambiado nada.
	if acento_antes != COL_ACENTO:
		_aplicar_tema()
	_cabecera.text = c.nombre
	_limpiar(_escudo_cabecera)
	var e := _escudo(c, 44)
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escudo_cabecera.add_child(e)
	var dir_txt := ""
	if mundo.directiva != null:
		dir_txt = "  ·  %s  ·  confianza %d" % [mundo.directiva.objetivo, mundo.directiva.confianza]
	## La plata y la fecha ya no van en el texto corrido: viven arriba a la
	## derecha, en grande. Aquí queda lo que de verdad es contexto.
	## La caja CUENTA hasta su nuevo valor (plan maestro B11): un cobro o un
	## pago se ve moverse, y late una vez.
	if _saldo_mostrado != -1 and _saldo_mostrado != c.saldo and _lbl_caja.is_inside_tree():
		Animar.contar(_lbl_caja, float(_saldo_mostrado), float(c.saldo), func(v: float) -> String: return _dinero(int(v)))
		Animar.pulso(_lbl_caja, 1.06)
	else:
		_lbl_caja.text = _dinero(c.saldo)
	_saldo_mostrado = c.saldo
	_lbl_fecha.text = Idiomas.t("%s  ·  semana %d") % [fecha_larga(), mundo.semana]
	_sub.text = Idiomas.t("%s  ·  Jornada %d de %d  ·  Sueldos %s/sem  ·  Media %.1f%s") % [
		liga.nombre, liga.jornada_actual, liga.jornadas(),
		_dinero(c.masa_salarial()), c.media(), dir_txt]
	## El desafío invicto no bloquea nada por dentro -se puede seguir jugando,
	## como en el HTML-, solo avisa UNA vez de que la racha se acabó.
	if not mundo.fin_partida.is_empty() and not _fin_partida_avisado:
		_fin_partida_avisado = true
		_escribir("[color=#e05555][b]💀 FIN DE LA PARTIDA.[/b][/color] Cayó la primera derrota y con ella el desafío del invicto (semana %d de %d). Puedes seguir jugando, pero el desafío ya está perdido." % [
			int(mundo.fin_partida.get("semana", 0)), int(mundo.fin_partida.get("anio", 0))])
	## LA TABLA, MODULARIZADA (25-9-2026, pedido explícito del usuario: "que no
	## sea tan frágil"). Las cinco funciones que pintaban esto viven ahora en
	## `ui/componentes/tabla_competicion.gd`, como clase estática -no como
	## componente de escena, ver el porqué en su propio comentario de cabecera-.
	## Los colores van YA resueltos (paleta + modo daltónico), la lección del
	## bug de coherencia visual que se encontró y arregló en `PanelMercado`
	## esa misma sesión, aplicada desde el principio esta vez.
	_titulo_tabla.text = TablaCompeticion.titulo_de(mundo, liga, c)
	TablaCompeticion.pintar(_lista_tabla, mundo, liga, c, {
		"suave":  _pal_suave(),
		"texto":  _pal_texto(),
		"acento": COL_ACENTO,
		"verde":  _color_accesible(COL_VERDE),
		"rojo":   _color_accesible(COL_ROJO),
		"oro":    _color_accesible(COL_ORO),
		"escala": _escala_texto,
	})
	_ui_plantel._pintar_plantel(c)
	## El panel de mercado se actualiza con la paleta del club activo para que
	## el color de acento refleje siempre al equipo que se dirige.
	##
	## PUNTO 3, COHERENCIA VISUAL (25-9-2026): `verde`/`rojo`/`oro` viajaban
	## SIN pasar por `_color_accesible()` -el remapeo a la paleta Okabe-Ito
	## ("modo daltónico" de Ajustes) que el resto del juego sí respeta desde
	## que se centralizó "en `_texto()` en vez de en las mil llamadas"-. Con el
	## modo activado, la interfaz entera cambiaba de verde/rojo/oro a azul
	## cielo/bermellón/ámbar MENOS la pestaña Mercado -"mercado abierto",
	## "ganas de venir", si el fichaje es pagable, seguían en los colores
	## viejos-, justo la clase de incoherencia entre un componente nuevo y el
	## resto de la interfaz que el pedido de mejora señalaba.
	if _panel_mercado != null:
		_panel_mercado.inicializar(mundo, {
			"acento": COL_ACENTO,
			"texto":  _pal_texto(),
			"suave":  _pal_suave(),
			"verde":  _color_accesible(COL_VERDE),
			"rojo":   _color_accesible(COL_ROJO),
			"oro":    _color_accesible(COL_ORO),
		}, _negociacion_ultimo)
	_perezoso(_lista_copa, _ui_plantel._pintar_copa.bind(c))
	_perezoso(_lista_club, _ui_ficha._pintar_club.bind(c))
	_perezoso(_lista_conti, _ui_club_vida._pintar_conti.bind(c))
	_perezoso(_lista_medico, _ui_club_vida._pintar_medico.bind(c))
	_perezoso(_lista_logros, _ui_club_vida._pintar_logros)
	_perezoso(_lista_entren, _ui_club_vida._pintar_entrenamiento.bind(c))
	_perezoso(_lista_fed, _pintar_federacion.bind(c))
	_perezoso(_lista_estadio, _pintar_estadio.bind(c))
	_perezoso(_lista_seleccion, _ui_cantera._pintar_seleccion.bind(c))
	_perezoso(_lista_cantera, _ui_cantera._pintar_cantera.bind(c))
	_perezoso(_lista_contratos, _ui_cantera._pintar_contratos.bind(c))
	_perezoso(_lista_comparar, _ui_cantera._pintar_comparar)
	_perezoso(_lista_records, func() -> void:
		_ui_legado._pintar_records()
		_ui_legado._filtrar_records())
	_perezoso(_lista_legado, _ui_legado._pintar_legado)
	_ui_legado._pintar_inicio(c)
	## Las otras tres viven DENTRO de `_pintar_gente()` ahora -un chip por
	## sección, solo se pinta la que está activa- en vez de apilarse las
	## cuatro siempre, aunque solo una se vea.
	_perezoso(_lista_gente, _ui_gente._pintar_gente)
	_perezoso(_lista_finanzas, _pintar_finanzas.bind(c))
	_perezoso(_lista_camarin, _pintar_camarin.bind(c))
	_perezoso(_lista_ciudad, _pintar_ciudad.bind(c))
	_perezoso(_lista_editor, _ui_editor._pintar_editor)
	_perezoso(_lista_glosario, _ui_opciones._pintar_glosario)
	_perezoso(_lista_ajustes, _ui_ajustes._pintar_ajustes)
	_perezoso(_lista_correo, _ui_gente._pintar_correo)
	_perezoso(_lista_redes, func() -> void:
		_ui_gente._pintar_redes()
		_ui_gente._filtrar_redes())
	## Diferidas como las demás (etapa 1, 2.ª pasada): llamadas a pelo, con
	## la pestaña oculta no pintaban NI quedaban pendientes, y al entrar en
	## «Vida» o «Habilidades» la hoja salía vacía.
	_perezoso(_lista_vida, _ui_legado._pintar_vida)
	_perezoso(_lista_habilidades, _ui_legado._pintar_habilidades)
	_perezoso(_lista_libres, _ui_plantel._pintar_libres.bind(c))
	_perezoso(_lista_premios, _ui_plantel._pintar_premios)
	_perezoso(_lista_clubes, _pintar_clubes)
	_perezoso(_lista_desafios, _ui_plantel._pintar_desafios)
	_perezoso(_lista_tactica, _ui_plantel._pintar_tactica.bind(c))
	_perezoso(_lista_partido, _ui_plantel._pintar_partido.bind(c))
	_perezoso(_lista_calendario, _ui_plantel._pintar_calendario.bind(c))
	_pintar_dias()
	_actualizar_badges()
	_ui_despacho._pintar_despacho()
	_ver_ficha(_seleccionado if _seleccionado != null else _jugador_de_la_semana(c))
	## LO ÚLTIMO DE TODO: traducir. Ver `nucleo/idiomas.gd` -la interfaz se pinta
	## siempre en castellano y se traduce al final, para no tener que marcar dos
	## mil cadenas con `tr()` en un archivo de diez mil líneas-.
	_traducir_pantalla(self)
	## Y la música, que también depende de lo que esté pasando.
	Musica.ambientar(_ui_opciones._situacion_musical())

func _avanzar_semana() -> void:
	if not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada. Pulsa «Temporada siguiente».[/color]")
		return
	var mio := mundo.mi_club()
	var liga := _liga_de(mio)
	var caja_antes := mio.saldo
	## EL CIERRE DEL MERCADO TIENE QUE NOTARSE. Un mercado que cierra en
	## silencio es un boton que un dia deja de funcionar; avisado con dos
	## semanas, es una fecha limite y cambia como se juega esa quincena.
	if mundo.mercado_abierto() and mundo.semanas_de_mercado() <= 2 and _mercado_avisado != mundo.semana:
		_mercado_avisado = mundo.semana
		var q := mundo.semanas_de_mercado()
		Aviso.mostrar(self, "mercado", "⏳", "El mercado cierra",
			"Queda%s %d semana%s para el cierre. Lo que no fiches ahora, no lo fichas hasta la próxima ventana." % [
				"" if q == 1 else "n", q, "" if q == 1 else "s"], "mercado_cierra")
	## Se escucha esta jornada para contar lo que le pasó a TU club, que es lo
	## único que interesa de las 190 jornadas que se juegan en el mundo.
	var visto := {"txt": ""}
	var oyente := func(_n: int, resultados: Array) -> void:
		for r: Dictionary in resultados:
			if r["local"] == mio or r["visita"] == mio:
				var casa: bool = r["local"] == mio
				var rival: Club = r["visita"] if casa else r["local"]
				var gf: int = r["gl"] if casa else r["gv"]
				var gc: int = r["gv"] if casa else r["gl"]
				var col := "#4caf6d" if gf > gc else ("#e05555" if gf < gc else "#8ea595")
				visto["txt"] = "[color=%s]J%d  %s %d-%d %s[/color]  [color=#8ea595]%s[/color]" % [
					col, liga.jornada_actual, mio.nombre, gf, gc, rival.nombre,
					"en casa" if casa else "fuera"]
	liga.jornada_terminada.connect(oyente)
	mundo.avanzar_semana()
	liga.jornada_terminada.disconnect(oyente)
	if visto["txt"] != "":
		_escribir(visto["txt"])
	if mundo.semana % Finanzas.SEMANAS_DEL_MES == 1 and mundo.semana > 1:
		var delta := mio.saldo - caja_antes
		_escribir("[color=#c9a227]Cierre de mes:[/color] la caja %s %s" % [
			"sube" if delta >= 0 else "baja", _dinero(absi(delta))])
	_autoguardar_si_toca()
	_refrescar()

## Avanza UN día. Si con eso se pasa del domingo, la semana del motor corre de
## verdad -es el único punto donde esto toca la simulación-.
func _avanzar_dia() -> void:
	if mundo == null or not mundo.temporada_en_curso():
		_escribir("[color=#e05555]La temporada está terminada. Pulsa «Temporada siguiente».[/color]")
		return
	if _dia_semana >= 6:
		_dia_semana = 0
		_avanzar_semana()
		return
	_dia_semana += 1
	## LA PORTADA DEL DÍA SIGUIENTE (B5): la frase de la rueda, citada.
	if mundo.prensa != null and not mundo.prensa.titular_pendiente.is_empty():
		var tit := mundo.prensa.publicar_titular_pendiente()
		Aviso.mostrar(self, "prensa", "🗞️", "La portada de hoy", tit)
	_refrescar()

## Los siete días con el de hoy encendido. El sábado lleva el balón porque es
## cuando cae la jornada: sin esa marca, la tira sería un adorno.
func _pintar_dias() -> void:
	if _fila_dias == null:
		return
	_limpiar(_fila_dias)
	var hay_partido := mundo != null and (not mundo.proximo_partido().is_empty()
		or not mundo.partido_de_copa().is_empty())
	for i in DIAS_CORTOS.size():
		var es_hoy := i == _dia_semana
		var dia_de_partido := i == 5 and hay_partido
		## C13: el día nacional, de memoria o festivo, con su icono y el nombre
		## al pasar el ratón.
		var fechas_dia := Calendario.del_dia(mundo.mi_club().pais if mundo != null and mundo.mi_club() != null else "CHI",
			mundo.anio if mundo != null else 2026, mundo.semana if mundo != null else 1, i)
		var marca := ""
		for fd: Dictionary in fechas_dia:
			marca += " " + Calendario.icono(String(fd["tipo"]))
		var b := _pildora("%s %d%s%s" % [DIAS_LARGOS[i], int(fecha_del_dia(i).get("day", 1)), marca, "  ⚽" if dia_de_partido else ""], 11, 26)
		if not fechas_dia.is_empty():
			b.tooltip_text = "\n".join(fechas_dia.map(func(fd: Dictionary) -> String: return String(fd["nombre"])))
		b.button_pressed = es_hoy
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if es_hoy and _dia_pintado != _dia_semana:
			_dia_pintado = _dia_semana
			(func() -> void: Animar.pulso(b, 1.1)).call_deferred()
		if dia_de_partido and not es_hoy:
			b.add_theme_color_override("font_color", _color_de_paleta(COL_ORO))
		## Tocar un día futuro avanza hasta ahí; uno pasado no hace nada -el
		## tiempo no vuelve atrás, y un botón que miente es peor que uno que
		## no está-.
		var destino := i
		b.disabled = destino <= _dia_semana
		b.pressed.connect(func() -> void:
			while _dia_semana < destino:
				_avanzar_dia())
		_fila_dias.add_child(b)

## AL CERRAR (etapa 1, 8-10-2026): las referencias estáticas a la partida
## (el contexto del edificio del club, la Carrera de Jugador, el último mundo)
## sobrevivían al cierre y el motor avisaba de objetos sin liberar.
func _exit_tree() -> void:
	EdificioClub.ctx = {}
	EdificioClub.mundo_ref = null
	CarreraJugadorUI.mundo = null
	Trabajadores.actual = null
	Partido.ctx_medico = null
	mundo_a_cargar = null
	mundo_pregenerado = null

func _preparar_mando() -> void:
	for par: Array in MANDO_BOTONES:
		var accion := String(par[0])
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		var ev := InputEventJoypadButton.new()
		ev.button_index = par[1]
		if not InputMap.action_has_event(accion, ev):
			InputMap.action_add_event(accion, ev)
	## El stick izquierdo, además de la cruceta: en un mando moderno la gente
	## usa el stick y se queda mirando por qué no pasa nada.
	for eje: Array in [["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0],
			["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0]]:
		var ev2 := InputEventJoypadMotion.new()
		ev2.axis = eje[1]
		ev2.axis_value = eje[2]
		if not InputMap.action_has_event(String(eje[0]), ev2):
			InputMap.action_add_event(String(eje[0]), ev2)
	for par2: Array in MANDO_PESTANAS:
		var accion2 := String(par2[0])
		if not InputMap.has_action(accion2):
			InputMap.add_action(accion2)
		var eb := InputEventJoypadButton.new()
		eb.button_index = par2[1]
		if not InputMap.action_has_event(accion2, eb):
			InputMap.action_add_event(accion2, eb)
		var et := InputEventKey.new()
		et.keycode = par2[2]
		if not InputMap.action_has_event(accion2, et):
			InputMap.action_add_event(accion2, et)
	for par3: Array in MANDO_BLOQUES:
		var accion3 := String(par3[0])
		if not InputMap.has_action(accion3):
			InputMap.add_action(accion3)
		var ea := InputEventJoypadMotion.new()
		ea.axis = par3[1]
		ea.axis_value = 1.0
		if not InputMap.action_has_event(accion3, ea):
			InputMap.action_add_event(accion3, ea)
