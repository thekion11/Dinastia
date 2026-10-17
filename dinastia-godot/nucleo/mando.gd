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
	"jugar_arriba": ["Mover arriba", [KEY_W, KEY_UP], [], JOY_AXIS_LEFT_Y, -1.0],
	"jugar_abajo": ["Mover abajo", [KEY_S, KEY_DOWN], [], JOY_AXIS_LEFT_Y, 1.0],
	"jugar_izquierda": ["Mover a la izquierda", [KEY_A, KEY_LEFT], [], JOY_AXIS_LEFT_X, -1.0],
	"jugar_derecha": ["Mover a la derecha", [KEY_D, KEY_RIGHT], [], JOY_AXIS_LEFT_X, 1.0],
	"jugar_pase": ["Pase raso · contener", [KEY_SPACE, KEY_J], [JOY_BUTTON_A], -1, 0.0],
	"jugar_tiro": ["Tiro · entrada · despeje", [KEY_K], [JOY_BUTTON_B], -1, 0.0],
	"jugar_centro": ["Centro · pase largo · barrida", [KEY_L], [JOY_BUTTON_X], -1, 0.0],
	"jugar_filtrado": ["Pase al hueco · salida del portero", [KEY_U], [JOY_BUTTON_Y], -1, 0.0],
	"jugar_cambiar": ["Cambiar de jugador · modificador LB (vaselina, bombeado, pared)", [KEY_Q], [JOY_BUTTON_LEFT_SHOULDER], -1, 0.0],
	"jugar_mod": ["Modificador RB (rosca, tenso, potente) · 2.º jugador presiona · regate técnico", [KEY_CTRL], [JOY_BUTTON_RIGHT_SHOULDER], -1, 0.0],
	"jugar_sprint": ["Sprint", [KEY_SHIFT], [], JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"jugar_regate": ["Proteger el balón · bregar (jockey)", [KEY_E], [], JOY_AXIS_TRIGGER_LEFT, 1.0],
	"jugar_pase_largo": ["Pase largo (teclado)", [KEY_I], [], -1, 0.0],
	"jugar_pedir": ["Pedir el balón · desmarque", [KEY_R], [JOY_BUTTON_LEFT_STICK], -1, 0.0],
	"jugar_sombrero": ["Autopase elevado (sombrero)", [KEY_KP_5], [JOY_BUTTON_RIGHT_STICK], -1, 0.0],
	"jugar_fili_arriba": ["Filigrana: stick derecho arriba", [KEY_KP_8], [], JOY_AXIS_RIGHT_Y, -1.0],
	"jugar_fili_abajo": ["Filigrana: stick derecho abajo", [KEY_KP_2], [], JOY_AXIS_RIGHT_Y, 1.0],
	"jugar_fili_izquierda": ["Filigrana: stick derecho izquierda", [KEY_KP_4], [], JOY_AXIS_RIGHT_X, -1.0],
	"jugar_fili_derecha": ["Filigrana: stick derecho derecha", [KEY_KP_6], [], JOY_AXIS_RIGHT_X, 1.0],
	"jugar_tac_arriba": ["Táctica rápida: más ofensiva", [KEY_F1], [JOY_BUTTON_DPAD_UP], -1, 0.0],
	"jugar_tac_abajo": ["Táctica rápida: más defensiva", [KEY_F2], [JOY_BUTTON_DPAD_DOWN], -1, 0.0],
	"jugar_tac_izquierda": ["Táctica rápida: presión de equipo", [KEY_F3], [JOY_BUTTON_DPAD_LEFT], -1, 0.0],
	"jugar_tac_derecha": ["Táctica rápida: laterales al ataque", [KEY_F4], [JOY_BUTTON_DPAD_RIGHT], -1, 0.0],
	"jugar_pausa": ["Pausa / táctica y cambios", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], -1, 0.0],
	"jugar_estadisticas": ["Estadísticas del partido", [KEY_T], [JOY_BUTTON_BACK], -1, 0.0],
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

# ---------------------------------------------------------------- configurable
## LOS CONTROLES SON CONFIGURABLES (14-10-2026, pedido del usuario: «el control
## debe ser configurable»). Cada acción puede llevar otras teclas o botones, se
## elige un esquema de teclado y las ayudas (pase, tiro, cambio de jugador,
## dirección del stick). Se guarda en `user://controles.cfg` y vale para el
## partido del DT y para la Carrera de Jugador.
const RUTA := "user://controles.cfg"

