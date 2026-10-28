extends BaseIdea
## Cierre 28-10: autobús «Red» (números de una cara, puertas opacas, luces de noche), coches alineados en su plaza del lavado, rampa del teleférico.

func _probar() -> void:
	_titulo("P6: CIERRE CIUDAD · BUS, LAVADO Y TELEFÉRICO")
	var bus := AutobusModelo.crear(Color(0.0, 0.47, 0.75), "122 · ESTADIO", "122")
	add_child(bus)
	var una_cara := true
	var rotulos := 0
	for l: Label3D in bus.find_children("*", "Label3D", true, false):
		rotulos += 1
		if l.double_sided:
			una_cara = false
	_comprobar(rotulos >= 4 and una_cara, "los %d números del bus son de una sola cara (no se espejan)" % rotulos)
	var d: StandardMaterial3D = bus.get_meta("luz_d", null)
	var antes := d.emission_energy_multiplier
	AutobusModelo.encender(bus, 1.0)
	_comprobar(d.emission_energy_multiplier > antes * 5.0 and (bus.get_node("FocoFaros") as SpotLight3D).visible, "de noche los faros brillan y el foco se enciende")
	AutobusModelo.encender(bus, 0.0)
	_comprobar(not (bus.get_node("FocoFaros") as SpotLight3D).visible, "de día el foco está apagado")
	var traslucidos := 0
	for mi: MeshInstance3D in bus.find_children("*", "MeshInstance3D", true, false):
		var m := mi.material_override as StandardMaterial3D
		if m != null and m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and absf(mi.position.x) > 1.28 and mi.position.y < 2.0:
			traslucidos += 1
	_comprobar(traslucidos == 0, "las puertas no son translúcidas (%d piezas translúcidas en el costado bajo)" % traslucidos)
	## Coches del aparcamiento: centrados y dentro de su plaza (5,2 × 3,2 m).
	var coche := Node3D.new()
	var mi2 := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 1.4, 6.0)   ## un coche largo y torcido a propósito: 6 m
	mi2.mesh = bm
	mi2.position = Vector3(3.0, 0.7, -2.0)
	coche.add_child(mi2)
	CiudadLavado.asentar(coche, Vector3(10.0, 0.05, 20.0), true, 1.0, 4.6)
	var bb := CiudadLavado._aabb(coche, Transform3D(coche.basis, Vector3.ZERO))
	var c := coche.position + bb.position + bb.size * 0.5
	_comprobar(bb.size.x <= 4.61 and bb.size.x > bb.size.z and absf(c.x - 10.0) < 0.05 and absf(c.z - 20.0) < 0.05, "el coche queda con el eje largo en x, encogido a %.1f m y centrado en su plaza" % bb.size.x)
	## Teleférico: la ruta de la gente pasa por la rampa y no por la barandilla.
	_comprobar(PasajerosTeleferico.RAMPA_ALTA.z < PasajerosTeleferico.RAMPA_BAJA.z and PasajerosTeleferico.RAMPA_ALTA.y > PasajerosTeleferico.RAMPA_BAJA.y and absf(PasajerosTeleferico.RAMPA_ALTA.x) < 2.5, "la rampa baja del andén a la hierba por la entrada central de la barandilla")
