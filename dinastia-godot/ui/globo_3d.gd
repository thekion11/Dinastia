class_name Globo3D
extends SubViewportContainer
## EL GLOBO TERRÁQUEO, EN 3D DE VERDAD -no un dibujo plano de respaldo-.
## Idea de Gemini (Drive, "Mejoras globo"): un `SubViewport` con una esfera real
## en vez del raymarching por píxel que hacía el HTML (`GLOBO_FS`, v3.17: cada
## fragmento del disco resolvía a mano rayo↔esfera y la textura equirectangular
## se muestreaba con la inversa de `gl3()`). Aquí sale gratis: `SphereMesh` YA
## trae esa proyección hecha en sus UV, así que el trabajo de `GLOBO_FS` se
## reduce a un shader spatial normal que lee `UV` en vez de reconstruirla.
##
## Reutiliza las MISMAS tres texturas que el HTML (`recursos/tierra/*.jpg`,
## Blue Marble + luces VIIRS + nubes), copiadas a `res://recursos/tierra/` -aquí
## no hace falta la incrustación en base64 del HTML: eso era el escape de
## `file://` con CORS de WebGL, que en Godot no existe.
##
## Día/noche NO es un simple `if`: se calcula con la MISMA fórmula que
## `GLOBO_FS` -`dot(normal, sol)` con un sol muy oblicuo (z=0.28) para que el
## terminador cruce el disco y siempre haya un trozo de planeta encendido- pero
## aquí el `normal` es el de verdad de la esfera 3D, no uno reconstruido a mano.

const GLOBO_PAIS := {
	"CHI": Vector2(-70.7, -33.4), "ARG": Vector2(-58.4, -34.6), "URU": Vector2(-56.2, -34.9),
	"PAR": Vector2(-57.6, -25.3), "BRA": Vector2(-47.9, -15.8), "BOL": Vector2(-68.1, -16.5),
	"PER": Vector2(-77.0, -12.0), "ECU": Vector2(-78.5, -0.2), "COL": Vector2(-74.1, 4.7),
	"VEN": Vector2(-66.9, 10.5), "ESP": Vector2(-3.7, 40.4), "ENG": Vector2(-0.1, 51.5),
	"ITA": Vector2(12.5, 41.9), "GER": Vector2(13.4, 52.5), "FRA": Vector2(2.3, 48.9),
	"JPN": Vector2(139.7, 35.7), "KOR": Vector2(127.0, 37.6), "KSA": Vector2(46.7, 24.7),
	"EGY": Vector2(31.2, 30.0), "MAR": Vector2(-6.8, 34.0), "RSA": Vector2(28.0, -26.2),
	"AUS": Vector2(149.1, -35.3), "MEX": Vector2(-99.1, 19.4), "USA": Vector2(-77.0, 38.9),
	"POR": Vector2(-9.1, 38.7), "NED": Vector2(4.9, 52.4), "BEL": Vector2(4.4, 50.9),
	"CRO": Vector2(16.0, 45.8), "DEN": Vector2(12.6, 55.7),
	"TUR": Vector2(32.9, 39.9), "SCO": Vector2(-3.2, 55.9), "SUI": Vector2(7.4, 46.9), "AUT": Vector2(16.4, 48.2), "GRE": Vector2(23.7, 38.0), "QAT": Vector2(51.5, 25.3), "SWE": Vector2(18.1, 59.3), "NOR": Vector2(10.7, 59.9), "POL": Vector2(21.0, 52.2), "CZE": Vector2(14.4, 50.1), "ROU": Vector2(26.1, 44.4), "SRB": Vector2(20.5, 44.8), "UKR": Vector2(30.5, 50.5), "CHN": Vector2(116.4, 39.9), "ISR": Vector2(35.2, 31.8), "RUS": Vector2(37.6, 55.8), "HUN": Vector2(19.0, 47.5), "SVK": Vector2(17.1, 48.1), "BUL": Vector2(23.3, 42.7), "UAE": Vector2(54.4, 24.5), "IRN": Vector2(51.4, 35.7),
}

