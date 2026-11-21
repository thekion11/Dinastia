extends "res://pruebas/medir_prologo_p1.gd"
## (Parte 2 de 2 de `medir_prologo.gd`.)

## Camina 40 s de juego hacia el centro de la ciudad, midiendo el coste por cuadro.
func _paseo_ciudad(e: ExploradorCiudad) -> void:
	var cuadros := 0
	var suma := 0
	var peor := 0
	var mem0 := Performance.get_monitor(Performance.MEMORY_STATIC)
	var dir := Vector3(1, 0, -0.3).normalized()
	var anterior := Time.get_ticks_msec()
	var n_paseo := 1200 if DisplayServer.get_name() == "headless" else 150   ## con ventana (render por software) cada cuadro cuesta mucho
	for i in n_paseo:
		if e != null and e.cuerpo != null:
			e.cuerpo.position += dir * (0.1 if n_paseo > 200 else 0.8)
		await get_tree().process_frame
		var ahora2 := Time.get_ticks_msec()
		var dt := ahora2 - anterior
		anterior = ahora2
		if i > 20:
			cuadros += 1
			suma += dt
			peor = maxi(peor, dt)
	_foto("tras caminar 120 m", "media %.1f ms/cuadro, peor %d ms, mem +%.0f MB" % [float(suma) / maxf(cuadros, 1), peor, (Performance.get_monitor(Performance.MEMORY_STATIC) - mem0) / 1048576.0])


## Entra al estadio a pie: construye el interior y mide el primer cuadro y el peor después.
func _entrar_estadio_medido(e: ExploradorCiudad) -> void:
	var anterior := 0
	## ENTRAR AL ESTADIO a pie (el paso que pide moverse al personaje: aquí se construye el interior y vuelven las butacas buenas).
	e.cuerpo.position = _p.puerta
	await get_tree().process_frame
	var mem1 := Performance.get_monitor(Performance.MEMORY_STATIC)
	var t1 := Time.get_ticks_msec()
	e._entrar_al_estadio()
	await get_tree().process_frame
	var primer := Time.get_ticks_msec() - t1
	var peor2 := primer
	anterior = Time.get_ticks_msec()
	for i in 90 if DisplayServer.get_name() == "headless" else 20:
		await get_tree().process_frame
		var ahora3 := Time.get_ticks_msec()
		peor2 = maxi(peor2, ahora3 - anterior)
		anterior = ahora3
	_foto("dentro del estadio", "entrar: %d ms en el primer cuadro, peor cuadro %d ms, mem +%.0f MB, estado %s" % [primer, peor2, (Performance.get_monitor(Performance.MEMORY_STATIC) - mem1) / 1048576.0, String(e.estado)])
