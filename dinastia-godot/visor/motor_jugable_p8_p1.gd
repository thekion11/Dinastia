extends "res://visor/motor_jugable_p7.gd"
## (Parte 1 de 2 de `motor_jugable_p8.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `motor_jugable_p8.gd`, conserva la clase.)

static var ANTICIPA := OS.get_environment("PMOT_ANT") != "0"   ## encendido el 3-11 (vídeo del dueño: persecución en vez de intercepción); PMOT_ANT=0 = antes
## [Capa 8/12 de `motor_jugable.gd`] _forma, _zona_de_llegada, _ia_ataque_sin_balon, _gatillo_presion, _linea_defensiva, _ia_defensa … (+10)

## La forma del equipo: la posición de la formación, movida con el balón.
func _forma(p: Dictionary, en_posesion: bool) -> Vector3:
	var base: Vector3 = MotorRoles.base(self as Object as MotorJugable, p)   ## puesto dinámico (F2, 03-11)
	var loc0 := bool(p["es_local"])
	var b := MotorColocacion.balon_lento(self as Object as MotorJugable, loc0)   ## balón con retardo (F1, 03-11)
	var pesos := MotorColocacion.pesos(self as Object as MotorJugable, loc0, en_posesion)
	var d := dir_ataque(bool(p["es_local"]))
	## La pizarra (con todo a 1, lo de siempre): la línea adelanta o retrasa el
	## bloque, la mentalidad lo empuja y la amplitud abre a los de banda.
	var loc := bool(p["es_local"])
	var lin := float(_tac(loc, "linea") - 1) + MotorTacticaViva.f(self as Object as MotorJugable, loc, "linea")   ## + estilo del club (U8)
	var men := float(_tac(loc, "mentalidad") - 1) + MotorTacticaViva.urgencia(self as Object as MotorJugable, loc)   ## + marcador y reloj (U2, 01-11)
	var amp := float(_tac(loc, "amplitud") - 1) + MotorTacticaViva.f(self as Object as MotorJugable, loc, "amplitud")
	var z := base.z * pesos[2] + b.z * pesos[0] + (d * (9.0 + men * 3.0) if en_posesion else -d * 3.0)
	z += d * (lin * 3.5 + men * 2.0)
	var x := base.x * (pesos[3] + (amp * 0.12 if en_posesion else 0.0)) + b.x * pesos[1] + MotorAdaptacion.desvio_x(self as Object as MotorJugable, loc0, en_posesion)   ## cubre el lado fuerte del rival (3-11)
	## Nadie se mete detrás de su propio arco ni más allá del rival.
	z = clampf(z, -LARGO + 4.0, LARGO - 4.0)
	return Vector3(clampf(x, -ANCHO + 2.0, ANCHO - 2.0), 0, z)

func _zona_de_llegada(p: Dictionary) -> Vector3:
	if not LLEGADA or poseedor.is_empty() or poseedor == p or bool(poseedor["es_local"]) != bool(p["es_local"]):
		return Vector3.INF
	var arco := _arco_rival(p)
	var pb := pos(poseedor)
	if pb.distance_to(arco) > MotorApoyo.LLEGADA_R:
		return Vector3.INF
	## Los dos apoyos cercanos siguen ofreciéndose al portador.
	if pos(p).distance_to(pb) < 9.0:
		return Vector3.INF
	var dz := dir_ataque(bool(p["es_local"]))
	var lado := signf(pb.x) if absf(pb.x) > 3.0 else 1.0
	var rol := _rol(p)
	var px := pos(p).x
	match rol:
		"DC":
			## Con el balón en la banda, al primer palo; si no, al punto de penal.
			if absf(pb.x) > 12.0:
				return Vector3(lado * 3.5, 0, arco.z - dz * 6.5)
			return Vector3(-lado * 1.5, 0, arco.z - dz * 10.5)
		"ED", "EI":
			## El extremo del lado contrario cierra al segundo palo; el del lado
			## del balón se queda abierto (apoyo o centro).
			if signf(px) != lado:
				return Vector3(-lado * 5.0, 0, arco.z - dz * 7.5)
			return Vector3.INF
		"MC":
			## Solo el más adelantado de los medios llega a la frontal.
			var mas_adelantado := true
			for q: Dictionary in jugadores:
				if q != p and bool(q["es_local"]) == bool(p["es_local"]) and _rol(q) == "MC" \
						and (pos(q).z - pos(p).z) * dz > 0.0:
					mas_adelantado = false
					break
			if mas_adelantado:
				return Vector3(-lado * 4.0, 0, arco.z - dz * 17.0)
	return Vector3.INF

