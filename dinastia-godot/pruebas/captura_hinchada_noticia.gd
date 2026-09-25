extends Node
## Verifica que las noticias de `Hinchada` (campana de abonos, encuestas,
## "la barra se planta") ya llegan al registro -13-9-2026, hallazgo de la
## auditoria de conectores: estaban escritas, disparandose de verdad, y
## nadie las escuchaba en `principal.gd`-.
##
##   godot --path . res://pruebas/captura_hinchada_noticia.tscn

func _ready() -> void:
	var pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(pantalla)
	await get_tree().process_frame
	await get_tree().process_frame
	var mundo = pantalla.get("mundo")
	var antes: int = (pantalla.get("_bandeja") as Array).size()
	mundo.hinchada.noticia.emit("Prueba de hinchada", "Si esto aparece en la bandeja, ya esta conectado.")
	await get_tree().process_frame
	var bandeja: Array = pantalla.get("_bandeja")
	var despues: int = bandeja.size()
	print("filas en la bandeja antes=%d despues=%d (debe subir en 1)" % [antes, despues])
	if despues > antes:
		print("primera fila: %s" % [bandeja[0]])
	print("FIN. %d fallo(s)" % (0 if despues > antes else 1))
	get_tree().quit()
