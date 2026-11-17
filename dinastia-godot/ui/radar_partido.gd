class_name RadarPartido
extends Control

## Radar / Minimapa 2D del terreno de juego estilo TV / FC 26.
## Muestra las posiciones en tiempo real de los 22 jugadores, árbitros y el balón.
## (17-11, puntos 6 y 8 de la comparación con FC Mobile) ORIENTADO COMO LA CÁMARA DE TV: el largo del campo va a lo ancho (el arco de
## −z a la derecha, como se ve desde la tribuna de +x) y la banda de la cámara abajo. El campo va DIBUJADO (contorno, medio campo,
## círculo central y las dos áreas de cada arco) sobre un fondo semitransparente, y cada jugador es un TRIÁNGULO que apunta hacia
## donde mira, del color fuerte de su club (`HudTV`); el que manejas, más grande y con borde blanco. Va abajo al centro (`HudTV`).
## BARATO: el campo se pinta UNA vez en una textura (antes eran 7 líneas suaves `TrazoSuave` y un fondo: una llamada cada una) y los
## triángulos son primitivas, que Godot agrupa en una sola llamada (los círculos con suavizado de antes costaban dos por jugador).

const LARGO_CAMPO := 105.0
const ANCHO_CAMPO := 68.0
## Medidas reglamentarias de las áreas (m): grande 16,5 × 40,32; chica 5,5 × 18,32.
const AREA := Vector2(16.5, 40.32)
const AREA_CHICA := Vector2(5.5, 18.32)
const FONDO := Color(0.03, 0.09, 0.05, 0.5)
const LINEA := Color(1, 1, 1, 0.45)

var jugadores: Array = []
var balon: Node3D = null
var jugador_activo: Node3D = null
## (17-11) Con el motor jugable, el que manejas sale de `motor.usuario` (si no, de `jugador_activo`, el control con guion).
var motor: Node = null
var escala := 1.0
var color_local := Color("3fa06a")
var color_visita := Color("e05555")
var campo: ImageTexture   ## el campo pintado (se rehace solo si cambia el tamaño)
var _ult_puntos: Array = []   ## (28-10) posiciones (al cm) y tamaño del último dibujo: si nada se movió, no se redibuja

func setup(all_players: Array, ball_node: Node3D, c_local: Color = Color("3fa06a"), c_visita: Color = Color("e05555")) -> void:
	jugadores = all_players
	balon = ball_node
	color_local = c_local
	color_visita = c_visita
	custom_minimum_size = Vector2(210, 136)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func actualizar_datos(all_players: Array = [], _ball_pos: Vector3 = Vector3.ZERO, _act_pos: Vector3 = Vector3.ZERO) -> void:
	if not all_players.is_empty():
		jugadores = all_players
	queue_redraw()

## Del campo 3D (x de −34 a +34, z de −52,5 a +52,5) al radar, orientado como la TV.
func a_radar(p: Vector3) -> Vector2:
	var u := clampf((LARGO_CAMPO * 0.5 - p.z) / LARGO_CAMPO, 0.02, 0.98)
	var v := clampf((p.x + ANCHO_CAMPO * 0.5) / ANCHO_CAMPO, 0.02, 0.98)
	return Vector2(u * size.x, v * size.y)

## También al estar listo: si las anclas le dan su tamaño antes de entrar al árbol, Godot no avisa del cambio (hasta el 17-11 el
## radar se quedaba así sin fondo ni líneas, solo con los puntos).
func _notification(que: int) -> void:
	if que == NOTIFICATION_RESIZED or (que == NOTIFICATION_READY and campo == null):
		campo = pintar_campo(Vector2i(size)) if size.x >= 8.0 and size.y >= 8.0 else null
		queue_redraw()

## El campo en una imagen: fondo, contorno, medio campo, círculo central y las dos áreas de cada arco.
static func pintar_campo(t: Vector2i) -> ImageTexture:
	var img := Image.create(t.x, t.y, false, Image.FORMAT_RGBA8)
	img.fill(FONDO)
	var w := float(t.x)
	var h := float(t.y)
	var g := maxi(1, int(round(h / 110.0)))   ## grosor de las líneas (1 px en el de PC; más en el del móvil)
	_marco(img, Rect2i(0, 0, t.x, t.y), g + 1, Color(1, 1, 1, 0.6))
	img.fill_rect(Rect2i(t.x / 2 - g / 2, 0, g, t.y), _sobre(FONDO, LINEA))
	for lado in 2:
		for med: Vector2 in [AREA, AREA_CHICA]:
			var aw := int(round(w * med.x / LARGO_CAMPO))
			var ah := int(round(h * med.y / ANCHO_CAMPO))
			_marco(img, Rect2i(0 if lado == 0 else t.x - aw, (t.y - ah) / 2, aw, ah), g, LINEA)
	## El círculo central, con borde suave (cobertura por distancia).
	var c := Vector2(w * 0.5, h * 0.5)
	var r := h * 9.15 / ANCHO_CAMPO
	var tinta := _sobre(FONDO, LINEA)
	for y in range(int(c.y - r) - 2, int(c.y + r) + 3):
		for x in range(int(c.x - r) - 2, int(c.x + r) + 3):
			if x < 0 or y < 0 or x >= t.x or y >= t.y:
				continue
			var d := absf(Vector2(x + 0.5, y + 0.5).distance_to(c) - r)
			var a := clampf(g * 0.5 + 0.5 - d, 0.0, 1.0)
			if a > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(tinta, a))
	return ImageTexture.create_from_image(img)

