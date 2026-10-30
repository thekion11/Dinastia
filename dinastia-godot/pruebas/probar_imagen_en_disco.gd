extends Node
## Las texturas guardadas en disco (`ImagenEnDisco`: el asfalto) son idénticas, mipmaps incluidos,
## a las recién pintadas (30-10-2026).

func _ready() -> void:
	var fallos := 0
	for c: Color in [Color(0.42, 0.425, 0.435), Color(0.40, 0.405, 0.415)]:
		var clave := "asfalto_prueba|%s|%d" % [var_to_bytes(c).hex_encode(), Time.get_ticks_usec()]
		var nueva: ImageTexture = Texturas._imagen_asfalto(c, 23)
		var primera := ImagenEnDisco.textura(clave, "res://visor/texturas_p1.gd", Texturas._imagen_asfalto.bind(c, 23))
		CacheDisco.esperar_guardados()
		var leida := ImagenEnDisco.textura(clave, "res://visor/texturas_p1.gd", func() -> ImageTexture: return null)
		for t: ImageTexture in [primera, leida]:
			if t == null or t.get_image().get_data() != nueva.get_image().get_data():
				fallos += 1
				print("FALLO asfalto ", c)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
