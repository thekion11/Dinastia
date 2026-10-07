class_name Balon3D
extends Node3D
## EL BALÓN, CON SU PROPIA PIEL Y SU PROPIO MOTOR DE MOVIMIENTO.
##
## Hasta ahora el balón del visor 3D era una malla suelta con una textura fija
## -un cuadriculado blanco y negro, siempre el mismo- y `MatchPlayback` lo
## movía a mano con un `lerp` lineal más un rebote de seno. Dos cosas se
## quedaban sin usar: el catálogo `Comercial.BALON_SKINS` -5 pieles ya
## elegibles en Club → Detalles del club y jamás pintadas en el 3D- y
## cualquier noción de que una pelota de verdad viaja en ARCO y rueda sobre
## un eje que depende de hacia dónde va, no siempre el mismo.
##
## Esta clase junta las dos cosas: pinta la piel elegida -reutilizando el
## mismo patrón a cuadros que ya existía, solo que coloreado- y sabe moverse
## sola: `enviar()` lanza un tiro/pase de un punto a otro con una parábola de
## verdad (altura real, no un seno decorativo) y `avanzar()` la hace rodar con
## el eje de giro correcto, calculado como rueda una pelota real -perpendicular
## a la dirección de viaje, no fijo en X-.

const RADIO := 0.11

var radio := RADIO
var _origen := Vector3.ZERO
var _destino := Vector3.ZERO
var _t := 1.0          ## 1.0 = ya llegó, quieta hasta el próximo enviar()
var _duracion := 0.4
var _altura_max := 0.0
## Física Magnus (documento maestro): convive con el arco `enviar()`.
## Si `_modo_fisica`, `avanzar()` integra velocidad+giro en vez de la parábola.
const GRAVEDAD := 9.81
const RESISTENCIA_AIRE := 0.12
const RESTITUCION_CESPED := 0.58
var _modo_fisica := false
var velocidad_vectorial := Vector3.ZERO
var giro_angular := Vector3.ZERO

## Construye el balón ya pintado con su piel y colocado en `pos`. `claro` y
## `oscuro` son los dos colores de la piel elegida -ya resueltos por
## `Comercial.color_balon()`, que sabe qué hacer con la piel "colores del
## club"-, y `diseno` el dibujo de los paneles (ver `DISENOS`).
static func crear(pos: Vector3, claro: Color, oscuro: Color, diseno: String = "clasico") -> Balon3D:
	var b := Balon3D.new()
	b.position = pos
	b._origen = pos
	b._destino = pos
	var malla := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = RADIO
	mesh.height = RADIO * 2.0
	## 48×24: con 20×10 el balón se veía facetado en las repeticiones y en la
	## presentación de fichajes, que lo enseñan de cerca.
	mesh.radial_segments = 48
	mesh.rings = 24
	malla.mesh = mesh
	malla.material_override = material(claro, oscuro, diseno)
	malla.name = "Malla"
	b.add_child(malla)
	b.name = "Ball"
	return b

# ---------------------------------------------------------------------------
#  LA PIEL: PANELES DE VERDAD (29-9-2026, mapa de metas 19)
# ---------------------------------------------------------------------------
## Hasta hoy la piel era un damero de 10×6 celdas. Ahora los paneles se
## calculan SOBRE LA ESFERA -cada píxel de la textura se lleva a su punto del
## balón con el mismo mapeo que usa `SphereMesh`-, así que no se estiran en
## los polos y las costuras cierran:
##   - "clasico": el balón de 32 paneles, 12 pentágonos oscuros y 20
##     hexágonos claros (icosaedro truncado, con sus proporciones reales);
##   - "moderno": 6 paneles curvos con una franja de color en los bordes, como
##     los balones de liga de hoy;
##   - "retro": cuero de 18 gajos cosidos, con su grano;
## y cada uno con costuras hundidas y un poco de brillo.
const DISENOS := ["clasico", "moderno", "retro"]
const ANCHO_TEX := 256
const ALTO_TEX := 128
## El balón elegido del partido en curso: lo usan las dominadas del
## calentamiento y la presentación de fichajes.
static var material_actual: Material
static var _cache_tex := {}

static func material(claro: Color, oscuro: Color, diseno: String = "clasico") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = textura(claro, oscuro, diseno)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.roughness = 0.62 if diseno == "retro" else 0.38
	mat.clearcoat_enabled = diseno != "retro"
	mat.clearcoat = 0.35
	mat.clearcoat_roughness = 0.3
	material_actual = mat
	return mat

