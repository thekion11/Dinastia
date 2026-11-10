extends "res://pruebas/auditoria_foco_mando.gd"
## AUDITORÍA DE LA NAVEGACIÓN CON MANDO, 2.ª parte (10-11-2026): las pantallas a pantalla completa de EVENTOS y de la TEMPORADA y el
## EDITOR DE FORMACIÓN. Mismos criterios que `auditoria_foco_mando` (foco visible al entrar y no en un campo de texto, 30 pulsaciones
## de cruceta sin perderlo ni salir de la capa, alcance con la cruceta, estilo de foco visible):
##  · selección: la oferta del cargo, el aviso de fecha FIFA, el partido de un torneo y la convocatoria;
##  · festejo de un título, aviso y ceremonia del partido de despedida, calendario, palmarés del mundo;
##  · la ficha de competición con la FASE FINAL de una liga que la tenga (Argentina, MLS, Egipto);
##  · el final de temporada (`ResumenTemporada`);
##  · el editor de formación (Táctica → «Editar posiciones»): al abrirlo el foco va al campo; Aceptar agarra la ficha, la cruceta la
##    mueve y Aceptar la suelta; sin ficha agarrada la cruceta elige ficha y, al borde, SALE del campo (no es una trampa).
## Los clubes varían (orden 34): el del jugador, uno de otro país para las Leyendas, la liga con fase final.
##   godot --headless --path . res://pruebas/auditoria_foco_eventos.tscn

func _ready() -> void:
	FocoMando.forzar = true
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 90:
		await get_tree().process_frame
	await _cerrar_eventos()
	var m: Mundo = _p.mundo
	var mio: Club = m.mi_club()
	print("club del jugador: %s (%s)" % [mio.nombre, mio.pais])
	if OS.get_environment("SOLO_FIN") != "1":
		await _resto(m, mio)
	CierreTorneos.cerrar_pendientes(m)
	var foto := CierreTorneos.foto(m)
	var resumen := m.nueva_temporada()
	for i in 10:   ## con pantalla, la temporada nueva abre en diferido sus propios eventos (con «Continuar»), que irían ENCIMA
		await get_tree().process_frame
	await _cerrar_eventos()
	await _capa("fin de temporada", ResumenTemporada.mostrar(_p, foto, resumen))
	print("RESUMEN")
	for r: String in _resumen:
		print("  " + r)
	print("===== FIN. %d fallos =====" % _fallos)
	FocoMando.forzar = false
	get_tree().quit(0 if _fallos == 0 else 1)

func _resto(m: Mundo, mio: Club) -> void:
	await _seleccion(m)
	var otro: Club = null
	for l: Liga in m.ligas:
		if l.clubes.size() > 0 and (l.clubes[0] as Club).pais != mio.pais:
			otro = l.clubes[3 % l.clubes.size()]
			break
	await _capa("festejo", EventoCelebracion.mostrar(_p, "Título de prueba", "liga", JornadaCelebracion.rival_del_pasillo(m)))
	await _capa("despedida (aviso)", EventoDespedida.mostrar(_p, otro))
	await _capa("despedida (ceremonia)", CeremoniaDespedida.mostrar(_p, [], otro))
	await _capa("calendario", CalendarioSemanas.mostrar(_p, m, 0))
	await _capa("palmarés del mundo", PalmaresMundoUI.abrir(_p))
	await _fase_final(m)
	await _editor(mio)

## Una capa a pantalla completa (`EventoPantallaCompleta`): se audita su raíz como modal y se cierra.
func _capa(nombre: String, ev: EventoPantallaCompleta) -> void:
	if ev == null or not is_instance_valid(ev):
		_comprobar(false, "[%s] se abre" % nombre)
		return
	await _auditar(nombre, ev._raiz, true)
	ev.queue_free()
	for i in 3:
		await get_tree().process_frame
	await _cerrar_eventos()

func _seleccion(m: Mundo) -> void:
	var nombres := ["Marruecos", "Japón", "Uruguay"]
	var sel_n := ""
	for n: String in nombres:
		if m.selecciones.fuerza(n) > 0:
			sel_n = n
			break
	if sel_n == "":
		sel_n = nombres[0]
	var c := SeleccionEquipo.club_de(m, sel_n, m.selecciones.fuerza(sel_n), m.anio)
	await _capa("selección: oferta", EventoSeleccion.oferta(_p, c, m.selecciones.fuerza(sel_n), 2400))
	m.selecciones.cargo.ofrecer(sel_n, m.selecciones.fuerza(sel_n), 2400)
	m.selecciones.cargo.responder(m, true)
	var t := SeleccionesTorneos.mundial(m.selecciones, m, 2026)
	var mia := SeleccionesTorneos.equipo_en(t, sel_n)
	if mia != null:
		t.jugar_fecha()
		var par := t.partido_de(mia)
		var rival: Club = par[1] if par[0] == mia else par[0]
		await _capa("selección: partido", EventoSeleccion.partido(_p, t, mia, rival))
		await _capa("selección: fecha FIFA", EventoSeleccion.fecha(_p, "amistoso", mia, rival, mia))
	else:
		print("  (%s no está en el Mundial: sin partido ni fecha)" % sel_n)
	JornadaSeleccion.abrir_convocatoria(_p)
	var conv: EventoPantallaCompleta = null
	for h: Node in _p.get_children():
		if h is EventoSeleccion:
			conv = h
	await _capa("selección: convocatoria", conv)

