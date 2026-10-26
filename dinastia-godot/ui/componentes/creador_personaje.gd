class_name CreadorPersonaje
extends "res://ui/componentes/creador_personaje_p1.gd"
## [Capa 2/2 de `creador_personaje.gd`] _montar y el teclado.

func _montar() -> void:
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var marco := MarginContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 24)
	add_child(marco)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	marco.add_child(vb)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	vb.add_child(cab)
	var t := Tema.etiqueta(Tema.TAM_TITULO + 4, Tema.ORO, Idiomas.t("🧍 TU PERSONAJE"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	for par: Array in [["🎲 Al azar", _aleatorio], ["↶ Deshacer", _deshacer], ["Cancelar", _cancelar], ["💾 Guardar", _guardar]]:
		var b := Button.new()
		b.text = Idiomas.t(String(par[0]))
		b.custom_minimum_size = Vector2(130, 40)
		b.pressed.connect(par[1])
		cab.add_child(b)
		if String(par[0]) == "↶ Deshacer":
			_b_deshacer = b
			b.disabled = true
	_aviso = Tema.etiqueta(Tema.TAM_CUERPO, Tema.MAL, "")
	_aviso.visible = false
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_aviso)
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	vb.add_child(cuerpo)
	## Mismo reparto siempre (antes la vista 3D se encogía o crecía según la
	## pestaña abierta, porque cada hoja pedía un ancho distinto).
	_estudio = EstudioPersonaje.new()
	_estudio.c1 = _c1
	_estudio.c2 = _c2
	_estudio.custom_minimum_size = Vector2(420, 480)
	_estudio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_estudio.size_flags_stretch_ratio = 1.0
	cuerpo.add_child(_estudio)
	_pestanas = HojasPersonaje.new()
	_pestanas.c1 = _c1
	_pestanas.c2 = _c2
	_pestanas.asp = _original.duplicate()
	_pestanas.hoja_extra = _hoja_conjuntos
	_pestanas.hoja_extra_titulo = "Conjuntos"
	_pestanas.custom_minimum_size = Vector2(520, 0)
	_pestanas.size_flags_stretch_ratio = 1.1
	_pestanas.cambiado.connect(_al_cambiar)
	cuerpo.add_child(_pestanas)
	_estudio.mostrar(_original, true)
	Animar.aparecer(marco)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cancelar()
