extends "res://pruebas/banco/base.gd"
## [Capa 1/2 de `ciudad.gd`] _probar_ciudad, _probar_minijuegos, _probar_ciudad_grande, _probar_ciudad_animo, _probar_ciudad_b7, _probar_modulos … (+1)

func _probar_ciudad() -> void:
	_titulo("LA CIUDAD (terrenos, negocios, vecinos, permisos y seguridad)")
	var m := Mundo.new()
	m.generar(["CHI"], 3131)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ci := m.ciudad
	var mio := m.mi_club()
	mio.mover_saldo(200000000)

	## TERRENOS Y NEGOCIOS: sin el paño no hay negocio, y eso es lo que hace que
	## el centro comercial sea la joya y no otra compra mas.
	_comprobar(ci.terrenos.is_empty(), "no hay terrenos de entrada")
	_comprobar(ci.construir_negocio("comercial", mio) != "",
		"sin el solar del centro no se puede levantar el centro comercial")
	_comprobar(ci.comprar_terreno("centro", mio) == "", "se compra el solar del centro")
	_comprobar(ci.comprar_terreno("centro", mio) != "", "y no dos veces")
	_comprobar(ci.construir_negocio("comercial", mio) == "", "y ahora si se levanta el centro comercial")
	_comprobar(ci.tiene_negocio("comercial"), "queda operando")
	var renta := ci.renta_negocios(mio, 60)
	_linea("  el centro comercial renta %s por semana" % _dinero(renta))
	_comprobar(renta > 0, "y renta todas las semanas")
	## Los negocios sin terreno se pueden construir directamente.
	var socios0 := mio.socios
	_comprobar(ci.construir_negocio("escuela", mio) == "", "la escuela no necesita terreno")
	_comprobar(mio.socios > socios0, "y trae socios de verdad (%d -> %d)" % [socios0, mio.socios])
	var reh0 := m.obras.nivel("rehab")
	ci.comprar_terreno("periferia", mio)
	ci.construir_negocio("clinica", mio)
	_comprobar(m.obras.nivel("rehab") > reh0,
		"la clinica sube un nivel de rehabilitacion gratis (%d -> %d)" % [reh0, m.obras.nivel("rehab")])

	## CONCIERTOS Y CESPED: dinero hoy contra rendimiento el domingo.
	var caja0 := mio.saldo
	_comprobar(ci.cesped == 100, "el cesped empieza impecable")
	ci.arrendar_estadio(mio)
	_linea("  tras el concierto: caja +%s, cesped %d, vecinos %d" % [
		_dinero(mio.saldo - caja0), ci.cesped, ci.vecinos])
	_comprobar(mio.saldo > caja0, "el concierto llena la caja")
	_comprobar(ci.cesped < 100, "y destroza el campo")
	_comprobar(ci.conciertos == 1, "se cuenta")
	## Con el campo por debajo de 60 los jugadores pierden precision. Se fuerza.
	ci.cesped = 40
	_comprobar(ci.penalizacion_cesped() < 1.0,
		"con el cesped a %d los jugadores pierden precision (x%.3f)" % [ci.cesped, ci.penalizacion_cesped()])
	_comprobar(ci.arrendar_estadio(mio) != "", "y no se puede arrendar con el campo asi")
	_comprobar(ci.reparar_cesped(mio) == "", "se puede resembrar")
	_comprobar(ci.cesped == 100, "y queda como nuevo")
	_comprobar(is_equal_approx(ci.penalizacion_cesped(), 1.0), "sin penalizacion")

	## VECINOS Y PERMISO. Una gestion al mes.
	var vec0 := ci.vecinos
	_comprobar(ci.gestion_vecinal("entradas", mio) == "", "se puede hacer una gestion vecinal")
	_comprobar(ci.vecinos > vec0, "repartir entradas mejora la relacion (%d -> %d)" % [vec0, ci.vecinos])
	_comprobar(ci.gestion_vecinal("obra", mio) != "", "y solo cabe una gestion al mes")
	ci.mes()
	_comprobar(ci.gestion_vecinal("obra", mio) == "", "al mes siguiente vuelve a haber cupo")
	_comprobar(not ci.permiso_ok, "no hay permiso municipal de entrada")
	_comprobar(ci.pedir_permiso(mio) == "", "se puede solicitar")
	_comprobar(ci.pedir_permiso(mio) != "", "y no dos veces a la vez")
	_linea("  permiso en tramite: %d semanas, %d%% de probabilidad" % [
		int(ci.permiso["semanas"]), int(round(float(ci.permiso["prob"]) * 100.0))])
	for i in 10:
		ci.semana(mio, 60)
	_comprobar(ci.permiso.is_empty(), "a las diez semanas la solicitud ya se resolvio")

	## SEGURIDAD Y SANCIONES.
	var r0 := ci.riesgo_incidente(60, 0)
	ci.mejorar_seguridad("privada", mio)
	ci.mejorar_seguridad("camaras", mio)
	var r1 := ci.riesgo_incidente(60, 0)
	_linea("  riesgo de incidente: %.1f%% -> %.1f%% tras invertir en seguridad" % [r0 * 100.0, r1 * 100.0])
	_comprobar(r1 < r0, "pagar seguridad baja el riesgo de incidente")
	_comprobar(ci.riesgo_incidente(20, 90) > ci.riesgo_incidente(90, 0),
		"y el mal ambiente con funa lo sube")
	_comprobar(is_equal_approx(ci.factor_aforo(), 1.0), "sin sancion, el aforo es el normal")
	ci.sancionar("cerradas")
	_comprobar(is_equal_approx(ci.factor_aforo(), 0.0), "a puertas cerradas no entra un peso de taquilla")
	ci.sancionar("aforo")
	_comprobar(is_equal_approx(ci.factor_aforo(), 0.4), "y con aforo reducido entra el 40%")
	for i in 6:
		ci.semana(mio, 60)
	_comprobar(ci.sancion.is_empty(), "la sancion caduca sola")

	## SOSTENIBILIDAD Y SUBVENCION.
	_comprobar(ci.certificar(mio) != "", "no se certifica sin cubierta solar")
	ci.instalar_paneles(mio)
	ci.instalar_paneles(mio)
	_comprobar(ci.ahorro_energetico(mio) > 0, "los paneles ahorran de verdad cada semana")
	_comprobar(ci.certificar(mio) == "", "con dos niveles de paneles ya se puede certificar")
	var sub := ci.subvencion_anual(mio)
	_linea("  subvencion municipal estimada: %s (vecinos %d, negocios %d)" % [
		_dinero(sub), ci.vecinos, ci.negocios.size()])
	_comprobar(sub > 0, "y el municipio paga por el deporte de base")
	var caja1 := mio.saldo
	ci.cobrar_subvencion(mio)
	_comprobar(mio.saldo > caja1, "la subvencion entra en la caja al cerrar el año")

