class_name MatchPlayback
extends "res://visor/match_playback_p3.gd"
## (Parte 4 de 4 de `match_playback.gd`.)

# ------------------------------------------------------------------- reloj

func tick(delta_real: float) -> void:
	# En pausa el reloj se detiene pero los jugadores siguen animados en el sitio,
	# asi la escena no se congela como una foto.
	var delta := delta_real * velocidad()
	if delta <= 0.0:
		_mover(delta_real * 0.15)
		reproductor.avanzar(delta_real)
		return
	elapsed += delta
	var m := elapsed / seconds_per_minute

	while next_event_idx < events.size() and float(events[next_event_idx]["min"]) <= m:
		_disparar(events[next_event_idx])
		next_event_idx += 1

	## Los gestos programados (el árbitro que primero pita y después saca la
	## tarjeta, la revisión del VAR, el asistente que levanta la bandera...).
	var i_g := 0
	while i_g < _gestos_pendientes.size():
		var g: Array = _gestos_pendientes[i_g]
		if elapsed >= float(g[0]):
			var pg = players_by_id.get(g[1])
			if pg != null:
				_ejecutar_accion(pg, String(g[2]), float(g[3]))
			_gestos_pendientes.remove_at(i_g)
		else:
			i_g += 1

	var min_ahora := current_minute()
	## Llegando al 90, el cuarto árbitro no está: lo indica el principal.
	if min_ahora >= 89 and not _anadido_mostrado:
		_anadido_mostrado = true
		_programar_gesto("arbitro", "arbitro_tiempo_anadido", 1.8, 0.0)
	if min_ahora != _ultimo_min and not reproductor.en_reproduccion:
		_ultimo_min = min_ahora
		## LAS JUGADAS PREHECHAS, EN EL PARTIDO DE VERDAD (25-9-2026). Hasta hoy
		## el catálogo solo corría en las pruebas: ningún partido lo usaba. En
		## los minutos sin suceso, a veces, el equipo con el balón construye una
		## jugada del catálogo -pase al pie, desmarque, cambio de orientación,
		## saque del portero, repliegue- en vez de un balón a un punto al azar.
		## Sin remate: el remate lo decide la simulación y llega como suceso.
		if _jugadas_ambiente and _disparo_pendiente.is_empty() and _corner_pendiente.is_empty() \
				and _tirolibre_pendiente.is_empty() and _rng.randf() < PROB_JUGADA_AMBIENTE:
			var ids := CatalogoJugadas.ambientales()
			var id: String = ids[_rng.randi() % ids.size()]
			var es_local := _rng.randf() * 100.0 < posesion_local
			if reproductor.iniciar(id, self, ball, es_local, true):
				jugada_ambiente.emit(CatalogoJugadas.obtener_definicion(id)["nombre"], es_local)
			else:
				_recalcular_fase(null)
		else:
			_recalcular_fase(null)

	if not _disparo_pendiente.is_empty():
		_disparo_pendiente["restante"] -= delta
		if _disparo_pendiente["restante"] <= 0.0:
			if ball is Balon3D:
				(ball as Balon3D).enviar(_disparo_pendiente["objetivo"], _disparo_pendiente["duracion"], _disparo_pendiente["altura"], _disparo_pendiente["es_gol"])
			_disparo_pendiente = {}

	if not _corner_pendiente.is_empty():
		_corner_pendiente["restante"] -= delta
		if _corner_pendiente["restante"] <= 0.0:
			var sacador = players_by_id.get(_corner_pendiente["sacador_id"])
			var n: Node3D = null
			if sacador != null:
				_ejecutar_accion(sacador, "patear", 0.9)
				n = sacador.get("node")
				if is_instance_valid(n):
					n.look_at(Vector3(0, n.position.y, float(_corner_pendiente["z_arco"])), Vector3.UP)
			## BUG REAL ENCONTRADO EN LA PRIMERA PRUEBA (21-9-2026): sin esto, el
			## centro salia desde donde HUBIERA quedado la pelota del remate
			## "fallo" original -que vuela por su cuenta via `_disparo_pendiente`,
			## sin relacion con el banderin- en vez de desde los pies del
			## sacador. `enviar()` siempre usa la posicion ACTUAL del balon como
			## origen (ver `Balon3D.enviar()`), asi que hay que reposicionarlo a
			## proposito antes de patear -el sacador ya tuvo la ventana de
			## `_jugada_corner()` para llegar de verdad al banderin.
			if ball is Balon3D:
				var origen_centro: Vector3 = _corner_pendiente["pos_saque"]
				if is_instance_valid(n):
					origen_centro = n.position
				## `detener()` primero: sin esto, `avanzar()` -llamado cada
				## fotograma por `_mover()`, mas abajo en este mismo tick()- seguia
				## interpolando desde el vuelo del remate "fallo" original (su
				## `_t` no habia llegado a 1.0 todavia) y pisaba esta posicion en
				## el mismo frame -confirmado con una captura real donde el
				## centro salia desde cualquier lado menos el banderin.
				(ball as Balon3D).detener()
				(ball as Balon3D).position = Vector3(origen_centro.x, 0.11, origen_centro.z)
			## Mismo principio que el disparo normal: la pelota no sale en el
			## fotograma 0 de "patear", espera a `CONTACTO_PATADA`.
			_disparo_pendiente = {
				"objetivo": _corner_pendiente["destino"], "duracion": _corner_pendiente["duracion"],
				"altura": _corner_pendiente["altura"], "es_gol": false, "restante": CONTACTO_PATADA,
			}
			_corner_pendiente = {}

	if not _tirolibre_pendiente.is_empty():
		_tirolibre_pendiente["restante"] -= delta
		if _tirolibre_pendiente["restante"] <= 0.0:
			var pateador = players_by_id.get(_tirolibre_pendiente["sacador_id"])
			var n2: Node3D = null
			if pateador != null:
				_ejecutar_accion(pateador, "patear", 0.9)
				n2 = pateador.get("node")
				if is_instance_valid(n2):
					n2.look_at(Vector3(0, n2.position.y, float(_tirolibre_pendiente["z_arco"])), Vector3.UP)
			## Mismo bug ya corregido en el corner, mismo arreglo: reposicionar
			## el balon junto al pateador -`detener()` primero, o `avanzar()`
			## lo pisa en el mismo fotograma.
			if ball is Balon3D:
				var origen_tl: Vector3 = _tirolibre_pendiente["pos_saque"]
				if is_instance_valid(n2):
					origen_tl = n2.position
				(ball as Balon3D).detener()
				(ball as Balon3D).position = Vector3(origen_tl.x, 0.11, origen_tl.z)
			_disparo_pendiente = {
				"objetivo": _tirolibre_pendiente["destino"], "duracion": _tirolibre_pendiente["duracion"],
				"altura": _tirolibre_pendiente["altura"], "es_gol": false, "restante": CONTACTO_PATADA,
			}
			_tirolibre_pendiente = {}

	_mover(delta)
	reproductor.avanzar(delta)

func ejecutar_jugada_prehecha(codigo: String, es_local: bool = true) -> bool:
	if not is_instance_valid(ball):
		return false
	return reproductor.iniciar(codigo, self, ball, es_local)

## Dispara un suceso VENIDO DE FUERA, en el momento en que ocurre.
##
## El diseño original de esta clase era reproducir un partido ya jugado: se le
## daba la lista entera de sucesos y el reloj los iba sacando por minuto. Aquí el
## partido se está jugando de verdad mientras se mira, así que los sucesos llegan
## de las señales de `Partido` cuando pasan, no antes.
##
## Se expone así, con nombre propio, en vez de dejar que quien llama toque
## `_disparar()`: los dos usos conviven -una repetición sigue funcionando igual-
## y queda claro cuál es la puerta de entrada para el modo en vivo.
func suceso(ev: Dictionary) -> void:
	_disparar(ev)
