class_name ControlesTactiles
extends Control
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026; rehechos el 4-11-2026 tras la revisión del dueño: «la posición y el estándar están mal»). Un stick virtual FLOTANTE a la izquierda y los botones del mando a la
## derecha, en ARCO alrededor del reposo del pulgar derecho (esquina inferior derecha), como los juegos de fútbol de móvil (FIFA Mobile, eFootball, Dream League): lo más usado (Pase, Tiro) abajo y grande,
## lo secundario (Al hueco, Centro, Cambiar) más arriba y pequeño, nada en el tercio superior (ahí van el marcador y las estadísticas). No tiene lógica de juego: pulsa y suelta las MISMAS acciones del InputMap
## (`Mando.MAPA`), así que el motor, el tutorial y el mando físico no se enteran. Varios dedos a la vez (mover + sprint + tirar); cada dedo se queda con el control que tocó al empezar, aunque se salga de él.
##   stick      jugar_izquierda/derecha/arriba/abajo, con fuerza analógica (aparece donde se toca, en la mitad izquierda; radio `RADIO_STICK`)
##   A Pase · Presión      B Tiro · Entrada      X Centro · Barrida      Y Pase al hueco      Cambiar      Sprint (se mantiene mientras se toca)
## Medidas (guías de Apple 44 pt / Material 48 dp / NN-g 1 cm; en juegos, 45-57 px por pulgar): en un móvil el botón grande mide ≈1,5 cm y el pequeño ≈1,1 cm (`escala`, por los puntos por pulgada);
## con 8 px o más entre botones. Respeta el área segura (muescas, esquinas redondeadas). `zurdo` espeja todo (stick a la derecha, botones a la izquierda).
const RADIO_STICK := 112.0
const RADIO_BOTON := 54.0               ## el radio de referencia (el de los botones medianos); cada botón lleva el suyo
const DIRS := {"jugar_izquierda": Vector2.LEFT, "jugar_derecha": Vector2.RIGHT, "jugar_arriba": Vector2.UP, "jugar_abajo": Vector2.DOWN}
## nombre → [etiqueta, acción, desplazamiento del centro desde la esquina inferior (derecha), radio, color del aro]
const BOTONES := {
	"A": ["Pase\nPresión", "jugar_pase", Vector2(220, 135), 66.0, Color(0.35, 0.65, 1.0)],
	"B": ["Tiro\nEntrada", "jugar_tiro", Vector2(105, 215), 66.0, Color(1.0, 0.45, 0.35)],
	"X": ["Centro\nBarrida", "jugar_centro", Vector2(185, 320), 50.0, Color(1.0, 0.85, 0.3)],
	"Y": ["Al hueco", "jugar_filtrado", Vector2(305, 285), 50.0, Color(0.45, 0.9, 0.5)],
	"Cambiar": ["Cambiar", "jugar_cambiar", Vector2(425, 230), 44.0, Color(0.8, 0.8, 0.85)],
	"Sprint": ["Sprint", "jugar_sprint", Vector2(360, 130), 56.0, Color(1, 1, 1)],
}
const ZONA_STICK_X := 0.45              ## el stick solo nace en este tramo del ancho (el lado del pulgar izquierdo)
const ZONA_STICK_Y := 0.2               ## y por debajo de este tramo de arriba (no tapa el marcador)

static var forzar := false             ## las pruebas lo encienden; en el teléfono sale solo
static var zurdo := false              ## espejo: stick a la derecha y botones a la izquierda

var _dedo_stick := -1
var _centro_stick := Vector2.ZERO
var _vec := Vector2.ZERO
var _dedos := {}                       ## índice de dedo → nombre del botón
var _ayuda: CanvasItem                 ## la línea de ayuda de teclado del partido (se mantiene escondida)

