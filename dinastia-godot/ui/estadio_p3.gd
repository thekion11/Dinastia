extends "res://ui/estadio_p2.gd"
## [Capa 3/6 de `estadio.gd`] _construir, _a_la_revision_var, _al_jugada_ambiente, _nodo_de, _banca_gesto, _banca_celebra … (+6)

func _construir(ocupacion: float, perfil_forzado: Dictionary = {}, colores_balon: Array = []) -> void:
	_ajustar_a_pantalla()
	get_viewport().size_changed.connect(_ajustar_a_pantalla)

	## El 3D va DIRECTO al viewport principal, no dentro de un SubViewport.
	##
	## El primer intento lo metía en un SubViewport para poder renderizar por
	## encima de la resolución de la ventana y sacar 4K de verdad. No funcionó: un
	## SubViewport dentro de un SubViewportContainer no tiene tamaño hasta que el
	## contenedor se coloca, y con 0×0 el motor intenta crear los búferes con
	## cinco niveles de mipmap sobre una textura de un píxel. Salían decenas de
	## errores de Vulkan ("Too many mipmaps requested…", "Image is not a valid
	## texture") que parecen un fallo de la tarjeta y no lo son, y la pantalla se
	## quedaba negra. Darle un tamaño a mano tampoco bastó.
	##
	## Así que se hace como en el visor que ya funcionaba: los nodos 3D cuelgan
	## del árbol y los pinta el viewport raíz, que dibuja el 3D primero y los
	## Control encima. Por eso aquí NO hay un ColorRect de fondo: taparía el
	## estadio entero. El 4K por SubViewport se puede recuperar más adelante, pero
	## es un lujo y esto es lo que tiene que verse.
	_raiz3d = Node3D.new()
	add_child(_raiz3d)
	## Fuera de la ciudad no se sabe la hora: la gente del club está siempre.
	PersonalEstadio.hora = -1.0

	var perfil := perfil_forzado if not perfil_forzado.is_empty() else club.perfil_estadio()
	_perfil = perfil
	perfil_actual = perfil
	butaca_sancion = {}
	var aforo := int(perfil.get("aforo", 20000))

	## EL ORDEN ES EL DEL VISOR QUE YA FUNCIONABA, y las cuatro llamadas hacen
	## falta. La primera vez faltaban `aplicar_viewport` y `build_pitch`, y el
	## resultado fue un estadio con gradas, techo, focos y marcador… sobre un
	## agujero negro donde tenía que estar el campo. No hubo ni un error: `build`
	## levanta el recinto, pero el césped, las líneas y las porterías los pone
	## `build_pitch`, que es una función aparte.
	Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)
	Ambience.apply(_raiz3d, perfil, null, Calidad.elegida)
	## El clima también se VE, no solo se oye (plan maestro B11).
	var gp := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	## B6.5: con el techo retráctil cerrado no llueve dentro.
	if String(perfil.get("techo", "")) != "retractil":
		Precipitacion.montar(_raiz3d, String(perfil.get("clima", "noche")), float(gp["dx"]), float(gp["dz"]), Calidad.elegida)
	## Si la máquina no llega a 40 FPS, se bajan efectos por escalones durante
	## el partido (ver `RendimientoAdaptativo`). En un renderizador por software
	## -los servidores de pruebas- no tiene sentido: ahí nunca se llegaría y las
	## capturas saldrían con la calidad rebajada.
	var adaptador := RenderingServer.get_video_adapter_name().to_lower()
	if Calidad.adaptativa and not adaptador.contains("llvmpipe") and not adaptador.contains("swiftshader"):
		var ra := RendimientoAdaptativo.new()
		ra.raiz3d = _raiz3d
		add_child(ra)
		ra.escalon_aplicado.connect(func(_e: int, que: String) -> void:
			if _pie != null:
				_pie_base += "  ·  calidad ajustada: %s" % que
				_pie.text = _pie_base)
	StadiumBuilder.build_pitch(_raiz3d, perfil, club)
	## La semilla sale del id del club: el mismo recinto siempre.
	## M-021: los colores del rival para su sector de la grada (solo en partido).
	var perfil_b := perfil
	if visitante != null and visitante != club:
		perfil_b = perfil.duplicate()
		perfil_b["visita1"] = visitante.color1
		perfil_b["visita2"] = visitante.color2
	StadiumBuilder.build(_raiz3d, perfil_b, aforo, ocupacion, club._hash_id(), club)
	## Lo que rodea al estadio: plaza, avenida, aparcamientos y la ciudad al fondo.
	EntornoEstadio.montar(_raiz3d, perfil, StadiumBuilder.niveles_de(perfil, aforo))
	## La piel de la grada, la del país del club de casa (M-034).
	OlaGrada.piel_de_pais(_raiz3d, club.pais if club != null else "")
	if club != null:
		OlaGrada.colores_club(_raiz3d, Color(club.color1), Color(club.color2))
	## LA PANTALLA GIGANTE (22-9-2026, rehecha el 23-9). Ahora se monta SIEMPRE,
	## haya partido o no: sin partido enseña bienvenida + tabla + goleadores,
	## que es lo que hace la pantalla de un estadio de verdad un día entre
	## semana. Antes, sin partido, se quedaba en el degradado estático.
	_montar_pantalla()
	## EL BALÓN DE INVIERNO (29-9-2026): con nieve se juega con el naranja,
	## que se ve sobre el blanco, como en las ligas de verdad.
	if String(perfil.get("clima", "")) == "nieve":
		colores_balon = [Color("#ff7a1a"), Color("#1a1a1a"), "moderno"]
	_balon = StadiumBuilder.spawn_ball(_raiz3d, Vector3(0, 0.11, 0), colores_balon)
	## Si viene un partido sin empezar hay que prepararlo ANTES de sacar a nadie:
	## `preparar()` es quien arma los dos onces y quien mide su fuerza. Sin eso,
	## `once_local` está vacío y la fuerza cacheada es un diccionario vacío, así
	## que `simular_minuto()` revienta con "Invalid access to property 'ata'" en
	## cada uno de los noventa minutos.
	##
	## Y solo si NO ha empezado: llamarlo con el partido en marcha lo devolvería
	## al minuto cero y borraría el marcador.
	if partido != null and partido.once_local.is_empty():
		partido.preparar()
	if visitante != null:
		_sacar_los_22()

	## Las cámaras se calculan CONTRA el estadio recién construido, no se ponen
	## en posiciones fijas: un recinto de 8.000 butacas y uno de 90.000 necesitan
	## encuadres distintos, y con posiciones fijas la cámara acaba dentro de una
	## tribuna. Eso ya pasó en el visor aparte — pantalla en verde sólido y ni un
	## error en consola.
	var g := StadiumBuilder.geom_de_forma(String(perfil["forma"]))
	var alto := StadiumBuilder.altura_de(perfil, aforo)
	_rig = CameraRig.new()
	_raiz3d.add_child(_rig)
	_rig.build_for(g["dx"], g["dz"], alto)
	_rig.balon_ref = _balon
	## SANCIONADO (estadio 2.0): el partido, desde tu butaca de la grada.
	if partido != null and PersonajeDT.sancionado and not butaca_sancion.is_empty():
		var ojo: Vector3 = (butaca_sancion["pos"] as Vector3) + Vector3(0, 1.2, 0)
		_rig._add("Desde la grada (sancionado)", ojo + Vector3(0.6, 0.3, 0), Vector3(0, 0, ojo.z * 0.3), 62)
		_rig.switch_to(_rig.cameras.size() - 1)

	## Viñeta de transmisión (22-9-2026, comparando contra el look de cámara de
	## Open-Soccer): un oscurecido 2D encima del 3D, no un efecto de Environment
	## -Godot 4 no trae viñeta nativa ahí-. Va ANTES del radar/barra/pie en el
	## árbol para quedar DEBAJO de ellos (los Control últimos en añadirse se
	## dibujan encima): la viñeta oscurece justo las esquinas donde vive el HUD,
	## y si se dibujara arriba le restaría legibilidad al marcador y los botones.
	_vineta = ColorRect.new()
	_vineta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vineta.material = ShaderMaterial.new()
	_vineta.material.shader = load("res://visor/vineta.gdshader")
	_vineta.visible = _pref("vineta", true)
	add_child(_vineta)

	# Radar táctico 2D en esquina inferior derecha
	_radar = RadarPartido.new()
	_radar.anchor_left = 1.0; _radar.anchor_right = 1.0; _radar.anchor_top = 1.0; _radar.anchor_bottom = 1.0
	_radar.offset_left = -226; _radar.offset_right = -16; _radar.offset_top = -178; _radar.offset_bottom = -42
	_radar.visible = _pref("radar", true)
	add_child(_radar)

	## LA PANTALLA GIGANTE, EN LA ESQUINA (26-9-2026). La del estadio rota
	## marcador, tabla y goleadores, pero desde la cámara de transmisión es una
	## mota al fondo del estadio: nadie la leía. Aquí se ve la MISMA textura,
	## en vivo, arriba a la derecha. Se apaga desde el cajón.
	_mini_pantalla = TextureRect.new()
	_mini_pantalla.anchor_left = 1.0; _mini_pantalla.anchor_right = 1.0
	_mini_pantalla.offset_left = -348; _mini_pantalla.offset_right = -16
	_mini_pantalla.offset_top = 64; _mini_pantalla.offset_bottom = 64 + 177
	_mini_pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mini_pantalla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mini_pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_pantalla.visible = false
	add_child(_mini_pantalla)
	## La pantalla se monta antes que el HUD: aquí ya puede existir.
	if _pantalla != null:
		_mini_pantalla.texture = _pantalla.get_texture()
		_mini_pantalla.visible = _pref("pantalla_esquina", true)

	## AJUSTES EN UN CAJÓN (25-9-2026, plan maestro B1). Antes siete botones
	## vivían encima de la transmisión (cámara, zoom ±, modo, velocidad, nombres,
	## volver); el usuario pidió que no estuvieran todos a la vista. Ahora en
	## pantalla quedan el marcador, "Volver" y el ⚙, y el resto entra desde la
	## derecha al pulsarlo (`CajonAjustes`).
	_cajon = CajonAjustes.crear(self, "partido3d")
	var volver := Button.new()
	volver.text = Idiomas.t("Volver")
	volver.focus_mode = Control.FOCUS_NONE
	add_child(volver)
	volver.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	volver.offset_left = -150
	volver.offset_right = -66
	volver.offset_top = 14
	volver.offset_bottom = 54
	volver.pressed.connect(func() -> void: cerrado.emit())

	_cajon.seccion("Transmisión")
	_btn_camara = _cajon.boton("📷 Cámara: " + (_rig.current_name() if _rig != null else "TV"), _rotar_camara)
	_cajon.fila([["🔍 Acercar", func() -> void: if _rig: _rig.ajustar_zoom(-3.0)],
		["🔍 Alejar", func() -> void: if _rig: _rig.ajustar_zoom(3.0)]])
	_cajon.boton("📸 Modo foto", func() -> void: ModoFoto.abrir(self, club, "el estadio"))
	## RECORRER EL ESTADIO A PIE (7-10-2026): del vestuario, por el túnel, a la
	## cancha. Solo sin partido en marcha.
	if partido == null:
		_cajon.boton("🚶 Recorrer el estadio (vestuario y túnel)", recorrer)
	if partido != null:
		_cajon.seccion("Partido")
		_btn_modo = _cajon.boton("🎮 Controlar a mi equipo: NO", _alternar_modo_control)
		_cajon.boton("📋 Táctica y cambios (Esc)", _abrir_panel_dt)
		_cajon.boton("📊 Estadísticas del partido", abrir_estadisticas)
		_cajon.boton("🎮 Controles: teclas, mando y ayudas", abrir_controles)
		_cajon.interruptor("⚽ Motor real: el resultado se juega en el césped", _pref("motor_real", true), func(si: bool) -> void:
			_guardar_pref("motor_real", si))
		_cajon.fila([["⏩ Partido corto", func() -> void: _fijar_ritmo("rapido")],
			["⏯ Normal", func() -> void: _fijar_ritmo("normal")],
			["🐢 Largo (FC)", func() -> void: _fijar_ritmo("largo")]])
		_btn_dificultad = _cajon.boton(_texto_dificultad(), _ciclar_dificultad_cpu)
		_btn_velocidad = _cajon.boton("⏱", _ciclar_velocidad)
		## SIMULAR EL RESTO (28-9-2026, informe externo: "falta el botón de
		## simular el partido entero"). Existía en la pantalla de texto, que
		## queda oculta mientras se ve el 3D. Juega todos los minutos que
		## faltan -descanso incluido- y vuelve al resumen.
		_cajon.boton("⏭ Simular hasta el final", func() -> void:
			if _motor != null:
				_simular_resto_motor()
				return
			_descanso_hecho = true
			while not partido.terminado_ya:
				partido.simular_minuto()
			cerrado.emit())
	_cajon.seccion("En pantalla")
	_cajon.interruptor("🏷 Nombres de los jugadores", PlayerSpawner.mostrar_nombres, _mostrar_nombres)
	_cajon.interruptor("📺 Pantalla del estadio en la esquina", _pref("pantalla_esquina", true), func(si: bool) -> void:
		_guardar_pref("pantalla_esquina", si)
		_mini_pantalla.visible = si and _mini_pantalla.texture != null)
	_cajon.interruptor("🗺 Radar táctico", _radar.visible, func(si: bool) -> void:
		_radar.visible = si
		_guardar_pref("radar", si))
	_cajon.interruptor("📺 Rótulos de las jugadas", _pref("rotulos", true), func(si: bool) -> void:
		_guardar_pref("rotulos", si)
		if _rotulo_jugada != null and not si:
			_rotulo_jugada.modulate.a = 0.0)
	_cajon.interruptor("🎞 Viñeta de transmisión", _vineta.visible, func(si: bool) -> void:
		_vineta.visible = si
		_guardar_pref("vineta", si))
	_cajon.interruptor("ℹ Ficha del estadio abajo", _pref("pie", false), func(si: bool) -> void:
		_pie.visible = si
		_guardar_pref("pie", si))
	_cajon.interruptor("🎬 Presentación antes del partido", _pref("intro", true), func(si: bool) -> void:
		_guardar_pref("intro", si))
	_cajon.interruptor("🧒 Ceremonia completa (niños, mascota, alineaciones)", _pref("ceremonia", true), func(si: bool) -> void:
		_guardar_pref("ceremonia", si))
	_cajon.interruptor("🔁 Repetición de los goles", _pref("repeticiones", true), func(si: bool) -> void:
		_guardar_pref("repeticiones", si))
	_cajon.interruptor("⚡ Calidad automática", Calidad.adaptativa, func(si: bool) -> void:
		Calidad.adaptativa = si)
	_cajon.seccion("Sonido")
	_cajon.deslizador("Grada y ambiente", float(Sonido.volumen.get(Sonido.Bus.AMBIENTE, 0.5)), func(v: float) -> void:
		Sonido.volumen[Sonido.Bus.AMBIENTE] = v)
	_cajon.deslizador("Efectos (balón, silbato)", float(Sonido.volumen.get(Sonido.Bus.EFECTOS, 0.8)), func(v: float) -> void:
		Sonido.volumen[Sonido.Bus.EFECTOS] = v)
	_cajon.deslizador("Música", Musica.volumen, func(v: float) -> void:
		Musica.volumen = v
		Musica.aplicar_volumen())

	_pie = Label.new()
	_pie.add_theme_font_size_override("font_size", 13)
	_pie.add_theme_color_override("font_color", Color("e9eeea"))
	_pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_pie.offset_left = 18
	_pie.offset_bottom = -14
	_pie.offset_top = -34
	_pie.visible = _pref("pie", false)
	add_child(_pie)
	_actualizar_pie(perfil, aforo, ocupacion)

