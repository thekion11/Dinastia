extends BaseIdea
## P1 «MEJORAR» (27-10-2026): el peatón gira con suavidad en las esquinas, arranca con rampa y, si le frenan, deja de mover las piernas.

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("P1: MOVIMIENTO NATURAL DE LOS PEATONES")
	seed(99)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var ruta := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(30, 0, 0), Vector3(30, 0, 30), Vector3(0, 0, 30)]))
	var d := PeatonVida.nuevo(t, 5)
	if d.is_empty():
		_comprobar(true, "(sin modelo de peatón en este entorno)")
		return
	t.agregar_vehiculo(d["nodo"], ruta, 28.0, 1.4, 0.15)
	var v: Dictionary = t._vehiculos[0]
	v["lod"] = 0
	## 1) Esquina: ningún fotograma gira más de 0,35 rad (el giro seco serían 1,57).
	var nodo: Node3D = v["nodo"]
	var previo := nodo.rotation.y
	var peor := 0.0
	for i in 150:
		v.erase("espera")
		v.erase("pausa")
		t._process(DT)
		peor = maxf(peor, absf(angle_difference(previo, nodo.rotation.y)))
		previo = nodo.rotation.y
	_comprobar(float(v["s"]) > 31.5, "el peatón pasó la esquina (s = %.1f)" % float(v["s"]))
	_comprobar(peor < 0.35, "gira con suavidad en la esquina (máx. %.2f rad por fotograma)" % peor)
	## 2) Frenado: sin avance pasa a «parado» y no mueve el cuerpo; al soltarlo arranca con rampa.
	var ap := MovimientoNatural._reproductor(v)
	var pedido := 1.4 * DT
	v["anda"] = true
	v["k"] = 1.0
	v["t_anda"] = 0.0
	var mov := 0.0
	for i in 20:
		mov += MovimientoNatural.marcha(v, 0.0, pedido, DT)
	_comprobar(ap.current_animation == "parado" and mov == 0.0, "frenado: clip «%s» y avance %.3f" % [ap.current_animation, mov])
	var primero := MovimientoNatural.marcha(v, pedido, pedido, DT)
	_comprobar(primero < pedido * 0.3, "al soltarlo no arranca de golpe (%.3f de %.3f)" % [primero, pedido])
	var total := 0.0
	for i in 30:
		total += MovimientoNatural.marcha(v, pedido, pedido, DT)
	_comprobar(ap.current_animation == "caminar" and float(v["k"]) >= 1.0, "y a los 1,0 s anda a velocidad plena (clip «%s», k %.2f)" % [ap.current_animation, float(v["k"])])
	_comprobar(total < pedido * 30.0, "la rampa le cuesta algo de camino (%.2f de %.2f m)" % [total, pedido * 30.0])
	## 3) La cabeza sigue al jugador cuando pasa cerca (2 de cada 3 peatones) y lo suelta al alejarse.
	var yo := Node3D.new()
	add_child(yo)
	t.jugador = yo
	for k in 6:
		var dk := PeatonVida.nuevo(t, 50 + k)
		t.agregar_vehiculo(dk["nodo"], ruta, 5.0 + float(k) * 3.0, 1.4, 0.15)
	var mirados := 0
	var suelta := true
	for v2: Dictionary in t._vehiculos:
		MovimientoNatural.mirada(v2, yo, 4.0, 0.5)
		MovimientoNatural.mirada(v2, yo, 4.0, 0.5)
		if v2.has("mira_mod") and (v2["mira_mod"] as LookAtModifier3D).influence > 0.5:
			mirados += 1
			MovimientoNatural.mirada(v2, yo, 400.0, 1.0)
			suelta = suelta and not (v2["mira_mod"] as LookAtModifier3D).active
	_comprobar(mirados >= 2 and mirados <= 6, "de siete peatones cerca, giran la cabeza hacia ti entre 2 y 6 (%d)" % mirados)
	_comprobar(suelta, "y la sueltan al alejarte")
	t.queue_free()

