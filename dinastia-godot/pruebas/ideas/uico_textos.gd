extends BaseIdea
## PERIÓDICO, REPUTACIÓN, TABLA DEL HUB Y TEXTOS (uico, 25-10-2026).
##   herramientas/ideas.sh uico_textos

func _ready() -> void:
	await get_tree().process_frame
	await _probar_con_espera()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _textos(n: Node) -> Array[String]:
	var r: Array[String] = []
	for c in n.find_children("*", "Label", true, false):
		r.append((c as Label).text)
	return r

func _probar_con_espera() -> void:
	var m := _mundo(777)
	for i in 4:
		m.avanzar_semana()

	_titulo("uico · PORTADA")
	_comprobar(PortadaPeriodico.nombre_propio("¡GOLAZO!") == "¡Golazo!", "«¡GOLAZO!» → «¡Golazo!» (antes «¡golazo!»)")
	_comprobar(PortadaPeriodico.nombre_propio("DIARIO LA BANDA") == "Diario La Banda", "«DIARIO LA BANDA» → «Diario La Banda»")
	var raiz := Control.new()
	raiz.size = Vector2(1280, 720)
	add_child(raiz)
	var d := {"t": "\"Golpe de autoridad\"", "c": "Lautaro FC 4-0 Chillán Rojo", "semana": 7, "anio": 2026, "medio": "El Pelotazo"}
	var por := PortadaPeriodico.mostrar(raiz, m, d)
	for i in 3:
		await get_tree().process_frame
	## Las cifras de la tabla del pie, bajo sus siglas: el borde derecho de
	## «PTS» y el de cada número de puntos coinciden.
	var hoja: Control = por.get("_hoja")
	var derechos := {}
	for l in hoja.find_children("*", "Label", true, false):
		var lb := l as Label
		if lb.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and lb.text.is_valid_int() or lb.text == "PTS":
			derechos[int(round(lb.get_global_rect().end.x))] = true
	_comprobar(derechos.size() == 2, "dos columnas exactas en la tabla del pie (bordes: %s)" % str(derechos.keys()))
	## Los botones, centrados bajo la hoja.
	var fila: HBoxContainer = null
	for h in por.get_children():
		if h is HBoxContainer:
			fila = h
	_linea("fila %s · hoja %s · portada %s" % [fila.get_global_rect(), hoja.get_global_rect(), por.get_global_rect()])
	var centro_fila := fila.get_global_rect().get_center().x
	var centro_hoja := hoja.get_global_rect().get_center().x
	_comprobar(absf(centro_fila - centro_hoja) < 4.0, "botones centrados bajo la hoja (desfase %.1f px)" % absf(centro_fila - centro_hoja))
	_comprobar(fila.get_global_rect().end.y <= 720.0, "los botones caben en 720 px de alto")
	## B del mando / Esc cierran sin necesidad de tener el ratón encima.
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	por._input(ev)
	_comprobar(por.is_queued_for_deletion(), "«cancelar» (Esc o B) cierra la portada")
	await get_tree().process_frame

	_titulo("uico · REPUTACIÓN EN INGLÉS")
	Idiomas.idioma = "en"
	var lista := VBoxContainer.new()
	add_child(lista)
	m.roles.anotar_reputacion("social", -30, "El amistoso benéfico")
	PanelReputacion.pintar(lista, m)
	var t := " | ".join(_textos(lista))
	_comprobar(not t.contains("nivel del club"), "nivel del club traducido")
	_comprobar(not t.contains("Juega en contra"), "faceta en contra traducida")
	_comprobar(not t.contains("Siguiente:"), "«Siguiente» traducido")
	_comprobar(not t.to_lower().contains("instalaciones"), "beneficios del nivel traducidos")
	_comprobar(t.contains("Works against you"), "la faceta baja dice «Works against you»")
	lista.queue_free()

	_titulo("uico · SIGLAS DE LA TABLA")
	var sig: Array[String] = []
	for s: String in ["PJ", "G", "E", "P"]:
		sig.append(CompeticionFilas.sigla(s))
	_comprobar(str(sig) == str(["P", "W", "D", "L"]), "en inglés: P W D L (antes «P G E P»): %s" % str(sig))
	_comprobar(Idiomas.t("E") == "E", "la «E» suelta (tecla del explorador) no se traduce")
	Idiomas.idioma = "tr"
	var sig_tr: Array[String] = []
	for s2: String in ["PJ", "G", "E", "P", "PTS"]:
		sig_tr.append(CompeticionFilas.sigla(s2))
	var distintas := {}
	for x in sig_tr:
		distintas[x] = true
	_comprobar(distintas.size() == sig_tr.size(), "en turco las cinco siglas son distintas: %s" % str(sig_tr))
	Idiomas.idioma = "es"
	_comprobar(CompeticionFilas.sigla("G") == "G", "en castellano las siglas no cambian")

	_titulo("uico · TABLA DEL HUB")
	var col := VBoxContainer.new()
	add_child(col)
	var liga := m.liga_de(m.mi_club())
	TablaCompeticion.pintar(col, m, liga, m.mi_club(), {"suave": Tema.SUAVE, "texto": Tema.TEXTO,
		"acento": Tema.ACENTO, "verde": Tema.BIEN, "rojo": Tema.MAL, "oro": Tema.ORO, "escala": 1.0})
	var con_zona := 0
	for l2 in col.find_children("*", "Label", true, false):
		if (l2 as Label).tooltip_text == Idiomas.t("Descenso"):
			con_zona += 1
	_comprobar(con_zona == liga.plazas_descenso, "el hub marca los %d puestos de descenso" % liga.plazas_descenso)
	col.queue_free()