## LOS MINIJUEGOS (7-10-2026): tiros libres y trivia del club.
func _probar_minijuegos() -> void:
	_titulo("MINIJUEGOS: TIROS LIBRES Y TRIVIA DEL CLUB")
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.2) == "barrera", "potencia floja: barrera")
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.95) == "alto", "potencia pasada: por encima")
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.62) == "justo", "en el centro: con rosca")
	var h: Array[int] = [0, 0]
	_comprobar(MinijuegoTiroLibre.prob_atajada(0, h, "bueno") > MinijuegoTiroLibre.prob_atajada(0, [] as Array[int], "bueno"), "repetir zona: el portero se adelanta")
	var m := Mundo.new()
	m.generar(["CHI"], 21)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ps := TriviaClub.preguntas(m, rng)
	_comprobar(ps.size() >= 6, "%d preguntas de trivia con los datos de la partida" % ps.size())
	var bien := true
	for pr: Dictionary in ps:
		var ops: Array = pr["opciones"]
		if ops.size() < 3 or int(pr["correcta"]) < 0 or int(pr["correcta"]) >= ops.size():
			bien = false
	_comprobar(bien, "cada pregunta tiene opciones y la respuesta correcta está entre ellas")
	var c := m.mi_club()
	var cap := ""
	for j: Jugador in c.plantilla:
		if j.capitan:
			cap = j.nombre
	var ok_cap := true
	for pr2: Dictionary in ps:
		if String(pr2["q"]).contains("brazalete"):
			ok_cap = String(pr2["opciones"][int(pr2["correcta"])]) == cap
	_comprobar(ok_cap, "la respuesta del capitán es el capitán de verdad (%s)" % cap)

