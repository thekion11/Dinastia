class_name MapaTransporte
extends Control
## EL MAPA DEL TRANSPORTE PÚBLICO (27-10-2026, pedido del dueño): plano de la ciudad con tres vistas que se cambian con N en la calle:
##  0 · COMPLETO: calles, río, barrios, edificios clave y todas las líneas (metro, autobús y teleférico);
##  1 · AUTOBUSES: solo las líneas de autobús con su NÚMERO, sus paradas y el recorrido;
##  2 · METRO: solo las dos líneas con todas sus estaciones por su nombre.
## Se dibuja a mano (como `PanelMando`) con los datos reales de `CiudadExpansion` (calles, bloques, líneas) y de `MetroCiudad`.
## `teleferico` ({nombre, base, cima, color}) lo rellena `Teleferico` cuando existe.

const NOMBRES_MODO := ["MAPA COMPLETO DEL TRANSPORTE", "RED DE AUTOBUSES", "RED DE METRO"]
const FONDO := Color(0.06, 0.09, 0.12)
const TIERRA := Color(0.11, 0.15, 0.18)
const AGUA := Color(0.12, 0.3, 0.45)
const TEXTO := Color(0.88, 0.93, 0.96)
const GRIS := Color(0.5, 0.58, 0.62)
const LIMITE := 1400.0
const ANILLO_X := 205.0
const ANILLO_Z0 := -320.0
const ANILLO_Z1 := 350.0
const COLOR_BARRIO := {"torres": Color(0.3, 0.34, 0.42), "comercial": Color(0.38, 0.33, 0.25), "pisos": Color(0.27, 0.28, 0.33),
	"casas": Color(0.24, 0.33, 0.26), "industrial": Color(0.34, 0.28, 0.24), "lejano": Color(0.16, 0.2, 0.23)}
## El color de cada línea de autobús por su número (lo usan el mapa y los autobuses de la calle).
const COLOR_LINEA := {"5": Color(0.95, 0.75, 0.15), "10": Color(0.9, 0.25, 0.2), "22": Color(0.2, 0.5, 0.95), "7": Color(0.2, 0.7, 0.4), "3": Color(0.65, 0.35, 0.85)}

static func color_linea(numero: String) -> Color:
	return COLOR_LINEA.get(numero, Color(0.7, 0.7, 0.7))
const CLAVES := {"hospital": "Hospital", "ayuntamiento": "Ayuntamiento", "universidad": "Universidad", "estacion_central": "Estación Central",
	"centro_comercial": "C. Comercial", "puerto": "Puerto", "feria": "Feria", "cocheras": "Cocheras"}

var ex: CiudadExpansion
var modo := 0
var teleferico: Dictionary = {}
var _lado := 600.0
var _origen := Vector2.ZERO
var _ocupado: Array[Rect2] = []   ## etiquetas ya puestas (para que no se pisen)

static func crear(e: CiudadExpansion, m: int = 0) -> MapaTransporte:
	var c := MapaTransporte.new()
	c.ex = e
	c.modo = m
	c.teleferico = e.get("teleferico") if e.get("teleferico") != null else {}
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

## N en la calle: abre el mapa, y cada pulsación más cambia de vista (completo → autobuses → metro → cerrar).
static func alternar(explorador) -> void:
	var capa: CanvasLayer = explorador._capa
	var viejo := capa.get_node_or_null("MapaTransporte") as MapaTransporte
	if viejo == null:
		if explorador.cb == null or explorador.cb.expansion == null:
			return
		var nuevo := MapaTransporte.crear(explorador.cb.expansion, 0)
		nuevo.name = "MapaTransporte"
		capa.add_child(nuevo)
	elif viejo.modo >= 2:
		viejo.queue_free()
	else:
		viejo.modo += 1
		viejo.queue_redraw()

static func cerrar(explorador) -> bool:
	var viejo := (explorador._capa as CanvasLayer).get_node_or_null("MapaTransporte")
	if viejo == null:
		return false
	viejo.queue_free()
	return true

