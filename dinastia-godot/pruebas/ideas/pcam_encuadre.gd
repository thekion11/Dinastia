extends BaseIdea
## EL ENCUADRE DE LA TRANSMISIÓN (25-10-2026, pulido de la retransmisión). La cámara de la tele tiene
## que llevar SIEMPRE el balón en cuadro: también pegado a la banda de la cámara (saques de banda,
## carreras por esa banda, córners de ese lado) y en los balones altos (despejes, saques de puerta).
## Mide, con la cámara real del partido (`CameraRig._transmision`) en todos los estadios, dónde cae
## el balón en la pantalla, con un margen del 7 % del alto para que no quede cortado en el borde.

const DT := 1.0 / 60.0

func _dentro(cam: Camera3D, p: Vector3, margen: float) -> bool:
	if cam.is_position_behind(p):
		return false
	var tam := cam.get_viewport().get_visible_rect().size
	var s := cam.unproject_position(p)
	var m := tam.y * margen
	return s.x > m and s.x < tam.x - m and s.y > m and s.y < tam.y - m

func _rig(forma: String, niveles: int) -> CameraRig:
	var g := StadiumBuilder.geom_de_forma(forma)
	var alto := StadiumBuilder.ALTURA_PIE + float(niveles) * StadiumBuilder.subida_bandeja() + float(niveles - 1) * StadiumBuilder.FRENTE_BANDEJA
	var rig := CameraRig.new()
	add_child(rig)
	rig.set_process(false)
	rig.build_for(float(g["dx"]), float(g["dz"]), alto)
	rig.pista_estado = "juego"
	rig.pista_ataca = 1.0
	return rig

func _probar() -> void:
	_titulo("RETRANSMISIÓN: EL BALÓN SIEMPRE EN CUADRO (cámara de la tele, todos los estadios)")
	var fuera: Array = []
	var total := 0
	for forma: String in ["ingles", "cuenco", "oval", "estrecho"]:
		for niveles in [1, 3]:
			var rig := _rig(forma, niveles)
			var cam: Camera3D = rig.cameras[0]
			cam.current = true
			for bx in [-31.0, -15.0, 0.0, 15.0, 25.0, 31.0, 33.5]:
				for bz in [-48.0, -20.0, 0.0, 20.0, 48.0]:
					var b := Vector3(bx, 0.11, bz)
					for i in 200:
						rig._transmision(cam, b, DT)
					total += 1
					if not _dentro(cam, b, 0.07):
						fuera.append("%s/%d (%.0f,%.0f)" % [forma, niveles, bx, bz])
			rig.free()
	_comprobar(fuera.is_empty(), "con el balón quieto en cualquier punto del césped (también pegado a la banda de la cámara) se ve en cuadro: %d de %d fuera %s" % [fuera.size(), total, str(fuera.slice(0, 8))])

	## Un saque de banda del lado de la cámara: el que saca, en cuadro (cabeza y pies).
	var r2 := _rig("cuenco", 2)
	var c2: Camera3D = r2.cameras[0]
	c2.current = true
	r2.pista_estado = "saque"
	r2.pista_saque = "banda"
	for i in 240:
		r2._transmision(c2, Vector3(34.2, 1.9, 6.0), DT)
	var pies_ok := _dentro(c2, Vector3(34.2, 0.0, 6.0), 0.05)
	var cabeza_ok := _dentro(c2, Vector3(34.2, 2.2, 6.0), 0.05)
	_comprobar(pies_ok and cabeza_ok, "saque de banda del lado de la cámara: el lanzador entero en cuadro (pies %s, cabeza %s)" % [pies_ok, cabeza_ok])
	r2.free()

	## Balones altos: un despeje que sube a 18 m en el medio y uno que cae en el área.
	var r3 := _rig("cuenco", 2)
	var c3: Camera3D = r3.cameras[0]
	c3.current = true
	for i in 120:
		r3._transmision(c3, Vector3(0, 0.11, -20.0), DT)
	var alto_fuera := 0
	var cuadros := 0
	for i in 150:
		var u := float(i) / 150.0
		## Parábola: 2,5 s de vuelo, 40 m hacia delante, 18 m de altura máxima.
		var b := Vector3(-4.0 * u, 0.11 + 18.0 * 4.0 * u * (1.0 - u), -20.0 + 40.0 * u)
		r3._transmision(c3, b, DT)
		cuadros += 1
		if not _dentro(c3, b, 0.03):
			alto_fuera += 1
	_comprobar(alto_fuera <= 4, "un despeje de 18 m de altura no se sale del cuadro (%d de %d fotogramas fuera)" % [alto_fuera, cuadros])
	r3.free()

	## Una jugada entera que va y viene (como la del banco): fotogramas con el balón fuera.
	var r4 := _rig("ingles", 1)
	var c4: Camera3D = r4.cameras[0]
	c4.current = true
	var perdidos := 0
	for i in 1800:
		var tt := float(i) * DT
		var b := Vector3(sin(tt * 0.7) * 32.0, 0.11, sin(tt * 0.45) * 50.0)
		r4.pista_ataca = 1.0 if cos(tt * 0.45) >= 0.0 else -1.0
		r4._transmision(c4, b, DT)
		if i > 60 and not _dentro(c4, b, 0.03):
			perdidos += 1
	_comprobar(perdidos <= 18, "en una jugada de 30 s de banda a banda el balón no se pierde de cuadro (%d fotogramas fuera de 1740)" % perdidos)
	r4.free()
