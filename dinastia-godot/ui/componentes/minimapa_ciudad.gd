class_name MinimapaCiudad
extends Control
## EL GPS DE LA CIUDAD, ESTILO GTA (17-10-2026, M-178/M-179; pedido del dueño:
## «el GPS debe ser en 2D, estilo GTA, y verse mejor»). Minimapa abajo a la
## izquierda que GIRA con tu rumbo (lo de delante siempre arriba), sin textos:
## calles con borde, río, parques, el núcleo del club, la ruta morada al
## estadio por las calles (`CiudadExpansion.camino_entre`) y marcas pegadas al
## borde cuando quedan lejos (estadio, casa) y la N del norte. M lo esconde.

const RADIO := 230.0           ## metros del centro al borde corto
const C_SUELO := Color(0.24, 0.28, 0.26)
const C_MANZANA := Color(0.30, 0.34, 0.32)
const C_CALLE := Color(0.86, 0.87, 0.85)
const C_AVENIDA := Color(0.97, 0.97, 0.95)
const C_BORDE_CALLE := Color(0.12, 0.13, 0.13)
const C_AGUA := Color(0.28, 0.52, 0.74)
const C_VERDE := Color(0.33, 0.52, 0.30)
const C_RUTA := Color(0.72, 0.36, 0.95)
const C_ESTADIO := Color(1.0, 0.78, 0.22)
const C_CASA := Color(0.35, 0.85, 0.55)

var red: CiudadExpansion
var pos := Vector3.ZERO
var rumbo := 0.0
var _rumbo_suave := 0.0
var _ruta: PackedVector2Array = []
var _t_ruta := 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 24
	offset_right = 24 + 300
	offset_top = -24 - 190
	offset_bottom = -24

## Arriba a la izquierda (cuando abajo están los botones táctiles).
func arriba() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 24
	offset_right = 24 + 300
	offset_top = 24
	offset_bottom = 24 + 190

func poner(p: Vector3, r: float, delta: float) -> void:
	pos = p
	rumbo = r
	_rumbo_suave = lerp_angle(_rumbo_suave, r, clampf(delta * 4.0, 0.0, 1.0))
	_t_ruta -= delta
	if _t_ruta <= 0.0:
		_t_ruta = 1.0
		_ruta = ruta_al_estadio(red, p)
	if _lienzo != null:
		_lienzo.queue_redraw()

## La ruta por las calles: del cruce más cercano a ti al cruce de la red más
## cercano al estadio, y de ahí a la puerta. Vacía si ya estás cerca.
static func ruta_al_estadio(e: CiudadExpansion, p: Vector3) -> PackedVector2Array:
	var r := PackedVector2Array()
	var meta := CityBuilder.ESTADIO_EN
	if e == null or Vector2(p.x - meta.x, p.z - meta.z).length() < 120.0:
		return r
	var ka := _cruce_cercano(e, Vector2(p.x, p.z))
	var kb := _cruce_cercano(e, Vector2(meta.x, meta.z))
	r.append(Vector2(p.x, p.z))
	if ka != kb:
		for k: Vector2i in e.camino_entre(ka, kb):
			var n: Vector3 = e.nodos[k]
			r.append(Vector2(n.x, n.z))
	r.append(Vector2(meta.x, meta.z))
	return r

static func _cruce_cercano(e: CiudadExpansion, p: Vector2) -> Vector2i:
	var mejor := Vector2i.ZERO
	var d := INF
	for k: Vector2i in e.vecinos:
		var n: Vector3 = e.nodos[k]
		var dd := Vector2(n.x, n.z).distance_squared_to(p)
		if dd < d:
			d = dd
			mejor = k
	return mejor

func _esc() -> float:
	return minf(size.x, size.y) * 0.5 / RADIO

## Del mundo (x, z) a la pantalla: centrado en ti y girado para que lo de
## delante quede arriba. El jugador va algo por debajo del centro (como GTA).
func _a_pantalla(x: float, z: float) -> Vector2:
	var d := Vector2(x - pos.x, z - pos.z).rotated(_rumbo_suave - PI) * _esc()
	return _centro() + d

func _centro() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.62)

func _poligono_mundo(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([_a_pantalla(x0, z0), _a_pantalla(x1, z0), _a_pantalla(x1, z1), _a_pantalla(x0, z1)])

var _lienzo: Control

## Lo dibujado no sale del marco: se pinta en un hijo y este control recorta.
class Lienzo extends Control:
	var mapa: MinimapaCiudad
	func _draw() -> void:
		mapa._pintar(self)

func _ready() -> void:
	clip_contents = true
	_lienzo = Lienzo.new()
	_lienzo.mapa = self
	_lienzo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lienzo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_lienzo)

