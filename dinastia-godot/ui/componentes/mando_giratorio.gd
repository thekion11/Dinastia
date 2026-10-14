class_name MandoGiratorio
extends Control
## EL MANDO EN 3D QUE SE GIRA COMO UN GLOBO (14-10-2026, pedido: «el modelo del
## control es un poco básico… la idea es poder hacer como con el globo
## terráqueo, poder girarlo»). Un mando de PlayStation o de Xbox modelado con
## mallas (cuerpo, empuñaduras, gatillos, bumpers, sticks, cruceta, botones),
## con los iconos de Kenney «Input Prompts» (CC0, `assets/iconos_botones/`) en
## cada botón y en las etiquetas. Se arrastra con el ratón para girarlo en
## cualquier sentido (con inercia, como un globo), la rueda acerca o aleja, el
## doble clic lo devuelve a la vista inicial y, si nadie lo toca, se mece solo.
## Las piezas de la combinación elegida laten en dorado y cada pieza visible
## lleva su etiqueta con línea; las que quedan de espaldas se apagan.

const CARPETA := "res://assets/iconos_botones/"

var dispositivo := "xbox"
var etiquetas := {}
var iluminadas: Array = []

var _vp: SubViewport
var _cam: Camera3D
var _pivote: Node3D
var _modelo: Node3D
var _luz: DirectionalLight3D
var _piezas := {}            ## nombre -> {"nodo", "mats": [...], "ancla": Vector3, "normal": Vector3}
var _iconos := {}            ## cache de texturas
var _fuente: Font
var _yaw := 0.0
var _pitch := 0.85
var _vel := Vector2.ZERO
var _arrastrando := false
var _ocioso := 0.0
var _zoom := 1.0
var _dispositivo_montado := ""

const YAW0 := 0.0
const PITCH0 := 0.85

# ------------------------------------------------------------------ montaje

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_fuente = ThemeDB.fallback_font
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cont)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cont.add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.74)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	_luz = DirectionalLight3D.new()
	_luz.rotation_degrees = Vector3(-50, 25, 0)
	_luz.light_energy = 1.25
	_vp.add_child(_luz)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-25, 205, 0)
	relleno.light_energy = 0.55
	_vp.add_child(relleno)
	_pivote = Node3D.new()
	_vp.add_child(_pivote)
	_cam = Camera3D.new()
	_cam.fov = 32.0
	_cam.position = Vector3(0, 0, 31.0)
	_vp.add_child(_cam)
	resized.connect(_ajustar_camara)
	_ajustar_camara()
	_construir(dispositivo)

## La cámara se aleja lo justo para que el mando entre entre las dos columnas
## de etiquetas (que ocupan ~100 px a cada lado) y no se corte al girarlo.
func _ajustar_camara() -> void:
	_vp.size = Vector2i(maxi(int(size.x), 16), maxi(int(size.y), 16))
	var libre := maxf(size.x - 190.0, 120.0)
	var ancho_modelo := 19.0
	var visible_ancho := ancho_modelo * size.x / libre
	var aspecto := maxf(size.x / maxf(size.y, 1.0), 0.5)
	var d := visible_ancho / (2.0 * tan(deg_to_rad(_cam.fov * 0.5)) * aspecto)
	## Y que no se salga por arriba ni por abajo (el mando girado mide hasta 15).
	var d_alto := 17.0 / (2.0 * tan(deg_to_rad(_cam.fov * 0.5)))
	_cam.position = Vector3(0, 0, maxf(d, d_alto))

func _icono(carpeta: String, nombre: String) -> Texture2D:
	var clave := carpeta + "/" + nombre
	if _iconos.has(clave):
		return _iconos[clave]
	var ruta := "%s%s/%s.png" % [CARPETA, carpeta, nombre]
	var t: Texture2D = load(ruta) if ResourceLoader.exists(ruta) else null
	_iconos[clave] = t
	return t

