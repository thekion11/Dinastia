class_name PartidoJugable
extends "res://ui/partido_jugable_p1.gd"
## (Parte 2 de 2 de `partido_jugable.gd`.)

func _montar_hud() -> void:
	## Marcador arriba a la izquierda.
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", _panel(LIMA))
	caja.position = Vector2(24, 18)
	add_child(caja)
	_hud.append(caja)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	caja.add_child(h)
	_marcador = _etiqueta(24, Color.WHITE)
	h.add_child(_marcador)
	_reloj = _etiqueta(22, LIMA)
	h.add_child(_reloj)
	## Tus números, arriba a la derecha.
	var caja2 := PanelContainer.new()
	caja2.add_theme_stylebox_override("panel", _panel(FUCSIA))
	caja2.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	caja2.offset_left = -330
	caja2.offset_right = -24
	caja2.offset_top = 18
	add_child(caja2)
	_hud.append(caja2)
	_mis_stats = _etiqueta(15, Color.WHITE)
	caja2.add_child(_mis_stats)
	## Tu jugador y su aguante, abajo a la izquierda.
	var caja3 := PanelContainer.new()
	caja3.add_theme_stylebox_override("panel", _panel(LIMA))
	caja3.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	caja3.offset_left = 24
	caja3.offset_top = -92
	caja3.offset_bottom = -20
	caja3.offset_right = 360
	add_child(caja3)
	_hud.append(caja3)
	_hud_abajo.append(caja3)
	var v := VBoxContainer.new()
	caja3.add_child(v)
	var yo := carrera.jugador(mundo) if carrera != null else null
	var nom := _etiqueta(18, LIMA)
	nom.text = ("%d  %s" % [yo.dorsal, yo.nombre.to_upper()]) if yo != null else "—"
	v.add_child(nom)
	_aguante = ProgressBar.new()
	_aguante.show_percentage = false
	_aguante.custom_minimum_size = Vector2(300, 10)
	_aguante.max_value = 1.0
	var fondo_b := StyleBoxFlat.new()
	fondo_b.bg_color = Color(1, 1, 1, 0.12)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = LIMA
	_aguante.add_theme_stylebox_override("background", fondo_b)
	_aguante.add_theme_stylebox_override("fill", lleno)
	v.add_child(_aguante)
	## La barra de potencia, abajo al centro (solo al cargar o apuntar).
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.max_value = 1.0
	_barra.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_barra.offset_left = -220
	_barra.offset_right = 220
	_barra.offset_top = -70
	_barra.offset_bottom = -50
	var lleno2 := StyleBoxFlat.new()
	lleno2.bg_color = FUCSIA
	_barra.add_theme_stylebox_override("background", fondo_b)
	_barra.add_theme_stylebox_override("fill", lleno2)
	_barra.visible = false
	add_child(_barra)
	## El gran rótulo de sucesos (¡GOL!, falta, córner...).
	_banner = _etiqueta(46, LIMA)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_top = 110
	_banner.offset_left = -500
	_banner.offset_right = 500
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	add_child(_banner)
	## Ayuda de controles.
	_ayuda = _etiqueta(12, Color(1, 1, 1, 0.75))
	_ayuda.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ayuda.offset_left = -760
	_ayuda.offset_right = -24
	_ayuda.offset_top = -44
	_ayuda.offset_bottom = -20
	_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_ayuda)
	_hud.append(_ayuda)
	_hud_abajo.append(_ayuda)
	## La mira del penal.
	_mira = _etiqueta(40, FUCSIA)
	_mira.text = "◎"
	_mira.visible = false
	add_child(_mira)

## Marcador, números, aguante y ayuda fuera durante la ceremonia; los nombres
## sobre los jugadores, fuera también en la realización del gol.
func _ver_hud(si: bool) -> void:
	for c: Control in _hud:
		if is_instance_valid(c):
			c.visible = si
	_ver_rotulos(si)

func ceremonia_activa() -> bool:
	return is_instance_valid(_ceremonia) and _ceremonia.activa

func saltar_ceremonia() -> void:
	if ceremonia_activa():
		_ceremonia.terminar()

func _silbato() -> void:
	Sonido.toca("silbato" if Sonido.NOMBRES.has("silbato") else "clic", Sonido.Bus.INTERFAZ)

