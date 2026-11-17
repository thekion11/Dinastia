class_name PopupPartidoJugado
extends PanelContainer
## EL POPUP DE «PARTIDO JUGADO ▲» (17-11-2026, como la maqueta): una tarjeta blanca sobre el botón con «Jugar partido de nuevo», «Ver partido» y «Jugar momentos específicos»
## (que se abre en Ofensivas / Defensivas / Todas). Emite `elegido("repetir" | "ver" | "momentos:ofensivas" | "momentos:defensivas" | "momentos:todas")` y se cierra sola.

signal elegido(op: String)

var _sub: VBoxContainer

## Lo abre sobre `ancla` (el botón «Partido jugado»), dentro de `padre` (un nodo de la pantalla principal).
static func abrir(padre: Node, ancla: Control) -> PopupPartidoJugado:
	var p := PopupPartidoJugado.new()
	padre.add_child(p)
	p.top_level = true
	p._armar()
	p.reset_size()
	p.position = Vector2(ancla.global_position.x + ancla.size.x - p.size.x, ancla.global_position.y - p.size.y - 8.0)
	p.position.x = maxf(p.position.x, 8.0)
	return p

func _armar() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 16
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	_fila(v, "repetir", "repetir", "Jugar partido de nuevo")
	_fila(v, "ojo", "ver", "Ver partido")
	v.add_child(HSeparator.new())
	var b := _fila(v, "rayo", "", "Jugar momentos específicos")
	_sub = VBoxContainer.new()
	_sub.add_theme_constant_override("separation", 2)
	var marco := MarginContainer.new()
	marco.add_theme_constant_override("margin_left", 12)
	marco.add_child(_sub)
	v.add_child(marco)
	for par: Array in [["ofensivas", "Ofensivas"], ["defensivas", "Defensivas"], ["todas", "Todas"]]:
		var s := _texto_boton(String(par[1]), 17)
		var clave := String(par[0])
		s.pressed.connect(func() -> void: _elegir("momentos:" + clave))
		_sub.add_child(s)
	_sub.visible = false
	b.pressed.connect(func() -> void: _sub.visible = not _sub.visible; reset_size())
	(v.get_child(0) as Control).call_deferred("grab_focus")

func _texto_boton(texto: String, tam: int) -> Button:
	var b := Button.new()
	b.text = Idiomas.t(texto)
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", Tema.letra(tam))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(c, Color("1b2340"))
	b.focus_mode = Control.FOCUS_ALL
	return b

func _fila(v: VBoxContainer, icono: String, op: String, texto: String) -> Button:
	var b := _texto_boton(texto, 19)
	b.icon = EstiloAvanzar.icono(icono, Color("c8102e"), 26)
	b.add_theme_constant_override("h_separation", 12)
	if op != "":
		b.pressed.connect(func() -> void: _elegir(op))
	v.add_child(b)
	return b

func _elegir(op: String) -> void:
	elegido.emit(op)
	queue_free()

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and not get_global_rect().has_point(e.position):
		queue_free()
	elif e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