func _a_la_revision_var(minuto: int, motivo: String, anular := false, al_anular := Callable(), lineas := {}) -> void:
	if _sala_var != null or _raiz3d == null:
		return
	var vel_antes := _juego.vel_idx if _juego != null else 2
	if _juego != null:
		_juego.vel_idx = 0
	var foco := _balon.global_position if is_instance_valid(_balon) else Vector3.ZERO
	_sala_var = SalaVAR.abrir(self, _raiz3d.get_world_3d(), foco, minuto, motivo, anular, lineas)
	_sala_var.terminada.connect(func() -> void:
		_sala_var = null
		if anular and al_anular.is_valid():
			al_anular.call()
		if _juego != null:
			_juego.vel_idx = maxi(vel_antes, 1))

func _al_jugada_ambiente(nombre: String, es_local: bool) -> void:
	if _rotulo_jugada == null or not _pref("rotulos", true):
		return
	var equipo: Club = club if es_local else visitante
	(_rotulo_jugada.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(equipo.color1) if equipo != null else Color("c9a227")
	_lbl_jugada.text = "▸ %s  ·  %s" % [nombre.to_upper(), equipo.nombre if equipo != null else ""]
	if _tween_jugada != null and _tween_jugada.is_valid():
		_tween_jugada.kill()
	_tween_jugada = create_tween()
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 1.0, 0.25)
	_tween_jugada.tween_interval(3.2)
	_tween_jugada.tween_property(_rotulo_jugada, "modulate:a", 0.0, 0.6)

