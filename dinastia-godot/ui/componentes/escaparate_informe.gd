class_name EscaparateInforme
extends Control
## LA PANTALLA COMPLETA DEL «INFORME DE LA SEMANA» (17-11-2026, cuarta ronda del menú central): se abre desde su tarjeta de «Información del club» y enseña `InformeSemana.pintar_en` con
## letra grande (cada aviso con su botón a la pantalla que lo arregla). Se alcanza con mando (el foco empieza en el primer aviso) y con teclado; Esc / B / «Volver» la cierran.

signal cerrada

var _volver: Button

static func abrir(p: Principal, padre: Control) -> EscaparateInforme:
	var n := EscaparateInforme.new()
	n.name = "InformeSemana"
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar(p)
	return n

func _montar(p: Principal) -> void:
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
	vb.add_child(barra)
	var res := InformeSemana.resumen(p)
	var tit := EstiloAvanzar.etiqueta("%s  ·  %s" % [Idiomas.t("Mensajes"), Idiomas.t("%d avisos urgentes") % int(res["graves"])], 26, Color.WHITE, true)
	barra.add_child(tit)
	var margen := MarginContainer.new()
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for lado: String in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	vb.add_child(margen)
	var desliza := ScrollContainer.new()   ## el informe puede traer muchos avisos: solo aquí se desliza
	desliza.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margen.add_child(desliza)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 12)
	desliza.add_child(lista)
	var sin := EscaparatePie.sin_leer(p) - int(res["graves"])   ## (17-11) «Mensajes · N»: el correo, las noticias recientes y el informe de la semana, juntos
	var correo := Button.new()
	correo.text = "✉  " + Idiomas.t("Correo") + ("  (%d)" % sin if sin > 0 else "")
	correo.custom_minimum_size = Vector2(0, 52)
	correo.alignment = HORIZONTAL_ALIGNMENT_LEFT
	correo.add_theme_font_size_override("font_size", Tema.letra(18))
	correo.pressed.connect(func() -> void:
		cerrar()
		TableroInicio.abrir(p, "Correo"))
	lista.add_child(correo)
	var bandeja: Variant = p.get("_bandeja")
	if bandeja is Array:
		for x: Dictionary in (bandeja as Array).slice(0, 4):
			var nt := EstiloAvanzar.etiqueta("• " + String(x.get("titulo", "")), 18, Color(1, 1, 1, 0.9))
			nt.clip_text = true
			lista.add_child(nt)
	lista.add_child(EstiloAvanzar.etiqueta(Idiomas.t("Informe de la semana").to_upper(), 16, Color(1, 1, 1, 0.7), true))
	InformeSemana.pintar_en(p, lista, true, func() -> void: cerrar())
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
	var primero: Button = null
	for b in lista.find_children("*", "Button", true, false):
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
