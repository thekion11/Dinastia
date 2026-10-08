extends Node
## RENDIMIENTO DE LA CIUDAD 3D (etapa 3, 8-10-2026). La escena más grande del
## juego (2.640 m, miles de piezas). Mide, con calidad MEDIO (la de un equipo
## modesto): el tiempo de construcción y, en régimen, llamadas de dibujo,
## primitivas, objetos y nodos en dos vistas -la aérea del mapa y a pie-.
## Los FPS de este servidor (render por software) no valen como absoluto; lo
## comparable entre versiones es lo que el juego le PIDE a la gráfica.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/medir_ciudad.tscn
var _p: Node
var _v: VistaCiudad
var _n := 0
var _t0 := 0
var _fase := "aerea"
var _m: Array = []
var _res := {}

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _muestra() -> Dictionary:
	return {
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitivas": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objetos": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"nodos": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"frame_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
	}

func _media(arr: Array) -> Dictionary:
	var r := {}
	for k: String in arr[0]:
		var s := 0.0
		for x: Dictionary in arr:
			s += float(x[k])
		r[k] = snappedf(s / arr.size(), 0.1)
	return r

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		_t0 = Time.get_ticks_msec()
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_res["construir_ms"] = Time.get_ticks_msec() - _t0
	if _n > 40 and _n <= 70:
		_m.append(_muestra())
	if _n == 71:
		_res["aerea"] = _media(_m)
		_m.clear()
		_v.explorar("pie")
		var e: ExploradorCiudad = _v.get("_explorador")
		e.cuerpo.position = Vector3(20, 0.2, 300)
	if _n > 100 and _n <= 130:
		_m.append(_muestra())
	if _n == 131:
		_res["a_pie"] = _media(_m)
		print("MEDIDA_CIUDAD ", JSON.stringify(_res))
		get_tree().quit()