static func _marco(img: Image, r: Rect2i, g: int, col: Color) -> void:
	var c := _sobre(FONDO, col)
	img.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, g), c)
	img.fill_rect(Rect2i(r.position.x, r.end.y - g, r.size.x, g), c)
	img.fill_rect(Rect2i(r.position.x, r.position.y, g, r.size.y), c)
	img.fill_rect(Rect2i(r.end.x - g, r.position.y, g, r.size.y), c)

## Una línea translúcida sobre el fondo translúcido (la imagen no mezcla sola).
static func _sobre(fondo: Color, l: Color) -> Color:
	var a := l.a + fondo.a * (1.0 - l.a)
	var rgb := (Vector3(l.r, l.g, l.b) * l.a + Vector3(fondo.r, fondo.g, fondo.b) * fondo.a * (1.0 - l.a)) / maxf(a, 0.001)
	return Color(rgb.x, rgb.y, rgb.z, a)

## (La Ruta) siempre llevas a tu jugador: es el resaltado aunque el motor no tenga el equipo en tus manos.
var siempre_usuario := false

func _activo() -> Node3D:
	if motor != null and is_instance_valid(motor) and (siempre_usuario or int(motor.get("control_equipo")) >= 0):
		var u: Dictionary = motor.get("usuario")
		if not u.is_empty() and is_instance_valid(u.get("node")):
			return u["node"]
	return jugador_activo

func _process(_delta: float) -> void:
	if not visible:
		return
	var puntos: Array = [size, _activo()]
	for p in jugadores:
		var node: Node3D = p.get("node")
		if is_instance_valid(node):
			var g := node.global_position
			puntos.append(Vector3i(int(g.x * 100.0), int(g.z * 100.0), int(node.rotation.y * 20.0)))
	if is_instance_valid(balon):
		puntos.append(Vector2i(int(balon.global_position.x * 100.0), int(balon.global_position.z * 100.0)))

	if puntos != _ult_puntos:
		_ult_puntos = puntos
		queue_redraw()

## Un triángulo que apunta a `d` (en el radar), de «radio» `r`.
func _triangulo(c: Vector2, d: Vector2, r: float, col: Color) -> void:
	var p := Vector2(-d.y, d.x)
	var pts := PackedVector2Array([c + d * r * 1.25, c - d * r * 0.75 + p * r * 0.85, c - d * r * 0.75 - p * r * 0.85])
	draw_primitive(pts, PackedColorArray([col, col, col]), PackedVector2Array())

## Un rombo como dos triángulos: las primitivas de 3 puntos se agrupan con las de los jugadores (las de 4 abrían otra llamada).
func _rombo(c: Vector2, r: float, col: Color) -> void:
	var cs := PackedColorArray([col, col, col])
	draw_primitive(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(-r, 0)]), cs, PackedVector2Array())
	draw_primitive(PackedVector2Array([c + Vector2(0, r), c + Vector2(r, 0), c + Vector2(-r, 0)]), cs, PackedVector2Array())

## Hacia dónde mira un jugador, en el radar (el motor gira el nodo: adelante = (sin y, 0, cos y)).
static func mira_en_radar(n: Node3D) -> Vector2:
	var f := Vector3(sin(n.rotation.y), 0.0, cos(n.rotation.y))
	return Vector2(-f.z, f.x * (ANCHO_CAMPO / LARGO_CAMPO)).normalized()

func _draw() -> void:
	if campo != null:
		draw_texture_rect(campo, Rect2(Vector2.ZERO, size), false)
	var e := escala
	var activo := _activo()
	var borde := Color(0, 0, 0, 0.6)
	var ultimo: Array = []
	for p in jugadores:
		var node: Node3D = p.get("node")
		if not is_instance_valid(node):
			continue
		var pt := a_radar(node.global_position)
		if bool(p.get("arbitro", false)):
			_rombo(pt, 2.6 * e, Color(0.95, 0.85, 0.2))
			continue
		var col := color_local if bool(p.get("es_local", true)) else color_visita
		var d := mira_en_radar(node)
		if node == activo:
			ultimo = [pt, d, col]
			continue
		_triangulo(pt, d, 4.6 * e, borde)
		_triangulo(pt, d, 3.4 * e, col)
	## El que manejas, encima de todos: más grande y con borde blanco.
	if not ultimo.is_empty():
		_triangulo(ultimo[0], ultimo[1], 7.2 * e, Color(1, 1, 1, 0.95))
		_triangulo(ultimo[0], ultimo[1], 5.0 * e, ultimo[2])
	if is_instance_valid(balon):
		var b_pt := a_radar(balon.global_position)
		_rombo(b_pt, 4.4 * e, borde)
		_rombo(b_pt, 3.0 * e, Color.WHITE)
