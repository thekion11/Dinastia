extends Node
## Peaje de la autopista con la cámara del coche (M-197): xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_peaje.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.explorar("coche")
		var e: ExploradorCiudad = _v.get("_explorador")
		e.cuerpo.position = Vector3(0, 0.2, -1318)
		e.rumbo = PI
		e.vel = 0.0
	if _n == 20:
		_foto("peaje")
		get_tree().quit()
