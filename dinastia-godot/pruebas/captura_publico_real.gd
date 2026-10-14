extends Node
## Captura del público de personas reales (14-10-2026): una toma cercana a las
## primeras filas y una de transmisión.
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_publico_real.tscn
var _vista: VistaEstadio
var _frame := 0
var _cam: Camera3D

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mundo.mi_club(), 0.95)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.fov = 50.0
	_cam.current = true
	_poner(0)

func _poner(n: int) -> void:
	if n == 0:
		_cam.position = Vector3(-4.0, 2.0, 44.0)
		_cam.look_at(Vector3(4.0, 2.8, 56.0), Vector3.UP)
		_cam.fov = 22.0
	else:
		_cam.position = Vector3(-60.0, 24.0, 0.0)
		_cam.look_at(Vector3(20.0, 4.0, 55.0), Vector3.UP)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 40 or _frame == 80:
		var img := get_viewport().get_texture().get_image()
		var nom := "res://pruebas/capturas/publico_real_%d.png" % (0 if _frame == 40 else 1)
		img.save_png(nom)
		print("captura: ", nom)
		if _frame == 40:
			_poner(1)
		else:
			print("FIN. 0 fallos")
			get_tree().quit()