## Los iconos de cada pieza para un dispositivo (nombre de archivo sin .png).
static func nombre_icono(pieza: String, disp: String) -> String:
	if disp == "ps":
		match pieza:
			"A": return "playstation_button_cross"
			"B": return "playstation_button_circle"
			"X": return "playstation_button_square"
			"Y": return "playstation_button_triangle"
			"LB": return "playstation_trigger_l1"
			"RB": return "playstation_trigger_r1"
			"LT": return "playstation_trigger_l2"
			"RT": return "playstation_trigger_r2"
			"LS": return "playstation_stick_l_press"
			"RS": return "playstation_stick_r_press"
			"DPAD": return "playstation_dpad"
			"START": return "playstation5_button_options"
			"BACK": return "playstation5_button_create"
	match pieza:
		"A": return "xbox_button_a"
		"B": return "xbox_button_b"
		"X": return "xbox_button_x"
		"Y": return "xbox_button_y"
		"LB": return "xbox_lb"
		"RB": return "xbox_rb"
		"LT": return "xbox_lt"
		"RT": return "xbox_rt"
		"LS": return "xbox_stick_l_press"
		"RS": return "xbox_stick_r_press"
		"DPAD": return "xbox_dpad"
		"START": return "xbox_button_menu"
		"BACK": return "xbox_button_view"
	return ""

func _material(color: Color, rug := 0.45, met := 0.1) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rug
	m.metallic = met
	m.emission_enabled = true
	m.emission = Color(1.0, 0.8, 0.2)
	m.emission_energy_multiplier = 0.0
	return m