func _probar_ciudad_grande() -> void:
	_titulo("LA CIUDAD GRANDE: RED VIAL, SEMÁFOROS Y TRANSPORTE")
	var cb := CityBuilder.new()
	var e := CiudadExpansion.new(cb)
	e.armar_red()
	e.armar_bloques()
	e.armar_transporte()
	var lado := float(CiudadExpansion.K) * CiudadExpansion.CELDA * 2.0
	_comprobar(lado * lado >= 4.0 * 1200.0 * 1200.0, "la ciudad mide %d m de lado: más de 4 veces la superficie de antes" % int(lado))
	_comprobar(e.tramos.size() >= 900, "%d tramos de calle en la red" % e.tramos.size())
	var puentes := 0
	for t: Dictionary in e.tramos:
		if bool(t["puente"]):
			puentes += 1
	_comprobar(puentes >= 15, "%d tramos cruzan el río por puente" % puentes)
	_comprobar(e.cruces_semaforo.size() >= 40, "%d cruces con semáforo" % e.cruces_semaforo.size())
	## Marcas y aceras coherentes en los cruces (16-10-2026).
	var cruce_ca := Vector3(550, 0, -660)    ## calle (x=550) que cruza una avenida (z=-660)
	_comprobar(is_equal_approx(e.medio_cruce(cruce_ca, Vector3(0, 0, 1)), CiudadExpansion.ANCHO_AV * 0.5), "la calle sabe que la cruza una avenida de 24 m")
	_comprobar(e._fin_acera(cruce_ca, Vector3(0, 0, -1), Vector3(1, 0, 0), CiudadExpansion.ANCHO_CALLE, false) >= CiudadExpansion.ANCHO_AV * 0.5,
		"la acera de la calle no entra en la calzada de la avenida")
	var mal_rayas := 0
	for p: Vector3 in e.cruces_semaforo:
		for d: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			if e.ancho_brazo(p, d) > 0.0 and not e.es_puente(p, d) and e._libre_de_marcas(p, d) < e.linea_detencion(e.medio_cruce(p, d)):
				mal_rayas += 1
	_comprobar(mal_rayas == 0, "las rayas del centro no pisan cruces ni cebras (%d mal)" % mal_rayas)
	var camino := e.camino_entre(Vector2i(-12, -12), Vector2i(12, 12))
	_comprobar(camino.size() >= 25, "la red está conectada: de una esquina a la otra en %d cruces" % camino.size())
	var camino2 := e.camino_entre(Vector2i(-9, 0), Vector2i(9, 0))
	_comprobar(not camino2.is_empty(), "se cruza de la orilla oeste a la este (%d cruces)" % camino2.size())
	var en_rio := 0
	var usos := {}
	for bl: Dictionary in e.bloques:
		var r: Rect2 = bl["rect"]
		usos[bl["uso"]] = true
		if not (String(bl["uso"]) in ["rio", "puerto"]) and r.position.x < CityBuilder.RIO_X + 45.0 and r.end.x > CityBuilder.RIO_X - 45.0:
			en_rio += 1
	_comprobar(en_rio == 0, "ninguna manzana edificada encima del río")
	for u in ["ayuntamiento", "hospital", "comisaria", "bomberos", "escuela", "universidad", "estacion_central", "centro_comercial", "puerto", "casa_grande", "torres", "casas", "industrial"]:
		_comprobar(usos.has(u), "la ciudad tiene %s" % u)
	var est := 0
	for l: Dictionary in e.lineas_metro:
		est += (l["estaciones"] as Array).size()
	_comprobar(e.lineas_metro.size() == 2 and est >= 10, "metro: %d líneas, %d estaciones" % [e.lineas_metro.size(), est])
	## Las calles tienen nombre: en un cruce, las dos; dentro de una manzana, ninguno.
	var cruce := e.nombre_calle_en(Vector3(990.0, 0, -990.0))
	var en_fila := e.nombre_calle_en(Vector3(1045.0, 0, -988.0))
	var en_col := e.nombre_calle_en(Vector3(1100.0, 0, -940.0))
	var en_manzana := e.nombre_calle_en(Vector3(1045.0, 0, -935.0))
	_comprobar(cruce.contains(" con ") and en_fila.begins_with("Avenida") and en_col.begins_with("Calle") and en_manzana == "" and e.nombre_calle_en(Vector3.ZERO) == "",
		"nombres de calle: «%s» · «%s» · «%s»" % [cruce, en_fila, en_col])
	var paradas := 0
	for l: Dictionary in e.lineas_bus:
		paradas += (l["paradas"] as Array).size()
	_comprobar(paradas >= 10, "autobuses: %d paradas" % paradas)
	## El metro: un tren va, para en cada estación y da la vuelta en la cabecera.
	var est_metro := PackedFloat32Array([220.0, 550.0, 880.0, 1210.0, 1540.0, 1870.0, 2200.0])
	var tren := MetroCiudad.Tren.new(2420.0, est_metro, 300.0, 1.0)
	var dentro := true
	var giro := false
	for k in 6000:
		var antes := tren.sentido
		tren.simular(0.1)
		if tren.sentido != antes:
			giro = true
		if tren.s < -1.0 or tren.s > 2421.0:
			dentro = false
	_comprobar(tren.paradas_hechas >= 6, "el tren del metro paró en %d estaciones en 10 minutos" % tren.paradas_hechas)
	_comprobar(giro and dentro, "el tren da la vuelta en la cabecera sin salirse de la vía")
	## El modo a pie / al volante: choques y puentes.
	var obst: Array[Rect2] = [Rect2(100, 100, 50, 50)]
	_comprobar(not ExploradorCiudad.libre(Vector3(120, 0, 120), 1.0, obst), "no se atraviesa una manzana")
	_comprobar(ExploradorCiudad.libre(Vector3(200, 0, 200), 1.0, obst), "por la calle se pasa")
	_comprobar(not ExploradorCiudad.libre(Vector3(CityBuilder.RIO_X, 0, 55.0), 1.0, obst), "no se cae al río fuera de un puente")
	_comprobar(ExploradorCiudad.libre(Vector3(CityBuilder.RIO_X, 0, 0.0), 1.0, obst), "por el puente sí se cruza")
	_comprobar(ExploradorCiudad.altura_suelo(CityBuilder.RIO_X, 0.0) > 4.0 and ExploradorCiudad.altura_suelo(CityBuilder.RIO_X + 100.0, 0.0) < 0.5, "sobre el puente se va arriba y fuera de él, a ras de suelo")
	_comprobar(MinijuegosCiudad.juego_de("ciudad_plaza_mayor") == "autografos" and MinijuegosCiudad.juego_de("ciudad_puerto") == "pesca" and MinijuegosCiudad.juego_de("karting") == "karting", "cada lugar de la ciudad lleva su minijuego")
	## El circuito 3D del karting: el progreso medido sobre la trazada coincide
	## con la distancia recorrida, y la trazada está siempre sobre el asfalto.
	var mk := MinijuegosCiudad.new()
	var err := 0.0
	var fuera := 0.0
	for k in 200:
		var s_k := mk._largo_pista() * float(k) / 200.0
		var c: Dictionary = mk._centro_pista(s_k)
		err = maxf(err, absf(mk._progreso(c["p"]) - s_k))
		fuera = maxf(fuera, mk._fuera_de_eje(c["p"]))
	_comprobar(err < 0.05 and fuera < 0.01, "karting 3D: progreso exacto (error %.3f m) y trazada sobre el eje (%.3f m)" % [err, fuera])
	mk.free()
	var sem := Semaforos.new()
	var vistos := {}
	var cruzados := 0
	for k in 80:
		sem.t = float(k) * 0.5
		vistos["%s%s" % [sem.estado(0), sem.estado(1)]] = true
		if sem.verde(0) and sem.verde(1):
			cruzados += 1
	_comprobar(cruzados == 0, "nunca verde en los dos ejes a la vez")
	_comprobar(vistos.has("vr") and vistos.has("rv") and vistos.has("ar"), "el ciclo pasa por verde, ámbar y rojo en cada eje")
	sem.free()
	cb.free()