func _fin_ceremonia() -> void:
	_ceremonia = null
	_cuadro_fin_ceremonia = Engine.get_process_frames()
	if is_instance_valid(_btn_saltar):
		_btn_saltar.queue_free()
	_btn_saltar = null
	_ver_hud(true)
	if is_instance_valid(_cam):
		_cam.current = true
	if motor != null and motor.estado != "fin" and _pausa == null:
		motor.set_physics_process(true)
	_silbato()

# ---------------------------------------------------------------- ceremonia

func _empezar_ceremonia() -> void:
	var gc := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
	var nombre := String(_perfil.get("nombre", ""))
	if nombre == "":
		nombre = local.estadio_nombre if local.estadio_nombre != "" else "Estadio de %s" % Nombres.visible(local.nombre)
	## El motor espera: la ceremonia mueve a los 22 y los devuelve a su sitio.
	motor.set_physics_process(false)
	_ceremonia = CeremoniaPartido.iniciar(self, _raiz, _en_campo, local, visita, nombre,
		float(gc["dx"]), float(gc["dz"]), StadiumBuilder.tunel_x(_perfil),
		{"fondo": NEGRO, "acento": LIMA, "borde": FUCSIA})
	_ver_hud(false)
	_btn_saltar = Button.new()
	_btn_saltar.text = Idiomas.t("Saltar  ▸")
	_btn_saltar.focus_mode = Control.FOCUS_NONE
	_btn_saltar.add_theme_font_size_override("font_size", 18)
	_btn_saltar.add_theme_color_override("font_color", NEGRO)
	_btn_saltar.add_theme_color_override("font_hover_color", NEGRO)
	_btn_saltar.add_theme_color_override("font_pressed_color", NEGRO)
	for estado: String in ["normal", "hover", "pressed"]:
		var st := _panel(FUCSIA)
		st.bg_color = LIMA if estado != "hover" else LIMA.lightened(0.25)
		_btn_saltar.add_theme_stylebox_override(estado, st)
	add_child(_btn_saltar)
	_btn_saltar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_saltar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_btn_saltar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_btn_saltar.offset_right = -32
	_btn_saltar.offset_bottom = -28
	_btn_saltar.pressed.connect(saltar_ceremonia)
	_ceremonia.terminada.connect(_fin_ceremonia)

