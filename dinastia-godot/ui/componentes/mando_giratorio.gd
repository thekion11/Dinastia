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

var _sombra: TextureRect
var _vp: SubViewport
var _cam: Camera3D
var _pivote: Node3D
var _modelo: Node3D
var _luz: DirectionalLight3D
var _piezas := {}            ## nombre -> {"nodo", "mats": [...], "ancla": Vector3, "normal": Vector3}
var _iconos := {}            ## cache de texturas
var _fuente: Font
var _yaw := 0.0
var _pitch := 1.28
var _vel := Vector2.ZERO
var _arrastrando := false
var _ocioso := 0.0
var _zoom := 1.0
var _dispositivo_montado := ""

const YAW0 := 0.0
const PITCH0 := 1.28

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
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
	_ajustar_camara()
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

## La cámara se aleja lo justo para que el mando entre entre las dos columnas
## de etiquetas (que ocupan ~100 px a cada lado) y no se corte al girarlo.
func _ajustar_camara() -> void:
	_vp.size = Vector2i(maxi(int(size.x), 16), maxi(int(size.y), 16))
	if _sombra != null:
		var ancho := minf(size.x * 0.82, 520.0)
		_sombra.size = Vector2(ancho, ancho * 0.36)
		_sombra.position = Vector2((size.x - ancho) * 0.5, size.y * 0.5 + ancho * 0.1)
	var libre := maxf(size.x - 170.0, 120.0)
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
	m.metallic_specular = 0.45
	m.clearcoat_enabled = true
	m.clearcoat = 0.12
	m.clearcoat_roughness = 0.5
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

## EL CUERPO: una malla suave que une tres elipsoides (el centro y las dos
## empuñaduras) con una norma-p, de modo que se funden sin costuras, y que cae
## hacia abajo y hacia delante en las empuñaduras como un mando de verdad.
## `[cx, cz, a, c, b, giro]` por elipsoide (semiejes a, c en x y z; b = alto).
const ELIPSOIDES := [
	[0.0, -0.3, 6.9, 4.3, 1.35, 0.0],
	[-5.6, 2.8, 2.35, 4.7, 1.65, 0.1],
	[5.6, 2.8, 2.35, 4.7, 1.65, -0.1],
]
const P_FUSION := 3.0

static func _semialtura(x: float, z: float) -> float:
	var suma := 0.0
	for e: Array in ELIPSOIDES:
		var dx := x - float(e[0])
		var dz := z - float(e[1])
		var g := float(e[5])
		var lx := dx * cos(g) - dz * sin(g)
		var lz := dx * sin(g) + dz * cos(g)
		var f := 1.0 - (lx / float(e[2])) * (lx / float(e[2])) - (lz / float(e[3])) * (lz / float(e[3]))
		if f > 0.0:
			## Cara casi plana con un borde redondeado (cuarto de círculo), no un
			## globo: g = 1 en la meseta y baja a 0 en el borde.
			var meseta := clampf(f / 0.42, 0.0, 1.0)
			suma += pow(float(e[4]) * sqrt(1.0 - (1.0 - meseta) * (1.0 - meseta)), P_FUSION)
	return pow(suma, 1.0 / P_FUSION)

## Cuánto se hunde el mando en las empuñaduras (y hacia delante).
static func _caida(x: float, z: float) -> float:
	return -0.03 * pow(maxf(absf(x) - 4.5, 0.0), 2.0) - 0.03 * pow(maxf(z - 1.5, 0.0), 2.0)

static func _y_cuerpo(x: float, z: float) -> float:
	return _caida(x, z) + _semialtura(x, z)

