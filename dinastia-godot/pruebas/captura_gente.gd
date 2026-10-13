extends Node
## Gente alrededor (13-10-2026): cuántos peatones hay a menos de 80 m al llegar
## y tras unos segundos de reciclaje. Foto: pruebas/capturas/gente.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_gente.tscn
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _n := 0
var _t := 0.0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _cerca() -> int:
	var k := 0
	for v: Dictionary in _e.trafico._vehiculos:
		var a := float(v["alto"])
		if a > 0.05 and a < 0.3 and is_instance_valid(v["nodo"]):
			if (v["nodo"] as Node3D).position.distance_to(_e.cuerpo.position) < 80.0:
				k += 1
	return k

func _process(d: float) -> void:
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
		_e.cuerpo.position = Vector3(120.0, 0, 1150.0)
		_e.set("rumbo", -PI * 0.5)
	if _n == 8:
		print("GENTE al llegar: ", _cerca())
	if _n > 8:
		_t += d
		## Se simula más deprisa: varias rondas de reciclaje por fotograma.
		_e.trafico.reciclar_peatones(_e.cuerpo.position, -_e.camara.global_transform.basis.z)
	if _n == 40:
		print("GENTE tras reciclar: ", _cerca())
		## Media vuelta: la gente que apareció a la espalda queda a la vista.
		_e.set("rumbo", PI * 0.5)
		_e.cuerpo.rotation.y = PI * 0.5
		_e.call("_colocar_camara", 1.0)
	if _n == 44:
		## Al peatón más cercano y por delante, para ver ropa y caras de cerca.
		var mejor: Node3D = null
		for v: Dictionary in _e.trafico._vehiculos:
			var a := float(v["alto"])
			if a > 0.05 and a < 0.3 and is_instance_valid(v["nodo"]):
				var n: Node3D = v["nodo"]
				if mejor == null or n.position.distance_to(_e.cuerpo.position) < mejor.position.distance_to(_e.cuerpo.position):
					mejor = n
		if mejor != null:
			var dir := (mejor.position - _e.cuerpo.position)
			dir.y = 0
			_e.cuerpo.position = mejor.position - dir.normalized() * 4.0
			_e.set("rumbo", atan2(dir.x, dir.z))
			_e.cuerpo.rotation.y = atan2(dir.x, dir.z)
			_e.call("_colocar_camara", 1.0)
	if _n == 46:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/gente.png")
		get_tree().quit()