## Lo añade al partido si el aparato es táctil (o `forzar`). Devuelve el control (null si no hacía falta).
static func poner(padre: Node) -> ControlesTactiles:
	if not (forzar or ExploradorCiudad.es_tactil()):
		return null
	var c := ControlesTactiles.new()
	c.name = "ControlesTactiles"
	padre.add_child(c)
	## La línea de ayuda de teclado y mando («SIN BALÓN: Espacio/A contener…») sobra en el móvil y tapa: se esconde del todo (con solo transparentarla se seguía viendo).
	var ayuda: Variant = padre.get("_ayuda")
	if ayuda is CanvasItem:
		c._ayuda = ayuda as CanvasItem
		c._ayuda.visible = false
	return c

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20

func _exit_tree() -> void:
	soltar_todo()

## El partido vuelve a mostrar su línea de ayuda de teclado al cambiar el HUD o de fase: aquí se vuelve a esconder (barato).
func _process(_d: float) -> void:
	if _ayuda == null or not is_instance_valid(_ayuda):
		var a: Variant = get_parent().get("_ayuda") if get_parent() != null else null   ## el partido la crea DESPUÉS de montar los controles: se busca aquí
		_ayuda = a as CanvasItem
	if _ayuda != null and _ayuda.visible:
		_ayuda.visible = false

## Factor de tamaño: proporcional a la altura del lienzo (los lienzos pequeños de las pruebas) y, en un móvil de verdad, a los puntos por pulgada
## para que el botón grande mida ≈1,5 cm sea cual sea la pantalla. Entre 0,6 y 1,5.
func escala() -> float:
	var s := clampf(size.y / 720.0, 0.6, 1.25)
	if OS.has_feature("mobile"):
		var dpi := float(DisplayServer.screen_get_dpi())
		var vent := DisplayServer.window_get_size()
		if dpi > 0.0 and vent.y > 0:
			var px_por_cm := dpi / 2.54 * size.y / float(vent.y)   ## píxeles del lienzo por cm de pantalla
			s = clampf(0.75 * px_por_cm / 66.0, 0.6, 1.5)           ## radio grande = 0,75 cm
	return s

## Márgenes por muescas y esquinas redondeadas: x = izquierda, y = derecha (en píxeles del lienzo). 0 fuera de un móvil.
func margenes() -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var vent := DisplayServer.window_get_size()
	var seg := DisplayServer.get_display_safe_area()
	var pant := DisplayServer.screen_get_size()
	if vent.x <= 0 or pant.x <= 0 or seg.size.x <= 0:
		return Vector2.ZERO
	var k := size.x / float(vent.x)
	return Vector2(maxf(0.0, float(seg.position.x)), maxf(0.0, float(pant.x - seg.position.x - seg.size.x))) * k

## Radio de un botón en este tamaño de pantalla.
func radio_de(nombre: String) -> float:
	return float((BOTONES[nombre] as Array)[3]) * escala()

## Dónde está el centro de un botón en este tamaño de pantalla.
func centro_de(nombre: String) -> Vector2:
	var b: Array = BOTONES[nombre]
	var off: Vector2 = b[2]
	var s := escala()
	var m := margenes()
	var x := (m.x + off.x * s) if zurdo else (size.x - m.y - off.x * s)
	return Vector2(x, size.y - off.y * s)

## Dónde se dibuja el stick en reposo (el pulgar izquierdo; por encima de la ficha del jugador, abajo a la izquierda).
func centro_reposo() -> Vector2:
	var s := escala()
	var m := margenes()
	var x := (size.x - m.y - (RADIO_STICK + 60.0) * s) if zurdo else (m.x + (RADIO_STICK + 60.0) * s)
	return Vector2(x, size.y - (RADIO_STICK + 120.0) * s)

func _boton_en(pos: Vector2) -> String:
	var mejor := ""
	var md := INF
	for n: String in BOTONES:
		var d := centro_de(n).distance_to(pos)
		if d <= radio_de(n) * 1.15 and d < md:   ## 15 % de margen alrededor: un dedo grande no falla; el más cercano gana
			md = d
			mejor = n
	return mejor

