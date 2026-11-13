class_name RutaMomentos
extends Control
## «LOS MOMENTOS», en pantalla: el marcador, el minuto, la jugada que te toca y
## la barra de toque. Al acabar las jugadas emite `terminado` con el resumen
## del partido (`CarreraMomentos.resultado`).

signal terminado(res: Dictionary)

const E := preload("res://ui/carrera/ruta_estilo.gd")

var ui: Variant
var par: Array = []
var entra_al := -1
var eliminatoria := false
var _guion: Array = []
var _hechas: Array = []
var _pausa := 0.0
var _fin := false
var _barra: RutaBarra
var _minuto: Label
var _titulo: Label
var _texto: Label
var _estado: Label
var _marcador: Label
var _boton: Button
var _azar := RandomNumberGenerator.new()

static func abrir(ui_carrera: Variant, partido: Array, minuto_entrada := -1, es_copa := false) -> RutaMomentos:
	var t := RutaMomentos.new()
	t.ui = ui_carrera
	t.par = partido
	t.entra_al = minuto_entrada
	t.eliminatoria = es_copa
	ui_carrera.add_child(t)
	return t

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_azar.randomize()
	_guion = CarreraMomentos.guion(ui.carrera, ui.mundo, entra_al)
	var velo := ColorRect.new()
	velo.color = Color(0.01, 0.02, 0.06, 0.92)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(velo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var tono := E.de_club(ui.carrera.club(ui.mundo))
	var p := E.tarjeta(tono, E.TINTA.lerp(tono, 0.08))
	p.custom_minimum_size = Vector2(minf(680.0, get_viewport_rect().size.x - 24.0), 0)
	centro.add_child(p)
	var v := E.columna(8)
	p.add_child(v)
	var cab := E.fila(10)
	v.add_child(cab)
	var rot := E.rotulo("LOS MOMENTOS", E.legible(tono))
	rot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(rot)
	_minuto = E.titulo(26, E.ORO, "")
	cab.add_child(_minuto)
	var mar := E.fila(10)
	mar.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(mar)
	mar.add_child(E.escudo(par[0], 40))
	_marcador = E.titulo(44, E.TEXTO, "0 - 0")
	mar.add_child(_marcador)
	mar.add_child(E.escudo(par[1], 40))
	_titulo = E.titulo(34, E.TEXTO, "")
	v.add_child(_titulo)
	_texto = E.lbl(14, E.SUAVE, "")
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_texto)
	_barra = RutaBarra.new()
	_barra.total_luces = _guion.size()
	v.add_child(_barra)
	_estado = E.titulo(26, E.ORO, "")
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_estado)
	_boton = E.boton("⚽  ¡AHORA!", E.ORO, golpear, 58, true)
	v.add_child(_boton)
	_siguiente()
	_boton.grab_focus()

func _siguiente() -> void:
	var mo: Dictionary = _guion[_hechas.size()]
	var def: Array = CarreraMomentos.TIPOS[String(mo["tipo"])]
	var z := CarreraMomentos.zona(ui.carrera.jugador(ui.mundo), String(mo["tipo"]))
	_minuto.text = "%d'" % int(mo["minuto"])
	_titulo.text = Idiomas.t(String(def[0])).to_upper()
	_texto.text = Idiomas.t(String(def[1]))
	_estado.text = Idiomas.t("Jugada %d de %d") % [_hechas.size() + 1, _guion.size()]
	_estado.add_theme_color_override("font_color", E.SUAVE)
	_barra.lanzar(_azar, 2.5 + float(_hechas.size()) * 0.45, float(z[0]), float(z[1]))

func _process(d: float) -> void:
	if _fin or _pausa <= 0.0:
		return
	_pausa -= d
	if _pausa <= 0.0:
		if _hechas.size() >= _guion.size():
			_terminar()
		else:
			_siguiente()

## Para la marca: resuelve la jugada (público para pruebas y capturas).
func golpear() -> void:
	if _fin or _pausa > 0.0:
		return
	var q := _barra.golpear()
	var mo: Dictionary = _guion[_hechas.size()]
	var d := CarreraMomentos.desenlace(String(mo["tipo"]), q)
	_hechas.append(d)
	var luces: Array = []
	for h: Dictionary in _hechas:
		luces.append(1.0 if float(h["nota"]) >= 0.7 else (0.6 if float(h["nota"]) > 0.0 else 0.1))
	_barra.luces = luces
	_estado.text = Idiomas.t(String(d["texto"]))
	_estado.add_theme_color_override("font_color", RutaBarra.color_de(q))
	## El marcador en vivo: lo tuyo ya cuenta; lo de los demás, al final.
	var club: Club = ui.carrera.club(ui.mundo)
	var mios := 0
	var suyos := 0
	for h2: Dictionary in _hechas:
		mios += int(h2["gol"]) + int(h2["asist"])
		suyos += int(h2["encajado"])
	_marcador.text = ("%d - %d" % [mios, suyos]) if par[0] == club else ("%d - %d" % [suyos, mios])
	_pausa = 1.1 if not E.sin_animar else 0.05

func _terminar() -> void:
	_fin = true
	var res := CarreraMomentos.resultado(ui.carrera, ui.mundo, par, _hechas, entra_al, eliminatoria)
	queue_free()
	terminado.emit(res)

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept"):
		accept_event()
		golpear()
