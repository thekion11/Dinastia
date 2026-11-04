class_name ControlesTactiles
extends Control
## CONTROLES TÁCTILES DEL PARTIDO (M-433, 27-10-2026): un stick virtual a la izquierda y los botones del mando a la derecha. No tiene lógica
## de juego: pulsa y suelta las MISMAS acciones del InputMap (`Mando.MAPA`), así que el motor, el tutorial y el mando físico no se enteran.
## Varios dedos a la vez (mover + sprint + tirar); cada dedo se queda con el control que tocó al empezar, aunque se salga de él.
##   stick      jugar_izquierda/derecha/arriba/abajo, con fuerza analógica (centro al toque, radio `RADIO_STICK`)
##   A          Pase · Presión (con y sin balón: `Mando.accion_de`)     B   Tiro · Entrada
##   X          Centro · Barrida                                         Y   Pase al hueco
##   Cambiar    cambia de jugador                                         Sprint   se mantiene mientras se toca
##   Mod        el modificador (rosca, tenso, vaselina…)                  II       pausa / táctica y cambios (arriba a la derecha)
## Tamaño y opacidad salen de Ajustes → Dispositivo (`AjustesTactil`); también eligen si salen siempre, nunca o solo en pantallas táctiles.
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
	"Mod": ["Mod", "jugar_mod", 3.4, 1.4],
	"Pausa": ["II", "jugar_pausa", 0.0, 0.0],   ## arriba a la derecha (ver `centro_de`)
}

static var forzar := false             ## las pruebas lo encienden; en el teléfono sale solo

var _dedo_stick := -1
var _centro_stick := Vector2.ZERO
var _vec := Vector2.ZERO
var _dedos := {}                       ## índice de dedo → nombre del botón

## Lo añade al partido si el aparato es táctil (o `forzar`). Devuelve el control (null si no hacía falta).
static func poner(padre: Node) -> ControlesTactiles:
	var modo := AjustesTactil.modo()
	if modo == "no" or not (forzar or modo == "si" or CargaCiudad.de("ExploradorCiudad").es_tactil()):
		return null
	var c := ControlesTactiles.new()
	c.name = "ControlesTactiles"
	padre.add_child(c)
	## La línea de ayuda de teclado y mando («SIN BALÓN: Espacio/A contener…») sobra en el móvil y tapa: se deja transparente (orden del líder, 27-10).
	var ayuda: Variant = padre.get("_ayuda")
	if ayuda is CanvasItem:
		(ayuda as CanvasItem).modulate.a = 0.0
	return c

var esc := 1.0                         ## tamaño elegido en Ajustes (1 = el de siempre)
var opac := 1.0                        ## opacidad elegida en Ajustes

## El tamaño elegido, sin pasar de lo que cabe: la columna de botones mide ~9 radios de alto (480 px de alto = tamaño 1).
func esc_real() -> float:
	return minf(esc, maxf(size.y / 480.0, AjustesTactil.TAM_MIN)) if size.y > 0.0 else esc

func radio_boton() -> float:
	return RADIO_BOTON * esc_real()

func radio_stick() -> float:
	return RADIO_STICK * esc_real()

func _ready() -> void:
	esc = AjustesTactil.tamano()
	opac = AjustesTactil.opacidad()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20

## La línea de ayuda de teclado y mando del partido sobra con los botones en pantalla y tapa su borde: se mantiene oculta aunque el partido
## la vuelva a mostrar (`_ver_hud`, `_ver_hud_abajo`) o le cambie el texto cada fotograma.
func _process(_d: float) -> void:
	var ayuda: Variant = get_parent().get("_ayuda") if get_parent() != null else null
	if ayuda is CanvasItem and (ayuda as CanvasItem).visible:
		(ayuda as CanvasItem).visible = false

func _exit_tree() -> void:
	soltar_todo()

## Dónde está el centro de un botón en este tamaño de pantalla.
func centro_de(nombre: String) -> Vector2:
	var r := radio_boton()
	if nombre == "Pausa":
		return Vector2(size.x - r * 0.9 - 20.0, r * 0.9 + 70.0)   ## bajo la ficha de estadísticas de arriba a la derecha
	var b: Array = BOTONES[nombre]
	return size - Vector2(r * 1.6, r * 1.6) - Vector2(float(b[2]), float(b[3])) * r * 2.5 * Vector2(1.0, 1.0)

func centro_reposo() -> Vector2:
	return Vector2(radio_stick() + 40.0, size.y - radio_stick() - 110.0)   ## por encima de la ficha del jugador (abajo a la izquierda)

func _boton_en(pos: Vector2) -> String:
	for n: String in BOTONES:
		if centro_de(n).distance_to(pos) <= radio_boton() * (0.9 if n == "Pausa" else 1.15):
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
	_vec = ((pos - _centro_stick) / radio_stick()).limit_length(1.0)
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
	var rs := radio_stick()
	draw_circle(c0, rs, Color(1, 1, 1, 0.10 * opac))
	draw_arc(c0, rs, 0.0, TAU, 48, Color(1, 1, 1, 0.45 * opac), 3.0)
	draw_circle(c0 + _vec * rs, radio_boton() * 0.7, Color(1, 1, 1, 0.38 * opac))
	var fuente := ThemeDB.fallback_font
	for n: String in BOTONES:
		var c := centro_de(n)
		var r := radio_boton() * (0.9 if n == "Pausa" else 1.0)
		var activo := _dedos.values().has(n)
		draw_circle(c, r, Color(0.9, 0.9, 0.2, 0.55 * opac) if activo else Color(0.05, 0.05, 0.08, 0.45 * opac))
		draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.7 * opac), 3.0)
		var lineas := Idiomas.t(String(BOTONES[n][0])).split("\n")
		for k in lineas.size():
			var y := c.y + 5.0 + (float(k) - float(lineas.size() - 1) * 0.5) * 17.0 * esc
			draw_string(fuente, Vector2(c.x - r, y), lineas[k], HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(15.0 * esc_real()), Color(1, 1, 1, opac))
