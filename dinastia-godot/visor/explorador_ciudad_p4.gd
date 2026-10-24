extends "res://visor/explorador_ciudad_p3.gd"
## [Capa 4/6 de `explorador_ciudad.gd`] _mover_en_estadio, _bajar_a_la_galeria, _usar, _tactil, _aplicar_ajustes, _montar_hud … (+5)

## Dentro del estadio se camina por las zonas de `TunelVestuario` (vestuario,
## túnel, banda, campo y la puerta). Salir por la puerta devuelve a la calle.
func _mover_en_estadio(delta: float) -> void:
	var e := _entrada()
	if _sentado:
		_mirada = clampf(_mirada - e.x * delta * 1.4, -1.2, 1.2)
		var dir := Vector3(sin(rumbo + _mirada), 0, cos(rumbo + _mirada))
		camara.position = cuerpo.position + Vector3(0, 1.2, 0) + Vector3(sin(rumbo), 0, cos(rumbo)) * 0.1
		camara.look_at(camara.position + dir * 10.0 + Vector3(0, -1.6, 0), Vector3.UP)
		return
	var corre := Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
	var objetivo_e := (VEL_CORRER if corre else VEL_PIE) * clampf(e.y, -0.5, 1.0)
	_vel_pie = move_toward(_vel_pie, objetivo_e, (7.0 if absf(objetivo_e) > absf(_vel_pie) else 12.0) * delta)
	vel = _vel_pie
	## La galería tiene cinta rodante: 150 m se hacen en un rato.
	if _zona_est == "Galería":
		vel *= GaleriaClub.CINTA
	rumbo -= e.x * delta * 2.6
	var adelante := Vector3(sin(rumbo), 0, cos(rumbo))
	var nueva := cuerpo.position + adelante * vel * delta
	var local := nueva - CityBuilder.ESTADIO_EN
	var zonas: Array = _est["zonas"]
	## La puerta del club se abre sola desde dentro (sensor), como en la vida.
	if _planta == 0:
		var pl: Vector3 = _est["puerta"]
		EntradaClub.abrir(get_tree(), Vector2(local.x - pl.x, local.z - pl.z).length() < 1.9)
	if _planta == GaleriaClub.PLANTA and GaleriaClub.arriba(_est, local):
		## Arriba de la escalera mecánica: la calle.
		_subir_de_la_galeria()
		return
	if _planta == 0 and local.z > float((_est["puerta"] as Vector3).z) + 1.0:
		## Cruzada la puerta, ya en la calle.
		_salir_del_estadio()
		return
	## Colisión del cuerpo entero (paredes, muebles, gente): `ColisionClub`.
	## La puerta a la calle es la excepción: cruzarla saca del estadio.
	if _planta == 0 and local.z > float((_est["puerta"] as Vector3).z) + 0.5:
		_salir_del_estadio()
		return
	var ant := cuerpo.position
	var pe_col := (get_tree().get_first_node_in_group("personal_club") as PersonalEstadio) if is_inside_tree() else null
	var llega := ColisionClub.mover(cuerpo, ant, nueva, zonas, _planta, CityBuilder.ESTADIO_EN, pe_col)
	var pedido := Vector2(nueva.x - ant.x, nueva.z - ant.z).length()
	var hecho := Vector2(llega.x - ant.x, llega.z - ant.z).length()
	if pedido > 1e-4:
		if hecho < pedido * 0.2:
			vel = 0.0
			_vel_pie = 0.0
		elif hecho < pedido * 0.9:
			_vel_pie *= 0.92
	cuerpo.position = Vector3(llega.x, RecorridoClub.y_de(_planta), llega.z)
	PersonalEstadio.avisar_jugador(cuerpo.position - CityBuilder.ESTADIO_EN, _planta)
	cuerpo.rotation.y = rumbo
	_animar_dt(vel)
	var z := TunelVestuario.zona_en(zonas, cuerpo.position - CityBuilder.ESTADIO_EN, _planta)
	var nombre := String(z.get("nombre", ""))
	var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
	var g: Dictionary = pe.cercano(cuerpo.position - CityBuilder.ESTADIO_EN, _planta) if pe != null else {}
	if not g.is_empty():
		_aviso.text = Idiomas.t("E: hablar con %s (%s)") % [String(g["nombre"]), Idiomas.t(String(g["puesto"]))]
		_zona_est = nombre
		_aviso_hablar = true
	elif RecorridoClub.junto_a_la_grada(cuerpo.position - CityBuilder.ESTADIO_EN, _planta):
		_aviso.text = Idiomas.t("E: sentarse en la grada")
		_zona_est = "·grada"
	elif nombre != _zona_est or _aviso_hablar:
		## Antes se miraba si el texto empezaba por «E: hablar»: en otro idioma
		## nunca coincidía y el aviso de hablar se quedaba pegado.
		_aviso_hablar = false
		_zona_est = nombre
		_aviso.text = RecorridoClub.aviso_de(nombre)
		if RecorridoClub.sala_decorable(nombre):
			_aviso.text += "  ·  " + Idiomas.t("E: decorar")
	if nombre == "Galería":
		_aviso.text = Idiomas.t("Galería del club · al complejo: %d m · cinta rodante") % GaleriaClub.metros_hasta(_est, cuerpo.position - CityBuilder.ESTADIO_EN)
	_hud.text = "📍 %s · %s %d · %s\n🚶 %s" % [Idiomas.t(nombre), Idiomas.t("Planta"), _planta, str(cb.datos.get("club", {}).get("estadioNom", "Estadio")),
		Idiomas.t("W/S/A/D o mando · Mayús: correr · E: usar · Esc: volver al mapa")]
	## Cámara: dentro de una sala no atraviesa paredes ni techo.
	var cerrado := float(z.get("techo", 99.0)) < 50.0
	var atras := 3.2 if cerrado else 5.5
	var alto := 1.9 if cerrado else 2.6
	var deseo := cuerpo.position - adelante * atras + Vector3(0, alto, 0)
	if cerrado:
		var r: Rect2 = z["r"]
		var o := CityBuilder.ESTADIO_EN
		deseo.x = clampf(deseo.x, o.x + r.position.x + 0.15, o.x + r.end.x - 0.15)
		## Solo el túnel deja que la cámara asome por sus extremos (la boca y la
		## puerta del vestuario); en una sala cerrada se queda dentro.
		var holgura := 1.0 if nombre == "Túnel" else -0.15
		deseo.z = clampf(deseo.z, o.z + r.position.y - holgura, o.z + r.end.y + holgura)
		deseo.y = minf(deseo.y, RecorridoClub.y_de(_planta) + float(z["techo"]) - 0.25)
		if nombre == "Escalera de la galería":
			## Mirando hacia abajo desde la escalera: la cámara va sobre los
			## peldaños, dentro del pozo, y no se sale por arriba.
			deseo.z = minf(deseo.z, o.z + float(GaleriaClub.trazado(_est)["z_esc"]) + 4.0)
			deseo.y = RecorridoClub.y_de(_planta) + GaleriaClub.alto_rampa(_est, deseo.z - o.z) + 1.7
	camara.position = camara.position.lerp(deseo, clampf(delta * 6.0, 0.0, 1.0)) if delta < 1.0 else deseo
	camara.look_at(cuerpo.position + Vector3(0, 1.4, 0) + adelante * 3.0, Vector3.UP)