func _p(v: Vector3) -> Vector2:
	return _origen + Vector2((v.x + LIMITE) / (LIMITE * 2.0), (v.z + LIMITE) / (LIMITE * 2.0)) * _lado

func _t(p: Vector2, texto: String, tam: int = 15, col: Color = TEXTO, ancho: float = -1.0, alinea: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font, p, texto, alinea, ancho, tam, col)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	if ex == null:
		return
	_lado = minf(size.y - 90.0, size.x - 400.0)
	_origen = Vector2(30.0, 70.0)
	draw_rect(Rect2(0, 0, size.x, 52), Color(0.03, 0.12, 0.16))
	draw_rect(Rect2(0, 50, size.x, 2), Color(0.45, 0.9, 1.0))
	_t(Vector2(24, 35), NOMBRES_MODO[modo], 26, Color(0.45, 0.9, 1.0))
	_t(Vector2(size.x - 24, 35), "N: cambiar de vista · Esc: cerrar", 16, GRIS, 400.0, HORIZONTAL_ALIGNMENT_RIGHT)
	_base()
	if modo != 2:
		_autobuses()
	if modo != 1:
		_metro()
	if modo == 0:
		_teleferico()
		_hitos()
	_leyenda()

# ============================================================================ BASE

func _base() -> void:
	var tenue := modo != 0
	draw_rect(Rect2(_origen, Vector2(_lado, _lado)), TIERRA)
	var a := _p(Vector3(CityBuilder.RIO_X - 50.0, 0, -LIMITE))
	var b := _p(Vector3(CityBuilder.RIO_X + 50.0, 0, LIMITE))
	draw_rect(Rect2(a, b - a), AGUA if not tenue else AGUA.darkened(0.4))
	for bl: Dictionary in ex.bloques:
		var r: Rect2 = bl["rect"]
		var uso := String(bl["uso"])
		var col: Color = COLOR_BARRIO.get(uso, Color(0.28, 0.38, 0.3) if uso.begins_with("parque") else Color(0.45, 0.42, 0.34))
		if tenue:
			col = col.darkened(0.35)
		var p0 := _p(Vector3(r.position.x, 0, r.position.y))
		var p1 := _p(Vector3(r.end.x, 0, r.end.y))
		draw_rect(Rect2(p0, p1 - p0), col)
	for t: Dictionary in ex.tramos:
		if bool(t["puente"]):
			continue
		draw_line(_p(t["a"]), _p(t["b"]), Color(0.62, 0.65, 0.68, 0.55 if not tenue else 0.25), 2.2 if bool(t["av"]) else 1.0)
	draw_rect(Rect2(_origen, Vector2(_lado, _lado)), Color(0.3, 0.4, 0.45), false, 2.0)

