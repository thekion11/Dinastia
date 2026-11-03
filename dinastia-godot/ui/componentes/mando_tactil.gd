class_name MandoTactil
extends Control
## EL MANDO TÁCTIL DEL PASEO (3-11-2026, prueba del dueño: «primera persona imposible» y «movilidad mala» en el móvil).
## Reemplaza la cruz de cuatro botones (todo o nada, a tirones) por dos dedos a la vez:
##  · pulgar IZQUIERDO: palanca analógica flotante (nace donde se toca la mitad izquierda): cuanto más se inclina, más rápido camina y más gira;
##    suave (zona muerta + curva + filtro), así que no hay tirones al soltar ni al cruzar el centro;
##  · pulgar DERECHO: arrastrar mira alrededor (gira el rumbo y, en primera persona, cabecea).
## El explorador lo busca con `MandoTactil.leer(...)`; los botones (E, cámara, Salir) siguen siendo botones normales y sus zonas no mueven la mirada.
const RADIO := 84.0            ## lo que hay que arrastrar el pulgar para el máximo
const ZONA_MUERTA := 0.12
const MIRAR_GIRO := 0.0048     ## rad por píxel arrastrado
const MIRAR_CABECEO := 0.0035
const META := "mando_tactil"

var valor := Vector2.ZERO      ## salida suavizada: x giro (+ derecha), y avance (+ adelante)
var explorador: Node           ## al que se le gira el rumbo
var _objetivo := Vector2.ZERO
var _dedo_mando := -1
var _dedo_mirar := -1
var _centro := Vector2.ZERO
var _punta := Vector2.ZERO
var _cabeceo := 0.0
var _mirada := Vector2.ZERO    ## lo arrastrado por el pulgar derecho desde el último fotograma

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   ## no se come los clics de los botones
	z_index = 5

static func leer(e: Node, respaldo: Vector2) -> Vector2:
	var m := e.get_meta(META, null) as MandoTactil
	if m != null and m.valor != Vector2.ZERO:
		return m.valor
	return respaldo

## El botón de la cámara (primera / tercera persona; en coche cambia de vista): manda la tecla V.
static func boton_camara(tam: float, visible_: bool) -> Button:
	var bc := Button.new()
	bc.text = "◉"
	bc.custom_minimum_size = Vector2(tam, tam)
	bc.add_theme_font_size_override("font_size", 28)
	bc.modulate = Color(1, 1, 1, 0.75)
	bc.visible = visible_
	bc.pressed.connect(func() -> void:
		var ev := InputEventKey.new()
		ev.keycode = KEY_V
		ev.pressed = true
		Input.parse_input_event(ev))
	return bc

## Corre cuando la palanca está casi a tope hacia delante.
static func corre(e: Node) -> bool:
	var m := e.get_meta(META, null) as MandoTactil
	return m != null and m.valor.y > 0.93

func zona_mando(p: Vector2) -> bool:
	var t := get_viewport_rect().size
	return p.x < t.x * 0.42 and p.y > t.y * 0.22

func zona_mirar(p: Vector2) -> bool:
	var t := get_viewport_rect().size
	return p.x >= t.x * 0.42 and not (p.x > t.x - 330.0 and p.y > t.y - 150.0) and p.y > t.y * 0.1

func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		if t.pressed:
			if _dedo_mando < 0 and zona_mando(t.position):
				_dedo_mando = t.index
				_centro = t.position
				_punta = t.position
			elif _dedo_mirar < 0 and zona_mirar(t.position):
				_dedo_mirar = t.index
		else:
			if t.index == _dedo_mando:
				_dedo_mando = -1
				_objetivo = Vector2.ZERO
			elif t.index == _dedo_mirar:
				_dedo_mirar = -1
		queue_redraw()
	elif ev is InputEventScreenDrag:
		var d := ev as InputEventScreenDrag
		if d.index == _dedo_mando:
			_punta = d.position
			var v := (_punta - _centro).limit_length(RADIO) / RADIO
			var largo := v.length()
			if largo < ZONA_MUERTA:
				_objetivo = Vector2.ZERO
			else:
				var f := pow((largo - ZONA_MUERTA) / (1.0 - ZONA_MUERTA), 1.25)   ## curva: fino cerca del centro
				_objetivo = Vector2(v.x, -v.y).normalized() * f
			queue_redraw()
		elif d.index == _dedo_mirar:
			_mirada += d.relative

func _process(delta: float) -> void:
	## Filtro exponencial: arrancar y parar sin tirones.
	valor = valor.lerp(_objetivo, 1.0 - exp(-delta * 16.0))
	if valor.length() < 0.01 and _objetivo == Vector2.ZERO:
		valor = Vector2.ZERO
	if _mirada != Vector2.ZERO and explorador != null:
		explorador.set("rumbo", float(explorador.get("rumbo")) - _mirada.x * MIRAR_GIRO)
		_cabeceo = clampf(_cabeceo - _mirada.y * MIRAR_CABECEO, -0.9, 0.9)
		explorador.set_meta("cabeceo", -0.15 + _cabeceo * 5.0)   ## desnivel de la mirada a 5 m (lo lee la cámara en primera persona)
		_mirada = Vector2.ZERO
	if _dedo_mando >= 0 or valor != Vector2.ZERO:
		queue_redraw()

func _draw() -> void:
	var t := get_viewport_rect().size
	var c := _centro if _dedo_mando >= 0 else Vector2(RADIO + 46.0, t.y - RADIO - 46.0)
	var p := _punta if _dedo_mando >= 0 else c
	var a := 0.55 if _dedo_mando >= 0 else 0.22
	draw_circle(c, RADIO, Color(1, 1, 1, a * 0.35))
	draw_arc(c, RADIO + 2.0, 0.0, TAU, 40, Color(0, 0, 0, a * 0.8), 3.0, true)   ## con borde oscuro: se ve también sobre suelo claro
	draw_arc(c, RADIO, 0.0, TAU, 40, Color(1, 1, 1, a), 3.0, true)
	draw_circle(c + (p - c).limit_length(RADIO), RADIO * 0.38, Color(0.15, 0.15, 0.18, a * 0.9))
	draw_circle(c + (p - c).limit_length(RADIO), RADIO * 0.3, Color(1, 1, 1, a + 0.25))
