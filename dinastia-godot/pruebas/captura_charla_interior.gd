extends Node
## Charlar con alguien que trabaja dentro de un edificio (13-10-2026): se entra
## al hospital, se acerca a la persona más cercana y se pulsa E.
## Salida: pruebas/capturas/charla_interior.png
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_charla_interior.tscn
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _n := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	AjustesCiudad.guardar("tutorial_visto", true)
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
	if _n == 10:
		_e.call("_entrar_en_edificio", OS.get_environment("SALA") if OS.get_environment("SALA") != "" else "edificio_bar|Bar El Rincón")
	if _n == 20:
		var it: Node = _e.get("_int")
		var mejor: Node3D = null
		for lista: Array in [it.get("_fijos"), it.get("_caminantes")]:
			for f: Dictionary in lista:
				var n: Node3D = (f["d"] as Dictionary).get("nodo")
				if n != null and (mejor == null or n.global_position.distance_to(_e.cuerpo.position) < mejor.global_position.distance_to(_e.cuerpo.position)):
					mejor = n
		print("persona: ", mejor != null)
		if mejor != null:
			var frente := mejor.global_transform.basis.z.normalized()
			_e.cuerpo.position = mejor.global_position + frente * 1.3
			_e.set("rumbo", atan2(-frente.x, -frente.z))
	if _n == 22:
		print("cerca: ", not (_e.get("_int_cerca") as Dictionary).is_empty())
		_e.call("_usar")
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/charla_interior.png")
		get_tree().quit()
