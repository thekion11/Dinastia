extends "res://pruebas/banco/partido_p5.gd"
## [Capa 6/6 de `partido.gd`] _probar_prorroga_y_penales, _probar_partido_abandonado

## PRÓRROGA Y PENALES (17-10-2026). Lo que no necesita el 3D: el acta que se
## alarga al 120' con un cambio más, la tanda del césped que `penales()` ya no
## vuelve a sortear (y la copa respeta), el reloj de la prórroga del motor y
## cuándo está decidida una tanda. La prueba con el partido entero en el
## césped es `pruebas/prueba_prorroga_penales.tscn`.
func _probar_prorroga_y_penales() -> void:
	_titulo("PRÓRROGA Y TANDA DE PENALES DEL MOTOR REAL")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)
	p.preparar()
	p.motor_externo = true
	while p.minuto < 89:
		p.simular_minuto()
	p.prorroga_externa()
	p.simular_minuto()
	_comprobar(not p.terminado_ya and p.minuto == 90 and p.minutos_fin == 120, "con prórroga el acta no termina en el 90'")
	_comprobar(p.MAX_CAMBIOS + p.cambios_extra == 6, "en la prórroga hay un cambio más")
	p.penales_externos(3, 4)
	while not p.terminado_ya:
		p.simular_minuto()
	_comprobar(p.minuto == 120, "el acta termina en el 120'")
	_comprobar(p.penales() == [3, 4] and p.penales() == [3, 4] and p.penales_en_cesped, "`penales()` devuelve la tanda del césped, siempre la misma")
	var copa := Copa.new("Copa de prueba")
	copa.vivos.assign([a, b])
	p.goles_local = 1
	p.goles_visita = 1
	var res := copa.jugar_ronda(p)
	_comprobar(not res.is_empty() and (res[0] as Dictionary)["pasa"] == b and (res[0] as Dictionary)["penales"] == [3, 4], "la copa clasifica al que ganó la tanda del césped")
	var p2 := Partido.new(a, b)
	p2.preparar()
	while not p2.terminado_ya:
		p2.simular_minuto()
	_comprobar(p2.minuto == 90 and not p2.penales_en_cesped, "sin motor ni prórroga: termina en el 90' como siempre")
	## El reloj del motor en la prórroga.
	var mo := MotorJugable.new()
	mo.duracion_mitad = 180.0
	mo.sortear_anadido()
	mo.mitad = 3
	mo.t = 30.0
	var m3 := mo.minuto()
	mo.mitad = 4
	mo.t = 59.0
	var m4 := mo.minuto()
	_comprobar(m3 == 97 and m4 == 119 and is_equal_approx(mo.dur_mitad(), 60.0), "prórroga de 15' (un tercio de la mitad): 97' y 119' (%d', %d')" % [m3, m4])
	_comprobar(mo.anadido.size() == 4 and mo._anadido_de(4) > 0.0, "la prórroga tiene su añadido")
	mo.free()
	_comprobar(MotorJugable.tanda_decidida([[true, true, true], [false, false, false]]), "tanda: 3-0 tras tres cada uno está decidida")
	_comprobar(not MotorJugable.tanda_decidida([[true, true, true, true, true], [true, true, true, true, true]]), "tanda: 5-5 sigue a muerte súbita")
	_comprobar(MotorJugable.tanda_decidida([[true, true, true, true, true, false], [true, true, true, true, true, true]]), "tanda: 5-6 en la muerte súbita está decidida")
	_comprobar(not MotorJugable.tanda_decidida([[true, true, true, true, true, true], [true, true, true, true, true]]), "tanda: en la muerte súbita el segundo aún tira")
	var circ := MarcadorTanda.circulos([true, false], 5)
	_comprobar(circ.count("●") == 2 and circ.count("○") == 3, "el marcador de la tanda pinta ●● y tres huecos")

