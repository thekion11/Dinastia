extends Control
## [Capa 1/4 de `config_club.gd`] el armazón: fondo, pasos, vista previa, pie y ayudantes.
##
## LA CONFIGURACIÓN DEL CLUB (fase 1, etapa 4 del flujo de entrada). Pantalla
## propia a pantalla completa, obligatoria y con confirmación: reúne lo que hasta
## hoy estaba repartido entre Identidad, Ajustes, Opciones, el diseñador de
## equipación, la vida del DT y la ciudad. A la izquierda la vista previa en vivo
## (escudo y equipación), a la derecha el paso actual, abajo la navegación.
## El modelo es `ConfigClubDatos`; esta capa no decide nada, solo pinta.

signal terminado(datos: Dictionary)
signal volver()

const FONDO_SHADER := preload("res://ui/entrada/config_club_fondo.gdshader")
const VistaMascota := preload("res://ui/entrada/config_club_mascota.gd")

## [icono, nombre] de cada paso, en orden. El índice es el «paso» de `validar()`.
## Nombres cortos a propósito: ocho caben en la barra a 1280 px sin cortarse.
const PASOS := [
	["🏷️", "Identidad"], ["🛡️", "Escudo"], ["👕", "Equipación"], ["🐾", "Mascota"],
	["🏟️", "Estadio"], ["🏠", "Tu casa"], ["⚙", "Gráficos"], ["✔", "Confirmar"],
]
const ANCHO_PREVIA := 330.0
## Cuánto se espera tras el último cambio para rehacer la vista previa: la
## camiseta se dibuja píxel a píxel y arrastrar un color no debe rehacerla 60
## veces por segundo.
const ESPERA_PREVIA := 0.15

var datos := ConfigClubDatos.new()
var _paso := 0
var _vistos := {0: true}
var _montada := false

var _fondo: ColorRect
var _chips: Array[Button] = []
var _contador: Label
var _contenido: VBoxContainer
var _scroll: ScrollContainer
var _titulo_paso: Label
var _ayuda_paso: Label
var _b_atras: Button
var _b_siguiente: Button
var _aviso: Label
var _p_escudo: TextureRect
var _p_kit: TextureRect
var _p_nombre: Label
var _p_estadio: Label
var _p_lema: Label
var _p_mascota: Label
var _p_colores: HBoxContainer
var _espalda := false
var _t_previa := -1.0

# ------------------------------------------------------------------ ARMAZÓN

func _montar() -> void:
	if _montada:
		return
	_montada = true
	## Con offsets (no solo anclas): si no, colgada de un `Node` o creada fuera del
	## árbol, la pantalla mide lo que su contenido y no llena la ventana.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not (get_parent() is Control) and is_inside_tree():
		size = get_viewport_rect().size
		get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = FONDO_SHADER
	sm.set_shader_parameter("velocidad", 0.0 if Animar.reducidas() else 0.035)
	_fondo.material = sm
	add_child(_fondo)
	resized.connect(func() -> void:
		if size.y > 0.0:
			sm.set_shader_parameter("aspecto", size.x / size.y))

	var marco := MarginContainer.new()
	marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado: String in ["left", "right"]:
		marco.add_theme_constant_override("margin_" + lado, 28)
	marco.add_theme_constant_override("margin_top", 18)
	marco.add_theme_constant_override("margin_bottom", 16)
	add_child(marco)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marco.add_child(col)
	col.add_child(_cabecera())
	col.add_child(_barra_pasos())
	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 16)
	col.add_child(cuerpo)
	cuerpo.add_child(_panel_previa())
	cuerpo.add_child(_panel_paso())
	col.add_child(_pie())

func _cabecera() -> Control:
	var fila := HBoxContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(v)
	var t := Tema.etiqueta(30, Tema.ORO, Idiomas.mayusculas(Idiomas.t("Configura tu club")))
	t.add_theme_constant_override("outline_size", 6)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	v.add_child(t)
	v.add_child(Tema.etiqueta(14, Tema.SUAVE, Idiomas.t("Todo tu club en un solo lugar. Podrás retocarlo más tarde en Identidad y en Ajustes.")))
	_contador = Tema.etiqueta(15, Tema.TEXTO)
	_contador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_contador)
	return fila