## Desde la caseta de la calle: escalera abajo, al pie de la galería.
func _bajar_a_la_galeria() -> void:
	_fundido()
	estado = "estadio"
	_rotulos_antes = cb._rotulos.visible if cb._rotulos != null else true
	cb.mostrar_rotulos(false)
	_planta = GaleriaClub.PLANTA
	cuerpo.position = CityBuilder.ESTADIO_EN + GaleriaClub.pie_de_escalera(_est)
	rumbo = PI
	_zona_est = "?"
	_aviso.text = ""
	_bajo_tierra(true)
	_mover_en_estadio(1.0)

func _usar() -> void:
	if estado == "interior":
		## E junto a alguien que trabaja ahí: charlar (13-10-2026); si no, salir.
		if not _int_cerca.is_empty():
			_hablar_con_vecino(_int_cerca)
			return
		_salir_del_edificio()   ## E dentro de un edificio: salir a la calle
		return
	if estado == "estadio":
		if is_instance_valid(_menu_asc):
			return
		var loc := cuerpo.position - CityBuilder.ESTADIO_EN
		if _sentado:
			_sentado = false
			cuerpo.visible = true
			RecorridoClub.devolver_hinchas(_hinchas_quitados)
			_hinchas_quitados = []
			cuerpo.position = _de_pie
			_aviso.text = ""
			_zona_est = "?"
			return
		if RecorridoClub.junto_a_la_grada(loc, _planta):
			var b := RecorridoClub.butaca(cb.datos.get("perfil_estadio", {}), signf(loc.x), loc.z)
			_de_pie = cuerpo.position
			cuerpo.position = CityBuilder.ESTADIO_EN + (b["pos"] as Vector3)
			rumbo = float(b["rumbo"])
			cuerpo.rotation.y = rumbo
			_mirada = 0.0
			_sentado = true
			cuerpo.visible = false
			_hinchas_quitados = RecorridoClub.despejar_hinchas(cb, cuerpo.global_position + Vector3(0, 0.5, 0))
			_aviso.text = Idiomas.t("En la grada. A/D: mirar alrededor · E: levantarse")
			return
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		var g: Dictionary = pe.cercano(cuerpo.position - CityBuilder.ESTADIO_EN, _planta) if pe != null else {}
		if not g.is_empty():
			_menu_asc = RecorridoClub.dialogo(_capa, pe, g, cuerpo.position - CityBuilder.ESTADIO_EN)
			return
		if _zona_est == "Acceso":
			_salir_del_estadio()
		elif _zona_est == "Ascensor" and not is_instance_valid(_menu_asc):
			_menu_asc = RecorridoClub.menu_ascensor(_capa, _planta, _ir_a_planta)
		elif RecorridoClub.sala_decorable(_zona_est):
			_menu_asc = RecorridoClub.panel_decorar(_capa, get_tree(), _zona_est)
		return
	if estado == "anden":
		_usar_en_anden()
		return
	if estado == "tren":
		if metro.estacion_del_tren(_linea, _tren_k) >= 0:
			_bajar_del_tren()
		else:
			_bajar_en_proxima = not _bajar_en_proxima
		return
	if _cerca.is_empty():
		return
	if _cerca["tipo"] == "lugar" and modo == "pie" and (String(_cerca["k"]).begins_with("edificio_") \
			or (InteriorInstalacion.tiene(String(_cerca["k"])) and not Instalaciones.CATALOGO.has(String(_cerca["k"])) \
				and MinijuegosCiudad.juego_de(String(_cerca["k"])) == "")):
		_entrar_en_edificio(String(_cerca["k"]))
		return
	if _cerca["tipo"] == "metro":
		_entrar_al_anden(_cerca["acc"])
		return
	if _cerca["tipo"] == "puerta_estadio":
		_entrar_al_estadio()
		return
	if _cerca["tipo"] == "portero":
		if is_instance_valid(_menu_asc):
			return
		var pe := get_tree().get_first_node_in_group("personal_club") as PersonalEstadio
		_menu_asc = RecorridoClub.dialogo_portero(_capa, pe, _cerca["g"], cuerpo.position - CityBuilder.ESTADIO_EN, _cruzar_puerta)
		_menu_asc.set_meta("portero", _cerca["g"])
		return
	if _cerca["tipo"] == "galeria":
		_bajar_a_la_galeria()
		return
	if _cerca["tipo"] == "peaton":
		_hablar_con_vecino(_cerca["v"])
	else:
		interactuar.emit(String(_cerca["k"]))

