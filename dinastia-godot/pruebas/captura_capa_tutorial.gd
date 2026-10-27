extends Node
## La tarjeta del tutorial por capas (fila 1040) la primera vez que se abre Entrenar. Deja `user://ajustes.cfg` como estaba.
##   herramientas/captura.sh res://pruebas/captura_capa_tutorial.tscn   (CAPAS=0 → sin tarjeta, «antes»; CAPTURA_SALIDA cambia la carpeta)
var _p: Node
var _n := 0
var _copia := ""

func _ready() -> void:
	_copia = FileAccess.get_file_as_string(CapasTutorial.ARCHIVO) if FileAccess.file_exists(CapasTutorial.ARCHIVO) else ""
	CapasTutorial.forzar = OS.get_environment("CAPAS") != "0"
	CapasTutorial.reiniciar()
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_p.call("_ir_a_pestana", "Entrenar")
		_p.call("_refrescar")
	if _n == 22:
		var carpeta := OS.get_environment("CAPTURA_SALIDA") if OS.get_environment("CAPTURA_SALIDA") != "" else "/tmp"
		get_viewport().get_texture().get_image().save_png("%s/capa_tutorial%s.png" % [carpeta, "_antes" if OS.get_environment("CAPAS") == "0" else ""])
		if _copia == "":
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CapasTutorial.ARCHIVO))
		else:
			FileAccess.open(CapasTutorial.ARCHIVO, FileAccess.WRITE).store_string(_copia)
		get_tree().quit()