func _hitos() -> void:
	_ocupado.clear()
	var estadio := _p(CityBuilder.ESTADIO_EN)
	draw_rect(Rect2(estadio - Vector2(6, 4), Vector2(12, 8)), Color(0.2, 0.9, 0.4))
	_t(estadio + Vector2(9, 5), "Estadio", 13)
	var vistos := {}
	for bl: Dictionary in ex.bloques:
		var uso := String(bl["uso"])
		if CLAVES.has(uso) and not vistos.has(uso):
			vistos[uso] = true
			var r: Rect2 = bl["rect"]
			var p := _p(Vector3(r.get_center().x, 0, r.get_center().y))
			draw_circle(p, 3.5, Color(0.95, 0.95, 0.9))
			var pos := p + Vector2(6, 4)
			var ancho := ThemeDB.fallback_font.get_string_size(String(CLAVES[uso]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var caja := Rect2(pos - Vector2(0, 12), Vector2(ancho, 14))
			for q: Rect2 in _ocupado:
				if q.intersects(caja):
					pos.y += 16.0
					caja = Rect2(pos - Vector2(0, 12), Vector2(ancho, 14))
			_ocupado.append(caja)
			_t(pos, String(CLAVES[uso]), 12, Color(0.85, 0.88, 0.9))

# ============================================================================ LÍNEAS

func _poli(pts: PackedVector3Array, col: Color, ancho: float, cerrada: bool = true) -> void:
	var n := pts.size()
	for i in (n if cerrada else n - 1):
		draw_line(_p(pts[i]), _p(pts[(i + 1) % n]), col, ancho, true)

func _insignia(p: Vector2, texto: String, col: Color) -> void:
	draw_circle(p, 13.0, Color.WHITE)
	draw_circle(p, 11.0, col)
	_t(p + Vector2(-14, 6), texto, 16 if texto.length() < 2 else 13, Color.WHITE, 28.0, HORIZONTAL_ALIGNMENT_CENTER)

func _rutas_bus() -> Array:
	var anillo := PackedVector3Array([Vector3(ANILLO_X, 0, ANILLO_Z0), Vector3(ANILLO_X, 0, ANILLO_Z1), Vector3(-ANILLO_X, 0, ANILLO_Z1), Vector3(-ANILLO_X, 0, ANILLO_Z0)])
	var paradas_anillo: Array = ex.b.paradas_bus_pos if ex.b != null and not ex.b.paradas_bus_pos.is_empty() else [
		Vector3(ANILLO_X - 13.0, 0, -170.0), Vector3(-ANILLO_X + 13.0, 0, 110.0), Vector3(ANILLO_X - 13.0, 0, 140.0), Vector3(CityBuilder.BARRIO_EN.x + 13.0, 0, ANILLO_Z1 + 60.0)]
	var r: Array = [{"numero": "5", "destino": "Estadio · Anillo", "puntos": anillo, "paradas": paradas_anillo, "color": color_linea("5")}]
	for l: Dictionary in ex.lineas_bus:
		var num := String(l["nombre"]).get_slice(" ", 1)
		r.append({"numero": num, "destino": String(l.get("destino", "Circular")).capitalize(), "puntos": l["puntos"], "paradas": l["paradas"], "color": color_linea(num)})
	return r

func _autobuses() -> void:
	var fuerte := modo == 1
	for l: Dictionary in _rutas_bus():
		var col: Color = l["color"]
		var pts: PackedVector3Array = l["puntos"]
		_poli(pts, col.darkened(0.0 if fuerte else 0.15), 5.0 if fuerte else 2.6)
		for p: Vector3 in l["paradas"]:
			var q := _p(p)
			draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), Color.WHITE)
			draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), col)
		if pts.size() > 3:
			for f: float in [0.08, 0.4, 0.72]:
				_insignia(_p(pts[int(float(pts.size()) * f)]), String(l["numero"]), col)

func _metro() -> void:
	var fuerte := modo == 2
	for l: Dictionary in ex.lineas_metro:
		var col: Color = l["color"]
		var est: Array = l["estaciones"]
		var a := Vector3(est[0]) + (Vector3(est[0]) - Vector3(est[1])).normalized() * 220.0
		var c := Vector3(est[est.size() - 1]) + (Vector3(est[est.size() - 1]) - Vector3(est[est.size() - 2])).normalized() * 220.0
		var linea := PackedVector3Array([a])
		for e: Vector3 in est:
			linea.append(e)
		linea.append(c)
		## Subterránea: punteada; elevada: continua.
		if bool(l["elevada"]):
			_poli(linea, col, 7.0 if fuerte else 4.5, false)
		else:
			for i in linea.size() - 1:
				var p0 := _p(linea[i])
				var p1 := _p(linea[i + 1])
				var n := int(p0.distance_to(p1) / 12.0)
				for k in n:
					if k % 2 == 0:
						draw_line(p0.lerp(p1, float(k) / float(n)), p0.lerp(p1, float(k + 1) / float(n)), col, 7.0 if fuerte else 4.5)
		var nombres: Array = MetroCiudad.NOMBRES.get(String(l["nombre"]), [])
		for i in est.size():
			var q := _p(est[i])
			draw_circle(q, 7.0, Color.WHITE)
			draw_circle(q, 4.5, col)
			if fuerte and i < nombres.size():
				var horizontal := absf(float((est[1] as Vector3).x - (est[0] as Vector3).x)) > absf(float((est[1] as Vector3).z - (est[0] as Vector3).z))
				var d := Vector2(-30, -14 if i % 2 == 0 else 24) if horizontal else Vector2(10, -6)
				_t(q + d, String(nombres[i]), 14)
		_insignia(_p(a) + Vector2(0, 0), String(l["nombre"]).right(1), col)
		_insignia(_p(c), String(l["nombre"]).right(1), col)

