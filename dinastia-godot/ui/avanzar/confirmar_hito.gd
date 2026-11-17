class_name ConfirmarHito
extends PantallaMaqueta
## EL DIÁLOGO DE CONFIRMACIÓN DE UN HITO (17-11-2026, como el avance del PES 2020): antes de pasar de un día que cierra algo importante (el último día del mercado),
## «Avanzarás al día siguiente. El mercado de fichajes cerrará. ¿Quieres continuar?» con No y Sí. Emite `elegido("si")` o `elegido("no")`; Esc / B = No.

static func mostrar(pr: Node, texto: String) -> ConfirmarHito:
	var d := ConfirmarHito.new()
	d._armar(pr, texto)
	return d

func _armar(pr: Node, texto: String) -> void:
	montar(pr, FondoCine.Modo.NOCHE, Color("0b1330"))
	var vel := ColorRect.new()
	vel.color = Color(0, 0, 0, 0.5)
	vel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(vel)
	var caja := PanelContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.custom_minimum_size = Vector2(760, 0)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("101a36")
	sb.border_color = Color("c8102e")
	sb.set_border_width_all(3)
	sb.set_content_margin_all(32)
	caja.add_theme_stylebox_override("panel", sb)
	_raiz.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 26)
	caja.add_child(v)
	var t := EstiloAvanzar.etiqueta(texto, 30, EstiloAvanzar.TINTA)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 24)
	v.add_child(fila)
	var no := boton(Idiomas.t("No"), false)
	var si := boton(Idiomas.t("Sí"), true)
	for b: Button in [no, si]:
		b.custom_minimum_size = Vector2(200, 58)
		fila.add_child(b)
	no.pressed.connect(func() -> void: elegido.emit("no"))
	si.pressed.connect(func() -> void: elegido.emit("si"))
	no.grab_focus.call_deferred()   ## el foco empieza en «No»: un clic de más no cierra el mercado

func _input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		elegido.emit("no")
