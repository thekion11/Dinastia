class_name AtajosCentrales
extends RefCounted
## ATAJOS DEL MENÚ CENTRAL (s3, 26-10-2026; plan §11 filas 1-2: «presupuesto de clics»
## y «atajos de teclado en todo el menú central, editables»). Las diez tareas que más
## se repiten en un manager, a una tecla: 1-9 y 0 saltan a su pestaña, N pasa un día,
## F3 lleva al buscador y F5 guarda. Son acciones del InputMap (`registrar`), así que
## se reasignan en Ajustes → Accesibilidad con las demás teclas de la interfaz
## (`TeclasInterfaz`). No hacen nada mientras se escribe en un campo de texto.

## [acción, nombre, tecla por defecto, destino]. Destino: un chip ({tab, secc}) o una orden.
const ATAJOS := [
	["dinastia_ir_inicio", "Ir a Inicio", KEY_1, {"tab": "Inicio", "label": "Inicio"}],
	["dinastia_ir_plantel", "Ir a Mi plantel", KEY_2, {"tab": "Mi plantel", "label": "Mi plantel"}],
	["dinastia_ir_tactica", "Ir a Táctica (el once)", KEY_3, {"tab": "Táctica", "label": "Táctica"}],
	["dinastia_ir_entrenar", "Ir a Entrenar", KEY_4, {"tab": "Entrenar", "label": "Entrenar"}],
	["dinastia_ir_mercado", "Ir al Mercado (fichar)", KEY_5, {"tab": "Mercado", "label": "Mercado"}],
	["dinastia_ir_finanzas", "Ir a Finanzas", KEY_6, {"tab": "Finanzas", "label": "Finanzas"}],
	["dinastia_ir_calendario", "Ir al Calendario", KEY_7, {"tab": "Calendario", "label": "Calendario"}],
	["dinastia_ir_correo", "Ir al Correo", KEY_8, {"tab": "Correo", "label": "Correo"}],
	["dinastia_ir_contratos", "Ir a Contratos (renovar)", KEY_9, {"tab": "Contratos", "label": "Contratos"}],
	["dinastia_ir_prensa", "Ir a la Sala de prensa", KEY_0, {"tab": "Redes", "secc": "prensa", "label": "Sala de Prensa"}],
	["dinastia_un_dia", "Pasar un día", KEY_N, "dia"],
	["dinastia_buscar", "Buscar un jugador o un club", KEY_F3, "buscar"],
	["dinastia_guardar", "Guardar la partida", KEY_F5, "guardar"],
]

## Mete las acciones en el InputMap (si no estaban) con su tecla por defecto.
static func registrar() -> void:
	for a: Array in ATAJOS:
		var accion := String(a[0])
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		var ev := InputEventKey.new()
		ev.physical_keycode = a[2] as Key
		InputMap.action_add_event(accion, ev)

## [acción, nombre] de todos, para la lista de teclas reasignables.
static func lista() -> Array:
	var out: Array = []
	for a: Array in ATAJOS:
		out.append([a[0], a[1]])
	return out

## Si `ev` es un atajo, lo ejecuta en la pantalla principal `p` y devuelve true.
static func manejar(p: Principal, ev: InputEvent) -> bool:
	if not (ev is InputEventKey) or not (ev as InputEventKey).pressed or (ev as InputEventKey).echo:
		return false
	var k := ev as InputEventKey
	if k.ctrl_pressed or k.alt_pressed or k.meta_pressed:
		return false
	## Escribiendo en un campo (buscador, móvil, nombres), las teclas son letras.
	var foco := p.get_viewport().gui_get_focus_owner()
	if foco is LineEdit or foco is TextEdit:
		return false
	for a: Array in ATAJOS:
		if not InputMap.has_action(String(a[0])) or not ev.is_action_pressed(String(a[0])):
			continue
		var destino: Variant = a[3]
		if destino is Dictionary:
			p._ir_a_chip(destino)
			p._refrescar()
		elif destino == "dia":
			p._avanzar_dia()
		elif destino == "buscar":
			var b: LineEdit = p.get("_buscador")
			if b != null:
				b.grab_focus()
		elif destino == "guardar":
			p._guardar()
		return true
	return false
