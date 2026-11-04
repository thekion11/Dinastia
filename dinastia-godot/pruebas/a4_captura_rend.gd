extends Node
## A4 rendimiento (4-11-2026): capturas de la ciudad en MÍNIMA, aérea y a pie, para comparar antes/después de un cambio de
## optimización (mismas posiciones, hora y cámara cada vez). Salida: PNG en el directorio de CAP_DIR (absoluto).
##   CAP_DIR=/ruta CAP_ETQ=antes xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/a4_captura_rend.tscn
var _p: Node
var _v: VistaCiudad
var _n := 0
var _e: ExploradorCiudad

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("CAP_DIR")
	var etq := OS.get_environment("CAP_ETQ")
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [dir, etq, nombre])
	print("CAPTURA ", nombre)

func _process(_d: float) -> void:
	_n += 1
	Engine.max_fps = 0
	if _n == 5:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad: _v = h
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", 13.0)
		_v.call("_aplicar_hora")
		_v.set("_objetivo", Vector3(0, 10, 0))
		_v.set("_objetivo_deseado", Vector3(0, 10, 0))
		_v.set("_dist", 120.0)
		_v.set("_alto", 900.0)
		_v.set("_ang", 0.0)
		_v.call("_mover_camara")
	if _n == 20:
		_foto("aerea_alta")
		_v.set("_dist", 60.0)
		_v.set("_alto", 160.0)
		_v.set("_objetivo", Vector3(0, 10, 300))
		_v.set("_objetivo_deseado", Vector3(0, 10, 300))
		_v.call("_mover_camara")
	if _n == 30:
		_foto("aerea_baja")
		_v.explorar("pie")
		_e = _v.get("_explorador")
		_e.cuerpo.position = Vector3(20, 0.2, 300)
		_e.rumbo = 0.0
	if _n == 50:
		_foto("pie_a")
		_e.cuerpo.position = Vector3(-300, 0.2, 380)
		_e.rumbo = PI * 0.5
	if _n == 70:
		_foto("pie_b")
		_e.cuerpo.position = Vector3(334, 0.2, -560)
		_e.rumbo = PI
	if _n == 90:
		_foto("pie_c")
		get_tree().quit()
