class_name GuardianFoco
extends Node
## EL GUARDIÁN DEL FOCO CON MANDO (10-11-2026, auditoría de navegación con mando: `pruebas/auditoria_foco_mando`, orden 26). Con un
## mando conectado, cada `CADA` s mira dónde está el foco de la pantalla principal y lo recupera si:
##  · no hay foco, o está en un control oculto (al reconstruir una pestaña se libera el botón que lo tenía: Mercado, Vida);
##  · está en la principal pero FUERA de la capa que hay encima (un menú, un diálogo a pantalla completa): la cruceta lo había
##    llevado a lo que está tapado.
## Lo devuelve a la capa de arriba o, si no hay, a la pestaña actual (`FocoMando.enfocar`, que si no hay controles enfoca la zona
## de desplazamiento). Si el foco está fuera de la principal (el teclado en pantalla, una ventana del sistema) no lo toca.
## Además, cada vez que cambia el foco, las zonas de desplazamiento que lo contienen se mueven hasta dejarlo A LA VISTA: tenían
## `follow_focus` apagado y la cruceta llevaba el foco a botones fuera de la pantalla, donde además se quedaba atascado (Finanzas:
## del «Lanzar» de arriba al «Firmar» de la fila 40, y de ahí ya no bajaba).
const CADA := 0.2

var _p: Control
var _t := 0.0

func _init(p: Control) -> void:
	_p = p
	name = "GuardianFoco"

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_a_la_vista)

func _a_la_vista(c: Control) -> void:
	if c == null or not FocoMando.hay_mando() or not is_instance_valid(_p) or not _p.is_ancestor_of(c):
		return
	var n := c.get_parent()
	while n != null and n != _p:
		if n is ScrollContainer:
			(n as ScrollContainer).ensure_control_visible(c)
		n = n.get_parent()

## La cruceta (o las flechas) arriba/abajo dentro de una zona de desplazamiento: si Godot no encuentra vecino DENTRO de ella (lo que
## sigue está recortado por el borde: su búsqueda lo ignora) pero la zona aún puede moverse en esa dirección, se va al control más
## cercano en esa dirección dentro de la zona y la vista lo sigue (`_a_la_vista`). Antes, en las listas largas el foco se quedaba
## clavado en la última fila visible.
func _input(ev: InputEvent) -> void:
	var dir := 1 if ev.is_action_pressed("ui_down", true) else (-1 if ev.is_action_pressed("ui_up", true) else 0)
	if dir == 0 or not FocoMando.hay_mando() or not is_instance_valid(_p):
		return
	var f := _p.get_viewport().gui_get_focus_owner()
	if f == null or not _p.is_ancestor_of(f) or f is TextEdit:
		return
	if f.has_meta("cruceta_propia") and bool((f.get_meta("cruceta_propia") as Callable).call(dir)):
		return   ## el control usa la cruceta (el campo del editor de formación con una ficha agarrada o por elegir)
	var sc := _zona(f)
	if sc == null:
		return
	var barra := sc.get_v_scroll_bar()
	var puede := sc.scroll_vertical < int(barra.max_value - barra.page) - 1 if dir > 0 else sc.scroll_vertical > 0
	if not puede:
		return
	var v := f.find_valid_focus_neighbor(SIDE_BOTTOM if dir > 0 else SIDE_TOP)
	if v != null and sc.is_ancestor_of(v):
		return
	var sig := siguiente_en(sc, f, dir)
	if sig != null:
		sig.grab_focus()
		_p.get_viewport().set_input_as_handled()

static func _zona(c: Control) -> ScrollContainer:
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null

## El enfocable de `sc` más cercano a `desde` hacia abajo (`dir` 1) o hacia arriba (-1): primero la fila más cercana y, en ella, el
## más cercano en horizontal. null si no hay.
static func siguiente_en(sc: ScrollContainer, desde: Control, dir: int) -> Control:
	var r0 := desde.get_global_rect()
	var mejor: Control = null
	var md := INF
	for n: Node in sc.find_children("*", "Control", true, false):
		var c := n as Control
		if c == desde or c.focus_mode != Control.FOCUS_ALL or not c.is_visible_in_tree() or (c is BaseButton and (c as BaseButton).disabled):
			continue
		var r := c.get_global_rect()
		var dy := (r.position.y - r0.end.y) if dir > 0 else (r0.position.y - r.end.y)
		if dy < -1.0:
			continue
		var d := maxf(dy, 0.0) * 4.0 + absf(r.get_center().x - r0.get_center().x)
		if d < md:
			md = d
			mejor = c
	return mejor

func _process(delta: float) -> void:
	_t += delta
	if _t < CADA:
		return
	_t = 0.0
	if not FocoMando.hay_mando() or not is_instance_valid(_p) or not _p.is_visible_in_tree():
		return
	var capa := capa_arriba(_p)
	var f := _p.get_viewport().gui_get_focus_owner()
	if f != null and not _p.is_ancestor_of(f):
		return   ## el teclado en pantalla u otra ventana: no es nuestro
	if f != null and f.is_visible_in_tree() and (capa == null or capa.is_ancestor_of(f)):
		return
	var raiz: Control = capa
	if raiz == null:
		var pest: Variant = _p.get("_pestanas")
		raiz = (pest as TabContainer).get_current_tab_control() if pest is TabContainer else null
	if raiz != null:
		FocoMando.enfocar(raiz, 0)

## La capa de encima de la principal: las capas de lienzo (`EventoPantallaCompleta`) se dibujan SIEMPRE encima de los hijos `Control`, así
## que van primero (la última que tape); si no hay, el último hijo `Control` a pantalla completa que para el ratón y no es de la base (como
## `AtajosMenu._capa_modal_encima`). null si no hay.
static func capa_arriba(p: Control) -> Control:
	var base: Variant = p.get("_hijos_base")
	var hijos := p.get_children()
	for i in range(hijos.size() - 1, -1, -1):
		var h: Node = hijos[i]
		if h is CanvasLayer and (h as CanvasLayer).visible:
			for k: Node in h.get_children():
				if k is Control and _tapa(k as Control):
					return k as Control
	for i in range(hijos.size() - 1, -1, -1):
		var h: Node = hijos[i]
		if not (h is Control) or (base is Dictionary and (base as Dictionary).has(h.get_instance_id())):
			continue
		if _tapa(h as Control):
			return h as Control
	return null

static func _tapa(c: Control) -> bool:
	return c.visible and not c.is_queued_for_deletion() and c.mouse_filter == Control.MOUSE_FILTER_STOP \
		and c.anchor_left == 0.0 and c.anchor_top == 0.0 and c.anchor_right == 1.0 and c.anchor_bottom == 1.0
