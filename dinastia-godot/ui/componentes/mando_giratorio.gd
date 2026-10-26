class_name MandoGiratorio
extends "res://ui/componentes/mando_giratorio_p1.gd"
## [Capa 2/2 de `mando_giratorio.gd`] _ready, _process, _reiniciar, _gui_input, _cortar, _columna … (+1)

## La capa de las etiquetas va ENCIMA del 3D: dibujadas en el propio control
## quedaban debajo del `SubViewportContainer` y el mando tapaba sus textos.
var _capa: Control
## La vista con la que se pintó la última vez (giro, inclinación y zoom).
var _vista_pintada := Vector3(INF, INF, INF)

# ------------------------------------------------------------------ montaje

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_fuente = ThemeDB.fallback_font
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Sombra suave de apoyo debajo del mando (una elipse difusa que no gira).
	_sombra = TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gr.colors = PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.18), Color(0, 0, 0, 0.0)])
	gt.gradient = gr
	gt.width = 128
	gt.height = 128
	_sombra.texture = gt
	_sombra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sombra.stretch_mode = TextureRect.STRETCH_SCALE
	_sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sombra)
	add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	## Se renderiza solo cuando algo cambia (`_process` lo pide fotograma a
	## fotograma mientras gira o late): quieto, el mando no gasta GPU.
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	cont.add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	## Un cielo de estudio (claro arriba, oscuro abajo) solo para los reflejos y
	## la luz ambiente: es lo que da brillo de plástico al cuerpo.
	var cielo := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.85, 0.9, 1.0)
	pm.sky_horizon_color = Color(0.55, 0.6, 0.68)
	pm.ground_horizon_color = Color(0.3, 0.32, 0.36)
	pm.ground_bottom_color = Color(0.08, 0.09, 0.1)
	pm.sun_angle_max = 25.0
	cielo.sky_material = pm
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	## Oclusión ambiental: las junturas, los botones y las empuñaduras se oscurecen
	## donde se tocan (solo en el renderizador completo; en móvil no hace nada).
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.4
	env.ssao_power = 1.6
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	_luz = DirectionalLight3D.new()
	_luz.rotation_degrees = Vector3(-50, 25, 0)
	_luz.light_energy = 1.25
	_luz.shadow_enabled = true
	_luz.shadow_bias = 0.03
	_luz.directional_shadow_max_distance = 60.0
	_vp.add_child(_luz)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-25, 205, 0)
	relleno.light_energy = 0.4
	## Luz de contorno fría desde atrás: separa la silueta del fondo.
	var contorno := DirectionalLight3D.new()
	contorno.rotation_degrees = Vector3(-35, -150, 0)
	contorno.light_color = Color(0.7, 0.85, 1.0)
	contorno.light_energy = 0.9
	_vp.add_child(contorno)
	_vp.add_child(relleno)
	_pivote = Node3D.new()
	_vp.add_child(_pivote)
	_cam = Camera3D.new()
	_cam.fov = 32.0
	_cam.position = Vector3(0, 0, 31.0)
	_vp.add_child(_cam)
	resized.connect(_ajustar_camara)
	resized.connect(func() -> void: _sucio = true)
	visibility_changed.connect(func() -> void: _sucio = true)
	_ajustar_camara()
	_capa = Control.new()
	_capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.draw.connect(_dibujar_etiquetas)
	add_child(_capa)
	## Atajos de vista: arriba (botones), atrás (gatillos y bumpers) y de lado.
	var fila := HBoxContainer.new()
	fila.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	fila.offset_top = -62
	fila.offset_bottom = -26
	fila.offset_left = 8
	fila.offset_right = -8
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 6)
	add_child(fila)
	for v: Array in [["⬆ Arriba: botones", YAW0, PITCH0], ["↻ Atrás: gatillos y bumpers", PI, 0.3]]:
		var b := Button.new()
		b.text = Idiomas.t(String(v[0]))
		b.add_theme_font_size_override("font_size", 12)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(mirar.bind(float(v[1]), float(v[2])))
		fila.add_child(b)
	_construir(dispositivo)

