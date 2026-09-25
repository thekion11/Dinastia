extends Node
## Aisla `StadiumBuilder._pantalla_textura()` de toda la escena 3D para ver
## si el escudo realmente se dibuja -la captura en el estadio real no lo
## mostraba ni de cerca, hay que descartar si es un problema de la textura
## misma o de como se ve en el mundo 3D.
##
##   godot --path . --headless res://pruebas/diagnostico_pantalla_textura.tscn

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	var mio := mundo.ligas[0].clubes[0]
	print("club: %s  esc_especial='%s'" % [mio.nombre, mio.esc_especial])
	var esc_tex := Escudo.textura(mio, 128)
	print("Escudo.textura() -> %s" % [esc_tex])
	if esc_tex != null:
		var img := esc_tex.get_image()
		print("  get_image() -> %s  formato=%s  tam=%s" % [img, img.get_format() if img else "?", img.get_size() if img else "?"])
		if img != null:
			img.save_png("res://pruebas/diag_escudo_solo.png")
	var tex := StadiumBuilder._pantalla_textura({"asiento1": mio.color1, "asiento2": mio.color2}, mio)
	print("_pantalla_textura() -> %s" % [tex])
	if tex != null:
		var img2 := tex.get_image()
		if img2 != null:
			img2.save_png("res://pruebas/diag_pantalla_textura.png")
			print("guardado diag_pantalla_textura.png")
	print("FIN. 0 fallos")
	get_tree().quit()
