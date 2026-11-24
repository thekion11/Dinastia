extends "res://pruebas/banco/ciudad_p1.gd"
## [Capa 2/3 de `ciudad.gd`] _probar_redes_ciudad y sus secciones (luz y agua, drenaje y gas, edificios y apagón, guardado, coche y azar).

## LAS REDES DE LA CIUDAD (27-10-2026): luz, agua, drenaje y gasolineras.
func _probar_redes_ciudad() -> void:
	_titulo("REDES DE LA CIUDAD: LUZ, AGUA, DRENAJE Y GAS")
	_redes_luz_y_agua()
	_redes_drenaje_y_gas()
	_redes_edificios_y_apagon()
	_redes_guardado()
	_redes_coche_y_azar()

## Luz y agua de las redes (sectores, de madrugada y en hora punta, averías y reparación).
func _redes_luz_y_agua() -> void:
	var r := RedesCiudad.new(7)
	r.averias_azar = false
	_comprobar(r.sectores().size() == 25 and is_equal_approx(r.fraccion_luz(), 1.0), "25 sectores y todos con luz al empezar")
	_comprobar(RedesCiudad.sector_en(0.0, 0.0) == Vector2i(2, 2) and RedesCiudad.sector_en(-1320.0, -1320.0) == Vector2i(0, 0) \
		and RedesCiudad.sector_en(1320.0, 1320.0) == Vector2i(4, 4), "cada punto del mapa cae en su sector")
	## LUZ: de madrugada sobra energía; en hora punta y sin viento se cortan sectores, menos el del hospital.
	r.pasar(1, 3, 0.5, 0.0)
	_comprobar(is_equal_approx(r.fraccion_luz(), 1.0), "de madrugada hay luz en toda la ciudad")
	r.pasar(1, 20, 0.0, 0.0)
	_comprobar(r.fraccion_luz() < 1.0, "a las 20:00 sin viento faltan %.0f MW y se cortan sectores" % (r.demanda - r.generacion))
	_comprobar(r.hay_luz(RedesCiudad.sector_de(Vector2i(5, -1))), "el hospital nunca se queda a oscuras")
	r.pasar(1, 20, 1.0, 0.0)
	_comprobar(is_equal_approx(r.fraccion_luz(), 1.0), "con viento pleno vuelve la luz en hora punta")
	r.averiar("luz", Vector2i(1, 1))
	r.pasar(1, 3, 0.5, 0.0)
	_comprobar(not r.hay_luz(Vector2i(1, 1)) and r.hay_luz(Vector2i(1, 2)), "un transformador averiado deja sin luz solo su sector")
	_comprobar(not r.hay_agua(Vector2i(1, 1)), "y sin luz no hay presión en el agua de ese sector")
	r.reparar("luz", Vector2i(1, 1))
	r.pasar(1, 3, 0.5, 0.0)
	_comprobar(r.hay_luz(Vector2i(1, 1)) and r.hay_agua(Vector2i(1, 1)), "al repararlo vuelven la luz y el agua")
	## AGUA: una rotura corta solo su ramal; el depósito se mantiene con la potabilizadora.
	r.averiar("agua", Vector2i(3, 3))
	r.pasar(1, 9, 0.5, 0.0)
	_comprobar(not r.hay_agua(Vector2i(3, 3)) and r.hay_agua(Vector2i(3, 2)), "una tubería rota corta el agua de su sector")
	r.agua_nivel = 0.0
	r.pasar(1, 9, 0.5, 0.0)
	_comprobar(r.agua_nivel > 0.0, "la potabilizadora vuelve a llenar un depósito vacío")

## Drenaje (lluvia, inundaciones, sumideros) y gas (repostaje, cisterna, bombas sin luz).
func _redes_drenaje_y_gas() -> void:
	## DRENAJE: un chaparrón desborda los colectores y se vacían al parar.
	var d := RedesCiudad.new(7)
	d.averias_azar = false
	d.pasar(5, 14, 0.5, 25.0)
	_comprobar(d.sectores_inundados() == 25, "cinco horas de 25 mm/h inundan la ciudad entera")
	d.pasar(8, 10, 0.5, 0.0)
	_comprobar(d.sectores_inundados() == 0, "ocho horas sin lluvia y los colectores desaguan")
	d.averiar("drenaje", Vector2i(2, 2))
	d.pasar(10, 12, 0.5, 8.0)
	_comprobar(d.inundado[Vector2i(2, 2)] and not d.inundado[Vector2i(2, 3)], "con 8 mm/h solo se inunda el sector de los sumideros atascados")
	_comprobar(RedesCiudad.tiempo_de("tormenta", 15)["lluvia"] > RedesCiudad.tiempo_de("lluvia", 15)["lluvia"] \
		and is_zero_approx(RedesCiudad.tiempo_de("despejado", 15)["lluvia"]), "el clima de la semana manda la lluvia")
	## GAS: se reposta, baja el depósito, la cisterna repone y sin luz no hay bomba.
	var g := RedesCiudad.new(7)
	g.averias_azar = false
	var antes: float = g.gas[0]
	var rep := g.repostar(0, Vector2i(2, 2), 45.0)
	_comprobar(is_equal_approx(float(rep["litros"]), 45.0) and int(rep["coste"]) == 63 and float(g.gas[0]) == antes - 45.0, "45 l cuestan 63 € y salen del depósito")
	g.averiar("luz", Vector2i(2, 2))
	g.pasar(1, 3, 0.5, 0.0)
	_comprobar(int(g.repostar(0, Vector2i(2, 2), 45.0)["coste"]) == 0, "sin corriente las bombas no sirven")
	g.gas[1] = 100.0
	g.pasar(1, 9, 0.5, 0.0)
	_comprobar(float(g.gas[1]) > 5000.0, "una gasolinera casi vacía recibe la cisterna")
	_comprobar(int(g.cisterna.get(1, 0)) == RedesCiudad.CISTERNA_HORAS and RedesCiudad.new(7).cisterna.is_empty(), "y el camión cisterna se queda descargando unas horas (§2.5)")
	g.pasar(RedesCiudad.CISTERNA_HORAS + 1, 10, 0.5, 0.0)
	_comprobar(not g.cisterna.has(1) and g.a_dic().has("cis"), "luego se va, y su estado se guarda")

