extends BaseIdea
## PETICIONES ABIERTAS DE LA SESIÓN 2 (26-10-2026, PLAN_DEL_LUNES §9). Comprueba los arreglos:
## capa modal que bloquea los gatillos de detrás, accesibilidad volcada en `Tema`, teclas
## legibles en el mando del partido, rachas en partidos simulados, peñas y el mentor.
##
##   herramientas/ideas.sh s2p_peticiones

func _probar() -> void:
	_titulo("PETICIONES DE LA SESIÓN 2")
	var pr: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(pr)
	_modal(pr)
	_tema(pr)
	_mando()
	_rachas()
	_penas(pr)
	pr.queue_free()

func _pulsar(pr: Principal, accion: String) -> void:
	var e := InputEventAction.new()
	e.action = accion
	e.pressed = true
	pr._input(e)

func _modal(pr: Principal) -> void:
	_comprobar(not pr._capa_modal_encima(), "sin popups no hay capa modal")
	var antes := pr._pestanas.current_tab
	var grupo := pr._grupo_actual
	_pulsar(pr, "dinastia_tab_siguiente")
	var cambia := pr._pestanas.current_tab != antes
	var pop := Telefono.abrir(pr, pr.mundo)
	_comprobar(pr._capa_modal_encima(), "con el móvil abierto hay capa modal")
	var con_movil := pr._pestanas.current_tab
	var grupo_m := pr._grupo_actual
	_pulsar(pr, "dinastia_tab_siguiente")
	_pulsar(pr, "dinastia_tab_anterior")
	_pulsar(pr, "dinastia_bloque_siguiente")
	var k := InputEventKey.new()
	k.keycode = KEY_E
	k.ctrl_pressed = true
	k.pressed = true
	pr._input(k)
	_comprobar(pr._pestanas.current_tab == con_movil and pr._grupo_actual == grupo_m,
		"con el móvil encima, L1/R1, L2/R2 y Ctrl+E no cambian la pestaña de detrás")
	pop.free()
	_pulsar(pr, "dinastia_bloque_siguiente")
	_comprobar(pr._grupo_actual != grupo_m or not cambia, "cerrado el móvil, L2/R2 vuelven a cambiar de bloque (antes %s)" % grupo)

func _tema(pr: Principal) -> void:
	pr._daltonico = true
	pr._escala_texto = 1.3
	_comprobar(Tema.daltonico and is_equal_approx(Tema.escala_texto, 1.3), "daltonismo y escala de Principal llegan a `Tema`")
	pr._daltonico = false
	pr._escala_texto = 1.0
	_comprobar(not Tema.daltonico and is_equal_approx(Tema.escala_texto, 1.0), "y vuelven a su valor al quitarlos")

func _mando() -> void:
	var con_espacio := ""
	for a: String in Mando.MAPA:
		var ts: Array = Mando.teclas_de(a)
		if not ts.is_empty() and int(ts[0]) == KEY_SPACE:
			con_espacio = a
			break
	_comprobar(con_espacio != "", "hay una acción con Espacio en el esquema")
	if con_espacio != "":
		var t := ControlFC.texto_ficha(con_espacio, "teclado")
		_comprobar(t == Idiomas.t("Espacio"), "el mando del partido dice «Espacio», no «Space» («%s»)" % t)

func _rachas() -> void:
	var m := _mundo(4242)
	var antes := int(m.logros.rachas["invicto"]) + int(m.logros.rachas["sin_ganar"])
	for _i in 4:
		m.avanzar_semana()
	var despues := int(m.logros.rachas["invicto"]) + int(m.logros.rachas["sin_ganar"])
	_comprobar(despues > antes, "las rachas cuentan los partidos simulados (%d → %d)" % [antes, despues])

func _penas(pr: Principal) -> void:
	var h: Hinchada = pr.mundo.hinchada
	for ciudad: String in Hinchada.CIUDADES_PENA:
		h.penas.append({"ciudad": ciudad, "socios": 1})
	var r := h.fundar_pena(pr.mundo.mi_club())
	_comprobar(not Hinchada.CIUDADES_PENA.has(r), "«ya tienes peñas en todas partes» no es una ciudad")
