extends BaseIdea
## EL PORTERO EN LA CARRERA DE JUGADOR (25-10-2026, prefijo cpor). Se puede crear un portero: atributos de
## portero, focos de entreno propios, nota por paradas y lo que encaja (no por goles), porterías a cero y sus
## eventos. En el partido, el bloque «tiro que viene» de `_ia_portero` vive en `_reaccion_portero`: la IA
## sigue igual; el usuario elige el lado con el stick (si se tira al otro lado no llega, y si no actúa la
## reacción automática es más floja).

func _probar() -> void:
	_titulo("CARRERA: se puede jugar de PORTERO")
	_carrera()
	_titulo("PARTIDO: la estirada del portero que manejas")
	_partido()
	_titulo("CAMBIO DE PORTERO: solo por portero; entra por lesión o roja")
	_cambios()
	_titulo("TANDA: tu portero elige el lado")
	_tanda()

func _carrera() -> void:
	_comprobar(CarreraJugador.PUESTOS.has("POR"), "«POR» está entre los puestos elegibles")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var c := CarreraJugador.crear(m, "Prueba Portero", "POR", false, 99)
	var j := c.jugador(m)
	_comprobar(j != null and j.es_portero() and j.pos == "POR", "el creado es portero (grupo %s)" % (j.pos if j != null else "?"))
	for k: String in ["div", "ref", "par", "pos", "saq"]:
		_comprobar(j.atributos.has(k), "tiene el atributo de portero «%s»" % k)
	_comprobar(not j.atributos.has("tir"), "no tiene atributos de campo (tir)")
	_comprobar(j.ovr >= 50 and j.ovr <= 75, "media de portero razonable (%d)" % j.ovr)
	_comprobar(c.foco == "estirada", "su foco de partida es de portero (%s)" % c.foco)
	var focos := CarreraPortero.focos_para(j)
	_comprobar(focos.has("reflejos") and not focos.has("tiro"), "sus focos son de portero, sin «tiro»")
	## Entrenar sube atributos de portero (nunca crea uno de campo).
	var antes := 0
	for k: String in ["div", "ref", "par", "pos", "saq"]:
		antes += int(j.atributos[k])
	for f: String in ["estirada", "reflejos", "blocaje", "colocacion"]:
		c.foco = f
		for i in 4:
			c.energia = 100
			c.entrenar(m)
	var despues := 0
	for k: String in ["div", "ref", "par", "pos", "saq"]:
		despues += int(j.atributos[k])
	_comprobar(despues > antes and not j.atributos.has("tir"), "entrenar sube sus atributos de portero (%d -> %d)" % [antes, despues])
	## Una partida vieja con un foco de campo no rompe nada: entrena uno de portero.
	c.foco = "tiro"
	c.energia = 100
	var aviso := c.entrenar(m)
	_comprobar(aviso != "" and not j.atributos.has("tir"), "foco de campo en un portero: entrena uno suyo («%s»)" % aviso)
	## Nota simulada por lo que encaja, no por goles.
	_comprobar(CarreraPortero.nota_simulada(j, 0, 0.0) > CarreraPortero.nota_simulada(j, 3, 0.0), "a cero, mejor nota que con 3 encajados")
	## Porterías a cero, eventos y guardado.
	c.tras_partido(m, {"minutos": 90, "goles": 0, "asist": 0, "nota": 7.4, "titular": true, "paradas": 4, "encajados": 0})
	c.tras_partido(m, {"minutos": 90, "goles": 0, "asist": 0, "nota": 5.8, "titular": true, "paradas": 1, "encajados": 2})
	c.tras_partido(m, {"minutos": 30, "goles": 0, "asist": 0, "nota": 6.0, "titular": false, "encajados": 0})
	_comprobar(c.vallas_invictas == 1, "cuenta las porterías a cero con una hora jugada (%d)" % c.vallas_invictas)
	var ids := c._eventos_posibles(m, j).map(func(e: Dictionary) -> String: return String(e["id"]))
	_comprobar(ids.has("primera_valla") and not ids.has("penales") and not ids.has("faltas"), "evento «primera portería a cero», sin los de lanzador")
	var c2 := CarreraJugador.desde_dic(c.a_dic())
	_comprobar(c2.vallas_invictas == 1 and c2.foco == c.foco, "se guarda y se carga")
	## El portero suplente entra poco: solo si el titular se lesiona (~6 %).
	var entra := 0
	var raros := 0
	for i in 500:
		var mi := c.minuto_entrada_suplente(true)
		entra += 1 if mi >= 0 else 0
		raros += 1 if mi != -1 and (mi < 15 or mi > 85) else 0
	_comprobar(entra >= 10 and entra <= 60 and raros == 0, "el portero suplente entra a veces, por lesión (%d de 500)" % entra)
	_comprobar(CarreraJugador.desde_dic({}).vallas_invictas == 0, "partidas viejas: 0 porterías a cero")
	## El jugador de campo, como siempre.
	var cd := CarreraJugador.crear(m, "Prueba Delantero", "DC", false, 98)
	var jd := cd.jugador(m)
	_comprobar(cd.foco == "tiro" and CarreraPortero.focos_para(jd) == CarreraJugador.FOCOS and jd.atributos.has("tir"), "el delantero sigue con sus focos y atributos")
	_comprobar(CarreraPortero.eventos(cd, jd).is_empty(), "al de campo no le salen eventos de portero")