## Esquemas de teclado: acción -> teclas.
const ESQUEMAS := {
	"wasd": {"nombre": "WASD + J/K/L (por defecto)"},
	"clasico": {"nombre": "Clásico de PC: flechas + A/S/D/W",
		"jugar_arriba": [KEY_UP], "jugar_abajo": [KEY_DOWN], "jugar_izquierda": [KEY_LEFT], "jugar_derecha": [KEY_RIGHT],
		"jugar_pase": [KEY_S], "jugar_tiro": [KEY_D], "jugar_centro": [KEY_A], "jugar_pase_largo": [KEY_Z],
		"jugar_filtrado": [KEY_W], "jugar_cambiar": [KEY_Q], "jugar_mod": [KEY_SHIFT], "jugar_sprint": [KEY_E],
		"jugar_regate": [KEY_C], "jugar_pedir": [KEY_X], "jugar_pausa": [KEY_ESCAPE, KEY_P],
		"jugar_estadisticas": [KEY_T]},
}
## Las ayudas, con sus opciones (la primera es la de fábrica).
const AYUDAS := {
	"pase": ["asistido", "manual"],
	"tiro": ["asistido", "manual"],
	"cambio": ["auto", "semi", "manual"],
	"direccion": ["camara", "campo"],
	"vibracion": ["normal", "suave", "no"],
}
static var ayudas := {"pase": "asistido", "tiro": "asistido", "cambio": "auto", "direccion": "camara", "vibracion": "normal"}
static var esquema := "wasd"
## Lo que el jugador cambió a mano: acción -> {"teclas": [..], "botones": [..]}.
static var propio := {}
static var _cargado := false

static func ayuda(k: String) -> String:
	if not _cargado:
		cargar()
	return String(ayudas.get(k, AYUDAS[k][0]))

static func cargar() -> void:
	_cargado = true
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return
	esquema = String(cfg.get_value("controles", "esquema", "wasd"))
	for k: String in AYUDAS:
		var v := String(cfg.get_value("ayudas", k, AYUDAS[k][0]))
		ayudas[k] = v if v in AYUDAS[k] else AYUDAS[k][0]
	propio = cfg.get_value("controles", "propio", {})

static func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controles", "esquema", esquema)
	cfg.set_value("controles", "propio", propio)
	for k: String in ayudas:
		cfg.set_value("ayudas", k, ayudas[k])
	cfg.save(RUTA)

## VIBRACIÓN DEL MANDO (17-10-2026, M-434): gol, choque, tarjeta, remate.
## `fuerza` 0..1 y `dur` en segundos; respeta la ayuda «vibracion».
static func vibrar(fuerza: float, dur: float) -> void:
	var modo := ayuda("vibracion")
	if modo == "no":
		return
	var f := clampf(fuerza * (0.5 if modo == "suave" else 1.0), 0.0, 1.0)
	for id: int in Input.get_connected_joypads():
		Input.start_joy_vibration(id, f * 0.7, f, dur)

## Las teclas que tiene ahora una acción (esquema + lo propio).
static func teclas_de(accion: String) -> Array:
	if not _cargado:
		cargar()
	var pr: Dictionary = propio.get(accion, {})
	if pr.has("teclas"):
		return pr["teclas"]
	var es: Dictionary = ESQUEMAS.get(esquema, {})
	if es.has(accion):
		return es[accion]
	return MAPA[accion][1]

static func botones_de(accion: String) -> Array:
	if not _cargado:
		cargar()
	var pr: Dictionary = propio.get(accion, {})
	if pr.has("botones"):
		return pr["botones"]
	return MAPA[accion][2]

