extends "res://visor/match_playback_p2.gd"
## (Parte 3 de 4 de `match_playback.gd`.)

## TERCERA JUGADA PREHECHA -EN REALIDAD LA SEGUNDA "DE VERDAD", `_celebrar()`
## no arma una escena nueva, solo pone una animacion- (21-9-2026): el corner.
## Manda a UN jugador del equipo que ataca al banderin mas cercano al lugar
## por donde salio el balon, y a dos o tres companeros mas al area a buscar el
## centro -mismo mecanismo de `_guion_destino`/`_guion_hasta` que ya usa
## `_jugada_gol()` para el asistidor, aplicado a mas de un jugador a la vez
## por primera vez-. `tick()` se encarga de patear recien cuando el sacador
## haya tenido tiempo de llegar (ver `_corner_pendiente` mas arriba).
func _jugada_corner(es_local_ataca: bool) -> void:
	var candidatos: Array = []
	for p in players:
		if p.get("es_local") == es_local_ataca and not bool(p.get("arbitro", false)) \
				and str(p.get("slot_code", "")) != "POR" and is_instance_valid(p.get("node")):
			candidatos.append(p)
	if candidatos.size() < 3:
		return

	## El corner cae en la esquina de la porteria que este equipo ataca -mismo
	## convenio de ejes que el resto del archivo: el local ataca hacia -Z, la
	## visita hacia +Z (ver `_recalcular_fase()`)-, del lado por el que salio
	## el balon (signo de `ball_target.x`, o derecha por defecto si salio
	## justo por el medio).
	var z_arco: float = -MEDIO_LARGO if es_local_ataca else MEDIO_LARGO
	var lado_x: float = signf(ball_target.x) if absf(ball_target.x) > 0.5 else 1.0
	var banderin := Vector3(lado_x * MEDIO_ANCHO, 0, z_arco)

	## El sacador: el candidato mas cercano al banderin -en un equipo real
	## suele sacarlo un extremo o lateral de ese costado, y "el mas cerca" es
	## una aproximacion barata y razonable sin tener que leer la demarcacion.
	var sacador: Dictionary = {}
	var sid = null
	var mejor_dist := INF
	for p in candidatos:
		var n: Node3D = p.get("node")
		var d := n.position.distance_to(banderin)
		if d < mejor_dist:
			mejor_dist = d
			sacador = p
			sid = p.get("id")
	if sid == null:
		return

	## Dentro del terreno de verdad, no exactamente sobre la linea -el jugador
	## no puede pararse en el aire fuera de la cancha. `z_arco` nunca es 0 (es
	## siempre ±MEDIO_LARGO), asi que `signf()` da siempre ±1 aqui.
	var pos_saque := Vector3(lado_x * (MEDIO_ANCHO - 0.6), 0, z_arco - signf(z_arco) * 0.6)
	_guion_destino[sid] = pos_saque
	_guion_hasta[sid] = elapsed + 1.6

	## Dos o tres companeros de verdad buscando el area: primer palo, centro
	## del area chica, segundo palo -los tres puntos que de verdad se disputan
	## en un corner real, no posiciones al azar-.
	var objetivos_area := [
		Vector3(lado_x * 3.0, 0, z_arco - signf(z_arco) * 8.5),
		Vector3(0.0, 0, z_arco - signf(z_arco) * 6.5),
		Vector3(-lado_x * 5.5, 0, z_arco - signf(z_arco) * 9.5),
	]
	var restantes: Array = []
	for p in candidatos:
		if p.get("id") != sid:
			restantes.append(p)
	var cuantos := mini(objetivos_area.size(), restantes.size())
	for i in cuantos:
		var idx := _rng.randi_range(0, restantes.size() - 1)
		var corredor: Dictionary = restantes[idx]
		restantes.remove_at(idx)
		var cid = corredor.get("id")
		_guion_destino[cid] = objetivos_area[i]
		## Un pelin mas que el sacador: tienen que estar ya ubicados cuando
		## llegue el centro, y quedarse un momento disputando el area.
		_guion_hasta[cid] = elapsed + 2.2

	## El centro en si: se arma como `_corner_pendiente`, que `tick()` resuelve
	## recien cuando el sacador haya tenido el tiempo de la ventana de arriba
	## para llegar -no antes-. Apunta al objetivo del medio (el mas disputado
	## de los tres) con una parabola alta, como un centro de verdad.
	var origen_aprox: Vector3 = pos_saque
	var destino_centro: Vector3 = objetivos_area[1] + Vector3(0, 1.6, 0)
	var dist := origen_aprox.distance_to(destino_centro)
	_corner_pendiente = {
		"sacador_id": sid, "z_arco": z_arco, "destino": destino_centro, "pos_saque": pos_saque,
		"duracion": clampf(dist / 10.0, 0.9, 2.0), "altura": 2.6,
		"restante": 1.6,
	}