## EL PARTIDO ABANDONADO A MEDIAS (17-10-2026): cerrar el juego perdiendo y
## volver a cargar NO repite el partido desde el 0-0, y recargar no cambia nada.
func _probar_partido_abandonado() -> void:
	_titulo("PARTIDO ABANDONADO A MEDIAS: NO SE PUEDE REPETIR HASTA GANAR")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	p.preparar()
	PartidoPendiente.abrir(m, p)
	p.goles_local = 0
	p.goles_visita = 2
	p.minuto = 60
	PartidoPendiente.actualizar(m, p)
	## La partida tal como quedó guardada (recargarla es partir siempre de aquí).
	var foto := Partida.instantanea(m)
	var d := PartidoPendiente.pendiente(m)
	_comprobar(not d.is_empty() and int(d["gv"]) == 2 and int(d["minuto"]) == 60, "el partido en curso queda apuntado con su marcador y su minuto")
	var r1 := PartidoPendiente.resolver(m, d)
	_comprobar(r1 != null and r1.terminado_ya and r1.goles_visita >= 2, "al cargar se completa desde el 0-2 del 60' (no desde 0-0): %d-%d" % [r1.goles_local, r1.goles_visita])
	_comprobar(PartidoPendiente.pendiente(m).is_empty(), "una vez resuelto, deja de estar pendiente")
	## Recargar = otra vez el mismo resultado (azar fijo para ese partido).
	var m2 := Partida.desde_instantanea(foto)
	var r2 := PartidoPendiente.resolver(m2, d)
	_comprobar(r2 != null and r2.goles_local == r1.goles_local and r2.goles_visita == r1.goles_visita, "recargar da el mismo resultado (%d-%d)" % [r2.goles_local, r2.goles_visita])
	d["minuto"] = 90
	var r3 := PartidoPendiente.resolver(m, d)
	_comprobar(r3 != null and r3.goles_local == 0 and r3.goles_visita == 2, "si ya se había pitado el final, queda el resultado tal cual")

## EL RECEPTOR SEGURO DE LOS SAQUES (03-11-2026, ciclo 11, `MotorSaque`, bandera SAQUE_SEGURO): banda y centro van al compañero más libre y cercano; apagado no cambia nada.
func _probar_saque_seguro() -> void:
	_titulo("RECEPTOR SEGURO EN SAQUES DE BANDA Y CENTRO")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var vis: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))
	for q: Dictionary in motor.jugadores:
		(q["node"] as Node3D).position = Vector3(-33.0, 0, -50.0 + randf())
	var sacador: Dictionary = locales[0]
	(sacador["node"] as Node3D).position = Vector3(30.0, 0, 0)
	var cerca_libre: Dictionary = locales[1]
	var cerca_tapado: Dictionary = locales[2]
	(cerca_libre["node"] as Node3D).position = Vector3(24.0, 0, 6.0)
	(cerca_tapado["node"] as Node3D).position = Vector3(22.0, 0, -7.0)
	(vis[0]["node"] as Node3D).position = Vector3(22.0, 0, -8.5)   ## encima del segundo
	var antes := MotorSaque._on
	MotorSaque._on = true
	var elegido := MotorSaque.receptor(motor, sacador, "banda")
	_comprobar(not elegido.is_empty() and String(elegido["id"]) == String(cerca_libre["id"]), "el saque de banda va al compañero libre, no al tapado")
	MotorSaque._on = false
	var apagado := MotorSaque.receptor(motor, sacador, "banda")
	_comprobar(apagado.is_empty() or bool(apagado["es_local"]), "apagado delega en el selector de siempre (devuelve un compañero)")
	MotorSaque._on = antes
	(r[1] as Node3D).queue_free()