func _barra_pasos() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	for i in PASOS.size():
		var b := Button.new()
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_ALL
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 40)
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 13)
		var idx := i
		b.pressed.connect(func() -> void: ir_a(idx))
		fila.add_child(b)
		_chips.append(b)
	return fila

func _panel_previa() -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(ANCHO_PREVIA, 0)
	pc.add_theme_stylebox_override("panel", _caja(Color(0.02, 0.03, 0.025, 0.62), Tema.RADIO_GRANDE, Color(1, 1, 1, 0.1)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	v.add_child(Tema.rotulo(Idiomas.t("VISTA PREVIA")))
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 12)
	v.add_child(arriba)
	_p_escudo = _imagen(Vector2(118, 118))
	arriba.add_child(_p_escudo)
	var datos_v := VBoxContainer.new()
	datos_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	datos_v.alignment = BoxContainer.ALIGNMENT_CENTER
	arriba.add_child(datos_v)
	_p_nombre = Tema.etiqueta(20, Tema.TEXTO)
	_p_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	datos_v.add_child(_p_nombre)
	_p_estadio = Tema.etiqueta(12, Tema.SUAVE)
	_p_estadio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	datos_v.add_child(_p_estadio)
	_p_colores = HBoxContainer.new()
	_p_colores.add_theme_constant_override("separation", 4)
	datos_v.add_child(_p_colores)
	_p_mascota = Tema.etiqueta(13, Tema.TEXTO)
	datos_v.add_child(_p_mascota)
	## La equipación entera; un clic la da vuelta (la espalda lleva el número).
	_p_kit = _imagen(Vector2(0, 250))
	_p_kit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_p_kit.mouse_filter = Control.MOUSE_FILTER_STOP
	_p_kit.tooltip_text = Idiomas.t("Clic para ver la espalda")
	_p_kit.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_espalda = not _espalda
			_t_previa = 0.0)
	v.add_child(_p_kit)
	_p_lema = Tema.etiqueta(13, Tema.ORO)
	_p_lema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_p_lema)
	return pc

func _panel_paso() -> Control:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _caja(Color(0.03, 0.045, 0.035, 0.78), Tema.RADIO_GRANDE, Color(1, 1, 1, 0.1)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pc.add_child(v)
	_titulo_paso = Tema.etiqueta(22, Tema.TEXTO)
	v.add_child(_titulo_paso)
	_ayuda_paso = Tema.etiqueta(13, Tema.SUAVE)
	_ayuda_paso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_ayuda_paso)
	v.add_child(HSeparator.new())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 10)
	_scroll.add_child(_contenido)
	return pc

func _pie() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	_b_atras = _boton_grande("", Tema.PANEL)
	_b_atras.pressed.connect(atras)
	fila.add_child(_b_atras)
	_aviso = Tema.etiqueta(14, Tema.SUAVE)
	_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fila.add_child(_aviso)
	_b_siguiente = _boton_grande("", Tema.ACENTO)
	_b_siguiente.pressed.connect(siguiente)
	fila.add_child(_b_siguiente)
	return fila

# ------------------------------------------------------------- NAVEGACIÓN

func ir_a(i: int) -> void:
	_paso = clampi(i, 0, PASOS.size() - 1)
	_vistos[_paso] = true
	_pintar_paso()
	_actualizar_estado()

## Avanza; no deja salir de un paso con un error grave (sí con un aviso leve).
func siguiente() -> void:
	if _paso == PASOS.size() - 1:
		_pedir_confirmacion()
		return
	if datos.hay_graves(_paso):
		_actualizar_estado(true)
		return
	ir_a(_paso + 1)

func atras() -> void:
	if _paso == 0:
		volver.emit()
		return
	ir_a(_paso - 1)

## Lo implementan las capas de arriba.
func _pintar_paso() -> void:
	pass

func _pedir_confirmacion() -> void:
	pass

