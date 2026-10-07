extends Node
## LAS INSTALACIONES CON CARA PROPIA Y SU PERSONAL (26-9-2026).
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_instalaciones.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		var m: Mundo = _p.get("mundo")
		for k: String in ["ct", "acad", "med", "gim", "resid", "rehab", "piscina", "cocina", "video", "pren", "museo", "com", "guarderia", "bienestar", "esports"]:
			m.obras.niveles[k] = 5
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.call("_reconstruir")
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.set_process(false)
	if _n == 12:
		var cam: Camera3D = _v.get("_camara")
		cam.position = Vector3(-70.0, 38.0, 195.0)
		cam.look_at(Vector3(-40.0, 4.0, 130.0), Vector3.UP)
	if _n == 18:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/instalaciones_a.png")
		var cam2: Camera3D = _v.get("_camara")
		cam2.position = Vector3(60.0, 30.0, 200.0)
		cam2.look_at(Vector3(80.0, 3.0, 150.0), Vector3.UP)
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/instalaciones_b.png")
		var cam3: Camera3D = _v.get("_camara")
		cam3.position = Vector3(40.0, 2.6, 133.0)
		cam3.look_at(Vector3(35.0, 1.5, 122.0), Vector3.UP)
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/instalaciones_personal.png")
		get_tree().quit()
