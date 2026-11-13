extends "res://visor/motor_jugable_p6.gd"
## (Parte 1 de 2 de `motor_jugable_p7.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `motor_jugable_p7.gd`, conserva la clase.)

## [Capa 7/12 de `motor_jugable.gd`] _parada, _penal_en_juego, _reaccion_portero, _ia_portero, _finta_ia, _intentar_regate … (+4)

## El portero se estira: atrapa si puede, si no la desvía.
func _parada(p: Dictionary, cruce: Vector3, estirada: bool) -> void:
	_cerrar_tiro("atajada")
	stats["paradas"] += 1 if p == usuario else 0
	var lado := "izq" if (cruce.x - pos(p).x) * dir_ataque(bool(p["es_local"])) > 0.0 else "der"
	var altura := "baja" if cruce.y < 0.7 else ("media" if cruce.y < 1.6 else "alta")
	var anim := ("estirada_%s_%s" % [altura, lado]) if estirada else ("atajar_bajo" if cruce.y < 0.6 else ("blocaje_alto" if cruce.y > 1.6 else "atajar"))
	_anim(p, anim, true)
	## Se tira de verdad: un impulso lateral que la inercia gasta (antes se teletransportaba 1,6 m de un fotograma a otro).
	var hacia_x := clampf(cruce.x - pos(p).x, -2.2, 2.2)
	p["vel"] = Vector3(hacia_x * (3.4 if estirada else 2.0), 0, 0)
	p["objetivo"] = Vector3(pos(p).x + hacia_x, 0, pos(p).z)
	var fuerza := vel_balon.length()
	if not estirada and fuerza < 22.0 and _rng.randf() < float(p["attr"]["par"]) * 0.9 * GestoTecnico.agarre(self):
		_tomar(p)
		p["en_manos"] = true   ## (saque de mano, 31-10)
		## El balón va a las manos desde donde estaba (antes saltaba a ellas en un fotograma: «teletransporte» de hasta 2 m, M-114).
		aviso.emit("¡Atajada!")
	else:
		## Rechace: hacia un lado y, la mitad de las veces, por detrás de la
		## línea (córner), como las manos abiertas de un portero de verdad.
		var lado_r := signf(cruce.x - pos(p).x + 0.01)
		if _rng.randf() < 0.5:
			## A córner: hacia FUERA del palo más cercano (antes, con el tiro entre
			## el portero y el centro del arco, la manopla lo metía en su red).
			if PULIDO:
				lado_r = signf(cruce.x + 0.01)
			vel_balon = Vector3(lado_r * _rng.randf_range(6, 11), _rng.randf_range(1, 4), vel_balon.z * 0.3)
		else:
			vel_balon = Vector3(lado_r * _rng.randf_range(4, 9), _rng.randf_range(1, 4), -vel_balon.z * 0.25)
		penultimo_toque = ultimo_toque
		ultimo_toque = p
		p["enfriar"] = 0.6
		aviso.emit("¡Qué parada!")

## PENAL EN PLENO PARTIDO: en `PenalPortero` (2-11, para la norma de 450 líneas).
func _penal_en_juego(gk: Dictionary, cruce: Vector3) -> void:
	PenalPortero.en_juego(self as Object as MotorJugable, gk, cruce)

func _lado_portero_tanda(lz: Dictionary, gk: Dictionary, mira := 1) -> int:
	return PenalPortero.lado(self as Object as MotorJugable, lz, gk, mira)