func _process(delta: float) -> void:
	if dispositivo == "teclado" or not is_visible_in_tree():
		return
	if dispositivo != _dispositivo_montado:
		_construir(dispositivo)
		_yaw = YAW0
		_pitch = PITCH0
		_sucio = true
	## Con «animaciones reducidas» ni se mece solo ni late: queda quieto.
	var quieto := Animar.reducidas()
	if not _arrastrando:
		_ocioso += delta
		## La inercia de un globo: sigue girando y se frena despacio.
		if _vel.length() > 0.0005:
			_yaw += _vel.x
			_pitch = clampf(_pitch + _vel.y, -1.45, 1.45)
			_vel *= pow(0.04, delta)
		elif _ocioso > 4.0 and not quieto:
			## Si nadie lo toca, se mece suave para que se note que es un objeto 3D.
			_yaw = lerp_angle(_yaw, YAW0 + sin(Time.get_ticks_msec() * 0.0006) * 0.5, delta * 0.8)
			_pitch = lerpf(_pitch, PITCH0 + sin(Time.get_ticks_msec() * 0.00045) * 0.1, delta * 0.8)
	var vista := Vector3(_yaw, _pitch, _zoom)
	var gira := not vista.is_equal_approx(_vista_pintada)
	var late := not iluminadas.is_empty() and not quieto
	if not (gira or late or _sucio):
		return
	_vista_pintada = vista
	_aplicar_rotacion()
	## Las piezas elegidas laten en dorado (fijas si las animaciones van reducidas).
	var latido := (0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)) if late else 1.0
	for k: String in _piezas:
		var on := iluminadas.has(k)
		for m: StandardMaterial3D in _piezas[k]["mats"]:
			m.emission_energy_multiplier = (0.15 + 0.35 * latido) if on else 0.0
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	## Las etiquetas no laten: solo se repintan si el mando se movió o cambió algo.
	if gira or _sucio:
		_capa.queue_redraw()
	_sucio = false

func _reiniciar() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void: _yaw = v, _yaw, YAW0 + roundf((_yaw - YAW0) / TAU) * TAU, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: _pitch = v, _pitch, PITCH0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: _zoom = v, _zoom, 1.0, 0.45)
	_vel = Vector2.ZERO

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var b := ev as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_LEFT:
			_arrastrando = b.pressed
			_ocioso = 0.0
			if b.pressed:
				_vel = Vector2.ZERO
				if b.double_click:
					_reiniciar()
			accept_event()
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom * 1.08, 0.7, 1.9)
			accept_event()
		elif b.pressed and b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom / 1.08, 0.7, 1.9)
			accept_event()
	elif ev is InputEventMouseMotion and _arrastrando:
		var d := (ev as InputEventMouseMotion).relative
		_yaw += d.x * 0.012
		_pitch = clampf(_pitch + d.y * 0.012, -1.45, 1.45)
		_vel = Vector2(d.x, d.y) * 0.012
		_ocioso = 0.0
		accept_event()
	elif ev is InputEventScreenDrag:
		var d2 := (ev as InputEventScreenDrag).relative
		_yaw += d2.x * 0.012
		_pitch = clampf(_pitch + d2.y * 0.012, -1.45, 1.45)
		_ocioso = 0.0

func _cortar(txt: String, tam: int, ancho: float) -> String:
	if _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
		return txt
	var t := txt
	while t.length() > 3 and _fuente.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
		t = t.substr(0, t.length() - 1)
	return t + "…"