func _tactil(capa: CanvasLayer) -> void:
	var tam := 74.0
	var base := Control.new()
	base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	base.offset_left = 24
	base.offset_top = -tam * 3.0 - 24
	## Solo en pantallas táctiles (en PC ocupaba el rincón del GPS).
	base.visible = es_tactil()
	capa.add_child(base)
	for d: Array in [["▲", Vector2(1, 0), Vector2(0, 1)], ["▼", Vector2(1, 2), Vector2(0, -1)],
			["◀", Vector2(0, 1), Vector2(-1, 0)], ["▶", Vector2(2, 1), Vector2(1, 0)]]:
		var b := Button.new()
		b.text = String(d[0])
		b.position = (d[1] as Vector2) * tam
		b.size = Vector2(tam - 6, tam - 6)
		b.add_theme_font_size_override("font_size", 28)
		b.modulate = Color(1, 1, 1, 0.7)
		var v: Vector2 = d[2]
		b.button_down.connect(func() -> void: _tactil_vec += v)
		b.button_up.connect(func() -> void: _tactil_vec -= v)
		base.add_child(b)
	var der := HBoxContainer.new()
	der.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	der.offset_left = -260
	der.offset_top = -100
	der.offset_right = -24
	der.offset_bottom = -24
	der.add_theme_constant_override("separation", 12)
	capa.add_child(der)
	var be := Button.new()
	be.text = "E"
	be.custom_minimum_size = Vector2(tam, tam)
	be.add_theme_font_size_override("font_size", 28)
	be.modulate = Color(1, 1, 1, 0.75)
	be.pressed.connect(_usar)
	der.add_child(be)
	_boton_e = be
	var bs := Button.new()
	bs.text = Idiomas.t("Salir")
	bs.custom_minimum_size = Vector2(tam * 1.6, tam)
	bs.modulate = Color(1, 1, 1, 0.75)
	bs.pressed.connect(func() -> void: salir.emit())
	bs.visible = es_tactil()
	der.add_child(bs)