func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
	p["correr"] = false
	## Si la jugada prehecha le da un destino a su puesto, va ahí.
	if not _jugada.is_empty() and bool(_jugada["local"]) == bool(p["es_local"]):
		var dest: Dictionary = _jugada.get("destinos", {})
		var rol := _rol(p)
		if dest.has(rol):
			p["correr"] = true
			## El desmarque de la jugada respeta la línea del fuera de juego
			## mientras el balón no sale (sin esto, 10-13 por partido).
			var dz := dir_ataque(bool(p["es_local"]))
			var linea := _ultima_linea(not bool(p["es_local"]))
			var dd: Vector3 = dest[rol]
			if (dd.z - linea) * dz > -0.5 and (dd.z - balon.position.z) * dz > 0.0:
				dd.z = linea - dz * 0.6
			return dd
	var obj := _forma(p, true)
	## Apoyo: los dos más cercanos al portador se ofrecen en ángulo.
	if not poseedor.is_empty():
		var d := pos(p).distance_to(pos(poseedor))
		if MotorApoyo.activo():
			obj = MotorApoyo.punto(self as Object as MotorJugable, p, poseedor, obj)   ## campo de fuerzas (F3, 03-11)
		elif d < 14.0:
			var lado := signf(pos(p).x - pos(poseedor).x)
			if lado == 0.0:
				lado = 1.0
			obj = pos(poseedor) + Vector3(lado * 9.0, 0, dir_ataque(bool(p["es_local"])) * 5.0)
	## LLEGADA AL ÁREA (20-10-2026, más chispa): con el balón de un compañero
	## en el último tercio, el ataque ocupa el área como en el fútbol de verdad
	## (antes casi nadie pisaba el área y no había a quién centrar).
	var zona := _zona_de_llegada(p); zona = zona if zona != Vector3.INF else MotorRebote.objetivo(self as Object as MotorJugable, p)   ## ciclo 28: rebote / segundo palo
	if zona != Vector3.INF:
		obj = zona
		p["correr"] = true
	## Los delanteros atacan el espacio a la espalda de la defensa.
	var linea := _ultima_linea(not bool(p["es_local"]))
	var dz := dir_ataque(bool(p["es_local"]))
	var obj0 := obj
	if _rol(p) in ["DC", "ED", "EI", "SD"]:
		obj.z = clampf(linea - dz * 0.6, -LARGO + 6.0, LARGO - 6.0) if (linea - pos(p).z) * dz > -8.0 else obj.z
		## Solo UN delantero a la vez hace la carrera al hueco; los demás mantienen la forma (F5, 03-11).
		if MotorCarreras.activo() and (linea - pos(p).z) * dz > -8.0:
			obj = MotorCarreras.objetivo(self as Object as MotorJugable, p, obj0, linea, dz)
	## Y NADIE se queda en fuera de juego esperando (MEGAPLAN fase 3): el
	## central que subió al córner o el lateral que se proyectó vuelven a
	## estar habilitados mientras el balón no pase la línea.
	var tope := maxf(linea * dz, balon.position.z * dz) - 0.6
	if obj.z * dz > tope:
		obj.z = tope * dz
	return obj

## ¿Toca apretar al que lleva el balón? Los gatillos clásicos de la presión:
##   · acaba de recibir y aún no se ha acomodado (medio segundo);
##   · está pegado a la banda (la línea es un defensor más);
##   · está de espaldas al juego, mirando a su propio arco;
##   · lo tiene un defensa o el portero cerca de su área (salida de balón).
func _gatillo_presion(dueno: Dictionary) -> bool:
	var q := pos(dueno)
	## Tras perder el balón (fila 18): con contrapresión se muerde más rato; replegando, menos.
	if t - float(_eq_tomo_en[0 if bool(dueno["es_local"]) else 1]) < [0.3, 0.6, 1.5][clampi(_tac(not bool(dueno["es_local"]), "tras_perdida"), 0, 2)]:
		return true
	if absf(q.x) > 28.0:
		return true
	var propio := _arco_propio(dueno)
	var mira := Vector3(sin(float(dueno.get("mirar", 0.0))), 0, cos(float(dueno.get("mirar", 0.0))))
	if mira.dot((propio - q).normalized()) > 0.6:
		return true
	if MotorPresion.zona(self as Object as MotorJugable, dueno):   ## presión por zona (U1, 01-11)
		return true
	return q.distance_to(propio) < 24.0 and _rol(dueno) in ["DFC", "LD", "LI", "POR"]

