extends Control
## Captura de la pantalla de controles: botones (esperando una tecla),
## combinaciones y filigranas.
##   xvfb-run -a godot --path . --resolution 1280x720 res://pruebas/captura_controles.tscn
func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color("0d1a12")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelControles.abrir(self)
	panel._escuchando = "jugar_tiro"
	panel._pintar()
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/controles.png")
	panel._escuchando = ""
	for par: Array in [["combinaciones", "controles_combinaciones"], ["filigranas", "controles_filigranas"]]:
		panel._pestana = par[0]
		panel._pintar()
		for i in 12:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % par[1])
	get_tree().quit()
