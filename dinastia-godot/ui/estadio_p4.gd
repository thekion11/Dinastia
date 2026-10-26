extends "res://ui/estadio_p3.gd"
## [Capa 4/6 de `estadio.gd`] _al_gol, _frenar_destacado, _a_la_tarjeta, _al_cambio, _al_remate, _a_la_lesion … (+12)

func _al_gol(c: Club, autor: Jugador, minuto: int, asistente: Jugador = null) -> void:
	var a_favor := c == club
	if _motor != null:
		## Con el motor real: la secuencia de cámaras y, al final, la repetición.
		_cine_gol(c, autor)
	else:
		get_tree().create_timer(SEG_ANTES_REPETICION).timeout.connect(_repetir_gol)
	_suceso({
		"min": minuto, "t": "golMi" if a_favor else "golR",
		"equipo": "local" if a_favor else "visita",
		"tx": "¡GOL de %s! %s" % [c.nombre, autor.nombre if autor else ""],
		"jugadorId": autor.id if autor else "",
		"asistidorId": asistente.id if asistente != null else "",
	})
	## SONIDO (18-9-2026): hasta ahora esta vista 3D -la que de verdad se juega,
	## `partido_vivo.gd` la abre encima del partido en marcha- nunca llamaba a
	## `Sonido`. Todo el catálogo (incluidos los ocho estilos de gol elegibles
	## en el diseño del estadio) existía y sonaba en las pruebas, pero en el
	## partido de verdad esta pantalla se quedaba muda -el 2D de `partido_vivo`
	## sí tenía sus propios `Sonido.toca()`, este visor no-. `a_favor` aquí
	## significa "anotó el club dueño de ESTE estadio" -es la bocina de SU
	## recinto, no una noción de "mi club" que este visor no conoce-.
	## Goles con nombre propio: el doblete, el hat-trick, el tempranero y el
	## agónico tienen su propio grito encima del de siempre.
	if autor != null:
		_goles_autor[autor.id] = int(_goles_autor.get(autor.id, 0)) + 1
		match int(_goles_autor[autor.id]):
			2: Sonido.toca("doblete", Sonido.Bus.AMBIENTE)
			3: Sonido.toca("hat_trick", Sonido.Bus.AMBIENTE)
	if minuto <= 3:
		Sonido.toca("gol_rapido", Sonido.Bus.AMBIENTE)
	elif minuto >= 86:
		Sonido.toca("gol_agonico", Sonido.Bus.AMBIENTE)
	if a_favor:
		Sonido.toca("festejo_hinchada_extra", Sonido.Bus.AMBIENTE)
		var estilo := String(_perfil.get("sonidoGol", "bombo"))
		Sonido.toca("gol_" + estilo if Sonido.catalogo().has("gol_" + estilo) else "gol")
	else:
		Sonido.toca("gol_rival")
	## Con el motor real lo dice la carta del goleador (como en FC); el cartel
	## queda para el gol en propia puerta y el partido sin motor.
	if _motor == null or autor == null:
		_mostrar_banner_gol("⚽ GOL DE %s" % (autor.nombre.to_upper() if autor else "?"), a_favor)
	_animar_marcador_gol()
	## La pantalla gigante corta a "¡GOOOL!" a pantalla completa y vuelve sola
	## a su rotación a los 6,5 s -igual que la de un estadio de verdad-.
	if _pantalla != null:
		_pantalla.al_gol(c, autor, minuto)
	_vallas_evento(["¡GOOOL!", c.nombre.to_upper()], c)
	if _motor == null:
		_seguir_jugada_gol(autor)
	## EL BANQUILLO REACCIONA (22-9-2026). `a_favor` aquí es "el dueño de este
	## estadio anotó", no necesariamente el club local en la cancha -mismo
	## matiz que ya advierte el comentario del sonido, un poco más arriba-,
	## así que el lado que festeja es el de `c`, no el de `a_favor` a secas.
	if _motor == null:
		_banca_celebra(c == club)

