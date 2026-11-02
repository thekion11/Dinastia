extends Node
## Señales de límite de velocidad en un cruce (vistas por quien llega por la avenida). → /tmp/senal_<n>.png
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
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
		_v.explorar("pie")
		_e = _v.get("_explorador")
		return
	if _n < 8:
		return
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	_v.set("_hora", 12.0)
	_v.call("_aplicar_hora")
	var f := _n - 8
	var c: Vector3 = _e.cb.expansion.cruces_semaforo[0]
	var ancho := CiudadExpansion.ANCHO_AV * 0.5 + 1.2
	if f == 0:
		print("senales ", _e.cb.expansion.cuenta.get("senales_velocidad", 0))
		var en := c + Vector3(ancho + 4.5 + 9.0, 0, ancho - 4.0)
		_e.cuerpo.position = Vector3(en.x, _e.altura_suelo(en.x, en.z), en.z)
		_e.set("rumbo", PI * 0.5)
	if f == 30:
		get_viewport().get_texture().get_image().save_png("/tmp/senal_0.png")
	if f == 31:
		var en2 := c + Vector3(-ancho + 4.0, 0, ancho + 4.5 + 9.0)
		_e.cuerpo.position = Vector3(en2.x, _e.altura_suelo(en2.x, en2.z), en2.z)
		_e.set("rumbo", PI)
	if f == 60:
		get_viewport().get_texture().get_image().save_png("/tmp/senal_1.png")
		print("FIN. 0 fallos")
		get_tree().quit()
