class_name TeclasInterfaz
extends RefCounted
## REASIGNAR LAS TECLAS DE LA INTERFAZ (s3, 26-10-2026; accesibilidad básica de las
## Game Accessibility Guidelines: «los controles se pueden reasignar»). Los del partido
## ya se cambian en Controles (`Mando`); aquí van los de moverse por los menús: aceptar,
## volver y pestaña anterior / siguiente, con una tecla y un botón del mando cada uno.
## Se guardan aparte (`RUTA`, para no pisar `user://controles.cfg`) y se aplican cuando
## la Principal registra su navegación (`_preparar_mando`). Reasignar QUITA las teclas
## (o botones) que la acción tenía y la tecla deja de servir en las otras tres.

const RUTA := "user://teclas_interfaz.cfg"
## [acción del InputMap, nombre]
const ACCIONES := [
	["ui_accept", "Aceptar / pulsar"],
	["ui_cancel", "Volver / cerrar"],
	["dinastia_tab_anterior", "Pestaña anterior"],
	["dinastia_tab_siguiente", "Pestaña siguiente"],
]

## Las de arriba más los atajos del menú central (`AtajosCentrales`): todas se reasignan igual.
static func acciones() -> Array:
	return ACCIONES + AtajosCentrales.lista()

static var _propio := {}       ## acción -> {"tecla": int, "boton": int}
static var _defectos := {}     ## acción -> [InputEvent] de antes de tocar nada
static var _cargado := false

static func cargar() -> void:
	_cargado = true
	_propio.clear()
	var cf := ConfigFile.new()
	if cf.load(RUTA) != OK:
		return
	for par: Array in acciones():
		var a := String(par[0])
		if cf.has_section_key("teclas", a):
			_propio[a] = cf.get_value("teclas", a, {})

static func guardar() -> void:
	var cf := ConfigFile.new()
	for a: String in _propio:
		cf.set_value("teclas", a, _propio[a])
	cf.save(RUTA)

## Aplica lo guardado sobre el InputMap (las acciones ya tienen que existir).
static func aplicar() -> void:
	if not _cargado:
		cargar()
	for par: Array in acciones():
		var a := String(par[0])
		if InputMap.has_action(a) and not _defectos.has(a):
			_defectos[a] = InputMap.action_get_events(a).duplicate()
	for a: String in _propio:
		var d: Dictionary = _propio[a]
		if d.has("tecla"):
			var ev := InputEventKey.new()
			ev.physical_keycode = int(d["tecla"]) as Key
			_poner(a, ev)
		if d.has("boton"):
			var eb := InputEventJoypadButton.new()
			eb.button_index = int(d["boton"]) as JoyButton
			_poner(a, eb)

## `ev` (una tecla o un botón) pasa a ser EL de esa clase para `accion`.
static func reasignar(accion: String, ev: InputEvent) -> void:
	if not _cargado:
		cargar()
	var d: Dictionary = _propio.get(accion, {})
	if ev is InputEventKey:
		var k := ev as InputEventKey
		d["tecla"] = int(k.physical_keycode if k.physical_keycode != 0 else k.keycode)
	elif ev is InputEventJoypadButton:
		d["boton"] = int((ev as InputEventJoypadButton).button_index)
	else:
		return
	_propio[accion] = d
	## La misma tecla no puede hacer dos cosas: se le quita a las otras.
	for otra: String in _propio.keys():
		if otra == accion:
			continue
		var o: Dictionary = _propio[otra]
		for campo: String in ["tecla", "boton"]:
			if d.has(campo) and o.has(campo) and int(o[campo]) == int(d[campo]):
				o.erase(campo)
	guardar()
	aplicar()

## Vuelve a las de fábrica.
static func restaurar() -> void:
	_propio.clear()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))
	for a: String in _defectos:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
			for ev: InputEvent in _defectos[a]:
				InputMap.action_add_event(a, ev)

static func _poner(accion: String, ev: InputEvent) -> void:
	if not InputMap.has_action(accion):
		return
	var es_tecla := ev is InputEventKey
	for viejo: InputEvent in InputMap.action_get_events(accion):
		if (es_tecla and viejo is InputEventKey) or (not es_tecla and viejo is InputEventJoypadButton):
			InputMap.action_erase_event(accion, viejo)
	## Y fuera de las otras acciones de la lista.
	for par: Array in acciones():
		var otra := String(par[0])
		if otra != accion and InputMap.has_action(otra):
			for e2: InputEvent in InputMap.action_get_events(otra):
				if _igual(e2, ev):
					InputMap.action_erase_event(otra, e2)
	InputMap.action_add_event(accion, ev)

static func _igual(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka := a as InputEventKey
		var kb := b as InputEventKey
		var ca := ka.physical_keycode if ka.physical_keycode != 0 else ka.keycode
		var cb := kb.physical_keycode if kb.physical_keycode != 0 else kb.keycode
		return ca == cb
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index
	return false

## «Intro, Espacio · 🎮 A»: lo que hace ahora la acción.
static func texto_de(accion: String) -> String:
	if not InputMap.has_action(accion):
		return "—"
	var ts: Array = []
	var bs: Array = []
	for ev: InputEvent in InputMap.action_get_events(accion):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			var n := Mando.nombre_tecla(int(k.physical_keycode if k.physical_keycode != 0 else k.keycode))
			if n != "" and not ts.has(n):
				ts.append(n)
		elif ev is InputEventJoypadButton:
			var b := int((ev as InputEventJoypadButton).button_index)
			var nb := String(Mando.NOMBRE_BOTON.get(b, "B%d" % b))
			if not bs.has(nb):
				bs.append(nb)
	var t := ", ".join(ts) if not ts.is_empty() else "—"
	if not bs.is_empty():
		t += "  ·  🎮 " + ", ".join(bs)
	return t

## Escucha la siguiente tecla o botón y se lo da a `accion` (Esc cancela).
class Escucha extends Node:
	var accion := ""
	var al_terminar: Callable
	func _input(ev: InputEvent) -> void:
		var vale := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo) \
			or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed)
		if not vale:
			return
		get_viewport().set_input_as_handled()
		if not (ev is InputEventKey and (ev as InputEventKey).keycode == KEY_ESCAPE):
			TeclasInterfaz.reasignar(accion, ev)
		al_terminar.call()
		queue_free()
