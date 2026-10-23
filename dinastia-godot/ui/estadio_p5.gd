extends "res://ui/estadio_p4.gd"
## [Capa 5/6 de `estadio.gd`] _montar_motor, _crear_banner_gol, _crear_rotulo_jugada, _arrancar_partido, abrir, _escalar_rotulos … (+2)

func _montar_motor() -> void:
	partido.motor_externo = true
	_motor = MotorJugable.new()
	add_child(_motor)
	_motor.set_physics_process(false)
	_motor.duracion_mitad = 45.0 * float(SEG_POR_MINUTO.get(ritmo_partido(), 5.5))
	_motor.cansancio_real = true
	_motor.duracion_gol = 7.6
	_motor.tarjetas_reales = true
	_motor.autopiloto = true
	_motor.lanza_usuario = {"corner": true, "falta": true, "penal": true, "banda": true}
	_motor.eliminatoria = eliminatoria
	_motor.preparar(_en_campo, _balon, "", hash(partido.local.id + partido.visita.id) + partido.minuto)
	## La cabeza de cada jugador sigue al balón (M-098).
	MiradaBalon.poner(_motor.jugadores, _balon)
	_motor.empezar_en(partido.minuto, partido.goles_local, partido.goles_visita)
	_motor.sortear_anadido()
	_mi_lado = 0 if partido.local.id == Partido.ctx_club_id else (1 if partido.visita.id == Partido.ctx_club_id else -1)
	if practica:
		_motor.empezar_practica()
		call_deferred("_empezar_practica")
	## La salida de los equipos: papelitos y bengalas de la hinchada (M-050).
	if partido.minuto == 0 and partido.goles_local + partido.goles_visita == 0:
		FestejoGrada.lanzar(_raiz3d, Color(partido.local.color1), Color(partido.local.color2), "salida")
	_stats = EstadisticasVivo.new()
	_motor.gol.connect(func(de_local: bool, autor: String, asist: String) -> void:
		_stats.cerrar_tiro(de_local, "gol", _balon.position if is_instance_valid(_balon) else Vector3.ZERO)
		partido.gol_externo(de_local, autor, asist)
		## La red se abomba donde entró el balón (M-149).
		if is_instance_valid(_balon):
			RedArco.golpe(_raiz3d, _balon.global_position)
		## Confeti, bengalas y humo de la hinchada local (M-050).
		if de_local:
			FestejoGrada.lanzar(_raiz3d, Color(partido.local.color1), Color(partido.local.color2), "gol")
			## Y la grada salta en onda desde el fondo donde entró (M-036).
			var fondo := signf(_balon.position.z) if is_instance_valid(_balon) else 1.0
			OlaGrada.lanzar(_raiz3d, "onda", Vector3(0, 0, fondo * 62.0))
		Mando.vibrar(1.0 if (_mi_lado == 0) == de_local else 0.35, 0.6)
		if _rig != null:
			_rig.impacto(0.9, 0.7)
			_rig.golpe_de_zoom(5.0, 1.2)
		## EL VAR SE USA (14-10-2026): con VAR en la liga, uno de cada cinco goles
		## se revisa en la sala (el partido espera). Desde el 17-10 uno de cada
		## tres revisados se ANULA: el marcador, el acta y el goleador vuelven
		## atrás y la grada lo nota.
		## Desde el 17-10 el fuera de juego sale de la JUGADA: el motor mide cuánto
		## estaba el goleador por delante de la línea en el pase (`margen_gol`);
		## si fue ajustado se revisa siempre, y se anula si de verdad estaba
		## adelantado (lo que el juez de línea dejó pasar, hasta 30 cm). La falta
		## previa sigue siendo rara y al azar.
		var m := _motor.margen_gol
		## Medido con la sonda (17-10): la mayoría de goles tras pase llegan con
		## el goleador 1-2 m en línea; se revisan los de menos de 1 m y, a veces,
		## los de hasta 1,8 m. Solo se anula si estaba de verdad adelantado.
		var ajustado := m <= 0.3 and (m > -1.0 or (m > -1.8 and Azar.suerte(0.35)))
		if Partido.ctx_factor_tarjetas < 1.0 and (ajustado or Azar.suerte(0.08)):
			var anula := m > 0.0 if ajustado else Azar.suerte(0.25)
			var motivo := "Revisión del gol: posible fuera de juego" if ajustado else "Revisión del gol: posible falta previa"
			get_tree().create_timer(2.2).timeout.connect(func() -> void:
				if is_instance_valid(self) and _motor != null:
					## Con la línea del fuera de juego en el monitor (M-118).
					var lineas := _motor.lineas_gol.duplicate() if ajustado else {}
					if not lineas.is_empty():
						lineas["margen"] = m
					_a_la_revision_var(partido.minuto, motivo, anula, func() -> void:
						_anular_gol_motor(de_local, autor), lineas)))
	_motor.remate.connect(func(de_local: bool, autor: String, tipo: String) -> void:
		var tirador := _nodo_de(autor)
		_stats.cerrar_tiro(de_local, tipo, Vector3.ZERO, tirador.position if tirador != null else (_balon.position if is_instance_valid(_balon) else Vector3.ZERO))
		partido.remate_externo(de_local, autor, tipo)
		Mando.vibrar(0.3, 0.15)
		if _rig != null:
			_rig.golpe_de_zoom(2.0, 0.5))
	_motor.tarjeta.connect(func(id: String, roja: bool, de_local: bool) -> void:
		_stats.tarjeta(de_local, roja)
		partido.tarjeta_externa(id, roja)
		if roja:
			_banca_protesta(de_local)
		## La grada de casa protesta la tarjeta a uno de los suyos (M-045).
		if de_local:
			OlaGrada.lanzar(_raiz3d, "protesta")
		Mando.vibrar(0.6 if roja else 0.35, 0.3)
		if _rig != null:
			_rig.impacto(0.45 if roja else 0.25, 0.4))
	_motor.aviso.connect(_al_aviso_motor)
	## El silbato del árbitro con su gesto (M-106). El final del partido ya
	## tiene su pitido (resumen); aquí, el del descanso y cada falta.
	_motor.gesto_arbitro.connect(func(g: String) -> void:
		if g == "silbato":
			Sonido.toca("silbato")
		elif g == "fin" and _motor.estado == "descanso":
			Sonido.toca("pitido_final"))
	## PRÓRROGA Y PENALES (17-10-2026): el acta sigue hasta el 120' y guarda la
	## tanda del césped (nadie la vuelve a sortear).
	_motor.prorroga_empieza.connect(func() -> void:
		partido.prorroga_externa()
		_mostrar_banner_gol("⏱ %s  %d - %d" % [Idiomas.t("PRÓRROGA"), partido.goles_local, partido.goles_visita], false)
		Sonido.toca("pitido_final"))
	_motor.tanda_empieza.connect(_al_empezar_tanda)
	_motor.cambio_estado.connect(func(e: String) -> void:
		if e != "tanda_penal" or _motor.tanda_equipo_usuario() < 0:
			return
		_pintar_tanda()
		if _motor.tanda_turno() == _motor.tanda_equipo_usuario():
			_mostrar_rotulo_suceso(Idiomas.t("Tu penal: apunta con el stick y mantén TIRO para la fuerza"))
		else:
			_mostrar_rotulo_suceso(Idiomas.t("Tu portero: elige el lado con el stick antes del disparo")))
	_motor.tanda_tiro.connect(func(_eq: int, _id: String, marcado: bool) -> void:
		_pintar_tanda()
		Sonido.toca("gol" if marcado else "ocasion", Sonido.Bus.AMBIENTE)
		if _rig != null and marcado:
			_rig.impacto(0.35, 0.4))
	_motor.tanda_terminada.connect(func(gl: int, gv: int) -> void:
		partido.penales_externos(gl, gv)
		_pintar_tanda())
	_motor.tactica_rapida.connect(func(eq: int, clave: String, valor: int) -> void:
		var c: Club = partido.local if eq == 0 else partido.visita
		if c != null and c.tactica != null:
			c.tactica.set(clave, valor)
			partido.invalidar_fuerza())
	_actualizar_tacticas()
	## La transmisión, como en el vídeo: cámara alta que sigue el balón y la
	## pantalla limpia (sin nombres sobre los 22 ni la pantalla gigante en la
	## esquina; se pueden encender en ⚙).
	if _rig != null:
		var it := _rig.camera_names.find("Transmisión")
		if it >= 0 and not (PersonajeDT.sancionado and _rig.current_name().begins_with("Desde la grada")):
			_rig.switch_to(it)
			if _btn_camara != null:
				_btn_camara.text = Idiomas.t("📷 Cámara: ") + _rig.current_name()
	_nombres_globales = PlayerSpawner.mostrar_nombres
	if not _pref("nombres_motor", false):
		_mostrar_nombres(false)
	## La dificultad de la CPU (20-10-2026): la última elegida.
	_motor.dificultad_cpu = dificultad_cpu_guardada()
	## Si jugaste tú el último partido, vuelves a jugar (se recuerda).
	if _pref("control_equipo", false) and _mi_lado >= 0 and not practica:
		_alternar_control_motor.call_deferred()
	if _mini_pantalla != null and not _pref("pantalla_esquina_motor", false):
		_mini_pantalla.visible = false