func _partido() -> void:
	var r := _motor()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var gk: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]) and bool(p["es_local"]):
			gk = p
	_comprobar(not gk.is_empty(), "hay portero local")
	motor.estado = "juego"
	motor.autopiloto = false
	motor.usuario = gk
	## Sin tocar el stick y con tiempo: espera (no gasta la decisión del tiro).
	_tiro(motor, gk, -30.0)
	_comprobar(not motor._reaccion_portero(gk, true, 0.0) and int(gk.get("_patada_vista", -1)) != motor._n_patada,
		"sin elegir lado y con tiempo, espera (no gasta la decisión)")
	## Elegir el lado bueno para más que no actuar; el lado malo, nunca.
	var bueno := _paradas(motor, gk, 1.0)
	var quieto := _paradas(motor, gk, 0.0)
	var malo := _paradas(motor, gk, -1.0)
	_linea("  (de 200: lado bueno %d, sin actuar %d, lado malo %d)" % [bueno, quieto, malo])
	_comprobar(bueno > quieto, "elegir el lado bueno para más que no actuar (%d > %d)" % [bueno, quieto])
	_comprobar(quieto > 0, "sin actuar, la reacción automática para alguna (%d)" % quieto)
	_comprobar(malo == 0, "tirarse al otro lado no para ninguna (%d)" % malo)
	## La IA del portero sigue con su bloque de siempre (manual = false).
	var ia := 0
	for i in 200:
		_tiro(motor, gk, -44.5)
		if motor._reaccion_portero(gk) and not motor._tiro_vivo.has("p"):
			ia += 1
	_comprobar(ia > 0, "la IA del portero sigue parando (%d de 200)" % ia)
	## La nota del portero: paradas y goles encajados, no los goles marcados.
	motor.stats["paradas"] = 0
	motor.goles = [0, 0]
	var base := motor.nota_usuario()
	motor.stats["paradas"] = 4
	var con_paradas := motor.nota_usuario()
	motor.goles = [0, 3]
	var goleado := motor.nota_usuario()
	_comprobar(con_paradas > base and goleado < con_paradas, "nota por paradas (%.1f -> %.1f) y baja al encajar (%.1f)" % [base, con_paradas, goleado])
	## Un rato de partido con el portero en manos del usuario no rompe nada.
	motor.stats["paradas"] = 0
	motor.goles = [0, 0]
	motor._saque_de_centro(true)
	for i in 600:
		motor.paso(1.0 / 30.0)
	_comprobar(motor.pos(gk).distance_to(motor._arco_propio(gk)) < 20.0, "quieto, el portero se coloca bajo su arco (a %.1f m)" % motor.pos(gk).distance_to(motor._arco_propio(gk)))
	raiz.queue_free()