## C14: la capital de cada país con liga (el pin se pone en sus coordenadas).
## F1 (25-10-2026): la de Australia es Canberra, no Sídney -lo decía la ficha del país-;
## el pin se movió con ella (está a 250 km, el globo apenas lo nota).
const CAPITAL := {
	"CHI": "Santiago", "ARG": "Buenos Aires", "URU": "Montevideo", "PAR": "Asunción",
	"BRA": "Brasilia", "BOL": "La Paz", "PER": "Lima", "ECU": "Quito", "COL": "Bogotá",
	"VEN": "Caracas", "ESP": "Madrid", "ENG": "Londres", "ITA": "Roma", "GER": "Berlín",
	"FRA": "París", "JPN": "Tokio", "KOR": "Seúl", "KSA": "Riad", "EGY": "El Cairo",
	"MAR": "Rabat", "RSA": "Pretoria", "AUS": "Canberra", "MEX": "Ciudad de México", "USA": "Washington",
	"POR": "Lisboa", "NED": "Ámsterdam", "BEL": "Bruselas", "CRO": "Zagreb", "DEN": "Copenhague",
	"TUR": "Ankara", "SCO": "Edimburgo", "SUI": "Berna", "AUT": "Viena", "GRE": "Atenas", "QAT": "Doha", "SWE": "Estocolmo", "NOR": "Oslo", "POL": "Varsovia", "CZE": "Praga", "ROU": "Bucarest", "SRB": "Belgrado", "UKR": "Kiev", "CHN": "Pekín", "ISR": "Jerusalén", "RUS": "Moscú", "HUN": "Budapest", "SVK": "Bratislava", "BUL": "Sofía", "UAE": "Abu Dabi", "IRN": "Teherán",
}

## Se tocó un país en el globo (clic sin arrastrar sobre su pin).
signal pais_tocado(pais: String)
## El ratón pasa por encima de un pin (o sale de él: ""). Para enseñar su nombre.
signal pais_sobre(pais: String)
var _sobre := ""

var _coords: Dictionary = {}     ## pais -> Vector2(lon, lat) de su capital (los 135 con liga, 15-11)
var _orden: Array[String] = []   ## el orden de las instancias del MultiMesh de pines
var _pines_mm: MultiMesh         ## (15-11) TODOS los pines en una sola llamada de dibujo (antes un MeshInstance3D por país)
var _rotulos: Dictionary = {}    ## pais -> Label3D: solo los que se han rotulado o señalado (antes 50 a la vez)
## (15-11, pedido del dueño) Los países que se pueden elegir (los de las ligas elegidas); vacío = todos. Los demás, pin apagado y sin respuesta.
var permitidos: Array = []
## Un vecino a menos de esto (radio del globo = 1) se esconde: no pisa al elegido.
const SEPARACION_ROTULO := 0.24
var _pulsado_en := Vector2.ZERO
var _movido := 0.0

## El sol del HTML: MUY oblicuo a propósito (línea ~14670 de `juego.js`). Con la z alta el planeta entero quedaba iluminado y las luces de noche nunca se veían;
## a 0.28 el terminador siempre cruza el disco visible.
const SOL := Vector3(-0.62, 0.44, 0.28)

var _viewport: SubViewport
var _pivote: Node3D
var _nubes: MeshInstance3D
var _marcador: Node3D
var _cam: Camera3D