func _programar_gesto(id: String, anim: String, dur: float, retraso: float) -> void:
	_gestos_pendientes.append([elapsed + retraso, id, anim, dur])

## Lo que hace el árbitro (y los asistentes) con cada suceso, además de las
## faltas: gol (silbato, a veces revisión del VAR, y al centro), balón que se
## va (córner o saque de meta), fuera de juego con bandera, lesión (pide
## calma y llama a las asistencias) y las decisiones arbitrales de la
## simulación (revisión o calmar a los jugadores).
func _trabajo_del_arbitro(t_ev: String, tipo_ev: String, ev: Dictionary, es_gol: bool) -> void:
	if not players_by_id.has("arbitro"):
		return
	var minuto := int(ev.get("min", current_minute()))
	if es_gol:
		_programar_gesto("arbitro", "arbitro_silbato", 0.9, 0.4)
		## Uno de cada seis goles se revisa en el VAR (se confirma: la
		## simulación ya decidió que es gol; esto solo lo dramatiza).
		if _rng.randf() < 0.17:
			_programar_gesto("arbitro", "arbitro_var", 2.2, 2.2)
			revision_var.emit(minuto, "Posible fuera de juego en el gol")
		_programar_gesto("arbitro", "senalar_falta", 1.8, 4.8)
	elif tipo_ev == "fallo":
		if _rng.randf() < 0.14:
			## Fuera de juego: el asistente levanta la bandera y la baja en
			## horizontal; el árbitro pita.
			var asist := "linea_a" if _rng.randf() < 0.5 else "linea_b"
			_programar_gesto(asist, "asistente_bandera", 1.8, 0.2)
			_programar_gesto(asist, "asistente_fuera_juego", 1.8, 2.0)
			_programar_gesto("arbitro", "arbitro_silbato", 0.9, 0.6)
		elif not _corner_pendiente.is_empty():
			_programar_gesto("arbitro", "arbitro_corner", 1.6, 0.8)
		else:
			_programar_gesto("arbitro", "arbitro_saque_meta", 1.6, 0.8)
	elif t_ev == "lesion":
		_programar_gesto("arbitro", "arbitro_silbato", 0.9, 0.3)
		_programar_gesto("arbitro", "arbitro_calma", 1.4, 1.4)
	elif t_ev == "arbitro":
		var tx := str(ev.get("tx", "")).to_lower()
		if tx.contains("var") or tx.contains("revis"):
			_programar_gesto("arbitro", "arbitro_var", 2.2, 0.4)
			revision_var.emit(minuto, str(ev.get("tx", "Revisión")))
		elif tx.contains("penal"):
			_programar_gesto("arbitro", "arbitro_silbato", 0.9, 0.2)
			_programar_gesto("arbitro", "arbitro_penal", 1.8, 1.1)
		else:
			_programar_gesto("arbitro", "arbitro_calma", 1.4, 0.3)

