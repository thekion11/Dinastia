extends Control
## El mando 3D solo, a gran tamaño y desde varios ángulos, para revisar el modelo.
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_mando_grande.tscn
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var f := ColorRect.new()
	f.color = Color("0f1a14")
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(f)
	var m := MandoGiratorio.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.dispositivo = OS.get_environment("DISP") if OS.get_environment("DISP") != "" else "xbox"
	add_child(m)
	var vistas := [[0.0, 1.28], [0.0, 0.55], [0.6, 0.7], [PI, 0.3], [0.0, 0.0], [0.0, -0.8]]
	for i in vistas.size():
		m.mirar(float(vistas[i][0]), float(vistas[i][1]))
		for k in 40:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/mando_grande_%d.png" % i)
	get_tree().quit()