## Cartel de gol, abajo al centro -pensado para pantalla horizontal, la misma
## orientación en la que se juega esta vista-. Empieza invisible y fuera de la
## pantalla (offset vertical positivo, `clip_contents` del padre no hace
## falta porque el Control raíz ya mide toda la pantalla): `_mostrar_banner_gol()`
## lo trae, lo sostiene y lo despide, todo con el mismo Tween para que un
## segundo gol a los dos segundos del primero no dispare una animación a medias
## sobre otra.
func _crear_banner_gol() -> void:
	_banner_caja = PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0.10, 0.62, 0.34, 0.92)
	e.set_corner_radius_all(10)
	e.content_margin_left = 26; e.content_margin_right = 26
	e.content_margin_top = 10; e.content_margin_bottom = 10
	e.border_width_top = 3
	e.border_color = Color(0.93, 0.85, 0.35)
	_banner_caja.add_theme_stylebox_override("panel", e)
	_banner_caja.anchor_left = 0.5
	_banner_caja.anchor_right = 0.5
	_banner_caja.anchor_top = 1.0
	_banner_caja.anchor_bottom = 1.0
	_banner_caja.offset_left = -260
	_banner_caja.offset_right = 260
	_banner_caja.offset_top = -108
	_banner_caja.offset_bottom = -60
	_banner_caja.pivot_offset = Vector2(260, 24)
	_banner_caja.modulate = Color(1, 1, 1, 0)
	add_child(_banner_caja)
	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 24)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.text = ""
	_banner_caja.add_child(_banner)

