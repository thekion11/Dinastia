class_name FocoMando
extends RefCounted
## EL FOCO CON MANDO EN LAS PANTALLAS DE GESTIÓN (2-11-2026, M-285): al abrir una pestaña con un mando conectado,
## el foco cae en el primer control usable del contenido (de arriba abajo), para que la cruceta empiece ahí y no
## en un botón de otra pantalla. Con ratón o teclado no se toca nada.

static var forzar := false   ## las pruebas lo encienden sin mando

static func hay_mando() -> bool:
	return forzar or not Input.get_connected_joypads().is_empty()

## El primer control visible y enfocable (no desactivado) dentro de `raiz`, en orden de árbol.
static func primero(raiz: Node) -> Control:
	if raiz == null:
		return null
	for n: Node in raiz.get_children():
		if n is Control and not (n as Control).is_visible_in_tree():
			continue
		if n is Control and (n as Control).focus_mode == Control.FOCUS_ALL and not (n is BaseButton and (n as BaseButton).disabled):
			return n as Control
		var dentro := primero(n)
		if dentro != null:
			return dentro
	return null

## Si hay mando y el foco no está ya dentro de `raiz`, lo pone en su primer control.
static func enfocar(raiz: Control) -> void:
	if raiz == null or not raiz.is_inside_tree() or not hay_mando():
		return
	var actual := raiz.get_viewport().gui_get_focus_owner()
	if actual != null and raiz.is_ancestor_of(actual):
		return
	var c := primero(raiz)
	if c != null:
		c.grab_focus()
