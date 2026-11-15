class_name MenuGuardado
extends RefCounted
## MENÚS LATERALES YA ARMADOS (15-11-2026, meta del dueño: «que no se demoren»). Dos ideas que comparten esta caché:
##   · AL CERRAR un menú no se borra: se guarda fuera de la pantalla, ya en su portada; al volver a abrirlo se enseña tal cual.
##   · EN REPOSO (3 s sin tocar nada, lo detecta `AhorroMenu`) se arma a escondidas el menú que más se abre (al principio, Plantel).
## Un menú guardado solo se reutiliza si sigue al día: el mismo mundo, la misma fecha, idioma, tamaño de ventana y forma de cabecera,
## y los mismos datos vivos de sus tarjetas («3 sin leer»). Si algo cambió, se libera y se arma de nuevo como siempre.
## Mientras está guardado sigue marcado como «cerrándose» (`cerrando()`): nadie lo confunde con un menú abierto.
const MAX := 3
static var _guardados: Dictionary = {}   ## id -> PantallaMenu (fuera del árbol)
static var _usos: Dictionary = {}        ## id -> veces abierto, para saber cuál precargar
static var activo := OS.get_environment("SIN_MENU_GUARDADO") == ""

## La huella de lo que muestra la portada de un menú: si cambia, lo guardado ya no vale.
static func huella(p: Principal, menu: Dictionary) -> String:
	var datos: Array = []
	for sub: Dictionary in menu["subs"]:
		datos.append(MenuLateral.dato(p, sub))
	var vp := p.get_viewport_rect().size if p.is_inside_tree() else Vector2.ZERO
	return "%d|%s|%s|%s|%s|%s|%s" % [p.mundo.get_instance_id() if p.mundo != null else 0, p.fecha_larga() if p.mundo != null else "",
		Idiomas.idioma, vp, PantallaMenu.compacta(), MenuLateral.abajo(), "·".join(datos)]

## El menú guardado de `menu` si sigue al día (y lo saca de la caché), o null.
static func tomar(p: Principal, menu: Dictionary) -> PantallaMenu:
	var id := String(menu["id"])
	var n: PantallaMenu = _guardados.get(id)
	_guardados.erase(id)
	if n == null or not is_instance_valid(n):
		return null
	if not activo or n._p != p or String(n.get_meta("huella", "")) != huella(p, menu):
		n.free()
		return null
	for c: Dictionary in n.cerrada.get_connections():
		n.cerrada.disconnect(c["callable"])
	n._cerrando = false
	n.modulate.a = 1.0
	return n

## Al terminar de cerrarse: se guarda (en su portada) en vez de borrarse.
static func guardar(n: PantallaMenu) -> void:
	if not activo or not is_instance_valid(n) or n._p == null or not is_instance_valid(n._p) or n._p.mundo == null or not n.is_inside_tree():
		if is_instance_valid(n):
			n.queue_free()
		return
	if n._activo >= 0:   ## estaba en un submenú: se deja en la portada, aún invisible (modulate 0)
		n._cerrando = false
		n.portada()
		n._cerrando = true
	_meter(n)

static func _meter(n: PantallaMenu) -> void:
	var id := String(n.get_meta("id", ""))
	n.set_meta("huella", huella(n._p, n._menu))
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	var viejo: PantallaMenu = _guardados.get(id)
	if viejo != null and is_instance_valid(viejo) and viejo != n:
		viejo.free()
	_guardados.erase(id)
	_guardados[id] = n
	while _guardados.size() > MAX:
		var primero: String = _guardados.keys()[0]
		var sobra: PantallaMenu = _guardados[primero]
		_guardados.erase(primero)
		if is_instance_valid(sobra):
			sobra.free()
	if not n._p.tree_exiting.is_connected(vaciar):
		n._p.tree_exiting.connect(vaciar)

static func usado(id: String) -> void:
	_usos[id] = int(_usos.get(id, 0)) + 1

## En reposo: arma a escondidas el menú que más se abre, si no está ya guardado ni abierto.
static func precargar(p: Principal) -> void:
	if not activo or p == null or not p.is_inside_tree() or p.mundo == null:
		return
	var id := "plantel"
	var mas := 0
	for k: String in _usos:
		if int(_usos[k]) > mas:
			mas = int(_usos[k])
			id = k
	if _guardados.has(id):
		return
	var abierta: Variant = p._menu_lateral.pantalla_abierta if p.get("_menu_lateral") != null else null
	if abierta != null and is_instance_valid(abierta) and not (abierta as PantallaMenu).cerrando():
		return
	var menu: Dictionary = {}
	for m: Dictionary in MenuLateral.MENUS:
		if String(m["id"]) == id:
			menu = m
	if menu.is_empty():
		return
	var n := PantallaMenu.preparar(p, menu)
	n.visible = false
	p.add_child(n)
	n._montar()
	n.portada()
	n._cerrando = true
	n.visible = true
	_meter(n)

static func vaciar() -> void:
	for n: Variant in _guardados.values():
		if is_instance_valid(n):
			(n as PantallaMenu).free()
	_guardados.clear()

static func guardados() -> Array:
	return _guardados.keys()