func _crear_rotulo_jugada() -> void:
	_rotulo_jugada = PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.62)
	e.border_width_left = 4
	e.border_color = Color("c9a227")
	e.set_corner_radius_all(4)
	e.content_margin_left = 12; e.content_margin_right = 14
	e.content_margin_top = 4; e.content_margin_bottom = 4
	_rotulo_jugada.add_theme_stylebox_override("panel", e)
	_rotulo_jugada.anchor_left = 0.0
	_rotulo_jugada.anchor_right = 0.0
	_rotulo_jugada.offset_left = 18
	_rotulo_jugada.offset_top = 60
	_rotulo_jugada.modulate.a = 0.0
	_rotulo_jugada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rotulo_jugada)
	_lbl_jugada = Label.new()
	_lbl_jugada.add_theme_font_size_override("font_size", 14)
	_lbl_jugada.add_theme_color_override("font_color", Color("e9eeea"))
	_rotulo_jugada.add_child(_lbl_jugada)

# --- el partido, jugándose -------------------------------------------------

func _arrancar_partido() -> void:
	_juego = MatchPlayback.new()
	## La posesión estimada sale de la fuerza de los dos onces, que es la que ya
	## decide los goles. Así lo que se ve en el campo -quién ataca más- cuadra
	## con lo que dice el marcador, en vez de ser un adorno aparte.
	var fl: float = partido.fuerza(partido.once_local, partido.local)["ata"]
	var fv: float = partido.fuerza(partido.once_visita, partido.visita)["ata"]
	var pos := 100.0 * fl / maxf(fl + fv, 0.001)
	_juego.setup([], _en_campo, Partido.MINUTOS, pos, _balon, club.tactica, visitante.tactica)
	## EL RELOJ EMPIEZA DONDE VA EL PARTIDO (28-9-2026). Al reabrir el 3D a
	## mitad de partido -tras el descanso, o con "Volver" y "Ver en 3D"- la
	## reproducción arrancaba en el 0' con el partido ya en el 45': durante
	## 45 minutos de reloj no se simulaba nada y parecía colgado ("después de
	## la charla del medio tiempo no deja continuar").
	_juego.elapsed = float(partido.minuto) * _juego.seconds_per_minute
	_descanso_hecho = partido.minuto >= 45
	## La cámara del árbitro sigue su cabeza.
	var arb: Variant = _juego.players_by_id.get("arbitro")
	if arb is Dictionary and _rig != null:
		_rig.arbitro_ref = (arb as Dictionary).get("node")
	## La sala VAR, cuando el árbitro pide revisar.
	_juego.revision_var.connect(_a_la_revision_var)
	## La repetición del gol (plan maestro B3): graba siempre los últimos
	## segundos de los 22 y del balón.
	_repe = Repeticion.new()
	add_child(_repe)
	_repe.setup(_en_campo, _balon)
	_repe.terminada.connect(func() -> void:
		if _rotulo_repe != null:
			_rotulo_repe.visible = false)
	_juego.jugada_ambiente.connect(_al_jugada_ambiente)
	if _btn_velocidad != null:
		_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()
	partido.gol.connect(_al_gol)
	partido.gol.connect(func(_c: Club, _a: Jugador, _m: int, _as: Jugador) -> void: _frenar_destacado())
	partido.remate.connect(func(_c: Club, _a: Jugador, _t: String, _m: int) -> void: _frenar_destacado())
	partido.invasion_de_campo.connect(func(_m: int) -> void:
		_mostrar_banner_gol("🚨 INVASIÓN DE CAMPO", false))
	if modo_destacados:
		_juego.vel_idx = VEL_DESTACADOS_RAPIDO
		if _btn_velocidad != null:
			_btn_velocidad.text = "⏱ " + _juego.etiqueta_velocidad()
	partido.tarjeta.connect(_a_la_tarjeta)
	partido.cambio_hecho.connect(_al_cambio)
	partido.remate.connect(_al_remate)
	## Tiros y goles de cada uno, para la carta del goleador.
	partido.remate.connect(func(_c: Club, a: Jugador, _t: String, _m: int) -> void:
		if a != null:
			_tiros_de[a.id] = int(_tiros_de.get(a.id, 0)) + 1)
	partido.gol.connect(func(_c: Club, a: Jugador, _m: int, _as: Jugador) -> void:
		if a != null:
			_tiros_de[a.id] = int(_tiros_de.get(a.id, 0)) + 1
			_goles_de[a.id] = int(_goles_de.get(a.id, 0)) + 1)
	partido.lesion.connect(_a_la_lesion)
	partido.decision_arbitral.connect(_a_la_decision_arbitral)
	## Saque inicial + murmullo de fondo: lo mismo que ya sonaba en la pantalla
	## 2D de `partido_vivo.gd`, que hasta hoy este visor 3D -el que de verdad se
	## juega- nunca reproducía.
	Sonido.toca("saque_inicial")
	Sonido.toca("murmullo", Sonido.Bus.AMBIENTE)
	## SONIDOS QUE EXISTÍAN Y NUNCA SONABAN (25-9-2026): de los 205 del
	## catálogo, 157 no tenían ningún disparador. Aquí los del partido: la
	## salida del túnel, el ambiente según el clima del estadio, los tiempos
	## del reloj y los goles especiales.
	if partido.minuto == 0:
		Sonido.toca("salida_tunel", Sonido.Bus.AMBIENTE)
	## La presentación: vuelo de cámara con el rótulo del partido (B3).
	if _pref("intro", true) and partido.minuto == 0:
		var gi := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
		var nombre_est := club.estadio_nombre if club.estadio_nombre != "" else "Estadio de %s" % club.nombre
		## LA CEREMONIA (13-10-2026): salida con niños, mascota, lona y
		## alineaciones. Con el ajuste «ceremonia» apagado, el vuelo corto.
		if _pref("ceremonia", true):
			## Se monta al final de `_arrancar_partido`, cuando el motor ya colocó
			## a todos para el saque (si no, los recolocaba encima).
			_ceremonia_pendiente = nombre_est
		else:
			_intro = IntroPartido.iniciar(self, float(gi["dx"]), float(gi["dz"]), 20.0,
				"%s  vs  %s" % [club.nombre, visitante.nombre],
				"%s  ·  %s butacas" % [nombre_est, _miles(club.estadio_aforo)])
	var clima := String(_perfil.get("clima", "noche"))
	var por_clima := {"lluvia": "lluvia_ambiente", "tormenta": "trueno", "niebla": "niebla_ambiente",
		"nieve": "frio_extremo", "noche": "noche_estadio", "dia": "dia_soleado", "tarde": "eco_estadio"}
	if por_clima.has(clima):
		Sonido.toca(String(por_clima[clima]), Sonido.Bus.AMBIENTE)
	partido.minuto_jugado.connect(_al_minuto_sonoro)
	## Semilla fija por partido (mismo criterio que `_rng` en MatchPlayback):
	## repetible si se reabre el mismo partido, pero sin tocar `Azar`.
	_rng_ambiente.seed = hash("ambiente") + partido.local.id.hash() + partido.visita.id.hash()
	_prox_ambiente = _juego.elapsed + _rng_ambiente.randf_range(10.0, 18.0)

	if _pref("motor_real", true):
		_montar_motor()
	else:
		# Control interactivo de jugador (Modo FC 26), con las jugadas con guion
		_control = ControlPartido.new()
		add_child(_control)
		var es_local_user: bool = (partido.local == club)
		_control.setup(_en_campo, _balon, _rig, es_local_user, _juego, _radar)


	var caja := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(0, 0, 0, 0.55)
	e.set_corner_radius_all(8)
	e.content_margin_left = 14; e.content_margin_right = 14
	e.content_margin_top = 6; e.content_margin_bottom = 6
	caja.add_theme_stylebox_override("panel", e)
	## Anclas a mano, sin preset.
	##
	## Con `position` el marcador se iba al borde izquierdo, y con
	## `set_anchors_preset(..., keep_offsets)` tampoco: ese `keep_offsets`
	## RECALCULA los offsets para conservar el rectángulo actual, así que pisa lo
	## que se le ponga justo después. Puestas las cuatro anclas y los cuatro
	## offsets a mano no hay ambigüedad. Desde el 25-9 va arriba a la izquierda
	## (la barra de botones pasó a la derecha), con 380 px de ancho.
	caja.anchor_left = 0.0
	caja.anchor_right = 0.0
	caja.anchor_top = 0.0
	caja.anchor_bottom = 0.0
	caja.offset_left = 18
	caja.offset_right = 398
	caja.offset_top = 12
	caja.offset_bottom = 54
	add_child(caja)
	_caja_marcador = caja
	## El pivote tiene que quedar al centro del panel para que el "salto" del
	## gol (escalar en `_animar_marcador_gol()`) crezca parejo a los dos lados,
	## no que se vaya de bruces hacia una esquina.
	caja.pivot_offset = Vector2(190, 21)
	_marcador = Label.new()
	_marcador.add_theme_font_size_override("font_size", 20)
	_marcador.add_theme_color_override("font_color", Color("e9eeea"))
	_marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_marcador)
	_refrescar_marcador()

	_crear_banner_gol()
	_crear_rotulo_jugada()
	if _ceremonia_pendiente != "":
		var gc := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
		_ceremonia = CeremoniaPartido.iniciar(self, _raiz3d, _en_campo, partido.local, partido.visita, _ceremonia_pendiente,
			float(gc["dx"]), float(gc["dz"]), StadiumBuilder.tunel_x(_perfil))
		_ceremonia_pendiente = ""
		## La pantalla limpia mientras dura: sin marcador, radar ni nombres.
		var ocultos: Array = []
		for c: Control in [_caja_marcador, _mini_pantalla, _radar]:
			if c != null and c.visible:
				c.visible = false
				ocultos.append(c)
		var nombres_antes := PlayerSpawner.mostrar_nombres
		_mostrar_nombres(false)
		_ceremonia.terminada.connect(func() -> void:
			for c: Control in ocultos:
				if is_instance_valid(c):
					c.visible = true
			_mostrar_nombres(nombres_antes))

