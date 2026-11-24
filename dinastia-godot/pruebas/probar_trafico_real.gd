extends Node
## EL TRÁFICO DE LA CIUDAD REAL, C++ frente a GDScript (18-11-2026, ciudad a C++): abre la ciudad a pie (como `sonda_explorador`), guarda el estado de los ~380 móviles,
## corre PASOS pasos con `_paso_gd`, restaura el estado y el azar y corre otros tantos con la extensión; los diccionarios (con tipo), las posiciones, los giros y el
## azar global tienen que ser idénticos. Complementa `probar_nativo_ciudad` (cruce sintético) con rutas, paradas, semáforos y peatones reales.
##   godot --headless --path . res://pruebas/probar_trafico_real.tscn
const PASOS := 600
const DT := 1.0 / 30.0

func _ready() -> void:
	InterruptorCiudad.activa = true
	Calidad.elegida = Calidad.MEDIO
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 6:
		await get_tree().process_frame
	p.call("_ver_ciudad_propia")
	var v: VistaCiudad = null
	for h in p.get_children():
		if h is VistaCiudad:
			v = h
	v.explorar("pie")
	for i in 3:
		await get_tree().process_frame
	var e: ExploradorCiudad = v.get("_explorador")
	var t: TraficoCiudad = e.trafico
	t.set_process(false)
	e.set_physics_process(false)
	e.set_process(false)
	if not (Nativo.obj() != null and Nativo.obj().has_method("trafico_paso")):
		print("FALLO la extensión no tiene trafico_paso")
		get_tree().quit(1)
		return
	var sem: Semaforos = t.semaforos
	t.volcar_estado_nativo()   ## el tráfico corrió con la extensión mientras se abría la ciudad: sus `lod` y `dt` aún no están en los diccionarios
	var guardado := _guardar(t)
	var t_sem := sem.t
	var ini := _correr(t, sem, false)
	_restaurar(t, guardado)
	sem.t = t_sem
	var fin := _correr(t, sem, true)
	var fallos := 0
	for i in PASOS:
		if ini["h"][i] != fin["h"][i]:
			print("FALLO el estado difiere desde el paso %d" % i)
			if i == 0:
				var a: Array = _p0[0]
				var b: Array = _p0[1]
				var cuenta := 0
				for q in a.size():
					if a[q] != b[q] and cuenta < 3:
						cuenta += 1
						for z in mini(a[q].size(), b[q].size()):
							if a[q][z] != b[q][z]:
								print("  móvil %d: GDScript %s | C++ %s" % [q, str(a[q][z]), str(b[q][z])])
								break
			fallos += 1
			break
	if ini["azar"] != fin["azar"]:
		print("FALLO el azar global llegó distinto: %s frente a %s" % [str(ini["azar"]), str(fin["azar"])])
		fallos += 1
	var movidos := 0
	for q in t._vehiculos.size():
		if absf(float(t._vehiculos[q]["s"]) - float(guardado[q]["d"]["s"])) > 1.0:
			movidos += 1
	if movidos < 20:
		print("FALLO casi nadie se movió (%d)" % movidos)
		fallos += 1
	print("tráfico real: %d móviles, %d pasos, %d recorren más de 1 m, controles %d" % [t._vehiculos.size(), PASOS, movidos, t._controles.size()])
	print("FIN. %d fallos" % fallos)
	get_tree().quit(fallos)

static var _p0: Array = []

func _huella_filas(t: TraficoCiudad) -> Array:
	var hs: Array = []
	for v: Dictionary in t._vehiculos:
		var ks := v.keys()
		ks.sort()
		var fila: Array = []
		for k in ks:
			var x: Variant = v[k]
			if x is Object:
				continue
			fila.append([k, typeof(x), x])
		var n: Node3D = v["nodo"]
		fila.append(n.position)
		fila.append(n.rotation)
		hs.append(fila)
	return hs

func _huella(t: TraficoCiudad) -> int:
	var hs: Array = []
	for v: Dictionary in t._vehiculos:
		var ks := v.keys()
		ks.sort()
		var fila: Array = []
		for k in ks:
			var x: Variant = v[k]
			if x is Object:
				continue
			fila.append([k, typeof(x), x])
		var n: Node3D = v["nodo"]
		fila.append(n.position)
		fila.append(n.rotation)
		hs.append(fila)
	return hash(hs)

func _correr(t: TraficoCiudad, sem: Semaforos, nativo: bool) -> Dictionary:
	t.usar_nativo = nativo
	seed(1811)
	var hs: Array = []
	for i in PASOS:
		sem.t = fposmod(sem.t + DT, Semaforos.CICLO)
		sem._t_npc = -1000000
		t._process(DT)
		if nativo:
			t.volcar_estado_nativo()   ## `lod` y `dt` viven en la extensión: se escriben en los diccionarios para compararlos
		if i == 0:
			_p0.append(_huella_filas(t))
		hs.append(_huella(t))
	return {"h": hs, "azar": randf()}

func _guardar(t: TraficoCiudad) -> Array:
	var g: Array = []
	for v: Dictionary in t._vehiculos:
		var d := {}
		for k in v.keys():
			var x: Variant = v[k]
			if not (x is Object):
				d[k] = x
		var n: Node3D = v["nodo"]
		g.append({"d": d, "pos": n.position, "rot": n.rotation})
	return g

func _restaurar(t: TraficoCiudad, g: Array) -> void:
	t._ver_estado += 1   ## la extensión relee `lod`, `dt` y `alto` de los diccionarios restaurados
	for i in t._vehiculos.size():
		var v: Dictionary = t._vehiculos[i]
		for k in v.keys():
			if not (v[k] is Object) and not g[i]["d"].has(k):
				v.erase(k)
		for k in g[i]["d"].keys():
			v[k] = g[i]["d"][k]
		var n: Node3D = v["nodo"]
		n.position = g[i]["pos"]
		n.rotation = g[i]["rot"]
