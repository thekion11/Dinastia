extends Node
## (9-11) REGLA DEL DUEÑO: los eventos solo salen al llegar a su fecha. El aviso del partido de despedida (a pantalla completa) NO sale a mitad de temporada ni al
## abrir un menú: sale cuando la liga termina y se refresca la pantalla, y una sola vez. Necesita pantalla: xvfb-run -a godot --path . --rendering-driver opengl3 …
var _n := 0
var _p: Node
var _fase := 0

func _ready() -> void:
	AvanceSemana.partido_obliga = false
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

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
		var antes := _evento() == null
		print("a mitad de temporada no hay evento: ", antes)
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
		var ev := _evento()
		var sale := ev != null
		print("al terminar la liga sale el aviso a pantalla completa: ", sale)
		var completa := false
		if sale:
			var r: Control = ev.get("_raiz")
			completa = r != null and r.get_global_rect().size.is_equal_approx(get_viewport().get_visible_rect().size)
		print("ocupa toda la pantalla: ", completa)
		if sale:
			ev.emit_signal("elegido", "no")
		_fase = 3
		_n = 80
		if not (sale and completa):
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