func _frenar_destacado() -> void:
	if not modo_destacados or _juego == null or _juego.vel_idx == 0:
		return
	_juego.vel_idx = VEL_DESTACADOS_JUGADA
	_destacado_hasta_ms = Time.get_ticks_msec() + int(SEG_DESTACADO * 1000.0)
	if _btn_velocidad != null:
		_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()

func _a_la_tarjeta(j: Jugador, roja: bool, minuto: int) -> void:
	Sonido.toca("roja" if roja else "amarilla")
	_suceso({
		"min": minuto, "t": "warn",
		"equipo": "local" if j.club_id == club.id else "visita",
		"tx": ("ROJA a " if roja else "Amarilla a ") + j.nombre,
		"roja": roja,
		"jugadorId": j.id,
	})

func _al_cambio(sale: Jugador, entra: Jugador, minuto: int) -> void:
	Sonido.toca("cambio")
	var del_cambio: Club = club if club != null and club.plantilla.has(entra) else visitante
	_vallas_evento(["CAMBIO", "⬆ %s" % entra.nombre.get_slice(" ", entra.nombre.get_slice_count(" ") - 1).to_upper(),
		"⬇ %s" % sale.nombre.get_slice(" ", sale.nombre.get_slice_count(" ") - 1).to_upper()], del_cambio, 4.0)
	## Si `entra` era uno de los 7 de la banca visual, se le quita el modelo
	## de ahí antes de crearle uno en la cancha -si no, quedaría duplicado:
	## uno de pie junto al banquillo y otro jugando, el mismo jugador dos
	## veces a la vista. Si no estaba entre los 7 mostrados (la banca visual
	## es una muestra, no la convocatoria real, ver `_poner_banca()`), no hay
	## nada que quitar y este bucle simplemente no encuentra nada.
	for i in range(_en_banca.size() - 1, -1, -1):
		var fb: Dictionary = _en_banca[i]
		if String(fb.get("id", "")) == entra.id:
			var nb: Node3D = fb.get("node")
			if is_instance_valid(nb):
				nb.queue_free()
			_en_banca.remove_at(i)
			break
	_suceso({
		"min": minuto, "t": "info", "equipo": "local",
		"tx": "Cambio: entra %s por %s" % [entra.nombre, sale.nombre], "jugadorId": entra.id,
	})
	for i in _en_campo.size():
		var f: Dictionary = _en_campo[i]
		if String(f.get("id", "")) != sale.id:
			continue
		var viejo: Node3D = f["node"]
		var pos: Vector3 = viejo.position
		var es_local: bool = f["es_local"]
		## Con el motor real el que sale NO desaparece: camina a la banda y
		## choca la mano con el que entra (`EscenaCambio`, M-104).
		var escena := _motor != null and is_instance_valid(viejo)
		if not escena:
			viejo.queue_free()
		var equipo := club if es_local else visitante
		var d := Puente3D.jugador(entra)
		var nuevos := _spawner.spawn_team(_raiz3d, [entra.id], {entra.id: d},
			{"s": [[f["slot_code"], 50, 50]]}, es_local,
			Puente3D.kit(equipo), Puente3D.kit_portero(equipo))
		if nuevos.is_empty():
			if escena:
				viejo.queue_free()
			_en_campo.remove_at(i)
			return
		var nf: Dictionary = nuevos[0]
		nf["node"].position = pos
		nf["base_pos"] = f["base_pos"]
		nf["slot_code"] = f["slot_code"]
		nf["es_local"] = es_local
		_en_campo[i] = nf
		if _motor != null:
			_motor.reemplazar(sale.id, nf)
			if escena:
				EscenaCambio.iniciar(_raiz3d, _spawner, _motor, viejo, f.get("anim"), nf, sale.dorsal, entra.dorsal, _kit_arbitro)
			_mostrar_banner_gol("🔁 %s  ⬆ %s   ⬇ %s" % [Idiomas.t("CAMBIO"), Nombres.visible(entra.nombre), Nombres.visible(sale.nombre)],
				equipo.id == Partido.ctx_club_id)
		_fov_rotulos = -1.0
		_juego.players = _en_campo
		_juego.players_by_id[entra.id] = nf
		_juego.players_by_id.erase(sale.id)
		return


