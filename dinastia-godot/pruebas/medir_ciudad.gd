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
		## Tiempo REAL entre fotogramas (el monitor TIME_PROCESS se refresca una
		## vez por segundo y arrastraba la construcción). Sin gráfica (headless)
		## es el coste de la CPU: scripts, animación y física.
		"frame_ms": _dt_ms,
	}

func _media(arr: Array) -> Dictionary:
	var r := {}
	for k: String in arr[0]:
		var s := 0.0
		for x: Dictionary in arr:
			s += float(x[k])
		r[k] = snappedf(s / arr.size(), 0.1)
	return r

var _t_prev := 0
var _dt_ms := 0.0

func _process(_d: float) -> void:
	var ahora := Time.get_ticks_usec()
	_dt_ms = (ahora - _t_prev) / 1000.0
	_t_prev = ahora
	## Sin tope de FPS (Principal pone el que eligió el jugador).
	Engine.max_fps = 0
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
		if OS.get_environment("CUADROS") != "":
			print("CUADRO ", _n, " ", snappedf(_m[-1]["frame_ms"], 0.1))
	if _n == 71:
		_res["aerea"] = _media(_m)
		if OS.get_environment("DETALLE") != "":
			_detalle()
		_m.clear()
		_v.explorar("pie")
		var e: ExploradorCiudad = _v.get("_explorador")
		e.cuerpo.position = Vector3(20, 0.2, 300)
	if _n > 100 and _n <= 130:
		_m.append(_muestra())
	if _n == 131:
		_res["a_pie"] = _media(_m)
		if OS.get_environment("CPU") != "":
			_cpu_por_partes()
			return
		print("MEDIDA_CIUDAD ", JSON.stringify(_res))
		get_tree().quit()

## Con DETALLE=1: qué piezas sueltas (sin distancia de corte) pesan más, por
## el nombre del nodo padre. Sirve para elegir dónde atacar.
func _detalle() -> void:
	var grupos := {}
	for n in _v.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() or g.visibility_range_end > 0.0:
			continue
		var nom := ""
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			nom = (g as MeshInstance3D).mesh.resource_name
		var clave := String(g.get_parent().name).rstrip("0123456789@") + "/" + g.get_class() + " " + nom + " d=" + str(snappedf(Optimizar._diagonal(g), 5.0))
		grupos[clave] = int(grupos.get(clave, 0)) + 1
	var orden := grupos.keys()
	orden.sort_custom(func(a, b): return grupos[a] > grupos[b])
	for k in orden.slice(0, 30):
		print("DETALLE ", grupos[k], "  ", k)

## Con CPU=1 (headless): apaga el `_process` de cada sistema a la vez y mide
## cuánto baja el fotograma a pie. Dice dónde se va la CPU.
func _cpu_por_partes() -> void:
	var por_clase := {}
	for n in _v.find_children("*", "Node", true, false):
		if n.get_script() != null and (n.is_processing() or n.is_physics_processing()):
			var k := String(n.get_script().resource_path.get_file())
			if not por_clase.has(k):
				por_clase[k] = []
			por_clase[k].append(n)
	var base := await _medir_cuadros(40)
	print("CPU base %.2f ms  (%d clases con proceso)" % [base, por_clase.size()])
	for k: String in por_clase:
		for n: Node in por_clase[k]:
			n.process_mode = Node.PROCESS_MODE_DISABLED
		var t := await _medir_cuadros(40)
		for n: Node in por_clase[k]:
			n.process_mode = Node.PROCESS_MODE_INHERIT
		print("CPU sin %-28s x%-4d -%.2f ms" % [k, por_clase[k].size(), base - t])
	for clase in ["AnimationPlayer", "AnimationTree", "Skeleton3D", "PhysicsBody3D", "Area3D", "Label3D"]:
		var ns := _v.find_children("*", clase, true, false)
		for n in ns:
			n.process_mode = Node.PROCESS_MODE_DISABLED
		var t2 := await _medir_cuadros(40)
		for n in ns:
			n.process_mode = Node.PROCESS_MODE_INHERIT
		print("CPU sin %-28s x%-4d -%.2f ms" % [clase, ns.size(), base - t2])
	get_tree().quit()

func _medir_cuadros(c: int) -> float:
	for i in 5:
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	for i in c:
		await get_tree().process_frame
	return (Time.get_ticks_usec() - t0) / 1000.0 / c