## FASE 5: la ciudad responde al club.
func _probar_ciudad_animo() -> void:
	_titulo("LA CIUDAD RESPONDE AL CLUB (FASE 5)")
	_comprobar(CiudadAnimo.evaluar(1, 16, 30, 30, 4, 5, 2, true)["estado"] == "euforia", "campeón → euforia")
	_comprobar(CiudadAnimo.evaluar(16, 16, 30, 30, -3, 5, 2, true)["estado"] == "crisis", "descendido → crisis")
	_comprobar(CiudadAnimo.evaluar(8, 16, 15, 30, 0, 5, 2, false)["estado"] == "normal", "mitad de tabla sin racha → normal")
	_comprobar(CiudadAnimo.evaluar(2, 16, 20, 30, 5, 5, 2, false)["estado"] in ["bien", "euforia"], "segundo con cinco victorias → buen ambiente")
	_comprobar(CiudadAnimo.evaluar(15, 16, 22, 30, -1, 5, 2, false)["valor"] <= -0.6, "en descenso a falta de un tercio: al menos «mal»")
	_comprobar(CiudadAnimo.evaluar(1, 16, 0, 30, 0, 0, 2, false)["estado"] == "normal", "antes de la 1.ª jornada: normal")
	var frentes: Array = []
	for i in 40:
		frentes.append(Rect2(float(i) * 12.0 - 240.0, 300.0, 10.0, 10.0))
	var raiz := Node3D.new()
	var e := CiudadAnimo.montar(raiz, {"estado": "euforia"}, frentes, Vector3(0, 0, -150), Color.RED, Color.WHITE)
	var raiz2 := Node3D.new()
	var c := CiudadAnimo.montar(raiz2, {"estado": "crisis"}, frentes, Vector3(0, 0, -150), Color.RED, Color.WHITE)
	_comprobar(int(e["pancartas"]) >= 35 and int(e["grafitis"]) == 0, "euforia: pancartas en las fachadas (%d), ningún grafiti" % e["pancartas"])
	_comprobar(int(c["persianas"]) >= 20 and int(c["grafitis"]) >= 10 and int(c["pancartas"]) == 0, "crisis: persianas (%d) y grafitis (%d), ninguna pancarta" % [c["persianas"], c["grafitis"]])
	raiz.free()
	raiz2.free()
	var m := Mundo.new()
	m.generar(["CHI"], 55)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for k in 6:
		m.avanzar_semana()
	var a := CiudadAnimo.de(m, m.mi_club())
	_comprobar(String(a["estado"]) in CiudadAnimo.ESTADOS and String(a["motivo"]) != "", "el ánimo sale del mundo real: %s (%s)" % [a["estado"], a["motivo"]])

