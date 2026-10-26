class_name ConfirmarVideo
extends CanvasLayer
## ¿MANTENER ESTE CAMBIO? (uiaj, 25-10-2026). Los ajustes de vídeo (pantalla
## completa, modo televisión, tamaño de la interfaz) se aplican al momento para
## verlos —esa es la vista previa—, pero pueden dejar la pantalla rara o ilegible.
## Como en cualquier juego de PC, se pregunta si se mantienen y, si nadie
## contesta en unos segundos, se deshacen solos: si el cambio rompió la imagen,
## el jugador no tiene que encontrar a ciegas el botón de volver.

signal resuelto(mantener: bool)

const SEGUNDOS := 12.0

var _deshacer: Callable
var _al_mantener: Callable
var _queda := SEGUNDOS
var _que: Label
var _cuenta: Label
var _boton_mantener: Button

## Abre la pregunta o, si ya hay una abierta en `padre` (se sigue arrastrando el
## tamaño, se vuelve a pulsar), la reutiliza y reinicia la cuenta: el deshacer
## que vale es el PRIMERO, el de cómo estaba todo antes de empezar a tocar.
static func pedir(padre: Node, que: String, deshacer: Callable, al_mantener := Callable(), segundos := SEGUNDOS) -> ConfirmarVideo:
	for h in padre.get_children():
		if h is ConfirmarVideo and not h.is_queued_for_deletion():
			var abierta := h as ConfirmarVideo
			abierta._queda = segundos
			abierta._que.text = que
			abierta._pintar_cuenta()
			return abierta
	var c := ConfirmarVideo.new()
	c.layer = 120
	## Sigue contando aunque el árbol esté en pausa (se abre desde menús de pausa).
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	c._deshacer = deshacer
	c._al_mantener = al_mantener
	c._queda = segundos
	padre.add_child(c)
	c._montar(que)
	return c

## La pregunta abierta en `padre`, o null.
static func abierta_en(padre: Node) -> ConfirmarVideo:
	for h in padre.get_children():
		if h is ConfirmarVideo and not h.is_queued_for_deletion():
			return h as ConfirmarVideo
	return null

func _montar(que: String) -> void:
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.45)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	caja.add_child(v)
	v.add_child(Tema.etiqueta(20, Tema.TEXTO, Idiomas.t("¿Mantener este cambio?")))
	_que = Tema.etiqueta(14, Tema.TEXTO, que)
	_que.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_que.custom_minimum_size = Vector2(400, 0)
	v.add_child(_que)
	_cuenta = Tema.etiqueta(13, Tema.SUAVE, "")
	v.add_child(_cuenta)
	_pintar_cuenta()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var b_no := Button.new()
	b_no.text = Idiomas.t("↩ Deshacer")
	b_no.custom_minimum_size = Vector2(150, 36)
	b_no.pressed.connect(deshacer)
	fila.add_child(b_no)
	_boton_mantener = Button.new()
	_boton_mantener.text = Idiomas.t("✔ Mantener")
	_boton_mantener.custom_minimum_size = Vector2(150, 36)
	_boton_mantener.pressed.connect(mantener)
	fila.add_child(_boton_mantener)
	## Con mando o teclado se contesta sin buscar nada: A/Enter mantiene, B/Esc deshace.
	_boton_mantener.grab_focus.call_deferred()

func _process(delta: float) -> void:
	_queda -= delta
	if _queda <= 0.0:
		deshacer()
	else:
		_pintar_cuenta()

func _pintar_cuenta() -> void:
	if _cuenta != null:
		_cuenta.text = Idiomas.t("Si no eliges nada, se deshace solo en %d s.") % int(ceil(maxf(_queda, 0.0)))

func mantener() -> void:
	if is_queued_for_deletion():
		return
	set_process(false)
	queue_free()
	resuelto.emit(true)
	if _al_mantener.is_valid():
		_al_mantener.call()

func deshacer() -> void:
	if is_queued_for_deletion():
		return
	set_process(false)
	queue_free()
	if _deshacer.is_valid():
		_deshacer.call()
	resuelto.emit(false)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		deshacer()