var lon := -70.0
var lat := -20.0
var _lon_obj := -70.0
var _lat_obj := -20.0
var _arrastrando := false
var _reposo := false   ## (3-11) en MÍNIMA, quieto: la última imagen se pinta una vez y no se repinta hasta que alguien lo toque
var _giro_idle := 6.0 ## grados por segundo cuando nadie lo toca -la "deriva lenta" del HTML.
var pais_actual := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 180)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Calidad.msaa_ui(Viewport.MSAA_2X)
	_viewport.size = Vector2i(600, 300)
	add_child(_viewport)
	stretch = true

	var mundo3d := Node3D.new()
	_viewport.add_child(mundo3d)

	_cam = Camera3D.new()
	_cam.position = Vector3(0, 0, 3.1)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = 2.35
	mundo3d.add_child(_cam)

	## Luz muy tenue de relleno: la sombra de verdad la pone el shader (EMISSION +
	## el mezclado día/noche), esta solo evita que el borde se vea negro puro.
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-30, 140, 0)
	relleno.light_energy = 0.35
	mundo3d.add_child(relleno)

	_pivote = Node3D.new()
	mundo3d.add_child(_pivote)

	var dia := _cargar("res://recursos/tierra/tierra4k.jpg")
	var noche := _cargar("res://recursos/tierra/luces4k.jpg")
	var nubes_tex := _cargar("res://recursos/tierra/nubes2k.jpg")
	## Fronteras de Natural Earth (dominio público), rasterizadas a 4096x2048
	## con la misma proyección equirectangular que la textura del día.
	var fronteras := _cargar("res://recursos/tierra/fronteras4k.png")

	var esfera := MeshInstance3D.new()
	var malla := SphereMesh.new()
	malla.radius = 1.0
	malla.height = 2.0
	malla.radial_segments = 64
	malla.rings = 32
	esfera.mesh = malla
	var mat_tierra := ShaderMaterial.new()
	mat_tierra.shader = GloboShaders.tierra(true)
	mat_tierra.set_shader_parameter("tex_dia", dia)
	mat_tierra.set_shader_parameter("tex_noche", noche)
	mat_tierra.set_shader_parameter("tex_fronteras", fronteras)
	esfera.material_override = mat_tierra
	_pivote.add_child(esfera)

	_nubes = MeshInstance3D.new()
	var malla_n := SphereMesh.new()
	malla_n.radius = 1.012
	malla_n.height = 2.024
	malla_n.radial_segments = 48
	malla_n.rings = 24
	_nubes.mesh = malla_n
	var mat_nubes := ShaderMaterial.new()
	mat_nubes.shader = GloboShaders.nubes()
	mat_nubes.set_shader_parameter("tex_nubes", nubes_tex)
	_nubes.material_override = mat_nubes
	_pivote.add_child(_nubes)

	## Atmósfera: una esfera un poco mayor, vista por dentro (`cull_front`), con
	## un azul que solo se nota en el borde -el mismo halo del `discard`/`pow`
	## de `GLOBO_FS` cuando el rayo pasa rozando el planeta.
	var atmosfera := MeshInstance3D.new()
	var malla_a := SphereMesh.new()
	malla_a.radius = 1.05
	malla_a.height = 2.1
	malla_a.radial_segments = 32
	malla_a.rings = 16
	atmosfera.mesh = malla_a
	atmosfera.material_override = GloboShaders.atmosfera()
	_pivote.add_child(atmosfera)

	_marcador = _crear_marcador()
	_pivote.add_child(_marcador)
	_crear_pines()

	set_process(true)

## BUG REAL (18-9-2026, consola del navegador en la build Web): `Image.load_from_file(globalize_path(ruta))` lee el disco DIRECTO y en Web o en un `.pck` no hay
## disco detrás de `res://` («Error opening file 'recursos/tierra/luces4k.jpg'»): el globo quedaba sin luces nocturnas ni nubes. Las tres imágenes SÍ están importadas
## como recurso: `load()` es el cargador normal y funciona igual en escritorio, Web y móvil.
func _cargar(ruta: String) -> Texture2D:
	return load(ruta) as Texture2D