func _al_remate(c: Club, autor: Jugador, tipo: String, minuto: int) -> void:
	if _juego == null:
		return
	## Igual que en `_al_gol()`: la reacción sonora es del ESTADIO (`a_favor` =
	## remató el dueño de este recinto), no de "mi club" -este visor no conoce
	## esa noción, y hasta hoy ninguna de las dos vivía aquí.
	if c == club:
		match tipo:
			"atajada":
				Sonido.toca("atajada")
				Sonido.toca("alarido_atajada", Sonido.Bus.AMBIENTE)
			"poste":
				Sonido.toca("travesano" if minuto % 2 == 0 else "ocasion")
				Sonido.toca("suspiro_grada", Sonido.Bus.AMBIENTE)
			## BUG REAL ENCONTRADO Y CORREGIDO (21-9-2026): un remate desviado no
			## sonaba NADA -la rama por defecto solo hacia `pass`- pese a que
			## `Sonido` ya trae "remate_fuera" sintetizado y sin usar en ningun
			## lado del visor 3D. El partido se quedaba mudo en el caso MAS
			## comun de un remate (fallar es mas frecuente que atajar o dar en
			## el palo).
			"fallo": Sonido.toca("remate_fuera")
			_: pass
	_suceso({
		"min": minuto,
		"t": "disparo",
		"tipo": tipo,
		"equipo": "local" if c == club else "visita",
		"tx": "Remate de %s (%s)" % [autor.nombre if autor else "delantero", tipo],
		"jugadorId": autor.id if autor else "",
	})

func _a_la_lesion(j: Jugador, semanas: int, minuto: int) -> void:
	if _juego == null:
		return
	if j.club_id == club.id:
		Sonido.toca("lesion_grave" if semanas >= 6 else "lesion")
	_suceso({
		"min": minuto,
		"t": "lesion",
		"equipo": "local" if j.club_id == club.id else "visita",
		"tx": "¡Lesión de %s! (%d sem)" % [j.nombre, semanas],
		"jugadorId": j.id,
	})

func _a_la_decision_arbitral(texto: String, minuto: int) -> void:
	if _juego == null:
		return
	_suceso({
		"min": minuto,
		"t": "arbitro",
		"tx": texto,
	})

## Los tiempos del partido, a oído: el descanso, la vuelta, el último minuto,
## el descuento, y la grada que se pone tensa en un final apretado.
func _al_minuto_sonoro(minuto: int) -> void:
	match minuto:
		45: Sonido.toca("medio_tiempo")
		46: Sonido.toca("reanudacion")
		89: Sonido.toca("ultimo_minuto", Sonido.Bus.AMBIENTE)
		90: Sonido.toca("descuento_anunciado")
	if minuto >= 80 and minuto % 4 == 0 and absi(partido.goles_local - partido.goles_visita) <= 1:
		Sonido.toca("tension_publico", Sonido.Bus.AMBIENTE)

static func ritmo_partido() -> String:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	return String(cfg.get_value(CajonAjustes.SECCION, "ritmo_partido", "normal"))
func _revisar_ola() -> void:
	if _ola_min == 0 or _motor.estado != "juego":
		return
	if _ola_min < 0:
		var azar := RandomNumberGenerator.new()
		azar.seed = hash(partido.local.id + "|ola|" + partido.visita.id)
		_ola_min = azar.randi_range(58, 82) if azar.randf() < 0.35 else 999
	var m := _motor.minuto()
	var decidido := absi(partido.goles_local - partido.goles_visita) >= 2 and m >= 62
	if m >= _ola_min or decidido:
		_ola_min = 0
		OlaGrada.lanzar(_raiz3d, "ola")

## Un rótulo corto debajo del marcador (reutiliza el de las jugadas).
func _mostrar_rotulo_suceso(texto: String) -> void:
	if _rotulo_jugada == null or not _pref("rotulos", true):
		return
	(_rotulo_jugada.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color("c9a227")
	_lbl_jugada.text = "▸ " + texto
	if _tween_jugada != null and _tween_jugada.is_valid():
		_tween_jugada.kill()
	_tween_jugada = create_tween()
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 1.0, 0.2)
	_tween_jugada.tween_interval(2.2)
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 0.0, 0.5)