## B7: la ciudad se puede tocar -cada instalación tiene su punto, lo que no
## existe es un solar-, las obras se ven con su grúa, y el día de partido trae
## gente y banderas. Construir desde el mapa cobra lo mismo que dice la ficha.
func _probar_ciudad_b7() -> void:
	_titulo("CIUDAD B7: SOLARES, OBRAS CON GRÚA, DÍA DE PARTIDO, FICHA Y CONSTRUIR")
	var m := Mundo.new()
	m.generar(["CHI"], 313)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = 900000000
	m.obras.niveles["gim"] = 2
	var antes := c.saldo
	var coste := m.obras.coste("piscina", c.rep)
	_comprobar(m.obras.iniciar("piscina", c) == "" and antes - c.saldo == coste, "construir cobra lo que anuncia la ficha (%d)" % coste)
	var datos := {
		"club": {"nombre": c.nombre, "c1": c.color1, "c2": c.color2, "cap": 30000, "rep": c.rep, "socios": c.socios, "estadioNom": "Estadio"},
		"inst": m.obras.niveles.duplicate(),
		"obras": [{"k": "piscina", "semanas": 4}],
		"terrenos": [], "negocios": {}, "perfil_estadio": {},
		"dia_partido": true, "vecinos": 30,
	}
	var cb := CityBuilder.new()
	add_child(cb)
	cb.build(datos)
	var por_k := {}
	for p: Dictionary in cb.puntos_clic:
		por_k[String(p["k"])] = String(p["estado"])
	_comprobar(por_k.size() >= CityBuilder.EDIFICIOS.size(), "cada instalación tiene su punto en el mapa (%d)" % por_k.size())
	_comprobar(por_k.get("gim", "") == "hecho" and por_k.get("piscina", "") == "obra" and por_k.get("video", "") == "solar",
		"hecho, en obra y solar se distinguen")
	_comprobar(cb.find_children("Grua", "Node3D", false, false).size() >= 1, "la obra tiene su grúa")
	_comprobar(cb.find_child("Hinchada", false, false) != null, "el día de partido hay gente")
	var rot: Node = cb.find_child("Rotulos", false, false)
	_comprobar(rot != null and rot.get_child_count() >= CityBuilder.EDIFICIOS.size(), "rótulos flotantes sobre cada parcela")
	var dentro := true
	for p: Dictionary in cb.puntos_clic:
		if String(p["estado"]) in ["hecho", "obra", "solar"] and (p["pos"] as Vector3).z > 250.0:
			dentro = false
	_comprobar(dentro, "ninguna parcela cae en la calle exterior (z=262)")
	cb.mostrar_rotulos(false)
	_comprobar(not rot.visible, "los rótulos se pueden ocultar")
	cb.queue_free()

