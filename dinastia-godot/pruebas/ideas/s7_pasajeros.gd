extends BaseIdea
## S7 · PASAJEROS DEL AUTOBÚS (27-10-2026): esperan en la parada, suben, viajan (su semilla queda anotada en el autobús) y bajan en otra parada.

func _probar() -> void:
	_titulo("S7 · LA GENTE ESPERA, SUBE AL AUTOBÚS, VIAJA Y BAJA EN OTRA PARADA")
	var b := CityBuilder.new()
	add_child(b)
	b.esperas_bus.append(Vector3(0, 0, 0))
	b.esperas_bus.append(Vector3(100, 0, 0))
	var ex := ExploradorCiudad.new()
	ex.cb = b
	ex.estado = "calle"
	var jug := Node3D.new()
	jug.position = Vector3(10, 0, 5)
	ex.cuerpo = jug
	add_child(ex)
	var pb := PasajerosBus.new()
	pb.expl = ex
	add_child(pb)
	pb._poblar()
	_comprobar((pb._esperando[0] as Array).size() == PasajerosBus.ESPERAN, "en la parada cercana esperan %d personas" % PasajerosBus.ESPERAN)
	_comprobar(pb._esperando.has(0) and not pb._esperando.has(1), "la parada lejana (100 m) está vacía")
	var s0: int = (pb._esperando[0][0] as Dictionary)["semilla"]
	var s1: int = (pb._esperando[0][1] as Dictionary)["semilla"]
	_comprobar(s0 != s1, "son personas distintas")
	## Llega el autobús a la primera parada.
	var bus := Node3D.new()
	add_child(bus)
	bus.position = Vector3(-1.5, 0, -4.6)   ## la puerta (1,5 | 4,6) cae sobre la parada
	pb.parada(bus)
	_comprobar((pb._esperando[0] as Array).is_empty() and pb._andando.size() == 2, "los dos que esperaban echan a andar hacia la puerta")
	pb._mover(20.0)
	var a: Array = bus.get_meta("pasajeros", [])
	a.sort()
	var esperados := [s0, s1]
	esperados.sort()
	_comprobar(a == esperados, "suben y quedan anotados en el autobús: %s" % str(a))
	_comprobar(pb._andando.is_empty(), "los que han subido desaparecen de la acera")
	## En la parada siguiente (otro sitio) bajan LAS MISMAS personas.
	bus.position = Vector3(300, 0, 300)
	pb.parada(bus)
	var bajan: Array = []
	for f: Dictionary in pb._andando:
		if not bool(f["sube"]):
			bajan.append(int(f["semilla"]))
	bajan.sort()
	_comprobar(bajan == esperados, "bajan las mismas dos personas (semillas %s)" % str(bajan))
	_comprobar((bus.get_meta("pasajeros", []) as Array).size() == 1 or (bus.get_meta("pasajeros", []) as Array).size() == 0, "ya no van en el autobús (los de antes) %s" % str(bus.get_meta("pasajeros", [])))
	pb._mover(30.0)
	var tope := Node3D.new()
	add_child(tope)
	var lleno := []
	for k in 12:
		lleno.append(k)
	tope.set_meta("pasajeros", lleno)
	_comprobar(PasajerosBus.MAX_ABORDO == 10, "el autobús admite como mucho 10 a bordo")
	## La gente se ve DENTRO: tantas siluetas como pasajeros, y los cristales dejan ver.
	var real := CityBuilder.autobus(Color(0.2, 0.4, 0.7))
	add_child(real)
	var vid := (real.get_child(1) as MeshInstance3D).material_override as StandardMaterial3D
	_comprobar(vid.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and vid.albedo_color.a < 0.5, "los cristales del autobús son semitransparentes")
	real.set_meta("pasajeros", [3, 9, 12])
	InteriorBus.actualizar(real)
	var vis := 0
	for k in InteriorBus.PLAZAS:
		if (real.get_node("Interior/Plaza%d/Persona" % k) as Node3D).visible:
			vis += 1
	_comprobar(vis == 3, "tres pasajeros, tres siluetas sentadas (%d)" % vis)
