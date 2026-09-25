class_name FondoAnimado
extends CPUParticles2D
## LA CAPA QUE SE MUEVE, por encima del fondo dibujado y por debajo de todo lo
## demás.
##
## Los veinticuatro fondos de `Fondo` son escenas QUIETAS -SVG rasterizado, que
## no anima-. Esto es lo otro: diez climas que se eligen aparte del fondo, así
## que "Estadio de pueblo" puede tener lluvia y "Vitrina" confeti sin dibujar
## veinticuatro fondos más.
##
## POR QUÉ VA APARTE Y NO DENTRO DE `Fondo`. Un fondo es una imagen que se
## cachea una vez y no cuesta nada; esto son partículas vivas que sí cuestan.
## Separarlos deja apagar el movimiento sin perder el dibujo -que es justo lo
## que va a querer quien juegue en un portátil- y deja combinar los dos catálogos
## en vez de multiplicarlos.
##
## NO TOCA `Azar`. Las partículas usan el azar propio de `CPUParticles2D`, que
## es otro generador: un adorno que consumiera el azar del juego cambiaría la
## liga entera según cuántos copos hubieran caído. Ya pasó una vez en este
## proyecto y solo lo cazó el banco de pruebas.

## clave -> [nombre, con qué fondo pega]
const MODOS := {
	"ninguno":  "Sin movimiento",
	"motas":    "Motas de polvo",
	"lluvia":   "Lluvia",
	"nieve":    "Nieve",
	"confeti":  "Confeti",
	"chispas":  "Chispas de bengala",
	"hojas":    "Hojas de otoño",
	"humo":     "Humo de bengala",
	"estrellas": "Cielo estrellado",
	"papeles":  "Papelitos de tifo",
}

static var _punto: Texture2D = null
static var _raya: Texture2D = null
static var _cuadro: Texture2D = null

static func _tex(clave: String) -> Texture2D:
	match clave:
		"raya":
			if _raya == null:
				_raya = _rasterizar('<svg width="3" height="18" xmlns="http://www.w3.org/2000/svg"><rect width="3" height="18" rx="1.5" fill="#ffffff"/></svg>', 2.0)
			return _raya
		"cuadro":
			if _cuadro == null:
				_cuadro = _rasterizar('<svg width="10" height="6" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="6" rx="1" fill="#ffffff"/></svg>', 2.0)
			return _cuadro
	if _punto == null:
		_punto = _rasterizar('<svg width="8" height="8" xmlns="http://www.w3.org/2000/svg"><circle cx="4" cy="4" r="4" fill="#ffffff"/></svg>', 2.0)
	return _punto

static func _rasterizar(svg: String, escala: float) -> Texture2D:
	var img := Image.new()
	img.load_svg_from_string(svg, escala)
	return ImageTexture.create_from_image(img)

var modo: String = "motas"
## Si el clima reacciona al ratón. No mueve cada partícula una a una -eso serían
## miles de cuentas por fotograma-: inclina el VIENTO hacia donde está el cursor,
## que es lo que de verdad se nota y cuesta una resta.
var interactivo: bool = true

var _viento := Vector2.ZERO
var _area := Vector2(1280, 720)

func _init() -> void:
	## Puramente visual: sin script de colisión ni de entrada, nunca le quita el
	## clic a ningún botón de debajo, esté donde esté en el árbol.
	z_index = -5
	emitting = false

func _ready() -> void:
	set_process(true)
	aplicar()

func ajustar_area(tam: Vector2) -> void:
	_area = tam
	position = tam / 2.0
	emission_rect_extents = tam / 2.0
	## La lluvia y la nieve nacen ARRIBA, no en cualquier punto: caer desde el
	## centro de la pantalla se ve como un error, no como lluvia.
	if modo in ["lluvia", "nieve", "hojas", "papeles", "confeti"]:
		position = Vector2(tam.x / 2.0, -30.0)
		emission_rect_extents = Vector2(tam.x / 2.0 + 60.0, 10.0)