## La ficha de competición con una liga que tiene fase final (playoffs o grupos de campeonato).
func _fase_final(m: Mundo) -> void:
	_p.call("_abrir_competicion")
	await get_tree().process_frame
	var comp: Control = null
	for h: Node in _p.get_children():
		if h is Competicion:
			comp = h
	if comp == null:
		_comprobar(false, "[competición] se abre")
		return
	var entradas: Array = comp.get("_entradas")
	for i in entradas.size():
		if entradas[i] is Liga and (entradas[i] as Liga).formato != null:
			(comp.get("_selector") as OptionButton).select(i)
			comp.call("_elegir", i)
			print("  liga con fase final: %s" % (entradas[i] as Liga).nombre)
			break
	await _auditar("competición (fase final)", comp, true)
	comp.queue_free()
	await get_tree().process_frame

func _editor(mio: Club) -> void:
	_p.call("_ir_a_pestana", "Táctica")
	for i in 10:
		await get_tree().process_frame
	var be: Button = null
	for b: Node in _p.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and String((b as Button).text).contains(Idiomas.t("Editar posiciones")):
			be = b
	if be == null:
		_comprobar(false, "[editor de formación] está el botón «Editar posiciones» en Táctica")
		return
	be.grab_focus()
	be.pressed.emit()
	for i in 6:
		await get_tree().process_frame
	var ed: EditorFormacion = null
	for n: Node in _p.find_children("*", "EditorFormacion", true, false):
		ed = n
	if ed == null:
		_comprobar(false, "[editor de formación] se abre")
		return
	var lienzo: Control = ed.get("_lienzo")
	await get_tree().create_timer(GuardianFoco.CADA * 1.5).timeout
	_comprobar(_foco() == lienzo, "[editor de formación] al abrirlo el foco va al campo (%s)" % _desc(_foco()))
	lienzo.grab_focus()
	await get_tree().process_frame
	_comprobar(lienzo.has_meta("foco_visible"), "[editor de formación] el campo enfocado dibuja su marco de foco")
	## sin agarrar: la cruceta cambia de ficha, la ficha no se mueve
	var s0: int = ed.sel
	var antes: Array = (ed.forma["s"] as Array).duplicate(true)
	await _pulsar(JOY_BUTTON_DPAD_UP)
	_comprobar(_foco() == lienzo and ed.sel != s0 and ed.forma["s"] == antes, "[editor de formación] sin agarrar, la cruceta elige otra ficha (%d → %d) sin moverla" % [s0, ed.sel])
	## agarrar, mover y soltar
	var s1: int = ed.sel
	var x0 := float(ed.forma["s"][s1][1])
	await _pulsar(JOY_BUTTON_A)
	await _pulsar(JOY_BUTTON_DPAD_LEFT)
	await _pulsar(JOY_BUTTON_DPAD_LEFT)
	var x1 := float(ed.forma["s"][s1][1])
	_comprobar(ed.sel == s1 and x1 < x0 and _foco() == lienzo, "[editor de formación] Aceptar agarra la ficha y la cruceta la mueve (x %.0f → %.0f)" % [x0, x1])
	if OS.get_environment("FOTOS") == "1":   ## la ficha agarrada, con el marco del foco
		var sc := GuardianFoco._zona(ed)
		if sc != null:
			sc.ensure_control_visible(ed)
		await get_tree().create_timer(0.5).timeout
		var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
		get_viewport().get_texture().get_image().save_jpg(dir.path_join("foco_editor_formacion.jpg"), 0.88)
	await _pulsar(JOY_BUTTON_A)
	await _pulsar(JOY_BUTTON_DPAD_RIGHT)
	_comprobar(not ed.agarrada and absf(float(ed.forma["s"][s1][1]) - x1) < 0.01, "[editor de formación] Aceptar la suelta (la cruceta ya no la mueve)")
	## no es una trampa: bajando se sale del campo a los botones de abajo
	var salio := false
	for i in 14:
		await _pulsar(JOY_BUTTON_DPAD_DOWN)
		if _foco() != lienzo:
			salio = true
			break
	_comprobar(salio and _foco() != null and ed.is_ancestor_of(_foco()), "[editor de formación] bajando, el foco sale del campo a los botones del editor (%s)" % _desc(_foco()))
	var visto := {}
	for i in 8:
		await _pulsar(JOY_BUTTON_DPAD_UP)
		visto[_foco()] = true
	_comprobar(visto.has(lienzo), "[editor de formación] y subiendo vuelve al campo")
	lienzo.grab_focus()   ## la auditoría general empieza donde empieza el editor
	await _auditar("editor de formación", ed, false)
	ed.call("_cancelar")
	for i in 6:
		await get_tree().process_frame
