extends "res://visor/motor_jugable_p3.gd"
## (Parte 4 de 12 de `motor_jugable.gd`.)

# ---------------------------------------------------------------- balón

func _mover_balon(delta: float) -> void:
	if not poseedor.is_empty():
		var n: Node3D = poseedor["node"]
		var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
		var sp := (poseedor["vel"] as Vector3).length()
		var previa := balon.position
		if sp < 2.2 or bool(poseedor["por"]) or estado != "juego" or bool(poseedor.get("protege", false)):
			## Parado o al paso: el balón pegado al pie, protegido.
			var destino := n.position + fwd * (0.45 + minf(sp, 7.0) * 0.07)
			destino.y = R
			balon.position = balon.position.lerp(destino, clampf(delta * 14.0, 0.0, 1.0))
			vel_balon = (balon.position - previa) / maxf(delta, 0.001)
		else:
			## CONDUCCIÓN A TOQUES (14-10-2026): el balón ya no va pegado como un
			## imán. El jugador lo empuja por delante, lo alcanza y lo vuelve a
			## tocar; con más regate, toques más cortos y controlados. Si se le
			## va largo, cualquiera puede llegar antes (ver `_disputas`).
			var rel := balon.position - n.position
			rel.y = 0.0
			var adelante := rel.dot(fwd)
			var reg := float(poseedor["attr"]["reg"])
			## Se pasó del balón (le queda atrás o al lado y lejos del pie): lo
			## recoge con el pie en vez de que el balón salte delante de él
			## (antes: saltos de ~2 m en un fotograma, M-114).
			if rel.length() >= 0.6 and adelante < 0.15:
				var recoge := n.position + fwd * 0.45
				recoge.y = R
				balon.position = balon.position.lerp(recoge, clampf(delta * 9.0, 0.0, 1.0))
				vel_balon = (balon.position - previa) / maxf(delta, 0.001)
				_palos_y_lineas(previa)
				return
			if rel.length() < 0.6:
				var empuje := sp * (1.25 - reg * 0.25) + 0.6
				## Regate técnico o ágil (RB/LB mantenidos): toques más cortos.
				if bool(poseedor.get("toque_corto", false)):
					empuje *= 0.7
				var lateral := Vector3(fwd.z, 0, -fwd.x) * _rng.randf_range(-0.25, 0.25) * (1.2 - reg)
				var dir_t := (fwd + lateral).normalized()
				## Pegado a la banda, el toque va hacia dentro (antes se salía solo).
				if absf(n.position.x) > ANCHO - 4.0 and dir_t.x * signf(n.position.x) > 0.0:
					dir_t.x *= -0.3
					dir_t = dir_t.normalized()
				vel_balon = dir_t * empuje
				## El toque acerca el balón al pie como mucho 25 cm (antes lo
				## recolocaba de golpe: saltos de hasta 1,1 m, 20-10-2026).
				balon.position = balon.position.move_toward(n.position + fwd * 0.55 + Vector3(0, R, 0), 0.25)
				poseedor["toques"] = int(poseedor.get("toques", 0)) + 1
			var h := Vector3(vel_balon.x, 0, vel_balon.z)
			var v := h.length()
			if v > 0.0:
				h = h / v * maxf(0.0, v - (v * ROCE_SUELO + ROCE_FIJO) * delta)
			vel_balon = Vector3(h.x, 0.0, h.z)
			balon.position += vel_balon * delta
			balon.position.y = R
			## Se le fue: balón suelto.
			if rel.length() > 3.2:
				poseedor["enfriar"] = 0.25
				poseedor = {}
		## Conduciendo también se puede meter gol o sacar el balón del campo.
		if estado == "juego":
			_palos_y_lineas(previa)
		return
	var p := balon.position
	var en_aire := p.y > R + 0.02 or vel_balon.y > 0.2
	if en_aire:
		var magnus := giro_balon.cross(vel_balon) * 0.012
		vel_balon += (Vector3(0, -G, 0) + magnus - vel_balon * ARRASTRE) * delta
	else:
		var h := Vector3(vel_balon.x, 0, vel_balon.z)
		var v := h.length()
		if v > 0.0:
			var nv := maxf(0.0, v - (v * ROCE_SUELO + ROCE_FIJO) * delta)
			h = h / v * nv
		vel_balon = Vector3(h.x, 0.0, h.z)
		giro_balon *= 0.97
	var antes := p
	p += vel_balon * delta
	if p.y < R:
		p.y = R
		if vel_balon.y < -1.2:
			vel_balon.y = -vel_balon.y * BOTE
			## El césped se come parte del avance en cada bote.
			vel_balon.x *= 0.72
			vel_balon.z *= 0.72
		else:
			vel_balon.y = 0.0
	## Dentro de la red, el balón se muere.
	if absf(p.z) > LARGO and absf(p.x) < PALO and p.y < LARGUERO:
		vel_balon *= 0.85
		p.z = clampf(p.z, -LARGO - 1.8, LARGO + 1.8)
	balon.position = p
	if estado == "juego":
		_palos_y_lineas(antes)

