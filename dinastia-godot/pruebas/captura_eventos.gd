extends Node
## Fotos de los eventos a pantalla completa del partido de despedida: el aviso (pregunta) y el homenaje (9-11, estética). OUT = carpeta (por defecto /tmp/fotos_eventos).
var _p: Node
func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame
func _foto(nombre: String, dir: String) -> void:
	get_viewport().get_texture().get_image().save_jpg("%s/%s.jpg" % [dir, nombre], 0.9)
	print("foto ", nombre)
func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_eventos"
	DirAccess.make_dir_recursive_absolute(dir)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	JornadaDespedida.ofrecer(_p)
	await _esperar(1.5)
	await _foto("aviso", dir)
	for h in _p.get_children():
		if h is CanvasLayer and h.has_signal("elegido"):
			h.emit_signal("elegido", "simular")
	await _esperar(2.0)
	await _foto("homenaje", dir)
	get_tree().quit()