## Edificios reales conectados a su sector y el evento del apagón (rearmar y reconectar).
func _redes_edificios_y_apagon() -> void:
	## EDIFICIOS REALES: consumen de su sector, el hospital tiene generador y aislar uno baja la demanda.
	var ed := RedesCiudad.new(7)
	ed.averias_azar = false
	ed.registrar_edificio("hospital", Vector3(550.0, 0, -110.0))
	ed.registrar_edificio("estadio", Vector3(0.0, 0, 0.0), "Estadio X")
	ed.registrar_edificio("inventado", Vector3.ZERO)
	_comprobar(ed.edificios.size() == 2 and ed.edificios[0]["sector"] == RedesCiudad.sector_de(Vector2i(5, -1)), "los edificios se conectan al sector donde están (y los usos raros se ignoran)")
	var dem0 := ed.demanda_sector(RedesCiudad.sector_en(0.0, 0.0))
	ed.edificios[1]["aislado"] = true
	_comprobar(ed.demanda_sector(RedesCiudad.sector_en(0.0, 0.0)) < dem0 - 1.5, "aislar el estadio le quita 1,8 MW a su sector")
	ed.averiar("luz", RedesCiudad.sector_de(Vector2i(5, -1)))
	ed.recalcular()
	_comprobar(bool(ed.estado_edificio(ed.edificios[0])["luz"]) and not bool(ed.estado_edificio(ed.edificios[1])["luz"]), "con el sector a oscuras el hospital sigue (generador) y el estadio aislado no")
	## EL EVENTO DEL APAGÓN: tormenta a las 20:00, hay que rearmar el disyuntor y luego reconectar.
	var ev := RedesCiudad.new(21)
	ev.averias_azar = false
	var dias := 0
	while not ev.evento.activo and dias < 60:
		ev.pasar(1, 20, 0.9, 10.0, "tormenta")
		dias += 1
	_comprobar(ev.evento.activo and ev.evento.sectores.size() == 2 and ev.evento.sectores[0] != ev.evento.sectores[1], "una semana de tormenta provoca el apagón (a los %d días de probar)" % dias)
	_comprobar(not ev.hay_luz(ev.evento.sectores[0]) and not ev.hay_luz(ev.evento.sectores[1]), "dos sectores se quedan sin luz")
	_comprobar(ev.reparar_todo() == 0 and not ev.hay_luz(ev.evento.sectores[0]), "el botón de reparar no arregla el disyuntor general")
	_comprobar(ev.evento.reconectar(ev) == "falta_rearmar" and ev.evento.rearmar() == "ok" and ev.evento.rearmar() == "ya", "primero se rearma (una sola vez) y solo entonces se reconecta")
	_comprobar(ev.evento.reconectar(ev) == "ok" and not ev.evento.activo and ev.hay_luz(Vector2i(2, 2)) and ev.evento.resueltos == 1, "reconectar devuelve la luz y cuenta como resuelto por el jugador")
	var tipos: Array = []
	for a: Dictionary in ev.evento.tomar_avisos():
		tipos.append(a["tipo"])
	_comprobar(tipos == ["inicio", "resuelto"] and not ev.registro.is_empty(), "el evento deja avisos (móvil y prensa) y líneas en el registro")
	while not ev.evento.activo and dias < 120:
		ev.pasar(1, 20, 0.9, 10.0, "tormenta")
		dias += 1
	ev.pasar(1, 8, 0.5, 0.0, "tormenta")
	_comprobar(not ev.evento.activo and ev.evento.por_cuadrilla == 1 and ev.hay_luz(Vector2i(2, 2)), "si nadie baja, la cuadrilla lo arregla a las 08:00")
	_comprobar(ev.historial.size() > 0 and ev.historial.size() <= RedesCiudad.HISTORIAL_MAX, "el historial de 24 horas alimenta las curvas del centro de mando")

