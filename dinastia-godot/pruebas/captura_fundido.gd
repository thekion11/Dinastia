extends Node
## CAPTURAS ANTES/DESPUÉS de la fusión de mallas sueltas (6-11-2026): vista aérea (sin giro) y tres tomas a pie en la ciudad, mismas posiciones.
##   NIVEL=minimo OUT=/ruta herramientas/captura.sh res://pruebas/captura_fundido.tscn   → fundido_aerea.png, fundido_pie1..3.png
var _p: Node
var _v: VistaCiudad
var _n := 0
const PIES := [Vector3(20, 0.2, 300), Vector3(-150, 0.2, 120), Vector3(200, 0.2, -80)]

func _ready() -> void:
	Calidad.elegida = Calidad.MINIMO if OS.get_environment("NIVEL") != "medio" else Calidad.MEDIO
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	var out := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp"
	get_viewport().get_texture().get_image().save_png("%s/fundido_%s.png" % [out, nombre])
	print("FOTO ", nombre)

func _process(_d: float) -> void:
	Engine.max_fps = 0
	_n += 1
	if _n == 5:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
	if _n == 40:
		_v.set("_girando", false)
	if _n == 80:
		_foto("aerea")
		_v.explorar("pie")
	for i in PIES.size():
		if _n == 100 + 40 * i:
			(_v.get("_explorador") as ExploradorCiudad).cuerpo.position = PIES[i]
		if _n == 130 + 40 * i:
			_foto("pie%d" % (i + 1))
	if _n > 130 + 40 * PIES.size():
		get_tree().quit()
