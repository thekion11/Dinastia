extends Node
## ANÁLISIS DE LA CIUDAD POR ZONAS (7-11-2026). Construye la ciudad y reparte TODA su geometría (mallas, instancias de
## MultiMesh y triángulos) entre las manzanas de `CiudadExpansion.bloques` según dónde cae; lo que no cae en ninguna manzana
## (calles, autopista, edificios lejanos, estadio…) se cuenta por el nombre de su padre. Salida: líneas `ZONA uso …` y `RESTO padre …`.
##   CALIDAD=minimo HW_RAM_MB=12000 bash herramientas/hw_modesto.sh res://pruebas/analisis_ciudad.tscn
var _p: Node
var _n := 0
var _cb: Node
var _zonas := {}   ## uso → {bloques, mallas, inst, tris, nodos}
var _resto := {}   ## padre → {mallas, inst, tris}
var _bloques: Array = []
var _mallas := {}   ## «uso malla» → [instancias, triángulos]

func _malla(uso: String, m: Mesh, cant: int, t: int) -> void:
	var k := uso.get_slice("|", 0) + " " + (m.resource_path.get_file() if m.resource_path != "" else m.resource_name) + " t=" + str(triangulos(m))
	var v: Array = _mallas.get(k, [0, 0])
	v[0] += cant
	v[1] += t
	_mallas[k] = v

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("CALIDAD") == "minimo" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	Engine.max_fps = 0
	_n += 1
	if _n == 5:
		_p.call("_ver_ciudad_propia")
	if _n == 60:
		for h in _p.get_children():
			if h is VistaCiudad:
				_cb = h.get("_raiz3d")
				for q in h.find_children("*", "Node3D", true, false):
					if q is CityBuilder:
						_cb = q
		_analizar()
		get_tree().quit()

static func triangulos(m: Mesh) -> int:
	if m == null:
		return 0
	var t := 0
	for s in m.get_surface_count():
		if m is ArrayMesh:
			var ni := (m as ArrayMesh).surface_get_array_index_len(s)
			t += (ni if ni > 0 else (m as ArrayMesh).surface_get_array_len(s)) / 3
		else:
			return m.get_faces().size() / 3
	return t

func _zona_de(x: float, z: float) -> String:
	for b: Dictionary in _bloques:
		if (b["rect"] as Rect2).has_point(Vector2(x, z)):
			return String(b["uso"]) + "|" + String(b["zona"])
	return ""

func _sumar(clave: String, dic: Dictionary, mallas: int, inst: int, tris: int) -> void:
	if not dic.has(clave):
		dic[clave] = {"bloques": 0, "mallas": 0, "inst": 0, "tris": 0}
	var d: Dictionary = dic[clave]
	d["mallas"] += mallas
	d["inst"] += inst
	d["tris"] += tris

func _analizar() -> void:
	var ex = _cb.get("expansion")
	_bloques = ex.bloques
	for b: Dictionary in _bloques:
		var k := String(b["uso"]) + "|" + String(b["zona"])
		_sumar(k, _zonas, 0, 0, 0)
		_zonas[k]["bloques"] += 1
	for n in _cb.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		var padre := String(g.get_parent().name).rstrip("0123456789@")
		if g is MeshInstance3D:
			var mi := g as MeshInstance3D
			if mi.mesh == null:
				continue
			var c := (mi.global_transform * mi.get_aabb()).get_center()
			var z := _zona_de(c.x, c.z)
			if z != "":
				_sumar(z, _zonas, 1, 1, triangulos(mi.mesh))
				_malla(z, mi.mesh, 1, triangulos(mi.mesh))
			else:
				_sumar(padre, _resto, 1, 1, triangulos(mi.mesh))
		elif g is MultiMeshInstance3D:
			var mm := (g as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			var t := triangulos(mm.mesh)
			var buf := mm.buffer
			var paso := Optimizar.paso_buffer(mm)
			var gt := g.global_transform
			var por := {}
			for i in mm.instance_count:
				var o := gt * Vector3(buf[i * paso + 3], buf[i * paso + 7], buf[i * paso + 11])
				var z := _zona_de(o.x, o.z)
				var k := z if z != "" else "~" + padre
				por[k] = int(por.get(k, 0)) + 1
			for k: String in por:
				var cant := int(por[k])
				if k.begins_with("~"):
					_sumar(k.substr(1), _resto, 1, cant, t * cant)
				else:
					_sumar(k, _zonas, 1, cant, t * cant)
					_malla(k, mm.mesh, cant, t * cant)
	var total := 0
	for k: String in _zonas:
		total += int(_zonas[k]["tris"])
	for k: String in _resto:
		total += int(_resto[k]["tris"])
	for k: String in _zonas:
		var d: Dictionary = _zonas[k]
		print("ZONA ", k, " bloques=", d["bloques"], " mallas=", d["mallas"], " inst=", d["inst"], " tris=", d["tris"])
	for k: String in _resto:
		var d: Dictionary = _resto[k]
		print("RESTO ", k, " mallas=", d["mallas"], " inst=", d["inst"], " tris=", d["tris"])
	print("TOTAL_TRIS ", total)
	for k: String in _mallas:
		print("MALLA ", k, " inst=", _mallas[k][0], " tris=", _mallas[k][1])