func _malla(padre: Node3D, mesh: Mesh, mat: Material, pos: Vector3, escala := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = escala
	mi.rotation_degrees = rot
	padre.add_child(mi)
	return mi

func _esfera() -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 48
	s.rings = 24
	return s

func _cilindro(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 40
	return c

## Altura de la superficie del cuerpo (un elipsoide) en (x, z).
const SEMI := Vector3(8.4, 2.0, 5.0)
static func _y_cuerpo(x: float, z: float) -> float:
	var f := 1.0 - (x / SEMI.x) * (x / SEMI.x) - (z / SEMI.z) * (z / SEMI.z)
	return SEMI.y * sqrt(maxf(f, 0.05))

func _construir(disp: String) -> void:
	_dispositivo_montado = disp
	for h in _pivote.get_children():
		h.queue_free()
	_piezas.clear()
	_modelo = Node3D.new()
	_pivote.add_child(_modelo)
	var ps := disp == "ps"
	var c_cuerpo := Color("e6e8ee") if ps else Color("2b2f37")
	var c_empu := Color("d3d6de") if ps else Color("23262d")
	var c_mando := Color("1b1d22") if ps else Color("15171b")
	var c_tapa := Color("20232a") if ps else Color("3c414c")
	var m_cuerpo := _material(c_cuerpo, 0.38, 0.05)
	var m_empu := _material(c_empu, 0.42, 0.05)
	var m_negro := _material(c_mando, 0.5, 0.2)
	## Cuerpo y empuñaduras.
	_malla(_modelo, _esfera(), m_cuerpo, Vector3.ZERO, SEMI)
	for lado in [-1.0, 1.0]:
		_malla(_modelo, _esfera(), m_empu, Vector3(lado * 6.3, -1.1, 2.6), Vector3(2.9, 2.5, 4.9), Vector3(0, -lado * 14.0, lado * 8.0))
	if ps:
		## Panel táctil y barra de luz.
		_malla(_modelo, _esfera(), m_negro, Vector3(0, 1.55, -1.7), Vector3(2.9, 0.42, 1.5))
		_malla(_modelo, _esfera(), _material(Color("5aa0ff"), 0.3), Vector3(0, 0.6, -4.7), Vector3(2.4, 0.18, 0.16), Vector3(-15, 0, 0))
	else:
		## El botón de guía de Xbox.
		_malla(_modelo, _cilindro(0.55, 0.2), _material(Color("e9ecf0"), 0.3, 0.3), Vector3(0, _y_cuerpo(0, -2.4) + 0.05, -2.4))
	## Gatillos y bumpers: delante de todo.
	var pos_t := _posiciones(disp)
	for lado: Array in [["L", -1.0], ["R", 1.0]]:
		var s: float = lado[1]
		var bump := _material(c_tapa, 0.35, 0.3)
		var trig := _material(c_mando, 0.5, 0.2)
		var mb := _malla(_modelo, _esfera(), bump, Vector3(s * 5.4, 0.55, -4.15), Vector3(2.3, 0.5, 0.85), Vector3(0, -s * 5.0, 0))
		_registrar(String(lado[0]) + "B", mb, [bump], Vector3(s * 5.4, 1.1, -4.15), Vector3.UP)
		var mt := _malla(_modelo, _esfera(), trig, Vector3(s * 5.4, -0.2, -5.1), Vector3(2.1, 0.95, 0.9), Vector3(-18, -s * 5.0, 0))
		_registrar(String(lado[0]) + "T", mt, [trig], Vector3(s * 5.4, 0.35, -5.5), Vector3(0, 0.5, -1).normalized())
		_icono_sobre(String(lado[0]) + "B", Vector3(s * 5.4, 1.12, -4.15), 1.7, disp)
		_icono_sobre(String(lado[0]) + "T", Vector3(s * 5.4, 0.62, -5.35), 1.5, disp, Vector3(-18, 0, 0))
	## Sticks.
	for k: String in ["LS", "RS"]:
		var p: Vector3 = pos_t[k]
		var y := _y_cuerpo(p.x, p.z)
		var base := _material(Color("0f1013"), 0.6, 0.1)
		var tapa := _material(Color("2a2d34") if not ps else Color("3a3e47"), 0.5, 0.2)
		var raiz := Node3D.new()
		raiz.position = Vector3(p.x, y, p.z)
		_modelo.add_child(raiz)
		_malla(raiz, _cilindro(1.05, 0.34), base, Vector3(0, 0.06, 0))
		_malla(raiz, _cilindro(0.42, 0.7), tapa, Vector3(0, 0.45, 0))
		var cabeza := _malla(raiz, _cilindro(0.98, 0.42), tapa, Vector3(0, 0.95, 0))
		var anillo := TorusMesh.new()
		anillo.inner_radius = 0.82
		anillo.outer_radius = 0.98
		var ma := _malla(raiz, anillo, base, Vector3(0, 1.17, 0), Vector3(1, 0.5, 1))
		_registrar(k, raiz, [tapa, base], Vector3(p.x, y + 1.7, p.z), Vector3.UP)
		_icono_sobre(k, Vector3(p.x, y + 1.19, p.z), 1.35, disp)
		cabeza.set_meta("sin_uso", true)
		ma.set_meta("sin_uso", true)
	## Cruceta.
	var pd: Vector3 = pos_t["DPAD"]
	var yd := _y_cuerpo(pd.x, pd.z)
	var m_dp := _material(Color("14161a"), 0.5, 0.15)
	var dp := Node3D.new()
	dp.position = Vector3(pd.x, yd, pd.z)
	_modelo.add_child(dp)
	_malla(dp, BoxMesh.new(), m_dp, Vector3(0, 0.15, 0), Vector3(2.6, 0.45, 0.85))
	_malla(dp, BoxMesh.new(), m_dp, Vector3(0, 0.15, 0), Vector3(0.85, 0.45, 2.6))
	_registrar("DPAD", dp, [m_dp], Vector3(pd.x, yd + 1.0, pd.z), Vector3.UP)
	_icono_sobre("DPAD", Vector3(pd.x, yd + 0.4, pd.z), 2.5, disp)
	## Los cuatro botones.
	for k: String in ["A", "B", "X", "Y"]:
		var p2: Vector3 = pos_t[k]
		var y2 := _y_cuerpo(p2.x, p2.z)
		var mb2 := _material(Color("16181d"), 0.4, 0.2)
		var bt := _malla(_modelo, _cilindro(0.72, 0.5), mb2, Vector3(p2.x, y2 + 0.05, p2.z))
		_registrar(k, bt, [mb2], Vector3(p2.x, y2 + 0.8, p2.z), Vector3.UP)
		_icono_sobre(k, Vector3(p2.x, y2 + 0.32, p2.z), 1.5, disp)
	## Menú y Vista (o Options y Create).
	for k: String in ["START", "BACK"]:
		var p3: Vector3 = pos_t[k]
		var y3 := _y_cuerpo(p3.x, p3.z)
		var m3 := _material(Color("4a4f5a") if not ps else Color("b9bdc8"), 0.4, 0.2)
		var b3 := _malla(_modelo, _cilindro(0.34, 0.2), m3, Vector3(p3.x, y3 + 0.02, p3.z))
		_registrar(k, b3, [m3], Vector3(p3.x, y3 + 0.7, p3.z), Vector3.UP)
		_icono_sobre(k, Vector3(p3.x, y3 + 0.14, p3.z), 0.85, disp)
	_aplicar_rotacion()

## Dónde va cada pieza (x, z sobre el cuerpo) según el mando.
func _posiciones(disp: String) -> Dictionary:
	if disp == "ps":
		return {"DPAD": Vector3(-4.7, 0, -1.0), "Y": Vector3(4.7, 0, -2.4), "B": Vector3(6.1, 0, -0.9), "A": Vector3(4.7, 0, 0.6),
			"X": Vector3(3.3, 0, -0.9), "LS": Vector3(-2.3, 0, 1.9), "RS": Vector3(2.3, 0, 1.9),
			"BACK": Vector3(-1.6, 0, -2.6), "START": Vector3(1.6, 0, -2.6)}
	return {"LS": Vector3(-4.7, 0, -1.4), "DPAD": Vector3(-2.2, 0, 1.9), "RS": Vector3(2.2, 0, 1.9),
		"Y": Vector3(4.7, 0, -2.5), "B": Vector3(6.1, 0, -1.0), "A": Vector3(4.7, 0, 0.5), "X": Vector3(3.3, 0, -1.0),
		"BACK": Vector3(-1.4, 0, -1.5), "START": Vector3(1.4, 0, -1.5)}

## Guarda una pieza: sus materiales (para iluminarla) y dónde clavar la etiqueta.
func _registrar(nombre: String, nodo: Node3D, mats: Array, ancla: Vector3, normal: Vector3) -> void:
	_piezas[nombre] = {"nodo": nodo, "mats": mats, "ancla": ancla, "normal": normal}

## El icono de Kenney pegado sobre una pieza, mirando hacia arriba.
func _icono_sobre(pieza: String, pos: Vector3, tam: float, disp: String, rot := Vector3.ZERO) -> void:
	var carpeta := "playstation" if disp == "ps" else "xbox"
	var tex := _icono(carpeta, nombre_icono(pieza, disp))
	if tex == null:
		return
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.pixel_size = tam / 64.0
	sp.axis = Vector3.AXIS_Y
	sp.double_sided = false
	sp.shaded = false
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sp.position = pos
	sp.rotation_degrees = rot
	## Sin esto, el icono se "pega" al cuerpo en la mitad de atrás.
	sp.render_priority = 1
	_modelo.add_child(sp)

# ------------------------------------------------------------------ giro

func _aplicar_rotacion() -> void:
	if _pivote == null:
		return
	_pivote.basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))
	_pivote.scale = Vector3.ONE * _zoom