func _columna(lista: Array, izquierda: bool, disp: String) -> void:
	if lista.is_empty():
		return
	var alto := size.y - 100.0
	var paso := minf(46.0, alto / float(lista.size()))
	var y0 := (size.y - 60.0 - paso * float(lista.size() - 1)) * 0.5 + 24.0
	var x_borde := 4.0 if izquierda else size.x - 4.0
	var carpeta := "playstation" if disp == "ps" else "xbox"
	for i in lista.size():
		var v: Dictionary = lista[i]
		var k: String = v["k"]
		var punto: Vector2 = v["p"]
		var activa := iluminadas.has(k)
		## Solo se ve la etiqueta de lo que da la cara a la cámara: arriba desde
		## arriba, los gatillos y bumpers desde el lado en que están.
		var a := smoothstep(0.42, 0.7, float(v["cara"]))
		if a < 0.03:
			continue
		var cp := ControlFC.color_pieza(k, disp)
		var col := Color(cp, a)
		var y := y0 + paso * float(i)
		## Primero el texto (para saber dónde termina) y luego la línea hasta él.
		var tex := _icono(carpeta, nombre_icono(k, disp))
		var que := _cortar(String(etiquetas[k]), 12, 104.0)
		var w := _fuente.get_string_size(que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var x_ico := x_borde if izquierda else size.x - 4.0 - 28.0
		var x_txt := x_ico + 31.0 if izquierda else x_ico - 3.0 - w
		var ancla := Vector2((x_txt + w + 5.0) if izquierda else (x_txt - 5.0), y)
		var codo := Vector2(lerpf(punto.x, ancla.x, 0.6), y)
		var gr := 2.6 if activa else 1.4
		_capa.draw_line(punto, codo, col, gr, true)
		_capa.draw_line(codo, ancla, col, gr, true)
		_capa.draw_circle(punto, 4.0 if activa else 3.0, col)
		## Una placa del color del botón detrás del icono.
		_capa.draw_rect(Rect2(Vector2(x_ico - 2.0, y - 16.0), Vector2(32, 32)), Color(cp, 0.28 * a), true)
		_capa.draw_rect(Rect2(Vector2(x_ico - 2.0, y - 16.0), Vector2(32, 32)), Color(cp, 0.9 * a), false, 1.5)
		if tex != null:
			_capa.draw_texture_rect(tex, Rect2(Vector2(x_ico, y - 14.0), Vector2(28, 28)), false, Color(1, 1, 1, a))
		## Una placa oscura detrás del texto: cuando el mando girado pasa por
		## debajo, la etiqueta se sigue leyendo.
		_capa.draw_rect(Rect2(Vector2(x_txt - 4.0, y - 10.0), Vector2(w + 8.0, 19.0)), Color(0.04, 0.06, 0.05, 0.62 * a), true)
		_capa.draw_string(_fuente, Vector2(x_txt, y + 4.0), que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if activa else Color(1, 1, 1, 0.85 * a))

# ------------------------------------------------------------------ etiquetas

func _dibujar_etiquetas() -> void:
	if dispositivo == "teclado" or _cam == null or _pivote == null:
		return
	var disp := dispositivo
	## Dónde cae cada pieza en pantalla, y si da la cara a la cámara.
	var vistos: Array = []
	var ocultas := 0
	for k: String in etiquetas:
		if not _piezas.has(k):
			continue
		var pz: Dictionary = _piezas[k]
		var mundo: Vector3 = _pivote.global_transform * (pz["ancla"] as Vector3)
		if _cam.is_position_behind(mundo):
			continue
		var n: Vector3 = (_pivote.global_basis * (pz["normal"] as Vector3)).normalized()
		var a_camara := (_cam.global_position - mundo).normalized()
		var cara := n.dot(a_camara)
		if smoothstep(0.42, 0.7, cara) < 0.03:
			ocultas += 1
			continue
		vistos.append({"k": k, "p": _cam.unproject_position(mundo), "cara": cara})
	var izq: Array = []
	var der: Array = []
	for v: Dictionary in vistos:
		((izq if (v["p"] as Vector2).x < size.x * 0.5 else der)).append(v)
	var por_y := func(a: Dictionary, b: Dictionary) -> bool: return (a["p"] as Vector2).y < (b["p"] as Vector2).y
	izq.sort_custom(por_y)
	der.sort_custom(por_y)
	_columna(izq, true, disp)
	_columna(der, false, disp)
	## La ayuda para el ratón.
	var txt := Idiomas.t("Arrastra para girarlo · rueda: zoom · doble clic: vista inicial")
	_capa.draw_string(_fuente, Vector2(8, size.y - 8), txt, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 11, Color(1, 1, 1, 0.5))
	if ocultas > 0:
		var aviso := Idiomas.t("Desde aquí no se ven %d botones: gira el mando o cambia de vista") % ocultas
		_capa.draw_string(_fuente, Vector2(8, 18), aviso, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 12, Color(1.0, 0.82, 0.25, 0.8))