## TIRO QUE VIENE: ¿llega a tapar? (de `_ia_portero`, 25-10, para el portero de la Carrera en `_control_usuario`).
## Devuelve true si ya actuó (parada o penal). `manual`: lo maneja el usuario, que elige lado con el stick (`guia`,
## X del mundo, 0 = no eligió); sin elegir espera a medio segundo y reacciona más flojo; si elige mal no llega.
func _reaccion_portero(p: Dictionary, manual := false, guia := 0.0) -> bool:
	if MotorParada.revisar(self as Object as MotorJugable, p): return true   ## la parada decidida, cuando llega el balón (01-11)
	var b := balon.position
	var arco := _arco_propio(p)
	var hacia := signf(arco.z)
	if poseedor.is_empty() and vel_balon.z * hacia > 6.0:
		var tz := (arco.z - hacia * 0.6 - b.z) / vel_balon.z
		if tz > 0.0 and tz < 1.6:
			var cruce := b + vel_balon * tz
			cruce.y = b.y + vel_balon.y * tz - 0.5 * G * tz * tz
			if absf(cruce.x) < PALO + 0.8 and cruce.y < LARGUERO + 0.4 and int(p.get("_patada_vista", -1)) != _n_patada:   ## UNA decisión por disparo (13-10)
				## El usuario aún no eligió: se espera (sin gastar la decisión).
				if manual and absf(guia) < 0.3 and tz > 0.55:
					return false
				p["_patada_vista"] = _n_patada
				if PULIDO and String(_tiro_vivo.get("clase", "")) == "penal":
					_penal_en_juego(p, cruce)
					return true
				## Alcance: hasta ~3 m con un gran portero, menos con menos tiempo; a la escuadra cuesta más.
				var alcance: float = (1.1 + float(p["attr"]["div"]) * 2.0 + float(p["attr"]["ref"]) * 0.8) * clampf((tz - 0.1) * 2.4, MotorParada.SUELO, 1.0)
				if cruce.y > 1.8:
					alcance *= 0.85
				## El alcance se mide donde está ÉL (adelantado tapa más ángulo), no en la línea de gol.
				var tg := clampf((pos(p).z - b.z) / vel_balon.z, 0.0, tz)
				var cruce_gk := b + vel_balon * tg
				cruce_gk.y = b.y + vel_balon.y * tg - 0.5 * G * tg * tg
				var lat := absf(cruce_gk.x - pos(p).x)
				var prob := (0.47 + float(p["attr"]["ref"]) * 0.42) * MotorParada.K
				if manual:
					if absf(guia) < 0.3:
						## No actuó: reacción automática más floja.
						alcance *= 0.8
						prob *= 0.75
					elif lat > 0.6 and signf(guia) != signf(cruce_gk.x - pos(p).x):
						## Se tiró al otro lado: el gesto se ve, pero no llega.
						_anim(p, "estirada_media_%s" % ("izq" if guia * dir_ataque(bool(p["es_local"])) > 0.0 else "der"), true)
						return true
					else:
						alcance *= 1.1  ## Eligió bien: se anticipa un poco.
				if TIRO_PULIDO: prob *= (1.0 - PARADA_LEJOS * pow(clampf(lat / maxf(alcance, 0.1), 0.0, 1.0), 2.0)) * clampf(1.15 - vel_balon.length() / 90.0, 0.7, 1.0)   ## lejos del cuerpo o muy fuerte cuesta más (27-10)
				prob = _prob_parada_extra(p, b, prob)   ## gancho (sesión 15): aquí no cambia nada
				if lat < alcance and _rng.randf() < prob:
					MotorParada.programar(self as Object as MotorJugable, p, cruce_gk, lat > 1.2)
					return true
				## NO LLEGA (27-10, §8): se estira hacia el balón y queda batido (antes miraba quieto el gol).
				if lat > 0.6:
					_anim(p, "estirada_media_%s" % ("izq" if (cruce_gk.x - pos(p).x) * dir_ataque(bool(p["es_local"])) > 0.0 else "der"), true)
					return true
	return false

