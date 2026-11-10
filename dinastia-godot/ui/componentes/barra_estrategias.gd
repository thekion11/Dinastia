class_name BarraEstrategias
extends HBoxContainer
## LA BARRA DE ESTRATEGIAS RÁPIDAS DEL PARTIDO (10-11, idea del PES aprobada por el dueño): cuatro botones abajo al centro (⚔ Ataque total, 🔥 Presión
## arriba, ⚡ Contraataque, 🔒 Cerrojo) que cambian el plan sin parar el partido (`EstrategiaRapida`). Atajos: Alt+1…4 en el teclado (1-4 solos son las
## cámaras; Ctrl es la rosca) y L2 + cruceta en el mando (como en el PES). La activa va resaltada; tras un cambio hay que esperar `EstrategiaRapida.ESPERA` minutos.
## Solo en TU partido. `est` es la vista del estadio (`VistaEstadio`): se le piden `partido`, `_mi_lado` y `_actualizar_tacticas()` por nombre.
const CRUCETA := [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_DOWN]

var est: Control
var logica := EstrategiaRapida.new()
var _botones: Array[Button] = []
var _aviso: Label

static func poner(estadio: Control) -> BarraEstrategias:
	var b := BarraEstrategias.new()
	b.est = estadio
	b.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	b.grow_horizontal = Control.GROW_DIRECTION_BOTH
	b.grow_vertical = Control.GROW_DIRECTION_BEGIN
	b.offset_bottom = -64
	b.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_theme_constant_override("separation", 6)
	b.z_index = 5
	estadio.add_child(b)
	b._montar()
	return b

func _montar() -> void:
	for i in EstrategiaRapida.ORDEN.size():
		var clave: String = EstrategiaRapida.ORDEN[i]
		var p: Array = EstrategiaRapida.PRESETS[clave]
		var bt := Button.new()
		bt.text = "%s %s" % [p[0], Idiomas.t(String(p[1]))]
		bt.tooltip_text = "%s (Alt+%d · L2 + %s)" % [Idiomas.t(String(p[1])), i + 1, ["▲", "▶", "◀", "▼"][i]]
		bt.focus_mode = Control.FOCUS_NONE
		bt.add_theme_font_size_override("font_size", Tema.letra(12))
		bt.pressed.connect(func() -> void: elegir(clave))
		add_child(bt)
		_botones.append(bt)
	_aviso = Label.new()
	_aviso.add_theme_font_size_override("font_size", Tema.letra(11))
	_aviso.add_theme_color_override("font_color", Tema.ORO)
	add_child(_aviso)
	_pintar()

## Aplica (o quita) una estrategia en tu club y avisa al motor.
func elegir(clave: String) -> void:
	var partido: Partido = est.get("partido")
	var lado := int(est.get("_mi_lado"))
	if partido == null or lado < 0 or partido.terminado_ya:
		return
	var club: Club = partido.local if lado == 0 else partido.visita
	var r := logica.aplicar(club, clave, partido.minuto)
	if r == "espera":
		_aviso.text = Idiomas.t("Espera un poco para otro cambio")
		return
	partido.invalidar_fuerza()
	if est.has_method("_actualizar_tacticas"):
		est.call("_actualizar_tacticas")
	_aviso.text = Idiomas.t(String(EstrategiaRapida.PRESETS[clave][1])) if logica.activa != "" else Idiomas.t("Plan de siempre")
	_pintar()

func _pintar() -> void:
	for i in _botones.size():
		var activa: bool = EstrategiaRapida.ORDEN[i] == logica.activa
		var st := StyleBoxFlat.new()
		st.bg_color = Color(Tema.ORO, 0.55) if activa else Color(0, 0, 0, 0.55)
		st.border_color = Tema.ORO if activa else Color(1, 1, 1, 0.25)
		st.set_border_width_all(2 if activa else 1)
		st.set_corner_radius_all(8)
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 4
		st.content_margin_bottom = 4
		for estado: String in ["normal", "hover", "pressed"]:
			_botones[i].add_theme_stylebox_override(estado, st)

func _input(e: InputEvent) -> void:
	var i := -1
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).alt_pressed:
		var k := int((e as InputEventKey).keycode) - int(KEY_1)
		if k >= 0 and k < 4:
			i = k
	elif e is InputEventJoypadButton and e.pressed and Input.get_joy_axis((e as InputEventJoypadButton).device, JOY_AXIS_TRIGGER_LEFT) > 0.5:
		i = CRUCETA.find((e as InputEventJoypadButton).button_index)
	if i >= 0:
		get_viewport().set_input_as_handled()
		elegir(EstrategiaRapida.ORDEN[i])
