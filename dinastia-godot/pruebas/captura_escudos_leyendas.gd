extends Node
## Foto de los 5 escudos de las Leyendas (9-11, estética): uno por temporada (año % 5). OUT = carpeta (por defecto /tmp/fotos_eventos).
func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_eventos"
	DirAccess.make_dir_recursive_absolute(dir)
	var fondo := ColorRect.new()
	fondo.color = Color("0c1510")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(fila)
	for k in 5:
		var anio := 2025 + k
		var c := Club.new("leyendas_%d" % anio, "Leyendas %d" % anio)
		var esc := PartidoDespedida.escudo_del_anio(anio)
		c.esc_forma = String(esc["forma"]); c.esc_patron = String(esc["patron"])
		c.esc_color1 = String(esc["c1"]); c.esc_color2 = String(esc["c2"])
		var tr := TextureRect.new()
		tr.texture = Escudo.textura(c, 240)
		tr.custom_minimum_size = Vector2(240, 240)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(tr)
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_jpg(dir + "/escudos.jpg", 0.9)
	print("foto lista")
	get_tree().quit()
