extends Node
## S6 con la CÁMARA REAL: la misma calle sin lluvia y con lluvia (paraguas, gotas, suelo mojado) y la memoria del proceso antes y después.
## Salen en /tmp/lluvia_ciudad_{seco,lluvia}.png y por consola «MEMORIA».
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_lluvia_ciudad.tscn
var _n := 0
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _vida: VidaCiudad

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _rss_mb() -> float:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	while f != null and not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			return float(l.split(" ", false)[1]) / 1024.0
	return 0.0

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
		_vida = VidaCiudad.enganchar(_e, _v, _p.get("mundo"))
		_vida.paraguas.set_process(false)
		return
	if _n < 8:
		return
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	_v.set("_hora", 12.0)
	_v.call("_aplicar_hora")
	var b: CityBuilder = _e.cb
	var f := _n - 8
	if f == 0:
		var pdoor: Vector3 = b.puertas_vida[0]["p"]
		var nn: Vector3 = b.puertas_vida[0]["n"]
		var d := (nn + nn.cross(Vector3.UP) * 0.8).normalized()
		var en := pdoor + d * 16.0
		_e.cuerpo.position = Vector3(en.x, _e.altura_suelo(en.x, en.z), en.z)
		_e.set("rumbo", atan2(-d.x, -d.z))
	if f == 20:
		get_viewport().get_texture().get_image().save_png("/tmp/lluvia_ciudad_seco.png")
		print("MEMORIA antes ", _rss_mb(), " MB")
		_vida.paraguas._actualizar_lluvia("lluvia", b)
		var trafico: Object = _e.get("trafico")
		ParaguasVida.tick(trafico.get("_vehiculos"), true, b.puertas_vida, 1)
	if f == 60:
		get_viewport().get_texture().get_image().save_png("/tmp/lluvia_ciudad_lluvia.png")
		print("MEMORIA despues ", _rss_mb(), " MB, partículas ", PrecipitacionCiudad.particulas(_vida.paraguas._lluvia))
		print("FIN. 0 fallos")
		get_tree().quit()
