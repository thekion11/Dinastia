class_name SelectorDireccional
extends Container
## SELECCIÓN DIRECCIONAL DE RESPUESTAS (10-11, orden del dueño: «reemplazar el formato de lista»). Las respuestas se colocan en CRUZ alrededor
## de un centro (arriba, derecha, abajo, izquierda); la de delegar («🙋») va en el CENTRO. Se elige:
##   - mando: inclinar el analógico (o la cruceta) hacia la respuesta y confirmar con R2 (o A); Cuadrado no hace nada aquí;
##   - PC: clic (o flechas + Enter); móvil: tocarla.
## Al elegir, una MINI ANIMACIÓN inmediata (la elegida late y se ilumina, las demás se apagan) y luego `elegido(i)`.
## Los botones son hijos DIRECTOS (uno por opción, en el orden de las opciones), así que `get_child_count()` es el número de opciones.
## Paleta propia (el dueño permite variar el verde con dorado): azul noche, blanco y un acento por club.
signal elegido(i: int)

const NOCHE := Color("0d1626")
const NOCHE_PANEL := Color("16243d")
const BLANCO := Color("f2f5fa")
const HUECO := 10.0
const ANCHO_CENTRO := 78.0
const UMBRAL_STICK := 0.55
const UMBRAL_R2 := 0.6

var acento := Color("4f8ff7")
var _centro: Button = null
var _brazos: Array[Button] = []
var _bloqueado := false
var _r2_suelto := true
var _dir_stick := -1

## `textos`: el texto de cada opción, en su orden. `centro_idx`: cuál va al centro (-1: ninguna; si no se dice, la que lleve «🙋»).
static func crear(textos: Array, color_acento: Color, centro_idx := -2) -> SelectorDireccional:
	var s := SelectorDireccional.new()
	s.acento = acento_legible(color_acento)
	if centro_idx == -2:
		centro_idx = -1
		for i in textos.size():
			if String(textos[i]).contains("🙋"):
				centro_idx = i
	for i in textos.size():
		var b := Button.new()
		b.text = String(textos[i])
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.focus_mode = Control.FOCUS_ALL
		s._estilo(b, i == centro_idx)
		var idx := i
		b.pressed.connect(func() -> void: s.elegir(idx))
		s.add_child(b)
		if i == centro_idx:
			s._centro = b
			b.tooltip_text = b.text
			b.text = "🙋\n" + Idiomas.t("Ayudante")
			b.autowrap_mode = TextServer.AUTOWRAP_OFF
			b.clip_text = true
		else:
			s._brazos.append(b)
	return s

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_vecinos()   ## los caminos de foco necesitan el árbol (rutas relativas)
	for b: Button in _todos():
		b.focus_entered.connect(queue_redraw)
		b.mouse_entered.connect(func() -> void:
			if not _bloqueado:
				b.grab_focus())

func _todos() -> Array[Button]:
	var r: Array[Button] = []
	for c in get_children():
		if c is Button:
			r.append(c as Button)
	return r

## Qué hueco de la cruz ocupa cada brazo, según cuántos hay: 0 arriba, 1 derecha, 2 abajo, 3 izquierda.
func _huecos() -> Array:
	match _brazos.size():
		1: return [0]
		2: return [3, 1]
		3: return [0, 3, 1]
		_: return [0, 1, 2, 3]

func _estilo(b: Button, es_centro: bool) -> void:
	b.add_theme_font_size_override("font_size", Tema.letra(13 if not es_centro else 12))
	b.add_theme_color_override("font_color", BLANCO)
	b.add_theme_color_override("font_hover_color", BLANCO)
	b.add_theme_color_override("font_focus_color", BLANCO)
	b.add_theme_color_override("font_pressed_color", BLANCO)
	for estado: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(NOCHE_PANEL, 0.92)
		sb.border_color = Color(BLANCO, 0.22)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(40 if es_centro else 10)
		sb.set_content_margin_all(4 if es_centro else 10)   ## (12-11) el redondel del centro mide 78 px: con 10 de margen «Ayudante» se partía en dos
		if estado in ["hover", "focus", "pressed"]:
			sb.bg_color = Color(acento.darkened(0.45), 0.95)
			sb.border_color = acento.lightened(0.25)
			sb.set_border_width_all(3)
		b.add_theme_stylebox_override(estado, sb)

## Vecinos de foco: desde cualquier brazo, la dirección lleva al brazo de ese lado (o al centro, si está en medio).
func _vecinos() -> void:
	var por_hueco := {}
	var h := _huecos()
	for i in _brazos.size():
		if i < h.size():
			por_hueco[int(h[i])] = _brazos[i]
	for b: Button in _todos():
		for d in 4:
			var destino: Button = por_hueco.get(d, null)
			if b != _centro and _centro != null and destino != b:
				## desde un brazo, hacia el lado opuesto se pasa por el centro
				var mi_hueco := -1
				for k: int in por_hueco:
					if por_hueco[k] == b:
						mi_hueco = k
				if mi_hueco >= 0 and posmod(mi_hueco + 2, 4) == d:
					destino = _centro
			if destino != null and destino != b:
				b.set("focus_neighbor_" + ["top", "right", "bottom", "left"][d], b.get_path_to(destino))

func _get_minimum_size() -> Vector2:
	var alto := 0.0
	for b: Button in _brazos:
		alto = maxf(alto, b.get_combined_minimum_size().y)
	alto = maxf(alto, 46.0)
	var filas := 3 if _brazos.size() >= 3 or _centro != null else 1
	if _brazos.size() == 3:
		filas = 2 if _centro == null else 3
	return Vector2(0, alto * filas + HUECO * (filas - 1))

func _notification(que: int) -> void:
	if que == NOTIFICATION_SORT_CHILDREN:
		_colocar()

