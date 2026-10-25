class_name PersonajeConfirmacion
extends RefCounted
## LA CONFIRMACIÓN DE LA ETAPA «PERSONAJE» (25-10-2026): una tarjeta sobre la
## propia etapa con el retrato 2D (el de las fichas y la prensa, sacado del 3D),
## el resumen de los datos y dos salidas: seguir editando o «Sí, ese soy yo».
## Es parte de la etapa, no otra pantalla: la regla del dueño es que cada etapa
## pida confirmación al rellenarla.

static func crear(p: Dictionary, c1: Color, cancelar: Callable, aceptar: Callable) -> Control:
	var capa := ColorRect.new()
	capa.name = "Confirmacion"
	capa.color = Color(0, 0, 0, 0.66)
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var caja := PanelContainer.new()
	var e := Tema.caja(Color("131d17"), Tema.RADIO_GRANDE, Tema.ORO)
	e.set_border_width_all(2)
	e.border_width_top = 6
	e.border_color = Tema.ORO
	e.content_margin_left = 28
	e.content_margin_right = 28
	e.content_margin_top = 22
	e.content_margin_bottom = 22
	caja.add_theme_stylebox_override("panel", e)
	caja.custom_minimum_size = Vector2(640, 0)
	centro.add_child(caja)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	caja.add_child(vb)
	vb.add_child(Tema.etiqueta(Tema.TAM_TITULO + 4, Tema.ORO, Idiomas.t("¿Empezamos así?")))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 22)
	vb.add_child(fila)
	## El retrato 2D con el aro del club, como sale en la prensa.
	var col_r := VBoxContainer.new()
	col_r.add_theme_constant_override("separation", 6)
	fila.add_child(col_r)
	var marco := PanelContainer.new()
	var em := Tema.caja(Color("0c1410"), 70, c1 if c1.get_luminance() > 0.2 else c1.lightened(0.35))
	em.set_border_width_all(4)
	em.content_margin_left = 6
	em.content_margin_right = 6
	em.content_margin_top = 6
	em.content_margin_bottom = 6
	marco.add_theme_stylebox_override("panel", em)
	col_r.add_child(marco)
	var look := CaraDT.look_por_defecto()
	for k: String in (p.get("look", {}) as Dictionary):
		look[k] = p["look"][k]
	var img := TextureRect.new()
	img.texture = CaraDT.textura(look, 128)
	img.custom_minimum_size = Vector2(128, 128)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marco.add_child(img)
	var pie := Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("Así sales en las fichas"))
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_r.add_child(pie)
	## El resumen.
	var datos := GridContainer.new()
	datos.columns = 2
	datos.add_theme_constant_override("h_separation", 18)
	datos.add_theme_constant_override("v_separation", 8)
	datos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(datos)
	var filas := [["Nombre", String(p["nombre_completo"])],
		["Edad", Idiomas.t("%d años") % int(p["edad"])],
		["Nacionalidad", PersonajeDatos.nombre_pais(String(p["nacionalidad"]))],
		["Idea de fútbol", PersonajeDatos.nombre_estilo(String(p["estilo"]))],
		["Ante la prensa", PersonajeDatos.nombre_comunicacion(String(p["comunicacion"]))],
		["Cuerpo", Idiomas.t("Mujer") if bool(p["mujer"]) else Idiomas.t("Hombre")]]
	for f: Array in filas:
		datos.add_child(Tema.rotulo(Idiomas.t(String(f[0]))))
		var v := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, String(f[1]))
		if String(f[0]) == "Nacionalidad":
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			var b := TextureRect.new()
			b.texture = Banderas.textura(String(p["nacionalidad"]))
			b.custom_minimum_size = Vector2(30, 20)
			b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
			h.add_child(v)
			datos.add_child(h)
		else:
			datos.add_child(v)
	var nota := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE,
		Idiomas.t("Tu nombre y tus datos no se podrán cambiar después. El aspecto, sí: en el menú, «Mi personaje»."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nota)
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 10)
	botones.alignment = BoxContainer.ALIGNMENT_END
	vb.add_child(botones)
	var b_no := Button.new()
	b_no.text = Idiomas.t("Seguir editando")
	b_no.custom_minimum_size = Vector2(170, 46)
	b_no.pressed.connect(cancelar)
	botones.add_child(b_no)
	var b_si := Button.new()
	b_si.name = "Aceptar"
	b_si.text = Idiomas.t("Sí, ese soy yo") if not bool(p["mujer"]) else Idiomas.t("Sí, esa soy yo")
	b_si.custom_minimum_size = Vector2(200, 46)
	for estado: String in ["normal", "hover", "pressed"]:
		b_si.add_theme_stylebox_override(estado, Tema.caja(Tema.ORO if estado != "hover" else Tema.ORO.lightened(0.15), Tema.RADIO, Tema.ORO))
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b_si.add_theme_color_override(c, Color("14110a"))
	b_si.pressed.connect(aceptar)
	botones.add_child(b_si)
	b_si.call_deferred("grab_focus")
	Animar.aparecer(caja)
	return capa