func _aplicar_ajustes() -> void:
	_ayudas = bool(AjustesCiudad.valor("ayudas", false))
	_con_movil = bool(AjustesCiudad.valor("movil", true))
	_hud.visible = _ayudas
	_aviso.visible = _ayudas

func _montar_hud() -> void:
	var capa := CanvasLayer.new()
	_capa = capa
	add_child(capa)
	_hud = Label.new()
	_hud.position = Vector2(18, 14)
	_hud.add_theme_font_size_override("font_size", 16)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	capa.add_child(_hud)
	_aviso = Label.new()
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -90
	_aviso.offset_left = -300
	_aviso.offset_right = 300
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_font_size_override("font_size", 20)
	_aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_aviso.add_theme_color_override("font_outline_color", Color.BLACK)
	_aviso.add_theme_constant_override("outline_size", 8)
	capa.add_child(_aviso)
	_tactil(capa)
	## Sin textos fijos en pantalla (13-10-2026): los controles van en ⚙ y en el
	## tutorial de la ciudad; la velocidad, en el móvil que sacas al correr.
	_movil = MovilMano.new()
	capa.add_child(_movil)
	_minimapa = MinimapaCiudad.new()
	capa.add_child(_minimapa)
	if DisplayServer.is_touchscreen_available():
		_minimapa.arriba()
	var engranaje := CuadroDialogo.respuesta(Button.new())
	engranaje.text = "⚙"
	engranaje.add_theme_font_size_override("font_size", 22)
	engranaje.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	engranaje.offset_left = -70
	engranaje.offset_top = 16
	engranaje.offset_right = -18
	engranaje.offset_bottom = 62
	engranaje.pressed.connect(func() -> void:
		if capa.get_node_or_null("AjustesCiudad") == null:
			var a := AjustesCiudad.crear(_aplicar_ajustes)
			a.name = "AjustesCiudad"
			capa.add_child(a))
	capa.add_child(engranaje)
	_aplicar_ajustes()
	if not bool(AjustesCiudad.valor("tutorial_visto", false)):
		capa.add_child.call_deferred(AjustesCiudad.TutorialCiudad.new())

## A pie o en coche, los rótulos del mapa (pensados para la vista aérea) se
## veían a kilómetros y a través de los edificios: aquí solo los cercanos y
## tapados por lo que haya delante (etapa 1, 8-10-2026).
func _rotulos_de_paseo(si: bool) -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("rotulo_mapa"):
		var l := n as Label3D
		if l == null:
			continue
		l.visibility_range_end = (60.0 if modo == "pie" else 140.0) if si else 0.0
		l.no_depth_test = not si

