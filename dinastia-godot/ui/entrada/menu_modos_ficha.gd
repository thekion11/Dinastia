class_name MenuModosFicha
extends PanelContainer
## LA FICHA DEL MODO QUE SE MIRA (menú de modos, fase 1, etapa 2): carátula,
## sección, nombre, la descripción corta de `MODOS_JUEGO`, tres rasgos en
## chips y el lema de su sección. Cambia de tono con la luz del modo y entra
## con un fundido corto y un deslizamiento de pocos píxeles: se nota que es
## OTRO modo sin que el texto baile.

## Se pulsa «Elegir este modo» (ratón o dedo; con teclado y mando se elige
## desde la lista).
signal elegir_pulsado

const MARGEN_DERECHO := -56.0

## Tres rasgos por modo, debajo de la descripción: lo que se hace (y lo que no)
## de un vistazo. Cada tramo se traduce suelto (`Idiomas.t` corta por « · »).
const RASGOS := {
	"dt": "Táctica · Camarín · Mercado",
	"dir": "Fichajes · Finanzas · Un DT a tus órdenes",
	"ayudante": "Desde abajo · Ganarte el banco · Sin fichajes",
	"interino": "Cinco fechas · Motivación · Sin red",
	"cantera": "De 10 a 16 años · Formación · El futuro del club",
	"imperio": "Multiclub · Capital propio · Nadie te echa",
	"jeque": "Sandbox · Caja ilimitada · Sin presión",
	"creador": "Tu escudo · Tus colores · Último puesto",
	"retos": "Cinco situaciones · Una meta · Partidas cortas",
	"tutorial": "Paso a paso · Tu propia partida · Un minuto",
	"carrera-m": "Juegas tú · Mando o teclado · Tu carrera",
	"fondo": "Hasta el 49 % · Clubes de todo el mundo · Caja propia",
}

var _estilo: StyleBoxFlat
var _portada: TextureRect
var _lbl_seccion: Label
var _lbl_titulo: Label
var _lbl_sub: Label
var _fila_rasgos: HFlowContainer
var _lbl_lema: Label
var _lbl_aviso: Label
var _btn_elegir: Button

func _init() -> void:
	anchor_left = 0.42
	anchor_right = 1.0
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_right = MARGEN_DERECHO
	grow_vertical = Control.GROW_DIRECTION_BOTH
	_estilo = StyleBoxFlat.new()
	_estilo.bg_color = Color(Tema.PANEL, 0.86)
	_estilo.set_border_width_all(1)
	_estilo.set_corner_radius_all(Tema.RADIO_GRANDE)
	_estilo.shadow_color = Color(0, 0, 0, 0.35)
	_estilo.shadow_size = 18
	add_theme_stylebox_override("panel", _estilo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	## La carátula de la tarjeta del modo (`TarjetaModo`), la misma que en la
	## pantalla de título: el jugador la reconoce de un menú al otro.
	_portada = TextureRect.new()
	_portada.custom_minimum_size = Vector2(0, 104)
	_portada.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portada.stretch_mode = TextureRect.STRETCH_SCALE
	v.add_child(_portada)
	var mt := MarginContainer.new()
	mt.add_theme_constant_override("margin_left", 26)
	mt.add_theme_constant_override("margin_right", 26)
	mt.add_theme_constant_override("margin_top", 16)
	mt.add_theme_constant_override("margin_bottom", 22)
	v.add_child(mt)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 8)
	mt.add_child(t)
	_lbl_seccion = _etiqueta(12, Tema.ORO)
	t.add_child(_lbl_seccion)
	_lbl_titulo = _etiqueta(38, Tema.TEXTO)
	_lbl_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(_lbl_titulo)
	_lbl_sub = _etiqueta(18, Tema.TEXTO)
	_lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(_lbl_sub)
	_fila_rasgos = HFlowContainer.new()
	_fila_rasgos.add_theme_constant_override("h_separation", 8)
	_fila_rasgos.add_theme_constant_override("v_separation", 8)
	t.add_child(_fila_rasgos)
	_lbl_lema = _etiqueta(13, Tema.SUAVE)
	_lbl_lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(_lbl_lema)
	_lbl_aviso = _etiqueta(13, Tema.ORO)
	_lbl_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_aviso.visible = false
	t.add_child(_lbl_aviso)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_END
	t.add_child(fila)
	_btn_elegir = Button.new()
	_btn_elegir.text = Idiomas.t("Elegir este modo")
	_btn_elegir.custom_minimum_size = Vector2(190, 44)
	## Fuera del recorrido del foco: con teclado o mando se elige desde la
	## lista (Intro / A); este botón es para el ratón y el dedo.
	_btn_elegir.focus_mode = Control.FOCUS_NONE
	_btn_elegir.add_theme_font_size_override("font_size", 16)
	_btn_elegir.set_meta("sin_sonido", true)
	_btn_elegir.pressed.connect(func() -> void: elegir_pulsado.emit())
	fila.add_child(_btn_elegir)