func _teleferico() -> void:
	if teleferico.is_empty():
		return
	## El cerro queda fuera del plano de la ciudad: se dibuja la estación de abajo y una flecha hacia la cima.
	var col: Color = teleferico.get("color", Color(0.95, 0.6, 0.1))
	var base: Vector3 = teleferico["base"]
	var cima: Vector3 = teleferico["cima"]
	var a := _p(Vector3(minf(base.x, LIMITE - 20.0), 0, base.z))
	var dir := Vector2(cima.x - base.x, cima.z - base.z)
	var b2 := a + dir.normalized() * 70.0
	draw_line(a, b2, col, 4.0, true)
	draw_line(b2, b2 + (-dir.normalized()).rotated(0.45) * 14.0, col, 4.0, true)
	draw_line(b2, b2 + (-dir.normalized()).rotated(-0.45) * 14.0, col, 4.0, true)
	draw_circle(a, 7.0, Color.WHITE)
	draw_circle(a, 4.5, col)
	_insignia(a + Vector2(-26, -4), "T", col)
	_t(b2 + Vector2(8, 16), "Cerro (%.1f km al SE)" % (dir.length() / 1000.0), 13)

# ============================================================================ LEYENDA

func _leyenda() -> void:
	var x := _origen.x + _lado + 30.0
	var y := 90.0
	if modo != 2:
		_t(Vector2(x, y), "AUTOBUSES", 18, Color(0.45, 0.9, 1.0))
		y += 12.0
		for l: Dictionary in _rutas_bus():
			y += 30.0
			_insignia(Vector2(x + 14.0, y - 5.0), String(l["numero"]), l["color"])
			_t(Vector2(x + 36.0, y), "%s · %d paradas" % [String(l["destino"]), (l["paradas"] as Array).size()], 15)
		y += 36.0
	if modo != 1:
		_t(Vector2(x, y), "METRO", 18, Color(0.45, 0.9, 1.0))
		y += 12.0
		for l: Dictionary in ex.lineas_metro:
			y += 30.0
			_insignia(Vector2(x + 14.0, y - 5.0), String(l["nombre"]).right(1), l["color"])
			_t(Vector2(x + 36.0, y), "%s · %s · %d estaciones" % [String(l["nombre"]), "elevada" if bool(l["elevada"]) else "subterránea", (l["estaciones"] as Array).size()], 15)
		y += 36.0
	if modo == 0 and not teleferico.is_empty():
		_t(Vector2(x, y), "TELEFÉRICO", 18, Color(0.45, 0.9, 1.0))
		y += 30.0
		_insignia(Vector2(x + 14.0, y - 5.0), "T", teleferico.get("color", Color(0.95, 0.6, 0.1)))
		var desnivel := float((teleferico["cima"] as Vector3).y - (teleferico["base"] as Vector3).y)
		_t(Vector2(x + 36.0, y), "%s · +%d m" % [String(teleferico.get("nombre", "Teleférico del Cerro")), roundi(desnivel)], 15)
		y += 36.0
	_t(Vector2(x, size.y - 60.0), "● estación   ■ parada   ┅ subterránea   ━ elevada", 14, GRIS)
	_t(Vector2(x, size.y - 36.0), "Transbordo en el cruce de las líneas 1 y 2.", 14, GRIS)