func _nodo_de(id: String) -> Node3D:
	for p: Dictionary in _en_campo:
		if String(p.get("id", "")) == id and is_instance_valid(p.get("node")):
			return p["node"]
	return null

func _banca_gesto(es_local: bool, clip: String, dura: float, otro := "") -> void:
	for f: Dictionary in _en_banca:
		if bool(f.get("es_local", false)) != es_local:
			continue
		## Los sentados NO se paran a festejar -la pose "celebrar" es de pie,
		## y sin además subir la raíz del modelo (bajada por `ALTO_ASIENTO_
		## OFFSET` para que la cadera caiga a la altura del banco) saldría
		## festejando hundido a medio metro bajo el piso. Arreglar eso es
		## trabajo aparte (parar, reposicionar, festejar, volver a sentar);
		## por ahora los sentados se quedan sentados, que ya es más real que
		## la banda vacía de antes de hoy.
		if bool(f.get("sentado", false)):
			continue
		var ap: AnimationPlayer = f.get("anim")
		var n: Node3D = f.get("node")
		if not is_instance_valid(ap) or not is_instance_valid(n):
			continue
		if ap.has_animation(clip):
			ap.play(clip)
		elif otro != "" and ap.has_animation(otro):
			ap.play(otro)
		else:
			continue
		## Vuelve a lo suyo: "parado", o las dominadas si estaba calentando.
		var reposo := String(f.get("reposo_anim", "parado"))
		get_tree().create_timer(dura).timeout.connect(func() -> void:
			if is_instance_valid(ap) and ap.has_animation(reposo):
				ap.play(reposo))

