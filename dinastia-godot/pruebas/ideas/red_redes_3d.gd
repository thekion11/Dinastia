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
	ex._farolas()
	ex.encender(1.0)
	var sin: Vector2i = sec
	var con := Vector2i(4, 4) if sin != Vector2i(4, 4) else Vector2i(0, 0)
	_comprobar(ex._farolas_sec.size() >= 20, "las farolas van por sectores (%d)" % ex._farolas_sec.size())
	_comprobar(float((ex._farolas_sec[sin]["luz"] as StandardMaterial3D).emission_energy_multiplier) == 0.0 \
		and float((ex._farolas_sec[con]["luz"] as StandardMaterial3D).emission_energy_multiplier) > 2.0, "de noche, las farolas del sector sin luz se apagan y las demás no")
	_comprobar((ex._farolas_sec[sin]["charco"] as StandardMaterial3D).albedo_color.a == 0.0 and float((ex._farolas_sec[sin]["cono"] as ShaderMaterial).get_shader_parameter("fuerza")) == 0.0, "y también su charco de luz y su haz")
	v.modelo.reparar("luz", sin)
	v.modelo.recalcular()
	ex.encender(1.0)
	_comprobar(float((ex._farolas_sec[sin]["luz"] as StandardMaterial3D).emission_energy_multiplier) > 2.0, "al volver la corriente se encienden otra vez")
	v.modelo.averiar("luz", sin)
	v.modelo.recalcular()
	v.refrescar()
	v.modelo.pasar(5, 14, 0.5, 25.0)
	v.refrescar()
	_comprobar((v._aguas[Vector2i(1, 1)] as MeshInstance3D).visible, "una tormenta cubre de agua los sectores desbordados")
	var s: Dictionary = v.surtidores[0]
	var pm: StandardMaterial3D = s["pantalla"]
	_comprobar(pm.emission_energy_multiplier > 0.0 or not v.modelo.hay_luz(s["sector"]), "la pantalla del surtidor sigue a la corriente")
	b.queue_free()
	_probar_subsuelo(b, v)

class FalsoExplorador:
	var vida = null
	var _aviso := Label.new()

func _probar_subsuelo(b: CityBuilder, v: RedesCiudadVista) -> void:
	_linea("· Subsuelo (easter egg)")
	_comprobar(v.bocas.size() == 5, "cinco tapas de alcantarilla con aro de óxido (%d)" % v.bocas.size())
	var tapas := 0
	for pc: Dictionary in b.puntos_clic:
		if String(pc["k"]).begins_with("alcantarilla_"):
			tapas += 1
	_comprobar(tapas == 5, "cada una es un punto de E")
	var s := SubsueloCiudad.crear(b, v)
	_comprobar(not s.visible and s.rects.size() == 10, "el subsuelo se levanta oculto, con 10 huecos")
	_comprobar(s.libre(Vector2(-1.5, -1.5)) and not s.libre(Vector2(-20.0, 0.0)), "se aparece en el pozo y la roca no se pisa")
	## Todo conectado: desde el pozo se llega a cada punto de interés (relleno por la rejilla de 0,5 m).
	var visto := {}
	var cola: Array[Vector2i] = [Vector2i(-3, -3)]
	visto[Vector2i(-3, -3)] = true
	while not cola.is_empty():
		var c: Vector2i = cola.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if visto.has(n) or not s.libre(Vector2(float(n.x), float(n.y)) * 0.5):
				continue
			visto[n] = true
			cola.append(n)
	var sin_llegar := 0
	for p: Dictionary in s.puntos:
		var q: Vector2 = p["pos"]
		if not visto.has(Vector2i(roundi(q.x * 2.0), roundi(q.y * 2.0))):
			sin_llegar += 1
			_linea("  sin llegar: %s %s" % [p["k"], q])
	_comprobar(sin_llegar == 0 and s.puntos.size() == 5 + v.modelo.edificios.size(), "las %d interacciones (salir, mandos, disyuntor, tele y una acometida por edificio) son alcanzables a pie" % s.puntos.size())
	_comprobar(visto.has(Vector2i(210, 0)), "y el cuarto olvidado del fondo también")
	_comprobar(s._acometidas.size() == v.modelo.edificios.size() and v.modelo.edificios.size() >= 15, "un armario de acometida por cada edificio real (%d)" % s._acometidas.size())
	_comprobar(s._paneles.size() == 3, "el centro de mando tiene sus tres pantallas")
	_comprobar(s.get_child_count() > 400, "paredes, tuberías y cables levantados (%d piezas)" % s.get_child_count())
	var cam := s.encajar_camara(SubsueloCiudad.ORIGEN + Vector3(-40.0, 9.0, 0.0), SubsueloCiudad.ORIGEN + Vector3(0, 1.0, 0))
	_comprobar(cam.y <= SubsueloCiudad.ORIGEN.y + SubsueloCiudad.ALTO and cam.x > SubsueloCiudad.ORIGEN.x - 6.0, "la cámara no se sale de los túneles")
	## Los mandos de la sala de control actúan sobre las redes.
	var e := FalsoExplorador.new()
	s.sector_entrada = Vector2i(2, 2)
	_comprobar(s.usar(e, "sub_cortar") and not v.modelo.hay_luz(Vector2i(2, 2)), "la palanca roja deja sin luz el sector de arriba")
	_comprobar(s.usar(e, "sub_cortar") and v.modelo.hay_luz(Vector2i(2, 2)), "y al volver a subirla la recupera")
	v.modelo.averiar("agua", Vector2i(1, 1))
	v.modelo.averiar("luz", Vector2i(3, 3))
	_comprobar(s.usar(e, "sub_reparar") and not v.modelo.esta_averiado("agua", Vector2i(1, 1)) and v.modelo.hay_luz(Vector2i(3, 3)), "el botón verde arregla todas las averías")
	v.modelo.evento._empezar(v.modelo)
	_comprobar(s.usar(e, "sub_reparar") and v.modelo.evento.activo, "con el disyuntor saltado, reparar no basta")
	_comprobar(s.usar(e, "sub_disyuntor") and v.modelo.evento.rearmado and s.usar(e, "sub_reparar") and not v.modelo.evento.activo, "rearmar en el cuadro general y reconectar en la sala resuelve el evento")
	var ed0: Dictionary = v.modelo.edificios[0]
	_comprobar(s.usar(e, "sub_edif_0") and bool(ed0["aislado"]) and s.usar(e, "sub_edif_0") and not bool(ed0["aislado"]), "cada armario aísla y restablece su edificio")
	_comprobar(not s.usar(e, "sub_inventada"), "una orden desconocida no hace nada")
