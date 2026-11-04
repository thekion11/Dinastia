extends BaseIdea
## M-199: señales de límite de velocidad (por sector, estilo chileno) y multa por exceso con policía a la vista.

func _probar() -> void:
	_titulo("P6: LÍMITES DE VELOCIDAD")
	_comprobar(SenalesVelocidad.limite(Vector3(0, 0, 0)) == 40 and SenalesVelocidad.limite(Vector3(0, 0, -825)) == 50 and SenalesVelocidad.limite(Vector3(9000, 0, 0)) == 60, "límites por sector: club 40, centro 50, periferia 60")
	for v in [30, 40, 50, 60, 100]:
		var t := SenalesVelocidad.textura(v)
		var img := t.get_image()
		var negro := 0
		for y in 64:
			for x in 64:
				if img.get_pixel(x, y).r < 0.2 and img.get_pixel(x, y).a > 0.5:
					negro += 1
		_comprobar(img.get_pixel(2, 2).a < 0.1 and img.get_pixel(32, 5).r > 0.6 and img.get_pixel(32, 5).g < 0.2 and negro > 40, "la señal de %d: esquina transparente, aro rojo y cifra negra (%d px)" % [v, negro])
	_comprobar(SenalesVelocidad.textura(50) == SenalesVelocidad.textura(50) and SenalesVelocidad.textura(40) != SenalesVelocidad.textura(50), "una textura por valor, en caché")
	var iguales := 0
	var a := SenalesVelocidad.textura(30).get_image()
	var b := SenalesVelocidad.textura(60).get_image()
	for y in 64:
		for x in 64:
			if a.get_pixel(x, y) == b.get_pixel(x, y):
				iguales += 1
	_comprobar(iguales < 64 * 64 - 40, "cada cifra se dibuja distinta (30 ≠ 60)")
	_comprobar(IncidentesCiudad.MULTA_VELOCIDAD > 0 and IncidentesCiudad.MULTA_VELOCIDAD < IncidentesCiudad.MULTA_SEMAFORO, "la multa de velocidad (%d €) es menor que la del semáforo" % IncidentesCiudad.MULTA_VELOCIDAD)
