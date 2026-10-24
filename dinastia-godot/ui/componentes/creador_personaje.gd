class_name CreadorPersonaje
extends "res://ui/componentes/creador_personaje_p1.gd"
## [Capa 2/2 de `creador_personaje.gd`] _montar, _process, _unhandled_input

func _montar() -> void:
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var marco := MarginContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 24)
	add_child(marco)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	marco.add_child(vb)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	vb.add_child(cab)
	var t := Tema.etiqueta(Tema.TAM_TITULO + 4, Tema.ORO, "🧍 TU PERSONAJE")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	for par: Array in [["🎲 Aleatorio", _aleatorio], ["↶ Deshacer", _deshacer], ["Cancelar", _cerrar], ["💾 Guardar", _guardar]]:
		var b := Button.new()
		b.text = String(par[0])
		b.custom_minimum_size = Vector2(130, 40)
		b.pressed.connect(par[1])
		cab.add_child(b)
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	vb.add_child(cuerpo)
	cuerpo.add_child(_estudio())
	_pestanas = TabContainer.new()
	_pestanas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pestanas.custom_minimum_size = Vector2(460, 0)
	cuerpo.add_child(_pestanas)
	_pintar_pestanas()
	_rearmar()
	Animar.aparecer(marco)

func _process(delta: float) -> void:
	if _pivote != null and _girar:
		_pivote.rotation.y += delta * 0.6
	if _pendiente > 0.0:
		_pendiente -= delta
		if _pendiente <= 0.0:
			_rearmar()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cerrar()
