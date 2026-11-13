class_name RutaToque
extends Control
## «EL TOQUE»: el mini juego del entreno. Tres balones; en cada uno una marca
## va y viene por la barra y hay que pararla dentro de la zona. La media de los
## tres decide la semana: perfecto = mejora asegurada (`CarreraRuta.tras_entreno`).

const E := preload("res://ui/carrera/ruta_estilo.gd")
const BALONES := 3

var ui: Variant
var _tiros: Array = []        ## calidad de cada balón (0-1)
var _pausa := 0.0
var _fin := false
var _pista: RutaBarra
var _estado: Label
var _boton: Button
var _azar := RandomNumberGenerator.new()

static func abrir(ui_carrera: Variant) -> RutaToque:
	var t := RutaToque.new()
	t.ui = ui_carrera
	ui_carrera.add_child(t)
	return t

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_azar.randomize()
	var velo := ColorRect.new()
	velo.color = Color(0.01, 0.02, 0.06, 0.86)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var p := E.tarjeta(E.MENTA)
	p.custom_minimum_size = Vector2(minf(640.0, get_viewport_rect().size.x - 32.0), 0)
	centro.add_child(p)
	var v := E.columna(12)
	p.add_child(v)
	v.add_child(E.rotulo("ENTRENO DE LA SEMANA", E.MENTA))
	v.add_child(E.titulo(46, E.TEXTO, "EL TOQUE"))
	v.add_child(E.lbl(14, E.SUAVE, "Tres balones. Para la marca dentro de la zona verde: cuanto más al centro, mejor. Con un toque perfecto la mejora de esta semana está asegurada."))
	_pista = RutaBarra.new()
	_pista.total_luces = BALONES
	v.add_child(_pista)
	_estado = E.titulo(26, E.ORO, "")
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_estado)
	_boton = E.boton("⚽  ¡AHORA!", E.MENTA, golpear, 58, true)
	v.add_child(_boton)
	_nuevo_balon()
	Idiomas.traducir_arbol(self)
	_boton.grab_focus()

func _nuevo_balon() -> void:
	_pista.lanzar(_azar, 2.6 + float(_tiros.size()) * 0.9)
	_estado.text = Idiomas.t("Balón %d de %d") % [_tiros.size() + 1, BALONES]

func _process(d: float) -> void:
	if _fin:
		return
	if _pausa > 0.0:
		_pausa -= d
		if _pausa <= 0.0:
			if _tiros.size() >= BALONES:
				_terminar()
			else:
				_nuevo_balon()
		return

func golpear() -> void:
	if _fin or _pausa > 0.0:
		return
	var q := _pista.golpear()
	_tiros.append(q)
	_pista.luces = _tiros
	_estado.text = Idiomas.t("¡PERFECTO!") if q >= 1.0 else (Idiomas.t("Bien") if q >= 0.6 else Idiomas.t("Fuera"))
	_estado.add_theme_color_override("font_color", RutaBarra.color_de(q))
	_pausa = 0.7
	_pista.queue_redraw()

func media() -> float:
	var s := 0.0
	for q: float in _tiros:
		s += q
	return s / float(maxi(1, _tiros.size()))

func _terminar() -> void:
	_fin = true
	var q := media()
	CarreraRuta.anotar_toque(ui.carrera, ui.mundo, q)
	ui._msg = Idiomas.t("Toque perfecto: la mejora de esta semana está asegurada.") if q >= 0.85 \
		else (Idiomas.t("Buen toque: experiencia extra en el entreno.") if q >= 0.5 else Idiomas.t("Toque flojo: esta semana, a lo de siempre."))
	queue_free()
	ui._pintar_semana()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept"):
		accept_event()
		golpear()