func _probar_modulos() -> void:
	_titulo("PIEZAS MODULARES: RECICLAR, UNIR, SEPARAR Y GUARDAR")
	_comprobar(Modulos.listar("muebles").size() >= 100, "el kit de muebles tiene %d piezas en el catálogo común" % Modulos.listar("muebles").size())
	_comprobar(Modulos.listar("suburbano").has("suburbano/tree-large"), "las piezas de otros kits llevan el kit delante")
	var silla := Modulos.tomar("chairDesk")
	_comprobar(silla.has_meta("pieza") and silla.get_child(0).get_child_count() > 0, "una pieza sale con sus mallas")
	_comprobar(absf((silla.get_meta("escala") as Vector3).x - 2.0) < 0.01, "los muebles salen a medidas reales (×2)")
	Modulos.vaciar_reserva()
	Modulos.devolver(silla)
	_comprobar(Modulos.en_reserva("chairDesk") == 0, "una pieza teñida (silla de despacho) se guarda en su propio montón")
	var mesa := Modulos.tomar("desk")
	Modulos.devolver(mesa)
	_comprobar(Modulos.en_reserva("desk") == 1, "devuelta, la mesa espera en la reserva")
	var otra := Modulos.tomar("desk")
	_comprobar(otra == mesa and otra.visible and Modulos.en_reserva("desk") == 0, "y la siguiente que se pide es la misma, reciclada")
	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(otra)
	otra.position = Vector3(2, 0, 3)
	var lampara := Modulos.tomar("lampRoundFloor")
	raiz.add_child(lampara)
	lampara.position = Vector3(3, 0, 3)
	lampara.rotation.y = 1.0
	var c := Modulos.unir([otra, lampara], "Rincon")
	_comprobar(c.get_parent() == raiz and c.get_child_count() == 2, "unir: la mesa y la lámpara forman un conjunto")
	_comprobar(lampara.global_position.distance_to(Vector3(3, 0, 3)) < 0.01, "unir no mueve las piezas de su sitio (%s)" % str(lampara.global_position))
	var datos := Modulos.a_datos(c)
	_comprobar(datos.size() == 2 and String(datos[1]["pieza"]) == "lampRoundFloor", "el conjunto se guarda como datos")
	c.position += Vector3(10, 0, 0)
	var sueltas := Modulos.separar(c)
	_comprobar(sueltas.size() == 2 and sueltas[1].get_parent() == raiz and sueltas[1].global_position.distance_to(Vector3(13, 0, 3)) < 0.01, "separar: las piezas quedan sueltas donde estaban (movidas con el conjunto)")
	var copia := Modulos.de_datos(JSON.parse_string(JSON.stringify(datos)))
	_comprobar(copia.get_child_count() == 2 and absf((copia.get_child(1) as Node3D).rotation.y - 1.0) < 0.01, "y se rearma igual desde los datos guardados")
	var deco := EdificioClub.datos_deco("tele")
	_comprobar(deco.size() == 2 and float((deco[1]["p"] as Array)[1]) > 0.3, "la tele de la decoración va ENCIMA de su mueble")
	for k: String in EdificioClub.DECO_MODULAR:
		for d: Array in EdificioClub.DECO_MODULAR[k]:
			_comprobar(Modulos.existe(String(d[0])), "la pieza %s de «%s» existe" % [d[0], k])
	copia.free()
	raiz.free()
	Modulos.vaciar_reserva()

