extends Control
## Capturas de la pantalla de controles: una parte del manual (con una fila
## elegida en el mando dibujado), la misma en PlayStation, las filigranas, el
## teclado, asignar botones (esperando una tecla) y el diálogo de guardar.
##   xvfb-run -a godot --path . --resolution 1280x720 res://pruebas/captura_controles.tscn
func _esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _foto(nombre: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)

func _fila(panel: PanelControles, i: int) -> void:
	var k := 0
	for h in panel._contenido.get_children():
		if h.has_meta("fila"):
			if k == i:
				(h as Control).grab_focus()
				return
			k += 1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelControles.abrir(self)
	panel.dispositivo = "xbox"
	panel._pestana = "p1"
	panel._pintar()
	await _esperar(30)
	_fila(panel, 3)
	await _esperar(20)
	_foto("controles")
	panel.dispositivo = "ps"
	panel._pintar()
	await _esperar(20)
	_fila(panel, 1)
	await _esperar(20)
	_foto("controles_ps")
	panel._pestana = "filigranas"
	panel._pintar()
	await _esperar(20)
	_fila(panel, 6)
	await _esperar(20)
	_foto("controles_filigranas")
	panel.dispositivo = "teclado"
	panel._pestana = "p0"
	panel._pintar()
	await _esperar(20)
	_fila(panel, 1)
	await _esperar(20)
	_foto("controles_teclado")
	panel.dispositivo = "xbox"
	panel._pestana = "asignar"
	panel._escuchando = "jugar_tiro"
	panel._pintar()
	await _esperar(20)
	_foto("controles_asignar")
	panel._escuchando = ""
	panel._cambios = true
	panel._pedir_guardar()
	await _esperar(25)
	_foto("controles_guardar")
	get_tree().quit()
