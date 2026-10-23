class_name VistaCiudad
extends "res://ui/ciudad_vista_p1.gd"
## (Parte 2 de 2 de `ciudad_vista.gd`.)

func _construir(obras: Instalaciones, ciudad: Ciudad, perfil_estadio: Dictionary) -> void:
	_ajustar_a_pantalla()
	get_viewport().size_changed.connect(_ajustar_a_pantalla)
	Calidad.aplicar_viewport(get_viewport(), Calidad.elegida)

	_raiz3d = Node3D.new()
	add_child(_raiz3d)
	_sol = Calidad.sol(Calidad.elegida, Calidad.TARDE)
	_raiz3d.add_child(_sol)
	var we := Calidad.entorno(Calidad.elegida, Calidad.TARDE)
	## AJUSTE PARA UN MAPA, NO PARA UN RECINTO. `Calidad` está calibrada para
	## escenas de ~200 m -un estadio, un complejo-, y aquí se ve un kilómetro
	## de lado: con su exposición (1,25 para compensar el sol bajo) y su niebla,
	## el mapa entero salía lavado, de un verde menta descolorido, y las
	## parcelas del fondo se fundían con el cielo. Menos exposición y menos
	## niebla devuelven el color sin tocar cómo se ve el partido, que usa el
	## mismo `Calidad` y no debe cambiar.
	var env := we.environment
	env.tonemap_exposure = 1.02
	## El ánimo del club también tiñe la escena: más viva en la euforia, más
	## gris en la crisis (fase 5).
	env.adjustment_saturation = _saturacion_animo()
	env.adjustment_contrast = 1.10
	if env.fog_enabled:
		env.fog_density = 0.00016
	if env.volumetric_fog_enabled:
		env.volumetric_fog_density = 0.0006
		env.volumetric_fog_length = 600.0
	## EL "SUELO" DEL CIELO, que en un mapa se ve y en un estadio no. `Calidad`
	## lo deja pardo cálido -correcto cuando la cámara está dentro de un recinto
	## y ese trozo de cielo casi no asoma-, pero aquí, con la vista alta sobre
	## un kilómetro de césped, salía una BANDA MARRÓN cortando la imagen justo
	## encima del terreno. Tiñéndolo del verde brumoso del propio césped, el
	## mapa se funde con el horizonte en vez de acabarse de golpe.
	## CIELO PROPIO, CON SHADER (12-9-2026). `ProceduralSkyMaterial` solo sabe
	## degradar cuatro colores: de noche el cielo quedaba vacío -ni una
	## estrella- y de día liso -ni una nube-, justo lo contrario de lo que
	## pide "se siente un poco vacío". `visor/cielo.gdshader` hace el mismo
	## degradado (para no perder el ajuste de arriba) y le suma nubes a la
	## deriva y estrellas que aparecen de verdad con la noche.
	var sky_shader := load("res://visor/cielo.gdshader") as Shader
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = sky_shader
	sky_mat.set_shader_parameter("ground_horizon_color", Color(0.62, 0.70, 0.62))
	sky_mat.set_shader_parameter("ground_bottom_color", Color(0.36, 0.47, 0.36))
	env.sky.sky_material = sky_mat
	_raiz3d.add_child(we)
	_env = env
	_cielo = sky_mat
	_aplicar_hora()

	_ciudad = CityBuilder.new()
	_raiz3d.add_child(_ciudad)
	_ciudad.build(_datos_de(club, obras, ciudad, perfil_estadio))
	## Etapa 3: la misma calidad adaptativa que el partido -si la máquina no
	## llega a 40 FPS se bajan efectos por escalones-. No en render por software.
	var adaptador := RenderingServer.get_video_adapter_name().to_lower()
	if Calidad.adaptativa and not adaptador.contains("llvmpipe") and not adaptador.contains("swiftshader"):
		var ra := RendimientoAdaptativo.new()
		ra.raiz3d = _raiz3d
		add_child(ra)

	_camara = Camera3D.new()
	_camara.fov = 55.0
	_raiz3d.add_child(_camara)
	_mover_camara()

	var barra := HBoxContainer.new()
	barra.add_theme_constant_override("separation", 8)
	barra.offset_left = 18
	barra.offset_top = 14
	add_child(barra)
	_boton(barra, "Detener giro", _alternar_giro)
	_boton(barra, "☀ Detener el día", alternar_ciclo)
	_boton(barra, "🏟️ Editar mi estadio", func() -> void: editar_estadio_pedido.emit())
	_boton(barra, "🏷 Rótulos", func() -> void:
		_rotulos_visibles = not _rotulos_visibles
		_ciudad.mostrar_rotulos(_rotulos_visibles))
	_boton(barra, "📷 Foto", func() -> void:
		## Sin rótulos flotantes en la foto; vuelven al salir.
		_ciudad.mostrar_rotulos(false)
		ModoFoto.abrir(self, club, "la ciudad").tree_exited.connect(func() -> void:
			_ciudad.mostrar_rotulos(_rotulos_visibles)))
	_boton(barra, "🚗 Conducir", func() -> void: explorar("coche"))
	_boton(barra, "🚶 Pasear", func() -> void: explorar("pie"))
	_boton(barra, "🚇 Metro", func() -> void:
		if _ciudad.expansion != null and _ciudad.expansion.metro != null:
			_ciudad.expansion.metro.alternar_rayos_x())
	_boton(barra, "⚽ Día de partido", func() -> void:
		dia_partido = not dia_partido
		_reconstruir())
	_boton(barra, "Volver", func() -> void: cerrado.emit())

	_reloj = Label.new()
	_reloj.add_theme_font_size_override("font_size", 15)
	_reloj.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_reloj.position = Vector2(18, 52)
	add_child(_reloj)

	var ayuda := Label.new()
	ayuda.text = "arrastra para girar · clic derecho o WASD para moverte · rueda para acercar · clic en un edificio o solar para ver su ficha"
	ayuda.add_theme_font_size_override("font_size", 13)
	ayuda.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	ayuda.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ayuda.offset_left = 18
	ayuda.offset_bottom = -14
	ayuda.offset_top = -34
	add_child(ayuda)

