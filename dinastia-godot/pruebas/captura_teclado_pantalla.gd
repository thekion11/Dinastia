extends Control
## Captura del teclado en pantalla (M-441, 2-11-2026).
##   herramientas/captura.sh res://pruebas/captura_teclado_pantalla.tscn

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.1, 0.14, 0.12)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var campo := LineEdit.new()
	campo.position = Vector2(200, 80)
	campo.size = Vector2(400, 40)
	add_child(campo)
	var t := TecladoPantalla.new()
	t.objetivo = campo
	add_child(t)
	t._escribir("d")
	t._escribir("t")
	for _i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://teclado_pantalla.png")
	print("CAPTURA ", ProjectSettings.globalize_path("user://teclado_pantalla.png"))
	get_tree().quit()
