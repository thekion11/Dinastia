extends Node
## El modo foto en la ciudad: filtro cine con marco, blanco y negro, y una foto guardada.
var _n := 0
var _p: Node
var _v: VistaCiudad
var _f: ModoFoto

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
		_v.set("_hora", 17.5)
		_v.call("_aplicar_hora")
		_v.set("_objetivo", Vector3(0, 10, -160))
		_v.set("_objetivo_deseado", Vector3(0, 10, -160))
		_v.set("_dist", 230.0)
		_v.set("_alto", 70.0)
		_v.call("_mover_camara")
		_f = ModoFoto.abrir(_v, _v.club, "la ciudad")
		_f.call("_cambiar", 4)
		(_f.get("_marco") as Control).visible = true
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/modo_foto_cine.png")
		(_f.get("_marco") as Control).visible = false
		_f.call("_cambiar", -2)
	if _n == 16:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/modo_foto_byn.png")
		_f.call("_disparar")
	if _n == 24:
		print("FOTOS GUARDADAS: ", ModoFoto.fotos().size())
		get_tree().quit()