func _ia_portero(p: Dictionary) -> Vector3:
	var b := balon.position
	var arco := _arco_propio(p)
	## En plena estirada sigue hacia donde se tiró (sin teletransportes).
	if float(p.get("gesto_hasta", 0.0)) > t and p.has("objetivo"):
		return p["objetivo"]
	p["correr"] = false
	if poseedor == p:
		## Sale con el balón: lo pasa a un defensa libre o despeja largo.
		if t > _decision_en + 0.8:
			var mejor := _mejor_pase(p)
			## Salida jugada casi siempre; el pelotazo, menos alto.
			if not mejor.is_empty() and _rng.randf() < MotorTacticaViva.prob_salida_jugada(self as Object as MotorJugable, bool(p["es_local"])):
				_pasar_a(p, mejor)
			else:
				var lejos := Vector3(_rng.randf_range(-15, 15), 0, dir_ataque(bool(p["es_local"])) * 2.0)
				_patear(p, lejos, 18.0, 3.0, 0.0, "patear")
		return pos(p)
	## Tiro que viene: ¿llega a tapar?
	var reacciona := _reaccion_portero(p)
	var desliza := MotorParada.destino(self as Object as MotorJugable, p)   ## F7 (3-11): se desliza hacia el cruce MIENTRAS la parada está pendiente
	if desliza != Vector3.INF:
		return desliza
	if reacciona:
		return pos(p)
	var sc := SalidaPortero.punto(self, p)   ## un centro que cae en su zona: sale a por él (semana 3)
	if sc != Vector3.INF:
		p["correr"] = true
		return pos(p) if SalidaPortero.atrapar(self, p) else sc
	## Balón suelto en su área y él llega antes: sale a por él.
	if poseedor.is_empty() and _en_su_area(p, b) and b.y < 2.0:
		var suyo := true
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) != bool(p["es_local"]) and pos(q).distance_to(b) < pos(p).distance_to(b) * 0.8:
				suyo = false
		if suyo:
			p["correr"] = true
			return b
	## Mano a mano: un rival con el balón entra solo por el centro del área y
	## no hay defensa en medio -> sale a achicar, a unos metros de él.
	if not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]):
		var pr := pos(poseedor)
		var d_arco := pr.distance_to(arco)
		if d_arco < 15.0 and absf(pr.x) < 12.0 and not _hay_defensa_entre(p, pr, arco):
			p["correr"] = true
			return pr + (arco - pr).normalized() * clampf(d_arco * 0.25, 1.8, 3.2)
	return colocacion_portero(b, arco, _tac(bool(p["es_local"]), "linea"))

## La finta en sí (la de antes del duelo y la de último recurso, pegado al
## defensor): gesto del repertorio según el regate, empujón lateral de
## verdad y, si el defensor pica, queda clavado y el atacante arranca.
func _finta_ia(p: Dictionary, rival: Dictionary, fwd: Vector3, lado: float, sp: float) -> void:
	regates_ia += 1
	var reg := float(p["attr"]["reg"])
	var der := Vector3(fwd.z, 0, -fwd.x)
	var salida := (fwd * 0.55 + der * lado).normalized()
	p["regate_dir"] = (fwd * 0.8 + der * lado * 0.6).normalized()
	p["regate_hasta"] = t + 0.75
	p["vel"] = salida * clampf(sp * 0.8, 3.0, 5.5)
	## El repertorio crece con el regate: los buenos sacan bicicletas,
	## elásticas, ruletas y caños.
	var fintas := ["regate_finta", "recorte_interior", "recorte_exterior", "amague_cuerpo", "finta_hombro"]
	if reg > 0.7:
		fintas.append_array(["bicicleta", "cola_de_vaca", "giro_cruyff", "pisada_lateral"])
	if reg > 0.82:
		fintas.append_array(["elastica", "ruleta", "cano", "croqueta"])
	var nom: String = fintas[_rng.randi() % fintas.size()]
	var ap_r: AnimationPlayer = p["anim"]
	if is_instance_valid(ap_r) and lado < 0.0 and ap_r.has_animation(nom + "_espejo"):
		nom += "_espejo"
	_anim(p, nom, true, 0.8)
	## ¿Pica el defensor? Regate contra defensa, con algo de suerte.
	if not rival.is_empty():
		var engano := clampf(0.4 + (reg - float(rival["attr"]["def"])) * 1.1, 0.12, 0.8)
		if _rng.randf() < engano:
			regates_ia_ok += 1
			rival["enfriar"] = maxf(float(rival["enfriar"]), 0.9)
			## Se va hacia el lado equivocado: frena y se le va el cuerpo; el
			## atacante sale disparado por el otro lado, ya mirando al frente.
			var se_va := -der * lado
			rival["vel"] = (rival["vel"] as Vector3) * 0.25 + se_va * 2.0
			## Se le va el cuerpo hacia ese lado (`AnimFutbol.defensor_pica`); la
			## derecha del modelo, que mira a +Z, es -X.
			var n_r: Node3D = rival["node"]
			var der_r := Vector3(-cos(n_r.rotation.y), 0, sin(n_r.rotation.y))
			_anim(rival, "defensor_pica_der" if se_va.dot(der_r) >= 0.0 else "defensor_pica_izq", true, 0.85)
			p["vel"] = salida * clampf(sp * 1.05, 4.5, 6.5)
			p["regate_dir"] = (fwd + der * lado * 0.35).normalized()
	## Tras la finta decide con calma (no la suelta en mitad del gesto).
	_decision_en = maxf(_decision_en, t + 0.45)