## Tres modos, según lo que se le pase:
##
##   abrir(club)                      el recinto vacío, para mirarlo
##   abrir(club, occ, rival)          los 22 colocados, sin jugar
##   abrir(club, occ, rival, partido) el partido, jugándose de verdad
##
## En el tercero manda el reloj de `MatchPlayback`: cada vez que cruza un minuto,
## le pide otro minuto al `Partido`. UN solo reloj y UNA sola verdad. Si el reloj
## corriera aquí y en la pantalla 2D a la vez, el marcador que se ve y el que va a
## la tabla se separarían, que es el fallo que ya costó una depuración con el
## partido dirigido.
## `perfil_forzado`: el perfil YA calculado -normalmente `mundo.perfil_estadio_de(c)`-,
## para cuando `c` es tu propio club y por tanto su recinto es el que hayas
## diseñado en `EstadioPropio`, no el que sale del hash de su id. Sin este
## parámetro `_construir()` cae siempre en `c.perfil_estadio()` -el genérico-,
## que es lo que hacía antes de que existiera este parámetro: el visor 3D
## nunca mostraba una reforma pagada, ni en el partido en vivo ni en el botón
## de vista previa, aunque el diseñador ya la tuviera guardada.
## `colores_balon`: `[claro, oscuro]` de la piel elegida en Club → Detalles del
## club (`Comercial.color_balon()`). Vacío se queda con la piel clásica.
func abrir(c: Club, ocupacion: float = 0.8, rival: Club = null, p: Partido = null,
		perfil_forzado: Dictionary = {}, colores_balon: Array = []) -> void:
	club = c
	visitante = rival
	partido = p
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir(ocupacion, perfil_forzado, colores_balon)
	if partido != null:
		_arrancar_partido()

