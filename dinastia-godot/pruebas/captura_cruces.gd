extends Node
## LOS CRUCES DE LA CIUDAD DESDE ARRIBA (26-9-2026): "hay calles que no
## cierran". Tres vistas cenitales: esquina del anillo, ramal en T y un fondo
## de saco.
var _n := 0
var _p: Node
var _v: VistaCiudad
const VISTAS := [
	[Vector3(205, 0, 350), "cruce_esquina"],
	[Vector3(205, 0, 140), "cruce_ramal"],
	[Vector3(0, 0, 262), "cruce_avenida"],
	[Vector3(-60, 0, 350), "cruce_barrio"],
	[Vector3(-60, 0, 470), "finca_barrio"],
]

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.set_process(false)
	if _n >= 10 and (_n - 10) % 5 == 0:
		var k: int = (_n - 10) / 5
		if k > 0:
			get_viewport().get_texture().get_image().save_png("res://pruebas/%s.png" % VISTAS[k - 1][1])
		if k >= VISTAS.size():
			get_tree().quit()
			return
		var cam: Camera3D = _v.get("_camara")
		var c: Vector3 = VISTAS[k][0]
		cam.position = c + (Vector3(0, 70, 18) if k < 4 else Vector3(40, 45, -110))
		cam.look_at(c, Vector3.UP)