func _linea_defensiva(local: bool) -> float:
	var eq := 0 if local else 1
	if _linea_def_t[eq] == t:
		return _linea_def[eq]
	var d := dir_ataque(local)
	var b := balon.position
	## Base: la forma de los defensores (z media), como hasta ahora.
	var suma := 0.0
	var n := 0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == local and _rol(q) in ["DFC", "LD", "LI"]:
			suma += _forma(q, false).z
			n += 1
	var z := suma / float(n) if n > 0 else -d * 30.0
	var trampa := int((tacticas[eq] as Dictionary).get("trampa", 0)) == 1
	## El portador rival: ¿libre y de cara, o apretado?
	if not poseedor.is_empty() and bool(poseedor["es_local"]) != local:
		var libre := _presion(poseedor) > 4.0
		if libre:
			z -= d * 4.0
		elif trampa:
			z += d * 3.0
	## Balón que viaja hacia el campo del rival (pase atrás o despeje): se sube.
	if poseedor.is_empty() and vel_balon.z * d > 3.0:
		z += d * (5.0 if trampa else 2.5)
	## Nunca por delante del balón (la línea no deja el balón a su espalda)…
	var lim_balon := b.z - d * 1.5
	if (z - lim_balon) * d > 0.0:
		z = lim_balon
	## …ni dentro del área chica.
	var fondo := -d * (LARGO - 6.0)
	if (z - fondo) * d < 0.0:
		z = fondo
	## Movimiento suave: sube despacio, recula rápido (como una defensa de verdad).
	if _linea_def_t[eq] >= 0.0 and _linea_def[eq] != INF:
		var dt_ := clampf(t - float(_linea_def_t[eq]), 0.0, 0.5)
		var sube := (z - float(_linea_def[eq])) * d > 0.0
		var vel := (6.0 if trampa else 4.0) if sube else 7.5
		z = move_toward(float(_linea_def[eq]), z, vel * dt_)
	_linea_def[eq] = z
	_linea_def_t[eq] = t
	return z

