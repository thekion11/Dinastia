class_name PrologoHud
extends CanvasLayer
## LO QUE EL PRÓLOGO PINTA ENCIMA DEL MUNDO (fase 2, 26-10-2026): el rótulo de
## presentación, la flecha que apunta al siguiente punto con los metros, la
## tarjeta de controles con las teclas reales, el botón «Saltar prólogo» con su
## confirmación y el cuadro de la pregunta de la directiva. Sin lógica de
## guion: `PrologoDT` le dice qué enseñar.

signal saltar_confirmado
signal directiva_respondida(indice: int)

var _flecha: Label
var _tarjeta: PanelContainer
var _tarjeta_caja: VBoxContainer
var _saltar: Button
var _confirmar: Control
var _presentacion: Control
var _directiva: Control

func _init() -> void:
	layer = 45

func _ready() -> void:
	_flecha = Label.new()
	_flecha.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_flecha.offset_top = 16
	_flecha.offset_left = -220
	_flecha.offset_right = 220
	_flecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flecha.add_theme_font_size_override("font_size", 20)
	_flecha.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	_flecha.add_theme_color_override("font_outline_color", Color.BLACK)
	_flecha.add_theme_constant_override("outline_size", 7)
	_flecha.visible = false
	add_child(_flecha)
	_tarjeta = PanelContainer.new()
	_tarjeta.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	_tarjeta.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_tarjeta.offset_left = 18
	_tarjeta.offset_top = 56
	_tarjeta.visible = false
	add_child(_tarjeta)
	_tarjeta_caja = VBoxContainer.new()
	_tarjeta_caja.add_theme_constant_override("separation", 4)
	_tarjeta.add_child(_tarjeta_caja)
	_saltar = Button.new()
	_saltar.text = Idiomas.t("Saltar prólogo")
	_saltar.add_theme_font_size_override("font_size", 12)
	_saltar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_saltar.offset_left = -150
	_saltar.offset_right = -12
	_saltar.offset_top = 10
	_saltar.offset_bottom = 38
	_saltar.focus_mode = Control.FOCUS_NONE
	_saltar.pressed.connect(pedir_saltar)
	add_child(_saltar)

## El plano de presentación: ciudad y club en grande, franjas de cine.
func presentacion(ciudad: String, club: String, segundos: float) -> void:
	_presentacion = Control.new()
	_presentacion.set_anchors_preset(Control.PRESET_FULL_RECT)
	_presentacion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_presentacion)
	for arriba: bool in [true, false]:
		var f := ColorRect.new()
		f.color = Color.BLACK
		f.set_anchors_preset(Control.PRESET_TOP_WIDE if arriba else Control.PRESET_BOTTOM_WIDE)
		if arriba:
			f.offset_bottom = 90
		else:
			f.offset_top = -90
		_presentacion.add_child(f)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caja.offset_top = -230
	caja.offset_left = -500
	caja.offset_right = 500
	caja.alignment = BoxContainer.ALIGNMENT_END
	_presentacion.add_child(caja)
	var l1 := Tema.etiqueta(Tema.TAM_ROTULO + 3, Tema.ORO, ciudad.to_upper())
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l1)
	var l2 := Tema.etiqueta(Tema.TAM_TITULO + 18, Tema.TEXTO, club)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l2)
	var l3 := Tema.etiqueta(Tema.TAM_DESTACADO, Tema.SUAVE, Idiomas.t("Tu primer día"))
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(l3)
	_presentacion.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_presentacion, "modulate:a", 1.0, 0.6)
	tw.tween_interval(maxf(0.0, segundos - 1.2))
	tw.tween_property(_presentacion, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_presentacion):
			_presentacion.queue_free()
		_presentacion = null)

## La flecha hacia el destino: `angulo` relativo a la cámara (0 = de frente,
## positivo = a la derecha), `metros` y, si está en otra planta, un aviso.
func flecha(visible_: bool, angulo: float = 0.0, metros: float = 0.0, otra_planta: String = "") -> void:
	_flecha.visible = visible_
	if not visible_:
		return
	var simbolo := "▲"
	var a := wrapf(angulo, -PI, PI)
	if absf(a) > 2.6:
		simbolo = "▼"
	elif a > 0.5:
		simbolo = "▶"
	elif a < -0.5:
		simbolo = "◀"
	if otra_planta != "":
		_flecha.text = "%s  %s" % [simbolo, otra_planta]
	else:
		_flecha.text = "%s  %d m" % [simbolo, int(round(metros))]

## La tarjeta de controles (vacía = se esconde).
func tarjeta(lineas: Array[String]) -> void:
	for h in _tarjeta_caja.get_children():
		_tarjeta_caja.remove_child(h)
		h.queue_free()
	_tarjeta.visible = not lineas.is_empty()
	if lineas.is_empty():
		return
	_tarjeta_caja.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, Idiomas.t("CÓMO SE HACE")))
	for l: String in lineas:
		_tarjeta_caja.add_child(Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, l))

func pedir_saltar() -> void:
	if is_instance_valid(_confirmar):
		return
	_confirmar = _velo()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ORO))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -110
	panel.offset_bottom = 110
	_confirmar.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	var t := Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO, Idiomas.t("¿Saltar el prólogo?"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var s := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, Idiomas.t("Irás directo al menú del club. El recorrido por el estadio, la directiva y la presentación ante la prensa no se repiten."))
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var no := Button.new()
	no.text = Idiomas.t("Seguir aquí")
	no.custom_minimum_size = Vector2(140, 40)
	no.pressed.connect(func() -> void:
		_confirmar.queue_free()
		_confirmar = null)
	fila.add_child(no)
	var si := Button.new()
	si.text = Idiomas.t("Sí, saltar")
	si.custom_minimum_size = Vector2(140, 40)
	CuadroDialogo.respuesta(si)
	si.pressed.connect(func() -> void:
		_confirmar.queue_free()
		_confirmar = null
		saltar_confirmado.emit())
	fila.add_child(si)
	FocoSeguro.dar(no)

func confirmando_salto() -> bool:
	return is_instance_valid(_confirmar)

## La pregunta del presidente: dos respuestas (ninguna es trampa).
func pregunta_directiva(quien: String, color: Color, pregunta: String, opciones: Array[String]) -> void:
	_directiva = _velo()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -300
	panel.offset_bottom = -40
	_directiva.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(CuadroDialogo.placa(quien, color))
	var p := Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO, pregunta)
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(p)
	var primero: Button = null
	for i in opciones.size():
		var b := Button.new()
		b.text = opciones[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 44)
		CuadroDialogo.respuesta(b)
		b.pressed.connect(func() -> void:
			_directiva.queue_free()
			_directiva = null
			directiva_respondida.emit(i))
		v.add_child(b)
		if primero == null:
			primero = b
	FocoSeguro.dar(primero)

func _velo() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(fondo)
	add_child(c)
	return c
