class_name PanelControles
extends Control
## LA PANTALLA DE CONTROLES (14-10-2026, pedido: «el control debe ser
## configurable»). Esquema de teclado, ayudas (pase, tiro, cambio de jugador,
## dirección del stick) y cada acción reasignable: «Cambiar» y se pulsa la
## tecla o el botón del mando nuevo. Se guarda en `Mando` (user://controles.cfg)
## y se aplica al momento.

signal cerrado

var _lista: VBoxContainer
var _escuchando := ""
var _aviso: Label
var _filas_ayuda := {}
var _botones_esquema := {}

const NOMBRES_AYUDA := {
	"pase": ["Pases", {"asistido": "Asistido (busca al compañero)", "manual": "Manual (al punto que apuntas)"}],
	"tiro": ["Tiros", {"asistido": "Asistido (al palo largo)", "manual": "Manual (apuntas tú)"}],
	"cambio": ["Cambio de jugador", {"auto": "Automático", "semi": "Semi (al recibir)", "manual": "Manual (solo con el botón)"}],
	"direccion": ["Dirección del stick", {"camara": "Según la cámara", "campo": "Según el campo"}],
}

static func abrir(padre: Node) -> PanelControles:
	var n := PanelControles.new()
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	n.z_index = 160
	padre.add_child(n)
	n._montar()
	return n

func _montar() -> void:
	Mando.registrar()
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	caja.custom_minimum_size = Vector2(900, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	caja.add_child(v)
	v.add_child(CuadroDialogo.placa(Idiomas.t("🎮 Controles")))
	## Esquema de teclado.
	var fe := HBoxContainer.new()
	fe.add_theme_constant_override("separation", 6)
	v.add_child(fe)
	fe.add_child(Tema.etiqueta(13, Tema.ORO, Idiomas.t("Teclado:")))
	for e: String in Mando.ESQUEMAS:
		var b := Button.new()
		b.text = Idiomas.t(String(Mando.ESQUEMAS[e]["nombre"]))
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 13)
		_marcar(b)
		b.pressed.connect(func() -> void:
			Mando.fijar_esquema(e)
			_pintar())
		fe.add_child(b)
		_botones_esquema[e] = b
	## Ayudas.
	var rej := GridContainer.new()
	rej.columns = 2
	rej.add_theme_constant_override("h_separation", 12)
	rej.add_theme_constant_override("v_separation", 4)
	v.add_child(rej)
	for k: String in Mando.AYUDAS:
		rej.add_child(Tema.etiqueta(13, Tema.TEXTO, Idiomas.t(String(NOMBRES_AYUDA[k][0]))))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 4)
		rej.add_child(fila)
		var bs := {}
		for op: String in Mando.AYUDAS[k]:
			var b2 := Button.new()
			b2.text = Idiomas.t(String((NOMBRES_AYUDA[k][1] as Dictionary).get(op, op)))
			b2.toggle_mode = true
			b2.focus_mode = Control.FOCUS_NONE
			b2.add_theme_font_size_override("font_size", 12)
			_marcar(b2)
			b2.pressed.connect(func() -> void:
				Mando.fijar_ayuda(k, op)
				_pintar())
			fila.add_child(b2)
			bs[op] = b2
		_filas_ayuda[k] = bs
	v.add_child(HSeparator.new())
	## Cada acción.
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 2)
	v.add_child(_lista)
	_aviso = Tema.etiqueta(13, Tema.SUAVE, "")
	v.add_child(_aviso)
	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	var rest := Button.new()
	rest.text = Idiomas.t("↺ Restaurar de fábrica")
	rest.pressed.connect(func() -> void:
		Mando.restaurar()
		_aviso.text = Idiomas.t("Controles de fábrica.")
		_pintar())
	pie.add_child(rest)
	var listo := Button.new()
	listo.text = Idiomas.t("✔ Listo")
	listo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listo.pressed.connect(cerrar)
	pie.add_child(listo)
	_pintar()

## La opción elegida se lee de un vistazo: letra dorada y borde.
func _marcar(b: Button) -> void:
	b.add_theme_color_override("font_pressed_color", Color("ffd23f"))
	b.add_theme_color_override("font_hover_pressed_color", Color("ffe27a"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.2, 0.05, 0.9)
	sb.border_color = Color("c9a227")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	## Los mismos márgenes que el botón normal, para que no se recorte.
	var normal := b.get_theme_stylebox("normal")
	if normal != null:
		for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			sb.set_content_margin(lado, normal.get_content_margin(lado))
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("hover_pressed", sb)

func _pintar() -> void:
	for e: String in _botones_esquema:
		(_botones_esquema[e] as Button).button_pressed = e == Mando.esquema
	for k: String in _filas_ayuda:
		for op: String in _filas_ayuda[k]:
			(_filas_ayuda[k][op] as Button).button_pressed = Mando.ayuda(k) == op
	for h in _lista.get_children():
		h.queue_free()
	for accion: String in Mando.MAPA:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		_lista.add_child(fila)
		var nom := Tema.etiqueta(13, Tema.TEXTO, Idiomas.t(String(Mando.MAPA[accion][0])))
		nom.custom_minimum_size = Vector2(300, 0)
		fila.add_child(nom)
		var val := Tema.etiqueta(13, Tema.ORO if _escuchando != accion else Color("ffd23f"),
			Idiomas.t("Pulsa una tecla o un botón… (Supr cancela)") if _escuchando == accion else Mando.texto_de(accion))
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(val)
		var b := Button.new()
		b.text = Idiomas.t("Cambiar")
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 12)
		b.custom_minimum_size = Vector2(90, 24)
		b.pressed.connect(func() -> void:
			_escuchando = accion
			_pintar())
		fila.add_child(b)

func _input(ev: InputEvent) -> void:
	if _escuchando == "":
		return
	var vale := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed)
	if not vale:
		return
	get_viewport().set_input_as_handled()
	if ev is InputEventKey and (ev as InputEventKey).keycode == KEY_DELETE:
		_escuchando = ""
		_pintar()
		return
	var accion := _escuchando
	_escuchando = ""
	Mando.reasignar(accion, ev)
	_aviso.text = Idiomas.t("«%s» ahora es: %s") % [Idiomas.t(String(Mando.MAPA[accion][0])), Mando.texto_de(accion)]
	_pintar()

func cerrar() -> void:
	cerrado.emit()
	queue_free()
