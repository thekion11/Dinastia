extends Node
## Conversación con un vecino (13-10-2026): tres turnos con el mismo vecino, una
## foto por turno. Salida: pruebas/capturas/dialogo_1..3.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_dialogo.tscn
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _n := 0
var _vec: Dictionary

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 5:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("pie")
		_e = _v.get("_explorador")
	if _n == 12:
		for v: Dictionary in _e.trafico._vehiculos:
			if float(v["alto"]) > 0.1 and float(v["alto"]) < 0.3 and is_instance_valid(v["nodo"]):
				_vec = v
				break
		var nodo: Node3D = _vec["nodo"]
		_e.cuerpo.position = nodo.global_position + Vector3(0, 0, -2.2)
		_e.set("rumbo", 0.0)
		_e.cuerpo.rotation.y = 0.0
	if _n in [20, 45, 70]:
		_vec["espera"] = 6.0
		_e.call("_hablar_con_vecino", _vec)
		(_vec["nodo"] as Node3D).position.y += 0.0
		_e.call("_colocar_camara", 1.0)
	if _n in [26, 51, 76]:
		var k := (_n - 26) / 25 + 1
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/dialogo_%d.png" % k)
		print("FOTO ", k, " ", _e.get("_burbuja").text)
	if _n > 80:
		get_tree().quit()
