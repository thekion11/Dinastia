class_name PantallaPersonaje
extends "res://ui/entrada/personaje_p1.gd"
## [Capa 2/2 de `personaje.gd`] la pantalla: estudio 3D y ficha a la izquierda,
## Aspecto / Datos a la derecha, la botonera y la CONFIRMACIÓN.
##
## Estética propia de la etapa: fondo de estudio con el foco del color del
## club, el título grande «¿Quién eres?» y la ficha de acreditación (bandera,
## nombre, edad y estilo) que se rellena en vivo bajo el personaje.

var _titulo_paso: Label
var _b_secciones := {}
var _contenido: Control
var _b_atras: Button
var _b_deshacer: Button
var _b_siguiente: Button
var _ficha_bandera: TextureRect
var _ficha_nombre: Label
var _ficha_linea: Label
var _aviso: Label
var _capa_confirmar: Control = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var veladura := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("16241b"), Color("0a110d")])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(1, 1)
	veladura.texture = t
	veladura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veladura.set_anchors_preset(Control.PRESET_FULL_RECT)
	veladura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veladura)
	var marco := MarginContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right", "top", "bottom"]:
		marco.add_theme_constant_override("margin_" + lado, 28 if lado in ["left", "right"] else 22)
	add_child(marco)
	var cuerpo := HBoxContainer.new()
	cuerpo.add_theme_constant_override("separation", 26)
	marco.add_child(cuerpo)
	cuerpo.add_child(_columna_estudio())
	cuerpo.add_child(_columna_editor())
	_ir_a("aspecto")
	_refrescar()
	_estudio.mostrar(_hojas.asp, true)
	Animar.aparecer(marco)

func _columna_estudio() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_stretch_ratio = 1.0
	vb.add_theme_constant_override("separation", 12)
	_estudio = EstudioPersonaje.new()
	_estudio.c1 = _c1
	_estudio.c2 = _c2
	_estudio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_estudio.custom_minimum_size = Vector2(380, 380)
	var borde := PanelContainer.new()
	var e := Tema.caja(Color("0b120e"), Tema.RADIO_GRANDE, Color("ffffff14"))
	e.content_margin_left = 0
	e.content_margin_right = 0
	e.content_margin_top = 0
	e.content_margin_bottom = 0
	borde.add_theme_stylebox_override("panel", e)
	borde.size_flags_vertical = Control.SIZE_EXPAND_FILL
	borde.add_child(_estudio)
	vb.add_child(borde)
	vb.add_child(_ficha())
	return vb

## La ficha de acreditación bajo el personaje, con la franja del club.
func _ficha() -> Control:
	var pc := PanelContainer.new()
	var e := Tema.caja(Color("101914"), Tema.RADIO, Tema.ORO.darkened(0.35))
	e.border_width_left = 6
	e.border_color = Tema.ORO.darkened(0.2)
	e.content_margin_left = 18
	pc.add_theme_stylebox_override("panel", e)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	pc.add_child(fila)
	_ficha_bandera = TextureRect.new()
	_ficha_bandera.custom_minimum_size = Vector2(54, 36)
	_ficha_bandera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ficha_bandera.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ficha_bandera.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_ficha_bandera)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(col)
	_ficha_nombre = Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO, "")
	_ficha_nombre.clip_text = true
	col.add_child(_ficha_nombre)
	_ficha_linea = Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "")
	_ficha_linea.clip_text = true
	col.add_child(_ficha_linea)
	return pc

func _columna_editor() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_stretch_ratio = 1.0
	vb.custom_minimum_size = Vector2(540, 0)
	vb.add_theme_constant_override("separation", 10)
	_titulo_paso = Tema.etiqueta(Tema.TAM_ROTULO + 1, Tema.ORO, "")
	vb.add_child(_titulo_paso)
	var titulo := Tema.etiqueta(Tema.TAM_MARCADOR, Tema.TEXTO, Idiomas.t("¿Quién eres?"))
	vb.add_child(titulo)
	var sub := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE,
		Idiomas.t("Así te verán en la banda, en la prensa y por la ciudad. El aspecto podrás cambiarlo cuando quieras desde el menú; tu nombre y tus datos, no."))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(sub)
	## Las dos secciones, como pestañas grandes numeradas.
	var segm := HBoxContainer.new()
	segm.add_theme_constant_override("separation", 8)
	vb.add_child(segm)
	for i in SECCIONES.size():
		var clave: String = SECCIONES[i]
		var b := ControlesPersonaje.chip("", false, func() -> void: _ir_a(clave))
		b.custom_minimum_size = Vector2(0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", Tema.TAM_DESTACADO)
		_b_secciones[clave] = b
		segm.add_child(b)
	_contenido = MarginContainer.new()
	_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_contenido)
	_hojas = HojasPersonaje.new()
	_hojas.c1 = _c1
	_hojas.c2 = _c2
	_hojas.asp = PersonajeDT.aspecto(_p["aspecto"])
	_hojas.cambiado.connect(func(a: Dictionary) -> void:
		_p["aspecto"] = a.duplicate()
		_estudio.mostrar(a)
		_refrescar())
	_contenido.add_child(_hojas)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_right", 14)
	sc.add_child(m)
	_caja_datos = m
	_contenido.add_child(sc)
	_pintar_datos()
	_aviso = Tema.etiqueta(Tema.TAM_CUERPO, Tema.MAL, "")
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.visible = false
	vb.add_child(_aviso)
	vb.add_child(_botonera())
	return vb