func _process(delta: float) -> void:
	if dispositivo == "teclado" or not is_visible_in_tree():
		return
	if dispositivo != _dispositivo_montado:
		_construir(dispositivo)
		_yaw = YAW0
		_pitch = PITCH0
	if not _arrastrando:
		_ocioso += delta
		## La inercia de un globo: sigue girando y se frena despacio.
		if _vel.length() > 0.0005:
			_yaw += _vel.x
			_pitch = clampf(_pitch + _vel.y, -1.45, 1.45)
			_vel *= pow(0.04, delta)
		elif _ocioso > 4.0:
			## Si nadie lo toca, se mece suave para que se note que es un objeto 3D.
			_yaw = lerp_angle(_yaw, YAW0 + sin(Time.get_ticks_msec() * 0.0006) * 0.5, delta * 0.8)
			_pitch = lerpf(_pitch, PITCH0 + sin(Time.get_ticks_msec() * 0.00045) * 0.1, delta * 0.8)
	_aplicar_rotacion()
	## Las piezas elegidas laten en dorado.
	var latido := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
	for k: String in _piezas:
		var on := iluminadas.has(k)
		for m: StandardMaterial3D in _piezas[k]["mats"]:
			m.emission_energy_multiplier = (0.35 + 0.75 * latido) if on else 0.0
	queue_redraw()

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

