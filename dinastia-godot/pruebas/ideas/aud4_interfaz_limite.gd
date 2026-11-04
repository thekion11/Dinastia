extends BaseIdea
## MEGA AUDITORÍA 4 · INTERFAZ · REPASO 3 (al límite): casos absurdos sobre menús, idiomas y guardado. Cuenta nodos y objetos antes y después (fugas), abre y cierra cada menú muchas veces,
## pulsa dos veces, cambia de idioma con un menú abierto, abre todo con plantel vacío y caja en rojo, reinicia el tutorial seguido y guarda/carga con archivos rotos.
var _p: Principal
var _respaldo := {}

func _frames(n: int = 4) -> void:
	for i in n:
		await get_tree().process_frame

func _abierto() -> PantallaMenu:
	var pm: Variant = _p._menu_lateral.pantalla_abierta
	return pm as PantallaMenu if is_instance_valid(pm) and not (pm as PantallaMenu).cerrando() else null

func _cerrar() -> void:
	for c in get_tree().root.get_children():
		if c != self and not _raiz0.has(c):
			c.queue_free()
	_p.visible = true
	var pm := _abierto()
	if pm != null:
		pm.cerrar()
	await _frames(24)

var _raiz0: Array = []

func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

func _probar() -> void:
	_titulo("AUDITORÍA 4 · INTERFAZ AL LÍMITE")
	_respaldar_user()
	var m := _mundo(20261104)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _frames(6)
	_raiz0 = get_tree().root.get_children()
	for t in get_tree().root.find_children("*", "", true, false):
		if t is Tutorial:
			(t as Tutorial)._terminar(false)
	CapasTutorial.poner_activas(false)
	await _fugas_de_menus()
	await _doble_pulsacion()
	await _idioma_a_mitad()
	await _tutorial_repetido()
	await _estado_extremo(m)
	_guardado_roto()
	_restaurar_user()

## Abrir y cerrar cada menú varias veces no deja nodos ni objetos huérfanos.
func _fugas_de_menus() -> void:
	var ids: Array[String] = []
	for mn: Dictionary in MenusLaterales.MENUS:
		ids.append(String(mn["id"]))
	for ronda in 2:   ## la primera ronda calienta cachés y cargas perezosas
		for id in ids:
			_p._menu_lateral.abrir_menu(id, -1)
			await _frames(4)
			await _cerrar()
	await _frames(10)
	var n0 := _nodos()
	var o0 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for ronda in 3:
		for id in ids:
			_p._menu_lateral.abrir_menu(id, -1)
			await _frames(4)
			await _cerrar()
	await _frames(20)
	var n1 := _nodos()
	var o1 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	_comprobar(n1 - n0 <= 60, "42 aperturas y cierres de menús no dejan nodos (antes %d, después %d, +%d)" % [n0, n1, n1 - n0])
	_comprobar(o1 - o0 <= 400, "ni objetos sueltos (antes %d, después %d, +%d)" % [o0, o1, o1 - o0])
	var huerfanos := 0
	for c in _p.get_children():
		if c is PantallaMenu and c != _abierto():
			huerfanos += 1
	_comprobar(huerfanos == 0, "no queda ninguna PantallaMenu cerrada colgando de Principal (%d)" % huerfanos)

## Pulsar dos veces el mismo botón del riel, o dos botones a la vez, deja un solo menú abierto.
func _doble_pulsacion() -> void:
	var b := _p._menu_lateral.boton_de("plantel")
	b.pressed.emit()
	b.pressed.emit()
	await _frames(6)
	var visibles := 0
	for c in _p.get_children():
		if c is PantallaMenu and not (c as PantallaMenu).cerrando():
			visibles += 1
	_comprobar(visibles == 1, "dos pulsaciones seguidas del mismo botón dejan UN menú (%d)" % visibles)
	_p._menu_lateral.boton_de("dinero").pressed.emit()
	_p._menu_lateral.boton_de("partido").pressed.emit()
	_p._menu_lateral.boton_de("ajustes").pressed.emit()
	await _frames(30)
	visibles = 0
	for c in _p.get_children():
		if c is PantallaMenu and not (c as PantallaMenu).cerrando():
			visibles += 1
	_comprobar(visibles == 1 and String(_abierto().get_meta("id", "")) == "ajustes", "tres botones pulsados a la vez: gana el último y queda UN menú (%d, %s)" % [visibles, String(_abierto().get_meta("id", "")) if _abierto() != null else "ninguno"])
	var colgando := 0
	for c in _p.get_children():
		if c is PantallaMenu and (c as PantallaMenu).cerrando():
			colgando += 1
	_comprobar(colgando == 0, "los menús que se cierran se liberan (%d colgando)" % colgando)
	await _cerrar()
	_comprobar(_p._menu_lateral.pantalla_abierta == null or not is_instance_valid(_p._menu_lateral.pantalla_abierta) or _p._menu_lateral.pantalla_abierta.cerrando(), "y al cerrar no queda referencia viva")

