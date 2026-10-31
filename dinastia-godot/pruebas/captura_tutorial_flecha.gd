extends Node
## LA FLECHA DE LA MISIÓN del tutorial (semana 7, 27-10-2026): abre la pantalla principal, el tutorial del
## entrenador y salta al primer paso con misión y control resaltado. Sale en /tmp/tutorial_flecha.png.
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_tutorial_flecha.tscn

var _p: Node
var _n := 0
var _t: Tutorial

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		_p.call("abrir_tutorial", "dt")
	if _n == 40:
		for h in get_tree().root.find_children("*", "", true, false):
			if h is Tutorial:
				_t = h
		if _t == null:
			print("SIN TUTORIAL")
			get_tree().quit()
			return
		_t.pulsar_prologo()
		_t.pulsar_prologo()
		var pasos: Array = _t.guion_actual()["pasos"]
		for i in pasos.size():
			if (pasos[i] as Dictionary).has("mision") and (pasos[i] as Dictionary).has("objetivo"):
				_t.call("_mostrar", i)
				break
	if _n == 90:
		_t.call("_completar_escritura")
	if _n == 120:
		get_viewport().get_texture().get_image().save_png("/tmp/tutorial_flecha.png")
		print("FOTO flecha")
		get_tree().quit()