func _probar_faros_coches() -> void:
	_titulo("M-175: FAROS Y LUCES DE FRENO")
	var t := TraficoCiudad.new()
	add_child(t)
	var ruta := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0, 100), Vector3(50, 0, 100)]))
	var coche := Node3D.new()
	var caja := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.8, 1.4, 4.3)
	caja.mesh = bm
	caja.position.y = 0.7
	coche.add_child(caja)
	t.agregar_vehiculo(coche, ruta, 10.0, 12.0, 0.0, 0.0)
	t.faros(0.0)
	_comprobar(coche.get_node_or_null("Faros") == null, "de día no se crean faros")
	t.faros(0.9)
	var f := coche.get_node_or_null("Faros") as MeshInstance3D
	_comprobar(f != null and f.mesh != null and f.mesh.get_faces().size() == 24, "de noche cada coche lleva 4 luces en una sola malla")
	_comprobar(f != null and f.get_aabb().end.z > 2.1 and f.get_aabb().position.z < -2.1, "delante y detrás del coche (%s)" % (str(f.get_aabb()) if f != null else "-"))
	_comprobar(t._mat_faros != null and is_equal_approx(float(t._mat_faros.get_shader_parameter("noche")), 0.9), "el brillo sigue a la noche")
	## M-183: de madrugada hay menos gente por la calle.
	var gente: Array[Node3D] = []
	for k in 40:
		var pe := Node3D.new()
		t.agregar_vehiculo(pe, ruta, float(k) * 2.0, 1.4, 0.1, 0.0)
		gente.append(pe)
	t.faros(0.0)
	var de_dia := gente.filter(func(x: Node3D) -> bool: return x.visible).size()
	t.faros(1.0)
	var de_noche := gente.filter(func(x: Node3D) -> bool: return x.visible).size()
	_comprobar(de_dia == 40 and de_noche >= 8 and de_noche <= 20, "M-183: de día 40 por la calle, de madrugada %d" % de_noche)
	t.free()

## EL PARQUE LLENO (relleno de la ciudad): bancos, mesas de pícnic y papeleras sin tocar el azar.
func _probar_parque_lleno() -> void:
	_titulo("EL PARQUE LLENO (bancos, mesas de pícnic y papeleras sin tocar el azar)")
	var cb := CityBuilder.new()
	add_child(cb)
	var ex := CiudadExpansion.new(cb)
	var antes := ex._rng.state
	var hijos := cb.get_child_count()
	CiudadParque.rellenar(ex, Rect2(-60.0, -50.0, 120.0, 100.0), Vector3.ZERO)
	var nuevos := cb.get_child_count() - hijos
	_comprobar(nuevos >= 40, "un parque de 120 × 100 m recibe más de 40 piezas (bancos, mesas, sillas, comida y papeleras): %d" % nuevos)
	_comprobar(ex._rng.state == antes, "y no consume el azar de la ciudad")
	var cb2 := CityBuilder.new()
	add_child(cb2)
	var ex2 := CiudadExpansion.new(cb2)
	var h2 := cb2.get_child_count()
	CiudadParque.rellenar(ex2, Rect2(-60.0, -50.0, 120.0, 100.0), Vector3.ZERO)
	_comprobar(cb2.get_child_count() - h2 == nuevos, "dos parques iguales reciben lo mismo")
	var cb3 := CityBuilder.new()
	add_child(cb3)
	var ex3 := CiudadExpansion.new(cb3)
	var h3 := cb3.get_child_count()
	CiudadParque.rellenar(ex3, Rect2(-14.0, -14.0, 28.0, 28.0), Vector3.ZERO)
	_comprobar(cb3.get_child_count() - h3 < nuevos, "un parque pequeño recibe menos piezas")
	cb.queue_free()
	cb2.queue_free()
	cb3.queue_free()
