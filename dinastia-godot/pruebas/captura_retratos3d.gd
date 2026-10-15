extends Control
## Los retratos 3D de varios jugadores (reales y ficticios), como salen en las listas.
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1280x720 res://pruebas/captura_retratos3d.tscn
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var f := ColorRect.new()
	f.color = Color("0f1a14")
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(f)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c: Club = m.ligas[0].clubes[0]
	var lista: Array = c.plantel().slice(0, 14)
	var fila := GridContainer.new()
	fila.columns = 7
	fila.position = Vector2(20, 40)
	fila.add_theme_constant_override("h_separation", 10)
	fila.add_theme_constant_override("v_separation", 10)
	add_child(fila)
	for j: Jugador in lista:
		var v := VBoxContainer.new()
		var r := TextureRect.new()
		r.texture = Cara.textura(j, c.color1, c.color2, 150)
		r.custom_minimum_size = Vector2(170, 170)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(r)
		var l := Label.new()
		l.text = "%s  %s" % [j.pos_e, Nombres.visible(j.nombre)]
		l.add_theme_font_size_override("font_size", 12)
		v.add_child(l)
		fila.add_child(v)
	for i in 180:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/retratos3d.png")
	get_tree().quit()
