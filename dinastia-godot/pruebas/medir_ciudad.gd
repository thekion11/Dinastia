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
	if _n == 71 and OS.get_environment("PARTES") != "":
		_res["aerea"] = _media(_m)
		print("MEDIDA_CIUDAD ", JSON.stringify(_res))
		_v.set("_girando", false)   ## sin giro: si no, cada medida mira a otro sitio
		_partes_aerea()
		return
	if _n == 71:
		_res["aerea"] = _media(_m)
		if OS.get_environment("DETALLE") != "":
			_detalle()
			var por_dueno := {}
			for g in _v.find_children("*", "MeshInstance3D", true, false):
				if g.get_parent() is Skeleton3D and g.is_visible_in_tree():
					var a: Node = g
					var cadena := ""
					for k in 6:
						a = a.get_parent()
						if a == null or a == _v:
							break
						cadena += String(a.name).left(14) + "<"
					var kk := "%s rango=%.0f" % [cadena, (g as GeometryInstance3D).visibility_range_end]
					por_dueno[kk] = int(por_dueno.get(kk, 0)) + 1
			for kk in por_dueno:
				print("CUERPO ", por_dueno[kk], " ", kk)
			for f: Dictionary in Optimizar.informe(_v, 22):
				print("TRIS %9d  piezas=%d corte=%.0f  %s" % [f["tris"], f["piezas"], f["corte"], f["clave"]])
		_m.clear()
		_v.explorar("pie")
		var e: ExploradorCiudad = _v.get("_explorador")
		e.cuerpo.position = Vector3(20, 0.2, 300)
	if _n > 100 and _n <= 130:
		_m.append(_muestra())
	if _n == 131:
		_res["a_pie"] = _media(_m)
		var ex: ExploradorCiudad = _v.get("_explorador")
		_res["circulos"] = ex.cb.circulos.size()
		var ok := 0
		var n_prueba := mini(40, ex.cb.circulos.size())
		for i in n_prueba:
			var c: Vector3 = ex.cb.circulos[i * (ex.cb.circulos.size() / maxi(n_prueba, 1))]
			if not ex.libre_total(Vector3(c.x, 0.2, c.y), 0.3):
				ok += 1
		_res["circulos_solidos"] = "%d de %d" % [ok, n_prueba]
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

func _cat(g: GeometryInstance3D) -> String:
	var estadio := false
	var a: Node = g
	while a != null:
		if a.has_meta("sin_corte"):
			estadio = true
		a = a.get_parent()
	if estadio:
		return "estadio"
	if g.get_parent() is Skeleton3D:
		return "cuerpos"
	if String(g.name) == "EdificiosLejos":
		return "edificios_lejos"
	var m: Mesh = null
	var n_inst := 1
	if g is MeshInstance3D:
		m = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null:
		m = (g as MultiMeshInstance3D).multimesh.mesh
		n_inst = (g as MultiMeshInstance3D).multimesh.instance_count
	if m == null:
		return "otros"
	var t := Optimizar._tris(m)
	if m is ArrayMesh and t > 1500:
		return "edificios_%s" % ("multi" if g is MultiMeshInstance3D else "suelto")
	if m is ArrayMesh:
		return "modelos_chicos"
	if m is CylinderMesh or m is SphereMesh or m is CapsuleMesh:
		return "cilindros_esferas"
	if m is BoxMesh:
		return "cajas"
	return "otros"

func _partes_aerea() -> void:
	var grupos := {}
	for g in _v.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D or not g.is_visible_in_tree():
			continue
		var k := _cat(g)
		if not grupos.has(k):
			grupos[k] = []
		grupos[k].append(g)
	var det := {}
	for g in grupos.get("cilindros_esferas", []):
		var m2: Mesh = (g as MeshInstance3D).mesh if g is MeshInstance3D else (g as MultiMeshInstance3D).multimesh.mesh
		var n2 := 1 if g is MeshInstance3D else (g as MultiMeshInstance3D).multimesh.instance_count
		var d := ""
		if m2 is CylinderMesh:
			d = "cil r=%.2f h=%.1f seg=%d" % [(m2 as CylinderMesh).top_radius, (m2 as CylinderMesh).height, (m2 as CylinderMesh).radial_segments]
		elif m2 is SphereMesh:
			d = "esf r=%.2f seg=%d anillos=%d" % [(m2 as SphereMesh).radius, (m2 as SphereMesh).radial_segments, (m2 as SphereMesh).rings]
		else:
			d = m2.get_class()
		var kk := "%s (%d tris/u, %s)" % [d, Optimizar._tris(m2), String(g.get_parent().name).left(12)]
		det[kk] = int(det.get(kk, 0)) + n2
	var ord := det.keys()
	ord.sort_custom(func(a, b): return det[a] * 1 > det[b] * 1)
	for kk in ord.slice(0, 14):
		print("CIL %6d  %s" % [det[kk], kk])
	var base := await _medir_prim()
	print("PARTES base %d tris" % base)
	for k: String in grupos:
		for g in grupos[k]:
			g.visible = false
		var t := await _medir_prim()
		for g in grupos[k]:
			g.visible = true
		print("PARTES sin %-18s (%4d nodos) -%d tris" % [k, grupos[k].size(), base - t])
	get_tree().quit()

func _medir_prim() -> int:
	for i in 4:
		await get_tree().process_frame
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