## LOS COMPAÑEROS SE OFRECEN EN EL SAQUE DE BANDA (03-11-2026, ciclo 11, `MotorSaque.oferta`, bandera SAQUE_OFRECE): los dos más cercanos al lanzador se ofrecen hacia dentro; apagado = base.
func _probar_saque_ofrece() -> void:
	_titulo("LOS COMPAÑEROS SE OFRECEN EN EL SAQUE DE BANDA")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var locales: Array = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))
	var rival: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	var lugar := Vector3(motor.ANCHO, 0, 10.0)
	var lanzador: Dictionary = locales[0]
	motor.saque = {"tipo": "banda", "local": true, "lugar": lugar, "lanzador": lanzador}
	for i in locales.size():
		(locales[i]["node"] as Node3D).position = Vector3(lugar.x - 3.0 * i - 2.0, 0, lugar.z + 1.5 * i)
	var base := Vector3(1.0, 0, 2.0)
	var antes := MotorSaque._ofrece
	MotorSaque._ofrece = false
	_comprobar(MotorSaque.oferta(motor, locales[1], lugar, true, base) == base, "apagado devuelve la posición base")
	MotorSaque._ofrece = true
	var o1 := MotorSaque.oferta(motor, locales[1], lugar, true, base)
	var o2 := MotorSaque.oferta(motor, locales[2], lugar, true, base)
	_comprobar(o1 != base and o1.x < lugar.x and absf(o1.x - lugar.x) < 8.0, "el más cercano se ofrece corto, hacia dentro del campo (x %.1f)" % o1.x)
	_comprobar(o2 != base and o2.x < o1.x, "el segundo se ofrece más adentro y en diagonal (x %.1f)" % o2.x)
	_comprobar(MotorSaque.oferta(motor, locales[5], lugar, true, base) == base, "el tercero y los demás siguen con su base")
	_comprobar(MotorSaque.oferta(motor, rival, lugar, true, base) == base, "el equipo que no saca no se coloca por este sistema")
	_comprobar(MotorSaque.oferta(motor, lanzador, lugar, true, base) == base, "el lanzador no cambia")
	MotorSaque._ofrece = antes
	## (9-11, fallo del dueño) Saque de banda del USUARIO sin ningún compañero a 30 m: antes no salía nunca (juego parado).
	for k in locales.size():
		(locales[k]["node"] as Node3D).position = Vector3(-30.0, 0, -45.0 - 2.0 * k)
	(lanzador["node"] as Node3D).position = lugar
	motor.usuario = lanzador
	motor.estado = "saque"
	motor.apuntando = true
	motor.saque = {"tipo": "banda", "local": true, "lugar": lugar, "lanzador": lanzador}
	motor._receptor_marcado = {}
	motor._saque_banda_usuario()
	_comprobar(not motor._receptor_marcado.is_empty(), "saque de banda del usuario sin compañeros a 30 m: igual se marca un receptor lejano y se puede sacar")
	(r[1] as Node3D).queue_free()

## ENTRAR EN EL MOMENTO BUENO (03-11-2026, ciclo 12, `MotorEntrada`, bandera ENTRADA_MOMENTO): el radio de la entrada crece con el portador de espaldas, con control largo o en la banda.
func _probar_entrada_momento() -> void:
	_titulo("ENTRAR EN EL MOMENTO BUENO")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var victima: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	var def_: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	var nv := victima["node"] as Node3D
	nv.position = Vector3(0, 0, 0)
	(def_["node"] as Node3D).position = Vector3(0, 0, 2.0)   ## el defensa está en +z
	motor.balon.position = Vector3(0, 0.11, 0.3)
	var antes := MotorEntrada._on
	MotorEntrada._on = false
	_comprobar(MotorEntrada.radio(motor, def_, victima, 1.25) == 1.25, "apagado devuelve el radio base")
	MotorEntrada._on = true
	nv.rotation.y = 0.0   ## mira a +z: DE FRENTE al defensa
	_comprobar(MotorEntrada.radio(motor, def_, victima, 1.25) == 1.25, "de frente, con el balón en los pies y en el centro: radio base")
	nv.rotation.y = PI    ## mira a -z: DE ESPALDAS al defensa
	_comprobar(absf(MotorEntrada.radio(motor, def_, victima, 1.25) - (1.25 + MotorEntrada.ESPALDAS)) < 0.001, "de espaldas: radio + %.1f" % MotorEntrada.ESPALDAS)
	motor.balon.position = Vector3(0, 0.11, -1.5)   ## el balón se le ha ido
	_comprobar(absf(MotorEntrada.radio(motor, def_, victima, 1.25) - (1.25 + MotorEntrada.TOPE)) < 0.001, "de espaldas y con control largo: radio + tope %.1f" % MotorEntrada.TOPE)
	nv.rotation.y = 0.0
	motor.balon.position = Vector3(motor.ANCHO - 1.0, 0.11, 0.3)
	nv.position = Vector3(motor.ANCHO - 1.0, 0, 0)
	(def_["node"] as Node3D).position = Vector3(motor.ANCHO - 1.0, 0, 2.0)
	_comprobar(absf(MotorEntrada.radio(motor, def_, victima, 1.25) - (1.25 + MotorEntrada.BANDA)) < 0.001, "pegado a la banda: radio + %.1f" % MotorEntrada.BANDA)
	MotorEntrada._on = antes
	(r[1] as Node3D).queue_free()