## Un pin dorado con un brillo suave: "flota sobre su chincheta" como los
## monumentos del HTML, sin tener que portar 24 iconos SVG distintos.
func _crear_marcador() -> Node3D:
	var n := Node3D.new()
	var bola := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 0.028
	esf.height = 0.056
	bola.mesh = esf
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffd24d")
	mat.emission_enabled = true
	mat.emission = Color("ffd24d")
	mat.emission_energy_multiplier = 2.4
	bola.material_override = mat
	n.add_child(bola)
	n.visible = false
	return n

## C14: un pin en la capital de cada país con liga; el elegido es el dorado. (15-11) Los 135, en UN MultiMesh con color por instancia
## (blanco = se puede elegir, gris = su liga no está elegida). Los rótulos ya no van todos a la vez: se crean al rotular o señalar un país.
func _crear_pines() -> void:
	var esf := SphereMesh.new()
	esf.radius = 0.011
	esf.height = 0.022
	esf.radial_segments = 8
	esf.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	esf.material = mat
	for p: String in GLOBO_PAIS:
		_coords[p] = GLOBO_PAIS[p]
	var extra: Dictionary = load("res://ui/entrada/pais_datos_extra.gd").EXTRA
	for p: String in extra:
		_coords[p] = Vector2(float(extra[p][2]), float(extra[p][3]))
	_orden.assign(_coords.keys())
	_pines_mm = MultiMesh.new()
	_pines_mm.transform_format = MultiMesh.TRANSFORM_3D
	_pines_mm.use_colors = true
	_pines_mm.mesh = esf
	_pines_mm.instance_count = _orden.size()
	for i in _orden.size():
		var c: Vector2 = _coords[_orden[i]]
		_pines_mm.set_instance_transform(i, Transform3D(Basis(), _cartesiano(c.x, c.y) * 1.01))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _pines_mm
	_pivote.add_child(mmi)
	_pintar_pines()

## Fija los países que se pueden elegir (vacío = todos) y repinta los pines.
func fijar_permitidos(lista: Array) -> void:
	permitidos = lista.duplicate()
	if _pines_mm != null:
		_pintar_pines()
		_activar()

func se_puede(p: String) -> bool:
	return _coords.has(p) and (permitidos.is_empty() or permitidos.has(p))

func _pintar_pines() -> void:
	for i in _orden.size():
		_pines_mm.set_instance_color(i, Color(1.0, 1.0, 1.0) if se_puede(_orden[i]) else Color(0.42, 0.45, 0.5))

func _rotulo_de(p: String) -> Label3D:
	if _rotulos.has(p):
		return _rotulos[p]
	var c: Vector2 = _coords.get(p, Vector2.ZERO)
	var r := Label3D.new()
	r.text = p
	r.font_size = 30
	r.pixel_size = 0.0022
	r.outline_size = 8
	r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.modulate = Color(1, 1, 1, 0.9)
	r.position = _cartesiano(c.x, c.y) * 1.04 + Vector3(0, 0.035, 0)
	_pivote.add_child(r)
	_rotulos[p] = r
	return r

## (15-11) Coordenadas y capital de cualquiera de los 135 países (los 50 de siempre y los de `PaisDatosExtra`).
static func tiene(p: String) -> bool:
	return GLOBO_PAIS.has(p) or load("res://ui/entrada/pais_datos_extra.gd").EXTRA.has(p)

static func coord(p: String) -> Vector2:
	return GLOBO_PAIS[p] if GLOBO_PAIS.has(p) else load("res://ui/entrada/pais_datos_extra.gd").coord(p)

static func capital(p: String) -> String:
	if CAPITAL.has(p):
		return String(CAPITAL[p])
	var f: Array = load("res://ui/entrada/pais_datos_extra.gd").EXTRA.get(p, [])
	return String(f[1]) if not f.is_empty() else "?"

## Cambia el rótulo 3D de un país (la pantalla de país pone el nombre completo del
## elegido; "" vuelve al código de tres letras de siempre).
func rotular(pais: String, texto: String = "") -> void:
	if not _coords.has(pais):
		return
	var r := _rotulo_de(pais)
	r.text = texto if texto != "" else pais
	_activar()

