extends Node
## (9-11) REGLA DEL DUEÑO: los eventos solo salen al llegar a su fecha. El aviso del partido de despedida (a pantalla completa) NO sale a mitad de temporada ni al
## abrir un menú: sale cuando la liga termina y se refresca la pantalla, y una sola vez. Necesita pantalla: xvfb-run -a godot --path . --rendering-driver opengl3 …
var _n := 0
var _p: Node
var _fase := 0
var completa_extra := false

func _ready() -> void:
	AvanceSemana.partido_obliga = false
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _ids_calendario() -> Array:
	var pop: PopupMenu = (_p._guia.nodos["calendario"] as MenuButton).get_popup()
	var ids: Array = []
	for i in pop.item_count:
		ids.append(pop.get_item_id(i))
	return ids

func _foto(nombre: String) -> void:
	if OS.get_environment("CAPTURAR") == "":
		return
	(_p._guia.nodos["calendario"] as MenuButton).show_popup()
	await get_tree().create_timer(0.6).timeout
	get_viewport().get_texture().get_image().save_jpg("/tmp/calendario_%s.jpg" % nombre, 0.9)
	(_p._guia.nodos["calendario"] as MenuButton).get_popup().hide()

func _evento() -> Node:
	for h in _p.get_children():
		if h is EventoDespedida:
			return h
	return null

func _process(_d: float) -> void:
	_n += 1
	if _n == 12 and _fase == 0:
		_p._refrescar()
		_p.mundo.avanzar_semana()
		_p._refrescar()
		_fase = 1
	elif _fase == 1 and _n > 30:
		_fase = 11   ## evita reentrar en cada fotograma mientras espera la foto
		var antes := _evento() == null
		print("a mitad de temporada no hay evento: ", antes)
		var mitad := _ids_calendario()
		var sin_siguiente := not mitad.has(3) and mitad.has(0) and mitad.has(1)
		print("a mitad de temporada NO existe «Temporada siguiente» (ids ", mitad, "): ", sin_siguiente)
		await _foto("mitad")
		antes = antes and sin_siguiente
		var guard := 0
		while _p.mundo.temporada_en_curso() and guard < 80:
			_p.mundo.avanzar_semana()
			guard += 1
		_p._refrescar()   ## la liga ya terminó: llega la fecha
		_fase = 2
		_n = 40
		if not antes:
			print("FIN. 1 fallos"); get_tree().quit()
	elif _fase == 2 and _n > 70:
		_fase = 12
		var ev := _evento()
		var sale := ev != null
		print("al terminar la liga sale el aviso a pantalla completa: ", sale)
		var fin := _ids_calendario()
		var solo_siguiente := fin == [3]
		print("al terminar la liga SOLO existe «Temporada siguiente» (ids ", fin, "): ", solo_siguiente)
		completa_extra = solo_siguiente
		var completa := false
		if sale:
			var r: Control = ev.get("_raiz")
			completa = r != null and r.get_global_rect().size.is_equal_approx(get_viewport().get_visible_rect().size)
		print("ocupa toda la pantalla: ", completa)
		if sale:
			ev.emit_signal("elegido", "no")
			await get_tree().create_timer(0.7).timeout
			await _foto("fin")
		_fase = 3
		_n = 80
		if not (sale and completa and completa_extra):
			print("FIN. 1 fallos"); get_tree().quit()
	elif _fase == 3 and _n > 110:
		_p._refrescar()   ## otro refresco: no vuelve a salir
		_fase = 4
		_n = 120
	elif _fase == 4 and _n > 140:
		var otra := _evento() == null
		print("no se repite en la misma temporada: ", otra)
		print("FIN. ", 0 if otra else 1, " fallos")
		get_tree().quit()