## Los nombres largos no caben en un marcador de televisión, y recortar por
## caracteres deja cosas como "Deportes Antofa". Se usa la primera palabra larga.
func _corto(n: String) -> String:
	if n.length() <= 14:
		return n
	for parte in n.split(" "):
		if parte.length() >= 5:
			return parte
	return n.substr(0, 14)

func _refrescar_marcador() -> void:
	if _marcador == null:
		return
	if _motor != null:
		_revisar_ola()
		## El reloj de la transmisión: 45' +2 en el añadido, y el cartel del
		## cuarto árbitro cuando empieza.
		var seg := _motor.segundos_anadidos()
		var reloj := "%d'" % _motor.minuto()
		if _motor.estado == "tanda" or not _motor.tanda.is_empty():
			## El detalle va en el marcador de la tanda (el de arriba no da para más).
			reloj = Idiomas.t("PEN.")
			seg = -1.0
		elif seg >= 0.0:
			reloj = "%d' +%d:%02d" % [_motor.minuto_base() + int(_motor.minutos_de_mitad()), int(seg) / 60, int(seg) % 60]
			if not _anadido_avisado.has(_motor.mitad) and _motor.minutos_anadidos() > 0:
				_anadido_avisado[_motor.mitad] = true
				_mostrar_rotulo_suceso("⏱ %s: +%d" % [Idiomas.t("Tiempo añadido"), _motor.minutos_anadidos()])
				Sonido.toca("descuento_anunciado")
				## Y el cuarto árbitro levanta el cartel en la banda (M-139).
				var cuarto := CuartoArbitro.levantar(_raiz3d, _spawner, _motor.minutos_anadidos(), _kit_arbitro)
				## Corte al cartel ya arriba, si la jugada lo permite (como la tele).
				get_tree().create_timer(0.7).timeout.connect(func() -> void:
					if is_instance_valid(cuarto) and _puede_insertar(true):
						_rig.inserto_cartel(cuarto))
		_marcador.text = "%s  %d - %d  %s      %s" % [_corto(partido.local.nombre), partido.goles_local,
			partido.goles_visita, _corto(partido.visita.nombre), reloj]
		return
	_marcador.text = "%s  %d - %d  %s      %d'" % [
		_corto(partido.local.nombre), partido.goles_local,
		partido.goles_visita, _corto(partido.visita.nombre),
		partido.minuto]

## El gol que el VAR anula: acta, motor y marcador, con aviso y reacción.
func _anular_gol_motor(de_local: bool, autor: String) -> void:
	if _motor == null or partido == null:
		return
	partido.anular_gol_externo(de_local, autor)
	_motor.anular_gol(de_local)
	if _stats != null:
		_stats.anular_gol(de_local)
	_refrescar_marcador()
	_mostrar_rotulo_suceso("🖥️ " + Idiomas.t("VAR: GOL ANULADO"))
	var mio := _mi_lado >= 0 and (_mi_lado == 0) == de_local
	Sonido.toca("abucheo" if mio or _mi_lado < 0 and de_local else "festejo_hinchada_extra")
	if de_local:
		OlaGrada.lanzar(_raiz3d, "protesta")
	if _rig != null:
		_rig.impacto(0.35, 0.4)

## M-102 (21-10): el banquillo reacciona a la roja de uno de los suyos:
## protestan los que están de pie (los sentados se quedan sentados, ver abajo).
func _banca_protesta(es_local: bool) -> void:
	_banca_gesto(es_local, "discutir_arbitro", 2.6, "protestar")