## Vuelve a repintar el globo cada fotograma (algo cambió: se tocó, se eligió un país, se rotuló).
func _activar() -> void:
	_reposo = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

## El país cuyo pin está más cerca de un punto de la pantalla (en píxeles del
## control), o "" si no hay ninguno a menos de 22 px o está de espaldas.
func pais_en(punto: Vector2) -> String:
	if _cam == null or size.x <= 0.0:
		return ""
	var escala := Vector2(_viewport.size) / size
	var mejor := ""
	var dist := 22.0
	var t := _pivote.global_transform
	for p: String in _coords:
		if not se_puede(p):
			continue
		var c: Vector2 = _coords[p]
		var g := t * (_cartesiano(c.x, c.y) * 1.01)
		if g.z < 0.15:
			continue
		var en_pantalla := _cam.unproject_position(g) / escala
		var d := en_pantalla.distance_to(punto)
		if d < dist:
			dist = d
			mejor = p
	return mejor

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastrando = mb.pressed
			## Clic sin arrastrar = tocar un país.
			if mb.pressed:
				_pulsado_en = mb.position
				_movido = 0.0
			elif _movido < 6.0:
				var p := pais_en(mb.position)
				if p != "":
					ir_a(p)
					pais_tocado.emit(p)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_arrastrando = st.pressed
	elif event is InputEventMouseMotion and not _arrastrando:
		var p := pais_en((event as InputEventMouseMotion).position)
		if p != _sobre:
			_sobre = p
			if p != "" and p != pais_actual and not _rotulos.has(p):
				_rotulo_de(p)   ## el señalado lleva su código (antes estaban todos a la vez)
			_activar()
			pais_sobre.emit(p)
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _arrastrando:
		## Arrastra el globo con el dedo: mismo signo y escala aproximada que el
		## HTML (rotación directa proporcional al desplazamiento).
		var rel: Vector2 = event.relative if event is InputEventMouseMotion else (event as InputEventScreenDrag).relative
		_movido += rel.length()
		lon += rel.x * 0.35
		lat = clampf(lat - rel.y * 0.35, -85.0, 85.0)
		_lon_obj = lon
		_lat_obj = lat

## Anima el viaje hasta un país, como `globoIr()` del HTML: toma el camino
## corto -si no, cruzaba medio planeta para ir de Chile a Japón- y deja que
## `_process` haga el resto con el mismo factor de suavizado (0.075/frame a 30
## FPS ~ misma velocidad percibida). `instantaneo` salta la animación -solo lo
## usa la captura de pruebas, para fotografiar el globo ya detenido.
func ir_a(pais: String, instantaneo: bool = false) -> void:
	if not _coords.has(pais):
		return
	pais_actual = pais
	_activar()
	var c: Vector2 = _coords[pais]
	_lon_obj = c.x
	_lat_obj = clampf(c.y * 0.72, -55.0, 55.0)
	while _lon_obj - lon > 180.0:
		lon += 360.0
	while lon - _lon_obj > 180.0:
		lon -= 360.0
	_marcador.visible = true
	if instantaneo:
		lon = _lon_obj
		lat = _lat_obj
		_orientar_pivote(lon, lat)
		_marcador.position = _cartesiano(c.x, c.y) * 1.03

