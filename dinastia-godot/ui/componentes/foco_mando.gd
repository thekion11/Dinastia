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
		if n is Control and (n as Control).focus_mode == Control.FOCUS_ALL and not (n is BaseButton and (n as BaseButton).disabled) \
				and not (n is LineEdit or n is TextEdit):   ## (10-11) un campo de texto abriría el teclado en pantalla sin pedirlo
			return n as Control
		var dentro := primero(n)
		if dentro != null:
			return dentro
	return null

## Si hay mando y el foco no está ya dentro de `raiz`, lo pone en su primer control. (10-11, auditoría de navegación con mando,
## `pruebas/auditoria_foco_mando`) Si el contenido aún se está montando (pestañas que entran escalonadas: Mercado, Vida) lo
## reintenta unos fotogramas; si no tiene NINGÚN control (Palmarés, Glosario, Enfermería…), el foco va a su zona de desplazamiento,
## que la cruceta arriba/abajo hace correr: antes el foco quedaba en nada y la cruceta no hacía nada.
static func enfocar(raiz: Control, intentos := 8) -> void:
	if raiz == null or not raiz.is_inside_tree() or not hay_mando():
		return
	var actual := raiz.get_viewport().gui_get_focus_owner()
	if actual != null and raiz.is_ancestor_of(actual) and actual.is_visible_in_tree():
		return
	var c := primero(raiz)
	if c != null:
		c.grab_focus()
	elif intentos > 0:
		raiz.get_tree().process_frame.connect(enfocar.bind(raiz, intentos - 1), CONNECT_ONE_SHOT)
	else:
		var sc := desplazable(raiz)
		if sc != null:
			sc.grab_focus()

## La primera zona de desplazamiento visible de `raiz`, preparada para el mando (enfocable y movida con la cruceta); null si no hay.
static func desplazable(raiz: Node) -> ScrollContainer:
	var lista := raiz.find_children("*", "ScrollContainer", true, false)
	if raiz is ScrollContainer:
		lista.push_front(raiz)
	for n: Node in lista:
		var sc := n as ScrollContainer
		if sc.is_visible_in_tree():
			sc.focus_mode = Control.FOCUS_ALL
			if not sc.gui_input.is_connected(_desplazar.bind(sc)):
				sc.gui_input.connect(_desplazar.bind(sc))
			return sc
	return null

const PASO_CRUCETA := 90

## La cruceta mueve la zona de desplazamiento; en el borde deja pasar el evento (el foco sale a la fila de pestañas o al riel).
static func _desplazar(ev: InputEvent, sc: ScrollContainer) -> void:
	var dir := 1 if ev.is_action_pressed("ui_down", true) else (-1 if ev.is_action_pressed("ui_up", true) else 0)
	if dir == 0:
		return
	var tope := int(sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page)
	if (dir > 0 and sc.scroll_vertical >= tope) or (dir < 0 and sc.scroll_vertical <= 0):
		return
	sc.scroll_vertical = clampi(sc.scroll_vertical + dir * PASO_CRUCETA, 0, maxi(tope, 0))
	sc.accept_event()

## Una capa a pantalla completa (un menú) se queda con el foco: sus hermanos (lo de detrás) dejan de ser enfocables mientras está
## abierta, para que la cruceta no lleve el foco a botones tapados. `liberar` lo deja como estaba.
static func aislar(capa: Control) -> void:
	var padre := capa.get_parent()
	if padre == null or capa.has_meta("foco_aislado"):
		return
	var previos: Array = []
	for h: Node in padre.get_children():
		if h != capa and h is Control:
			previos.append([h, (h as Control).focus_behavior_recursive])
			(h as Control).focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	capa.set_meta("foco_aislado", previos)

static func liberar(capa: Control) -> void:
	if not capa.has_meta("foco_aislado"):
		return
	for par: Array in capa.get_meta("foco_aislado"):
		if is_instance_valid(par[0]):
			(par[0] as Control).focus_behavior_recursive = par[1]
	capa.remove_meta("foco_aislado")

## `aislar` mientras la capa exista (se libera sola al salir del árbol): para capas que no son `PantallaMenu` (la rueda de prensa).
static func aislar_mientras(capa: Control) -> void:
	aislar(capa)
	if not capa.tree_exiting.is_connected(liberar.bind(capa)):
		capa.tree_exiting.connect(liberar.bind(capa))