func _pintar(l: Control) -> void:
	var caja := Rect2(Vector2.ZERO, size)
	l.draw_rect(caja, C_SUELO)
	var esc := _esc()
	## El núcleo del club y la finca de tu casa.
	l.draw_colored_polygon(_poligono_mundo(CiudadExpansion.NUC_X0, CiudadExpansion.NUC_Z0, CiudadExpansion.NUC_X1, CiudadExpansion.NUC_Z1), C_MANZANA)
	var f := CiudadExpansion.FINCA_GRANDE
	l.draw_colored_polygon(_poligono_mundo(f.position.x, f.position.y, f.end.x, f.end.y), C_VERDE)
	## El río (franja de norte a sur).
	l.draw_colored_polygon(_poligono_mundo(CityBuilder.RIO_X - 70.0, pos.z - 2000.0, CityBuilder.RIO_X + 70.0, pos.z + 2000.0), C_AGUA)
	## Las calles: primero el borde oscuro, luego el relleno claro.
	if red != null:
		var vis := caja.grow(30)
		var lineas: Array = []
		for t: Dictionary in red.tramos:
			var a: Vector3 = t["a"]
			var b: Vector3 = t["b"]
			var pa := _a_pantalla(a.x, a.z)
			var pb := _a_pantalla(b.x, b.z)
			if not vis.has_point(pa) and not vis.has_point(pb):
				continue
			lineas.append([pa, pb, bool(t["av"])])
		for li: Array in lineas:
			var w := (16.0 if bool(li[2]) else 10.0) * esc
			l.draw_line(li[0], li[1], C_BORDE_CALLE, maxf(w + 2.5, 3.5))
		for li: Array in lineas:
			var w2 := (16.0 if bool(li[2]) else 10.0) * esc
			l.draw_line(li[0], li[1], C_AVENIDA if bool(li[2]) else C_CALLE, maxf(w2, 2.0))
	## La ruta al estadio, gruesa y con borde (como el GPS de GTA).
	if _ruta.size() >= 2:
		var pts := PackedVector2Array()
		for q: Vector2 in _ruta:
			pts.append(_a_pantalla(q.x, q.y))
		l.draw_polyline(pts, Color(0.18, 0.05, 0.25), 6.5, true)
		l.draw_polyline(pts, C_RUTA, 4.0, true)
	## Marcas: el estadio y tu casa (pegadas al borde si quedan fuera).
	_marca(l, CityBuilder.ESTADIO_EN.x, CityBuilder.ESTADIO_EN.z, C_ESTADIO, "estadio")
	_marca(l, f.get_center().x, f.get_center().y, C_CASA, "casa")
	## La N del norte, en el borde.
	var norte := _al_borde(_centro() + Vector2(0, -1).rotated(_rumbo_suave - PI) * 1000.0, 11.0)
	l.draw_circle(norte, 9.0, Color(0.1, 0.1, 0.1, 0.85))
	_texto_centrado(l, norte, "N", Color.WHITE, 12)
	## Tú: flecha blanca con borde, siempre hacia arriba (el mapa gira).
	var c := _centro()
	var gi := rumbo - _rumbo_suave
	var dir := Vector2(0, -1).rotated(-gi)
	var lado := Vector2(-dir.y, dir.x)
	var flecha := PackedVector2Array([c + dir * 10.0, c - dir * 7.0 + lado * 7.0, c - dir * 3.0, c - dir * 7.0 - lado * 7.0])
	var borde := PackedVector2Array()
	for q: Vector2 in flecha:
		borde.append(c + (q - c) * 1.35)
	l.draw_colored_polygon(borde, Color(0, 0, 0, 0.8))
	l.draw_colored_polygon(flecha, Color.WHITE)
	## Marco.
	l.draw_rect(caja.grow(-1.5), Color(0.05, 0.05, 0.05), false, 3.0)
	l.draw_rect(caja.grow(-4), Color(1, 1, 1, 0.12), false, 1.0)

func _al_borde(p: Vector2, margen: float) -> Vector2:
	var caja := Rect2(Vector2.ZERO, size).grow(-margen)
	if caja.has_point(p):
		return p
	var c := _centro()
	var d := p - c
	var tx := INF
	var ty := INF
	if absf(d.x) > 0.001:
		tx = ((caja.end.x if d.x > 0 else caja.position.x) - c.x) / d.x
	if absf(d.y) > 0.001:
		ty = ((caja.end.y if d.y > 0 else caja.position.y) - c.y) / d.y
	return c + d * minf(tx, ty)

func _marca(l: Control, x: float, z: float, col: Color, tipo: String) -> void:
	var p := _al_borde(_a_pantalla(x, z), 12.0)
	l.draw_circle(p, 10.0, Color(0, 0, 0, 0.8))
	l.draw_circle(p, 8.0, col)
	if tipo == "estadio":
		## Un balón: círculo blanco con el centro oscuro.
		l.draw_circle(p, 4.0, Color.WHITE)
		l.draw_circle(p, 1.6, Color(0.1, 0.1, 0.1))
	else:
		## Una casa: tejado y cuerpo.
		l.draw_colored_polygon(PackedVector2Array([p + Vector2(-4.5, -0.5), p + Vector2(0, -5), p + Vector2(4.5, -0.5)]), Color.WHITE)
		l.draw_rect(Rect2(p + Vector2(-3, -0.5), Vector2(6, 4.5)), Color.WHITE)

func _texto_centrado(l: Control, p: Vector2, t: String, col: Color, tam: int) -> void:
	var fuente := l.get_theme_default_font()
	var w := fuente.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
	l.draw_string(fuente, p + Vector2(-w.x * 0.5, w.y * 0.32), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
