extends Node
## Captura de la plantilla a la PES (comparando dos jugadores): xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_plantilla_pes.tscn
var _n := 0
var _p: Node
var _v: PlantillaPes
var _hecho := false

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		_v = PlantillaPes.abrir(_p)
		var campo: Array = _p.mundo.mi_club().plantilla.filter(func(j: Jugador) -> bool: return j.pos != "POR")
		_v._comparando = true
		_v._a = campo[0]
		_v._b = campo[3]
		_v._pintar()
	if _n == 40 and not _hecho:
		_hecho = true
		await get_tree().create_timer(2.5).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_jpg("/tmp/plantilla_pes.jpg", 0.85)
		print("CAPTURA OK")
		get_tree().quit()
