class_name EscaparatePanel
extends Control
## UNA PANTALLA COMPLETA DEL ESCAPARATE (17-11-2026): barra del color del club con su título, el contenido (lo pinta quien la abre en `contenedor`, con desplazamiento solo aquí),
## el pie con las ayudas del aparato y «Volver». Esc / B / «Volver» la cierran (`cerrada`). El foco empieza en el primer botón del contenido, o en «Volver».
## La usa «Despacho» (los asuntos de decisión del DT, que viven en `p._despacho`); el informe de la semana tiene la suya (`EscaparateInforme`).

signal cerrada

var contenedor: VBoxContainer
var _volver: Button

static func abrir(p: Principal, padre: Control, titulo: String) -> EscaparatePanel:
	var n := EscaparatePanel.new()
	n.name = "Panel"
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(p, titulo)
	return n

func _montar(p: Principal, titulo: String) -> void:
	var c: Club = p.mundo.mi_club()
	var fondo := ColorRect.new()
	fondo.color = Color(0.035, 0.05, 0.085, 0.985)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 0)
	add_child(vb)
	var barra := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = EscaparateBarra.color_de(c)
	sb.content_margin_left = 24; sb.content_margin_right = 24; sb.content_margin_top = 10; sb.content_margin_bottom = 10
	barra.add_theme_stylebox_override("panel", sb)
	barra.add_child(EstiloAvanzar.etiqueta(titulo, 26, Color.WHITE, true))
	vb.add_child(barra)
	var margen := MarginContainer.new()
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado: String in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	vb.add_child(margen)
	var desliza := ScrollContainer.new()
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margen.add_child(desliza)
	contenedor = VBoxContainer.new()
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.add_theme_constant_override("separation", 12)
	desliza.add_child(contenedor)
	var pie := PanelContainer.new()
	pie.custom_minimum_size.y = 64
	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0, 0, 0, 0.55)
	sp.content_margin_left = 24; sp.content_margin_right = 24
	pie.add_theme_stylebox_override("panel", sp)
	vb.add_child(pie)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	pie.add_child(fila)
	if Mando.hay_mando():
		fila.add_child(PieMando._chip("R2 / A", Idiomas.t("Confirmar")))
		fila.add_child(PieMando._chip("Cuadrado / B", Idiomas.t("Atrás")))
	elif not DisplayServer.is_touchscreen_available():
		fila.add_child(PieMando._chip(Idiomas.t("Intro"), Idiomas.t("Confirmar")))
		fila.add_child(PieMando._chip(Idiomas.t("Esc"), Idiomas.t("Atrás")))
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(hueco)
	_volver = Button.new()
	_volver.text = Idiomas.t("Volver")
	_volver.custom_minimum_size = Vector2(180, 44)
	_volver.pressed.connect(cerrar)
	fila.add_child(_volver)

## El foco al primer botón del contenido (llamar cuando ya se pintó), o a «Volver».
func enfocar() -> void:
	var primero: Button = null
	for b in contenedor.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and (b as Button).focus_mode != Control.FOCUS_NONE:
			primero = b as Button
			break
	(primero if primero != null else _volver).grab_focus.call_deferred()

func cerrar() -> void:
	cerrada.emit()
	queue_free()

func _unhandled_input(e: InputEvent) -> void:
	if is_visible_in_tree() and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()
