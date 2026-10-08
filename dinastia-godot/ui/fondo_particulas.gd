class_name FondoParticulas
extends CPUParticles2D
## El "fondo animado" del menú -`iniciarPhaserMenu()`/`EscenaMenuFx` del
## HTML-: luz flotando en el aire de la portada.
##
## 8-10-2026 (pedido: «esas partículas mejóralas y haz que se vean más
## bonitas»). Antes eran puntos blancos planos que subían todos igual. Ahora
## hay dos tipos, con brillo de verdad (mezcla aditiva y textura de halo):
##   "motas"  chispas pequeñas con núcleo brillante y halo, que nacen, titilan
##            (la escala late a lo largo de su vida), se mecen al subir y se
##            apagan; cada una con un tono un poco distinto.
##   "bokeh"  pocas luces grandes y desenfocadas, lentísimas, como las luces
##            de un estadio vistas a través de una lente.
## El color lo pone la portada (`teñir`): cada variante tiñe su propia luz.

const TAM_TEX := 64

static var _halo: Texture2D = null
static var _disco: Texture2D = null

## Halo: núcleo casi blanco que se apaga en curva suave (una chispa).
static func _textura_halo() -> Texture2D:
	if _halo != null:
		return _halo
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.35, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.22), Color(1, 1, 1, 0.0)])
	_halo = _radial(g)
	return _halo

## Disco de bokeh: lleno y parejo, con el borde un poco más claro y un corte
## suave, que es como se ve una luz fuera de foco.
static func _textura_disco() -> Texture2D:
	if _disco != null:
		return _disco
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.7, 0.86, 0.95, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.25), Color(1, 1, 1, 0.0)])
	_disco = _radial(g)
	return _disco

static func _radial(g: Gradient) -> Texture2D:
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = TAM_TEX
	t.height = TAM_TEX
	return t

var tipo := "motas"

func _init(tipo_: String = "motas") -> void:
	tipo = tipo_
	## Luz que SUMA: donde se cruzan dos motas brilla más, como la luz real.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	emitting = true
	randomness = 0.8
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	gravity = Vector2.ZERO
	direction = Vector2(0, -1)
	if tipo == "bokeh":
		texture = _textura_disco()
		amount = 12
		lifetime = 16.0
		preprocess = 16.0
		spread = 40.0
		initial_velocity_min = 3.0
		initial_velocity_max = 11.0
		scale_amount_min = 0.9
		scale_amount_max = 2.6
		_curva_escala([Vector2(0, 0.85), Vector2(0.5, 1.0), Vector2(1, 0.9)])
		_rampa([0.0, 0.25, 0.75, 1.0], [0.0, 0.16, 0.16, 0.0])
		hue_variation_min = -0.04
		hue_variation_max = 0.04
	else:
		texture = _textura_halo()
		amount = 70
		lifetime = 9.0
		preprocess = 9.0
		spread = 14.0
		initial_velocity_min = 10.0
		initial_velocity_max = 34.0
		## Se mecen al subir: una órbita pequeña, a izquierda o derecha.
		orbit_velocity_min = -0.012
		orbit_velocity_max = 0.012
		## Deriva lateral, como polvo en una corriente de aire.
		tangential_accel_min = -4.0
		tangential_accel_max = 4.0
		scale_amount_min = 0.12
		scale_amount_max = 0.55
		## Titilan: la escala late tres veces en su vida y se apaga al final.
		_curva_escala([Vector2(0, 0.2), Vector2(0.15, 1.0), Vector2(0.3, 0.6), Vector2(0.45, 1.0),
			Vector2(0.62, 0.55), Vector2(0.8, 0.9), Vector2(1, 0.0)])
		_rampa([0.0, 0.12, 0.7, 1.0], [0.0, 0.7, 0.55, 0.0])
		hue_variation_min = -0.06
		hue_variation_max = 0.06

func _curva_escala(puntos: Array) -> void:
	var c := Curve.new()
	for p: Vector2 in puntos:
		c.add_point(p)
	scale_amount_curve = c

func _rampa(offs: Array, alfas: Array) -> void:
	var g := Gradient.new()
	var o := PackedFloat32Array()
	var cs := PackedColorArray()
	for i in offs.size():
		o.append(float(offs[i]))
		cs.append(Color(1, 1, 1, float(alfas[i])))
	g.offsets = o
	g.colors = cs
	color_ramp = g

## El color de la luz, el de la portada. Se mezcla con blanco para que las
## chispas sigan pareciendo luz y no confeti.
func tenir(c: Color) -> void:
	var destino := c.lerp(Color.WHITE, 0.45 if tipo == "motas" else 0.25)
	var tw := create_tween()
	tw.tween_property(self, "color", destino, 1.2)

## Se llama cuando ya se conoce el tamaño del área -antes de eso, `position`/
## `emission_rect_extents` se quedarían con cualquier valor y las motas
## nacerían todas en la esquina-.
func ajustar_area(tam: Vector2) -> void:
	position = tam / 2.0
	emission_rect_extents = tam / 2.0