## Cambiar de idioma con un menú abierto no rompe nada y el texto cambia; volver al castellano lo deja igual.
func _idioma_a_mitad() -> void:
	var antes := Idiomas.idioma
	_p._menu_lateral.abrir_menu("plantel", 0)
	await _frames(100)   ## el menú se asienta (lo oculto de debajo se suelta cada 90 fotogramas, A4-INT-R01)
	var cuenta_es := _etiquetas()
	var textos_es := _textos_pantalla()
	for l: String in ["en", "ja", "tr", "pl", "ca", "de", "it", "fr", "pt", "es"]:
		Idiomas.idioma = l
		_p._refrescar()
		await _frames(3)
		_comprobar(_abierto() != null, "cambiar a «%s» con el menú abierto no lo cierra ni lo rompe" % l)
	await _frames(100)
	var cuenta_fin := _etiquetas()
	_comprobar(absi(cuenta_fin - cuenta_es) <= 4, "tras la vuelta por 10 idiomas, la pantalla tiene las mismas etiquetas (%d → %d)" % [cuenta_es, cuenta_fin])
	await _frames(100)
	var textos_fin := _textos_pantalla()
	_comprobar(textos_fin == textos_es, "y los textos de la pantalla abierta son los mismos tras repintar (%d → %d etiquetas)" % [textos_es.size(), textos_fin.size()])
	Idiomas.idioma = antes
	await _cerrar()

## Los textos visibles de la pantalla que está abierta (no los de la página de debajo, que se suelta al ocultarse).
func _textos_pantalla() -> Array:
	var r: Array = []
	var pm := _abierto()
	if pm == null:
		return r
	for l in pm.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree() and (l as Label).text.strip_edges() != "":
			r.append((l as Label).text)
	r.sort()
	return r

func _etiquetas() -> int:
	var n := 0
	for l in _p.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree() and (l as Label).text.strip_edges() != "":
			n += 1
	return n

## Abrir el tutorial varias veces seguidas deja uno solo.
func _tutorial_repetido() -> void:
	for i in 4:
		_p._guia.abrir("dt")
	await _frames(6)
	var n := 0
	for x in get_tree().root.find_children("*", "", true, false):
		if x is Tutorial:
			n += 1
	_comprobar(n == 1, "cuatro «abrir tutorial» seguidos dejan UN tutorial (%d)" % n)
	for x in get_tree().root.find_children("*", "", true, false):
		if x is Tutorial:
			(x as Tutorial)._terminar(false)
	await _frames(4)
	n = 0
	for x in get_tree().root.find_children("*", "", true, false):
		if x is Tutorial and not (x as Tutorial).is_queued_for_deletion():
			n += 1
	_comprobar(n == 0, "al terminarlo no queda ninguno (%d)" % n)

## Plantel vacío, caja en rojo y sin jugadores a la venta: se abre CADA submenú sin romper.
func _estado_extremo(m: Mundo) -> void:
	var club := m.mi_club()
	var plantilla_antes: Array = club.plantilla.duplicate()
	var saldo_antes := club.saldo
	club.plantilla.clear()
	club.saldo = -250000000
	_p._refrescar()
	await _frames(4)
	var errores: Array[String] = []
	var n := 0
	for mn: Dictionary in MenusLaterales.MENUS:
		var subs: Array = mn["subs"]
		for i in subs.size():
			if (subs[i] as Dictionary).has("accion") or String((subs[i] as Dictionary).get("secc", "")) == "kits":
				continue
			n += 1
			_p._menu_lateral.abrir_menu(String(mn["id"]), i)
			await _frames(5)
			if _abierto() == null:
				errores.append("%s/%d no abre" % [mn["id"], i])
			await _cerrar()
	_comprobar(errores.is_empty(), "con plantel vacío y caja en −250 M se abren los %d submenús %s" % [n, str(errores.slice(0, 4))])
	club.plantilla = plantilla_antes
	club.saldo = saldo_antes
	_p._refrescar()
	await _frames(3)

## Guardar y cargar con archivos rotos, vacíos o de otra versión.
func _guardado_roto() -> void:
	var nombre := "aud4_prueba"
	var m := _mundo(777)
	_comprobar(Partida.guardar(m, nombre), "guarda una partida de prueba")
	var ruta := Partida.ruta_de(nombre)
	_comprobar(Partida.cargar(nombre) != null, "se carga")
	## Truncada a la mitad.
	var bytes := FileAccess.get_file_as_bytes(ruta)
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_buffer(bytes.slice(0, bytes.size() / 2))
	f.close()
	var c1 := Partida.cargar(nombre)
	_comprobar(c1 == null or c1.mi_club() != null, "un archivo truncado no rompe el juego (devuelve null o recupera la copia): %s" % ("null" if c1 == null else "mundo de la copia"))
	## Vacío.
	f = FileAccess.open(ruta, FileAccess.WRITE)
	f.close()
	var c2 := Partida.cargar(nombre)
	_comprobar(c2 == null or c2.mi_club() != null, "un archivo vacío tampoco: %s" % ("null" if c2 == null else "mundo de la copia"))
	## Basura.
	f = FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string("esto no es una partida {{{")
	f.close()
	var c3 := Partida.cargar(nombre)
	_comprobar(c3 == null or c3.mi_club() != null, "ni un archivo con basura: %s" % ("null" if c3 == null else "mundo de la copia"))
	Partida.borrar(nombre)
	for e in DirAccess.get_files_at(Partida.CARPETA):
		if e.begins_with(nombre):
			DirAccess.remove_absolute(Partida.CARPETA + "/" + e)
	_comprobar(Partida.cargar(nombre) == null, "una ranura que no existe devuelve null")