## Los avisos del motor que merecen rótulo (los goles ya tienen el suyo).
func _al_aviso_motor(texto: String) -> void:
	## En la tanda: «Penal 3: Nombre» lleva el nombre (no se traduce entero).
	if texto.begins_with("🥅 Penal ") and texto.contains(":"):
		var partes := texto.split(":", true, 1)
		_mostrar_rotulo_suceso("🥅 %s %s:%s" % [Idiomas.t("Penal"), partes[0].trim_prefix("🥅 Penal "), partes[1]])
		return
	for clave in ["Córner", "Penal", "PENAL", "Fuera de juego", "Roja", "PALO", "LARGUERO", "parada", "Atajada", "Dentro", "Fallado", "¡Fuera!", "Cambio de campo", "Ventaja"]:
		if texto.contains(clave):
			_mostrar_rotulo_suceso(Idiomas.t(texto))
			return

func _pintar_tanda() -> void:
	if _marcador_tanda == null or _motor == null or _motor.tanda.is_empty():
		return
	var turno := -1 if String(_motor.tanda.get("fase", "")) == "fin" else _motor.tanda_turno()
	_marcador_tanda.pintar(_corto(partido.local.nombre), _corto(partido.visita.nombre), _motor.tanda["tiros"], turno)

## LA TANDA EN PANTALLA: el marcador de círculos arriba al centro y la
## cámara detrás del lanzador.
func _al_empezar_tanda() -> void:
	## El rótulo de estadísticas de la tele no puede taparle el marcador de la tanda.
	for h in get_children():
		if h is RotuloEstadisticas:
			h.queue_free()
	if _marcador_tanda == null:
		_marcador_tanda = MarcadorTanda.crear(self)
	_pintar_tanda()
	_mostrar_banner_gol("🥅 " + Idiomas.t("TANDA DE PENALES"), false)
	if _rig != null:
		_rig.plano_tanda = true

# --- los insertos de la realización (25-10-2026) -------------------------------------

## Si el realizador puede cortar a un plano corto: con el motor real, sin la realización del
## gol, la repetición ni la sala VAR en pantalla. `tranquila`: además, la jugada lejos del
## área y sin ocasión (el cartel del añadido; la tarjeta llega siempre con el juego parado).
func _puede_insertar(tranquila: bool) -> bool:
	if _rig == null or _motor == null or is_instance_valid(_cine) or _sala_var != null:
		return false
	if (_repe != null and _repe.reproduciendo) or (is_instance_valid(_ceremonia) and _ceremonia.activa):
		return false
	if tranquila and (_motor.control_equipo >= 0 or not _motor.estado in ["juego", "saque"]
			or _rig.trans_cerca > 0.35 or _rig.pista_ocasion > 0.0):
		return false
	return true

## LA TARJETA, DE CERCA: el árbitro y el amonestado cuando la enseña.
func _inserto_tarjeta() -> void:
	if not _puede_insertar(false):
		return
	for a: Dictionary in _motor.arbitros:
		if String(a.get("id", "")) == "arbitro" and is_instance_valid(a.get("node")):
			var quien: Dictionary = a.get("mira_a", {})
			var nodo: Node3D = quien.get("node") if not quien.is_empty() and is_instance_valid(quien.get("node")) else null
			_rig.inserto_tarjeta(a["node"], nodo)
			return

## Un inserto se corta si la jugada se reanuda (la tarjeta) o se pone peligrosa (el cartel).
func _vigilar_inserto() -> void:
	if _rig == null or _rig.inserto == "" or _motor == null:
		return
	if (_rig.inserto == "tarjeta" and _motor.estado == "juego") or (_rig.inserto == "cartel" and (_rig.trans_cerca > 0.5 or _rig.pista_ocasion > 0.0)):
		_rig.quitar_inserto()

## Durante la realización del gol, la repetición y los insertos la tele no enseña el radar
## ni la pantalla de la esquina: se desvanecen y vuelven solos (sin tocar si están puestos).
func _hud_realizacion(delta: float) -> void:
	var tapa := (_repe != null and _repe.reproduciendo) or is_instance_valid(_cine) or (_rig != null and _rig.inserto != "")
	for c: Control in [_radar, _mini_pantalla]:
		if c != null:
			c.modulate.a = move_toward(c.modulate.a, 0.0 if tapa else 1.0, delta * 5.0)