func _reiniciar() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void: _yaw = v, _yaw, YAW0 + roundf((_yaw - YAW0) / TAU) * TAU, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: _pitch = v, _pitch, PITCH0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: _zoom = v, _zoom, 1.0, 0.45)
	_vel = Vector2.ZERO

## Vista desde arriba, de frente, de atrás… para el botón «Ver por…».
func mirar(yaw: float, pitch: float) -> void:
	_vel = Vector2.ZERO
	_ocioso = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void: _yaw = v, _yaw, yaw + roundf((_yaw - yaw) / TAU) * TAU, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: _pitch = v, _pitch, pitch, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# ------------------------------------------------------------------ etiquetas

func _draw() -> void:
	if dispositivo == "teclado" or _cam == null or _pivote == null:
		return
	var disp := dispositivo
	## Dónde cae cada pieza en pantalla, y si da la cara a la cámara.
	var vistos: Array = []
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
	draw_string(_fuente, Vector2(8, size.y - 8), txt, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 11, Color(1, 1, 1, 0.5))

func _columna(lista: Array, izquierda: bool, disp: String) -> void:
	if lista.is_empty():
		return
	var alto := size.y - 50.0
	var paso := minf(46.0, alto / float(lista.size()))
	var y0 := (size.y - paso * float(lista.size() - 1)) * 0.5 - 8.0
	var x_borde := 4.0 if izquierda else size.x - 4.0
	var carpeta := "playstation" if disp == "ps" else "xbox"
	for i in lista.size():
		var v: Dictionary = lista[i]
		var k: String = v["k"]
		var punto: Vector2 = v["p"]
		var visible_cara := float(v["cara"]) > -0.1
		var activa := iluminadas.has(k)
		var a := 1.0 if visible_cara else 0.25
		var col := Color(1.0, 0.82, 0.25, a) if activa else Color(1, 1, 1, 0.45 * a + 0.1)
		var y := y0 + paso * float(i)
		var ancla := Vector2(x_borde + (78.0 if izquierda else -78.0), y)
		var codo := Vector2(lerpf(punto.x, ancla.x, 0.6), y)
		draw_line(punto, codo, col, 1.3, true)
		draw_line(codo, ancla, col, 1.3, true)
		draw_circle(punto, 3.0, col)
		## El icono de Kenney y lo que hace.
		var tex := _icono(carpeta, nombre_icono(k, disp))
		var que := _cortar(String(etiquetas[k]), 12, 100.0)
		var x_ico := x_borde if izquierda else size.x - 4.0 - 28.0
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(x_ico, y - 14.0), Vector2(28, 28)), false, Color(1, 1, 1, a))
		var w := _fuente.get_string_size(que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var x_txt := x_ico + 31.0 if izquierda else x_ico - 3.0 - w
		draw_string(_fuente, Vector2(x_txt, y + 4.0), que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if activa else Color(1, 1, 1, 0.82 * a))

func _cortar(txt: String, tam: int, ancho: float) -> String:
	if _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
		return txt
	var t := txt
	while t.length() > 3 and _fuente.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
		t = t.substr(0, t.length() - 1)
	return t + "…"
