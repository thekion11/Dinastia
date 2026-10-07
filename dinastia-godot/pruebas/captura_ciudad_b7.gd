extends Node
## LA CIUDAD 3D DE B7 (25-9-2026): solares, una obra con andamio y grúa, los
## rótulos, el día de partido y la ficha de un edificio abierta desde el mapa.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_ciudad_b7.tscn
## Por fotogramas: sin tarjeta gráfica cada uno tarda casi medio segundo.
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
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_b7_mapa.png")
		_v.abrir_ficha("piscina")
	if _n == 22:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_b7_ficha.png")
		_v.abrir_ficha("video")
	if _n == 32:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/ciudad_b7_solar.png")
		get_tree().quit()
