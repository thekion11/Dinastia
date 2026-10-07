class_name MinijuegoTiroLibre
extends Control
## MINIJUEGO: TIROS LIBRES (7-10-2026; estaba en el plan C7 y nunca se hizo).
## Cinco faltas desde la frontal: una barrera de cuatro y el portero detrás.
##  1. Eliges a dónde va el balón (seis zonas, como en los penales).
##  2. La barra de POTENCIA sube y baja: la frenas con el botón o con espacio.
##     Floja → se la come la barrera. Pasada → por encima del larguero. En la
##     franja verde, el balón llega a puerta; en el centro exacto, va con
##     tanta rosca que el portero casi no llega.
## El portero aprende como en los penales: si repites zona, se adelanta. Con
## tres goles o más el plantel se anima (moral +1, una vez por semana). Usa un
## generador propio: jugar no cambia la partida.

signal cerrado

const TIROS := 5
const ZONAS := [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]
const NOMBRE_ZONA := ["la escuadra izquierda", "arriba al centro", "la escuadra derecha",
	"abajo a la izquierda", "abajo al centro", "abajo a la derecha"]
const ARCO_TAM := Vector2(480, 170)

static var record := 0
static var _premio_semana := -1

var _mundo: Mundo
var _rng := RandomNumberGenerator.new()
var _tiros := 0
var _goles := 0
var _zona := -1
var _historial: Array[int] = []
var _arco_pos := Vector2.ZERO
var _balon: Label
var _portero: Label
var _marcador: Label
var _aviso: Label
var _barra: ProgressBar
var _boton_patear: Button
var _botones: Array[Button] = []
var _cargando := false
var _potencia := 0.0
var _sube := true
var _ocupado := false

static func mostrar(padre: Control, mundo: Mundo) -> MinijuegoTiroLibre:
	var n := MinijuegoTiroLibre.new()
	n._mundo = mundo
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

## Clasifica la potencia (0..1): "barrera", "alto", "justo" o "bueno".
static func resultado_potencia(p: float) -> String:
	if p < 0.38:
		return "barrera"
	if p > 0.86:
		return "alto"
	if absf(p - 0.62) < 0.06:
		return "justo"
	return "bueno"

## Probabilidad de que el portero ataje: más si repites zona, menos si el
## tiro va «justo» o a una escuadra.
static func prob_atajada(zona: int, historial: Array[int], calidad: String) -> float:
	var repetidas := 0
	for z in historial:
		if z == zona:
			repetidas += 1
	var p := 0.32 + 0.16 * float(repetidas)
	if zona in [0, 2]:
		p -= 0.12
	if calidad == "justo":
		p -= 0.18
	return clampf(p, 0.05, 0.9)

func _montar() -> void:
	_rng.seed = Time.get_ticks_usec()
	var tam := get_viewport_rect().size
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.1, 0.07)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_arco_pos = Vector2(tam.x / 2.0 - ARCO_TAM.x / 2.0, tam.y * 0.18)
	var cesped := ColorRect.new()
	cesped.color = Color(0.18, 0.45, 0.24)
	cesped.position = Vector2(tam.x / 2.0 - 440.0, _arco_pos.y + ARCO_TAM.y)
	cesped.size = Vector2(880, tam.y * 0.6)
	add_child(cesped)
	## El arco: red, palos y larguero.
	var red := ColorRect.new()
	red.color = Color(0.85, 0.88, 0.9, 0.18)
	red.position = _arco_pos
	red.size = ARCO_TAM
	add_child(red)
	for r: Rect2 in [Rect2(_arco_pos - Vector2(8, 8), Vector2(ARCO_TAM.x + 16, 8)),
			Rect2(_arco_pos - Vector2(8, 8), Vector2(8, ARCO_TAM.y + 8)),
			Rect2(_arco_pos + Vector2(ARCO_TAM.x, -8), Vector2(8, ARCO_TAM.y + 8))]:
		var palo := ColorRect.new()
		palo.color = Color.WHITE
		palo.position = r.position
		palo.size = r.size
		add_child(palo)
	_portero = _lbl("🧤", 64, Color.WHITE)
	_portero.position = _arco_pos + Vector2(ARCO_TAM.x / 2.0 - 32, ARCO_TAM.y - 84)
	add_child(_portero)
	## La barrera: cuatro jugadores delante del arco.
	for k in 4:
		var j := _lbl("🧍", 58, Color.WHITE)
		j.position = Vector2(tam.x / 2.0 - 110 + float(k) * 50.0, _arco_pos.y + ARCO_TAM.y + 70)
		add_child(j)
	_balon = _lbl("⚽", 40, Color.WHITE)
	add_child(_balon)
	_poner_balon()
	## Zonas: botones transparentes sobre el arco.
	for i in ZONAS.size():
		var b := Button.new()
		b.flat = true
		b.text = ""
		b.tooltip_text = NOMBRE_ZONA[i]
		var zona := ZONAS[i] as Vector2
		b.position = _arco_pos + Vector2((zona.x + 1.0) * ARCO_TAM.x / 3.0, (zona.y + 1.0) * ARCO_TAM.y / 4.0)
		b.size = Vector2(ARCO_TAM.x / 3.0, ARCO_TAM.y / 2.0)
		b.pressed.connect(func() -> void: _elegir(i))
		add_child(b)
		_botones.append(b)
	_marcador = _lbl("", 22, Color.WHITE)
	_marcador.position = Vector2(24, 20)
	add_child(_marcador)
	_aviso = _lbl("Toca la zona del arco a la que quieres patear.", 18, Color(1, 0.95, 0.75))
	_aviso.position = Vector2(tam.x / 2.0 - 300, tam.y - 170)
	_aviso.size = Vector2(600, 30)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_aviso)
	_barra = ProgressBar.new()
	_barra.max_value = 1.0
	_barra.step = 0.001
	_barra.show_percentage = false
	_barra.position = Vector2(tam.x / 2.0 - 220, tam.y - 128)
	_barra.size = Vector2(440, 22)
	add_child(_barra)
	var verde := ColorRect.new()
	verde.color = Color(0.3, 0.9, 0.4, 0.35)
	verde.position = _barra.position + Vector2(440.0 * 0.38, 0)
	verde.size = Vector2(440.0 * (0.86 - 0.38), 22)
	verde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(verde)
	var justo := ColorRect.new()
	justo.color = Color(1, 0.85, 0.2, 0.55)
	justo.position = _barra.position + Vector2(440.0 * 0.56, 0)
	justo.size = Vector2(440.0 * 0.12, 22)
	justo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(justo)
	_boton_patear = Button.new()
	_boton_patear.text = "¡PATEAR! (espacio)"
	_boton_patear.position = Vector2(tam.x / 2.0 - 110, tam.y - 92)
	_boton_patear.size = Vector2(220, 44)
	_boton_patear.disabled = true
	_boton_patear.pressed.connect(_patear)
	add_child(_boton_patear)
	var cerrar := Button.new()
	cerrar.text = "Salir"
	cerrar.position = Vector2(tam.x - 120, 20)
	cerrar.size = Vector2(96, 36)
	cerrar.pressed.connect(func() -> void:
		cerrado.emit()
		queue_free())
	add_child(cerrar)
	_pintar_marcador()