## Guardado de las redes y de la partida, y partidas viejas sin redes.
func _redes_guardado() -> void:
	## GUARDADO: ida y vuelta por JSON (con evento a medias, averías, aislados y gas) y partida vieja sin redes.
	var gd := RedesCiudad.new(33)
	gd.averias_azar = false
	gd.registrar_edificio("hospital", Vector3(550.0, 0, -110.0))
	gd.registrar_edificio("estadio", Vector3(0.0, 0, 0.0))
	gd.pasar(30, 6, 0.8, 9.0, "tormenta")
	gd.evento._empezar(gd)
	gd.evento.rearmar()
	gd.averiar("agua", Vector2i(4, 0))
	gd.edificios[1]["aislado"] = true
	gd.repostar(1, Vector2i(2, 2), 300.0)
	var vuelta := RedesCiudad.new(1)
	vuelta.desde_dic(JSON.parse_string(JSON.stringify(gd.a_dic())))
	vuelta.recibir_edificios([{"id": 0, "nombre": "H", "uso": "hospital", "pos": Vector3.ZERO, "sector": Vector2i(3, 1), "kw": 900, "m3h": 60, "generador": true, "aislado": false},
		{"id": 1, "nombre": "E", "uso": "estadio", "pos": Vector3.ZERO, "sector": Vector2i(2, 2), "kw": 1800, "m3h": 40, "generador": false, "aislado": false}])
	_comprobar(vuelta.horas == gd.horas and is_equal_approx(vuelta.agua_nivel, gd.agua_nivel) and vuelta.esta_averiado("agua", Vector2i(4, 0)), "el guardado devuelve el reloj, el depósito y las averías")
	_comprobar(vuelta.evento.activo == gd.evento.activo and vuelta.evento.rearmado and vuelta.evento.sectores == gd.evento.sectores, "y el evento del apagón a medias (con el disyuntor ya rearmado)")
	_comprobar(vuelta.edificios[1]["aislado"] and not vuelta.edificios[0]["aislado"] and is_equal_approx(float(vuelta.gas[1]), float(gd.gas[1])), "y los edificios aislados y las existencias de gas")
	_comprobar(vuelta.luz == gd.luz and vuelta.inundado == gd.inundado and vuelta.historial.size() == gd.historial.size(), "y la luz, las inundaciones y las curvas son las mismas")
	var vieja := RedesCiudad.new(5)
	vieja.desde_dic({})
	_comprobar(vieja.horas == 0 and is_equal_approx(vieja.fraccion_luz(), 1.0), "una partida vieja sin redes se queda con las redes nuevas")
	var mu := Mundo.new()
	mu.generar(["CHI"], 3131)
	mu.tomar_el_mando(mu.ligas[0].clubes[0].id)
	_comprobar(Partida.desde_instantanea(Partida.instantanea(mu)).redes_ciudad == null, "una partida sin redes pisadas se guarda y se carga sin ellas")
	mu.redes_ciudad = gd
	var mu2 := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(Partida.instantanea(mu))))
	_comprobar(mu2.redes_ciudad != null and mu2.redes_ciudad.horas == gd.horas and mu2.redes_ciudad.evento.activo, "la partida completa guarda y carga las redes")

## Depósito del coche (gasolina y aviso) y determinismo de las averías.
func _redes_coche_y_azar() -> void:
	## EL DEPÓSITO DEL COCHE: gasta con la distancia, no baja de 0 y se guarda con la vida del DT.
	var vd := VidaDT.new()
	_comprobar(is_equal_approx(vd.combustible, 45.0) and is_equal_approx(vd.fraccion_comb(), 1.0), "el coche sale con el depósito lleno (45 l)")
	vd.gastar_combustible(10000.0)
	_comprobar(is_equal_approx(vd.combustible, 40.0), "10 km gastan 5 l (0,5 l/km, decisión del dueño del 31-10)")
	vd.gastar_combustible(100000.0)
	_comprobar(is_zero_approx(vd.combustible), "el depósito no baja de cero")
	vd.combustible = 6.0
	vd.aviso_comb = 202645
	var vd2 := VidaDT.new()
	vd2.desde_dic(JSON.parse_string(JSON.stringify(vd.a_dic())))
	_comprobar(is_equal_approx(vd2.combustible, 6.0) and vd2.aviso_comb == 202645 and vd2.fraccion_comb() < 0.15, "la gasolina y el aviso semanal se guardan y se cargan")
	var vd3 := VidaDT.new()
	vd3.desde_dic({})
	_comprobar(is_equal_approx(vd3.combustible, 45.0), "una partida vieja sin gasolina empieza con el depósito lleno")
	## Determinista: misma semilla, mismas averías.
	var a1 := RedesCiudad.new(11)
	var a2 := RedesCiudad.new(11)
	a1.pasar(500, 6, 0.5, 0.0)
	a2.pasar(500, 6, 0.5, 0.0)
	_comprobar(a1.luz == a2.luz and a1.cortes == a2.cortes and a1.agua_nivel == a2.agua_nivel, "la misma semilla da las mismas averías")
	_comprobar(not a1.resumen().is_empty(), "el resumen cuenta las cuatro redes")