## El banquillo del equipo que anotó se levanta a festejar -misma animación
## "celebrar" que ya usa el autor del gol en la cancha (real, no a mano, ver
## `AnimQuaternius`)- y vuelve solo a "parado" a los 3s. No es un bucle: si
## hay otro gol antes de que termine el timer, simplemente se reinicia sobre
## la marcha, no hace falta encolar nada más elaborado para esto.
func _banca_celebra(es_local: bool) -> void:
	_banca_gesto(es_local, "celebrar", 3.0)

func _repetir_gol() -> void:
	if _repe == null or not _pref("repeticiones", true) or partido == null or partido.terminado_ya:
		return
	_lanzar_repeticion(6.0 if _motor != null else 9.0)

func _cine_gol(c: Club, autor: Jugador) -> void:
	if _raiz3d == null:
		return
	if is_instance_valid(_cine):
		_cine.cortar()
	## La repetición debe acabar en el gol, no en la celebración: se deja de
	## grabar hasta que termine.
	if _repe != null:
		_repe.congelar = true
		_repe.club_barrido = c
	if _rig != null:
		_rig.quitar_inserto()
	var autor_id := autor.id if autor != null else ""
	var g := StadiumBuilder.geom_de_forma(String(_perfil.get("forma", "oval")))
	var carta := func() -> Dictionary:
		var j := partido._por_id(autor_id) if partido != null and autor_id != "" else null
		if j == null:
			return {}
		return {"dorsal": j.dorsal, "nombre": j.nombre, "tiros": int(_tiros_de.get(j.id, 1)), "goles": int(_goles_de.get(j.id, 1))}
	_cine = CineGol.iniciar(self, _raiz3d, c, c == club, _nodo_de(autor_id), carta, float(g["dx"]))
	_cine.banquillo.connect(func() -> void: _banca_celebra(c == club))
	_cine.terminado.connect(func() -> void:
		_repetir_gol()
		if _repe != null:
			if _repe.reproduciendo:
				_repe.terminada.connect(func() -> void: _repe.congelar = false, CONNECT_ONE_SHOT)
			else:
				_repe.congelar = false)