## GEOMETRÍA DE LA INTERCEPCIÓN (03-11-2026, ciclo 14, `MotorTraza.cortar`): distancia perpendicular del cortador a la línea del pase y tiempo de vuelo; solo cuenta.
func _probar_traza_corte() -> void:
	_titulo("TRAZA DE LA INTERCEPCIÓN: DISTANCIA Y TIEMPO")
	var r := _motor_de_prueba()
	var motor: MotorJugable = r[0]
	var rival: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	motor.diag = {}
	motor.set_meta("_traza_geo", {"t": 10.0, "a": Vector3(0, 0, 0), "b": Vector3(0, 0, 20.0), "rivales": {String(rival["id"]): Vector3(5.0, 0, 10.0)}})
	motor.t = 11.5
	MotorTraza.cortar(motor, rival)
	_comprobar(int(motor.diag.get("traza_corte_perp_corriendo", 0)) == 1, "un defensa a 5 m de la línea tuvo que correr («corriendo»)")
	_comprobar(int(motor.diag.get("traza_corte_t_lento", 0)) == 1, "un corte a 1,5 s del pase es «lento»")
	motor.set_meta("_traza_geo", {"t": 20.0, "a": Vector3(0, 0, 0), "b": Vector3(0, 0, 20.0), "rivales": {String(rival["id"]): Vector3(0.5, 0, 8.0)}})
	motor.t = 20.2
	MotorTraza.cortar(motor, rival)
	_comprobar(int(motor.diag.get("traza_corte_perp_en_linea", 0)) == 1, "un defensa a 0,5 m de la línea estaba «en_linea»")
	_comprobar(int(motor.diag.get("traza_corte_t_rapido", 0)) == 1, "un corte a 0,2 s del pase es «rapido» (sin tiempo de reacción)")
	(r[1] as Node3D).queue_free()