## Pinta el modo `m` (con `_sec`/`_sec_desc` de `PantallaModos.leer_modos`).
func pintar(m: Dictionary, jugable: bool, al_instante: bool) -> void:
	var luz := MenuModosFondo.luz_de(m)
	_portada.texture = TarjetaModo.textura(String(m.get("c1", "#161b22")), String(m.get("c2", "#30363d")), 640, 104)
	var sec := String(m.get("_sec", ""))
	_lbl_seccion.text = Idiomas.t(sec).to_upper() if sec != "" else ""
	_lbl_seccion.visible = sec != ""
	_lbl_seccion.add_theme_color_override("font_color", luz)
	_lbl_titulo.text = Idiomas.t(String(m.get("titulo", "")))
	_lbl_sub.text = Idiomas.t(String(m.get("sub", "")))
	_lbl_lema.text = Idiomas.t(String(m.get("_sec_desc", "")))
	_lbl_lema.visible = _lbl_lema.text != ""
	_lbl_aviso.visible = false
	for h in _fila_rasgos.get_children():
		_fila_rasgos.remove_child(h)
		h.queue_free()
	for r in rasgos_de(String(m.get("id", ""))):
		_fila_rasgos.add_child(_chip(r, luz))
	_estilo.border_color = Color(luz, 0.45)
	_pintar_boton(luz, jugable)
	if al_instante:
		modulate.a = 1.0
		return
	modulate.a = 0.25
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	tw.tween_method(_desplazar, 18.0, 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Los rasgos de un modo, ya traducidos.
static func rasgos_de(id: String) -> PackedStringArray:
	var salida := PackedStringArray()
	var r := String(RASGOS.get(id, ""))
	if r != "":
		for tramo in r.split(" · ", false):
			salida.append(Idiomas.t(tramo))
	return salida

func avisar(texto: String) -> void:
	_lbl_aviso.text = texto
	_lbl_aviso.visible = true

func titulo() -> String:
	return _lbl_titulo.text

func descripcion() -> String:
	return _lbl_sub.text

func rasgos_visibles() -> int:
	return _fila_rasgos.get_child_count()

func _desplazar(dx: float) -> void:
	offset_left = dx
	offset_right = MARGEN_DERECHO + dx

func _chip(texto: String, luz: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var e := StyleBoxFlat.new()
	e.bg_color = Color(luz, 0.14)
	e.border_color = Color(luz, 0.5)
	e.set_border_width_all(1)
	e.set_corner_radius_all(Tema.RADIO_GRANDE)
	e.content_margin_left = 10
	e.content_margin_right = 10
	e.content_margin_top = 3
	e.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", e)
	var l := _etiqueta(13, luz.lerp(Color.WHITE, 0.35))
	l.text = texto
	p.add_child(l)
	return p

func _pintar_boton(luz: Color, activo: bool) -> void:
	for estado in ["normal", "hover", "pressed"]:
		var e := StyleBoxFlat.new()
		e.set_corner_radius_all(Tema.RADIO)
		e.bg_color = luz.darkened(0.35 if estado == "normal" else 0.15) if activo else Color(1, 1, 1, 0.08)
		_btn_elegir.add_theme_stylebox_override(estado, e)
	var col := Color("0c1510") if activo else Tema.SUAVE
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		_btn_elegir.add_theme_color_override(k, col)

func _etiqueta(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
