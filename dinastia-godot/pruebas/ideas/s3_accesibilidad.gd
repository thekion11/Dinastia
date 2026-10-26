extends BaseIdea
## s3 (26-10-2026): ACCESIBILIDAD BÁSICA (Game Accessibility Guidelines, nivel básico):
## reasignar teclas y botones de la interfaz, contraste alto y ningún dato solo con color.

var _p: Principal

func _ready() -> void:
	await get_tree().process_frame
	_titulo("S3: ACCESIBILIDAD BÁSICA (teclas, contraste alto, datos sin depender del color)")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 3:
		await get_tree().process_frame
	_contraste()
	await _teclas()
	_sin_color()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _contraste() -> void:
	var antes := _p._paleta
	_p._paleta = "contraste"
	_p._aplicar_aspecto()
	_p._refrescar()
	_comprobar(Tema.contraste, "la paleta «contraste» enciende también `Tema.contraste` (teléfono, avisos, competición)")
	var panel := _p._pal_panel()
	_comprobar(panel.a == 1.0 and panel.get_luminance() < 0.02, "panel negro y opaco (luminosidad %.2f, alfa %.2f)" % [panel.get_luminance(), panel.a])
	_comprobar(_p._pal_suave().get_luminance() > 0.7 and Tema.accesible(Tema.SUAVE).get_luminance() > 0.7,
		"el texto suave pasa a casi blanco (%.2f)" % Tema.accesible(Tema.SUAVE).get_luminance())
	var acento := _p._con_contraste(Color("3fa06a"))
	_comprobar(absf(acento.get_luminance() - panel.get_luminance()) >= 0.6, "un verde oscuro se aclara hasta separarse 0,6 del fondo (%.2f)" % acento.get_luminance())
	_comprobar(Tema.caja().border_color == Tema.BORDE_CONTRASTE, "las tarjetas de `Tema` llevan el borde marcado")
	_p._paleta = antes
	_p._aplicar_aspecto()
	_p._refrescar()
	_comprobar(not Tema.contraste and Tema.accesible(Tema.SUAVE) == Tema.SUAVE, "al quitarlo, todo vuelve a como estaba")

func _teclas() -> void:
	TeclasInterfaz.restaurar()
	var f9 := InputEventKey.new()
	f9.physical_keycode = KEY_F9
	f9.pressed = true
	TeclasInterfaz.reasignar("ui_cancel", f9)
	_comprobar(InputMap.action_has_event("ui_cancel", f9) and not _tiene_tecla("ui_cancel", KEY_ESCAPE),
		"«Volver» pasa a F9 y deja Esc (%s)" % TeclasInterfaz.texto_de("ui_cancel"))
	## La misma tecla no puede hacer dos cosas.
	TeclasInterfaz.reasignar("ui_accept", f9)
	_comprobar(_tiene_tecla("ui_accept", KEY_F9) and not _tiene_tecla("ui_cancel", KEY_F9), "F9 para «Aceptar» se le quita a «Volver»")
	## Un botón del mando con la escucha de Ajustes, como lo haría el jugador.
	var hecho := [false]
	var e := TeclasInterfaz.Escucha.new()
	e.accion = "dinastia_tab_siguiente"
	e.al_terminar = func() -> void: hecho[0] = true
	add_child(e)
	var bx := InputEventJoypadButton.new()
	bx.button_index = JOY_BUTTON_X
	bx.pressed = true
	Input.parse_input_event(bx)
	for i in 3:
		await get_tree().process_frame
	_comprobar(hecho[0] and InputMap.action_has_event("dinastia_tab_siguiente", bx), "la escucha toma el siguiente botón pulsado (X → pestaña siguiente)")
	## Se guarda y se vuelve a aplicar al arrancar.
	TeclasInterfaz._cargado = false
	TeclasInterfaz.cargar()
	_comprobar(TeclasInterfaz._propio.has("ui_accept") and TeclasInterfaz._propio.has("dinastia_tab_siguiente"), "lo reasignado queda guardado")
	TeclasInterfaz.restaurar()
	_comprobar(_tiene_tecla("ui_cancel", KEY_ESCAPE) and not _tiene_tecla("ui_accept", KEY_F9), "«Restaurar» devuelve las de fábrica (Esc vuelve a «Volver»)")

func _tiene_tecla(accion: String, k: int) -> bool:
	for ev: InputEvent in InputMap.action_get_events(accion):
		if ev is InputEventKey and (int((ev as InputEventKey).physical_keycode) == k or int((ev as InputEventKey).keycode) == k):
			return true
	return false

func _sin_color() -> void:
	var simbolos := {}
	for z: String in CompeticionZonas.COLORES:
		simbolos[String(CompeticionZonas.SIMBOLOS.get(z, ""))] = true
	_comprobar(simbolos.size() == CompeticionZonas.COLORES.size() and not simbolos.has(""), "cada zona de la tabla tiene su propio símbolo (%s)" % " ".join(simbolos.keys()))
	_comprobar(CompeticionZonas.puesto_con_simbolo(15, {"zona": CompeticionZonas.DESCENSO}) == "15▼" and CompeticionZonas.puesto_con_simbolo(5, {}) == "5",
		"el puesto lleva el símbolo de su zona («15▼»)")
	## El plantel: el verde de «joven con margen» lleva «↗».
	var c := _p.mundo.mi_club()
	var j: Jugador = c.plantilla[0]
	j.edad = 19
	j.pot = j.ovr + 10
	_p._ui_plantel._pintar_plantel(c)
	var hay := false
	for b in (_p.get("_lista_plantel") as Node).find_children("*", "Button", true, false):
		if String((b as Button).text).begins_with(j.nombre) and String((b as Button).text).contains("↗"):
			hay = true
	_comprobar(hay, "en el plantel, el joven con margen lleva «↗» además del verde")
