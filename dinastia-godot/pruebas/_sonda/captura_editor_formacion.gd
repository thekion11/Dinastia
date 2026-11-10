extends Control
## Captura del editor de formaciones propias (10-11) con dos clubes de países distintos. Salida: CAPTURA_DIR (JPG).
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 900x700 res://pruebas/_sonda/captura_editor_formacion.tscn
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["ESP", "BRA"], 4711)
	var dir := OS.get_environment("CAPTURA_DIR") if OS.get_environment("CAPTURA_DIR") != "" else "user://"
	var clubes: Array = [m.ligas[0].clubes[1], m.ligas[m.ligas.size() - 1].clubes[3]]
	for k in clubes.size():
		var c: Club = clubes[k]
		for h in get_children():
			h.queue_free()
		await get_tree().process_frame
		var fondo := ColorRect.new()
		fondo.color = Color("14281b")
		fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(fondo)
		var caja := VBoxContainer.new()
		caja.position = Vector2(20, 20)
		caja.custom_minimum_size = Vector2(560, 0)
		add_child(caja)
		var tit := Label.new()
		tit.text = "%s (%s) · %s" % [c.nombre, c.pais, c.tactica.formacion]
		caja.add_child(tit)
		var ed := EditorFormacion.crear(c)
		caja.add_child(ed)
		await get_tree().process_frame
		await get_tree().process_frame
		## Mueve una ficha de medio hacia arriba y un lateral al medio para que se vea el cambio de puesto.
		for i in (ed.forma["s"] as Array).size():
			if String(ed.forma["s"][i][0]) in ["MC", "MCD"]:
				ed.sel = i
				ed._mover(30, 34)
				break
		ed._lienzo.queue_redraw()
		for i in 4:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_jpg(dir.path_join("editor_formacion_%d.jpg" % k), 0.85)
		print("CAPTURA ", c.nombre, " ", ed.forma["DEF"], "-", ed.forma["MED"], "-", ed.forma["DEL"], " ", ed.forma["s"])
	get_tree().quit()
