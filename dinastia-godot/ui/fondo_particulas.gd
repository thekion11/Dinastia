class_name FondoParticulas
extends CPUParticles2D
## El "fondo animado" del menú -`iniciarPhaserMenu()`/`EscenaMenuFx` del
## HTML-: motas de luz naciendo en cualquier punto de la pantalla y subiendo
## despacio, como polvo en el aire. El HTML monta un `Phaser.Game` entero
## para esto solo; Godot ya trae su propio sistema de partículas, así que se
## porta como lo que es de verdad -un emisor con esta forma-, no como "cargar
## un motor externo".
##
## Mismos números que `this.emisor=this.add.particles(...)`: nace en
## cualquier (x,y) de la pantalla, sube entre 4 y 12 px por fotograma con una
## deriva lateral pequeña, dura 6 segundos, y se apaga en tamaño (.6→0) y
## opacidad (.3→0) según se acerca el final de su vida.

static var _punto: Texture2D = null
static func _textura_punto() -> Texture2D:
	if _punto != null:
		return _punto
	var img := Image.new()
	img.load_svg_from_string('<svg width="8" height="8" xmlns="http://www.w3.org/2000/svg"><circle cx="4" cy="4" r="4" fill="#ffffff"/></svg>', 2.0)
	_punto = ImageTexture.create_from_image(img)
	return _punto

func _init() -> void:
	texture = _textura_punto()
	emitting = true
	amount = 40
	lifetime = 6.0
	preprocess = 6.0
	randomness = 0.7
	speed_scale = 1.0
	## No es un `Control` -no tiene mouse_filter-, pero al ser puramente visual
	## (sin script de colisión ni de input) nunca le quita el clic a ningún
	## botón de debajo, sea cual sea su lugar en el árbol.
	z_index = 50

	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	direction = Vector2(0, -1)
	spread = 12.0
	initial_velocity_min = 16.0
	initial_velocity_max = 46.0
	gravity = Vector2.ZERO
	angular_velocity_min = 0.0
	angular_velocity_max = 0.0

	scale_amount_min = 0.35
	scale_amount_max = 1.0
	var curva_escala := Curve.new()
	curva_escala.add_point(Vector2(0, 1.0))
	curva_escala.add_point(Vector2(1, 0.0))
	scale_amount_curve = curva_escala

	var rampa := Gradient.new()
	rampa.set_color(0, Color(1, 1, 1, 0.34))
	rampa.set_color(1, Color(1, 1, 1, 0.0))
	color_ramp = rampa

## Se llama una vez, cuando ya se conoce el tamaño real de la pantalla -antes
## de eso, `position`/`emission_rect_extents` se quedarían con cualquier valor
## y las motas nacerían todas en la esquina-.
func ajustar_area(tam: Vector2) -> void:
	position = tam / 2.0
	emission_rect_extents = tam / 2.0