func _ia_defensa(p: Dictionary) -> Vector3:
	p["correr"] = false
	var b := balon.position
	var arco := _arco_propio(p)
	## El que presiona y el segundo, estables (R3, 01-11: `MotorPresion`); el segundo cubre entre el balón y el arco.
	var pp := MotorPresion.papeles(self as Object as MotorJugable, bool(p["es_local"]))
	var yo := String(p.get("id", ""))
	## Presión baja: lejos de su área se temporiza; presión alta: van dos.
	var pres := _tac(bool(p["es_local"]), "presion")
	## GATILLOS DE PRESIÓN (21-10-2026, M-124): hay momentos en que hasta un
	## equipo que espera sale a morder (`_gatillo_presion`).
	var gatillo := false
	if not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]):
		gatillo = _gatillo_presion(poseedor)
	if yo != "" and pp[0] == yo:
		if pres == 0 and not gatillo and b.distance_to(arco) > 42.0 and pos(p).distance_to(b) > 9.0:
			return b + (arco - b).normalized() * 5.0
		p["correr"] = true
		## (Sondas, PMOT_ANT=1: el que presiona va adonde VA a estar el portador.)
		if ANTICIPA and not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]):
			var ba := b + _plano(poseedor["vel"] as Vector3) * clampf(pos(p).distance_to(b) / 8.0, 0.0, 0.5)
			return ba + (arco - ba).normalized() * 0.8
		return b + (arco - b).normalized() * 0.8
	if yo != "" and pp[1] == yo:
		if pres == 2 or (pres == 1 and gatillo):
			p["correr"] = true
			return b + (arco - b).normalized() * 2.5
		return b + (arco - b).normalized() * 7.0
	## CONTRAPRESIÓN (10-11, «tras la pérdida» ALTO): en la ventana en que el equipo acaba de perder el balón, los que están cerca de él lo aprietan todos
	## (hasta entonces solo cambiaba al segundo presionador y no se notaba en el juego). Sin la línea defensiva ni el portero, a menos de 9 m.
	if gatillo and _tac(bool(p["es_local"]), "tras_perdida") >= 2 and not bool(p["por"]) and not (_rol(p) in ["DFC", "LD", "LI"]) and pos(p).distance_to(b) < 9.0 \
			and t - float(_eq_tomo_en[0 if bool(poseedor["es_local"]) else 1]) < 1.5:
		p["correr"] = true
		return b + (arco - b).normalized() * 3.0
	## MARCAJE A LOS PELIGROSOS (F4, 03-11): un marcador por cada uno de los 3 más peligrosos, con ancla a su puesto.
	var om := MotorMarcaje.objetivo(self as Object as MotorJugable, p, arco)
	if om != Vector3.INF:
		return MotorAncla.limitar(self as Object as MotorJugable, p, om)
	## Los demás: zona, marcando al rival más cercano.
	var obj := _forma(p, false)
	var rival: Dictionary = {}
	var al_hombre := MotorTacticaViva.bandera(self as Object as MotorJugable, bool(p["es_local"]), "marca")   ## pizarra: marca al hombre (01-11)
	var md := 16.0 if al_hombre else 11.0
	var r_vista := MotorMente.retardo(self as Object as MotorJugable, p)   ## (13-11, rendimiento) una vez por jugador, no por rival
	var es_local_p := bool(p["es_local"])
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != es_local_p and not bool(q["por"]):
			var d := MotorMente.pos_vista_con(self as Object as MotorJugable, q, r_vista).distance_to(obj)
			if d < md:
				md = d
				rival = q
	if not rival.is_empty():
		## Marca a distancia de zona: entre el rival y el arco, a 2,4 m (donde LO VE: F8, 03-11).
		var pv := MotorMente.pos_vista(self as Object as MotorJugable, p, rival)
		obj = pv + (arco - pv).normalized() * (1.2 if al_hombre else 2.4)
	## La defensa no persigue a cada delantero hacia su arco: se queda en la
	## línea común (M-123) y solo cierra por dentro hacia el que marca.
	if _rol(p) in ["DFC", "LD", "LI"] and not _SIN_LINEA:
		obj.z = _linea_defensiva(bool(p["es_local"]))
	return MotorAncla.limitar(self as Object as MotorJugable, p, MotorRegiones.libre(self as Object as MotorJugable, p, obj))   ## región propia + ancla (3-11)

# ---------------------------------------------------------------- IA

func _ia_equipos(delta: float) -> void:
	var b := balon.position
	var equipo_con_balon := -1
	if not poseedor.is_empty():
		equipo_con_balon = 0 if bool(poseedor["es_local"]) else 1
	elif not ultimo_toque.is_empty():
		equipo_con_balon = 0 if bool(ultimo_toque["es_local"]) else 1
	## Quién va a por el balón suelto: el más rápido de cada equipo en llegar.
	var persigue := [{}, {}]
	if poseedor.is_empty():
		var destino := b + Vector3(vel_balon.x, 0, vel_balon.z) * 0.35
		## Con un pase en camino, el rival solo sale a cortarlo si llega antes
		## que el receptor al punto donde se recibe (sin esto cortaba cuatro de
		## cada diez pases: el que persigue siempre iba a la línea del balón).
		var recep := _punto_de_recepcion() if not pase_a.is_empty() else Vector3.ZERO
		var d_recep := pos(pase_a).distance_to(recep) if not pase_a.is_empty() else 0.0
		for eq in 2:
			var md := 999.0
			for p: Dictionary in jugadores:
				if (0 if bool(p["es_local"]) else 1) != eq or bool(p["por"]):
					continue
				var d := pos(p).distance_to(Vector3(destino.x, 0, destino.z))
				if not pase_a.is_empty() and bool(pase_a["es_local"]) != bool(p["es_local"]) \
						and pos(p).distance_to(recep) > d_recep * 0.8:
					continue
				if d < md:
					md = d
					persigue[eq] = p
	## La jugada prehecha del equipo que ataca.
	if not poseedor.is_empty():
		_guiar_jugada(delta)
	for p: Dictionary in jugadores:
		if p == usuario and not autopiloto:
			continue
		var eq := 0 if bool(p["es_local"]) else 1
		if bool(p["por"]):
			## Si lo manejas con R3 (o lo mandaste al palo largo), manda tu orden.
			if float(p.get("mandado_hasta", 0.0)) > t:
				continue
			p["objetivo"] = _ia_portero(p)
			continue
		if p == poseedor:
			_ia_portador(p)
			continue
		if not pase_a.is_empty() and p == pase_a:
			p["objetivo"] = _punto_de_recepcion()
			p["correr"] = true
			continue
		if poseedor.is_empty() and p == persigue[eq]:
			p["objetivo"] = b + Vector3(vel_balon.x, 0, vel_balon.z) * 0.35
			p["correr"] = true
			continue
		if equipo_con_balon == eq:
			p["objetivo"] = _ia_ataque_sin_balon(p)
		else:
			p["objetivo"] = _ia_defensa(p)