func _malla_cuerpo(mat: Material) -> MeshInstance3D:
	## La silueta se saca EXACTA por rayos desde el centro (bisección en el borde)
	## y la malla se reparte en anillos (más densos hacia el borde): así no hay
	## bordes dentados como con una cuadrícula.
	var n := 200
	var anillos := 56
	var centro := Vector2(0.0, 0.4)
	var radios: Array[float] = []
	for i in n:
		var ang := TAU * float(i) / float(n)
		var d := Vector2(cos(ang), sin(ang))
		var r := 0.0
		while r < 14.0 and _semialtura(centro.x + d.x * (r + 0.1), centro.y + d.y * (r + 0.1)) > 0.0:
			r += 0.1
		var lo := r
		var hi := r + 0.1
		for _k in 14:
			var mid := (lo + hi) * 0.5
			if _semialtura(centro.x + d.x * mid, centro.y + d.y * mid) > 0.0:
				lo = mid
			else:
				hi = mid
		radios.append(lo)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	## Vértices: arriba (anillos 0..anillos) y abajo (anillos 0..anillos-1); el
	## borde (anillo `anillos`) lo comparten.
	for capa in 2:
		var hasta := anillos if capa == 0 else anillos - 1
		for j in hasta + 1:
			var u := float(j) / float(anillos)
			var t := 1.0 - (1.0 - u) * (1.0 - u) * (1.0 - u)
			for i in n:
				var ang := TAU * float(i) / float(n)
				var rr := radios[i] * t
				var x := centro.x + cos(ang) * rr
				var z := centro.y + sin(ang) * rr
				var h := _semialtura(x, z) if j < anillos else 0.0
				var y := _caida(x, z) + (h if capa == 0 else -h * 0.85)
				## Color de vértice (se multiplica por el del material): más claro en
				## la meseta, más oscuro hacia los bordes y por debajo, goma oscura en
				## las empuñaduras y una junta negra entre las dos mitades de la carcasa.
				var tono := lerpf(0.74, 1.0, smoothstep(0.0, 1.2, h)) if capa == 0 else 0.6
				if absf(x) > 3.7 and z > 0.4:
					tono *= 0.8
				tono = lerpf(0.2, tono, smoothstep(0.1, 0.34, h))
				st.set_color(Color(tono, tono, tono))
				st.add_vertex(Vector3(x, y, z))
	var base_abajo := (anillos + 1) * n
	## Un vértice del anillo `j` de la capa: el borde es el mismo arriba y abajo.
	var vid := func(capa: int, j: int, i: int) -> int:
		if capa == 0 or j == anillos:
			return j * n + (i % n)
		return base_abajo + j * n + (i % n)
	for capa in 2:
		for j in anillos:
			for i in n:
				var a: int = vid.call(capa, j, i)
				var b: int = vid.call(capa, j, i + 1)
				var c: int = vid.call(capa, j + 1, i)
				var d: int = vid.call(capa, j + 1, i + 1)
				if capa == 0:
					for idx in [a, c, b, b, c, d]:
						st.add_index(idx)
				else:
					for idx in [a, b, c, b, d, c]:
						st.add_index(idx)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	## El ordenamiento de los triángulos depende del sentido del ángulo: si salió
	## del revés, se invierte el culling en vez de recalcular la malla.
	var m: StandardMaterial3D = mat
	var primero: Vector3 = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0]
	var cima: Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	if m != null and (cima[0] as Vector3).y < 0.0 and primero.y < 0.0:
		m.cull_mode = BaseMaterial3D.CULL_FRONT
	_modelo.add_child(mi)
	return mi

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
	var m_cuerpo := _material(c_cuerpo, 0.5, 0.0)
	m_cuerpo.vertex_color_use_as_albedo = true
	var m_empu := _material(c_empu, 0.6, 0.0)
	var m_negro := _material(c_mando, 0.5, 0.2)
	## Cuerpo y empuñaduras: una sola malla suave.
	_malla_cuerpo(m_cuerpo)
	if ps:
		## Panel táctil y barra de luz.
		_malla(_modelo, _esfera(), m_negro, Vector3(0, _y_cuerpo(0, -1.5) - 0.05, -1.5), Vector3(2.9, 0.32, 1.5))
		_malla(_modelo, _esfera(), _material(Color("5aa0ff"), 0.3), Vector3(0, 0.15, -4.75), Vector3(2.4, 0.16, 0.14), Vector3(-15, 0, 0))
	else:
		## El botón de guía de Xbox.
		_malla(_modelo, _cilindro(0.55, 0.2), _material(Color("e9ecf0"), 0.3, 0.3), Vector3(0, _y_cuerpo(0, -2.4) + 0.05, -2.4))
	## Gatillos y bumpers: en el borde de delante, asentados en el cuerpo.
	var pos_t := _posiciones(disp)
	for lado: Array in [["L", -1.0], ["R", 1.0]]:
		var s: float = lado[1]
		var nb: String = String(lado[0]) + "B"
		var nt: String = String(lado[0]) + "T"
		var bump := _material(c_tapa, 0.45, 0.1)
		var trig := _material(c_mando, 0.55, 0.1)
		var yb := _y_cuerpo(s * 5.0, -3.3) + 0.1
		var mb := _malla(_modelo, _esfera(), bump, Vector3(s * 5.0, yb, -3.95), Vector3(1.9, 0.3, 0.62), Vector3(-10, -s * 8.0, 0))
		_registrar(nb, mb, [bump], Vector3(s * 5.0, yb + 0.4, -3.95), Vector3(0, 0.3, -0.95).normalized())
		_tira(mb, Vector3(0, 0.55, -0.35), Vector3(1.5, 0.12, 0.1), ControlFC.color_pieza(nb, disp))
		var mt := _malla(_modelo, _esfera(), trig, Vector3(s * 5.0, yb - 0.3, -4.55), Vector3(1.7, 0.5, 0.6), Vector3(-26, -s * 8.0, 0))
		_registrar(nt, mt, [trig], Vector3(s * 5.0, yb - 0.05, -4.95), Vector3(0, -0.05, -1).normalized())
		_tira(mt, Vector3(0, 0.1, -0.9), Vector3(1.3, 0.22, 0.08), ControlFC.color_pieza(nt, disp))
		_icono_sobre(nb, Vector3(s * 5.0, yb + 0.31, -3.92), 1.2, disp, Vector3(-10, 0, 0))
		_icono_sobre(nt, Vector3(s * 5.0, yb - 0.1, -4.85), 1.1, disp, Vector3(-26, 0, 0))
	## Sticks: base hundida, vástago y capuchón, con un aro de su color.
	for k: String in ["LS", "RS"]:
		var p: Vector3 = pos_t[k]
		var y := _y_cuerpo(p.x, p.z)
		var base := _material(Color("0f1013"), 0.7, 0.0)
		var tapa := _material(Color("30333b") if not ps else Color("43474f"), 0.8, 0.0)
		var raiz := Node3D.new()
		raiz.position = Vector3(p.x, y, p.z)
		_modelo.add_child(raiz)
		_malla(raiz, _cilindro(1.0, 0.16), base, Vector3(0, -0.02, 0))
		_aro(raiz, Vector3(0, 0.07, 0), 1.0, ControlFC.color_pieza(k, disp))
		_malla(raiz, _cilindro(0.34, 0.5), tapa, Vector3(0, 0.25, 0))
		_malla(raiz, _cilindro(0.78, 0.3), tapa, Vector3(0, 0.55, 0))
		var rodete := TorusMesh.new()
		rodete.inner_radius = 0.62
		rodete.outer_radius = 0.78
		_malla(raiz, rodete, base, Vector3(0, 0.7, 0), Vector3(1, 0.45, 1))
		_registrar(k, raiz, [tapa, base], Vector3(p.x, y + 1.5, p.z), Vector3.UP)
		_icono_sobre(k, Vector3(p.x, y + 0.71, p.z), 1.15, disp)
	## Cruceta: una cruz baja sobre un disco de su color.
	var pd: Vector3 = pos_t["DPAD"]
	var yd := _y_cuerpo(pd.x, pd.z)
	var m_dp := _material(Color("14161a"), 0.6, 0.0)
	var dp := Node3D.new()
	dp.position = Vector3(pd.x, yd, pd.z)
	_modelo.add_child(dp)
	_aro(dp, Vector3(0, 0.04, 0), 1.45, ControlFC.color_pieza("DPAD", disp))
	_malla(dp, BoxMesh.new(), m_dp, Vector3(0, 0.12, 0), Vector3(2.1, 0.26, 0.7))
	_malla(dp, BoxMesh.new(), m_dp, Vector3(0, 0.12, 0), Vector3(0.7, 0.26, 2.1))
	_registrar("DPAD", dp, [m_dp], Vector3(pd.x, yd + 1.0, pd.z), Vector3.UP)
	## Los cuatro botones: discos bajos con el aro del color de su mando.
	for k: String in ["A", "B", "X", "Y"]:
		var p2: Vector3 = pos_t[k]
		var y2 := _y_cuerpo(p2.x, p2.z)
		var mb2 := _material(Color("1a1c21"), 0.5, 0.0)
		_hueco(Vector3(p2.x, y2 + 0.005, p2.z), 0.78)
		var bt := _malla(_modelo, _cilindro(0.56, 0.22), mb2, Vector3(p2.x, y2 + 0.02, p2.z))
		_aro(_modelo, Vector3(p2.x, y2 + 0.1, p2.z), 0.6, ControlFC.color_pieza(k, disp))
		_registrar(k, bt, [mb2], Vector3(p2.x, y2 + 0.8, p2.z), Vector3.UP)
		_icono_sobre(k, Vector3(p2.x, y2 + 0.14, p2.z), 1.05, disp)
	## Menú y Vista (o Options y Create).
	for k: String in ["START", "BACK"]:
		var p3: Vector3 = pos_t[k]
		var y3 := _y_cuerpo(p3.x, p3.z)
		var m3 := _material(Color("3a3e47") if not ps else Color("aeb2be"), 0.5, 0.0)
		_hueco(Vector3(p3.x, y3 + 0.005, p3.z), 0.46)
		var b3 := _malla(_modelo, _cilindro(0.3, 0.14), m3, Vector3(p3.x, y3 + 0.0, p3.z))
		_aro(_modelo, Vector3(p3.x, y3 + 0.07, p3.z), 0.3, ControlFC.color_pieza(k, disp))
		_registrar(k, b3, [m3], Vector3(p3.x, y3 + 0.7, p3.z), Vector3.UP)
		_icono_sobre(k, Vector3(p3.x, y3 + 0.1, p3.z), 0.62, disp)
	_aplicar_rotacion()

