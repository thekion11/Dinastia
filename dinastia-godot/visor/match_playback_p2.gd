extends "res://visor/match_playback_p1.gd"
## [Capa 2/4 de `match_playback.gd`] _ejecutar_accion, _decidir_regate, _animar, _resolver_choques, _mover, _mas_cercano_a … (+2)

func _ejecutar_accion(p: Dictionary, anim_name: String, duracion: float) -> void:
	var pid = p.get("id")
	if pid == null:
		return
	var ap: AnimationPlayer = p.get("anim")
	## EL PORTAFOLIO (26-9-2026): el zurdo patea con la zurda y los regates,
	## festejos y lamentos se eligen entre muchas variantes.
	if is_instance_valid(ap):
		anim_name = AnimExtra.variante(ap, anim_name, str(pid), _rng)
	_acciones_activas[pid] = {"anim": anim_name, "hasta": elapsed + duracion}
	if is_instance_valid(ap) and ap.has_animation(anim_name):
		ap.play(anim_name)
		ap.speed_scale = 1.0

func _decidir_regate(p: Dictionary, vel: float) -> void:
	var pid = p.get("id")
	if pid == null or _acciones_activas.has(pid) or _esta_celebrando(p):
		return
	if elapsed < float(_proximo_regate.get(pid, 0.0)):
		return
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(ap):
		return
	var es_local: bool = p["es_local"]
	var rival: Variant = _rival_mas_cercano(p, es_local)
	var n: Node3D = p["node"]
	if rival != null and (rival["node"] as Node3D).position.distance_to(n.position) < RADIO_PRESION \
			and ap.has_animation("regate_finta"):
		_ejecutar_accion(p, "regate_finta", 1.3)
		_proximo_regate[pid] = elapsed + PAUSA_ENTRE_REGATES
		regates_hechos += 1
		Sonido.toca("regate")
		return
	var ataca := (fase == "ataqueLocal" and es_local) or (fase == "ataqueVisita" and not es_local)
	if ataca and vel < 0.35 and ap.has_animation("regate_pausa") and _rng.randf() < 0.35:
		_ejecutar_accion(p, "regate_pausa", 2.0)
		_proximo_regate[pid] = elapsed + PAUSA_ENTRE_REGATES
		return
	## Tampoco se reintenta cada fotograma: una decisión cada medio segundo.
	_proximo_regate[pid] = elapsed + 0.5

func _animar(p: Dictionary, ap: AnimationPlayer, vel: float, celebrando: bool) -> void:
	if not is_instance_valid(ap):
		return
	var pid = p.get("id")
	if pid != null and _acciones_activas.has(pid):
		var acc: Dictionary = _acciones_activas[pid]
		if elapsed < acc["hasta"]:
			var nom: String = acc["anim"]
			if ap.current_animation != nom and ap.has_animation(nom):
				ap.play(nom)
				ap.speed_scale = 1.0
			return
		else:
			_acciones_activas.erase(pid)

	var realista := ap.has_animation("correr")
	var es_por: bool = str(p.get("slot_code", "")) == "POR"
	var quiere: String
	if celebrando:
		quiere = "celebrar" if realista else "jump"
	elif realista and vel > 0.9 and vel < 2.0 and not _portador.is_empty() and p.get("id") == _portador.get("id") \
			and ap.has_animation("conducir"):
		quiere = "conducir"
	elif vel > 2.6:
		quiere = "correr" if realista else "run"
	elif vel > 1.1:
		quiere = "trotar" if realista else "run"
	elif vel > 0.35:
		quiere = "caminar" if realista else "run"
	elif es_por and realista and ap.has_animation("portero_listo"):
		quiere = "portero_listo"
	else:
		quiere = "parado" if realista else "idle"
	if ap.current_animation != quiere and ap.has_animation(quiere):
		ap.play(quiere)
	if VEL_CICLO.has(quiere):
		## Documento maestro: TimeScale = velocidad real / velocidad de ciclo,
		## acotado para que el pie no deslice ni se convierta en un dibujo.
		ap.speed_scale = clampf(vel / float(VEL_CICLO[quiere]), 0.6, 1.4)
	else:
		ap.speed_scale = 1.0

