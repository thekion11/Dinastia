extends Node
## Duda del usuario: "que es eso en la porteria?" -vio un bloque oscuro en una
## captura de prueba de los camarografos, tomada con una camara de diagnostico
## que nadie usa en el juego real. Esto comprueba como se ve el mismo tunel de
## vestuarios desde las camaras DE VERDAD que usa un partido (camera_rig.gd),
## para saber si es solo el angulo de la prueba o un problema real.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_tunel_real.tscn

var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4713)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), 0.85, null, null, _mundo.perfil_estadio_de(_mundo.mi_club()))

func _process(_d: float) -> void:
	_n += 1
	if _n == 20:
		## Cámara principal (TV), la que usa la mayoría de las partidas.
		var img0 := get_viewport().get_texture().get_image()
		img0.save_png("res://pruebas/capturas/tunel_camara_principal.png")
		var rig: CameraRig = _vista.get("_rig")
		for i in rig.camera_names.size():
			if String(rig.camera_names[i]).begins_with("Detr"):
				rig.switch_to(i)
				break
	if _n == 30:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/tunel_camara_real.png")
		print("capturas guardadas")
		get_tree().quit()