## CUARTA JUGADA PREHECHA (21-9-2026): el tiro libre directo. Manda al
## pateador mas cercano al punto de la falta a colocarse sobre el balon, y a
## dos o tres defensores del equipo que la cometio a formar una barrera entre
## el balon y su propio arco -la distancia real de una barrera, 9.15m, no un
## numero inventado-. `tick()` resuelve el disparo igual que el corner: espera
## la ventana, patea, reposiciona el balon junto al pateador (mismo bug ya
## corregido ahi, mismo arreglo aqui) y lo manda al arco.
func _jugada_tiro_libre(atacante_es_local: bool, z_arco_propio: float) -> void:
	var atacantes: Array = []
	var defensores: Array = []
	for p in players:
		if bool(p.get("arbitro", false)) or str(p.get("slot_code", "")) == "POR" \
				or not is_instance_valid(p.get("node")):
			continue
		if p.get("es_local") == atacante_es_local:
			atacantes.append(p)
		else:
			defensores.append(p)
	if atacantes.size() < 1 or defensores.size() < 2:
		return

	var punto_falta: Vector3 = Vector3(ball_target.x, 0, ball_target.z)
	var arco_pos := Vector3(0, 0, z_arco_propio)

	## El pateador: el atacante mas cercano al punto de la falta -en la
	## realidad no siempre es el mejor pateador del equipo, pero "el que ya
	## esta mas cerca" es la misma aproximacion barata que ya usa el corner
	## para el sacador, y es razonable sin leer atributos de tiro libre.
	var sid = null
	var mejor_dist := INF
	for p in atacantes:
		var n: Node3D = p.get("node")
		var d := n.position.distance_to(punto_falta)
		if d < mejor_dist:
			mejor_dist = d
			sid = p.get("id")
	if sid == null:
		return
	_guion_destino[sid] = punto_falta - (punto_falta - arco_pos).normalized() * 1.8
	_guion_hasta[sid] = elapsed + 1.6

	## La barrera: 9.15m (10 yardas reales) desde el balon hacia el propio
	## arco, dos o tres defensores repartidos a los lados del punto central de
	## la barrera -perpendicular a la linea balon-arco, no en fila india.
	var hacia_arco := (arco_pos - punto_falta)
	hacia_arco.y = 0.0
	if hacia_arco.length() < 0.01:
		hacia_arco = Vector3.FORWARD
	hacia_arco = hacia_arco.normalized()
	var centro_barrera: Vector3 = punto_falta + hacia_arco * 9.15
	var lateral := Vector3(-hacia_arco.z, 0, hacia_arco.x)
	var def_ordenados := defensores.duplicate()
	def_ordenados.sort_custom(func(a, b):
		return (a.get("node") as Node3D).position.distance_to(punto_falta) \
			< (b.get("node") as Node3D).position.distance_to(punto_falta))
	var offsets := [0.0, -1.1, 1.1]
	var cuantos_b := mini(offsets.size(), def_ordenados.size())
	for i in cuantos_b:
		var d2: Dictionary = def_ordenados[i]
		var did = d2.get("id")
		_guion_destino[did] = centro_barrera + lateral * offsets[i]
		_guion_hasta[did] = elapsed + 1.8

	var dist_tiro := punto_falta.distance_to(arco_pos)
	_tirolibre_pendiente = {
		"sacador_id": sid, "z_arco": z_arco_propio, "pos_saque": punto_falta,
		"destino": Vector3(arco_pos.x + _rng.randf_range(-3.0, 3.0), _rng.randf_range(0.3, 2.2), arco_pos.z),
		"duracion": clampf(dist_tiro / 22.0, 0.6, 1.6), "altura": _rng.randf_range(0.4, 1.4),
		"restante": 1.6,
	}

## JUGADAS PREHECHAS, primera pieza (18-9-2026): hasta ahora el asistidor de un
## gol quedaba TOTALMENTE ajeno a su propio pase -seguia con el reparto tactico
## normal, que en el instante del gol lo puede tener a 20 metros del área-. Esto
## le da al asistidor un destino puntual, cerca del rematador, por una ventana
## corta: no es una animacion nueva (usa correr/trotar, que `_animar()` ya elige
## solo con la velocidad), es la primera "jugada" con guion propio en vez de
## reparto de zona. `_recalcular_fase()` ya decidio hacia donde vuela el balon
## un poco antes en `_disparar()`; esta ventana cubre ese vuelo y un poco mas.
func _jugada_gol(p_remate: Dictionary, asistidor_id) -> void:
	if asistidor_id == null or asistidor_id == "" or not players_by_id.has(asistidor_id):
		return
	var a: Dictionary = players_by_id[asistidor_id]
	var n_a: Node3D = a.get("node")
	var n_r: Node3D = p_remate.get("node")
	if not is_instance_valid(n_a) or not is_instance_valid(n_r):
		return
	var hacia := n_r.position - n_a.position
	hacia.y = 0.0
	if hacia.length() > 0.01:
		hacia = hacia.normalized()
	else:
		hacia = Vector3.FORWARD
	var destino: Vector3 = n_r.position - hacia * 3.5
	_guion_destino[asistidor_id] = destino
	## 1.6s, no 1.3: pensado para que la carrera se alcance a LEER en una
	## grabación corta, no solo a medirse en el banco.
	_guion_hasta[asistidor_id] = elapsed + 1.6