## El stick (o las teclas) en el plano del campo: según la cámara o el campo.
func _a_mundo(v: Vector2, d: float) -> Vector3:
	var mundo := Vector3(-v.x * d, 0, -v.y * d)
	if camara != null and is_instance_valid(camara) and Mando.ayuda("direccion") == "camara":
		var f := -camara.global_basis.z
		f.y = 0.0
		var r := camara.global_basis.x
		r.y = 0.0
		if f.length() > 0.01 and r.length() > 0.01:
			mundo = r.normalized() * v.x + f.normalized() * (-v.y)
	return mundo

## TÁCTICAS RÁPIDAS (cruceta): mentalidad arriba/abajo, presión de equipo 45 s
## y laterales al ataque. Solo con todo el equipo en tus manos.
func _tacticas_rapidas() -> void:
	if control_equipo < 0:
		return
	var eq := control_equipo
	var tc: Dictionary = tacticas[eq]
	var cambio := ""
	if _presion_equipo_hasta > 0.0 and t > _presion_equipo_hasta:
		_presion_equipo_hasta = 0.0
		tc["presion"] = int(_tac_base[eq].get("presion", 1))
		cambio = "presion"
		aviso.emit("Presión de equipo: se acaba")
	if Input.is_action_just_pressed("jugar_tac_arriba"):
		tc["mentalidad"] = mini(int(tc.get("mentalidad", 1)) + 1, 2)
		cambio = "mentalidad"
		aviso.emit("⚔ Mentalidad: %s" % ["defensiva", "equilibrada", "ofensiva"][int(tc["mentalidad"])])
	elif Input.is_action_just_pressed("jugar_tac_abajo"):
		tc["mentalidad"] = maxi(int(tc.get("mentalidad", 1)) - 1, 0)
		cambio = "mentalidad"
		aviso.emit("🛡 Mentalidad: %s" % ["defensiva", "equilibrada", "ofensiva"][int(tc["mentalidad"])])
	elif Input.is_action_just_pressed("jugar_tac_izquierda"):
		_tac_base[eq] = tc.duplicate()
		tc["presion"] = 2
		cambio = "presion"
		_presion_equipo_hasta = t + 45.0
		aviso.emit("🔥 ¡Presión de equipo!")
	elif Input.is_action_just_pressed("jugar_tac_derecha"):
		tc["amplitud"] = 2 if int(tc.get("amplitud", 1)) < 2 else 1
		cambio = "amplitud"
		aviso.emit("↗ Laterales al ataque" if int(tc["amplitud"]) == 2 else "Laterales en su sitio")
	tacticas[eq] = tc
	if cambio != "":
		tactica_rapida.emit(eq, cambio, int(tc[cambio]))