## Los chips de pasos, el contador y el pie. `insistir` = se intentó avanzar con un error.
func _actualizar_estado(insistir: bool = false) -> void:
	var problemas := datos.validar()
	for i in _chips.size():
		var grave := false
		var leve := false
		for p: Dictionary in problemas:
			if int(p["paso"]) == i:
				grave = grave or bool(p["grave"])
				leve = leve or not bool(p["grave"])
		## Delante, el número; o el estado del paso si ya dice algo (⚠ error, • aviso, ✔ visto).
		var marca := "⚠" if grave else ("•" if leve else ("✔" if _vistos.has(i) and i != _paso else str(i + 1)))
		_chips[i].text = "%s  %s" % [marca, Idiomas.t(String(PASOS[i][1]))]
		_chips[i].button_pressed = i == _paso
		_chips[i].tooltip_text = "%s %s" % [String(PASOS[i][0]), Idiomas.t(String(PASOS[i][1]))]
		var fondo := Tema.ACENTO if i == _paso else (Tema.MAL.darkened(0.45) if grave else Color(0.06, 0.09, 0.07, 0.85))
		for est: String in ["normal", "hover", "pressed", "focus"]:
			var cj := _caja(fondo.lightened(0.08) if est == "hover" else fondo, Tema.RADIO, Color(1, 1, 1, 0.25) if est == "focus" else Color(1, 1, 1, 0.06))
			_chips[i].add_theme_stylebox_override(est, cj)
	_contador.text = Idiomas.t("Paso %d de %d") % [_paso + 1, PASOS.size()]
	_b_atras.text = "← " + (Idiomas.t("Volver") if _paso == 0 else Idiomas.t("Atrás"))
	var ultimo := _paso == PASOS.size() - 1
	_b_siguiente.text = ("✔ " + Idiomas.t("Confirmar y continuar")) if ultimo else (Idiomas.t("Siguiente") + " →")
	_b_siguiente.disabled = ultimo and datos.hay_graves()
	var del_paso: Array = problemas.filter(func(p: Dictionary) -> bool: return ultimo or int(p["paso"]) == _paso)
	if del_paso.is_empty():
		_aviso.text = Idiomas.t("Todo en orden.") if ultimo else ""
		_aviso.add_theme_color_override("font_color", Tema.BIEN)
		return
	var grave_aqui := del_paso.any(func(p: Dictionary) -> bool: return bool(p["grave"]))
	_aviso.text = ("⚠ " if grave_aqui else "• ") + String((del_paso[0] as Dictionary)["texto"]) + \
		("" if del_paso.size() == 1 else "  (+%d)" % (del_paso.size() - 1))
	_aviso.add_theme_color_override("font_color", Tema.MAL if grave_aqui else Tema.ORO)
	if insistir and is_inside_tree():
		Animar.pulso(_aviso)

# ----------------------------------------------------------- VISTA PREVIA

## Pide rehacer la vista previa (con espera) y repasa la validación.
func _cambio() -> void:
	_t_previa = ESPERA_PREVIA
	_actualizar_estado()

func _process(delta: float) -> void:
	if _t_previa < 0.0:
		return
	_t_previa -= delta
	if _t_previa < 0.0:
		_rehacer_previa()

func _rehacer_previa() -> void:
	var c := datos.club
	Escudo.limpiar_cache()
	_p_escudo.texture = Escudo.textura(c, 118)
	_p_kit.texture = DisenosKit.textura_completa(kit_previa(), _espalda, 150)
	_p_nombre.text = c.nombre.strip_edges() if c.nombre.strip_edges() != "" else Idiomas.t("(sin nombre)")
	_p_nombre.add_theme_color_override("font_color", Tema.TEXTO if c.nombre.strip_edges() != "" else Tema.SUAVE)
	_p_estadio.text = "🏟️ " + (c.estadio_nombre.strip_edges() if c.estadio_nombre.strip_edges() != "" \
		else Idiomas.t("Estadio %s") % (c.nombre.strip_edges() if c.nombre.strip_edges() != "" else "…"))
	var an: Array = ConfigClubDatos.ANIMALES.get(datos.mascota, ["", ""])
	_p_mascota.text = "%s %s" % [String(an[1]), Idiomas.t(String(an[0]))]
	_p_lema.text = ("«%s»" % datos.lema.strip_edges()) if datos.lema.strip_edges() != "" else ""
	for h in _p_colores.get_children():
		h.queue_free()
	for hexa: String in [c.color1, c.color2, c.color_acento()]:
		var m := ColorRect.new()
		m.color = Color(hexa)
		m.custom_minimum_size = Vector2(22, 14)
		_p_colores.add_child(m)
	var sm := _fondo.material as ShaderMaterial
	sm.set_shader_parameter("color_a", Color(c.color1))
	sm.set_shader_parameter("color_b", Color(c.color2))