## EL REGATE DE LA IA (15-10-2026, H-11 / M-443). Antes la finta solo se probaba con un rival a menos de 1,8 m
## y DESPUÉS de tirar, centrar o pasar: 0 en un partido. Ahora se decide al VER venir al defensor (en carrera,
## rival delante a 1,5-3,6 m, una tirada por duelo). Las ganas crecen con el regate (nada bajo 35, ~2 de 5 duelos
## con 65, 3 de 5 con 85+) y bajan en el propio tercio. Sale al lado contrario del defensor con un empujón de
## verdad; el defensor se la come según regate contra defensa y, si pica, queda clavado (no puede entrar). Si
## no pica, decide la entrada normal (con la bonificación de `regate_hasta`).
func _intentar_regate(p: Dictionary, rival: Dictionary, dist_arco: float) -> bool:
	if rival.is_empty() or bool(p["por"]) or t < float(p["regate_hasta"]) + 0.6:
		return false
	if float(p.get("duelo_hasta", 0.0)) > t and String(p.get("duelo_con", "")) == String(rival.get("id", "")):
		return false
	var yo := pos(p)
	var rp := pos(rival)
	var hacia_r := rp - yo
	hacia_r.y = 0.0
	var dr := hacia_r.length()
	if dr < 1.3 or dr > 3.6:
		return false
	var vel: Vector3 = p["vel"]
	var sp := Vector2(vel.x, vel.z).length()
	## En carrera; casi parado solo si el defensor ya está encima.
	if sp < 1.2 or (sp < 2.4 and dr > 2.2):
		return false
	var fwd := Vector3(vel.x, 0, vel.z) / sp
	## El defensor tiene que estar DELANTE (cerrándole el paso), no detrás.
	if fwd.dot(hacia_r / dr) < 0.35:
		return false
	## Una tirada por duelo: hasta que se separen o pase un rato no se repite.
	p["duelo_con"] = String(rival.get("id", ""))
	p["duelo_hasta"] = t + 2.2
	var reg := float(p["attr"]["reg"])
	var ganas := clampf((reg - 0.35) * 1.3, 0.0, 0.6)
	## En su propio tercio, se arriesga mucho menos; cerca del área rival, más.
	var en_su_tercio := dist_arco > 70.0
	if en_su_tercio:
		ganas *= 0.3
	elif dist_arco < 32.0:
		ganas *= 1.25
	if _rng.randf() >= minf(ganas * _escala_ritmo(), 0.95):
		return false
	## Sale por el lado contrario al que tapa el defensor (y hacia dentro si
	## va pegado a la banda).
	var der := Vector3(fwd.z, 0, -fwd.x)
	var lado := -signf(der.dot(hacia_r))
	if lado == 0.0:
		lado = 1.0 if _rng.randf() < 0.5 else -1.0
	if absf(yo.x) > ANCHO - 6.0 and (der * lado).x * signf(yo.x) > 0.0 and _rng.randf() < 0.7:
		lado = -lado
	_finta_ia(p, rival, fwd, lado, sp)
	return true

