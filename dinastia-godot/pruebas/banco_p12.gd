extends "res://pruebas/banco_p12_p1.gd"
## (Parte 2 de 2 de `banco_p12.gd`.)

## Tramo 2 de 2 de `_probar_guardado` (la norma de 450 líneas la troceó).
func _probar_guardado_2(m: Mundo, v_rp) -> Array:
	if v_rp != null:
		var plantel_rp := m.mi_club().plantilla.duplicate()
		plantel_rp.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var crack: Jugador = plantel_rp[0]
		var suplente: Jugador = plantel_rp[plantel_rp.size() - 1]
		_comprobar(not bool(v_rp.acepta_rol(crack, "prescindible")["ok"]),
			"el mejor del plantel no acepta ser prescindible")
		_comprobar(not bool(v_rp.acepta_rol(suplente, "intocable")["ok"]),
			"al ultimo del plantel no le puedes prometer ser intocable")
		## Y bajarle el escalafon a alguien duele en la moral EN EL ACTO, que es
		## lo que el motor lee cada minuto de partido.
		v_rp.fijar_rol(crack, "intocable")
		var moral_antes := crack.moral
		var res_rp: Dictionary = v_rp.cambiar_rol(crack, "titular")
		_linea("  rol: %s de intocable a titular -> %s (moral %d -> %d)" % [
			crack.nombre, String(res_rp.get("txt", "")), moral_antes, crack.moral])
		_comprobar(bool(res_rp["ok"]) and crack.moral < moral_antes,
			"rebajarle el papel a un crack le cuesta moral")
		_comprobar(v_rp.rol_plantel(crack) == "titular", "y el papel nuevo queda escrito")

	## EL ARBOL DEL ENTRENADOR: igual que los roles, estaba escrito y sin
	## pantalla. Lo que hay que demostrar es la CADENA -requisito, coste, y que
	## el nodo abierto llega al equipo-, no que la tabla exista.
	var e_dt := m.entrenamiento
	if e_dt != null:
		var nodos_antes := e_dt.dt_nodos.duplicate()
		var pts_antes := e_dt.dt_puntos
		var ramas := e_dt.dt_ramas()
		_comprobar(ramas.size() >= 3, "el arbol del DT tiene ramas (%d)" % ramas.size())
		## Un nodo con requisito no se puede abrir sin el padre, por muchos
		## puntos que tengas: si esto falla, el arbol es una lista plana.
		var con_req := ""
		for rama: String in ramas:
			for k: String in (ramas[rama] as Array):
				if con_req == "" and e_dt.dt_requisito(k) != "" and not e_dt.dt_tiene(k):
					con_req = k
		if con_req != "":
			e_dt.dt_nodos.erase(e_dt.dt_requisito(con_req))
			e_dt.dt_puntos = 99
			_comprobar(e_dt.dt_aprender(con_req) != "",
				"sin el nodo padre no se puede abrir el hijo aunque sobren puntos")
			_comprobar(e_dt.dt_motivo(con_req).begins_with("antes:"),
				"y el motivo lo dice: %s" % e_dt.dt_motivo(con_req))
			## Con el padre puesto sí, y el coste se cobra de verdad.
			e_dt.dt_nodos[e_dt.dt_requisito(con_req)] = true
			var coste := e_dt.dt_coste(con_req)
			e_dt.dt_puntos = coste
			_comprobar(e_dt.dt_aprender(con_req) == "", "con el padre puesto y los puntos justos, se abre")
			_comprobar(e_dt.dt_puntos == 0, "y el coste se cobra (%d puntos gastados)" % coste)
		## Y el efecto llega al partido: "genio" reemplaza a "pizarra fina", no
		## se suman, asi que el 6% ya incluye el 3%.
		e_dt.dt_nodos.clear()
		var pelado := e_dt.bonus_dt()
		e_dt.dt_nodos["genio"] = true
		var con_genio := e_dt.bonus_dt()
		_linea("  arbol DT: sin nodos x%.3f, con genio x%.3f" % [pelado, con_genio])
		_comprobar(con_genio > pelado, "abrir el nodo del banquillo mejora al equipo de verdad")
		e_dt.dt_nodos = nodos_antes
		e_dt.dt_puntos = pts_antes

	## EL SALON DE LA FAMA (`vMemoria()`): no es una lista guardada, se deduce de
	## los records. Lo que se comprueba es el ORDEN -que estar en el once de un
	## titulo pese mas que una temporada goleadora-, porque es la unica decision
	## de diseno que hay aqui; si se invierte, la pantalla miente sin fallar.
	var lg_f := m.logros
	var goles_antes: Dictionary = lg_f.rec.get("goles", {})
	var pj_antes: Dictionary = lg_f.rec.get("pj", {})
	var muro_antes := lg_f.muro.duplicate(true)
	## OJO con la forma: `rec["goles"]` va por NOMBRE, pero `rec["pj"]` va por ID
	## y guarda {nombre, n}. No son simetricas, y escribirlas mal aqui reventaba
	## `mas_partidos()` sin que el banco lo notase.
	lg_f.rec["goles"] = {"Goleador": 30, "Capitan": 4}
	lg_f.rec["pj"] = {"g1": {"nombre": "Goleador", "n": 60}, "c1": {"nombre": "Capitan", "n": 200}}
	lg_f.muro = [{"once": ["Capitan"]}, {"once": ["Capitan"]}]
	var fama := lg_f.salon_de_la_fama(12)
	_comprobar(fama.size() == 2, "al salon entran los dos que dejaron huella (%d)" % fama.size())
	if fama.size() == 2:
		_comprobar(String(fama[0]["nombre"]) == "Capitan",
			"dos titulos y 200 partidos pesan mas que 30 goles (manda %s)" % String(fama[0]["nombre"]))
		_comprobar(String(fama[0]["motivo"]).contains("título"),
			"y el motivo lo dice: %s" % String(fama[0]["motivo"]))
	lg_f.rec["goles"] = goles_antes
	lg_f.rec["pj"] = pj_antes
	lg_f.muro = muro_antes

	m.directiva.mover_confianza(-13, "prueba")
	m.mi_club().mover_saldo(2000000)
	m.directiva.alternar_consejero("dep")
	var cand: Array[Dictionary] = Directiva.candidatas_embajador(m.cantera.leyendas, m.anio) if m.cantera != null else []
	if not cand.is_empty():
		m.directiva.contratar_embajador(cand[0])
	if m.ojeadores != null:
		m.ojeadores.modo_ciego = true
	if m.prensa != null:
		m.prensa.animo = 41
		m.prensa.funa = 7
	## Se juega media temporada para que haya algo que guardar: tabla con
	## puntos, gente lesionada, goleadores. Guardar un mundo recién creado no
	## prueba nada, porque todo está a cero y a cero se parece cualquier cosa.
	for s in 10:
		m.avanzar_semana()
	var antes_caja := m.mi_club().saldo
	var antes_jug := m.cuantos_jugadores()
	var antes_tabla := m.ligas[0].tabla()
	var antes_jornada := m.ligas[0].jornada_actual

	var t0 := Time.get_ticks_msec()
	_comprobar(Partida.guardar(m, "prueba_banco"), "la partida se guarda")
	var ms_guardar := Time.get_ticks_msec() - t0
	var f := FileAccess.open(Partida.ruta_de("prueba_banco"), FileAccess.READ)
	var bytes := f.get_length() if f != null else 0
	if f != null:
		f.close()
	_linea("  %d jugadores -> %d KB comprimidos, %d ms" % [antes_jug, bytes / 1024, ms_guardar])
	_comprobar(bytes > 0 and bytes < 4 * 1024 * 1024, "el fichero es manejable (%d KB)" % (bytes / 1024))

	t0 = Time.get_ticks_msec()
	var m2 := Partida.cargar("prueba_banco")
	_linea("  cargado en %d ms" % (Time.get_ticks_msec() - t0))
	_comprobar(m2 != null, "la partida se carga")
	if m2 == null:
		return [true, null]
	_comprobar(m2.anio == m.anio and m2.semana == m.semana, "vuelve el almanaque (%d, semana %d)" % [m2.anio, m2.semana])
	_comprobar(m2.mi_club_id == m.mi_club_id, "vuelve tu club")
	_comprobar(m2.cuantos_jugadores() == antes_jug, "vuelven los %d jugadores" % antes_jug)
	_comprobar(m2.mi_club().saldo == antes_caja, "vuelve la caja exacta")
	_comprobar(m2.ligas.size() == m.ligas.size(), "vuelven las ligas")
	_comprobar(m2.ligas[0].jornada_actual == antes_jornada, "vuelve la jornada (%d)" % antes_jornada)
	_comprobar(m2.directiva.tiene_consejero("dep"), "vuelve el consejero deportivo contratado")
	_comprobar(not cand.is_empty() and not m2.directiva.embajador.is_empty() and m2.directiva.embajador["nombre"] == cand[0]["nombre"], "vuelve el embajador contratado")
	_comprobar(m2.ojeadores != null and m2.ojeadores.modo_ciego, "vuelve el modo ciego activado")

	## La tabla tiene que volver ENTERA y en el mismo orden. Es lo que se pierde
	## si el calendario se rearma sin volver a poner los puntos encima.
	var tabla2 := m2.ligas[0].tabla()
	var igual := tabla2.size() == antes_tabla.size()
	if igual:
		for i in tabla2.size():
			if tabla2[i]["club"].id != antes_tabla[i]["club"].id or tabla2[i]["pts"] != antes_tabla[i]["pts"]:
				igual = false
				break
	_comprobar(igual, "vuelve la tabla completa, en el mismo orden y con los mismos puntos")
	var tac := m2.mi_club().tactica
	_comprobar(tac.salida_corta and tac.tiro_lejano and not tac.marca_al_hombre and not tac.fuera_de_juego,
		"vuelven los cuatro interruptores tacticos, los puestos y los no puestos")
	## Y el once elegido a mano, que tampoco se guardaba: armabas tu equipo,
	## salvabas la partida, y al volver decidia el automatico.
	_comprobar(m2.mi_club().once_elegido.size() == 11, "vuelve el once elegido a mano (%d)" % m2.mi_club().once_elegido.size())
	var mismo_once := true
	for n in mini(11, m.mi_club().once_elegido.size()):
		if m2.mi_club().once_elegido[n] != m.mi_club().once_elegido[n]:
			mismo_once = false
	_comprobar(mismo_once, "y son exactamente los mismos once, en el mismo orden")
	_comprobar(bool(m2.tienda.get("buf", false)), "vuelve la linea de tienda lanzada")

	## OJO CON EL ORDEN DE ESTAS PRUEBAS: todo lo que compare el mundo cargado
	## con el original tiene que ir ANTES de seguir jugando con el cargado. Al
	## reves, la copa de `m2` ya habia avanzado tres rondas mas que la de `m` y
	## la comparacion fallaba sin que hubiera nada roto.
	_comprobar_estado_cargado(m, m2)

	## Los detalles de un jugador concreto, que es donde se ve si el mapeo de
	## claves cortas esta bien hecho. Va ANTES de "seguir jugando" y no despues
	## -misma regla que el resto de esta prueba-: con Cantera enganchada, cinco
	## semanas mas ya pueden robarle un canterano sin ficha al club, y entonces
	## el de plantilla[0] deja de ser el mismo jugador sin que nada este roto.
	var j1: Jugador = m.mi_club().plantilla[0]
	var j2: Jugador = null
	for j in m2.mi_club().plantilla:
		if j.id == j1.id:
			j2 = j
			break
	if j2 != null:
		_comprobar(j2.nombre == j1.nombre and j2.ovr == j1.ovr and j2.valor == j1.valor \
			and j2.atributos.size() == j1.atributos.size() and j2.dorsal == j1.dorsal,
			"un jugador vuelve identico (%s, %d, dorsal %d)" % [j2.nombre, j2.ovr, j2.dorsal])
	else:
		_comprobar(false, "el jugador de prueba no aparece tras cargar")

	## Y lo mas facil de romper: que se pueda SEGUIR jugando desde donde estaba.
	for s in 5:
		m2.avanzar_semana()
	_comprobar(m2.ligas[0].jornada_actual == antes_jornada + 5, "se puede seguir jugando tras cargar")

	var lista := Partida.listar()
	_comprobar(lista.size() >= 1, "el guardado aparece en la lista (%d)" % lista.size())
	Partida.borrar("prueba_banco")
	return [false]

func _probar_guardado() -> void:
	var _r1 = _probar_guardado_1()
	var m: Mundo = _r1[0]
	var v_rp = _r1[1]
	var _r2 = _probar_guardado_2(m, v_rp)
	if _r2[0]:
		return
