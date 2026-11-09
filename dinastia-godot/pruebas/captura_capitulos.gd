extends Node
## Foto del diálogo «Capítulos de cada temporada» con 12 años guardados (9-11, estética). Fuera del repo: OUT (por defecto /tmp/fotos_capitulos).
func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_capitulos"
	DirAccess.make_dir_recursive_absolute(dir)
	var m := Mundo.new()
	m.generar(["CHI"], 20261109)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for k in 12:
		m.prensa.capitulos.append({"anio": 2026 + k})
	PedidoPartida.mundo_pregenerado = m
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await get_tree().create_timer(3.0).timeout
	CapasTutorial.poner_activas(false)
	CapitulosSelector.abrir(p)
	await get_tree().create_timer(1.0).timeout
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg(dir + "/capitulos.jpg", 0.9)
	print("foto lista")
	get_tree().quit()
