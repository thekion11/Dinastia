extends Control
## Captura del bloque «Tu club frente a…» (M-294, 2-11-2026).
##   herramientas/captura.sh res://pruebas/captura_compara_clubes.tscn

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.1, 0.12)
	fondo.size = Vector2(440, 230)
	add_child(fondo)
	var m := Mundo.new()
	m.generar(["CHI"], 2940)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var caja := VBoxContainer.new()
	caja.position = Vector2(10, 10)
	caja.size = Vector2(420, 210)
	add_child(caja)
	ComparaClubes.pintar(caja, m.mi_club(), m.ligas[0].clubes[1], Color(0.6, 0.65, 0.7), Color(0.9, 0.92, 0.95), Color(0.35, 0.85, 0.45), Color(0.9, 0.35, 0.3))
	for _i in 6:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://compara_clubes.png")
	print("CAPTURA ", ProjectSettings.globalize_path("user://compara_clubes.png"))
	get_tree().quit()