func _botonera() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_b_atras = _boton(Idiomas.t("← Atrás"), func() -> void: volver.emit())
	fila.add_child(_b_atras)
	fila.add_child(_boton(Idiomas.t("🎲 Al azar"), _al_azar))
	_b_deshacer = _boton(Idiomas.t("↶ Deshacer"), func() -> void: _hojas.deshacer())
	fila.add_child(_b_deshacer)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(hueco)
	_b_siguiente = _boton("", _siguiente, true)
	_b_siguiente.custom_minimum_size = Vector2(220, 46)
	fila.add_child(_b_siguiente)
	return fila

func _boton(texto: String, al_pulsar: Callable, principal := false) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(120, 46)
	b.add_theme_font_size_override("font_size", Tema.TAM_DESTACADO - 1)
	if principal:
		for estado: String in ["normal", "hover", "pressed", "focus"]:
			var sb := Tema.caja(Tema.ORO if estado != "hover" else Tema.ORO.lightened(0.15), Tema.RADIO, Tema.ORO.lightened(0.3))
			if estado == "focus":
				sb.draw_center = false
			b.add_theme_stylebox_override(estado, sb)
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, Color("14110a"))
	b.pressed.connect(al_pulsar)
	return b

func _ir_a(seccion: String) -> void:
	_seccion = seccion if seccion in SECCIONES else "aspecto"
	if _hojas == null:
		return
	_hojas.visible = _seccion == "aspecto"
	(_caja_datos.get_parent() as Control).visible = _seccion == "datos"
	_refrescar()

## El paso, la ficha y los botones al día con lo elegido.
func _refrescar() -> void:
	if _ficha_nombre == null:
		return
	var p := personaje()
	var e := _mostrar_errores()
	_titulo_paso.text = Idiomas.t("PASO %d · TU PERSONAJE") % _paso
	var completo := String(p["nombre_completo"])
	_ficha_nombre.text = completo if completo != "" else Idiomas.t("Tu nombre")
	_ficha_nombre.add_theme_color_override("font_color", Tema.TEXTO if completo != "" else Tema.SUAVE)
	_ficha_linea.text = "%s  ·  %s  ·  %s  ·  %s" % [Idiomas.t("%d años") % int(p["edad"]),
		PersonajeDatos.nombre_pais(String(p["nacionalidad"])), PersonajeDatos.nombre_estilo(String(p["estilo"])),
		PersonajeDatos.nombre_comunicacion(String(p["comunicacion"]))]
	_ficha_bandera.texture = Banderas.textura(String(p["nacionalidad"]))
	var datos_ok := e.is_empty()
	for i in SECCIONES.size():
		var clave: String = SECCIONES[i]
		var b: Button = _b_secciones[clave]
		var marca := "" if clave == "aspecto" or not datos_ok else "  ✓"
		b.text = "%d  ·  %s%s" % [i + 1, Idiomas.t("Aspecto") if clave == "aspecto" else Idiomas.t("Datos"), marca]
		ControlesPersonaje.estilar_chip(b, clave == _seccion)
	_b_siguiente.text = Idiomas.t("Siguiente: datos →") if _seccion == "aspecto" else Idiomas.t("Confirmar ✓")
	_b_deshacer.disabled = not _hojas.puede_deshacer()
	_b_deshacer.visible = _seccion == "aspecto"
	_aviso.visible = _intento and not datos_ok
	_aviso.text = Idiomas.t("Falta algo en tus datos: está marcado en rojo.") if _aviso.visible else ""

func _siguiente() -> void:
	if _seccion == "aspecto":
		_ir_a("datos")
		if _campos.has("nombre") and String(_p.get("nombre", "")) == "":
			(_campos["nombre"] as LineEdit).grab_focus()
		return
	_confirmar()

## Todo al azar pero con sentido: el aspecto, la edad y un nombre del país
## elegido. La nacionalidad se respeta (la eligió el jugador o su club).
func _al_azar() -> void:
	if _seccion == "aspecto":
		_hojas.poner(PersonajeDatos.aspecto_coherente(_rng, -1, int(_p["edad"])))
		return
	var nuevo := PersonajeDatos.al_azar(String(_p["nacionalidad"]), _rng,
		1 if String(_hojas.asp["cuerpo"]) == "female" else 0)
	for k: String in ["nombre", "apellido", "edad", "estilo", "comunicacion"]:
		_p[k] = nuevo[k]
		_tocados[k] = true
	_pintar_datos()
	_refrescar()

## Validar y, si está todo, la tarjeta de confirmación: el retrato 2D de las
## fichas, el resumen y «Sí, ese soy yo».
func _confirmar() -> void:
	_intento = true
	var e := errores()
	_refrescar()
	if not e.is_empty():
		_ir_a("datos")
		Animar.pulso(_aviso)
		for campo: String in ["nombre", "apellido"]:
			if e.has(campo) and _campos.has(campo):
				(_campos[campo] as LineEdit).grab_focus()
				break
		return
	if _capa_confirmar != null:
		return
	_capa_confirmar = PersonajeConfirmacion.crear(personaje(), _c1, func() -> void: _cerrar_confirmacion(),
		func() -> void:
			var p := personaje()
			_cerrar_confirmacion()
			terminado.emit({"personaje": p}))
	add_child(_capa_confirmar)

func _cerrar_confirmacion() -> void:
	if _capa_confirmar != null:
		_capa_confirmar.queue_free()
		_capa_confirmar = null

## Esc cierra la confirmación; en la etapa no hace nada más (es obligatoria y
## volver atrás tiene su botón: un Esc sin querer no debe perder lo hecho).
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
		if _capa_confirmar != null:
			get_viewport().set_input_as_handled()
			_cerrar_confirmacion()
