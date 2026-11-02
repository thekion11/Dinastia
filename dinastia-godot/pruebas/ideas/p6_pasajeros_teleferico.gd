extends BaseIdea
## La gente del teleférico (orden del líder): al llegar la cabina abajo bajan dos personas y, unos segundos después, suben otras dos.

func _probar() -> void:
	_titulo("P6: PASAJEROS DEL TELEFÉRICO")
	var raiz := Node3D.new()
	add_child(raiz)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.make_current()
	var tele := Teleferico.new()
	tele.process_mode = Node.PROCESS_MODE_DISABLED   ## sin cable ni cabinas: solo se usa su reloj
	raiz.add_child(tele)
	var est := Node3D.new()
	raiz.add_child(est)
	var pt := PasajerosTeleferico.crear(tele, est)
	tele._t = PasajerosTeleferico.llegada() + 0.2
	pt._process(0.05)
	_comprobar(pt._andando.is_empty(), "antes de los 0,5 s de la llegada aún no sale nadie")
	tele._t = PasajerosTeleferico.llegada() + 1.0
	pt._process(0.05)
	_comprobar(pt._andando.size() == 2, "al llegar la cabina bajan dos personas (%d)" % pt._andando.size())
	tele._t = PasajerosTeleferico.llegada() + 5.0
	pt._process(0.05)
	_comprobar(pt._andando.size() == 4, "unos segundos después suben otras dos (%d en marcha)" % pt._andando.size())
	var antes := pt._andando.size()
	tele._t = PasajerosTeleferico.llegada() + 5.2
	pt._process(0.05)
	_comprobar(pt._andando.size() == antes, "no se repiten en el mismo ciclo")
	for i in 40:
		pt._process(1.0)
	_comprobar(pt._andando.is_empty(), "al llegar a su sitio (plaza o puerta) las figuras desaparecen")
	tele._t = PasajerosTeleferico.llegada() + 1.0 + Teleferico.CICLO
	pt._process(0.05)
	_comprobar(pt._andando.size() == 2, "en el ciclo siguiente vuelve a haber gente")
	cam.global_position = Vector3(9000, 0, 0)
	var n0 := pt._andando.size()
	tele._t += Teleferico.CICLO
	pt._process(0.05)
	_comprobar(pt._andando.size() == n0, "con la cámara lejos no se monta gente")
	## Segunda llegada del ciclo (la otra cabina, a los V s) y estación de arriba con su propia ruta.
	pt._andando.clear()
	cam.global_position = Vector3.ZERO
	tele._t = Teleferico.VIAJE + 1.0 + 2.0 * Teleferico.CICLO
	pt._process(0.05)
	_comprobar(pt._andando.size() == 2, "la otra cabina también llega a esta estación (a los %.0f s) y baja gente" % Teleferico.VIAJE)
	var cima_n := Node3D.new()
	raiz.add_child(cima_n)
	var pc := PasajerosTeleferico.crear(tele, cima_n, true)
	tele._t = PasajerosTeleferico.llegada() + 1.0 + 3.0 * Teleferico.CICLO
	pc._process(0.05)
	_comprobar(pc._andando.size() == 2 and (pc._andando[0]["ruta"] as Array).size() == 5, "la estación de arriba también baja gente (por su rampa corta)")
	tele._t = Teleferico.VIAJE + 20.0 + 3.0 * Teleferico.CICLO
	var n_antes := pc._andando.size()
	pc._process(0.05)
	_comprobar(pc._andando.size() == n_antes, "fuera de la ventana de 9 s de una llegada no sale nadie de golpe")
	## Viajeros que cambian dentro de la cabina.
	var cab := Node3D.new()
	for i in 4:
		var v := Node3D.new()
		v.set_meta("viajero", true)
		cab.add_child(v)
	_comprobar(PasajerosTeleferico.cambiar_viajeros(cab, true) == 2 and not cab.get_child(0).visible and cab.get_child(2).visible, "al llegar bajan dos viajeros de la cabina")
	_comprobar(PasajerosTeleferico.cambiar_viajeros(cab, false) == 2 and cab.get_child(0).visible, "y suben otros dos al salir")
	cab.free()