## Un tiro al arco rival. `apunte.x` ∈ [-1, 1] mueve el objetivo de palo a
## palo; `fuerza` ∈ [0, 1] es la carga. Mucha fuerza sin técnica se va alta.
func _tirar(p: Dictionary, apunte_: Vector2, fuerza: float) -> void:
	var arco := _arco_rival(p)
	var tec := GestoTecnico.tiro(p, _mod_tiro)   ## cada tiro pesa sus atributos (27-10)
	## El error crece con la distancia: desde 25 m se falla mucho más que
	## dentro del área (la sonda medía 8 de cada 10 tiros entre los palos).
	var lejos := Vector2(pos(p).x - arco.x, pos(p).z - arco.z).length()
	var error := ((1.0 - tec) * 2.6 + maxf(0.0, fuerza - 0.8) * 2.5) * (0.55 + lejos / 26.0) * (1.25 if _manual_tiro else 1.0) * _error_extra * preset_error * GestoTecnico.factor_pie(p, pos(p), arco) * GestoTecnico.factor(self, p, _mod_tiro == "vaselina")
	var clase := String(saque.get("tipo", "pie")) if estado == "saque" else "pie"
	if clase == "penal":
		error *= PENAL_ERROR   ## quieto y a 11 m: el error es una fracción del de un tiro cualquiera (sonda de penales, 2-11)
	## LA PUNTERÍA DE VERDAD (25-10-2026). La sonda medía 3 de cada 4 tiros entre
	## los palos (en el fútbol, 1 de cada 3; en FC, la mitad) y el portero los
	## paraba casi todos (84 %). Ahora hasta el bueno se desvía algo más desde
	## lejos y con un rival encima; el penal, quieto y a 11 m, no.
	if TIRO_PULIDO and clase != "penal":
		error += (0.45 + lejos * PUNTERIA) * (1.15 - tec * 0.5) * (1.3 if _presion(p) < 1.8 else 1.0)
	error = _error_tiro_extra(p, lejos, error, clase)   ## gancho (sesión 15): aquí no cambia nada
	var x := clampf(apunte_.x, -1.0, 1.0) * (PALO - 0.35) + _rng.randf_range(-error, error)
	var y := clampf(0.35 + fuerza * 1.2 + apunte_.y * 0.6 + _rng.randf_range(-error, error) * 0.6, 0.15, 3.4)
	var destino := Vector3(x, y, arco.z + signf(arco.z) * 0.3)
	var vh := 16.0 + fuerza * 14.0 + tec * 4.0
	var loft := 0.0
	var efecto := _rng.randf_range(-3, 3)
	match _mod_tiro:
		"rosca":
			## RB + B: con el interior, curvado hacia dentro, más colocado y flojo.
			destino.x = clampf(apunte_.x, -1.0, 1.0) * (PALO - 0.5) + _rng.randf_range(-error, error) * 0.75
			destino.y = clampf(0.6 + apunte_.y * 0.5 + _rng.randf_range(-error, error) * 0.4, 0.2, 2.3)
			vh *= 0.82
			efecto = -signf(destino.x - pos(p).x + 0.01) * 7.0 * signf(arco.z)
		"vaselina":
			## LB + B: por encima del portero, cae bajo el larguero.
			destino.y = clampf(1.4 + _rng.randf_range(-error, error) * 0.4, 0.8, 2.6)
			vh = clampf(9.0 + lejos * 0.32, 10.0, 17.0)
			loft = clampf(lejos * 0.28, 3.5, 7.5)
		"raso":
			## LT + B: el tiro raso, pegado al césped y al palo (semana 3, 27-10-2026).
			destino.y = clampf(0.18 + _rng.randf_range(0.0, error) * 0.25, 0.12, 0.5)
			vh *= 0.92
		"potente":
			## LB + RB + B: el cañonazo; apuntado a mano, castiga el mal apunte.
			vh += 9.0
			destino.x = clampf(apunte_.x, -1.0, 1.0) * (PALO - 0.35) + _rng.randf_range(-error, error) * (0.7 if tec > 0.75 else 1.3)
			aviso.emit("💥 ¡Tiro potente!")
	if clase != "penal":   ## (4-11) el penal ya tiene su error propio (PENAL_ERROR): sin esto se fallaban 27 de 120 y la sonda daba 61 % marcados
		destino = MotorTiroLimpio.fallar(self as Object as MotorJugable, p, destino, lejos, _presion(p))   ## tiro fallido / bloqueado (TIRO_REAL, ciclo 7)
	_ctx_golpeo = "tiro"
	_patear(p, destino, vh, loft, efecto, "patear")
	tiros[0 if bool(p["es_local"]) else 1] += 1
	_cerrar_tiro("fallo")   ## (01-11) el remate anterior aún abierto se cierra: si no, el mapa de tiros lo contaba y el acta no
	_tiro_vivo = {"p": p, "t": t, "clase": clase}; MotorTraza.tiro(self as Object as MotorJugable, p, lejos)   ## (ciclo 23) solo cuenta
	_contar("tiro_%s" % clase)
	_contar("tiro_%s_%s" % [clase, "dentro" if lejos < 16.5 else ("frontal" if lejos < 25.0 else "lejos")])
	if absf(destino.x) < PALO and destino.y < LARGUERO:
		_contar("a_puerta_%s" % clase)
	if OS.get_environment("DEPURAR_TIROS") != "":
		Registro.depurar("TIRO", "de %s a %.0f m, destino x %.1f y %.1f, vh %.0f, error %.2f" % [String(p.get("slot_code", "")),
			pos(p).distance_to(arco), x, y, vh, error])
	if p == usuario:
		stats["tiros"] += 1
		if absf(destino.x) < PALO and destino.y < LARGUERO:
			stats["a_puerta"] += 1

