class_name Mando
extends RefCounted
## LOS CONTROLES PARA JUGAR CON MANDO (base, 26-9-2026). Todavía no hay partido
## jugable; esto deja listo el mapa de botones para cuando lo haya. Se registra
## en el InputMap en tiempo de ejecución (no toca project.godot), con mando y
## teclado a la vez, y los nombres de acción son los mismos `boton` del
## catálogo de `AccionesJuego`.
##
## El mismo botón hace cosas distintas con balón y sin él, como en cualquier
## juego de fútbol: A pasa o presiona, B tira o entra, X centra o barre.

## acción: [descripción, [teclas], [botones del mando], eje (-1 si ninguno), signo del eje]
const MAPA := {
	"jugar_arriba": ["Mover arriba", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0],
	"jugar_abajo": ["Mover abajo", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0],
	"jugar_izquierda": ["Mover a la izquierda", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0],
	"jugar_derecha": ["Mover a la derecha", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0],
	"jugar_pase": ["Pase / presionar", [KEY_SPACE, KEY_J], [JOY_BUTTON_A], -1, 0.0],
	"jugar_tiro": ["Tiro / entrada / despeje", [KEY_K], [JOY_BUTTON_B], -1, 0.0],
	"jugar_centro": ["Centro / barrida", [KEY_L], [JOY_BUTTON_X], -1, 0.0],
	"jugar_pase_largo": ["Pase largo / salida del portero", [KEY_I], [JOY_BUTTON_Y], -1, 0.0],
	"jugar_filtrado": ["Pase al hueco", [KEY_U], [JOY_BUTTON_RIGHT_SHOULDER], -1, 0.0],
	"jugar_cambiar": ["Cambiar de jugador", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], -1, 0.0],
	"jugar_sprint": ["Sprint", [KEY_SHIFT], [], JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"jugar_regate": ["Regate / proteger", [KEY_E], [JOY_BUTTON_RIGHT_STICK], JOY_AXIS_TRIGGER_LEFT, 1.0],
	"jugar_pedir": ["Pedir el balón / desmarque", [KEY_R], [JOY_BUTTON_LEFT_STICK], -1, 0.0],
	"jugar_pausa": ["Pausa / táctica rápida", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], -1, 0.0],
}

## Qué acción del catálogo sale de cada botón, con balón y sin balón.
const CON_BALON := {
	"jugar_pase": "pase_corto", "jugar_tiro": "tiro", "jugar_centro": "centro",
	"jugar_pase_largo": "pase_largo", "jugar_filtrado": "pase_filtrado", "jugar_regate": "regate",
}
const SIN_BALON := {
	"jugar_pase": "presionar", "jugar_tiro": "entrada", "jugar_centro": "entrada_barrida",
	"jugar_pase_largo": "salida", "jugar_pedir": "desmarque", "jugar_sprint": "sprint",
}

const ZONA_MUERTA := 0.2

## Mete las acciones en el InputMap si no estaban. Se puede llamar las veces
## que haga falta.
static func registrar() -> void:
	for accion: String in MAPA:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion, ZONA_MUERTA)
		var d: Array = MAPA[accion]
		for tecla: int in d[1]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla as Key
			InputMap.action_add_event(accion, ev)
		for b: int in d[2]:
			var eb := InputEventJoypadButton.new()
			eb.button_index = b as JoyButton
			InputMap.action_add_event(accion, eb)
		if int(d[3]) >= 0:
			var em := InputEventJoypadMotion.new()
			em.axis = int(d[3]) as JoyAxis
			em.axis_value = float(d[4])
			InputMap.action_add_event(accion, em)

## La dirección del stick (o de las flechas), en el plano del campo.
static func movimiento() -> Vector2:
	return Input.get_vector("jugar_izquierda", "jugar_derecha", "jugar_arriba", "jugar_abajo", ZONA_MUERTA)

## Traduce un botón a una acción del catálogo según haya balón o no. "" si el
## botón no significa nada en esa situación.
static func accion_de(boton: String, con_balon: bool) -> String:
	return String((CON_BALON if con_balon else SIN_BALON).get(boton, ""))

## La acción de un evento de entrada ("" si no es de juego). Para `_input`.
static func accion_del_evento(ev: InputEvent, con_balon: bool) -> String:
	for boton: String in MAPA:
		if InputMap.has_action(boton) and ev.is_action_pressed(boton):
			if boton == "jugar_cambiar" or boton == "jugar_pausa":
				return boton
			return accion_de(boton, con_balon)
	return ""

## Hay un mando enchufado.
static func hay_mando() -> bool:
	return not Input.get_connected_joypads().is_empty()
