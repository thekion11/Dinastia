class_name ControlesTactiles
extends Control
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026): un stick virtual a la izquierda y los botones del mando a la derecha. No tiene lógica
## de juego: pulsa y suelta las MISMAS acciones del InputMap (`Mando.MAPA`), así que el motor, el tutorial y el mando físico no se enteran.
## Varios dedos a la vez (mover + sprint + tirar); cada dedo se queda con el control que tocó al empezar, aunque se salga de él.
##   stick      jugar_izquierda/derecha/arriba/abajo, con fuerza analógica (centro al toque, radio `RADIO_STICK`)
##   A          Pase · Presión (con y sin balón: `Mando.accion_de`)     B   Tiro · Entrada
##   X          Centro · Barrida                                         Y   Pase al hueco
##   Cambiar    cambia de jugador                                         Sprint   se mantiene mientras se toca
const RADIO_STICK := 120.0
const RADIO_BOTON := 54.0
const DIRS := {"jugar_izquierda": Vector2.LEFT, "jugar_derecha": Vector2.RIGHT, "jugar_arriba": Vector2.UP, "jugar_abajo": Vector2.DOWN}
## nombre → [etiqueta, acción, columna, fila] (en unidades de 1,25·RADIO_BOTON desde la esquina inferior derecha)
const BOTONES := {
	"A": ["Pase\nPresión", "jugar_pase", 1.0, 0.0],
	"B": ["Tiro\nEntrada", "jugar_tiro", 0.0, 1.0],
	"X": ["Centro\nBarrida", "jugar_centro", 2.0, 1.0],
	"Y": ["Al hueco", "jugar_filtrado", 1.0, 2.0],
	"Cambiar": ["Cambiar", "jugar_cambiar", 3.2, 0.2],
	"Sprint": ["Sprint", "jugar_sprint", 2.3, 2.5],
}

static var forzar := false             ## las pruebas lo encienden; en el teléfono sale solo

var _dedo_stick := -1
var _centro_stick := Vector2.ZERO
var _vec := Vector2.ZERO
var _dedos := {}                       ## índice de dedo → nombre del botón

## Lo añade al partido si el aparato es táctil (o `forzar`). Devuelve el control (null si no hacía falta).
static func poner(padre: Node) -> ControlesTactiles:
	if not (forzar or ExploradorCiudad.es_tactil()):
		return null
	var c := ControlesTactiles.new()
	c.name = "ControlesTactiles"
	padre.add_child(c)
	return c

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20

func _exit_tree() -> void:
	soltar_todo()

## Dónde está el centro de un botón en este tamaño de pantalla.
func centro_de(nombre: String) -> Vector2:
	var b: Array = BOTONES[nombre]
	return size - Vector2(RADIO_BOTON * 1.6, RADIO_BOTON * 1.6) - Vector2(float(b[2]), float(b[3])) * RADIO_BOTON * 2.5 * Vector2(1.0, 1.0)

func centro_reposo() -> Vector2:
	return Vector2(RADIO_STICK + 40.0, size.y - RADIO_STICK - 110.0)   ## por encima de la ficha del jugador (abajo a la izquierda)

func _boton_en(pos: Vector2) -> String:
	for n: String in BOTONES:
		if centro_de(n).distance_to(pos) <= RADIO_BOTON * 1.15:
			return n
	return ""

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
	elif _dedo_stick < 0 and pos.x < size.x * 0.5:
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
	_vec = ((pos - _centro_stick) / RADIO_STICK).limit_length(1.0)
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
	var c0 := _centro_stick if _dedo_stick >= 0 else centro_reposo()
	draw_circle(c0, RADIO_STICK, Color(1, 1, 1, 0.10))
	draw_arc(c0, RADIO_STICK, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 3.0)
	draw_circle(c0 + _vec * RADIO_STICK, RADIO_BOTON * 0.7, Color(1, 1, 1, 0.38))
	var fuente := ThemeDB.fallback_font
	for n: String in BOTONES:
		var c := centro_de(n)
		var activo := _dedos.values().has(n)
		draw_circle(c, RADIO_BOTON, Color(0.9, 0.9, 0.2, 0.55) if activo else Color(0.05, 0.05, 0.08, 0.45))
		draw_arc(c, RADIO_BOTON, 0.0, TAU, 32, Color(1, 1, 1, 0.7), 3.0)
		var lineas := Idiomas.t(String(BOTONES[n][0])).split("\n")
		for k in lineas.size():
			var y := c.y + 5.0 + (float(k) - float(lineas.size() - 1) * 0.5) * 17.0
			draw_string(fuente, Vector2(c.x - RADIO_BOTON, y), lineas[k], HORIZONTAL_ALIGNMENT_CENTER, RADIO_BOTON * 2.0, 15, Color.WHITE)
