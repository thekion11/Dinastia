extends Control
## (Parte 1 de 2 de `mando_giratorio_p1.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `mando_giratorio_p1.gd`, conserva la clase.)

## [Capa 1/2 de `mando_giratorio.gd`] _ajustar_camara, mirar, _material, _semialtura, _caida, _malla_cuerpo … (+14)

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

## Cambiar cualquiera de las tres marca el dibujo como sucio: el 3D y las
## etiquetas se vuelven a pintar solo cuando algo cambia, no en cada fotograma.
var dispositivo := "xbox":
	set(v):
		if v != dispositivo:
			dispositivo = v
			_sucio = true
var etiquetas := {}:
	set(v):
		etiquetas = v
		_sucio = true
var iluminadas: Array = []:
	set(v):
		iluminadas = v
		_sucio = true
var _sucio := true

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

## La cámara se aleja lo justo para que el mando entre entre las dos columnas
## de etiquetas (que ocupan ~100 px a cada lado) y no se corte al girarlo.
func _ajustar_camara() -> void:
	## (El tamaño del visor lo pone su `SubViewportContainer` con `stretch`: ponerlo a mano no valía y escribía un aviso en cada cambio de tamaño.)
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

## Vista desde arriba, de frente, de atrás… para el botón «Ver por…».
func mirar(yaw: float, pitch: float) -> void:
	_vel = Vector2.ZERO
	_ocioso = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_method(func(v: float) -> void: _yaw = v, _yaw, yaw + roundf((_yaw - yaw) / TAU) * TAU, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: _pitch = v, _pitch, pitch, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

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

static func _y_cuerpo(x: float, z: float) -> float:
	return _caida(x, z) + _semialtura(x, z)

func _cilindro(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 40
	return c

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

## Una tira de color pegada a un bumper o un gatillo.
func _tira(padre: Node3D, pos: Vector3, tam: Vector3, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	_malla(padre, BoxMesh.new(), m, pos, tam)

func _icono(carpeta: String, nombre: String) -> Texture2D:
	var clave := carpeta + "/" + nombre
	if _iconos.has(clave):
		return _iconos[clave]
	var ruta := "%s%s/%s.png" % [CARPETA, carpeta, nombre]
	var t: Texture2D = load(ruta) if ResourceLoader.exists(ruta) else null
	_iconos[clave] = t
	return t

## Los iconos de cada pieza para un dispositivo (nombre de archivo sin .png).
const _ICONOS_PS := {
	"A": "playstation_button_cross",
	"B": "playstation_button_circle",
	"X": "playstation_button_square",
	"Y": "playstation_button_triangle",
	"LB": "playstation_trigger_l1",
	"RB": "playstation_trigger_r1",
	"LT": "playstation_trigger_l2",
	"RT": "playstation_trigger_r2",
	"LS": "playstation_stick_l_press",
	"RS": "playstation_stick_r_press",
	"DPAD": "playstation_dpad",
	"START": "playstation5_button_options",
	"BACK": "playstation5_button_create",
}

static func nombre_icono(pieza: String, disp: String) -> String:
	if disp == "ps" and _ICONOS_PS.has(pieza):
		return String(_ICONOS_PS[pieza])
	var r_nombre_icono_1: Variant = _nombre_icono_1(pieza)
	if r_nombre_icono_1 != null:
		return r_nombre_icono_1
	var r_nombre_icono_2: Variant = _nombre_icono_2(pieza)
	if r_nombre_icono_2 != null:
		return r_nombre_icono_2
	return ""

static func _nombre_icono_1(pieza: String) -> Variant:
	match pieza:
		"A": return "xbox_button_a"
		"B": return "xbox_button_b"
		"X": return "xbox_button_x"
		"Y": return "xbox_button_y"
		"LB": return "xbox_lb"
		"RB": return "xbox_rb"
		"LT": return "xbox_lt"
		"RT": return "xbox_rt"
	return null

static func _nombre_icono_2(pieza: String) -> Variant:
	match pieza:
		"LS": return "xbox_stick_l_press"
		"RS": return "xbox_stick_r_press"
		"DPAD": return "xbox_dpad"
		"START": return "xbox_button_menu"
		"BACK": return "xbox_button_view"
	return null


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

## El hueco oscuro donde se asienta un botón (como el borde de goma de un mando).
func _hueco(pos: Vector3, radio: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.03, 0.035)
	m.roughness = 0.9
	var mi := _malla(_modelo, _cilindro(radio, 0.04), m, pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ------------------------------------------------------------------ giro

func _aplicar_rotacion() -> void:
	if _pivote == null:
		return
	_pivote.basis = Basis.from_euler(Vector3(_pitch, _yaw, 0.0))
	_pivote.scale = Vector3.ONE * _zoom