## LA BARRIDA DEL USUARIO (25-10-2026): se tira al suelo hacia donde va a estar
## el rival (un impulso con inercia, no un salto de 1,6 m en un fotograma) y la
## entrada se decide cuando llega al balón. Si el rival se va antes, se queda
## en el suelo un momento: la barrida fallida también se paga.
func _lanzar_barrida(p: Dictionary) -> void:
	var rp := pos(poseedor) + _plano(poseedor["vel"] as Vector3) * 0.25
	var dir := _plano(rp - pos(p))
	if dir.length() < 0.01:
		var ry := (p["node"] as Node3D).rotation.y
		dir = Vector3(sin(ry), 0, cos(ry))
	dir = dir.normalized()
	p["vel"] = dir * maxf(_plano(p["vel"] as Vector3).dot(dir), 7.5)
	_empujar(p, dir, 4.0, 1.0, 0.0)
	_mirar(p, atan2(dir.x, dir.z), 0.45)
	p["barrida_hasta"] = t + 0.45
	p["barrida_dir"] = dir
	## (31-10) Una de cada tres, la barrida de la UAL2: entra, se desliza y se levanta (1,8 s; las hechas a mano duran menos).
	if _rng.randf() < 0.34 and AnimExtra.unir(p.get("anim"), FutbolistaQ.esqueleto_de(p["node"]), "barrida_real", AnimExtra.BARRIDA_REAL):
		_anim(p, "barrida_real", true, 1.9)
	else:
		_anim(p, ["barrida_lateral", "barrida_corta", "barrida_rapida", "barrida_larga"][_rng.randi() % 4], true)

## Mientras dura, el que barre no maneja nada (está en el suelo): true.
func _seguir_barrida(p: Dictionary) -> bool:
	## LEVANTÁNDOSE (31-10): tras la barrida de la UAL2 sigue en el suelo, frenando, hasta que el clip lo pone de pie (si no, se le
	## veía deslizarse tumbado a velocidad de carrera).
	if float(p.get("levanta_hasta", 0.0)) > t:
		p["objetivo"] = pos(p)
		p["correr"] = false
		return true
	if float(p.get("barrida_hasta", 0.0)) <= 0.0:
		return false
	if String(p.get("anim_actual", "")) == "barrida_real":
		p["levanta_hasta"] = float(p.get("gesto_hasta", 0.0)) - 0.15
	if not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]) and pos(poseedor).distance_to(pos(p)) < 1.4:
		p["barrida_hasta"] = 0.0
		_entrada(p, true)
		return true
	if t >= float(p["barrida_hasta"]) or poseedor == p:
		p["barrida_hasta"] = 0.0
		if poseedor != p:
			p["enfriar"] = maxf(float(p["enfriar"]), 0.8)
		return false
	p["objetivo"] = pos(p) + (p.get("barrida_dir", Vector3.FORWARD) as Vector3) * 3.0
	p["correr"] = true
	return true

## La pared: el que la dio corre al espacio mientras dure.
func _seguir_pared() -> void:
	if _pared.is_empty():
		return
	if t > float(_pared["hasta"]):
		_pared = {}
		return
	var de: Dictionary = _pared["de"]
	if de == usuario or de == poseedor:
		return
	var dd := dir_ataque(bool(de["es_local"]))
	de["objetivo"] = pos(de) + Vector3(0, 0, dd * 8.0)
	de["correr"] = true

func _mi_portero(p: Dictionary) -> Dictionary:
	for q: Dictionary in jugadores:
		if bool(q["por"]) and bool(q["es_local"]) == bool(p["es_local"]):
			return q
	return {}

## El portero que mandas con R3 o con el doble toque de Y (palo largo).
func _seguir_portero_mandado() -> void:
	if usuario.is_empty():
		return
	var gk := _mi_portero(usuario)
	if gk.is_empty() or gk == usuario or gk == poseedor:
		return
	if t < _palo_largo_hasta:
		var arco := _arco_propio(gk)
		var largo := -signf(balon.position.x + 0.01)
		gk["objetivo"] = Vector3(largo * PALO * 0.55, 0, arco.z - signf(arco.z) * 0.8)

## EL PORTERO QUE MANEJAS (Carrera de Jugador, 25-10-2026), sin el balón. Ante
## un tiro, el lado de la estirada lo elige el stick (`_reaccion_portero`); en
## plena estirada sigue el gesto; con el stick quieto se coloca solo, como la IA.
## Devuelve true si este fotograma ya lo resolvió el portero.
func _portero_usuario(p: Dictionary, mundo: Vector3) -> bool:
	if float(p.get("gesto_hasta", 0.0)) > t and p.has("_obj_gesto"):
		p["objetivo"] = p["_obj_gesto"]
		return true
	if _reaccion_portero(p, true, mundo.x):
		p["_obj_gesto"] = p["objetivo"]
		return true
	if mundo.length() < 0.1:
		p["objetivo"] = colocacion_portero(balon.position, _arco_propio(p), _tac(bool(p["es_local"]), "linea"))
	return false
