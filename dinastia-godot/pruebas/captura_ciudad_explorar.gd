extends Node
## Recorrer la ciudad: al volante, a pie y los minijuegos de la ciudad.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_ciudad_explorar.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _j: Control

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
		e.cuerpo.position = Vector3(334, 0.2, -560)
		e.rumbo = PI
		e.vel = 15.0
	if _n == 16:
		_foto("explorar_coche")
		_v.call("_dejar_de_explorar")
		_v.explorar("pie")
		var e2: ExploradorCiudad = _v.get("_explorador")
		e2.cuerpo.position = Vector3(-30, 0.2, -470)
		e2.rumbo = PI
	if _n == 26:
		_foto("explorar_pie")
		_v.call("_dejar_de_explorar")
		_j = MinijuegosCiudad.abrir(_v, "autografos", _v.club)
	if _n == 60:
		_foto("ciudad_juego_autografos")
		_j.queue_free()
		_j = MinijuegosCiudad.abrir(_v, "karting", _v.club)
	if _n == 66:
		_foto("ciudad_juego_karting")
		_j.queue_free()
		_j = MinijuegosCiudad.abrir(_v, "pesca", _v.club)
	if _n == 72:
		_foto("ciudad_juego_pesca")
		get_tree().quit()
