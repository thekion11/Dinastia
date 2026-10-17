extends Node
## Conducción: tercera persona, capó e interior (14-10-2026), con el coche en marcha.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_conduccion.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad

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
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 11.0)
		_v.call("_aplicar_hora")
		_v.explorar("coche")
		_e = _v.get("_explorador")
		## NUCLEO=1: dentro del núcleo del club (para ver sus calles en el GPS).
		var en := Vector3(CityBuilder.RING_X, 0, 60.0) if OS.get_environment("NUCLEO") != "" else Vector3(1005.0, 0, -500.0)
		_e.cuerpo.position = en
		_e.cuerpo.position.y = _e.altura_suelo(en.x, en.z)
		_e.set("rumbo", PI)
	if _n >= 8:
		var fase := (_n - 8) / 12
		if fase < 3:
			_e.cam_coche = fase
			_e.set("vel", 14.0)
			_e.set("_volante", -0.4)
			_e.set("_balanceo", 0.04)
			_e.call("_colocar_camara", 1.0)
			if (_n - 8) % 12 == 10:
				var nom := ("res://pruebas/capturas/conduccion_nucleo_%d.png" if OS.get_environment("NUCLEO") != "" else "res://pruebas/capturas/conduccion_%d.png") % fase
				get_viewport().get_texture().get_image().save_png(nom)
				print("FOTO ", nom)
		else:
			print("FIN. 0 fallos")
			get_tree().quit()