func _plano(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

func _libre_para_duelo(p: Dictionary) -> bool:
	return not bool(p["por"]) and float(p.get("contacto_hasta", 0.0)) <= t and float(p.get("gesto_hasta", 0.0)) <= t + 0.15

## La fuerza que pone en el choque ahora (el cansado empuja menos).
func _fuerza(p: Dictionary) -> float:
	return float(p.get("fuerza", 0.6)) * (0.75 + 0.25 * float(p.get("aguante", 1.0)))

## La derecha del modelo (mira a +Z con rotación 0, su derecha es -X).
func _derecha(p: Dictionary) -> Vector3:
	var ry := (p["node"] as Node3D).rotation.y
	return Vector3(-cos(ry), 0, sin(ry))

func _ganador(w: Dictionary, l: Dictionary) -> void:
	w["duelos_g"] = int(w.get("duelos_g", 0)) + 1
	l["duelos_p"] = int(l.get("duelos_p", 0)) + 1

func _empujar(p: Dictionary, dir: Vector3, fuerza: float, freno: float, dur: float) -> void:
	var d := _plano(dir)
	if d.length() > 0.001 and fuerza > 0.0:
		p["empujon_obj"] = d.normalized() * fuerza
	p["freno_duelo"] = freno
	p["freno_duelo_hasta"] = t + dur

## EL RITMO NO QUITA FINTAS (16-10-2026). Los duelos ocurren por segundo de
## césped, no por minuto del acta: con el ritmo «normal» del partido (4 s por
## minuto = 180 s la mitad) había 3/4 de los duelos de la sonda (240 s) y la IA
## amagaba ~13 veces por partido en vez de ~20. Las ganas de cada duelo se
## multiplican por lo que falta de césped para que salgan las mismas por 90'.
func _escala_ritmo() -> float:
	return clampf(MITAD_CALIBRADA / maxf(duracion_mitad, 1.0), 0.6, 2.0)

## Las faltas de duelo se reparten por segundo de césped: con partidos más
## cortos hay menos choques y cada uno pesa más (como las fintas).
func _escala_falta() -> float:
	return _escala_ritmo()

## ¿`victima` iba sola hacia el arco? Cerca del arco rival (35 m), de cara a él
## y sin ningún defensor de campo (aparte de `menos`) entre ella y la portería.
func _ocasion_clara(victima: Dictionary, menos: Dictionary) -> bool:
	var arco := _arco_rival(victima)
	var pv := pos(victima)
	if pv.distance_to(arco) > 35.0:
		return false
	var hacia := _plano(arco - pv).normalized()
	var vi := _plano(victima.get("vel", Vector3.ZERO) as Vector3)
	if vi.length() > 1.0 and vi.normalized().dot(hacia) < 0.3:
		return false
	for q: Dictionary in jugadores:
		if q == menos or bool(q["por"]) or bool(q["es_local"]) == bool(victima["es_local"]):
			continue
		var rq := _plano(pos(q) - pv)
		if rq.dot(hacia) > 0.0 and rq.dot(hacia) < pv.distance_to(arco) and (rq - hacia * rq.dot(hacia)).length() < 9.0:
			return false
	return true

## Los puntos de una falta de `infractor` sobre `victima` con una entrada `tipo`
## (una clave de PESO_FALTA: de_pie, deslizante, hombro, agarron, empujon).
func puntos_falta(infractor: Dictionary, victima: Dictionary, tipo: String) -> Dictionary:
	var factores: Array = []
	if PESO_FALTA.has(tipo):
		factores.append(tipo)
	var vi: Vector3 = _plano(victima.get("vel", Vector3.ZERO) as Vector3)
	var vf: Vector3 = _plano(infractor.get("vel", Vector3.ZERO) as Vector3)
	var desde := _plano(pos(victima) - pos(infractor))
	## Por detrás: la víctima corre alejándose del que entra.
	if vi.length() > 1.5 and desde.length() > 0.05 and vi.normalized().dot(desde.normalized()) > 0.6:
		factores.append("por_detras")
	## A gran velocidad: el infractor llega lanzado.
	if vf.length() > 6.0:
		factores.append("gran_velocidad")
	## Agresiva: mal genio y entrada fuerte (barrida o empujón).
	if float(infractor.get("agresividad", 0.5)) > 0.8 and tipo in ["deslizante", "empujon"]:
		factores.append("agresiva")
	## Falta profesional: corta una ocasión clara siendo el último hombre.
	if _ocasion_clara(victima, infractor) or _falta_tactica:
		factores.append("profesional")
	var puntos := 0.0
	for f: String in factores:
		puntos += float(PESO_FALTA[f])
	return {"puntos": puntos, "factores": factores}

func _mirar(p: Dictionary, rumbo: float, dur: float) -> void:
	p["mirar"] = rumbo
	p["mirar_hasta"] = t + dur

func _protestar(p: Dictionary) -> void:
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(ap):
		return
	var clip := "discutir_arbitro" if ap.has_animation("discutir_arbitro") else "protestar"
	_anim(p, clip, true, 2.4)
	for a: Dictionary in arbitros:
		if String(a.get("id", "")) == "arbitro" and is_instance_valid(a.get("node")):
			var d := (a["node"] as Node3D).position - pos(p)
			_mirar(p, atan2(d.x, d.z), 2.4)

static func _texto_factores(f: Array) -> String:
	var t: Array = []
	for k: String in f:
		t.append(String(NOMBRE_FACTOR.get(k, k)))
	return ", ".join(t)

func _falta(infractor: Dictionary, victima: Dictionary, prob_tarjeta := 0.25, motivo := "", tipo := "de_pie") -> void:
	if infractor == usuario:
		stats["faltas"] += 1
	if motivo != "":
		duelos["faltas"] += 1
		duelos["faltas_" + motivo] = int(duelos.get("faltas_" + motivo, 0)) + 1
	var lugar := pos(victima)
	var atacante_local := bool(victima["es_local"])
	var arco := _arco_rival(victima)
	var en_area := absf(lugar.x) < AREA_X and absf(lugar.z - arco.z) < AREA_Z
	var nombre := String((infractor.get("jugador", {}) as Dictionary).get("nombre", "Un defensor"))
	faltas[0 if bool(infractor["es_local"]) else 1] += 1
	## La sanción por puntos (con un margen de criterio del árbitro de ±0,4).
	## `prob_tarjeta` queda solo para quien llame sin tipo (compatibilidad).
	var pf := puntos_falta(infractor, victima, tipo)
	var total := float(pf["puntos"]) + _rng.randf_range(-0.4, 0.4)
	var roja_directa := total >= UMBRAL_ROJA
	var con_tarjeta := total >= UMBRAL_AMARILLA or _falta_tactica
	ultima_falta = {"puntos": total, "factores": pf["factores"], "sancion": "roja" if roja_directa else ("amarilla" if con_tarjeta else "falta")}
	var eq_inf := 0 if bool(infractor["es_local"]) else 1
	## M-139 (20-10): una entrada dura (nivel de amarilla o más) deja al
	## derribado en el suelo y lo atienden: medio minuto más de añadido.
	if total >= UMBRAL_AMARILLA:
		_sumar_anadido(0.5)
	if roja_directa:
		tarjetas_motor[eq_inf][1] += 1
	elif con_tarjeta:
		tarjetas_motor[eq_inf][0] += 1
	## LA VENTAJA (17-10-2026, M-106): una entrada que no llega, en campo
	## rival, sin tarjeta y con la víctima todavía con el balón: el árbitro
	## deja seguir con los dos brazos hacia delante. (Solo la entrada fallida:
	## en el choque o el agarrón la víctima cae o pierde el balón.)
	if motivo == "" and not con_tarjeta and not en_area and not _falta_tactica and poseedor == victima \
			and lugar.z * dir_ataque(atacante_local) > 4.0 and _rng.randf() < 0.35:
		aviso.emit("Ventaja")
		_gesto_arbitro("arbitro_ventaja", 0.0, 1.6, {"mira": lugar})
		return
	_gesto_arbitro("arbitro_silbato", 0.0, 0.9, {"mira": lugar})
	var tras := 0.8
	if con_tarjeta:
		## M-105 (20-10): el amonestado protesta mirando al árbitro (manos
		## abiertas, «¿qué he hecho?») mientras este se acerca con la tarjeta.
		_protestar(infractor)
		## Habla con el infractor y le enseña la tarjeta (con la cartulina en la mano).
		var sera_roja := tarjetas_reales and (roja_directa or int(infractor.get("amarillas", 0)) + 1 >= 2)
		_gesto_arbitro("arbitro_amonestar_hablar", 0.9, 1.5, {"mira_a": infractor})
		_gesto_arbitro("mostrar_roja" if sera_roja else "mostrar_tarjeta", 2.4, 2.0,
			{"mira_a": infractor, "tarjeta": "roja" if sera_roja else "amarilla"})
		tras = 4.5
	if en_area:
		_gesto_arbitro("arbitro_penal", tras, 1.8, {"mira": arco})
	else:
		## Señala hacia donde se saca: de cara a la portería del que la recibe.
		_gesto_arbitro("senalar_falta", tras, 1.6, {"mira": lugar + Vector3(0, 0, dir_ataque(atacante_local) * 10.0)})
	if con_tarjeta:
		if tarjetas_reales and roja_directa:
			aviso.emit("🟥 ¡Roja directa para %s! (%s)" % [nombre, _texto_factores(pf["factores"])])
			tarjeta.emit(String(infractor.get("id", "")), true, bool(infractor["es_local"]))
			_expulsar(infractor)
		elif tarjetas_reales:
			infractor["amarillas"] = int(infractor.get("amarillas", 0)) + 1
			var roja := int(infractor["amarillas"]) >= 2
			aviso.emit(("🟥 ¡Roja! Segunda amarilla para %s" if roja else "🟨 Amarilla para %s") % nombre)
			tarjeta.emit(String(infractor.get("id", "")), roja, bool(infractor["es_local"]))
			if roja:
				_expulsar(infractor)
		else:
			aviso.emit("🟨 Amarilla para %s" % nombre)
	if en_area:
		aviso.emit("¡PENAL!")
		_empezar_saque("penal", atacante_local, Vector3(0, R, arco.z - signf(arco.z) * PUNTO_PENAL))
	else:
		aviso.emit("Falta de %s" % nombre)
		_empezar_saque("falta", atacante_local, Vector3(lugar.x, R, lugar.z))

## BALÓN DIVIDIDO: el más cercano de cada equipo, los dos a menos de 1,7 m de
## un balón suelto y raso, llegando con menos de 0,35 s de diferencia.
func _duelo_dividido() -> void:
	if not poseedor.is_empty() or balon.position.y > 1.0 or _plano(vel_balon).length() > 10.0:
		return
	var b := _plano(balon.position)
	var cand := [{}, {}]
	var dist := [99.0, 99.0]
	for p: Dictionary in jugadores:
		if float(p["enfriar"]) > 0.0 or not _libre_para_duelo(p):
			continue
		var d := _plano(pos(p)).distance_to(b)
		var eq := 0 if bool(p["es_local"]) else 1
		if d < float(dist[eq]):
			dist[eq] = d
			cand[eq] = p
	if (cand[0] as Dictionary).is_empty() or (cand[1] as Dictionary).is_empty():
		return
	if maxf(dist[0], dist[1]) > 1.7 or minf(dist[0], dist[1]) > 1.1:
		return
	var eta := [0.0, 0.0]
	for k in 2:
		var p: Dictionary = cand[k]
		var hacia := b - _plano(pos(p))
		var acerca := (p["vel"] as Vector3).dot(hacia.normalized()) if hacia.length() > 0.01 else 3.0
		eta[k] = float(dist[k]) / maxf(acerca, 2.0)
		if p == pase_a:
			eta[k] = float(eta[k]) - 0.12
	if absf(float(eta[0]) - float(eta[1])) > 0.35:
		return
	var a: Dictionary = cand[0]
	var c: Dictionary = cand[1]
	duelos["dividido"] += 1
	a["contacto_hasta"] = t + 1.1
	c["contacto_hasta"] = t + 1.1
	var nota := [0.0, 0.0]
	for k in 2:
		var p: Dictionary = cand[k]
		nota[k] = -float(eta[k]) * 1.3 + _fuerza(p) * 0.4 + float(p["equilibrio"]) * 0.2 + float(p["attr"]["reg"]) * 0.1 + _rng.randf_range(-0.28, 0.28)
	var gana := 0 if float(nota[0]) >= float(nota[1]) else 1
	var w: Dictionary = cand[gana]
	var l: Dictionary = cand[1 - gana]
	var m := absf(float(nota[0]) - float(nota[1]))
	var entre := _plano(pos(l) - pos(w))
	if entre.length() < 0.01:
		entre = _derecha(w)
	if m < 0.05:
		## Llegan a la vez y chocan: el balón sale rebotado entre los dos.
		duelos["rebote"] += 1
		var lado := Vector3(-entre.z, 0, entre.x).normalized() * (1.0 if _rng.randf() < 0.5 else -1.0)
		vel_balon = lado * _rng.randf_range(2.5, 5.0) + Vector3(0, _rng.randf_range(0.8, 2.2), 0)
		penultimo_toque = ultimo_toque
		ultimo_toque = w
		pase_a = {}
		for p: Dictionary in cand:
			p["enfriar"] = maxf(float(p["enfriar"]), 0.3)
		_anim(w, "duelo_hombro_der" if _derecha(w).dot(entre) > 0.0 else "duelo_hombro_izq", true, 0.6)
		_anim(l, "duelo_hombro_der" if _derecha(l).dot(-entre) > 0.0 else "duelo_hombro_izq", true, 0.6)
		return
	_ganador(w, l)
	l["enfriar"] = maxf(float(l["enfriar"]), 0.55)
	_empujar(l, entre, 1.0 + m * 3.0, clampf(0.85 - m, 0.5, 0.9), 0.5)
	_anim(w, "duelo_hombro_der" if _derecha(w).dot(entre) > 0.0 else "duelo_hombro_izq", true, 0.6)
	## Llegar tarde con mal genio: entrada al tobillo y falta.
	var tarde := float(eta[1 - gana]) - float(eta[gana])
	if tarde > 0.1 and _rng.randf() < float(l["agresividad"]) * 0.2 * _escala_falta():
		_anim(l, "zancadilla" if _rng.randf() < 0.5 else "entrada_lateral_pie", true)
		_anim(w, "caida_fea", true, 1.2)
		_falta(l, w, 0.15 + float(l["agresividad"]) * 0.2, "dividido", "de_pie")
		return
	_anim(l, "duelo_empujado_der" if _derecha(l).dot(entre) > 0.0 else "duelo_empujado_izq", true, 0.7)

## HOMBRO CON HOMBRO: corren juntos (rumbos parecidos), uno al lado del otro,
## con el balón de por medio (uno lo lleva, va a recibirlo o va suelto por
## delante de los dos).
func _duelo_hombro(a: Dictionary, c: Dictionary, rel: Vector3, d: float) -> bool:
	## Con el balón de por medio se busca antes el hombro (si no, la entrada
	## de `_disputas`, que salta a 1,25 m, se adelantaba siempre).
	var con_balon := poseedor == a or poseedor == c
	if d < 0.45 or d > (1.3 if con_balon else 1.15):
		return false
	var va := _plano(a["vel"])
	var vc := _plano(c["vel"])
	var sa := va.length()
	var sc := vc.length()
	if sa < 3.0 or sc < 3.0:
		return false
	if (va / sa).dot(vc / sc) < 0.55:
		return false
	var rumbo := (va / sa + vc / sc).normalized()
	var adelante := rel.dot(rumbo)
	var lateral := rel - rumbo * adelante
	if lateral.length() < 0.3:
		return false
	var implicado := poseedor == a or poseedor == c or pase_a == a or pase_a == c
	if not implicado and poseedor.is_empty():
		var hacia := _plano(balon.position - (pos(a) + pos(c)) * 0.5)
		implicado = hacia.length() < 9.0 and hacia.normalized().dot(rumbo) > 0.5
	if not implicado:
		return false
	duelos["hombro"] += 1
	a["contacto_hasta"] = t + 1.3
	c["contacto_hasta"] = t + 1.3
	## El que va medio cuerpo por delante tiene ventaja de posición.
	var na := _fuerza(a) * 0.4 + float(a["equilibrio"]) * 0.2 + sa / 8.0 * 0.2 - adelante * 0.15 + _rng.randf_range(-0.3, 0.3)
	var nc := _fuerza(c) * 0.4 + float(c["equilibrio"]) * 0.2 + sc / 8.0 * 0.2 + adelante * 0.15 + _rng.randf_range(-0.3, 0.3)
	var w := a if na >= nc else c
	var l := c if na >= nc else a
	var m := absf(na - nc)
	_ganador(w, l)
	var fuera := _plano(pos(l) - pos(w))
	fuera = (fuera - rumbo * fuera.dot(rumbo)).normalized()
	_anim(w, "duelo_hombro_der" if _derecha(w).dot(fuera) > 0.0 else "duelo_hombro_izq", true, 0.6)
	_anim(l, "duelo_empujado_der" if _derecha(l).dot(fuera) > 0.0 else "duelo_empujado_izq", true, 0.7)
	_empujar(l, fuera, 1.2 + m * 3.0, clampf(0.85 - m * 0.6, 0.5, 0.9), 0.55)
	_empujar(w, -fuera, 0.4, 0.96, 0.3)
	var era_suyo := poseedor == l
	if era_suyo or poseedor == w:
		duelos["hombro_con_balon"] = int(duelos.get("hombro_con_balon", 0)) + 1
	if era_suyo:
		if _rng.randf() < clampf(0.25 + m * 1.6, 0.0, 0.85):
			## Se le va el balón: sigue rodando por delante, libre.
			duelos["balon_perdido"] += 1
			l["enfriar"] = maxf(float(l["enfriar"]), 0.6)
			poseedor = {}
			_jugada = {}
			ultimo_toque = l
			vel_balon = rumbo * maxf(_plano(l["vel"]).length() * 0.9, 4.0) + fuera * 0.8
		else:
			w["enfriar"] = maxf(float(w["enfriar"]), 0.4)
	elif poseedor == w or poseedor.is_empty() or pase_a == w:
		l["enfriar"] = maxf(float(l["enfriar"]), 0.45)
	## Ganar el choque con los brazos o por detrás contra el que lleva el balón.
	if era_suyo and _rng.randf() < (0.08 + float(w["agresividad"]) * 0.08 + m * 0.08) * _escala_falta():
		_anim(l, "caida_fea", true, 1.2)
		_falta(w, l, 0.06 + float(w["agresividad"]) * 0.1, "hombro", "empujon" if float(w["agresividad"]) > 0.7 else "hombro")
	return true