## La cruz: fila de arriba (brazo 0), fila del medio (izquierda · centro · derecha), fila de abajo (brazo 2).
func _colocar() -> void:
	var w := size.x
	var min_alto := 46.0
	for b: Button in _brazos:
		b.custom_minimum_size = Vector2.ZERO
	var lateral := (w - ANCHO_CENTRO - HUECO * 2.0) * 0.5
	var vertical := w * 0.62
	for b: Button in _brazos:   ## alto real con el ancho que le toca (el texto salta de línea)
		b.size = Vector2(lateral, 0)
		min_alto = maxf(min_alto, b.get_combined_minimum_size().y)
	var h := _huecos()
	var hay_arriba := h.has(0)
	var y_medio := (min_alto + HUECO) if hay_arriba else 0.0
	for i in _brazos.size():
		var b := _brazos[i]
		var r := Rect2()
		match int(h[i]) if i < h.size() else 2:
			0: r = Rect2((w - vertical) * 0.5, 0, vertical, min_alto)
			1: r = Rect2(w - lateral, y_medio, lateral, min_alto)
			2: r = Rect2((w - vertical) * 0.5, y_medio + min_alto + HUECO, vertical, min_alto)
			3: r = Rect2(0, y_medio, lateral, min_alto)
		fit_child_in_rect(b, r)
		b.pivot_offset = r.size * 0.5
	if _centro != null:
		var lado := minf(ANCHO_CENTRO, min_alto + 16.0)
		var rc := Rect2((w - ANCHO_CENTRO) * 0.5, y_medio + (min_alto - lado) * 0.5, ANCHO_CENTRO, lado)
		fit_child_in_rect(_centro, rc)
		_centro.pivot_offset = rc.size * 0.5
	update_minimum_size()
	queue_redraw()

## El dibujo de fondo: un aro en el centro y el «rayo» hacia la respuesta con el foco (lo que apunta el analógico).
func _draw() -> void:
	if _brazos.is_empty():
		return
	var h := _huecos()
	var c := Vector2(size.x * 0.5, 0.0)
	var y_medio := 0.0
	for i in _brazos.size():
		if i < h.size() and (int(h[i]) == 1 or int(h[i]) == 3):
			y_medio = _brazos[i].position.y + _brazos[i].size.y * 0.5
	c.y = y_medio if y_medio > 0.0 else size.y * 0.5
	if _centro == null:
		draw_circle(c, 20.0, Color(NOCHE, 0.85))
		draw_arc(c, 20.0, 0, TAU, 32, Color(BLANCO, 0.35), 2.0, true)
	var f := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if f is Button and f.get_parent() == self and f != _centro:
		var destino := (f as Control).position + (f as Control).size * 0.5
		var dir := (destino - c).normalized()
		draw_line(c + dir * 22.0, c + dir * 40.0, acento.lightened(0.2), 4.0, true)
		if _centro == null:
			draw_circle(c + dir * 9.0, 6.0, acento.lightened(0.2))

## MANDO: el analógico izquierdo apunta (con un umbral, sin repetir mientras no cambie la dirección) y R2 confirma.
func _process(_d: float) -> void:
	if _bloqueado or not is_visible_in_tree() or Input.get_connected_joypads().is_empty():
		return
	var v := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if v.length() < UMBRAL_STICK:
		_dir_stick = -1
		return
	var d := direccion_de(v)
	if d != _dir_stick:
		_dir_stick = d
		apuntar(d)

## El color del club como acento, salvo que sea demasiado claro u oscuro para leer texto blanco encima: entonces el azul de la paleta.
static func acento_legible(c: Color) -> Color:
	var l := c.get_luminance()
	return c if l > 0.12 and l < 0.55 and c.s > 0.25 else Color("4f8ff7")

## 0 arriba, 1 derecha, 2 abajo, 3 izquierda.
static func direccion_de(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 1 if v.x > 0.0 else 3
	return 2 if v.y > 0.0 else 0

## Pone el foco en el brazo de esa dirección (si existe). Devuelve el índice de la opción, o -1.
func apuntar(d: int) -> int:
	var h := _huecos()
	for i in _brazos.size():
		if i < h.size() and int(h[i]) == d:
			_brazos[i].grab_focus()
			queue_redraw()
			Sonido.toca("menu_mover", Sonido.Bus.INTERFAZ)
			return _brazos[i].get_index()
	return -1

func _input(ev: InputEvent) -> void:
	if _bloqueado or not is_visible_in_tree():
		return
	if ev is InputEventJoypadMotion and (ev as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_RIGHT:
		var val := (ev as InputEventJoypadMotion).axis_value
		if val > UMBRAL_R2 and _r2_suelto:
			_r2_suelto = false
			var f := get_viewport().gui_get_focus_owner()
			if f is Button and f.get_parent() == self:
				get_viewport().set_input_as_handled()
				elegir(f.get_index())
		elif val < 0.3:
			_r2_suelto = true

## Elige la opción `i`: mini animación inmediata y después `elegido(i)`.
func elegir(i: int) -> void:
	if _bloqueado or i < 0 or i >= get_child_count():
		return
	_bloqueado = true
	Sonido.toca("menu_aceptar", Sonido.Bus.INTERFAZ)
	var b := get_child(i) as Button
	if Animar.reducidas() or not is_inside_tree():
		elegido.emit(i)
		return
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2(1.1, 1.1), 0.12)
	tw.tween_property(b, "modulate", Color(1.35, 1.35, 1.35), 0.12)
	for o: Button in _todos():
		if o != b:
			tw.tween_property(o, "modulate:a", 0.25, 0.15)
	tw.chain().tween_property(b, "scale", Vector2.ONE, 0.1)
	tw.chain().tween_callback(func() -> void: elegido.emit(i))
