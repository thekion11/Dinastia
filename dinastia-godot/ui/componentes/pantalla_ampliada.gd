class_name PantallaAmpliada
extends Control
## UN BLOQUE A PANTALLA COMPLETA (3-11-2026, orden 22: «muchas partes de la pantalla inicial deberían tener su propia
## pantalla completa»). Cualquier bloque de la pantalla principal (ficha del jugador, lo que va pasando, la
## competición…) lleva un «⤢»: su contenido se muda entero a esta capa, con letra y aire de pantalla grande, y al
## cerrar (✕, Esc o atrás del mando) vuelve exactamente a su sitio. Es el MISMO nodo (no una copia): lo que se
## repinte mientras está abierto se ve aquí.

var _contenido: Control
var _padre_antes: Node
var _indice_antes := 0
var _anclas_antes := []

static var _abierta: PantallaAmpliada = null

## Abre el bloque; si ya está abierto (el «⤢» viaja con él), lo cierra: funciona como interruptor.
static func abrir(raiz: Control, contenido: Control, titulo: String) -> PantallaAmpliada:
	if is_instance_valid(_abierta):
		_abierta.cerrar()
		return null
	var a := PantallaAmpliada.new()
	_abierta = a
	a._contenido = contenido
	a.name = "PantallaAmpliada"
	raiz.add_child(a)
	a._montar(titulo)
	return a

func _montar(titulo: String) -> void:
	top_level = true
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color(Tema.FONDO, 0.98)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 32
	col.offset_right = -32
	col.offset_top = 20
	col.offset_bottom = -20
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	var barra := HBoxContainer.new()
	col.add_child(barra)
	var t := Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, titulo)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(t)
	var cerrar_b := Button.new()
	cerrar_b.text = Idiomas.t("✕ Cerrar")
	cerrar_b.custom_minimum_size = Vector2(120, 44)
	cerrar_b.pressed.connect(cerrar)
	barra.add_child(cerrar_b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	## La mudanza: se recuerda dónde estaba para devolverlo igual.
	_padre_antes = _contenido.get_parent()
	_indice_antes = _contenido.get_index()
	_anclas_antes = [_contenido.anchor_left, _contenido.anchor_top, _contenido.anchor_right, _contenido.anchor_bottom,
		_contenido.offset_left, _contenido.offset_top, _contenido.offset_right, _contenido.offset_bottom,
		_contenido.size_flags_horizontal, _contenido.size_flags_vertical]
	_contenido.reparent(scroll, false)
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_contenido.scale = Vector2.ONE
	Animar.entrar(col)
	cerrar_b.grab_focus.call_deferred()

func cerrar() -> void:
	_devolver(true)
	queue_free()

## Si alguien borra esta capa sin `cerrar()` (otra pantalla que limpia lo que tiene encima), el bloque prestado NO
## puede morir con ella: se saca antes y se devuelve a su sitio en cuanto se pueda.
func _exit_tree() -> void:
	_devolver(false)

## `ya`: devolverlo en el acto (cierre normal); si no (la capa sale del árbol), al siguiente momento libre.
func _devolver(ya: bool) -> void:
	if _abierta == self:
		_abierta = null
	if not is_instance_valid(_contenido) or not is_ancestor_of(_contenido):
		return
	var c := _contenido
	var destino := _padre_antes
	c.get_parent().remove_child(c)
	if not is_instance_valid(destino):
		c.queue_free()
		return
	var a: Array = _anclas_antes
	var idx := _indice_antes
	var volver := func() -> void:
		if not is_instance_valid(c) or not is_instance_valid(destino):
			return
		destino.add_child(c)
		destino.move_child(c, mini(idx, destino.get_child_count() - 1))
		c.anchor_left = a[0]; c.anchor_top = a[1]; c.anchor_right = a[2]; c.anchor_bottom = a[3]
		c.offset_left = a[4]; c.offset_top = a[5]; c.offset_right = a[6]; c.offset_bottom = a[7]
		c.size_flags_horizontal = a[8]
		c.size_flags_vertical = a[9]
	if ya or not destino.is_inside_tree():
		volver.call()
	else:
		volver.call_deferred()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()
