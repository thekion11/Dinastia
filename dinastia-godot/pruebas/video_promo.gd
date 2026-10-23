extends "res://pruebas/video_promo_p1.gd"
## (Parte 2 de 2 de `video_promo.gd`.)

func _montar_cierre() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 110
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.color = Color("#07120c")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	capa.add_child(caja)
	for fila: Array in [["DINASTÍA", 92, Color.WHITE], ["Construye un club. Escribe su historia.", 28, Color("#c9f24b")],
			["", 18, Color.WHITE], ["24 ligas · 384 clubes · 7 modos de juego · 9 idiomas", 22, Color(1, 1, 1, 0.8)],
			["Dueño · Director técnico · Presidente · Crear tu club · Retos · Fondo de inversión · Carrera de jugador", 17, Color(1, 1, 1, 0.6)]]:
		var l := Label.new()
		l.text = String(fila[0])
		l.add_theme_font_size_override("font_size", int(fila[1]))
		l.add_theme_color_override("font_color", fila[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(l)
	_x["caja"] = caja

func _paso_cierre(t: float) -> void:
	(_x["caja"] as Control).modulate.a = clampf(t / 1.2, 0.0, 1.0)
	_rotulo.visible = false
