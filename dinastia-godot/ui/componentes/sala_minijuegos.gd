class_name SalaMinijuegos
extends Control
## LA SALA DE MINIJUEGOS (7-10-2026). Pregunta del usuario: «recuerdo que
## existían minijuegos, ¿se perdieron?». No se perdieron, pero el de penales
## estaba escondido en una lista de Mi carrera. Ahora los tres tienen su
## puerta en Mi Vida → «Minijuegos»: penales, tiros libres y la trivia del
## club, cada uno con su récord.

static func abrir(p: Control, mundo: Mundo) -> SalaMinijuegos:
	var s := SalaMinijuegos.new()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.mouse_filter = Control.MOUSE_FILTER_STOP
	p.add_child(s)
	s._montar(p, mundo)
	return s

func _montar(p: Control, mundo: Mundo) -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.05, 0.08, 0.96)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	centro.add_child(v)
	var t := Label.new()
	t.text = "🎮 MINIJUEGOS"
	t.add_theme_font_size_override("font_size", 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	v.add_child(fila)
	var juegos := [
		["🎯", "Tanda de penales", "Cinco penales contra un portero que aprende.", func() -> void: MinijuegoPenales.mostrar(p, mundo)],
		["🧱", "Tiros libres", "Barrera, rosca y una barra de potencia.\nRécord: %d de 5" % MinijuegoTiroLibre.record, func() -> void: MinijuegoTiroLibre.mostrar(p, mundo)],
		["🧠", "Trivia del club", "Preguntas sobre tu propio plantel y tu estadio.\nRécord: %d" % TriviaClub.record, func() -> void: TriviaClub.mostrar(p, mundo)],
	]
	for j: Array in juegos:
		var caja := PanelContainer.new()
		caja.custom_minimum_size = Vector2(250, 230)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.12, 0.18)
		sb.border_color = Color(0.35, 0.55, 0.9)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		sb.content_margin_left = 16; sb.content_margin_right = 16
		sb.content_margin_top = 14; sb.content_margin_bottom = 14
		caja.add_theme_stylebox_override("panel", sb)
		fila.add_child(caja)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 8)
		caja.add_child(cv)
		var ic := Label.new()
		ic.text = String(j[0])
		ic.add_theme_font_size_override("font_size", 48)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(ic)
		var nom := Label.new()
		nom.text = String(j[1])
		nom.add_theme_font_size_override("font_size", 20)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nom)
		var d := Label.new()
		d.text = String(j[2])
		d.add_theme_font_size_override("font_size", 13)
		d.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(d)
		var b := Button.new()
		b.text = "Jugar"
		b.custom_minimum_size = Vector2(0, 40)
		var accion: Callable = j[3]
		b.pressed.connect(func() -> void:
			queue_free()
			accion.call())
		cv.add_child(b)
	var cerrar := Button.new()
	cerrar.text = "Volver"
	cerrar.pressed.connect(queue_free)
	v.add_child(cerrar)
