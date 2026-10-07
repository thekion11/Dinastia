extends Node
## La ciudad entera desde arriba, para ver dónde queda vacía.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_ciudad_cenital.tscn
## SALIDA=nombre (sin .png) · ALTO, DIST, ANG para la cámara.
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _f(k: String, d: float) -> float:
	return float(OS.get_environment(k)) if OS.get_environment(k) != "" else d

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		var m: Mundo = _p.get("mundo")
		m.mi_club().rep = int(_f("REP", 80.0))
		## TODO=1: todas las instalaciones construidas a nivel 3.
		if OS.get_environment("TODO") == "1":
			for k: String in m.obras.niveles:
				m.obras.niveles[k] = 3
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		var t0 := Time.get_ticks_msec()
		if OS.get_environment("SIN_RECON") != "1":
			_v.call("_reconstruir")
		var cb := _v.get("_ciudad") as CityBuilder
		print("CIUDAD construida en %d ms · %d nodos · %d manzanas de distrito" % [Time.get_ticks_msec() - t0, cb.get_child_count(), cb.manzanas_distrito])
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", _f("HORA", 13.0))
		_v.call("_aplicar_hora")
		_v.set("_objetivo", Vector3(_f("OX", 0.0), 10.0, _f("OZ", 0.0)))
		_v.set("_objetivo_deseado", Vector3(_f("OX", 0.0), 10.0, _f("OZ", 0.0)))
		_v.set("_dist", _f("DIST", 120.0))
		_v.set("_alto", _f("ALTO", 900.0))
		_v.set("_ang", _f("ANG", 0.0))
		_v.call("_mover_camara")
		if OS.get_environment("METRO") == "1":
			(_v.get("_ciudad") as CityBuilder).expansion.metro.alternar_rayos_x()
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % (OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "ciudad_cenital"))
		get_tree().quit()