func _resolver_choques() -> void:
	var n := players.size()
	var minimo := RADIO_CUERPO * 2.0
	for i in n:
		var a: Node3D = players[i].get("node")
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, n):
			var b: Node3D = players[j].get("node")
			if not is_instance_valid(b):
				continue
			var dx := b.position.x - a.position.x
			var dz := b.position.z - a.position.z
			var d2 := dx * dx + dz * dz
			if d2 >= minimo * minimo:
				continue
			var d := sqrt(d2)
			var dir := Vector2(dx, dz) / d if d > 0.001 else Vector2(1.0, 0.0).rotated(float(i * 7 + j))
			var mitad := (minimo - d) * 0.5
			a.position.x -= dir.x * mitad
			a.position.z -= dir.y * mitad
			b.position.x += dir.x * mitad
			b.position.z += dir.y * mitad

func _mover(delta: float) -> void:
	if is_instance_valid(ball) and ball is Balon3D:
		(ball as Balon3D).avanzar(delta)

	var vivas: Array = []
	for c in _celebrando:
		if elapsed < c["hasta"]:
			vivas.append(c)
	_celebrando = vivas

	var bola: Vector3 = ball.position if is_instance_valid(ball) else Vector3.ZERO
	_portador = _buscar_portador(bola)
	_presionador = {}
	if fase == "ataqueLocal" or fase == "ataqueVisita":
		## Defiende el que no ataca; su jugador de campo más cercano al balón
		## sale a presionarlo.
		var r: Variant = _companero_mas_cercano_al_balon(fase == "ataqueVisita", bola)
		if r != null and (r["node"] as Node3D).position.distance_to(bola) < RADIO_IR_A_PRESIONAR:
			_presionador = r

	for p in players:
		var node: Node3D = p["node"]
		if not is_instance_valid(node):
			continue
		var ap: AnimationPlayer = p["anim"]
		var es_local: bool = p["es_local"]
		var base: Vector3 = p["base_pos"]
		var es_por: bool = str(p.get("slot_code", "")) == "POR"

		## Jugador nuevo (entra por cambio a mitad de partido, `_al_cambio()` en
		## `estadio.gd`): no paso por `setup()`, asi que estos campos no
		## existen todavia. Se siembran aqui mismo, una sola vez, ANTES de
		## calcular el objetivo -`_objetivo_jugador()` ya necesita `_reaccion`.
		if not p.has("_vel"):
			var h: int = hash(str(p.get("id", "")))
			p["_fase"] = float(h % 6283) / 1000.0
			p["_vel_mult"] = 0.90 + float((h / 7) % 1000) / 1000.0 * 0.22
			## RONDA 2 (17-9-2026): cuanto tarda ESTE jugador en reaccionar a
			## un cambio de fase del juego -1.8 a 3.2 s. Sin esto los 22 se
			## reposicionan en el mismo fotograma exacto en que cambia `fase`,
			## que es la parte MAS robotica de todas: da igual lo suave que
			## sea el movimiento de cada uno si los 22 deciden a la vez, como
			## una sola mente. Un rango de reaccion, no un numero fijo: no
			## todos los futbolistas leen el juego igual de rapido.
			p["_reaccion"] = 1.8 + float((h / 13) % 1000) / 1000.0 * 1.4
			p["_empuje_actual"] = 0.0
			p["_vel"] = Vector3.ZERO

		var objetivo: Vector3
		var pid_guion = p.get("id")
		## JUGADAS PREHECHAS: el guion manda por encima de TODO lo demas -incluida
		## la celebracion-. `_celebrar()` marca tambien al asistidor como
		## "celebrando" (linea que ya existia antes de esta pieza), y esa rama iba
		## ANTES en la cadena de prioridad: sin este chequeo primero, el destino de
		## la jugada quedaba calculado pero nunca se usaba, el asistidor se iba
		## derecho a la banda a celebrar como si el pase no fuera suyo.
		if pid_guion != null and float(_guion_hasta.get(pid_guion, -1.0)) > elapsed:
			objetivo = _guion_destino[pid_guion]
			objetivo.x = clampf(objetivo.x, -MEDIO_ANCHO + 0.5, MEDIO_ANCHO - 0.5)
			objetivo.z = clampf(objetivo.z, -MEDIO_LARGO + 0.5, MEDIO_LARGO - 0.5)
		elif bool(p.get("arbitro", false)):
			objetivo = _objetivo_arbitro(p, base, bola)
		elif _esta_celebrando(p):
			objetivo = Vector3(sign(base.x) * 32.0, 0, base.z * 0.4)
		elif es_por:
			objetivo = _objetivo_portero(base, bola, es_local)
		else:
			objetivo = _objetivo_jugador(base, bola, es_local, p, delta)
			## LA PRESIÓN (25-9-2026): el jugador del equipo que defiende más
			## cercano al balón sale a presionarlo y se planta entre el balón y
			## su propio arco, a un par de metros -no encima, que sería falta-.
			## Sin esto nadie se acercaba nunca a menos de 4 m del que llevaba
			## la pelota (medido en `pruebas/prueba_regates.gd`: mediana 7 m):
			## el partido era un rondo sin oposición y el regate no tenía a
			## quién regatear.
			if not _presionador.is_empty() and p.get("id") == _presionador.get("id"):
				var z_arco_propio: float = 52.5 if es_local else -52.5
				var hacia_arco := Vector3(0.0, 0.0, signf(z_arco_propio - bola.z))
				objetivo = objetivo.lerp(Vector3(bola.x, 0.0, bola.z) + hacia_arco * 2.0, 0.8)
			## RONDA 3 (17-9-2026): SEPARACION entre companeros. La formula de
			## `_objetivo_jugador()` atrae a TODOS los de un lado hacia la
			## misma zona de la pelota -sin nada que los separe, dos o tres
			## companeros terminan apuntando casi al mismo punto, que es
			## exactamente lo que NUNCA pasa en un equipo real (nadie quiere
			## la pelota pegado a otro). Un empuje corto y barato -once
			## comparaciones como mucho por jugador- alcanza para que el
			## bloque se vea repartido en vez de amontonado.
			objetivo += _separacion(p, es_local)

		## BALANCEO SUTIL: sin esto, un jugador "quieto" en su ranura de
		## formacion se queda literalmente clavado -ni el mejor jugador del
		## mundo se para como una estatua-. Un vaivén de un par de decimas de
		## metro, desincronizado por jugador via `_fase`, rompe la sensacion
		## de bot sin mover a nadie fuera de su zona real. RONDA 2: mas quieto
		## cuanto mas cerca de la pelota -un jugador disputando el balon no
		## se balancea igual que uno esperando lejos de la jugada.
		var p_fase: float = p.get("_fase", 0.0)
		var dist_bola: float = node.position.distance_to(bola)
		var foco: float = clampf(dist_bola / 14.0, 0.12, 1.0)
		objetivo.x += sin(elapsed * 0.6 + p_fase) * 0.35 * foco
		objetivo.z += cos(elapsed * 0.47 + p_fase * 1.3) * 0.35 * foco

		## CORRECCION REAL (17-9-2026), reportada por el usuario como
		## movimiento "horrible": la separacion de la ronda 3 se sumaba SIN
		## volver a acotar a los limites de cancha, y se recalcula entera
		## cada fotograma sin ningun suavizado -si dos o tres companeros
		## quedan cerca (normal en un area), el empuje puede mandar el
		## objetivo fuera de la cancha y, como se recalcula de cero cada
		## fotograma, temblar en vez de asentarse. El clamp final es la red
		## de seguridad que faltaba.
		objetivo.x = clampf(objetivo.x, -MEDIO_ANCHO + 0.5, MEDIO_ANCHO - 0.5)
		objetivo.z = clampf(objetivo.z, -MEDIO_LARGO + 0.5, MEDIO_LARGO - 0.5)

		## RONDA 5 (17-9-2026): PRESIÓN. Cuando este jugador defiende -su equipo
		## no tiene la fase de ataque- un equipo con `presion` ALTA corre más
		## rápido a cerrar al rival; uno con presión BAJA deja jugar, no
		## persigue. Nada de esto se aplica si el propio equipo ataca -la
		## presión es una decisión SIN balón, no una prisa general.
		var tac_p := _tactica_de(es_local)
		var defendiendo := (fase == "ataqueVisita" and es_local) or (fase == "ataqueLocal" and not es_local)
		var mult_presion := 1.0
		if tac_p != null and defendiendo and not es_por and not bool(p.get("arbitro", false)):
			mult_presion = 1.0 + (float(tac_p.presion) - 1.0) * 0.12

		## RONDA 7 (17-9-2026): RITMO. Un equipo de ritmo alto juega mas rapido
		## de transicion -no solo cuando presiona, TODO el movimiento sin
		## balon es mas vivo-; uno de ritmo bajo controla, se mueve con mas
		## pausa. A diferencia de la presion (solo sin el balon en juego
		## rival), el ritmo pesa siempre que el equipo NO tiene la pelota
		## -con ella, quien decide el paso es quien la lleva, no la pizarra.
		var mult_ritmo := 1.0
		if tac_p != null and not es_por and not bool(p.get("arbitro", false)):
			mult_ritmo = 1.0 + (float(tac_p.ritmo) - 1.0) * 0.08

		var antes := node.position
		var vel_mult: float = p.get("_vel_mult", 1.0)
		## AJUSTE (18-9-2026): sin jugada ni presion rival ("medio", nadie ataca)
		## el bloque se mueve mas pausado -antes corria al mismo paso que en
		## plena jugada aunque el balon estuviera parado en el circulo central,
		## que es justo lo que el usuario leyo como "no se ve la jugada
		## planificada": si todo se mueve igual de rapido todo el tiempo, nada
		## resalta cuando de verdad pasa algo.
		var tiene_guion := pid_guion != null and float(_guion_hasta.get(pid_guion, -1.0)) > elapsed
		var mult_calma := 0.62 if (fase == "medio" and not tiene_guion and not _esta_celebrando(p)) else 1.0
		var paso: float = (5.8 if _esta_celebrando(p) else 3.4 * mult_calma) * vel_mult * mult_presion * mult_ritmo
		var dir := objetivo - antes
		dir.y = 0.0
		var dist := dir.length()
		## ESPRINT (13-10-2026): la sonda medía 3,5 m/s de máximo -un trote-
		## para los 22 todo el partido. Quien tiene lejos su sitio en plena
		## jugada (repliegue, desmarque, llegar a la presión) acelera hasta
		## casi el doble; en calma («medio») no.
		if mult_calma >= 1.0 and not bool(p.get("arbitro", false)) and not es_por:
			paso *= 1.0 + clampf((dist - 3.0) / 9.0, 0.0, 1.0) * 1.05

		## INERCIA: antes el jugador saltaba a velocidad máxima en el instante
		## que cambiaba de objetivo -frenar en seco y arrancar en seco es lo
		## que más se lee como control remoto, no como un cuerpo con masa-.
		## Ahora hay una velocidad DESEADA (más lenta cuanto más cerca del
		## objetivo, para no pasarse de largo y volver) y la velocidad de
		## verdad la persigue con una aceleración limitada.
		var vel_deseada := Vector3.ZERO
		if dist > 0.05:
			var frenado := clampf(dist / 1.8, 0.25, 1.0)
			vel_deseada = dir.normalized() * (paso * frenado)
		var acel: float = (18.0 if _esta_celebrando(p) else 11.0) * delta
		var vel_actual: Vector3 = p["_vel"]
		vel_actual = vel_actual.move_toward(vel_deseada, acel)
		p["_vel"] = vel_actual
		node.position += vel_actual * delta

		var vel := vel_actual.length()
		if not _portador.is_empty() and p.get("id") == _portador.get("id"):
			_decidir_regate(p, vel)
		_animar(p, ap, vel, _esta_celebrando(p))
		if vel > 0.35:
			var ang_deseado := atan2(vel_actual.x, vel_actual.z)
			node.rotation.y = rotate_toward(node.rotation.y, ang_deseado, 8.5 * delta)
	_resolver_choques()