static func textura(claro: Color, oscuro: Color, diseno: String = "clasico") -> ImageTexture:
	var clave := "%s|%s|%s" % [claro.to_html(false), oscuro.to_html(false), diseno]
	if _cache_tex.has(clave):
		return _cache_tex[clave]
	var img := Image.create(ANCHO_TEX, ALTO_TEX, false, Image.FORMAT_RGB8)
	var centros_p := _icosaedro()
	var centros_h := _caras_icosaedro(centros_p)
	var ejes := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
	var costura := claro.darkened(0.45)
	for y in ALTO_TEX:
		var th := (float(y) + 0.5) / float(ALTO_TEX) * PI
		for x in ANCHO_TEX:
			var ph := (float(x) + 0.5) / float(ANCHO_TEX) * TAU
			## El mismo mapeo que `SphereMesh`.
			var d := Vector3(sin(ph) * sin(th), cos(th), cos(ph) * sin(th))
			var col: Color
			match diseno:
				"moderno":
					col = _pixel_moderno(d, ejes, claro, oscuro, costura)
				"retro":
					col = _pixel_retro(d, ejes, claro, oscuro, x, y)
				_:
					col = _pixel_clasico(d, centros_p, centros_h, claro, oscuro, costura)
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache_tex[clave] = tex
	return tex

## Los 12 vértices del icosaedro: los centros de los pentágonos.
static func _icosaedro() -> Array[Vector3]:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = []
	for a: float in [-1.0, 1.0]:
		for b: float in [-t, t]:
			v.append(Vector3(0, a, b).normalized())
			v.append(Vector3(a, b, 0).normalized())
			v.append(Vector3(b, 0, a).normalized())
	return v

