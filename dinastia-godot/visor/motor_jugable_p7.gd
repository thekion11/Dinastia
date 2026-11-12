extends "res://visor/motor_jugable_p7_p1.gd"
## (Parte 2 de 2 de `motor_jugable_p7.gd`.)

## El que lleva el balón decide: tirar, pasar o conducir.
func _ia_portador(p: Dictionary) -> void:
	var arco := _arco_rival(p)
	var d := dir_ataque(bool(p["es_local"]))
	var yo := pos(p)
	var dist_arco := Vector2(yo.x - arco.x, yo.z - arco.z).length()
	var presion := _presion(p)
	## Conduce hacia el arco, esquivando al rival más cercano.
	var hacia := (arco - yo).normalized()
	if dist_arco > 30.0:
		hacia = Vector3(0, 0, d)
	var rival := _rival_mas_cercano(p)
	if not rival.is_empty() and pos(rival).distance_to(yo) < 4.0:
		var esquiva := (yo - pos(rival)).normalized()
		hacia = (hacia + esquiva * 0.8).normalized()
	## Durante la finta sigue la salida que eligió (no se lo come de nuevo).
	if t < float(p["regate_hasta"]) and p.has("regate_dir"):
		hacia = p["regate_dir"]
	p["objetivo"] = yo + hacia * 6.0
	p["correr"] = dist_arco < 35.0 or presion < 4.0
	if _intentar_regate(p, rival, dist_arco):
		return
	if t < _decision_en and not MotorDescarga.urge(self as Object as MotorJugable, p, presion):   ## descarga bajo presión (ciclo 9)
		return
	## Conduce algo más antes de decidir (antes se la quitaba de encima en
	## medio segundo: el balón en los pies solo el 24 % del tiempo).
	## Con espacio se conduce más (1 a 1,6 s): en un partido de verdad el balón
	## pasa más tiempo en los pies que viajando.
	var holgura := 1.7 if presion > 6.0 else (1.0 if presion > 3.5 else MotorDescarga.holgura(0.5))
	_decision_en = t + (0.45 + _rng.randf() * 0.45) * (1.0 - 0.15 * float(_tac(bool(p["es_local"]), "ritmo") - 1)) * (1.0 + holgura) * CHISPA_PAUSA * _pausa_dificultad(p) / pow(prisa(), 0.8)
	if OS.get_environment("DEPURAR_PORTADOR") != "" and dist_arco < 40.0:
		Registro.depurar("PORTADOR", "%s(%s) a %.0f m del arco, x %.0f, presión %.1f" % [String(p.get("slot_code", "")), "L" if bool(p["es_local"]) else "V", dist_arco, yo.x, presion])
	## En su propio campo y apretado: despeje, lejos y hacia fuera si hace falta.
	var en_su_tercio := (arco.z - yo.z) * d > 70.0
	if en_su_tercio and presion < 2.2 and _rng.randf() < 0.55:
		var lado := signf(yo.x) if yo.x != 0.0 else 1.0
		var despeje := Vector3(lado * _rng.randf_range(18, 36), 0, yo.z + d * _rng.randf_range(20, 40))
		_ctx_golpeo = "despeje"
		_patear(p, despeje, 18.0, 4.0, 0.0, "patear")
		despejes[0 if bool(p["es_local"]) else 1] += 1
		return
	## Tirar: cerca y con ángulo.
	var angulo := absf(yo.x) / maxf(absf(arco.z - yo.z), 1.0)
	## Se tira también desde la frontal (hasta ~27 m), como en un partido de
	## verdad; con más pegada, desde más lejos.
	var lejano := MotorTacticaViva.bandera(self as Object as MotorJugable, bool(p["es_local"]), "tiro_lejano")   ## pizarra: tiro lejano (01-11)
	var ganas_tiro := (1.0 - dist_arco / MotorTiroLimpio.alcance(40.0 if lejano else 34.0)) * (0.7 + float(p["attr"]["tir"]) * 0.6) - angulo * 0.25
	ganas_tiro = (ganas_tiro + MotorTiroLimpio.bono_area(dist_arco)) * MotorTiroLimpio.paciencia(dist_arco)   ## TIRO_REAL: más ganas dentro del área (ciclo 7)
	## F6 (03-11): tres puntos del arco puntuados por la línea limpia; tapada = menos ganas, limpia = más.
	var linea_limpia: Array = MotorTiroLimpio.mejor(self as Object as MotorJugable, p) if dist_arco < MotorTiroLimpio.alcance(34.0) else [0.0, -1.0]
	if float(linea_limpia[1]) >= 0.0:
		ganas_tiro *= MotorTiroLimpio.factor_ganas(float(linea_limpia[1])) if ganas_tiro > 0.0 else 1.0
	ganas_tiro = _ganas_tiro_extra(p, dist_arco, ganas_tiro, presion)   ## gancho (12-11): C4 lo usa para la paciencia; aquí no cambia nada
	## MÁS CHISPA (20-10-2026): el sorteo era muy conservador y el partido se quedaba en ~0,8 tiros por minuto
	## y equipo (FC ronda 1,5). Ahora se anima más desde la frontal; la calidad del tiro no cambia.
	if dist_arco < MotorTiroLimpio.alcance(34.0 if lejano else 30.0) and ganas_tiro > 0.05 - 0.05 * float(_tac(bool(p["es_local"]), "mentalidad") - 1) + _rng.randf() * CHISPA_TIRO / pow(prisa(), 1.3):
		## A un palo, abajo o arriba (antes se apuntaba al azar por el centro
		## y el portero lo paraba casi todo: 27 de 29 en la sonda).
		## (Pulido: más pegado al palo, lejos del portero, a riesgo de irse fuera.)
		var palo := (1.0 if _rng.randf() < 0.5 else -1.0) * (_rng.randf_range(PALO_TIRO, 1.0) if TIRO_PULIDO else _rng.randf_range(0.55, 0.95))
		if float(linea_limpia[1]) >= 0.0:
			palo = clampf(float(linea_limpia[0]) + _rng.randf_range(-0.08, 0.08), -1.0, 1.0)   ## al punto más limpio (F6)
		var alto := -0.45 if _rng.randf() < 0.6 else 0.55
		_tirar(p, Vector2(palo, alto), clampf(0.55 + _rng.randf() * 0.4, 0.0, 1.0))
		return
	## Centro desde la banda, cerca del fondo.
	if MotorCorner.centrar(self as Object as MotorJugable, p, yo, arco):
		var err_c := (1.0 - float(p["attr"]["pas"])) * 7.0
		var destino := Vector3(_rng.randf_range(-4, 4) + _rng.randf_range(-err_c, err_c), 1.6, arco.z - d * _rng.randf_range(4, 10))
		_ctx_golpeo = "centro"; MotorTraza.centro(self as Object as MotorJugable, p)   ## ciclo 32: solo cuenta
		## El efecto se da EN EL SENTIDO DEL ATAQUE (`* -d`): antes era el mismo
		## giro absoluto para los dos y, con el Magnus, el local centraba
		## abriéndose y el visitante cerrándose hacia el arco (sesgo de lado).
		_patear(p, destino, 17.0, 0.0, -signf(yo.x) * 6.0 * -d, "pase")
		pase_a = _companero_cerca(p, destino)
		return
	## LA FINTA DE ÚLTIMO RECURSO (13-10, rehecha el 15-10): con el defensor ya
	## encima (< 1,8 m), el que tiene regate intenta irse antes de soltarla. Antes
	## se teletransportaba 0,8 m de lado; ahora es un empujón con inercia.
	if presion < 1.8 and t > float(p["regate_hasta"]) + 0.6 and _rng.randf() < minf(float(p["attr"]["reg"]) * 0.45 * _escala_ritmo(), 0.9):
		var n_f: Node3D = p["node"]
		var fwd_f := Vector3(sin(n_f.rotation.y), 0, cos(n_f.rotation.y))
		var lado_f := -signf(Vector3(fwd_f.z, 0, -fwd_f.x).dot(pos(rival) - yo)) if not rival.is_empty() else 1.0
		if lado_f == 0.0:
			lado_f = 1.0
		_finta_ia(p, rival, fwd_f, lado_f, maxf((p["vel"] as Vector3).length(), 2.0))
		return
	## EL PASE AL HUECO (13-10-2026). La IA nunca filtraba: los ataques
	## morían a 30 m de la portería tocando atrás (la sonda: 5 tiros en 8
	## minutos). Si un delantero o un extremo habilitado ataca la espalda de la
	## defensa y la línea de pase está limpia, se la mete al espacio; con más
	## pase (y más verticalidad, fila 18), más a menudo.
	if dist_arco < 48.0:
		var hueco := _companero_al_hueco(p)
		if not hueco.is_empty() and _rng.randf() < 0.6 + 0.2 * float(_tac(bool(p["es_local"]), "verticalidad") - 1) + float(p["attr"]["pas"]) * 0.3:
			_pasar_a(p, hueco, false, true)
			return
	## Pasar si hay presión o un compañero mejor situado.
	var mejor := _mejor_pase(p)
	if not mejor.is_empty():
		var hay_prisa := presion < 3.0
		## Cerca del área y con espacio, sigue conduciendo hacia la portería.
		var conduce := dist_arco < 34.0 and presion > 3.0
		if hay_prisa or float(mejor.get("_nota", 0.0)) > 1.5 or (not conduce and _rng.randf() < 0.15):
			_pasar_a(p, mejor)

## GANCHO DE LAS GANAS DE TIRAR (12-11-2026, sesión 13): el motor de siempre las deja igual (no gasta azar: la huella no cambia);
## `MotorCombinado` (C4) lo cambia por la paciencia de `MejorasC4.ganas_tiro`.
func _ganas_tiro_extra(_p: Dictionary, _dist_arco: float, ganas: float, _presion: float) -> float:
	return ganas

## GANCHO DEL RADIO DEL CABEZAZO (12-11-2026, sesión 13): 0,8 m en el motor de siempre; C4 lo puede cambiar (`MejorasC4.RADIO_CABEZA`).
func _radio_cabezazo(_p: Dictionary) -> float:
	return 0.8
