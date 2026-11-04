extends BaseIdea
## La camiseta 2D se dibuja con la estructura en caché (2-11, «se demora demasiado el diseñador»): mismo resultado, mucho más rápido.

func _probar() -> void:
	_titulo("P6: CAMISETA 2D CON ESTRUCTURA EN CACHÉ")
	var cols: Array[Color] = [Color("c8102e"), Color("ffffff"), Color("1a237e"), Color("ffd600"), Color("00897b")]
	var e1 := DisenosKitEstructura.de(170.0 / 64.0, false, 0, true)
	var e2 := DisenosKitEstructura.de(170.0 / 64.0, false, 0, true)
	_comprobar(e1 == e2 and (e1["x"] as PackedInt32Array).size() > 1000, "la estructura de un tamaño se calcula una vez (%d píxeles)" % (e1["x"] as PackedInt32Array).size())
	var img: Image = DisenosKit._imagen_camiseta("liso", cols, 1, 170, false, {}, 0)
	var centro := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	_comprobar(img.get_width() > 100 and centro.a > 0.9 and centro.r > 0.5 and centro.g < 0.3, "una camiseta lisa roja pinta el torso de rojo con luz (%s)" % str(centro))
	var rapido := DisenosKit._imagen_camiseta("liso", cols, 1, 170, true, {}, 2)
	_comprobar(rapido.get_width() == img.get_width() and rapido.get_pixel(0, 0).a < 0.1, "de espaldas y con cuello de polo también (esquina transparente)")
	var t0 := Time.get_ticks_usec()
	for i in 6:
		DisenosKit._imagen_camiseta("liso", cols, 1, 170, false, {}, 0)
	var ms := float(Time.get_ticks_usec() - t0) / 6000.0
	_comprobar(ms < 120.0, "una camiseta de 170 px sale en %.0f ms (antes ~160 ms)" % ms)
