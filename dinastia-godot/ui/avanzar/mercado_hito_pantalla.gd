class_name MercadoHitoPantalla
extends PantallaMaqueta
## EL HITO DEL ÚLTIMO DÍA DEL MERCADO (17-11-2026, pedido de Auditoría según el avance del PES 2020): una banda de color arriba con «Último día del periodo de
## transferencias», la CUENTA ATRÁS grande (corre en vivo) con «El mercado cierra en N horas» y el escudo de tu club abajo. Emite `elegido("0")` al continuar.

const HORAS := 24   ## el mercado cierra al terminar el día

var _cuenta: Label
var _resta := float(HORAS * 3600)

static func mostrar(pr: Node, club: Club) -> MercadoHitoPantalla:
	var e := MercadoHitoPantalla.new()
	e._armar(pr, club)
	return e

func _armar(pr: Node, club: Club) -> void:
	var col := EstiloAvanzar.color_de("mercado")
	montar(pr, FondoCine.Modo.EVENTO, col, Color.BLACK, true)
	Sonido.toca("cronometro")
	var banda := ColorRect.new()
	banda.color = Color(col.darkened(0.55), 0.92)
	banda.anchor_right = 1.0; banda.anchor_bottom = 0.17
	_raiz.add_child(banda)
	var t := EstiloAvanzar.etiqueta(Idiomas.t("Último día del periodo de transferencias"), 46, Color.WHITE, true, true)
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banda.add_child(t)
	var centro := VBoxContainer.new()
	centro.anchor_left = 0.0; centro.anchor_right = 1.0; centro.anchor_top = 0.2; centro.anchor_bottom = 0.95
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 6)
	_raiz.add_child(centro)
	var cand := TextureRect.new()
	cand.texture = EstiloAvanzar.arte("mercado")
	cand.custom_minimum_size = Vector2(0, 190)
	cand.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cand.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	centro.add_child(cand)
	_cuenta = EstiloAvanzar.etiqueta(_formato(_resta), 130, Color.WHITE, true)
	_cuenta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(_cuenta)
	var l := EstiloAvanzar.etiqueta(Idiomas.t("El mercado cierra en %d horas") % HORAS, 34, Color(1, 1, 1, 0.92))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(l)
	var n := EstiloAvanzar.etiqueta(Idiomas.t("Lo que no fiches ahora, no se ficha hasta la próxima ventana."), 18, Color(1, 1, 1, 0.65))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(n)
	var esc := TextureRect.new()
	esc.texture = Escudo.textura(club, 96)
	esc.custom_minimum_size = Vector2(0, 84)
	esc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	centro.add_child(esc)
	var seguir := boton(Idiomas.t("Continuar"), true)
	seguir.anchor_left = 0.5; seguir.anchor_right = 0.5; seguir.anchor_top = 1.0; seguir.anchor_bottom = 1.0
	seguir.offset_left = 360.0; seguir.offset_right = 600.0; seguir.offset_top = -86.0; seguir.offset_bottom = -26.0
	seguir.pressed.connect(func() -> void: elegido.emit("0"))
	_raiz.add_child(seguir)
	seguir.grab_focus.call_deferred()
	set_process(not Animar.reducidas())

func _process(delta: float) -> void:
	_resta = maxf(_resta - delta, 0.0)
	_cuenta.text = _formato(_resta)

static func _formato(seg: float) -> String:
	var s := int(seg)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