func _lbl(t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _poner_balon() -> void:
	var tam := get_viewport_rect().size
	_balon.position = Vector2(tam.x / 2.0 - 20, _arco_pos.y + ARCO_TAM.y + 165)
	_balon.scale = Vector2.ONE

func _pintar_marcador() -> void:
	_marcador.text = "Tiros libres  ·  %d de %d  ·  goles: %d  ·  récord: %d" % [_tiros, TIROS, _goles, record]

func _elegir(i: int) -> void:
	if _ocupado or _tiros >= TIROS:
		return
	_zona = i
	_cargando = true
	_potencia = 0.0
	_sube = true
	_boton_patear.disabled = false
	_aviso.text = "Apuntas a %s. ¡Frena la barra en la franja verde!" % NOMBRE_ZONA[i]

func _process(delta: float) -> void:
	if not _cargando:
		return
	_potencia += (1.0 if _sube else -1.0) * delta * 1.1
	if _potencia >= 1.0:
		_potencia = 1.0
		_sube = false
	elif _potencia <= 0.0:
		_potencia = 0.0
		_sube = true
	_barra.value = _potencia

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_SPACE and _cargando:
		_patear()
		get_viewport().set_input_as_handled()

func _patear() -> void:
	if not _cargando or _zona < 0:
		return
	_cargando = false
	_ocupado = true
	_boton_patear.disabled = true
	var cal := resultado_potencia(_potencia)
	var zona := ZONAS[_zona] as Vector2
	var destino := _arco_pos + Vector2((zona.x + 1.0) * ARCO_TAM.x / 3.0 + ARCO_TAM.x / 6.0 - 20, (zona.y + 1.0) * ARCO_TAM.y / 4.0 + ARCO_TAM.y / 4.0 - 20)
	var texto := ""
	var gol := false
	var tam := get_viewport_rect().size
	match cal:
		"barrera":
			destino = Vector2(tam.x / 2.0 - 20, _arco_pos.y + ARCO_TAM.y + 70)
			texto = "Floja: se la comió la barrera."
		"alto":
			destino = Vector2(destino.x, _arco_pos.y - 90)
			texto = "Demasiado fuerte: por encima del larguero."
		_:
			## El portero se tira: a la zona que más has repetido o al azar.
			var p := prob_atajada(_zona, _historial, cal)
			var ataja := _rng.randf() < p
			var tirada := destino if ataja else _arco_pos + Vector2(_rng.randf_range(0.0, ARCO_TAM.x - 64), ARCO_TAM.y - 84)
			var tw := create_tween()
			tw.tween_property(_portero, "position", tirada - Vector2(12, 12), 0.35)
			gol = not ataja
			texto = ("¡GOLAZO! Con rosca, imposible." if cal == "justo" else "¡Gol!") if gol else "¡Atajada! El portero se lo olía."
	_historial.append(_zona)
	var tw2 := create_tween()
	tw2.tween_property(_balon, "position", destino, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(_balon, "scale", Vector2(0.6, 0.6), 0.45)
	tw2.tween_interval(0.7)
	tw2.tween_callback(func() -> void:
		_tiros += 1
		if gol:
			_goles += 1
		_aviso.text = texto
		_pintar_marcador()
		_poner_balon()
		_portero.position = _arco_pos + Vector2(ARCO_TAM.x / 2.0 - 32, ARCO_TAM.y - 84)
		_ocupado = false
		_barra.value = 0.0
		if _tiros >= TIROS:
			_fin())

func _fin() -> void:
	record = maxi(record, _goles)
	var msg := "Terminó la sesión: %d de %d." % [_goles, TIROS]
	if _goles >= 3 and _mundo != null and _mundo.mi_club() != null:
		var marca := _mundo.anio * 60 + _mundo.semana
		if marca != _premio_semana:
			_premio_semana = marca
			for j: Jugador in _mundo.mi_club().plantilla:
				j.moral = clampi(j.moral + 1, 10, 99)
			msg += " El plantel se fue contento del entrenamiento (moral +1)."
	_aviso.text = msg
	_pintar_marcador()
