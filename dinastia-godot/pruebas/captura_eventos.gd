extends Node
## Foto del aviso del partido de despedida (9-11, estética). OUT = carpeta (por defecto /tmp/fotos_eventos). AÑO=n para ver otra de las 5 variantes de escudo.
func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame
func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_eventos"
	DirAccess.make_dir_recursive_absolute(dir)
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	if OS.get_environment("ANIO") != "":
		p.mundo.anio = int(OS.get_environment("ANIO"))
	JornadaDespedida.ofrecer(p)
	await _esperar(5.0)
	get_viewport().get_texture().get_image().save_jpg(dir + "/aviso.jpg", 0.9)
	print("foto lista")
	get_tree().quit()