## ¿Está `pos` en la zona donde puede nacer el stick?
func _en_zona_stick(pos: Vector2) -> bool:
	var lado := pos.x > size.x * (1.0 - ZONA_STICK_X) if zurdo else pos.x < size.x * ZONA_STICK_X
	return lado and pos.y > size.y * ZONA_STICK_Y

func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed:
			_toca(t.index, t.position)
		else:
			_suelta(t.index)
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if d.index == _dedo_stick:
			_mueve_stick(d.position)

func _toca(dedo: int, pos: Vector2) -> void:
	var b := _boton_en(pos)
	if b != "":
		_dedos[dedo] = b
		Input.action_press(String(BOTONES[b][1]))
	elif _dedo_stick < 0 and _en_zona_stick(pos):
		_dedo_stick = dedo
		_centro_stick = pos
		_mueve_stick(pos)
	queue_redraw()

func _suelta(dedo: int) -> void:
	if dedo == _dedo_stick:
		_dedo_stick = -1
		_vec = Vector2.ZERO
		_aplicar_stick()
	elif _dedos.has(dedo):
		Input.action_release(String(BOTONES[String(_dedos[dedo])][1]))
		_dedos.erase(dedo)
	queue_redraw()

func _mueve_stick(pos: Vector2) -> void:
	_vec = ((pos - _centro_stick) / (RADIO_STICK * escala())).limit_length(1.0)
	_aplicar_stick()
	queue_redraw()

## Las cuatro acciones de dirección con la fuerza que toque (el motor lee `Mando.movimiento`, que es analógico).
func _aplicar_stick() -> void:
	for a: String in DIRS:
		var f := maxf(0.0, _vec.dot(DIRS[a]))
		if f > 0.0:
			Input.action_press(a, f)
		else:
			Input.action_release(a)

func soltar_todo() -> void:
	for a: String in DIRS:
		Input.action_release(a)
	for d: int in _dedos:
		Input.action_release(String(BOTONES[String(_dedos[d])][1]))
	_dedos.clear()
	_dedo_stick = -1
	_vec = Vector2.ZERO

func _draw() -> void:
	var s := escala()
	var rs := RADIO_STICK * s
	var c0 := _centro_stick if _dedo_stick >= 0 else centro_reposo()
	var en_uso := _dedo_stick >= 0
	draw_circle(c0, rs, Color(1, 1, 1, 0.13 if en_uso else 0.07))
	draw_arc(c0, rs, 0.0, TAU, 48, Color(1, 1, 1, 0.55 if en_uso else 0.30), 3.0)
	draw_circle(c0 + _vec * rs, rs * 0.38, Color(1, 1, 1, 0.50 if en_uso else 0.25))
	var fuente := ThemeDB.fallback_font
	for n: String in BOTONES:
		var c := centro_de(n)
		var r := radio_de(n)
		var col: Color = (BOTONES[n] as Array)[4]
		var activo := _dedos.values().has(n)
		draw_circle(c, r, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.62) if activo else Color(0.04, 0.05, 0.08, 0.42))
		draw_arc(c, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.95 if activo else 0.75), 4.0 * s)
		var lineas := Idiomas.t(String(BOTONES[n][0])).split("\n")
		var tam := int(roundf(clampf(r * 0.30, 11.0, 24.0)))
		for k in lineas.size():
			var y := c.y + float(tam) * 0.35 + (float(k) - float(lineas.size() - 1) * 0.5) * float(tam) * 1.15
			var tk := tam if k == 0 else int(tam * 0.85)
			draw_string_outline(fuente, Vector2(c.x - r, y), lineas[k], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, 5, Color(0, 0, 0, 0.8))
			draw_string(fuente, Vector2(c.x - r, y), lineas[k], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, tk, Color.WHITE if k == 0 else Color(1, 1, 1, 0.85))
