extends Control
## Captura del gráfico de evolución de la ficha (M-295, 2-11-2026): seis temporadas de ejemplo.
##   herramientas/captura.sh res://pruebas/captura_grafico_evolucion.tscn

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.1, 0.12)
	fondo.size = Vector2(420, 140)
	add_child(fondo)
	var h := []
	var ovr := [64, 68, 72, 75, 74, 77]
	var val := [800, 1500, 3200, 5400, 4600, 7800]
	for i in 6:
		h.append({"anio": 2026 + i, "club": "Andino FC", "pj": 30, "goles": 5, "as": 3, "ovr": ovr[i], "val": val[i] * 1000})
	var g := GraficoEvolucion.de(h, {"suave": Color(0.6, 0.65, 0.7), "verde": Color(0.35, 0.85, 0.45), "escala": 1.0})
	g.position = Vector2(10, 10)
	g.size = Vector2(400, 110)
	add_child(g)
	for _i in 6:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() / 2, img.get_height() / 2)
	img.save_png("user://grafico_evolucion.png")
	print("CAPTURA ", ProjectSettings.globalize_path("user://grafico_evolucion.png"))
	get_tree().quit()