## `perfil_estadio`: el mismo diccionario que consume el visor de partido
## (`mundo.perfil_estadio_de(club)`). Con él, el estadio que se ve en el mapa
## es EL TUYO, con la forma, las bandejas, el techo y las butacas que hayas
## pagado -no una maqueta genérica-.
func abrir(c: Club, obras: Instalaciones, ciudad: Ciudad, perfil_estadio: Dictionary = {}) -> void:
	club = c
	_obras = obras
	_ciudad_datos = ciudad
	_perfil = perfil_estadio
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir(obras, ciudad, perfil_estadio)

## Mueve el punto mirado: `d.x` a la derecha de la cámara, `d.y` hacia atrás.
func _desplazar(d: Vector2) -> void:
	var derecha := Vector3(cos(_ang), 0, -sin(_ang))
	var atras := Vector3(sin(_ang), 0, cos(_ang))
	_objetivo_deseado += derecha * d.x + atras * d.y
	_objetivo_deseado.x = clampf(_objetivo_deseado.x, -1400.0, 1400.0)
	_objetivo_deseado.z = clampf(_objetivo_deseado.z, -1400.0, 1400.0)
	_girando = false

func _process(delta: float) -> void:
	if _explorador != null:
		if _ciclo_activo:
			_hora = fposmod(_hora + delta * (24.0 / CICLO_SEG), 24.0)
			_aplicar_hora()
		return
	if _girando:
		_ang += delta * 0.12
	## CÁMARA LIBRE (B7): WASD mueve el punto que se mira, en el plano del
	## suelo y según hacia dónde mira la cámara.
	var mov := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if mov != Vector2.ZERO:
		_desplazar(mov * delta * _dist * 0.9)
	_objetivo = _objetivo.lerp(_objetivo_deseado, clampf(delta * 4.0, 0.0, 1.0))
	if _ciclo_activo:
		_hora = fposmod(_hora + delta * (24.0 / CICLO_SEG), 24.0)
		_aplicar_hora()
	_mover_camara()

func punto_en(pos_click: Vector2) -> Dictionary:
	if _camara == null or _ciudad == null:
		return {}
	var mejor: Dictionary = {}
	var mejor_d := INF
	for p: Dictionary in _ciudad.puntos_clic:
		var pos3: Vector3 = p["pos"]
		if _camara.is_position_behind(pos3):
			continue
		var d := _camara.unproject_position(pos3).distance_to(pos_click)
		var radio := ESTADIO_CLIC_RADIO_PX if String(p["estado"]) == "estadio" else CLIC_RADIO_PX
		if d <= radio and d < mejor_d:
			mejor_d = d
			mejor = p
	return mejor

## El clic busca el punto tocable más cercano en pantalla (B7): el estadio
## abre el editor, como siempre; un edificio o un solar abre su ficha.
func _probar_clic_estadio(pos_click: Vector2) -> void:
	var p := punto_en(pos_click)
	if p.is_empty():
		return
	if String(p["estado"]) == "estadio":
		editar_estadio_pedido.emit()
		return
	abrir_ficha(String(p["k"]))

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and (ev.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)):
		_desplazar(Vector2(-ev.relative.x, -ev.relative.y) * _dist * 0.0022)
		return
	if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_ang -= ev.relative.x * 0.006
		_alto = clampf(_alto - ev.relative.y * 0.9, 35.0, 520.0)
		_girando = false
		if ev.position.distance_to(_mouse_down_pos) > CLIC_TOLERANCIA_PX:
			_mouse_down_valido = false
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_mouse_down_pos = ev.position
			_mouse_down_valido = true
		elif _mouse_down_valido and ev.position.distance_to(_mouse_down_pos) <= CLIC_TOLERANCIA_PX:
			_probar_clic_estadio(ev.position)
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = clampf(_dist - 60.0, 120.0, 2600.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = clampf(_dist + 60.0, 120.0, 2600.0)
