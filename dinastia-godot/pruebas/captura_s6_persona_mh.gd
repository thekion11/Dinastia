extends Control
## SESIÓN 6 (26-10-2026): la persona realista de MakeHuman (CC0) en los retratos
## del tutorial y del sorteo -cuerpo entero, plano medio y cara- con tres aspectos.
## Solo sale si `assets/personas/persona_mh_*.glb` están (ver PersonaMH).
##   herramientas/captura.sh res://pruebas/captura_s6_persona_mh.tscn
var _n := 0

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.06)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var fila := HBoxContainer.new()
	fila.position = Vector2(20, 20)
	fila.add_theme_constant_override("separation", 14)
	add_child(fila)
	print("PersonaMH disponible: ", PersonaMH.disponible())
	var aspectos := [PersonaRealista.aspecto("presentador_sorteo", {"ropa": "marino", "pelo": "castaño", "piel": "media"}),
		PersonaRealista.aspecto("mentor_a", {"ropa": "burdeos", "pelo": "canoso", "piel": "clara"}),
		PersonaRealista.aspecto("mentor_b", {"ropa": "gris", "pelo": "negro", "piel": "oscura"})]
	for a: Dictionary in aspectos:
		fila.add_child(PersonaRealista.retrato(a, Vector2i(300, 640), Color(0.08, 0.1, 0.1), "entero"))
	var col := VBoxContainer.new()
	fila.add_child(col)
	col.add_child(PersonaRealista.retrato(aspectos[0], Vector2i(300, 320), Color(0.08, 0.1, 0.1), "medio"))
	col.add_child(PersonaRealista.retrato(aspectos[1], Vector2i(300, 300), Color(0.08, 0.1, 0.1), "cara"))

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/s6_persona_mh.png")
		get_tree().quit()
