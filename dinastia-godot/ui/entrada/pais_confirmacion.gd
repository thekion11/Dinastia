class_name PaisConfirmacion
extends Control
## LA CONFIRMACIÓN de la pantalla de país: cada etapa de la entrada es obligatoria y se
## confirma al terminar (plan, §3.1). Un velo oscuro sobre la pantalla y una tarjeta con
## la bandera, «¿Empezar en …?» y dos botones. Enter/A acepta, Esc/B vuelve al globo.

signal aceptado()
signal cancelado()

var _bandera: TextureRect
var _titulo: Label
var _texto: Label
var _si: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.62)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(centro)
	var caja := PanelContainer.new()
	var estilo := Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Color(Tema.ORO, 0.55))
	estilo.content_margin_left = 28
	estilo.content_margin_right = 28
	estilo.content_margin_top = 22
	estilo.content_margin_bottom = 22
	caja.add_theme_stylebox_override("panel", estilo)
	caja.custom_minimum_size = Vector2(440, 0)
	caja.mouse_filter = Control.MOUSE_FILTER_STOP
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(v)
	_bandera = TextureRect.new()
	_bandera.custom_minimum_size = Vector2(120, 80)
	_bandera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bandera.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bandera.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	v.add_child(_bandera)
	_titulo = Tema.etiqueta(Tema.TAM_TITULO, Tema.TEXTO)
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_titulo)
	_texto = Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)
	var no := Button.new()
	no.text = Idiomas.t("Cambiar de país")
	no.custom_minimum_size = Vector2(170, 40)
	no.pressed.connect(cerrar.bind(true))
	fila.add_child(no)
	_si = Button.new()
	_si.text = Idiomas.t("Confirmar")
	_si.custom_minimum_size = Vector2(170, 40)
	_si.add_theme_stylebox_override("normal", Tema.caja(Tema.ACENTO, Tema.RADIO, Color(1, 1, 1, 0.2)))
	_si.add_theme_stylebox_override("hover", Tema.caja(Tema.ACENTO.lightened(0.15), Tema.RADIO, Color(1, 1, 1, 0.3)))
	_si.add_theme_color_override("font_color", Color.WHITE)
	_si.pressed.connect(func() -> void:
		visible = false
		aceptado.emit())
	fila.add_child(_si)

func abrir(p: String, detalle: String) -> void:
	_bandera.texture = Banderas.textura(p)
	_titulo.text = Idiomas.t("¿Empezar en %s?") % PaisDatos.nombre(p)
	_texto.text = detalle
	visible = true
	_si.grab_focus.call_deferred()

func cerrar(avisar := true) -> void:
	visible = false
	if avisar:
		cancelado.emit()

func _gui_input(event: InputEvent) -> void:
	## Clic en el velo (fuera de la tarjeta): igual que «Cambiar de país».
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		cerrar(true)
		accept_event()