func _montar(duracion_mitad: float) -> void:
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	cont.add_child(_vp)
	## Mismos acabados que el partido del modo entrenador (antialias, sombras,
	## debanding): antes aquí solo había un MSAA suelto y la grada se veía
	## rayada a la rasante.
	Calidad.aplicar_viewport(_vp, Calidad.elegida)
	_raiz = Node3D.new()
	_vp.add_child(_raiz)
	## El estadio del local, el que se juega.
	var perfil := mundo.perfil_estadio_de(local).duplicate() if mundo != null and equipo_usuario == null else local.perfil_estadio()
	_perfil = perfil
	Ambience.apply(_raiz, perfil, null, Calidad.elegida)
	StadiumBuilder.build_pitch(_raiz, perfil, local)
	StadiumBuilder.build(_raiz, perfil, int(perfil.get("aforo", 20000)), 0.8, local._hash_id(), local)
	EntornoEstadio.montar(_raiz, perfil, StadiumBuilder.niveles_de(perfil, int(perfil.get("aforo", 20000))))
	OlaGrada.piel_de_pais(_raiz, local.pais)
	OlaGrada.colores_club(_raiz, Color(local.color1), Color(local.color2))
	## Lo que el modo entrenador ya tenía y aquí faltaba: la lluvia o la nieve,
	## la pantalla gigante y camarógrafos/guardias de verdad en vez de maniquíes.
	var gp := StadiumBuilder.geom_de_forma(String(perfil.get("forma", "oval")))
	if String(perfil.get("techo", "")) != "retractil":
		Precipitacion.montar(_raiz, String(perfil.get("clima", "noche")), float(gp["dx"]), float(gp["dz"]), Calidad.elegida)
	_montar_pantalla(perfil)
	_camarografos = VistaEstadio.poner_personal(_raiz)
	## Los 22.
	var yo := carrera.jugador(mundo) if carrera != null else null
	_es_local_usuario = yo != null and yo.club_id == local.id
	var once_l := carrera.once_para_partido(mundo) if _es_local_usuario else local.once()
	var once_v := carrera.once_para_partido(mundo) if (yo != null and yo.club_id == visita.id) else visita.once()
	if equipo_usuario != null and yo != null:
		## Con la selección: tú siempre en el once de tu país.
		_es_local_usuario = equipo_usuario == local
		var mio := _once_con(equipo_usuario, yo)
		if _es_local_usuario:
			once_l = mio
		else:
			once_v = mio
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(once_l)
	var v := Puente3D.once(once_v)
	var lista: Array = []
	var kit_l := Puente3D.kit(local)
	var kit_v := Puente3D.kit_visita(local, visita)
	var por_l := Puente3D.kit_portero(local)
	var por_v := Puente3D.kit_portero(visita)
	lista.append_array(sp.spawn_team(_raiz, l["xi"], l["jugadores"], Puente3D.formacion(local.tactica.formacion), true, kit_l, por_l))
	lista.append_array(sp.spawn_team(_raiz, v["xi"], v["jugadores"], Puente3D.formacion(visita.tactica.formacion), false, kit_v, por_v))
	_en_campo = lista.duplicate()
	## Árbitros, suplentes y los dos DT en la banda, como en el modo entrenador.
	## El trío, de la camiseta que contrasta con los dos equipos (M-072).
	_kit_arb = Puente3D.kit_arbitro(kit_l, kit_v, hash(local.id + "|" + visita.id), [por_l, por_v])
	_sp = sp
	lista.append_array(sp.spawn_arbitros(_raiz, _kit_arb))
	VistaEstadio.poner_banca_de(_raiz, sp, local, once_l, true)
	VistaEstadio.poner_banca_de(_raiz, sp, visita, once_v, false)
	var cb := Comercial.color_balon(mundo.comercial.balon, local) if mundo != null and mundo.comercial != null else []
	if String(perfil.get("clima", "")) == "nieve":
		cb = [Color("#ff7a1a"), Color("#1a1a1a"), "moderno"]
	var balon := StadiumBuilder.spawn_ball(_raiz, Vector3(0, 0.11, 0), cb)
	if _camarografos != null:
		_camarografos.balon = balon
	motor = MotorJugable.new()
	add_child(motor)
	motor.duracion_mitad = duracion_mitad
	motor.preparar(lista, balon, yo.id if yo != null else "", hash(local.id + visita.id))
	## La cabeza de cada jugador sigue al balón (M-098, como en el modo DT).
	MiradaBalon.poner(motor.jugadores, balon)
	_preparar_cambio(sp, yo)
	if carrera != null:
		motor.lanza_usuario = {"corner": bool(carrera.lanzador.get("corners", true)),
			"falta": bool(carrera.lanzador.get("faltas", false)), "penal": bool(carrera.lanzador.get("penales", false)), "banda": false}
	motor.aviso.connect(_mostrar_banner)
	motor.sustitucion.connect(func(_s: String, _e: String, _l: bool) -> void: _escena_cambio())
	## El silbato con el gesto del árbitro (M-106).
	motor.gesto_arbitro.connect(func(g: String) -> void:
		if g == "silbato":
			Sonido.toca("silbato"))
	motor.gol.connect(_al_gol)
	## La celebración dura lo que la realización del gol (como en el modo DT).
	motor.duracion_gol = CineGol.DURACION + 0.6
	motor.remate.connect(func(_l: bool, autor: String, _t: String) -> void:
		if autor != "":
			_tiros_de[autor] = int(_tiros_de.get(autor, 0)) + 1)
	## La repetición graba siempre los últimos segundos (dentro del mundo 3D:
	## sus cámaras son del SubViewport).
	_repe = Repeticion.new()
	_raiz.add_child(_repe)
	_repe.setup(motor.jugadores, balon)
	_repe.terminada.connect(_fin_repeticion)
	motor.terminado.connect(_al_terminar)
	## La cámara, detrás de tu jugador.
	_cam = Camera3D.new()
	_cam.fov = 58.0
	_cam.far = 700.0
	_raiz.add_child(_cam)
	_cam.current = true
	_flecha = _crear_flecha()
	_raiz.add_child(_flecha)
	_montar_hud()
	if _banner_pendiente != "":
		_mostrar_banner.call_deferred(_banner_pendiente)
	if con_ceremonia and entra_al < 0 and motor.minuto() == 0 and _pref("ceremonia", true):
		_empezar_ceremonia()
	else:
		_silbato()