func _process(delta: float) -> void:
	if _reposo:
		if not _arrastrando and AhorroMenu.fondo_estatico():
			return
		_activar()
	if not _arrastrando:
		lon += (_lon_obj - lon) * minf(1.0, 4.5 * delta)
		lat += (_lat_obj - lat) * minf(1.0, 4.5 * delta)
		if absf(_lon_obj - lon) < 0.3 and absf(_lat_obj - lat) < 0.3:
			if AhorroMenu.fondo_estatico():
				_reposo = true   ## MÍNIMA (3-11): sin deriva; se pinta esta imagen una vez y queda quieto hasta que lo toquen
				_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			else:
				## Deriva lenta perpetua, como el HTML: el globo sigue vivo aunque nadie lo toque.
				_lon_obj -= _giro_idle * delta
				lon -= _giro_idle * delta
	_orientar_pivote(lon, lat)
	## El elegido lleva su nombre completo; los vecinos (ARG, URU) se le montaban encima.
	var sel: Label3D = _rotulos.get(pais_actual)
	for p: String in _rotulos:
		var r: Label3D = _rotulos[p]
		var z := r.global_position.z
		var pisa := sel != null and r != sel and r.global_position.distance_to(sel.global_position) < SEPARACION_ROTULO
		r.visible = z > 0.45 and not pisa and (p == pais_actual or p == _sobre)
		r.modulate = Color("ffd24d") if p == pais_actual else Color(1, 1, 1, clampf((z - 0.45) * 3.0, 0.0, 0.9))
	if _marcador.visible and pais_actual != "":
		var c: Vector2 = _coords.get(pais_actual, Vector2.ZERO)
		_marcador.position = _cartesiano(c.x, c.y) * 1.03

## Orienta el pivote para que el punto (lon_g, lat_g) quede mirando de frente a la cámara (+Z local). NO usa `rotation_degrees.x/y` -eso fue el bug real: Godot compone
## los tres ejes de Euler como Y·X·Z, así que con `.y` y `.x` a mano la X se aplicaba ANTES que la Y, y el punto elegido quedaba en el canto de la esfera (x≈1, z≈0.05,
## comprobado imprimiendo la posición) en vez de centrado-. Aquí se construye la base ortonormal -adelante = el punto, arriba y derecha por producto cruz- y se usa su
## traspuesta (su inversa) como rotación: no hay ángulo que adivinar ni orden que acertar.
func _orientar_pivote(lon_g: float, lat_g: float) -> void:
	var adelante := _cartesiano(lon_g, lat_g).normalized()
	var arriba_mundo := Vector3.UP
	if absf(adelante.dot(arriba_mundo)) > 0.999:
		arriba_mundo = Vector3.RIGHT ## evita el polo, donde cross() da vector nulo
	var derecha := arriba_mundo.cross(adelante).normalized()
	var arriba := adelante.cross(derecha).normalized()
	_pivote.basis = Basis(derecha, arriba, adelante).transposed()

## La posición 3D de un punto (lon, lat) sobre la esfera SIN rotar -mismo
## sistema de coordenadas que usan las UV que `SphereMesh` genera solo, sin
## ningún giro añadido a mano-, para que el pin caiga exactamente donde cae la
## costa en la textura y no en un punto "parecido".
##
## Derivación (no una rotación adivinada por prueba y error): `SphereMesh`
## genera cada vértice con phi = U·2π, theta = V·π, y
##   x=-cos(phi)·sin(theta), y=cos(theta), z=sin(phi)·sin(theta).
## La textura es equirectangular al estilo del HTML (`GLOBO_FS`):
## `uv.x = lon/2π + 0.5`, `uv.y = 0.5 - lat/π` → phi = lon+180°,
## theta = 90°-lat. Sustituyendo queda la fórmula de abajo.
func _cartesiano(lon_g: float, lat_g: float) -> Vector3:
	var theta := deg_to_rad(90.0 - lat_g)
	var phi := deg_to_rad(lon_g + 180.0)
	## C14 (26-9-2026): la fórmula de arriba suponía x=-cos(phi), z=sin(phi), pero con las UV del `SphereMesh` de Godot 4 el punto (lon, lat) de la textura cae
	## en x=sin(phi), z=cos(phi): los pines quedaban 90° corridos (Australia en el océano Índico) y el país elegido no era el que se veía. Comprobado a ojo con las
	## fronteras dibujadas: Sídney, Brasilia y las capitales andinas caen en su sitio.
	return Vector3(sin(phi) * sin(theta), cos(theta), cos(phi) * sin(theta))