## Reasigna una acción: `ev` es la tecla o el botón que pulsó el jugador.
## Quita esa misma tecla de cualquier otra acción (sin repetidas).
static func reasignar(accion: String, ev: InputEvent) -> void:
	if not _cargado:
		cargar()
	if ev is InputEventKey:
		var k := int((ev as InputEventKey).physical_keycode if (ev as InputEventKey).physical_keycode != 0 else (ev as InputEventKey).keycode)
		for otra: String in MAPA:
			if otra != accion and k in teclas_de(otra):
				var resto: Array = teclas_de(otra).duplicate()
				resto.erase(k)
				var po: Dictionary = propio.get(otra, {})
				po["teclas"] = resto
				propio[otra] = po
		var pa: Dictionary = propio.get(accion, {})
		pa["teclas"] = [k]
		propio[accion] = pa
	elif ev is InputEventJoypadButton:
		var b := int((ev as InputEventJoypadButton).button_index)
		for otra: String in MAPA:
			if otra != accion and b in botones_de(otra):
				var resto2: Array = botones_de(otra).duplicate()
				resto2.erase(b)
				var po2: Dictionary = propio.get(otra, {})
				po2["botones"] = resto2
				propio[otra] = po2
		var pb: Dictionary = propio.get(accion, {})
		pb["botones"] = [b]
		propio[accion] = pb
	guardar()
	aplicar()

static func fijar_esquema(e: String) -> void:
	esquema = e if ESQUEMAS.has(e) else "wasd"
	## Elegir un esquema borra las teclas cambiadas a mano (los botones del
	## mando se quedan).
	for a: String in propio.keys():
		(propio[a] as Dictionary).erase("teclas")
	guardar()
	aplicar()

static func restaurar() -> void:
	esquema = "wasd"
	propio = {}
	ayudas = {"pase": "asistido", "tiro": "asistido", "cambio": "auto", "direccion": "camara"}
	guardar()
	aplicar()

static func fijar_ayuda(k: String, v: String) -> void:
	if not _cargado:
		cargar()
	if v in AYUDAS.get(k, []):
		ayudas[k] = v
		guardar()

## Texto para la pantalla de controles: «Espacio, J · A».
static func texto_de(accion: String) -> String:
	var partes: Array = []
	for k: int in teclas_de(accion):
		partes.append(OS.get_keycode_string(k as Key))
	var bs: Array = []
	for b: int in botones_de(accion):
		bs.append(NOMBRE_BOTON.get(b, "Botón %d" % b))
	if _gatillo(accion) != "":
		bs.append(_gatillo(accion))
	var t := ", ".join(partes) if not partes.is_empty() else "—"
	if not bs.is_empty():
		t += "  ·  🎮 " + ", ".join(bs)
	return t

## Versión corta para la guía en pantalla: la primera tecla y el primer botón.
static func corto_de(accion: String) -> String:
	var ts := teclas_de(accion)
	var bs := botones_de(accion)
	var t := OS.get_keycode_string(ts[0] as Key) if not ts.is_empty() else ""
	if not bs.is_empty():
		t += ("/" if t != "" else "") + String(NOMBRE_BOTON.get(int(bs[0]), "B%d" % int(bs[0])))
	elif _gatillo(accion) != "":
		t += ("/" if t != "" else "") + _gatillo(accion)
	return t if t != "" else "—"

## Los gatillos (RT sprint, LT regate) van por eje, no por botón.
static func _gatillo(accion: String) -> String:
	match int(MAPA[accion][3]):
		JOY_AXIS_TRIGGER_RIGHT: return "RT"
		JOY_AXIS_TRIGGER_LEFT: return "LT"
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: return "Stick izq."
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y: return "Stick der."
	return ""

const NOMBRE_BOTON := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_START: "Start", JOY_BUTTON_BACK: "Select",
	JOY_BUTTON_DPAD_UP: "Cruceta ▲", JOY_BUTTON_DPAD_DOWN: "Cruceta ▼", JOY_BUTTON_DPAD_LEFT: "Cruceta ◀",
	JOY_BUTTON_DPAD_RIGHT: "Cruceta ▶"}

## Vuelve a escribir el InputMap con lo configurado.
static func aplicar() -> void:
	for accion: String in MAPA:
		if InputMap.has_action(accion):
			InputMap.erase_action(accion)
	registrar()

## Mete las acciones en el InputMap si no estaban. Se puede llamar las veces
## que haga falta.
static func registrar() -> void:
	if not _cargado:
		cargar()
	for accion: String in MAPA:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion, ZONA_MUERTA)
		var d: Array = MAPA[accion].duplicate()
		d[1] = teclas_de(accion)
		d[2] = botones_de(accion)
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
