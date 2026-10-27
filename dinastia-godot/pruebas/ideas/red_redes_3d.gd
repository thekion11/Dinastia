extends BaseIdea
## REDES DE LA CIUDAD EN 3D (27-10-2026): se levantan las instalaciones sobre la red de calles y
## el dibujo sigue al modelo (lámparas de transformador, agua en las calles, farolas, surtidores).

func _probar() -> void:
	_titulo("CIUDAD · REDES EN 3D (luz, agua, drenaje, gas)")
	var b := CityBuilder.new()
	add_child(b)
	var ex := CiudadExpansion.new(b)
	ex.armar_red()
	ex.armar_bloques()
	ex.armar_transporte()
	var v := RedesCiudadVista.crear(ex, 5)
	v.modelo.averias_azar = false
	_comprobar(int(v.cuenta["hidrantes"]) > 200 and int(v.cuenta["sumideros"]) > 800 and int(v.cuenta["tapas"]) > 400, \
		"hidrantes %d, sumideros %d, tapas %d" % [v.cuenta["hidrantes"], v.cuenta["sumideros"], v.cuenta["tapas"]])
	_comprobar(int(v.cuenta["transformadores"]) > 100 and v._lamparas.size() >= 20, "%d transformadores repartidos en %d sectores" % [v.cuenta["transformadores"], v._lamparas.size()])
	_comprobar(int(v.cuenta["torres"]) >= 10 and v.cuenta.has("subestacion") and v.cuenta.has("central"), "línea de alta tensión con %d torres, subestación y central" % v.cuenta["torres"])
	_comprobar(v.cuenta.has("potabilizadora") and v.cuenta.has("depuradora"), "potabilizadora y depuradora levantadas")
	_comprobar(v.surtidores.size() == 3 and int(v.cuenta["surtidores"]) == 12, "tres gasolineras con 4 surtidores cada una")
	var punto := 0
	for pc: Dictionary in b.puntos_clic:
		if String(pc["k"]).begins_with("surtidor_"):
			punto += 1
	_comprobar(punto == 3, "cada gasolinera es un punto de E «Repostar»")
	## El dibujo sigue al modelo.
	var sec: Vector2i = v._lamparas.keys()[0]
	var lampara: StandardMaterial3D = v._lamparas[sec]
	_comprobar(lampara.albedo_color.g > 0.5, "con corriente la lámpara del transformador está verde")
	v.modelo.averiar("luz", sec)
	v.hora_cambiada(3, "despejado")
	_comprobar(lampara.albedo_color.r > 0.5 and lampara.albedo_color.g < 0.3, "con el corte la lámpara se pone roja")
	_comprobar(v.fraccion_luz() < 1.0, "y la fracción de ciudad con luz baja")
	ex.redes = v
	ex.encender(1.0)
	_comprobar(true, "encender con un apagón no falla")
	v.modelo.pasar(5, 14, 0.5, 25.0)
	v.refrescar()
	_comprobar((v._aguas[Vector2i(1, 1)] as MeshInstance3D).visible, "una tormenta cubre de agua los sectores desbordados")
	var s: Dictionary = v.surtidores[0]
	var pm: StandardMaterial3D = s["pantalla"]
	_comprobar(pm.emission_energy_multiplier > 0.0 or not v.modelo.hay_luz(s["sector"]), "la pantalla del surtidor sigue a la corriente")
	b.queue_free()