## El jugador de campo más cercano a un punto, si está a menos de `radio`.
func _mas_cercano_a(punto: Vector3, radio: float) -> Dictionary:
	var mejor: Dictionary = {}
	var d_mejor := radio
	for p in players:
		if bool(p.get("arbitro", false)) or bool(p.get("banca", false)):
			continue
		var n: Node3D = p.get("node")
		if not is_instance_valid(n):
			continue
		var d := Vector2(n.position.x - punto.x, n.position.z - punto.z).length()
		if d < d_mejor:
			d_mejor = d
			mejor = p
	return mejor

## Elige hacia donde va el juego este minuto. Si acaba de pasar algo (ev != null)
## manda el suceso: tras un remate la pelota esta en el area, no en el medio.
func _recalcular_fase(ev) -> void:
	var r := _rng.randf() * 100.0
	var p := posesion_local
	if r < p * 0.72:
		fase = "ataqueLocal"
	elif r < p * 0.72 + (100.0 - p) * 0.72:
		fase = "ataqueVisita"
	else:
		fase = "medio"

	if ev != null:
		var equipo = ev.get("equipo")
		if equipo == "local":
			fase = "ataqueLocal"
		elif equipo == "visita":
			fase = "ataqueVisita"

	var es_gol: bool = ev != null and (ev["t"] == "golMi" or ev["t"] == "golR")
	## CORRECCION (17-9-2026): el evento real que manda `estadio.gd::_al_remate()`
	## viaja como `"t": "disparo"` con el resultado en `"tipo"` (atajada/poste/
	## fallo) -no como `"t": "atajada"` directo-. Comparar contra `ev["t"]` aqui
	## dejaba esta rama muerta para TODO remate real que no fuera gol: el balon
	## nunca volaba al arco en una atajada/poste/fallo, solo en el gol (que si
	## compara "t" porque golMi/golR SI son el tipo real del evento).
	var tipo_ev: String = str(ev.get("tipo", "")) if ev != null else ""
	var es_atajada: bool = tipo_ev == "atajada"
	var es_poste: bool = tipo_ev == "poste"
	var es_fallo: bool = tipo_ev == "fallo"

	var z := 0.0
	var ancho_z := 0.0
	match fase:
		"ataqueLocal":
			# el local ataca hacia -Z (arco rival en -52.5)
			if es_gol:
				ball_target = Vector3(_rng.randf_range(-3.0, 3.0), _rng.randf_range(0.3, 2.0), -53.3)
			elif es_atajada:
				ball_target = Vector3(_rng.randf_range(-2.8, 2.8), _rng.randf_range(0.3, 1.8), -51.8)
			elif es_poste:
				var l_poste: float = 3.66 if _rng.randf() > 0.5 else -3.66
				ball_target = Vector3(l_poste, _rng.randf_range(0.2, 2.4), -52.5)
			elif es_fallo:
				var l_fuera: float = (_rng.randf_range(4.5, 7.5)) * (1.0 if _rng.randf() > 0.5 else -1.0)
				ball_target = Vector3(l_fuera, _rng.randf_range(0.5, 3.5), -54.5)
			else:
				z = -30.0
				ancho_z = 14.0
				ball_target = Vector3(_rng.randf_range(-24.0, 24.0), 0.11, z + _rng.randf_range(-ancho_z, ancho_z))
		"ataqueVisita":
			# la visita ataca hacia +Z (arco local en +52.5)
			if es_gol:
				ball_target = Vector3(_rng.randf_range(-3.0, 3.0), _rng.randf_range(0.3, 2.0), 53.3)
			elif es_atajada:
				ball_target = Vector3(_rng.randf_range(-2.8, 2.8), _rng.randf_range(0.3, 1.8), 51.8)
			elif es_poste:
				var l_poste: float = 3.66 if _rng.randf() > 0.5 else -3.66
				ball_target = Vector3(l_poste, _rng.randf_range(0.2, 2.4), 52.5)
			elif es_fallo:
				var l_fuera: float = (_rng.randf_range(4.5, 7.5)) * (1.0 if _rng.randf() > 0.5 else -1.0)
				ball_target = Vector3(l_fuera, _rng.randf_range(0.5, 3.5), 54.5)
			else:
				z = 30.0
				ancho_z = 14.0
				ball_target = Vector3(_rng.randf_range(-24.0, 24.0), 0.11, z + _rng.randf_range(-ancho_z, ancho_z))
		_:
			z = 0.0
			ancho_z = 18.0
			ball_target = Vector3(_rng.randf_range(-24.0, 24.0), 0.11, z + _rng.randf_range(-ancho_z, ancho_z))

	if ball is Balon3D and not reproductor.en_reproduccion:
		var origen: Vector3 = (ball as Balon3D).position
		var dist := origen.distance_to(ball_target)
		var duracion := clampf(dist / 12.0, 0.3, 2.2)
		var altura: float
		var es_remate_fase: bool = es_gol or es_atajada or es_poste or es_fallo
		if es_gol:
			altura = _rng.randf_range(0.4, 0.85)
			duracion = maxf(duracion, 0.8)
		elif es_atajada or es_poste or es_fallo:
			altura = _rng.randf_range(0.3, 0.8)
			duracion = maxf(duracion, 0.7)
		else:
			altura = _rng.randf_range(0.06, 0.28)
		if es_remate_fase:
			## `_disparar()` recien va a arrancar la animacion "patear"/"cabezazo"
			## del rematador -ver `_ejecutar_accion()`-. Si el balon sale aqui
			## mismo, vuela desde el fotograma 0 (el jugador recien empezando a
			## levantar la pierna), no desde el instante real de contacto. Se
			## guarda el vuelo ya calculado y `tick()` lo dispara recien pasado
			## `CONTACTO_PATADA`.
			_disparo_pendiente = {
				"objetivo": ball_target, "duracion": duracion,
				"altura": altura, "es_gol": es_gol, "restante": CONTACTO_PATADA,
			}
		else:
			## EL PASE TIENE GESTO: quien está pegado al balón le pega con el
			## interior del pie. Antes el balón salía solo, sin que nadie lo tocara.
			var pasador := _mas_cercano_a(origen, 2.6)
			if not pasador.is_empty():
				_ejecutar_accion(pasador, "pase", 0.8)
				var np: Node3D = pasador.get("node")
				if is_instance_valid(np):
					np.look_at(Vector3(ball_target.x, np.position.y, ball_target.z), Vector3.UP)
			(ball as Balon3D).enviar(ball_target, duracion, altura, es_gol)

func _buscar_portero(es_local: bool) -> Dictionary:
	for p in players:
		if p.get("es_local") == es_local and str(p.get("slot_code", "")) == "POR":
			return p
	return {}