## La línea del último defensor (sin el portero) del equipo `local`.
func _ultima_linea(local: bool) -> float:
	var d := dir_ataque(local)
	var linea := d * 40.0
	var hay := false
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var z := pos(q).z + (q["vel"] as Vector3).z * MotorPresion.PREVE_LINEA   ## donde ESTARÁ (U3, 01-11)
		if not hay or (z - linea) * d < 0.0:
			linea = z
			hay = true
	return linea

## Un compañero de ataque, habilitado, cerca de la última línea rival y por
## delante del balón, con el pasillo hacia el espacio a su espalda limpio.
func _companero_al_hueco(p: Dictionary) -> Dictionary:
	var local := bool(p["es_local"])
	var d := dir_ataque(local)
	var linea := _ultima_linea(not local)
	var yo := pos(p)
	var mejor: Dictionary = {}
	var mejor_nota := 0.0
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		if not _rol(q) in ["DC", "ED", "EI", "MC"]:
			continue
		var qp := pos(q)
		var adelante := (qp.z - yo.z) * d
		if adelante < 4.0 or absf(qp.z - linea) > 7.0 or _adelantado(q, p):
			continue
		var espacio := qp + Vector3(0, 0, d * 7.0)
		espacio.z = clampf(espacio.z, -LARGO + 4.0, LARGO - 4.0)
		if _linea_tapada(yo, espacio, local):
			continue
		var nota := adelante - absf(qp.x) * 0.15
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor

## GANCHO DEL ERROR DEL REMATE (13-11-2026, sesión 15, OK del líder): el de siempre lo deja igual (sin azar: la huella no cambia);
## `MotorCombinado` (C4) lo usa para la definición dentro del área (`MejorasC4Avance.error_tiro`, `C4_ERROR_AREA`).
func _error_tiro_extra(_p: Dictionary, _lejos: float, error: float, _clase: String) -> float:
	return error

## GANCHO DE LA PROBABILIDAD DE PARADA (13-11-2026, sesión 15, OK del líder): el de siempre la deja igual (sin azar: la huella no
## cambia); `MotorCombinado` (C4) la baja ante remates desde dentro del área (`MejorasC4Avance.parada`, `C4_PARADA_AREA`).
func _prob_parada_extra(_gk: Dictionary, _desde: Vector3, prob: float) -> float:
	return prob