## La cámara va detrás de tu jugador, mirando hacia el arco rival; en los
## lanzamientos, detrás del balón.
func _actualizar_camara(delta: float) -> void:
	var foco: Vector3
	var d := MotorJugable.dir_ataque(_es_local_usuario)
	if motor.apuntando or motor.estado == "saque" and not motor.usuario.is_empty() and motor.saque.get("lanzador") == motor.usuario:
		foco = motor.balon.position
	elif not motor.usuario.is_empty():
		foco = motor.pos(motor.usuario).lerp(motor.balon.position, 0.35)
	else:
		foco = motor.balon.position
	var detras := Vector3(0, 12.5, -15.0 * d)
	var mira := foco + Vector3(0, 0.5, 10.0 * d)
	if motor.estado == "saque" and String(motor.saque.get("tipo", "")) == "penal":
		detras = Vector3(0, 3.2, -7.0 * d)
	elif motor.apuntando:
		## Córner y falta: detrás del balón, mirando adonde apuntas.
		var dir := motor.direccion_apunte()
		detras = -dir * 10.0 + Vector3(0, 8.5, 0)
		mira = foco + dir * 18.0
	var deseada := foco + detras
	## LA CÁMARA NO SALE DEL CAMPO (29-9-2026). Pegada a la grada se veía el
	## público de cerca -muñecos y textura estirada- y la tapaban las vallas.
	## Si choca con el borde, en vez de atravesarlo sube: queda un plano
	## picado, como la cámara de una transmisión en el fondo.
	var lim := Vector3(33.0, 0, 51.0)
	var fuera := maxf(absf(deseada.x) - lim.x, 0.0) + maxf(absf(deseada.z) - lim.z, 0.0)
	deseada.x = clampf(deseada.x, -lim.x, lim.x)
	deseada.z = clampf(deseada.z, -lim.z, lim.z)
	deseada.y += fuera * 0.6
	_cam.position = _cam.position.lerp(deseada, clampf(delta * 3.5, 0.0, 1.0)) if _cam.position.length() > 0.1 else deseada
	_cam.look_at(mira, Vector3.UP)

func _abrev(nombre: String) -> String:
	var n := Nombres.visible(nombre)
	return n.substr(0, 3).to_upper() if n.length() > 3 else n.to_upper()

## La guía con las teclas que el jugador haya configurado (Mando).
func _guia_controles(con_balon: bool) -> String:
	var c := func(a: String) -> String: return Mando.corto_de(a)
	if con_balon:
		return Idiomas.t("CON BALÓN: %s pase · %s tiro (mantén) · %s centro · %s al hueco · %s rosca/tenso · %s vaselina/pared · %s proteger · %s sprint · stick der. filigranas") % [
			c.call("jugar_pase"), c.call("jugar_tiro"), c.call("jugar_centro"), c.call("jugar_filtrado"),
			c.call("jugar_mod"), c.call("jugar_cambiar"), c.call("jugar_regate"), c.call("jugar_sprint")]
	return Idiomas.t("SIN BALÓN: %s contener · %s entrada · %s barrida · %s bregar · %s pedir el balón · %s sprint · %s pausa") % [
		c.call("jugar_pase"), c.call("jugar_tiro"), c.call("jugar_centro"), c.call("jugar_regate"), c.call("jugar_pedir"),
		c.call("jugar_sprint"), c.call("jugar_pausa")]

func _actualizar_apunte() -> void:
	_flecha.visible = false
	_mira.visible = false
	if not motor.apuntando:
		return
	var tipo := String(motor.saque.get("tipo", ""))
	var lugar: Vector3 = motor.saque["lugar"]
	if tipo == "penal":
		var arco_z := MotorJugable.LARGO * MotorJugable.dir_ataque(_es_local_usuario)
		var x := -float(motor.apunte["x"]) * MotorJugable.dir_ataque(_es_local_usuario) * (MotorJugable.PALO - 0.35)
		var y := 0.35 + float(motor.apunte["y"]) * 1.8
		var p3 := Vector3(x, y, arco_z)
		if not _cam.is_position_behind(p3):
			_mira.visible = true
			_mira.position = _cam.unproject_position(p3) - Vector2(16, 28)
		return
	var dir := motor.direccion_apunte()
	var largo := 3.0 + float(motor.apunte["fuerza"]) * 10.0
	_flecha.visible = true
	_flecha.scale = Vector3(1, 1, largo)
	_flecha.position = lugar + dir * (largo * 0.5 + 0.6) + Vector3(0, 0.05 + float(motor.apunte["loft"]) * 0.5, 0)
	_flecha.rotation.y = atan2(dir.x, dir.z)

