extends Node
## EL PANEL DE OBJETIVOS EN 1280x720 (MEGAPLAN fase 1): sin preferencia
## guardada arranca plegado y no tapa la ficha.
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_objetivos_720.tscn
var _n := 0
var _p: Node
func _ready() -> void:
	PanelObjetivos.ruta = "user://objetivos_720_%d.cfg" % Time.get_ticks_usec()
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_p.call("_refrescar")
	if _n == 30:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/objetivos_720.png")
		var po: Variant = _p.get("_panel_obj")
		print("PLEGADO=", po.get("_plegado") if po != null else "sin panel")
		get_tree().quit()