# --- el partido con el motor real ---------------------------------------------

## Las jugadas con guion de `MatchPlayback` solo cuando NO juega el motor real
## (con el motor, `MatchPlayback` no mueve a nadie).
func _suceso(ev: Dictionary) -> void:
	if _motor != null or _juego == null:
		return
	_juego.suceso(ev)

## El "salto" del marcador: un golpe de escala corto -crece y vuelve, como el
## marcador de un estadio de verdad al subir el número-, no una animación larga
## que tape el juego. Se corta y se reinicia si llega un segundo gol encima.
func _animar_marcador_gol() -> void:
	if _caja_marcador == null:
		return
	if is_instance_valid(_tween_marcador):
		_tween_marcador.kill()
	_caja_marcador.scale = Vector2.ONE
	_tween_marcador = create_tween()
	_tween_marcador.tween_property(_caja_marcador, "scale", Vector2(1.22, 1.22), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_marcador.tween_property(_caja_marcador, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Un cambio en el campo: sale uno y entra otro DE VERDAD, no solo en la lista.
## Al que sale se le quita el modelo y al que entra se le crea en la ranura que
## deja libre, para que el once que se ve sea el once que juega.
## Las vallas LED cortan al mensaje con los colores del club (`VallasLed.evento`).
func _vallas_evento(palabras: Array, c: Club, seg: float = 6.0) -> void:
	var led := _raiz3d.find_child("VallasLed", true, false) as VallasLed if _raiz3d != null else null
	if led == null or c == null:
		return
	led.evento(palabras, Color(c.color1), Color(c.color2), seg)

## CÁMARA (18-9-2026): "no se ve la jugada planificada" -con razón: la cámara
## seguía al balón, no al jugador, y en el instante del gol el balón ya viaja
## solo hacia la red mientras la jugada real (la carrera del asistidor) pasa
## en otra parte del encuadre. Mientras haya un gol en curso, la cámara sigue
## al GOLEADOR -que es quien tiene la jugada con guion encima- por el tiempo
## que dura la jugada más el festejo, y después SUELTA sola para no quedarse
## pegada a él el resto del partido. No se activa en Modo Jugador: ahí el
## usuario ya eligió a quién sigue la cámara con sus propias manos.
func _seguir_jugada_gol(autor: Jugador) -> void:
	if _rig == null or autor == null or _juego == null:
		return
	if _control != null and _control.activo:
		return
	if not _juego.players_by_id.has(autor.id):
		return
	var nodo_autor: Node3D = _juego.players_by_id[autor.id].get("node")
	if not is_instance_valid(nodo_autor):
		return
	_rig.objetivo_seguimiento = nodo_autor
	## NO BASTABA CON `objetivo_seguimiento`: cada modo de cámara de
	## `CameraRig._process()` decide por su cuenta qué tan de cerca reacciona a
	## ese objetivo -varias de las 9 son planos casi fijos que apenas se
	## inmutan-. Si el gol pasa con una de esas activa, el objetivo cambia pero
	## en pantalla no se nota nada: es la causa real de "no se ve la jugada
	## planificada". "Tele Dinámica" es la única pensada para acompañar de
	## cerca el avance de una jugada -se guarda la cámara de antes y se
	## restaura sola al terminar, para no imponerle al usuario un cambio de
	## plano permanente.
	var idx_antes := _rig.current_index
	var idx_tele := _rig.camera_names.find("Tele Dinámica")
	if idx_tele != -1 and idx_tele != idx_antes:
		_rig.switch_to(idx_tele)
	get_tree().create_timer(5.5).timeout.connect(func() -> void:
		if not is_instance_valid(_rig):
			return
		if _rig.objetivo_seguimiento == nodo_autor:
			_rig.objetivo_seguimiento = null
		if _rig.current_index == idx_tele:
			_rig.switch_to(idx_antes))
