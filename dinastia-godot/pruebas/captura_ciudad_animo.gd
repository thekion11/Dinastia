extends Node
## LA CIUDAD RESPONDE AL CLUB (fase 5): la misma ciudad en euforia y en crisis.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_ciudad_animo.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _poner(estado: String) -> void:
	_v.animo = {"euforia": CiudadAnimo.evaluar(1, 16, 30, 30, 5, 5, 2, true),
		"crisis": CiudadAnimo.evaluar(16, 16, 30, 30, -4, 5, 2, true)}[estado]
	print("ANIMO ", _v.animo)
	_v.call("_reconstruir")
	_v.set("_girando", false)
	_v.set("_ciclo_activo", false)
	_v.set("_hora", 13.0)
	_v.call("_aplicar_hora")
	_camara(false)

## `calle`: de cerca, mirando las fachadas de la acera sur del anillo.
func _camara(calle: bool) -> void:
	var o := Vector3(470, 8, -60) if calle else Vector3(0, 16, 0)
	_v.set("_objetivo", o)
	_v.set("_objetivo_deseado", o)
	_v.set("_dist", 70.0 if calle else 430.0)
	_v.set("_alto", 18.0 if calle else 150.0)
	_v.set("_ang", -1.35 if calle else 0.5)
	_v.call("_mover_camara")

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_poner("euforia")
	if _n == 14:
		print("MONTADO ", (_v.get("_ciudad") as CityBuilder).animo_montado)
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_animo_euforia.png")
		_camara(true)
	if _n == 18:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_animo_euforia_calle.png")
		_poner("crisis")
	if _n == 26:
		print("MONTADO ", (_v.get("_ciudad") as CityBuilder).animo_montado)
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_animo_crisis.png")
		_camara(true)
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_animo_crisis_calle.png")
		get_tree().quit()
