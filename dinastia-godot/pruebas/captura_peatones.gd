extends Node
## LOS PEATONES DE LA CIUDAD (26-9-2026), a ras de la acera del anillo.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_peatones.tscn
## Por fotogramas: sin tarjeta gráfica cada uno tarda casi medio segundo.
const RING_X_CAP := 205.0
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
		var c := m.mi_club()
		c.saldo = 900000000
		for k: String in ["ct", "acad", "med", "gim", "resid", "com"]:
			m.obras.niveles[k] = 2
		m.obras.iniciar("piscina", c)
		m.obras.iniciar("trib", c)
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.dia_partido = true
		_v.call("_reconstruir")
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
	if _n == 12:
		## Al ras de la acera del anillo, para ver a los peatones.
		var cam: Camera3D = _v.get("_camara")
		_v.set_process(false)
		cam.position = Vector3(RING_X_CAP + 20.0, 4.0, 30.0)
		cam.look_at(Vector3(RING_X_CAP + 10.0, 1.2, 0.0), Vector3.UP)
	if _n == 18:
		get_viewport().get_texture().get_image().save_png("res://pruebas/ciudad_peatones.png")
		var cam2: Camera3D = _v.get("_camara")
		cam2.position = Vector3(120.0, 70.0, 230.0)
		cam2.look_at(Vector3(230.0, 0.0, 330.0), Vector3.UP)
	if _n == 24:
		get_viewport().get_texture().get_image().save_png("res://pruebas/ciudad_calles.png")
		## Los frentes urbanos de la calle sur, a la altura de un segundo piso.
		var cam3: Camera3D = _v.get("_camara")
		cam3.position = Vector3(60.0, 9.0, 350.0)
		cam3.look_at(Vector3(140.0, 6.0, 368.0), Vector3.UP)
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/ciudad_frentes.png")
		get_tree().quit()
