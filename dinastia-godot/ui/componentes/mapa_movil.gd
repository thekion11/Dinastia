class_name MapaMovil
extends Control
## EL GPS DEL MÓVIL (17-10-2026, M-178/M-179): un mapa pequeño dentro del móvil
## en la mano (nada de minimapa fijo en pantalla: la ciudad va sin HUD). Norte
## arriba, calles de la red vial, el río, el núcleo del club, tu casa y el
## estadio; la flecha eres tú y la línea dorada es la ruta al estadio por las
## calles (`CiudadExpansion.camino_entre`).

const RADIO := 280.0          ## metros que caben del centro al borde
var red: CiudadExpansion
var pos := Vector3.ZERO
var rumbo := 0.0
var _ruta: PackedVector2Array = []
var _t_ruta := 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(0, 118)

func poner(p: Vector3, r: float, delta: float) -> void:
	pos = p
	rumbo = r
	_t_ruta -= delta
	if _t_ruta <= 0.0:
		_t_ruta = 1.0
		_ruta = ruta_al_estadio(red, p)
	queue_redraw()

## La ruta por las calles: del cruce más cercano a ti al cruce de la red más
## cercano al estadio, y de ahí recto a la puerta. Vacía si ya estás cerca.
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

func _a_pantalla(x: float, z: float) -> Vector2:
	var esc := minf(size.x, size.y) * 0.5 / RADIO
	return size * 0.5 + Vector2(x - pos.x, z - pos.z) * esc

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.14, 0.12))
	var esc := minf(size.x, size.y) * 0.5 / RADIO
	## El núcleo del club (sus calles van aparte) y la finca de tu casa.
	var n0 := _a_pantalla(CiudadExpansion.NUC_X0, CiudadExpansion.NUC_Z0)
	var n1 := _a_pantalla(CiudadExpansion.NUC_X1, CiudadExpansion.NUC_Z1)
	draw_rect(Rect2(n0, n1 - n0), Color(0.16, 0.22, 0.18))
	var f := CiudadExpansion.FINCA_GRANDE
	var f0 := _a_pantalla(f.position.x, f.position.y)
	draw_rect(Rect2(f0, f.size * esc), Color(0.2, 0.36, 0.22))
	## El río.
	var rx := _a_pantalla(CityBuilder.RIO_X, 0).x
	draw_rect(Rect2(rx - 70.0 * esc, 0, 140.0 * esc, size.y), Color(0.16, 0.34, 0.5))
	## Las calles.
	if red != null:
		for t: Dictionary in red.tramos:
			var a: Vector3 = t["a"]
			var b: Vector3 = t["b"]
			var pa := _a_pantalla(a.x, a.z)
			var pb := _a_pantalla(b.x, b.z)
			if not Rect2(Vector2.ZERO, size).grow(20).has_point(pa) and not Rect2(Vector2.ZERO, size).grow(20).has_point(pb):
				continue
			draw_line(pa, pb, Color(0.62, 0.66, 0.62) if bool(t["av"]) else Color(0.4, 0.44, 0.41), 3.0 if bool(t["av"]) else 1.6)
	## La ruta al estadio.
	if _ruta.size() >= 2:
		var pts := PackedVector2Array()
		for q: Vector2 in _ruta:
			pts.append(_a_pantalla(q.x, q.y))
		draw_polyline(pts, Color(1.0, 0.8, 0.25), 2.5, true)
	## El estadio (aunque quede fuera: pegado al borde, como una brújula).
	var est := _a_pantalla(CityBuilder.ESTADIO_EN.x, CityBuilder.ESTADIO_EN.z)
	var c := size * 0.5
	var lim := minf(size.x, size.y) * 0.5 - 8.0
	if (est - c).length() > lim:
		est = c + (est - c).normalized() * lim
	draw_circle(est, 6.0, Color(1.0, 0.8, 0.25))
	draw_string(get_theme_default_font(), est + Vector2(-4, 4), "⚽", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.BLACK)
	## Tú: una flecha que mira hacia donde vas.
	var dir := Vector2(sin(rumbo), cos(rumbo))
	var lado := Vector2(-dir.y, dir.x)
	var punta := c + dir * 8.0
	draw_colored_polygon(PackedVector2Array([punta, c - dir * 5.0 + lado * 5.0, c - dir * 2.0, c - dir * 5.0 - lado * 5.0]), Color(0.35, 0.9, 0.6))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.15), false, 1.0)