## El hueco oscuro donde se asienta un botón (como el borde de goma de un mando).
func _hueco(pos: Vector3, radio: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.03, 0.035)
	m.roughness = 0.9
	var mi := _malla(_modelo, _cilindro(radio, 0.04), m, pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Un aro plano de color (brilla sin sombra) alrededor de un botón.
func _aro(padre: Node3D, pos: Vector3, radio: float, color: Color) -> void:
	var t := TorusMesh.new()
	t.inner_radius = radio * 1.02
	t.outer_radius = radio * 1.2
	t.rings = 32
	t.ring_segments = 8
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	## El aro va plano y por encima del punto MÁS ALTO del cuerpo bajo él (la
	## superficie sube hacia las empuñaduras y se lo comía por un lado).
	var origen := padre.position if padre != _modelo else Vector3.ZERO
	var c := origen + pos
	var ymax := -9.0
	for k in 16:
		var a := TAU * float(k) / 16.0
		ymax = maxf(ymax, _y_cuerpo(c.x + cos(a) * radio * 1.2, c.z + sin(a) * radio * 1.2))
	var local_y := maxf(ymax + 0.06 - origen.y, pos.y)
	var mi := _malla(padre, t, m, Vector3(pos.x, local_y, pos.z), Vector3(1, 0.4, 1))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Una tira de color pegada a un bumper o un gatillo.
func _tira(padre: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	_malla(padre, BoxMesh.new(), m, pos, tam)

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
			m.emission_energy_multiplier = (0.15 + 0.35 * latido) if on else 0.0
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
	draw_string(_fuente, Vector2(8, size.y - 8), txt, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 11, Color(1, 1, 1, 0.5))
	if ocultas > 0:
		var aviso := Idiomas.t("Desde aquí no se ven %d botones: gira el mando o cambia de vista") % ocultas
		draw_string(_fuente, Vector2(8, 18), aviso, HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 12, Color(1.0, 0.82, 0.25, 0.8))

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
		draw_line(punto, codo, col, gr, true)
		draw_line(codo, ancla, col, gr, true)
		draw_circle(punto, 4.0 if activa else 3.0, col)
		## Una placa del color del botón detrás del icono.
		draw_rect(Rect2(Vector2(x_ico - 2.0, y - 16.0), Vector2(32, 32)), Color(cp, 0.28 * a), true)
		draw_rect(Rect2(Vector2(x_ico - 2.0, y - 16.0), Vector2(32, 32)), Color(cp, 0.9 * a), false, 1.5)
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2(x_ico, y - 14.0), Vector2(28, 28)), false, Color(1, 1, 1, a))
		draw_string(_fuente, Vector2(x_txt, y + 4.0), que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if activa else Color(1, 1, 1, 0.85 * a))

func _cortar(txt: String, tam: int, ancho: float) -> String:
	if _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
		return txt
	var t := txt
	while t.length() > 3 and _fuente.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
		t = t.substr(0, t.length() - 1)
	return t + "…"