## Rehace el emisor entero con los números del modo elegido. Se llama al cambiar
## de clima y al arrancar; no en cada fotograma.
func aplicar() -> void:
	if modo == "ninguno" or not MODOS.has(modo):
		emitting = false
		visible = false
		return
	visible = true
	texture = _tex("punto")
	gravity = Vector2.ZERO
	angular_velocity_min = 0.0
	angular_velocity_max = 0.0
	randomness = 0.7
	preprocess = 4.0
	direction = Vector2(0, -1)
	spread = 12.0
	var curva := Curve.new()
	curva.add_point(Vector2(0, 1.0))
	curva.add_point(Vector2(1, 0.0))
	scale_amount_curve = curva
	var rampa := Gradient.new()

	match modo:
		"motas":
			amount = 40
			lifetime = 6.0
			initial_velocity_min = 16.0
			initial_velocity_max = 46.0
			scale_amount_min = 0.35
			scale_amount_max = 1.0
			rampa.set_color(0, Color(1, 1, 1, 0.34))
			rampa.set_color(1, Color(1, 1, 1, 0.0))
		"lluvia":
			## La lluvia no se apaga al final de su vida: cae y desaparece por
			## abajo. Por eso la curva de escala se deja plana.
			texture = _tex("raya")
			amount = 260
			lifetime = 2.2
			direction = Vector2(0.12, 1)
			spread = 3.0
			initial_velocity_min = 620.0
			initial_velocity_max = 900.0
			gravity = Vector2(0, 300)
			scale_amount_min = 0.7
			scale_amount_max = 1.5
			curva.clear_points()
			curva.add_point(Vector2(0, 1.0))
			curva.add_point(Vector2(1, 1.0))
			rampa.set_color(0, Color(0.76, 0.86, 0.95, 0.28))
			rampa.set_color(1, Color(0.76, 0.86, 0.95, 0.10))
		"nieve":
			amount = 160
			lifetime = 9.0
			direction = Vector2(0.2, 1)
			spread = 22.0
			initial_velocity_min = 26.0
			initial_velocity_max = 64.0
			gravity = Vector2(6, 22)
			scale_amount_min = 0.3
			scale_amount_max = 1.1
			curva.clear_points()
			curva.add_point(Vector2(0, 1.0))
			curva.add_point(Vector2(1, 0.9))
			rampa.set_color(0, Color(1, 1, 1, 0.42))
			rampa.set_color(1, Color(1, 1, 1, 0.16))
		"confeti":
			texture = _tex("cuadro")
			amount = 120
			lifetime = 7.0
			direction = Vector2(0, 1)
			spread = 40.0
			initial_velocity_min = 60.0
			initial_velocity_max = 190.0
			gravity = Vector2(0, 70)
			angular_velocity_min = -220.0
			angular_velocity_max = 220.0
			scale_amount_min = 0.6
			scale_amount_max = 1.3
			curva.clear_points()
			curva.add_point(Vector2(0, 1.0))
			curva.add_point(Vector2(1, 1.0))
			## Confeti de un solo color sería serpentina. La rampa recorre el oro,
			## el verde y el rojo del juego para que se lea como una fiesta.
			rampa.set_color(0, Color("c9a227"))
			rampa.set_color(1, Color("4caf6d"))
			rampa.add_point(0.5, Color("e05555"))
			color_ramp = rampa
			modulate = Color(1, 1, 1, 0.55)
		"chispas":
			amount = 90
			lifetime = 1.6
			direction = Vector2(0, -1)
			spread = 180.0
			initial_velocity_min = 40.0
			initial_velocity_max = 220.0
			gravity = Vector2(0, 120)
			scale_amount_min = 0.2
			scale_amount_max = 0.6
			rampa.set_color(0, Color(1, 0.82, 0.42, 0.85))
			rampa.set_color(1, Color(0.9, 0.25, 0.1, 0.0))
		"hojas":
			texture = _tex("cuadro")
			amount = 46
			lifetime = 11.0
			direction = Vector2(0.4, 1)
			spread = 30.0
			initial_velocity_min = 30.0
			initial_velocity_max = 90.0
			gravity = Vector2(14, 40)
			angular_velocity_min = -90.0
			angular_velocity_max = 90.0
			scale_amount_min = 0.9
			scale_amount_max = 2.0
			curva.clear_points()
			curva.add_point(Vector2(0, 1.0))
			curva.add_point(Vector2(1, 1.0))
			rampa.set_color(0, Color("8a5a26"))
			rampa.set_color(1, Color("4a3a1a"))
			modulate = Color(1, 1, 1, 0.4)
		"humo":
			amount = 34
			lifetime = 9.0
			direction = Vector2(0.3, -1)
			spread = 30.0
			initial_velocity_min = 18.0
			initial_velocity_max = 52.0
			scale_amount_min = 6.0
			scale_amount_max = 16.0
			rampa.set_color(0, Color(0.85, 0.3, 0.25, 0.0))
			rampa.add_point(0.25, Color(0.85, 0.35, 0.28, 0.14))
			rampa.set_color(1, Color(0.4, 0.2, 0.2, 0.0))
			color_ramp = rampa
		"estrellas":
			## Las únicas que no se mueven de sitio: parpadean. Es un cielo, no un
			## clima, y por eso la velocidad es cero y la vida corta.
			amount = 130
			lifetime = 3.4
			initial_velocity_min = 0.0
			initial_velocity_max = 3.0
			scale_amount_min = 0.15
			scale_amount_max = 0.5
			curva.clear_points()
			curva.add_point(Vector2(0, 0.0))
			curva.add_point(Vector2(0.5, 1.0))
			curva.add_point(Vector2(1, 0.0))
			rampa.set_color(0, Color(1, 1, 1, 0.0))
			rampa.add_point(0.5, Color(0.92, 0.95, 1.0, 0.6))
			rampa.set_color(1, Color(1, 1, 1, 0.0))
			color_ramp = rampa
		"papeles":
			texture = _tex("cuadro")
			amount = 200
			lifetime = 6.0
			direction = Vector2(0, 1)
			spread = 25.0
			initial_velocity_min = 90.0
			initial_velocity_max = 240.0
			gravity = Vector2(0, 40)
			angular_velocity_min = -160.0
			angular_velocity_max = 160.0
			scale_amount_min = 0.4
			scale_amount_max = 0.9
			curva.clear_points()
			curva.add_point(Vector2(0, 1.0))
			curva.add_point(Vector2(1, 1.0))
			rampa.set_color(0, Color(0.95, 0.95, 0.92, 0.5))
			rampa.set_color(1, Color(0.8, 0.82, 0.8, 0.25))

	if modo not in ["confeti", "humo", "estrellas"]:
		color_ramp = rampa
	if modo not in ["confeti", "hojas"]:
		modulate = Color(1, 1, 1, 1)
	ajustar_area(_area)
	emitting = true

func _process(delta: float) -> void:
	if not interactivo or not emitting:
		return
	## El cursor empuja el clima. La fuerza es pequeña a propósito -60 px/s² como
	## mucho- porque esto va DETRÁS de una tabla de posiciones: se tiene que
	## notar de refilón, no llamar la atención.
	var centro := _area / 2.0
	var raton := get_viewport().get_mouse_position()
	var d := (raton - centro) / maxf(1.0, centro.length())
	_viento = _viento.lerp(d * 60.0, clampf(delta * 1.6, 0.0, 1.0))
	gravity = _gravedad_base() + _viento

func _gravedad_base() -> Vector2:
	match modo:
		"lluvia": return Vector2(0, 300)
		"nieve": return Vector2(6, 22)
		"confeti": return Vector2(0, 70)
		"chispas": return Vector2(0, 120)
		"hojas": return Vector2(14, 40)
		"papeles": return Vector2(0, 40)
	return Vector2.ZERO
