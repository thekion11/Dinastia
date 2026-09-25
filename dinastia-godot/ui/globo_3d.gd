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
	"AUS": Vector2(151.2, -33.9), "MEX": Vector2(-99.1, 19.4), "USA": Vector2(-77.0, 38.9),
}

## El sol del HTML: MUY oblicuo a propósito (línea ~14670 de `juego.js`). Con la
## z alta el planeta entero quedaba iluminado y las luces de noche nunca se
## veían; a 0.28 el terminador siempre cruza el disco visible.
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
var _giro_idle := 6.0 ## grados por segundo cuando nadie lo toca -la "deriva lenta" del HTML.
var pais_actual := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 180)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
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

	var esfera := MeshInstance3D.new()
	var malla := SphereMesh.new()
	malla.radius = 1.0
	malla.height = 2.0
	malla.radial_segments = 64
	malla.rings = 32
	esfera.mesh = malla
	var mat_tierra := ShaderMaterial.new()
	mat_tierra.shader = _shader_tierra()
	mat_tierra.set_shader_parameter("tex_dia", dia)
	mat_tierra.set_shader_parameter("tex_noche", noche)
	mat_tierra.set_shader_parameter("luz_dir", SOL)
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
	mat_nubes.shader = _shader_nubes()
	mat_nubes.set_shader_parameter("tex_nubes", nubes_tex)
	mat_nubes.set_shader_parameter("luz_dir", SOL)
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
	atmosfera.material_override = _mat_atmosfera()
	_pivote.add_child(atmosfera)

	_marcador = _crear_marcador()
	_pivote.add_child(_marcador)

	set_process(true)

## BUG REAL (18-9-2026), encontrado por la consola del navegador jugando en la
## build Web: `Image.load_from_file(ProjectSettings.globalize_path(ruta))` lee
## el archivo del disco DIRECTO, saltándose el cargador de recursos de Godot.
## En escritorio `res://` apunta a una carpeta real y esto "funciona" de
## casualidad; en Web (y en cualquier build empaquetada con `.pck`) no hay
## sistema de archivos real detrás de `res://`, así que `globalize_path()` no
## da una ruta legible y la carga fallaba siempre -"Error opening file
## 'recursos/tierra/luces4k.jpg'"- dejando el globo sin luces nocturnas ni
## nubes. Las tres imágenes SÍ están importadas como recurso de Godot
## (`.import` al lado de cada .jpg): `load()` es el cargador normal, funciona
## igual en escritorio, Web y móvil porque lee del `.pck`, no del disco.
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

func _mat_atmosfera() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_front, blend_add, unshaded, depth_draw_never;
void fragment(){
	float borde = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	ALBEDO = vec3(0.35, 0.58, 0.95);
	ALPHA = borde * 0.55;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

func _shader_tierra() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;
uniform sampler2D tex_dia : source_color;
uniform sampler2D tex_noche : source_color;
uniform vec3 luz_dir = vec3(-0.62, 0.44, 0.28);
varying vec3 v_normal_mundo;
void vertex(){
	v_normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment(){
	vec3 n = normalize(v_normal_mundo);
	float cara = dot(n, normalize(luz_dir));
	// El mismo terminador difuso del HTML (smoothstep, no un corte duro): el
	// amanecer es una franja de cientos de kilómetros, no una línea.
	float t = smoothstep(-0.14, 0.30, cara);
	vec3 dia = texture(tex_dia, UV).rgb;
	vec3 noche = texture(tex_noche, UV).rgb;
	ALBEDO = mix(noche * 0.55, dia, t);
	EMISSION = noche * (1.0 - t) * 1.35;
	ROUGHNESS = 0.92;
	SPECULAR = 0.12;
}
"""
	return sh

func _shader_nubes() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, cull_back, blend_mix;
uniform sampler2D tex_nubes : hint_default_white;
uniform vec3 luz_dir = vec3(-0.62, 0.44, 0.28);
varying vec3 v_normal_mundo;
void vertex(){
	v_normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment(){
	float nub = texture(tex_nubes, UV).r;
	float dif = max(dot(normalize(v_normal_mundo), normalize(luz_dir)), 0.0);
	ALBEDO = vec3(0.30 + 0.75 * dif);
	ALPHA = nub * 0.75;
	ROUGHNESS = 1.0;
}
"""
	return sh

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_arrastrando = mb.pressed
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_arrastrando = st.pressed
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _arrastrando:
		## Arrastra el globo con el dedo: mismo signo y escala aproximada que el
		## HTML (rotación directa proporcional al desplazamiento).
		var rel: Vector2 = event.relative if event is InputEventMouseMotion else (event as InputEventScreenDrag).relative
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
	if not GLOBO_PAIS.has(pais):
		return
	pais_actual = pais
	var c: Vector2 = GLOBO_PAIS[pais]
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
	if not _arrastrando:
		lon += (_lon_obj - lon) * minf(1.0, 4.5 * delta)
		lat += (_lat_obj - lat) * minf(1.0, 4.5 * delta)
		if absf(_lon_obj - lon) < 0.3 and absf(_lat_obj - lat) < 0.3:
			## Deriva lenta perpetua, como el HTML: el globo nunca se queda
			## clavado del todo, sigue vivo aunque nadie lo toque.
			_lon_obj -= _giro_idle * delta
			lon -= _giro_idle * delta
	_orientar_pivote(lon, lat)
	if _marcador.visible and pais_actual != "":
		var c: Vector2 = GLOBO_PAIS.get(pais_actual, Vector2.ZERO)
		_marcador.position = _cartesiano(c.x, c.y) * 1.03

## Orienta el pivote para que el punto (lon_g, lat_g) quede mirando de frente
## a la cámara (+Z local). NO usa `rotation_degrees.x/y` -eso fue el bug real:
## Godot compone los tres ejes de Euler como Y·X·Z, así que con `.y` y `.x`
## puestos a mano la X se aplicaba ANTES que la Y, no después como parecía al
## leer el código, y el punto elegido quedaba en el canto de la esfera (x≈1,
## z≈0.05, comprobado imprimiendo la posición) en vez de centrado. Aquí se
## construye la base ortonormal directamente -adelante = el punto, arriba y
## derecha por producto cruz- y se usa su traspuesta -su inversa, por ser
## ortonormal- como rotación: no hay ángulo que adivinar ni orden que acertar.
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
	return Vector3(-cos(phi) * sin(theta), cos(theta), sin(phi) * sin(theta))
