extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: la GENTE QUE SUBE Y BAJA de los transportes, al límite.
##   1. Bus lleno: nunca van más de `MAX_ABORDO` a bordo; los que no caben se quedan esperando en la acera (no se «evaporan» dentro del bus).
##   2. El bus se va mientras suben o bajan, o desaparece del todo: nadie queda FLOTANDO a la altura del escalón (y 0,55) en el aire ni sigue andando hacia un hueco.
##   3. 60 paradas seguidas (con y sin gente esperando): los nodos de la gente se liberan, `_andando` se vacía y el bus no pasa de 10.
##   4. Teleférico: solo salen (o entran) tantas personas como viajeros cambian en la cabina.
func _esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _flotando(pb: PasajerosBus, bus: Node3D) -> int:
	var malos := 0
	for f: Dictionary in pb._andando:
		var n: Node3D = (f["d"] as Dictionary)["nodo"]
		if is_instance_valid(n) and n.position.y > 0.3:
			if bus == null or not is_instance_valid(bus) or bus.global_position.distance_to(f["ancla"]) > 2.0 and not bool(f.get("libre", false)):
				malos += 1
	return malos

func _montar() -> Array:
	var b := CityBuilder.new()
	add_child(b)
	b.esperas_bus.append(Vector3(0, 0, 0))
	var ex := ExploradorCiudad.new()
	ex.cb = b
	ex.estado = "calle"
	var jug := Node3D.new()
	jug.position = Vector3(10, 0, 5)
	ex.cuerpo = jug
	ex.process_mode = Node.PROCESS_MODE_DISABLED   ## sin cámara de verdad su _process falla; aquí solo hace de «explorador» para el bus
	add_child(ex)
	var pb := PasajerosBus.new()
	pb.expl = ex
	add_child(pb)
	return [pb, b]

func _probar() -> void:
	_titulo("A4 MUNDO_3D: pasajeros de los transportes al límite (bus lleno, bus que se va, 60 paradas, teleférico)")
	var m := _montar()
	var pb: PasajerosBus = m[0]
	## 1. bus lleno
	var bus := CityBuilder.autobus(Color(0.2, 0.4, 0.7))
	add_child(bus)
	bus.position = Vector3(-1.5, 0, -4.6)
	var lleno := []
	for k in PasajerosBus.MAX_ABORDO:
		lleno.append(100 + k)
	bus.set_meta("pasajeros", lleno)
	pb._poblar()
	pb.parada(bus)   ## bajan 2 y quedan 2 huecos: suben 2
	pb.parada(bus)   ## una segunda parada sin haber llegado aún los anteriores: no cabe nadie más
	var suben := 0
	for f: Dictionary in pb._andando:
		if bool(f["sube"]):
			suben += 1
	pb._mover(30.0)
	var abordo: Array = bus.get_meta("pasajeros", [])
	print("  (info) bus lleno: %d a bordo tras dos paradas seguidas (suben en marcha: %d)" % [abordo.size(), suben])
	_comprobar(abordo.size() <= PasajerosBus.MAX_ABORDO, "el bus nunca pasa de %d a bordo (%d)" % [PasajerosBus.MAX_ABORDO, abordo.size()])
	## 2. el bus se va mientras suben
	var m2 := _montar()
	var pb2: PasajerosBus = m2[0]
	var bus2 := CityBuilder.autobus(Color(0.2, 0.4, 0.7))
	add_child(bus2)
	bus2.position = Vector3(-1.5, 0, -4.6)
	bus2.set_meta("pasajeros", [201, 202, 203])
	pb2._poblar()
	pb2.parada(bus2)
	pb2._mover(2.5)
	bus2.position = Vector3(400, 0, 400)   ## el bus arranca
	var max_flota := 0
	var t := 0.0
	while t < 25.0:
		pb2._mover(0.25)
		t += 0.25
		max_flota = maxi(max_flota, _flotando(pb2, bus2))
	print("  (info) bus que se va: %d figuras flotando como mucho; quedan %d andando" % [max_flota, pb2._andando.size()])
	_comprobar(max_flota == 0, "el bus se va mientras suben/bajan: nadie queda flotando en el aire (%d)" % max_flota)
	## 2b. el bus desaparece (LOD, borrado)
	var bus3 := CityBuilder.autobus(Color(0.2, 0.4, 0.7))
	add_child(bus3)
	bus3.position = Vector3(-1.5, 0, -4.6)
	bus3.set_meta("pasajeros", [301, 302])
	pb2._poblar()
	pb2.parada(bus3)
	pb2._mover(1.0)
	bus3.free()
	var malos_libre := 0
	for i in 40:
		pb2._mover(0.5)
		malos_libre = maxi(malos_libre, _flotando(pb2, null))
	_comprobar(malos_libre == 0 and pb2._andando.is_empty(), "el bus desaparece con gente subiendo: nadie flota ni se queda colgado (%d, quedan %d)" % [malos_libre, pb2._andando.size()])
	## 3. 60 paradas seguidas
	var m3 := _montar()
	var pb3: PasajerosBus = m3[0]
	var bus4 := CityBuilder.autobus(Color(0.2, 0.4, 0.7))
	add_child(bus4)
	pb3._poblar()   ## los dos que esperan ya existen al medir
	pb3.parada(bus4)
	pb3._mover(40.0)
	await _esperar(2)
	var nodos0 := get_tree().root.find_children("*", "", true, false).size()
	var tope := 0
	for k in 60:
		bus4.position = Vector3(-1.5 + float(k % 3) * 300.0, 0, -4.6 + float(k % 2) * 300.0)
		if k % 3 == 0:
			pb3._poblar()
		pb3.parada(bus4)
		pb3._mover(40.0)
		tope = maxi(tope, (bus4.get_meta("pasajeros", []) as Array).size())
	await _esperar(2)
	var nodos1 := get_tree().root.find_children("*", "", true, false).size()
	print("  (info) 60 paradas: máximo a bordo %d; nodos %d → %d; andando %d" % [tope, nodos0, nodos1, pb3._andando.size()])
	_comprobar(tope <= PasajerosBus.MAX_ABORDO and pb3._andando.is_empty(), "60 paradas: nunca más de %d a bordo y nadie queda andando (%d)" % [PasajerosBus.MAX_ABORDO, tope])
	_comprobar(nodos1 - nodos0 < 110, "60 paradas: los nodos no crecen más que los 2 que esperan en la marquesina (%d → %d)" % [nodos0, nodos1])
	## 4. teleférico: tantas personas como viajeros cambian
	var cab := Node3D.new()
	add_child(cab)
	for k in 4:
		var h := Node3D.new()
		h.set_meta("viajero", true)
		h.visible = k < 1   ## solo hay 1 viajero
		cab.add_child(h)
	var bajan := PasajerosTeleferico.cambiar_viajeros(cab, true)
	var suben2 := PasajerosTeleferico.cambiar_viajeros(cab, false)
	print("  (info) cabina con 1 viajero: bajan %d, suben %d" % [bajan, suben2])
	_comprobar(bajan == 1 and suben2 == 2, "la cabina cambia sus viajeros, como mucho 2 (bajan %d de 1, suben %d)" % [bajan, suben2])