func iniciar(builder: CityBuilder, modo_: String, desde: Vector3, club: String, estado_animo: String) -> void:
	cb = builder
	modo = modo_
	club_nombre = club
	animo = estado_animo
	trafico = cb.get_node_or_null("Trafico") as TraficoCiudad
	metro = cb.expansion.metro if cb.expansion != null else null
	obstaculos = construir_obstaculos(cb)
	_indexar_obstaculos()
	_indexar_circulos()
	var perfil: Dictionary = cb.datos.get("perfil_estadio", {})
	if not perfil.is_empty():
		var aforo := int(perfil.get("aforo", 20000))
		_est = TunelVestuario.datos(perfil, StadiumBuilder.niveles_de(perfil, aforo))
		## La galería subterránea al complejo (fase 6) solo existe aquí.
		_est["zonas"] = GaleriaClub.zonas(_est) + (_est["zonas"] as Array)
	position = Vector3.ZERO
	cuerpo = _crear_cuerpo()
	if trafico != null:
		trafico.jugador = cuerpo
	add_child(cuerpo)
	cuerpo.position = buscar_libre(desde)
	camara = Camera3D.new()
	camara.fov = 65.0
	camara.far = 5000.0
	add_child(camara)
	camara.make_current()
	_luz_cam = OmniLight3D.new()
	_luz_cam.omni_range = 12.0
	_luz_cam.light_energy = 0.45
	_luz_cam.visible = false
	camara.add_child(_luz_cam)
	_burbuja = Label3D.new()
	_burbuja.font_size = 40
	_burbuja.pixel_size = 0.012
	_burbuja.outline_size = 8
	_burbuja.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_burbuja.visible = false
	add_child(_burbuja)
	_montar_hud()
	_colocar_camara(1.0)
	_rotulos_de_paseo(true)
func _golpe_coche(v: float, contra_fijo: bool) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	if v < 2.5 or ahora - _t_golpe < 0.5:
		return
	_t_golpe = ahora
	Sonido.toca("choque_coche")
	_sacudida_golpe = clampf(v / 18.0, 0.15, 1.0)
	Mando.vibrar(clampf(v / 20.0, 0.25, 1.0), 0.35)
	if not contra_fijo and v * 3.6 > 25.0:
		multas += 1
		Sonido.toca("claxon", Sonido.Bus.AMBIENTE)
		if _movil != null:
			_movil.notificar(Idiomas.t("🚓 Multa por conducción temeraria (%d)") % multas)

## Un trozo de movimiento con sus choques. Devuelve false si chocó de frente.
func _mover_un_trozo(paso: Vector3, r: float) -> bool:
	var pos := cuerpo.position
	## Si ya estás dentro de algo FIJO (al salir del metro, por ejemplo), se te
	## deja andar para salir. Si lo que tienes encima es un MÓVIL (un coche que
	## se te mete), se ignoran los móviles pero NO las paredes: antes, con un
	## coche encima, se podía entrar caminando en los edificios (17-10).
	var libre_fijo := func(q: Vector3) -> bool: return libre_obst(q, r) and not _choca_circulos(q, r)
	var dentro_fijo: bool = not libre_fijo.call(pos)
	var solo_movil: bool = not dentro_fijo and _choca_moviles(pos, r)
	var vale := func(q: Vector3) -> bool:
		if dentro_fijo:
			return true
		if solo_movil:
			return libre_fijo.call(q)
		return libre_total(q, r)
	if vale.call(pos + paso):
		cuerpo.position = Vector3(pos.x + paso.x, altura_suelo(pos.x + paso.x, pos.z + paso.z), pos.z + paso.z)
		return true
	if vale.call(pos + Vector3(paso.x, 0, 0)):
		## Choque en diagonal: se desliza por la pared en vez de pararse en seco.
		cuerpo.position = Vector3(pos.x + paso.x, altura_suelo(pos.x + paso.x, pos.z), pos.z)
		vel *= 0.92
		return true
	if vale.call(pos + Vector3(0, 0, paso.z)):
		cuerpo.position = Vector3(pos.x, altura_suelo(pos.x, pos.z + paso.z), pos.z + paso.z)
		vel *= 0.92
		return true
	if modo == "coche":
		_golpe_coche(absf(vel), not libre_fijo.call(pos + paso))
	vel *= -0.25 if modo == "coche" else 0.0
	return false

## El rótulo de comercio cuya fachada está junto a `p`, o vacío.
func _rotulo_en(p: Vector3) -> Dictionary:
	if cb == null or cb.expansion == null:
		return {}
	var mejor: Dictionary = {}
	var md := INF
	for r: Dictionary in cb.expansion.rotulos:
		var q: Vector3 = r["pos"]
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		if d < float(r["ancho"]) * 0.5 + 2.5 and d < md:
			md = d
			mejor = r
	return mejor
