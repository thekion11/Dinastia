class_name MenuModosRetos
extends Control
## EL SELECTOR DE RETOS del menú de modos (26-10-2026). El menú de inicio viejo dejaba
## elegir uno de los cinco retos (`Retos.LISTA`); cuando la entrada nueva pasó a ser el
## único camino para empezar partida, sin esto todo reto habría sido siempre el primero.
## Se abre al confirmar «Retos»: cada reto con su planteamiento y su meta. Ratón, teclado
## y mando: el foco empieza en el primero y no se escapa del cuadro; Esc / B cancela.

signal elegido(id: String)
signal cancelado

var _velo: ColorRect
var _panel: PanelContainer
var _estilo: StyleBoxFlat
var _botones: Array[Button] = []
var _btn_volver: Button

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_velo = ColorRect.new()
	_velo.color = Color(0, 0, 0, 0.6)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_velo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(640, 0)
	_estilo = StyleBoxFlat.new()
	_estilo.bg_color = Color(Tema.PANEL, 0.97)
	_estilo.set_border_width_all(2)
	_estilo.set_corner_radius_all(Tema.RADIO_GRANDE)
	_estilo.set_content_margin_all(22)
	_estilo.border_color = Tema.ORO
	_panel.add_theme_stylebox_override("panel", _estilo)
	centro.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, Idiomas.t("🎯 RETOS")))
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("Una temporada con una meta. Si la cumples, va a tu vitrina; después la carrera sigue."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	for r: Array in Retos.LISTA:
		var b := Button.new()
		b.text = Idiomas.t("%s  %s\n%s\nMeta: %s") % [String(r[1]), String(r[2]), String(r[3]), String(r[4])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 76)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.set_meta("sin_sonido", true)
		var id := String(r[0])
		b.pressed.connect(func() -> void: elegir(id))
		v.add_child(b)
		_botones.append(b)
	_btn_volver = Button.new()
	_btn_volver.text = Idiomas.t("Volver")
	_btn_volver.set_meta("sin_sonido", true)
	_btn_volver.pressed.connect(cancelar)
	v.add_child(_btn_volver)
	## El foco da la vuelta dentro del cuadro: del último al primero y al revés.
	var todos: Array[Button] = _botones.duplicate()
	todos.append(_btn_volver)
	for i in todos.size():
		var b := todos[i]
		b.focus_neighbor_top = b.get_path_to(todos[(i - 1 + todos.size()) % todos.size()])
		b.focus_neighbor_bottom = b.get_path_to(todos[(i + 1) % todos.size()])
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(b)

func abierto() -> bool:
	return visible

## Abre el selector con el borde en la luz del modo.
func abrir(luz: Color) -> void:
	_estilo.border_color = Color(luz, 0.7)
	visible = true
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.18)
	if is_inside_tree() and not _botones.is_empty():
		_botones[0].grab_focus()

## Elige el reto `id` (el clic y las pruebas van por aquí).
func elegir(id: String) -> void:
	if not visible:
		return
	visible = false
	elegido.emit(id)

func cancelar() -> void:
	if not visible:
		return
	visible = false
	cancelado.emit()

func botones() -> Array[Button]:
	return _botones
