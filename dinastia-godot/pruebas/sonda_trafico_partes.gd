extends Node
## SONDA DEL PASEO (15-10-2026): cuánto cuesta cada cálculo del explorador de la
## ciudad que se repite en CADA fotograma de física. Abre la ciudad a pie como
## `perfil_cpu` y llama N veces a cada función, en µs por llamada.
##   godot --headless --path . res://pruebas/sonda_explorador.tscn
const N := 120
var _p: Node

func _ready() -> void:
	InterruptorCiudad.activa = true
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
	var t: TraficoCiudad = e.trafico
	var cam := get_viewport().get_camera_3d()
	var ojo := cam.global_position
	var n := t._vehiculos.size()
	var casos := {
		"_process (C++)": func() -> void:
			t.usar_nativo = true
			t._process(0.016),
		"_process (GDScript)": func() -> void:
			t.usar_nativo = false
			t._process(0.016),
		"_rejilla_paso": func() -> void: t._rejilla_paso(ojo),
		"_colocar x todos": func() -> void:
			for m: Dictionary in t._vehiculos: t._colocar(m, 0.016),
		"Ruta.en x todos": func() -> void:
			for m: Dictionary in t._vehiculos: (t._rutas[int(m["ruta"])] as TraficoCiudad.Ruta).en(float(m["s"])),
		"_cede_paso x todos": func() -> void:
			var i := 0
			for m: Dictionary in t._vehiculos:
				t._cede_paso(m, i, 0.016); i += 1,
		"bucle vacio LOD": func() -> void:
			var c := 0
			for m: Dictionary in t._vehiculos:
				if m.get("oculto", false): continue
				c += int(m.get("lod", 0)),
	}
	var lod := [0, 0, 0]
	var pe := 0
	for w: Dictionary in t._vehiculos:
		lod[int(w.get("lod", 0))] += 1
		if bool(w.get("peaton", false)): pe += 1
	print("SONDA vehiculos %d peatones %d lod %s" % [n, pe, lod])
	for k: String in casos:
		var f: Callable = casos[k]
		var t0 := Time.get_ticks_usec()
		for i in 60:
			f.call()
		print("SONDA %-20s %8.1f us" % [k, float(Time.get_ticks_usec() - t0) / 60.0])
	get_tree().quit()