## Lo que falta se juega solo (tu jugador en piloto automático), a toda
## velocidad y sin pantalla.
func _simular_resto() -> void:
	if _pausa != null:
		_pausa.queue_free()
		_pausa = null
	saltar_ceremonia()
	if is_instance_valid(_cine):
		_cine.cortar()
		_cine = null
	_simulando = true
	motor.autopiloto = true
	var pasos := 0
	while motor.estado != "fin" and pasos < 60 * 1200:
		motor.paso(1.0 / 20.0)
		pasos += 1
	_simulando = false
	motor.set_physics_process(false)

func _alternar_pausa() -> void:
	if _pausa != null:
		_pausa.queue_free()
		_pausa = null
		motor.set_physics_process(true)
		return
	motor.set_physics_process(false)
	_pausa = _caja_centro("PAUSA", [
		["▶  Seguir jugando", _alternar_pausa],
		["🎮  Controles", func() -> void:
			if _controles == null:
				_controles = PanelControles.abrir(self)
				_controles.cerrado.connect(func() -> void: _controles = null)],
		["⏩  Simular lo que queda", _simular_resto],
	])

func _process(delta: float) -> void:
	StadiumBuilder.ocultar_techo_ante(get_viewport().get_camera_3d())
	## La grada sigue el balón con la cabeza (M-049), como en el modo DT.
	if Engine.get_process_frames() % 4 == 0 and motor != null and motor.balon != null:
		OlaGrada.mirar(_raiz, motor.balon.global_position)
	_t_rotulos -= delta
	if is_instance_valid(_cine) and _pausa == null:
		_cine.paso(delta)
	if _t_rotulos <= 0.0 and motor != null and not _rotulos_fuera:
		_t_rotulos = 0.1
		PlayerSpawner.despejar_rotulos(motor.jugadores, _cam, motor.balon.position, _vp.size.y if _vp != null else 900.0)
	if motor == null:
		return
	_actualizar_camara(delta)
	var yo := motor.usuario
	_marcador.text = "%s  %d - %d  %s" % [_abrev(local.nombre), motor.goles[0], motor.goles[1], _abrev(visita.nombre)]
	_reloj.text = "%d'" % motor.minuto()
	var s := motor.stats
	_mis_stats.text = Idiomas.t("⚽ %d   🅰 %d   🎯 %d/%d   ✔ %d/%d pases   ⭐ %.1f") % [s["goles"], s["asist"], s["a_puerta"], s["tiros"], s["pases_ok"], s["pases"], motor.nota_usuario()]
	if not yo.is_empty():
		_aguante.value = motor.forma_fisica(yo)
		if motor.estado == "juego":
			_minutos_usuario += delta / motor.duracion_mitad * 45.0
	var con_balon := not yo.is_empty() and motor.poseedor == yo
	if motor.apuntando:
		_barra.visible = true
		_barra.value = float(motor.apunte["fuerza"])
		_ayuda.text = Idiomas.t("APUNTAR: ◀ ▶ dirección · ▲ ▼ altura · mantén TIRO para cargar y suelta · PASE: a ras")
	elif motor.cargando:
		_barra.visible = true
		_barra.value = motor.carga
	else:
		_barra.visible = false
		_ayuda.text = _guia_controles(con_balon)
	_actualizar_apunte()
	if Input.is_action_just_pressed("jugar_pausa") and motor.estado != "fin" and _controles == null \
			and not ceremonia_activa() and not (_repe != null and _repe.reproduciendo) \
			and Engine.get_process_frames() != _cuadro_fin_ceremonia:
		_alternar_pausa()

## Para las pruebas: si hay realización o repetición en marcha.
func realizando_gol() -> bool:
	return is_instance_valid(_cine) or (_repe != null and _repe.reproduciendo)
