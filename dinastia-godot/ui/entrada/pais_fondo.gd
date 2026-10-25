class_name PaisFondo
extends Control
## EL FONDO DE LA PANTALLA DE PAÍS (fase 1, etapa 3): la bandera del país elegido
## ondeando a pantalla completa y, delante, uno de sus CINCO MONUMENTOS, que cambia
## cada 30 s con un fundido. Pedido del plan: «fondo con bandera y 5 monumentos que
## rotan cada 30 s».
##
## CAPAS, de atrás adelante: color base → bandera (dos, para fundir de un país a otro)
## → resplandor cálido detrás del monumento (sin él, una silueta oscura sobre una
## bandera oscurecida no se lee) → monumento (dos, para fundir de uno a otro) → viñeta
## y degradado inferior (para que la interfaz de encima se lea siempre).
##
## Las banderas son las de `Banderas` (dibujadas en código, las mismas del estudio del
## sorteo y la sala de prensa); los monumentos, siluetas de `PaisTrazo`. Nada sale de
## la red ni de imágenes con licencia.

## Se enseñó otro monumento (por tiempo o a mano): índice dentro de los cinco y nombre.
signal monumento_cambiado(indice: int, nombre: String)

const INTERVALO := 30.0
const FUNDIDO := 1.4
const SHADER := preload("res://ui/entrada/pais_bandera.gdshader")

var pais := ""
var indice := 0
## Dónde se planta el monumento (coordenadas de este control). La pone la pantalla; si
## no, ocupa la mitad inferior central.
var zona_monumento := Rect2()
## Las pruebas y capturas lo apagan: cambios instantáneos y bandera quieta.
var animar := true

var _t := 0.0
var _banderas: Array[TextureRect] = []
var _bandera_activa := 0
var _monumentos: Array[PaisMonumento] = []
var _mon_activo := 0
var _resplandor: TextureRect
var _caja_monumentos: Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = Tema.FONDO
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	for i in 2:
		var b := TextureRect.new()
		b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = SHADER
		b.material = m
		b.modulate.a = 0.0
		add_child(b)
		_banderas.append(b)
	_resplandor = TextureRect.new()
	_resplandor.texture = _degradado_radial(Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.0))
	_resplandor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_resplandor.stretch_mode = TextureRect.STRETCH_SCALE
	_resplandor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var suma := CanvasItemMaterial.new()
	suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_resplandor.material = suma
	add_child(_resplandor)
	_caja_monumentos = Control.new()
	_caja_monumentos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caja_monumentos)
	for i in 2:
		var mo := PaisMonumento.new()
		mo.modulate.a = 0.0
		_caja_monumentos.add_child(mo)
		_monumentos.append(mo)
	var vineta := TextureRect.new()
	vineta.texture = _degradado_radial(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.62), 0.35)
	vineta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vineta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vineta.stretch_mode = TextureRect.STRETCH_SCALE
	vineta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vineta)
	var pie := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.7))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	pie.texture = gt
	pie.anchor_left = 0.0
	pie.anchor_right = 1.0
	pie.anchor_top = 0.82
	pie.anchor_bottom = 1.0
	pie.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pie.stretch_mode = TextureRect.STRETCH_SCALE
	pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pie)
	resized.connect(_colocar)
	_colocar()

## Un degradado radial (centro → borde) en textura, para el resplandor y la viñeta.
static func _degradado_radial(centro: Color, borde: Color, desde := 0.0) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([desde, 1.0])
	g.colors = PackedColorArray([centro, borde])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5) if desde == 0.0 else Vector2(1.08, 1.08)
	t.width = 128
	t.height = 128
	return t

func fijar_zona(r: Rect2) -> void:
	zona_monumento = r
	_colocar()

func _colocar() -> void:
	if _caja_monumentos == null:
		return
	var z := zona_monumento
	if z.size.x <= 0.0:
		z = Rect2(size.x * 0.2, size.y * 0.45, size.x * 0.6, size.y * 0.5)
	_caja_monumentos.position = z.position
	_caja_monumentos.size = z.size
	for mo: PaisMonumento in _monumentos:
		mo.size = z.size
	## El resplandor nace del pie del monumento y sube: como un atardecer detrás.
	var r := Vector2(z.size.x * 1.25, z.size.y * 1.3)
	_resplandor.size = r
	_resplandor.position = Vector2(z.get_center().x - r.x * 0.5, z.end.y - r.y * 0.62)

func _process(delta: float) -> void:
	if pais == "" or not animar:
		return
	_t += delta
	if _t >= INTERVALO:
		_t = 0.0
		avanzar()

## Cambia de país: funde la bandera y vuelve al primer monumento.
func poner_pais(p: String) -> void:
	if p == pais:
		return
	pais = p
	indice = 0
	_t = 0.0
	var nueva := _banderas[1 - _bandera_activa]
	var vieja := _banderas[_bandera_activa]
	nueva.texture = Banderas.textura(p)
	(nueva.material as ShaderMaterial).set_shader_parameter("ola", 1.0 if animar else 0.0)
	_bandera_activa = 1 - _bandera_activa
	move_child(nueva, vieja.get_index())
	_fundir(nueva, 1.0, vieja, 0.0, FUNDIDO * 0.7)
	_resplandor.modulate = _color_resplandor(p)
	_mostrar()

## El siguiente de los cinco (lo llama el reloj de 30 s; la prueba también).
func avanzar() -> void:
	var n := PaisDatos.monumentos(pais).size()
	if n == 0:
		return
	indice = (indice + 1) % n
	_t = 0.0
	_mostrar()

func monumento_actual() -> Array:
	var lista := PaisDatos.monumentos(pais)
	return lista[indice] if indice < lista.size() else []

func segundos_para_el_siguiente() -> float:
	return maxf(0.0, INTERVALO - _t)

func silueta_visible() -> PaisMonumento:
	return _monumentos[_mon_activo]

func _mostrar() -> void:
	var m := monumento_actual()
	if m.is_empty():
		for mo: PaisMonumento in _monumentos:
			mo.modulate.a = 0.0
		return
	var nueva := _monumentos[1 - _mon_activo]
	var vieja := _monumentos[_mon_activo]
	nueva.poner(String(m[1]), String(m[2]))
	_mon_activo = 1 - _mon_activo
	nueva.position.y = 14.0 if animar else 0.0
	_fundir(nueva, 1.0, vieja, 0.0, FUNDIDO)
	if animar:
		nueva.create_tween().tween_property(nueva, "position:y", 0.0, FUNDIDO) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	monumento_cambiado.emit(indice, String(m[0]))

func _fundir(entra: CanvasItem, a_entra: float, sale: CanvasItem, a_sale: float, dur: float) -> void:
	if not animar or not is_inside_tree():
		entra.modulate.a = a_entra
		sale.modulate.a = a_sale
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(entra, "modulate:a", a_entra, dur)
	tw.tween_property(sale, "modulate:a", a_sale, dur)

## El resplandor toma el color medio de la bandera, calentado hacia el oro del juego
## (el rojo y blanco de Chile dan un rosado que, solo, se ve sucio).
func _color_resplandor(p: String) -> Color:
	var img := Banderas.textura(p).get_image()
	var suma := Color(0, 0, 0)
	var n := 0
	for y in range(0, img.get_height(), 4):
		for x in range(0, img.get_width(), 4):
			var c := img.get_pixel(x, y)
			suma += c
			n += 1
	var medio := Color(suma.r / n, suma.g / n, suma.b / n)
	var c := medio.lerp(Color("ffcf7a"), 0.55)
	return Color(c.r, c.g, c.b, 0.5)
