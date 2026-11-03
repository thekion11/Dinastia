extends BaseIdea
## R7 (3-11): mientras corre la «Prueba de rendimiento», la pantalla queda bloqueada: una capa por encima de todo se come el ratón y el dedo, el teclado y el
## mando no llegan al menú de detrás, el botón «atrás» de Android no cierra el juego y solo queda «Cancelar la prueba». Al terminar se restaura todo.

func _ready() -> void:
	await get_tree().process_frame
	_titulo("R7 · PRUEBA DE RENDIMIENTO: PANTALLA BLOQUEADA")
	var atras_antes := get_tree().quit_on_go_back
	var m := Medicion.new()
	add_child(m)
	await get_tree().process_frame
	_comprobar(not Medicion.en_curso, "sin pantalla (headless) la prueba no monta bloqueo por su cuenta")
	m._montar_bloqueo(true)
	_comprobar(Medicion.en_curso, "al montarlo, la prueba figura en curso")
	var capa := get_tree().root.find_child("BloqueoMedicion", false, false) as CanvasLayer
	_comprobar(capa != null and capa.layer >= 100, "la capa de bloqueo está por encima de las pantallas (capa %d)" % (capa.layer if capa != null else -1))
	var fondo: ColorRect = capa.get_child(0) as ColorRect if capa != null else null
	_comprobar(fondo != null and fondo.mouse_filter == Control.MOUSE_FILTER_STOP and fondo.anchor_right == 1.0 and fondo.anchor_bottom == 1.0,
		"cubre toda la pantalla y se come el ratón y el dedo")
	var botones := capa.find_children("*", "Button", true, false) if capa != null else []
	_comprobar(botones.size() == 1 and (botones[0] as Button).text == "Cancelar la prueba", "solo queda un botón: «Cancelar la prueba» (%d)" % botones.size())
	_comprobar(not get_tree().quit_on_go_back, "el botón «atrás» de Android no cierra el juego mientras corre")
	m._empezar_parte("estadio (cámara TV)")
	var rotulo := capa.find_children("*", "Label", true, false)[0] as Label if capa != null else null
	_comprobar(rotulo != null and rotulo.text.contains("estadio") and rotulo.text.contains("no toques nada"), "el cartel dice en qué parte va y que no se toque nada")
	## El teclado no llega al menú de detrás.
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_ESCAPE
	tecla.pressed = true
	get_viewport().set_input_as_handled()   ## (limpia)
	m._input(tecla)
	_comprobar(get_viewport().is_input_handled(), "una tecla se la traga la prueba (no llega al menú)")
	m._quitar_bloqueo()
	await get_tree().process_frame
	_comprobar(not Medicion.en_curso and get_tree().quit_on_go_back == atras_antes, "al acabar se restaura «atrás» y la prueba deja de figurar en curso")
	_comprobar(get_tree().root.find_child("BloqueoMedicion", false, false) == null, "y la capa de bloqueo desaparece")
	m.queue_free()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
