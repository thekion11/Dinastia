extends "res://ui/componentes/telefono_p3.gd"
## [Capa 4/5 de `telefono.gd`] _montar_carcasa, _montar_barra_estado, _montar_lista (el montaje del móvil, separado para no pasar de 450 líneas).

## La carcasa del móvil: borde, pantalla, papel de fondo, isla y la columna principal (que se devuelve).
func _montar_carcasa() -> VBoxContainer:
	var borde := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		borde.add_theme_constant_override("margin_" + k, 10)
	add_child(borde)
	var pantalla := PanelContainer.new()
	var sb := Tema.caja(FONDO_APP, 26, Color(0, 0, 0))
	sb.set_content_margin_all(0)
	pantalla.add_theme_stylebox_override("panel", sb)
	pantalla.clip_contents = true
	borde.add_child(pantalla)
	_papel = TextureRect.new()
	_papel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_papel.stretch_mode = TextureRect.STRETCH_SCALE
	_papel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pantalla.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pantalla.add_child(v)
	## La «isla» de la cámara frontal, centrada arriba.
	var isla := Panel.new()
	isla.add_theme_stylebox_override("panel", Tema.caja(Color(0, 0, 0), 11, Color(0, 0, 0)))
	isla.custom_minimum_size = Vector2(92, 24)
	isla.anchor_left = 0.5
	isla.anchor_right = 0.5
	isla.offset_left = -46
	isla.offset_right = 46
	isla.offset_top = 8
	isla.offset_bottom = 32
	isla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## Dentro de un Control libre: el PanelContainer estiraría la isla a toda la pantalla.
	var capa := Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(isla)
	pantalla.add_child(capa)
	return v

## La barra de estado (hora, señal y el aviso).
func _montar_barra_estado(v: VBoxContainer) -> void:
	## Barra de estado.
	var estado := HBoxContainer.new()
	estado.custom_minimum_size = Vector2(0, 40)
	var hora := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "   " + _hora())
	hora.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	estado.add_child(hora)
	estado.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "▂▄▆ 5G  🔋 82%   "))
	v.add_child(estado)
	_aviso = Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, "")
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.add_theme_stylebox_override("normal", _estilo_aviso())
	_aviso.visible = false
	v.add_child(_aviso)

## La lista desplazable de las apps (con su cuerpo).
func _montar_lista(v: VBoxContainer) -> void:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	## Con teclado o mando la lista se desplaza sola hasta el botón enfocado.
	_scroll.follow_focus = true
	v.add_child(_scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + k, 8)
	_scroll.add_child(margen)
	_cuerpo = VBoxContainer.new()
	_cuerpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_theme_constant_override("separation", 8)
	margen.add_child(_cuerpo)
