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
## club"-, no una clave de catálogo: esta clase no conoce `Comercial` ni
## falta que le haga, la resolución de qué piel toca vive donde vive el dato.
static func crear(pos: Vector3, claro: Color, oscuro: Color) -> Balon3D:
	var b := Balon3D.new()
	b.position = pos
	b._origen = pos
	b._destino = pos
	var malla := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = RADIO
	mesh.height = RADIO * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	malla.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _textura(claro, oscuro)
	mat.roughness = 0.4
	malla.material_override = mat
	malla.name = "Malla"
	b.add_child(malla)
	b.name = "Ball"
	return b

## El mismo patrón a cuadros de siempre -10×6 celdas, es lo que se lee como
## "pelota" a la distancia de cámara de este juego, un balón de verdad con
## pentágonos reales solo se distinguiría de cerca-, pero coloreado con la
## piel que se le pida en vez de blanco y negro fijos.
static func _textura(claro: Color, oscuro: Color) -> ImageTexture:
	var w := 64
	var h := 32
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in range(h):
		for x in range(w):
			var cell := int(floor(float(x) / w * 10.0)) + int(floor(float(y) / h * 6.0))
			img.set_pixel(x, y, oscuro if cell % 2 == 0 else claro)
	return ImageTexture.create_from_image(img)

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
