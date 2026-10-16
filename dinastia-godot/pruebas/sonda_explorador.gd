extends Node
## SONDA DEL PASEO (15-10-2026): cuánto cuesta cada cálculo del explorador de la
## ciudad que se repite en CADA fotograma de física. Abre la ciudad a pie como
## `perfil_cpu` y llama N veces a cada función, en µs por llamada.
##   godot --headless --path . res://pruebas/sonda_explorador.tscn
const N := 120
var _p: Node

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 6:
		await get_tree().process_frame
	_p.call("_ver_ciudad_propia")
	var v: VistaCiudad = null
	for h in _p.get_children():
		if h is VistaCiudad:
			v = h
	v.explorar("pie")
	for i in 3:
		await get_tree().process_frame
	var e: ExploradorCiudad = v.get("_explorador")
	e.cuerpo.position = Vector3(1005.0, e.altura_suelo(1005.0, -500.0), -500.0)
	e.trafico.reciclar_peatones(e.cuerpo.position, Vector3.ZERO, 70.0, 22, 28, true)
	for i in 30:
		await get_tree().process_frame
	var p := e.cuerpo.position
	var cb: CityBuilder = e.cb
	var pruebas := {
		"libre_total": func() -> void: e.libre_total(p + Vector3(0.05, 0, 0), 0.35),
		"altura_suelo": func() -> void: e.altura_suelo(p.x, p.z),
		"_buscar_cerca": func() -> void: e.call("_buscar_cerca"),
		"edificio_en": func() -> void: e.edificio_en(p),
		"nombre_calle_en": func() -> void: cb.expansion.nombre_calle_en(p),
		"Idiomas.t hud": func() -> void: Idiomas.t("  ·  %d km/h  ·  W/S/A/D o mando · %sE: interactuar · Esc: volver al mapa"),
		"_colocar_camara": func() -> void: e.call("_colocar_camara", 0.016),
		"_physics_process": func() -> void: e._physics_process(0.016),
		"trafico._process": func() -> void: e.trafico._process(0.016),
	}
	print("SONDA tráfico en el origen: %s · %d móviles" % [e.trafico.global_transform.is_equal_approx(Transform3D.IDENTITY), e.trafico._vehiculos.size()])
	var cam := get_viewport().get_camera_3d()
	var cerca := 0
	var peat := 0
	for v: Dictionary in e.trafico._vehiculos:
		var q: Vector3 = (v["nodo"] as Node3D).position
		if absf(q.x - cam.global_position.x) <= 150.0 and absf(q.z - cam.global_position.z) <= 150.0:
			cerca += 1
			if float(v["alto"]) > 0.05 and float(v["alto"]) < 0.3:
				peat += 1
	print("SONDA móviles a <150 m de la cámara: %d (%d peatones)" % [cerca, peat])
	## La rejilla de huellas tiene que decir lo mismo que recorrerlas todas.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var distintos := 0
	for i in 5000:
		var q := p + Vector3(rng.randf_range(-400, 400), 0, rng.randf_range(-400, 400))
		var r := rng.randf_range(0.2, 2.5)
		if e.libre_obst(q, r) != ExploradorCiudad.libre(q, r, e.obstaculos):
			distintos += 1
	print("SONDA rejilla == lineal: %s (%d distintos de 5000)" % [distintos == 0, distintos])
	pruebas["libre lineal"] = func() -> void: ExploradorCiudad.libre(p + Vector3(0.05, 0, 0), 0.35, e.obstaculos)
	for k: String in pruebas:
		var f: Callable = pruebas[k]
		var t0 := Time.get_ticks_usec()
		for i in N:
			f.call()
		print("SONDA %-18s %8.1f µs" % [k, float(Time.get_ticks_usec() - t0) / N])
	## Todos los scripts con _process/_physics_process del árbol, uno a uno.
	var costes: Array = []
	var por_script := {}
	for n in get_tree().root.find_children("*", "", true, false):
		if n == self or n.get_script() == null:
			continue
		for m: String in ["_process", "_physics_process"]:
			if n.has_method(m) and (n.is_processing() if m == "_process" else n.is_physics_processing()):
				var t0 := Time.get_ticks_usec()
				for i in 20:
					n.call(m, 0.016)
				var us := float(Time.get_ticks_usec() - t0) / 20.0
				var k := "%s %s" % [(n.get_script() as Script).resource_path.get_file(), m]
				por_script[k] = float(por_script.get(k, 0.0)) + us
	for k: String in por_script:
		costes.append([por_script[k], k])
	costes.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for c: Array in costes.slice(0, 18):
		print("SCRIPT %8.1f µs  %s" % [c[0], c[1]])
	get_tree().quit()