## Los 20 centros de cara: los centros de los hexágonos (tres vértices vecinos).
static func _caras_icosaedro(v: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var lado := 99.0
	for i in v.size():
		for j in range(i + 1, v.size()):
			lado = minf(lado, v[i].angle_to(v[j]))
	for i in v.size():
		for j in range(i + 1, v.size()):
			if absf(v[i].angle_to(v[j]) - lado) > 0.01:
				continue
			for k in range(j + 1, v.size()):
				if absf(v[i].angle_to(v[k]) - lado) < 0.01 and absf(v[j].angle_to(v[k]) - lado) < 0.01:
					out.append((v[i] + v[j] + v[k]).normalized())
	return out

## Icosaedro truncado: del centro al borde hay 16,47° en un pentágono y 20,9°
## en un hexágono. Comparar las distancias YA divididas por eso pone la
## frontera justo en la arista, con las proporciones del balón de verdad.
static func _pixel_clasico(d: Vector3, cp: Array[Vector3], ch: Array[Vector3], claro: Color, oscuro: Color, costura: Color) -> Color:
	var m1 := 99.0
	var m2 := 99.0
	var es_pent := false
	for c: Vector3 in cp:
		var a := d.angle_to(c) / deg_to_rad(16.47)
		if a < m1:
			m2 = m1
			m1 = a
			es_pent = true
		elif a < m2:
			m2 = a
	for c: Vector3 in ch:
		var a := d.angle_to(c) / deg_to_rad(20.9)
		if a < m1:
			m2 = m1
			m1 = a
			es_pent = false
		elif a < m2:
			m2 = a
	if m2 - m1 < 0.045:
		return costura
	var base := oscuro if es_pent else claro
	## Relieve: el panel se oscurece un poco hacia la costura.
	return base.darkened(clampf(0.12 - (m2 - m1) * 0.35, 0.0, 0.12))

## Seis paneles torcidos (el giro depende de la altura, por eso se curvan) con
## una franja del color secundario pegada a cada costura.
static func _pixel_moderno(d: Vector3, ejes: Array, claro: Color, oscuro: Color, costura: Color) -> Color:
	var q := d.rotated(Vector3.UP, d.y * 0.9).rotated(Vector3.RIGHT, d.z * 0.5)
	var m1 := -9.0
	var m2 := -9.0
	var cual := 0
	for i in ejes.size():
		var p := q.dot(ejes[i])
		if p > m1:
			m2 = m1
			m1 = p
			cual = i
		elif p > m2:
			m2 = p
	var ventaja := m1 - m2
	if ventaja < 0.018:
		return costura
	if ventaja < 0.16:
		## La franja: una pasada más fina con un tercer tono.
		return oscuro if ventaja > 0.05 else oscuro.lerp(claro, 0.35)
	if cual % 3 == 0 and ventaja > 0.42:
		return claro.lerp(oscuro, 0.12)
	return claro

## Cuero de 18 gajos: 6 caras con 3 tiras cada una, con grano.
static func _pixel_retro(d: Vector3, ejes: Array, claro: Color, oscuro: Color, x: int, y: int) -> Color:
	var cual := 0
	var m := -9.0
	for i in ejes.size():
		var p: float = d.dot(ejes[i])
		if p > m:
			m = p
			cual = i
	var eje: Vector3 = ejes[cual]
	## Coordenada a lo ancho de la cara para partirla en 3 tiras.
	var otro := Vector3.UP if absf(eje.y) < 0.5 else Vector3.RIGHT
	var u := d.dot(eje.cross(otro).normalized()) / maxf(m, 0.2)
	var tira := u * 1.5 + 1.5
	var borde_tira := absf(tira - roundf(tira))
	## Grano del cuero: ruido barato y estable por píxel.
	var grano := float((x * 73856093) ^ (y * 19349663)) / 2147483647.0
	grano = fposmod(grano, 1.0) * 0.08 - 0.04
	var base := claro.lerp(oscuro, 0.08 * float(cual % 2)).darkened(grano)
	## Costura de cara (donde dos caras empatan) y entre tiras.
	var segundo := -9.0
	for i in ejes.size():
		if i != cual:
			segundo = maxf(segundo, d.dot(ejes[i]))
	if m - segundo < 0.03 or (borde_tira < 0.035 and absf(tira - 1.5) < 1.4):
		return oscuro
	return base

# ---------------------------------------------------------------------------
#  EL MOTOR: ARCO DE VERDAD Y RODADO CON EL EJE CORRECTO
# ---------------------------------------------------------------------------

## Lanza el balón de donde está ahora hacia `destino`, tardando `duracion`
## segundos y subiendo `altura_max` metros en el punto más alto del arco -0
## es un pase raso que no despega del césped, más de medio metro ya se lee
## como un remate o un despeje-. No mueve nada por sí sola: es `avanzar()`,
## llamada cada fotograma, la que recorre el arco.
var _en_red := false

## Lanza el balón de donde está ahora hacia `destino`, tardando `duracion`
## segundos y subiendo `altura_max` metros en el punto más alto del arco.
## Si `destino.y` viene alto (un remate al ángulo, un tiro que entra a media altura),
## el balón terminará a esa altura en vez de forzarlo al suelo.
## `es_gol`: si es true, al llegar a la red el balón amortigua y cae al césped dentro del arco.
func enviar(destino: Vector3, duracion: float, altura_max: float, es_gol: bool = false) -> void:
	_modo_fisica = false
	_origen = Vector3(position.x, maxf(position.y, radio), position.z)
	_destino = Vector3(destino.x, maxf(destino.y, radio), destino.z)
	_duracion = maxf(duracion, 0.05)
	_altura_max = maxf(altura_max, 0.0)
	_t = 0.0
	_en_red = es_gol

func disparar(impulso: Vector3, spin: Vector3 = Vector3.ZERO) -> void:
	_modo_fisica = true
	_t = 0.0
	_en_red = false
	velocidad_vectorial = impulso
	giro_angular = spin

func detener() -> void:
	_modo_fisica = false
	_t = 1.0
	velocidad_vectorial = Vector3.ZERO
	giro_angular = Vector3.ZERO

## Avanza el arco un paso de `delta` segundos. La altura combina la interpolación
## lineal entre el origen y el destino con la parábola de elevación `4·t·(1-t)`.
## Además calcula el giro de rodadura sin deslizamiento.
func avanzar(delta: float) -> void:
	if _modo_fisica:
		_avanzar_fisica(delta)
		return
	if _t >= 1.0:
		if _en_red and position.y > radio + 0.01:
			position.y = maxf(radio, position.y - 2.8 * delta)
		return
	var t_antes := _t
	_t = minf(1.0, _t + delta / _duracion)
	var xz_antes := Vector2(_origen.x, _origen.z).lerp(Vector2(_destino.x, _destino.z), t_antes)
	var xz_ahora := Vector2(_origen.x, _origen.z).lerp(Vector2(_destino.x, _destino.z), _t)
	var y_base := lerpf(_origen.y, _destino.y, _t)
	var y := y_base + _altura_max * 4.0 * _t * (1.0 - _t)
	position = Vector3(xz_ahora.x, y, xz_ahora.y)

	var despl := xz_ahora - xz_antes
	if despl.length_squared() > 0.0000001:
		var eje := Vector3(despl.y, 0.0, -despl.x).normalized()
		var angulo := despl.length() / radio
		global_rotate(eje, angulo)

## ¿Sigue en el aire o ya llegó? Le sirve a quien lo mueve para saber cuándo
## puede pedirle el próximo destino sin que el arco actual se corte a medias.
func _avanzar_fisica(delta: float) -> void:
	var dt := maxf(delta, 0.0001)
	var pos_antes := position
	var fuerza_magnus := giro_angular.cross(velocidad_vectorial) * 0.02
	var arrastre := -velocidad_vectorial * RESISTENCIA_AIRE
	var aceleracion := Vector3(0.0, -GRAVEDAD, 0.0) + fuerza_magnus + arrastre
	velocidad_vectorial += aceleracion * dt
	position += velocidad_vectorial * dt
	if position.y <= radio:
		position.y = radio
		velocidad_vectorial.y = -velocidad_vectorial.y * RESTITUCION_CESPED
		velocidad_vectorial.x *= 0.82
		velocidad_vectorial.z *= 0.82
		giro_angular *= 0.7
		if velocidad_vectorial.length() < 0.35:
			detener()
			return
	var despl := Vector2(position.x, position.z) - Vector2(pos_antes.x, pos_antes.z)
	if despl.length_squared() > 0.0000001:
		var eje := Vector3(despl.y, 0.0, -despl.x).normalized()
		global_rotate(eje, despl.length() / radio)

func en_vuelo() -> bool:
	if _modo_fisica:
		return velocidad_vectorial.length() > 0.4 or position.y > radio + 0.05
	return _t < 1.0