## EL MOTOR A CIEGAS (11-11, sesión 11): el selector A/B/C reparte los tres motores sin decir cuál es cuál, por defecto sigue el de siempre,
## el voto se guarda con el motor real y el combinado con todas las piezas «siempre» juega EXACTAMENTE como el de siempre.
func _probar_motor_ciego() -> void:
	_titulo("PARTIDO: MOTOR A CIEGAS (A/B/C) Y COMBINADO")
	var ruta0 := MotorEleccion.ruta
	MotorEleccion.ruta = "user://motor_ciego_prueba.json"
	MotorEleccion.reiniciar(true)
	_comprobar(MotorEleccion.seleccion() == "" and MotorEleccion.motor_activo() == "siempre" and not MotorEleccion.a_ciegas(), "por defecto no hay letra y el motor es el de siempre")
	_comprobar(MotorFabrica.crear().get_meta("motor_id") == "siempre" and not MotorFabrica.crear() is MotorLeague, "la fábrica da el de siempre por defecto")
	MotorEleccion.barajar(7)
	var o: Array = MotorEleccion.orden().duplicate()
	var o2: Array = o.duplicate()
	o2.sort()
	var ref: Array = MotorEleccion.MOTORES.duplicate()
	ref.sort()
	_comprobar(o2 == ref, "el reparto A-D es una permutación de los cuatro motores (%s)" % str(o))
	MotorEleccion.barajar(7)
	_comprobar(MotorEleccion.orden() == o, "con la misma semilla el reparto es el mismo")
	MotorEleccion.elegir("B")
	_comprobar(MotorEleccion.motor_activo() == o[1] and MotorEleccion.letra_de(String(o[1])) == "B" and MotorEleccion.a_ciegas(), "elegir B juega el motor que le tocó a B")
	var motores_ok := true
	for k in MotorEleccion.LETRAS.size():
		MotorEleccion.elegir(MotorEleccion.LETRAS[k])
		var mo: MotorJugable = MotorFabrica.crear()
		motores_ok = motores_ok and String(mo.get_meta("motor_id")) == String(o[k]) and (mo is MotorCombinado) == String(o[k]).begins_with("combinado") and (mo is MotorLeague) == (o[k] != "siempre")
		mo.free()
	_comprobar(motores_ok, "cada letra crea el motor que le toca (siempre, League o un combinado)")
	var c2 := MotorFabrica.crear("combinado_c2") as MotorCombinado
	var c3 := MotorFabrica.crear("combinado_c3") as MotorCombinado
	_comprobar(c2.piezas["locomocion"] == "siempre" and c2.piezas["decide_con_balon"] == "siempre" and c2.piezas["coloca_sin_balon"] == "league" and c3.piezas["coloca_sin_balon"] == "siempre" and c3.piezas["locomocion"] == "league", "C2 = C1 + locomoción nuestra y C3 = C1 + colocación nuestra")
	_comprobar(c3.cadencia_coloca == 0.1 and c3._cache_col.is_empty(), "C3 recalcula la colocación cada 0,1 s por jugador (caché vacía al empezar)")
	var c4 := MotorFabrica.crear("combinado_c4") as MotorCombinado
	_comprobar(c4.piezas["locomocion"] == "siempre" and c4.piezas["coloca_sin_balon"] == "siempre" and c4.piezas["decide_con_balon"] == "siempre" and c4.piezas["fisica_balon"] == "league" and MotorEleccion.MOTORES.size() == 4 and not MotorEleccion.MOTORES.has("combinado_c2"), "C4 = decide + colocación + locomoción nuestras; el selector de Ajustes solo ofrece 4 letras (sin C2 ni C3)")
	c4.free()
	c2.free()
	c3.free()
	MotorEleccion.elegir("C")
	MotorEleccion.revelar()
	MotorEleccion.votar(4, "league", {"marcador": "2-1"})
	MotorEleccion.votar(2, "league")
	MotorEleccion.votar(5, "siempre")
	MotorEleccion.reiniciar()
	var rv := MotorEleccion.resumen_votos()
	_comprobar(MotorEleccion.revelado() and MotorEleccion.seleccion() == "C" and int(rv["league"]["votos"]) == 2 and is_equal_approx(float(rv["league"]["media"]), 3.0) and int(rv["siempre"]["votos"]) == 1 and int(rv["combinado"]["votos"]) == 0, "la letra, la revelación y los votos (con el motor real) sobreviven al reinicio")
	MotorEleccion.reiniciar(true)
	MotorEleccion.ruta = ruta0
	MotorEleccion.reiniciar()
	## Combinado = League por defecto; con TODAS las piezas «siempre» juega igual que el de siempre (mismo balón, pases y tiros en 20 s).
	var mu := Mundo.new()
	mu.generar(["CHI", "BRA"], 99)
	var res := []
	for cual in ["siempre", "combinado"]:
		var raiz := Node3D.new()
		add_child(raiz)
		var sp := PlayerSpawner.new()
		var lista: Array = []
		var a: Club = mu.ligas[0].clubes[1]
		var b: Club = mu.ligas[mu.ligas.size() - 1].clubes[4]
		var l := Puente3D.once(a.once())
		var v := Puente3D.once(b.once())
		lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
		lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
		var mo := MotorFabrica.crear(cual)
		raiz.add_child(mo)
		mo.set_physics_process(false)
		mo.autopiloto = true
		if mo is MotorCombinado:
			for k: String in MotorCombinado.PIEZAS:
				(mo as MotorCombinado).piezas[k] = "siempre"
			(mo as MotorCombinado).cadencia_coloca = 0.0   ## la caché de 0,1 s cambia el detalle: sin ella, igual que el de siempre
		var bola := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
		mo.preparar(lista, bola, "", 5)
		for i in 600:
			mo.paso(1.0 / 30.0)
		res.append("%.3f,%.3f|%d|%d|%d" % [bola.position.x, bola.position.z, mo.pases[0] + mo.pases[1], mo.tiros[0] + mo.tiros[1], mo.regates_ia])
		raiz.queue_free()
	_comprobar(res[0] == res[1], "el combinado con todas las piezas «siempre» (sin caché de colocación) es el de siempre (%s | %s)" % [res[0], res[1]])
	var c := MotorCombinado.new()
	_comprobar(c.piezas == {"decide_con_balon": "siempre", "coloca_sin_balon": "league", "fisica_balon": "league", "locomocion": "league"}, "el combinado arranca como League con nuestra decisión con balón (y no es igual a League)")
	c.free()
