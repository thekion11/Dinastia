extends Control
## Captura de «¿Empezamos así?» con la foto del personaje 3D (orden 22, 3-11-2026).
##   herramientas/captura.sh res://pruebas/captura_confirmar_personaje.tscn

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["ESP"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	size = get_viewport_rect().size
	var pp := PantallaPersonaje.new()
	pp.configurar({"pais": "ESP", "club": m.mi_club(), "paso": 6, "nombre": "Gustavo"})
	pp.size = size
	add_child(pp)
	for _i in 90:
		await get_tree().process_frame
	var campos: Dictionary = pp.get("_campos")
	for k in ["nombre", "apellido"]:
		if campos.has(k):
			(campos[k] as LineEdit).text = "Gustavo" if k == "nombre" else "Navarrete"
			(campos[k] as LineEdit).text_changed.emit((campos[k] as LineEdit).text)
	pp.call("_confirmar")
	for _i in 40:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://confirmar_personaje.png")
	print("CAPTURA ", ProjectSettings.globalize_path("user://confirmar_personaje.png"))
	get_tree().quit()