func _celebrar(p: Dictionary, asistidor) -> void:
	## Según su carácter y con su celebración de siempre (AnimExtra).
	var jd: Dictionary = p.get("jugador", {}) if p.get("jugador") is Dictionary else {}
	var ap_c: AnimationPlayer = p.get("anim")
	var anim_celeb := AnimExtra.celebracion(ap_c if is_instance_valid(ap_c) else null, String(jd.get("rasgo", "")),
		str(p.get("id", "")), not bool(p.get("es_local", true)), _rng)
	var pid_c = p.get("id")
	if pid_c != null:
		## Directo, sin pasar por el sorteo de `_ejecutar_accion`.
		_acciones_activas[pid_c] = {"anim": anim_celeb, "hasta": elapsed + 3.8}
		if is_instance_valid(ap_c) and ap_c.has_animation(anim_celeb):
			ap_c.play(anim_celeb)
			ap_c.speed_scale = 1.0
	_celebrando.append({"p": p, "hasta": elapsed + 4.2})
	## Cara de alegría del goleador (13-10-2026).
	var nodo_c = p.get("node")
	if nodo_c is Node and is_instance_valid(nodo_c):
		Expresion.de(nodo_c).poner("alegre", 4.0)
	if asistidor != null and players_by_id.has(asistidor):
		var a = players_by_id[asistidor]
		_ejecutar_accion(a, "celebrar", 3.4)
		_celebrando.append({"p": a, "hasta": elapsed + 3.6})

func _desolar_defensa(es_local_defensa: bool) -> void:
	for p in players:
		if p.get("es_local") == es_local_defensa and not bool(p.get("arbitro", false)):
			var slot := str(p.get("slot_code", ""))
			if slot == "POR" or slot in ["DFC", "LI", "LD", "DEF"]:
				var anim_lamento := "lamento" if _rng.randf() > 0.4 else "rabia"
				_ejecutar_accion(p, anim_lamento, 2.4)

