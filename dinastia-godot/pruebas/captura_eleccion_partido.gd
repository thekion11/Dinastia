extends Control
## Captura de la pantalla de antes del partido (orden 22, 3-11-2026).
##   herramientas/captura.sh res://pruebas/captura_eleccion_partido.tscn

func _ready() -> void:
	var el := EleccionPartido.new()
	el.titulo = "Lautaro FC  vs  Marga Marga FC"
	add_child(el)
	for _i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://eleccion_partido.png")
	print("CAPTURA ", ProjectSettings.globalize_path("user://eleccion_partido.png"))
	get_tree().quit()