## La equipación de la vista previa: la del juego (`DisenosKit.kit_de_club`) sin
## patrocinadores, que en esta etapa todavía no hay contratos.
func kit_previa() -> Dictionary:
	var k := DisenosKit.kit_de_club(datos.club)
	k["sp"] = {}
	return k

# --------------------------------------------------------------- AYUDANTES

func _caja(fondo: Color, radio: int, borde: Color) -> StyleBoxFlat:
	var e := Tema.caja(fondo, radio, borde)
	e.content_margin_left = 14
	e.content_margin_right = 14
	e.content_margin_top = 12
	e.content_margin_bottom = 12
	return e

func _imagen(tam: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.custom_minimum_size = tam
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

func _boton_grande(texto: String, fondo: Color) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(190, 46)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_stylebox_override("normal", _caja(fondo, Tema.RADIO, Color(1, 1, 1, 0.12)))
	b.add_theme_stylebox_override("hover", _caja(fondo.lightened(0.12), Tema.RADIO, Color(1, 1, 1, 0.2)))
	b.add_theme_stylebox_override("pressed", _caja(fondo.darkened(0.15), Tema.RADIO, Color(1, 1, 1, 0.2)))
	b.add_theme_stylebox_override("focus", _caja(fondo.lightened(0.06), Tema.RADIO, Tema.ORO))
	b.add_theme_stylebox_override("disabled", _caja(fondo.darkened(0.5), Tema.RADIO, Color(1, 1, 1, 0.05)))
	return b

## Un rótulo de sección dentro del paso, con su explicación opcional.
func _seccion(titulo: String, ayuda: String = "") -> void:
	var t := Tema.etiqueta(13, Tema.ORO, Idiomas.mayusculas(titulo))
	_contenido.add_child(t)
	if ayuda != "":
		var a := Tema.etiqueta(12, Tema.SUAVE, ayuda)
		a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_contenido.add_child(a)

## Una fila «etiqueta ……… [color]». `al_cambiar` recibe "#rrggbb".
func _fila_color(etiqueta: String, hexa: String, al_cambiar: Callable, padre: Control = null) -> ColorPickerButton:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	(padre if padre != null else _contenido).add_child(fila)
	var et := Tema.etiqueta(14, Tema.TEXTO, etiqueta)
	et.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(et)
	var cp := ColorPickerButton.new()
	cp.color = Color(hexa)
	cp.edit_alpha = false
	cp.custom_minimum_size = Vector2(96, 30)
	## `color_changed` y no `popup_closed`: se ve el cambio mientras se elige.
	cp.color_changed.connect(func(c: Color) -> void: al_cambiar.call("#" + c.to_html(false)))
	fila.add_child(cp)
	return cp

## Un botón de opción con estilo de tarjeta (seleccionado = borde dorado).
func _opcion(texto: String, elegido: bool, al_pulsar: Callable, tam := Vector2(0, 34), tip := "") -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	b.button_pressed = elegido
	b.custom_minimum_size = tam
	b.tooltip_text = tip
	b.add_theme_font_size_override("font_size", 13)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_estilo_opcion(b)
	b.pressed.connect(al_pulsar)
	return b

func _estilo_opcion(b: BaseButton) -> void:
	var base := Color(0.07, 0.1, 0.08, 0.9)
	b.add_theme_stylebox_override("normal", _caja(base, Tema.RADIO, Color(1, 1, 1, 0.08)))
	b.add_theme_stylebox_override("hover", _caja(base.lightened(0.08), Tema.RADIO, Color(1, 1, 1, 0.2)))
	b.add_theme_stylebox_override("pressed", _caja(Tema.ACENTO.darkened(0.45), Tema.RADIO, Tema.ORO))
	b.add_theme_stylebox_override("hover_pressed", _caja(Tema.ACENTO.darkened(0.35), Tema.RADIO, Tema.ORO))
	b.add_theme_stylebox_override("focus", _caja(Color(0, 0, 0, 0), Tema.RADIO, Color(1, 1, 1, 0.45)))

## Un grupo de opciones excluyentes en un contenedor que fluye.
func _flujo(padre: Control = null, sep: int = 6) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	(padre if padre != null else _contenido).add_child(f)
	return f

func _grupo(botones: Array) -> void:
	var g := ButtonGroup.new()
	for b: BaseButton in botones:
		b.button_group = g