func _disparar(ev: Dictionary) -> void:
	## Un suceso real manda sobre la jugada que se estuviera escenificando.
	if reproductor.en_reproduccion and reproductor.ambiente:
		reproductor.abortar()
	event_fired.emit("%d'  %s" % [int(ev["min"]), ev["tx"]])
	_recalcular_fase(ev)

	var t_ev: String = str(ev.get("t", ""))
	var tipo_ev: String = str(ev.get("tipo", ""))
	## El lesionado se duele, agachado y con las manos en la rodilla.
	if t_ev == "lesion":
		var lesionado = players_by_id.get(ev.get("jugadorId"))
		if lesionado != null:
			_ejecutar_accion(lesionado, "dolor", 3.0)
	var es_gol: bool = t_ev == "golMi" or t_ev == "golR"
	## Mismo arreglo que en `_recalcular_fase()`: el remate real llega como
	## `"t": "disparo"`, no como `"t": "atajada"/"poste"/"fallo"` directo.
	var es_remate: bool = es_gol or t_ev == "disparo" or tipo_ev in ["remate", "atajada", "poste", "fallo"]
	var pid = ev.get("jugadorId")
	var p_remate = players_by_id.get(pid) if pid != null else null

	# Animar al rematador ejecutando el tiro
	if es_remate and p_remate != null:
		var es_aereo: bool = _rng.randf() < 0.25
		_ejecutar_accion(p_remate, "cabezazo" if es_aereo else "patear", 0.9)
		# Orientar hacia la portería rival
		var node_rem: Node3D = p_remate.get("node")
		if is_instance_valid(node_rem):
			var z_arco: float = -52.5 if p_remate.get("es_local") else 52.5
			node_rem.look_at(Vector3(0, node_rem.position.y, z_arco), Vector3.UP)

	# Reacción del portero defensor
	var es_local_atacando: bool = fase == "ataqueLocal"
	var por_defensor = _buscar_portero(not es_local_atacando)
	if not por_defensor.is_empty():
		if tipo_ev == "atajada" or (es_gol and _rng.randf() < 0.75) or tipo_ev == "poste":
			var lado_der := ball_target.x > 0 if not es_local_atacando else ball_target.x < 0
			var anim_atajada := "atajar_der" if lado_der else "atajar_izq"
			## Balón a ras de suelo y centrado: el portero se agacha, no vuela.
			if ball_target.y < 0.6 and absf(ball_target.x) < 1.6:
				anim_atajada = "atajar_bajo"
			_ejecutar_accion(por_defensor, anim_atajada, 1.9)

	## JUGADAS PREHECHAS, segunda pieza (21-9-2026): un remate desviado
	## ("fallo") es, en la realidad, a menudo un balon que sale por el fondo
	## -un corner-. La simulacion portada del HTML no distingue esto (no hay
	## un tipo "corner" en el JSON, solo golMi/golR/atajada/poste/fallo), asi
	## que esto NO decide nada nuevo sobre el resultado -sigue siendo un
	## "fallo" a todos los efectos del marcador y las estadisticas, exactamente
	## el mismo principio que ya usa `_jugada_gol()` (dramatizar lo decidido,
	## no redecidir nada)-, solo una fraccion de esos fallos (30%, sorteado con
	## `_rng` propio, NUNCA `Azar`) se viste como un saque de esquina en vez de
	## un simple "se fue afuera". Un solo corner a la vez -no se pisa uno en
	## marcha con otro-, y la pelota debe estar libre (no en pleno vuelo de
	## otro disparo).
	## BUG REAL ENCONTRADO EN LA PRUEBA DE ESTRES (21-9-2026): exigir tambien
	## `_disparo_pendiente.is_empty()` aqui bloqueaba el corner el 100% de las
	## veces en un partido real -`_recalcular_fase(ev)`, un poco mas arriba en
	## esta misma funcion, YA deja `_disparo_pendiente` ocupado con el vuelo
	## del propio remate "fallo" que se esta procesando, asi que la condicion
	## nunca podia ser verdadera-. Confirmado con un partido natural de 2000
	## fotogramas (`pruebas/estres_corner.gd`, nuevo): 2 fallos reales, cero
	## corners, ambos con `disparo_vacio=false`. No hace falta esa guarda: el
	## corner sobreescribe `_disparo_pendiente` mas tarde en `tick()`, cuando
	## el vuelo del fallo original ya se lanzo hace rato.
	if tipo_ev == "fallo" and _corner_pendiente.is_empty() and _rng.randf() < 0.30:
		_jugada_corner(es_local_atacando)

	## EL ÁRBITRO HACE SU TRABAJO (26-9-2026): pita, señala, habla, revisa.
	_trabajo_del_arbitro(t_ev, tipo_ev, ev, es_gol)

	# Faltas y tarjetas
	if t_ev in ["warn", "falta"]:
		if p_remate != null:
			_ejecutar_accion(p_remate, "falta_barrida" if _rng.randf() > 0.35 else "falta_empujon", 1.2)
		var arb = players_by_id.get("arbitro")
		if arb != null:
			## Primero el silbato; en una falta sin tarjeta, a veces deja seguir
			## (ventaja); con tarjeta, habla con el jugador y después la muestra.
			_ejecutar_accion(arb, "arbitro_silbato", 0.9)
			if t_ev == "warn":
				_programar_gesto("arbitro", "arbitro_amonestar_hablar", 1.6, 0.9)
				var gesto := "mostrar_roja" if bool(ev.get("roja", false)) else "mostrar_tarjeta"
				_programar_gesto("arbitro", gesto, 2.4 if gesto == "mostrar_roja" else 1.8, 2.5)
				## Protestas y el árbitro que las aparta.
				if p_remate != null:
					_programar_gesto(str(p_remate.get("id")), "protestar", 1.6, 2.6)
				_programar_gesto("arbitro", "arbitro_dispersar", 1.6, 4.3)
			else:
				var ventaja := _rng.randf() < 0.3
				_programar_gesto("arbitro", "arbitro_ventaja" if ventaja else "senalar_falta", 1.6, 0.8)

		## JUGADAS PREHECHAS, tercera pieza (21-9-2026): el tiro libre. Mismo
		## principio que el corner -no redecide nada, `ev` sigue siendo un
		## "warn"/"falta" normal a todos los efectos-, solo que esta vez el
		## equipo que se viste es el CONTRARIO al que cometio la falta (`ev.
		## equipo` es de quien la comete, per `_a_la_tarjeta()` en estadio.gd),
		## y solo si la falta cayo en zona de disparo directo -no tiene sentido
		## un tiro libre "de verdad" desde el propio campo-.
		var equipo_falta: String = str(ev.get("equipo", ""))
		var atacante_es_local: bool = equipo_falta == "visita"
		var z_arco_propio: float = MEDIO_LARGO if equipo_falta == "local" else -MEDIO_LARGO
		var dist_arco := ball_target.distance_to(Vector3(0, 0, z_arco_propio))
		if _tirolibre_pendiente.is_empty() and dist_arco < 30.0 and _rng.randf() < 0.35:
			_jugada_tiro_libre(atacante_es_local, z_arco_propio)

	if es_gol:
		if ev.get("equipo") == "local":
			local_goals += 1
		elif ev.get("equipo") == "visita":
			visita_goals += 1
		if p_remate != null:
			_jugada_gol(p_remate, ev.get("asistidorId"))
			_celebrar(p_remate, ev.get("asistidorId"))
		_desolar_defensa(not es_local_atacando)