func _escalar_rotulos() -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null or is_equal_approx(cam.fov, _fov_rotulos):
		return
	_fov_rotulos = cam.fov
	var tam := PlayerSpawner.TAM_ROTULO * tan(deg_to_rad(cam.fov) * 0.5) / tan(deg_to_rad(46.0) * 0.5)
	for f: Dictionary in _en_campo:
		var n: Node3D = f.get("node")
		if is_instance_valid(n) and n.has_node(PlayerSpawner.ROTULO):
			var rot := n.get_node(PlayerSpawner.ROTULO) as Label3D
			rot.pixel_size = tam
			if rot.has_node(PlayerSpawner.BARRA):
				rot.get_node(PlayerSpawner.BARRA).set("pixel_size", tam)

func _despejar_rotulos(delta: float) -> void:
	if not PlayerSpawner.mostrar_nombres:
		return
	_t_despeje -= delta
	if _t_despeje > 0.0:
		return
	_t_despeje = 0.1
	var bpos := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	PlayerSpawner.despejar_rotulos(_en_campo, get_viewport().get_camera_3d(), bpos, get_viewport().get_visible_rect().size.y)

func _energia_motor(f: Dictionary) -> float:
	if _motor == null:
		return -1.0
	var id := String(f.get("id", ""))
	for p: Dictionary in _motor.jugadores:
		if p.get("node") == f.get("node") or (id != "" and String(p.get("id", "")) == id):
			return _motor.forma_fisica(p)
	return -1.0