## Un tiro desde `z0` al palo derecho (x = +1,5 visto desde el arco local en -Z), a media altura.
func _tiro(motor: MotorJugable, gk: Dictionary, z0: float) -> void:
	motor.estado = "juego"
	motor.poseedor = {}
	motor._tiro_vivo = {}
	motor._n_patada += 1
	gk["_patada_vista"] = -1
	gk["gesto_hasta"] = 0.0
	(gk["node"] as Node3D).position = Vector3(0, 0, -51.0)
	gk["vel"] = Vector3.ZERO
	var tg := (-51.0 - z0) / -25.0
	motor.balon.position = Vector3(0, 0.5, z0)
	motor.vel_balon = Vector3(1.5 / tg, (0.5 + 0.5 * MotorJugable.G * tg * tg) / tg, -25.0)

## Cuántas de 200 para con el tiro a 13 m (medio segundo: cuando el automático ya no espera) eligiendo `guia`.
func _paradas(motor: MotorJugable, gk: Dictionary, guia: float) -> int:
	var n := 0
	for i in 200:
		_tiro(motor, gk, -38.5)
		var antes := int(motor.stats["paradas"])
		motor._reaccion_portero(gk, true, guia)
		if int(motor.stats["paradas"]) > antes:
			n += 1
	return n

func _cambios() -> void:
	## Titular el de campo: su cambio nunca deja fuera al portero.
	var r := _motor()
	var motor: MotorJugable = r[0]
	var gk := _portero(motor, true)
	var campo := _suplente(r, false)
	motor.poner_extra(campo, false)
	_comprobar(not bool(campo["por"]) and not bool(motor._quien_sale_por(campo)["por"]), "un suplente de campo sale por uno de campo")
	(r[1] as Node3D).queue_free()
	## Un portero suplente sigue siendo portero y solo sale por el portero.
	r = _motor()
	motor = r[0]
	gk = _portero(motor, true)
	var sup := _suplente(r, true)
	motor.poner_extra(sup, false)
	_comprobar(bool(sup["por"]), "el portero que espera en la banda sigue siendo portero")
	_comprobar(motor._quien_sale_por(sup) == gk, "un portero solo cambia por el portero")
	## Expulsan al portero: entra el suplente bajo palos por uno de campo.
	motor._expulsar(gk)
	var locales := motor.jugadores.filter(func(q: Dictionary) -> bool: return bool(q["es_local"]))
	var pors := locales.filter(func(q: Dictionary) -> bool: return bool(q["por"]))
	_comprobar(motor.jugadores.has(sup) and pors.size() == 1 and pors[0] == sup, "roja al portero: entra el suplente bajo palos")
	_comprobar(locales.size() == 10 and String(sup["slot_code"]) == "POR", "y el equipo sigue con uno menos (%d) con el suplente de POR" % locales.size())
	(r[1] as Node3D).queue_free()
	## CARRERA, suplente: entras en tu minuto porque el titular se lesiona.
	r = _motor()
	motor = r[0]
	gk = _portero(motor, true)
	sup = _suplente(r, true)
	motor.usuario = {}
	motor.autopiloto = false
	motor.poner_extra(sup, true, 3)
	var pasos := 0
	while motor.usuario.is_empty() and motor.estado != "fin" and pasos < 20 * 600:
		motor.paso(1.0 / 20.0)
		pasos += 1
	_comprobar(motor.usuario == sup and bool(sup["por"]) and not motor.jugadores.has(gk), "suplente: entras de portero por el titular (min %d)" % motor.minuto())
	(r[1] as Node3D).queue_free()
	## CARRERA, suplente: si expulsan al titular estando tú en la banda, entras ya.
	r = _motor()
	motor = r[0]
	gk = _portero(motor, true)
	sup = _suplente(r, true)
	motor.usuario = {}
	motor.poner_extra(sup, true, 80)
	motor._expulsar(gk)
	_comprobar(motor.usuario == sup and motor.jugadores.has(sup), "suplente: roja al titular y entras tú")
	(r[1] as Node3D).queue_free()
	## Titular: el DT no cambia a su portero con una noche normal; goleado, puede.
	_comprobar(MotorCambioPortero.prob_dt_portero(6.0, 0.0) == 0.0 and MotorCambioPortero.prob_dt_portero(4.2, 0.0) > 0.2, "el DT solo cambia al portero si lo golean")
	r = _motor()
	motor = r[0]
	gk = _portero(motor, true)
	sup = _suplente(r, true)
	motor.usuario = gk
	motor.autopiloto = false
	motor.poner_extra(sup, false)
	motor.prob_cambio_extra = 1.0
	motor.t = motor.duracion_mitad * 1.4
	motor.mitad = 2
	motor._revisar_cambio(true)
	_comprobar(motor.usuario_sustituido and motor.jugadores.has(sup) and not motor.jugadores.has(gk), "titular: si el DT te cambia, entra el portero suplente")
	(r[1] as Node3D).queue_free()

