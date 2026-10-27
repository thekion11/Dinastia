extends Node
## El visor de la copa con su ficha. xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_visor_trofeo.tscn → /tmp/visor_trofeo.png
var _n := 0

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.1, 0.13, 0.12)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var capa := CanvasLayer.new()
	add_child(capa)
	VisorTrofeo.abrir(capa, {"vacia": false, "titulo": "Liga", "anio": 2031, "final": "Campeón de liga con Lautaro FC", "goleadores": ["J. Pérez (18)", "M. Soto (11)", "R. Díaz (7)"]})

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("/tmp/visor_trofeo.png")
		if OS.get_environment("GIROS") != "1":
			get_tree().quit()
	if OS.get_environment("GIROS") == "1" and _n in [60, 80, 100, 120]:
		get_viewport().get_texture().get_image().save_png("/tmp/visor_trofeo_%d.png" % _n)
		if _n == 120:
			get_tree().quit()
