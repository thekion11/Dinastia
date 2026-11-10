class_name TecladoPantalla
extends CanvasLayer
## TECLADO EN PANTALLA (2-11-2026, M-441): para escribir nombres solo con el mando en PC o TV. En Android e iOS ya
## sale el del sistema; aquí, cuando un campo de texto recibe el foco y hay un mando conectado, aparece una rejilla
## de teclas que se recorre con la cruceta: ✔ escribe y cierra, ✖ cierra sin tocar nada. Se engancha una vez para
## todo el juego (`vigilar`, desde `Idiomas`), sin tocar los campos uno a uno.
## (10-11, orden 33 del dueño, «Mando (corrección)» de `PLAN_GENERAL.md`) Botones del mando: CUADRADO borra, R2 confirma
## (✔ Aceptar), TRIÁNGULO pone un espacio y L2 cambia mayúsculas/minúsculas; las teclas en pantalla lo dicen.

const FILAS := ["1234567890", "qwertyuiop", "asdfghjklñ", "zxcvbnm-'."]
static var forzar := false          ## las pruebas lo encienden sin mando
static var _abierto: TecladoPantalla = null
static var _saltar_foco := false    ## al devolver el foco al campo, no reabrir

var objetivo: LineEdit
var _mayus := true
var _teclas: Array[Button] = []

static func vigilar(arbol: SceneTree) -> void:
	if arbol != null and arbol.root != null and not arbol.root.gui_focus_changed.is_connected(_al_enfocar):
		arbol.root.gui_focus_changed.connect(_al_enfocar)

static func hace_falta() -> bool:
	if forzar:
		return true
	return not OS.has_feature("mobile") and not Input.get_connected_joypads().is_empty()

static func _al_enfocar(c: Control) -> void:
	if _saltar_foco:
		_saltar_foco = false
		return
	if not (c is LineEdit) or not (c as LineEdit).editable or not hace_falta():
		return
	if _abierto != null and is_instance_valid(_abierto):
		return
	abrir(c as LineEdit)

static func abrir(campo: LineEdit) -> TecladoPantalla:
	var t := TecladoPantalla.new()
	t.objetivo = campo
	t.layer = 120
	campo.get_tree().root.add_child.call_deferred(t)   ## el foco puede llegar mientras la raíz monta sus hijos
	_abierto = t
	return t

func _ready() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -24
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var vista := Label.new()
	vista.name = "Vista"
	vista.add_theme_font_size_override("font_size", 20)
	col.add_child(vista)
	for fila: String in FILAS:
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(h)
		for ch in fila:
			var b := _tecla(h, ch, 48)
			b.pressed.connect(_escribir.bind(ch))
			_teclas.append(b)
	var abajo := HBoxContainer.new()
	abajo.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(abajo)
	_tecla(abajo, Idiomas.t("⇧ Mayús") + " (L2)", 140).pressed.connect(_cambiar_mayus)
	_tecla(abajo, Idiomas.t("Espacio") + " (△)", 200).pressed.connect(_escribir.bind(" "))
	_tecla(abajo, "⌫ (□)", 100).pressed.connect(_borrar)
	_tecla(abajo, Idiomas.t("✔ Aceptar") + " (R2)", 170).pressed.connect(aceptar)
	_tecla(abajo, Idiomas.t("✖ Cerrar"), 110).pressed.connect(cerrar)
	_rotular()
	if not _teclas.is_empty():
		_teclas[10].grab_focus.call_deferred()   ## la «q»: arriba a la izquierda de las letras

func _tecla(padre: Node, texto: String, ancho: int) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(ancho, 44)
	b.add_theme_font_size_override("font_size", 18)
	padre.add_child(b)
	return b

func _rotular() -> void:
	if _teclas.size() < 40:
		return
	var i := 0
	for fila: String in FILAS:
		for ch in fila:
			_teclas[i].text = ch.to_upper() if _mayus else ch
			i += 1
	var v := find_child("Vista", true, false) as Label
	if v != null and is_instance_valid(objetivo):
		v.text = objetivo.text + "▏"

func _escribir(ch: String) -> void:
	if not is_instance_valid(objetivo):
		return
	var nuevo := objetivo.text + (ch.to_upper() if _mayus else ch)
	if objetivo.max_length > 0 and nuevo.length() > objetivo.max_length:
		return
	objetivo.text = nuevo
	objetivo.caret_column = nuevo.length()
	objetivo.text_changed.emit(nuevo)
	if _mayus and ch != " ":
		_mayus = false   ## como en el móvil: mayúscula solo para la primera
	_rotular()

func _borrar() -> void:
	if not is_instance_valid(objetivo) or objetivo.text.is_empty():
		return
	objetivo.text = objetivo.text.left(-1)
	objetivo.caret_column = objetivo.text.length()
	objetivo.text_changed.emit(objetivo.text)
	_rotular()

func aceptar() -> void:
	if is_instance_valid(objetivo):
		objetivo.text_submitted.emit(objetivo.text)
	cerrar()

func cerrar() -> void:
	if is_instance_valid(objetivo) and objetivo.is_inside_tree():
		_saltar_foco = true
		objetivo.grab_focus()
	_abierto = null
	queue_free()

func _cambiar_mayus() -> void:
	_mayus = not _mayus
	_rotular()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()

const UMBRAL_GATILLO := 0.6
var _gatillos := {}   ## eje → apretado (para que R2/L2 cuenten una vez por pulsación)

## Los botones del mando de la orden 33. En `_input` (antes que la principal, que usa R2/L2 para cambiar de bloque).
func _input(ev: InputEvent) -> void:
	if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed:
		match (ev as InputEventJoypadButton).button_index:
			JOY_BUTTON_X:
				_borrar()
			JOY_BUTTON_Y:
				_escribir(" ")
			_:
				return
		get_viewport().set_input_as_handled()
	elif ev is InputEventJoypadMotion:
		var m := ev as InputEventJoypadMotion
		if m.axis != JOY_AXIS_TRIGGER_RIGHT and m.axis != JOY_AXIS_TRIGGER_LEFT:
			return
		var antes := bool(_gatillos.get(m.axis, false))
		var ahora := m.axis_value >= UMBRAL_GATILLO
		_gatillos[m.axis] = ahora
		get_viewport().set_input_as_handled()
		if ahora and not antes:
			if m.axis == JOY_AXIS_TRIGGER_RIGHT:
				aceptar()
			else:
				_cambiar_mayus()