func _tanda() -> void:
	var r := _motor()
	var motor: MotorJugable = r[0]
	var gk := _portero(motor, true)
	motor.id_usuario = String(gk["id"])
	motor.autopiloto = false
	motor._empezar_tanda()
	var vistos := 0
	var respetado := 0
	var ajenos_mios := 0
	for i in 12:
		motor._siguiente_penal()
		if motor.tanda["portero"] != gk:
			ajenos_mios += 1 if motor.tanda_me_toca_parar() else 0
			(motor.tanda["tiros"][motor.tanda_turno()] as Array).append(true)
			continue
		vistos += 1
		motor.tanda["lado"] = -1
		motor._tras_tiro_tanda()
		respetado += 1 if int(motor.tanda["lado"]) == -1 else 0
		(motor.tanda["tiros"][motor.tanda_turno()] as Array).append(false)
	_comprobar(ajenos_mios == 0, "los penales que para el otro portero no son tuyos")
	_comprobar(vistos >= 4 and respetado == vistos, "en la tanda tu portero va al lado que eliges (%d de %d)" % [respetado, vistos])
	## Con el partido simulado (piloto automático), adivina la IA.
	motor.autopiloto = true
	var ia_distinto := 0
	for i in 40:
		motor.tanda["portero"] = gk
		motor.tanda["lado"] = -1
		motor._tras_tiro_tanda()
		ia_distinto += 1 if int(motor.tanda["lado"]) != -1 else 0
	_comprobar(ia_distinto > 0, "en piloto automático elige la IA (%d de 40 a otro lado)" % ia_distinto)
	(r[1] as Node3D).queue_free()

func _portero(motor: MotorJugable, local: bool) -> Dictionary:
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]) and bool(p["es_local"]) == local:
			return p
	return {}

## Un suplente del club local (portero o de campo), puesto en el campo como lo hace `PartidoJugable`.
func _suplente(r: Array, portero: bool) -> Dictionary:
	var a: Club = r[2]
	var once := a.once()
	var quien: Jugador = null
	for j: Jugador in a.plantilla:
		if not once.has(j) and j.es_portero() == portero:
			quien = j
	var una := Puente3D.once([quien] as Array[Jugador])
	var h := PlayerSpawner.new().spawn_team(r[1], una["xi"], una["jugadores"], {"s": [[quien.pos_e, 50, 50]]}, true, Puente3D.kit(a), Puente3D.kit_portero(a))
	return h[0]

func _motor() -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", 7)
	return [motor, raiz, a]
