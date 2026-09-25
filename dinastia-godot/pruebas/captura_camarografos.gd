extends Node
## Prueba de los camarógrafos nuevos (13-9-2026): construye el estadio a
## secas (sin partido, sin interfaz) y pone la cámara justo donde va uno de
## ellos -detrás del arco- para comprobar que la figura existe, tiene los
## materiales correctos y mira hacia la cancha.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_camarografos.tscn

var _n := 0

func _ready() -> void:
	var raiz3d := Node3D.new()
	add_child(raiz3d)
	var we := Calidad.entorno(Calidad.ALTO, Calidad.TARDE)
	raiz3d.add_child(we)
	raiz3d.add_child(Calidad.sol(Calidad.ALTO, Calidad.TARDE))
	StadiumBuilder.build(raiz3d, {}, 30000, 0.7, 12345)
	StadiumBuilder.build_pitch(raiz3d, {})

	var cam := Camera3D.new()
	cam.fov = 45.0
	## Pegada al camarógrafo de detrás del arco norte (21, 0, 54.5), mirando
	## de frente -sin depender de adivinar el encuadre general del estadio-.
	cam.position = Vector3(21.0, 3.5, 62.0)
	cam.look_at(Vector3(21.0, 1.0, 54.5), Vector3.UP)
	raiz3d.add_child(cam)
	cam.current = true

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/camarografos.png")
		print("captura guardada")
		get_tree().quit()
