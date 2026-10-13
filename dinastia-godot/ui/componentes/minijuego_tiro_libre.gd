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
## En 3D (7-10-2026, «los mini juegos también deben ser 3D con animaciones»):
## la falta desde la frontal con la barrera de verdad, el portero que se tira
## y el balón que hace la curva por encima de la barrera.
const FALTA := Vector3(-3.0, 0.11, 21.0)

static var record := 0
static var _premio_semana := -1

var _mundo: Mundo
var _rng := RandomNumberGenerator.new()
var _tiros := 0
var _goles := 0
var _zona := -1
var _historial: Array[int] = []
var _v := {}
var _cam: Camera3D
var _raiz: Node3D
var _red: Node3D
var _balon: Node3D
var _portero := {}
var _pateador := {}
var _barrera: Array = []
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
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_v = Mini3D.vista(self, Calidad.DIA)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	_red = Mini3D.campo_y_arco(_raiz)
	var c1 := Color(0.8, 0.12, 0.12)
	var c2 := Color.WHITE
	if _mundo != null and _mundo.mi_club() != null:
		c1 = Color(_mundo.mi_club().color1)
		c2 = Color(_mundo.mi_club().color2)
	_portero = Mini3D.persona(_raiz, _rng, Vector3(0.6, 0, 0.3), [Color(0.95, 0.75, 0.1), Color(0.1, 0.1, 0.1), true])
	## La barrera: cuatro suplentes con peto azul a 9,15 m, tapando el palo cercano.
	var hacia := (Vector3(-0.8, 0, 0) - FALTA).normalized()
	hacia.y = 0.0
	var centro := FALTA + hacia * 9.15
	var lat := Vector3(-hacia.z, 0, hacia.x)
	for k in 4:
		var d := Mini3D.persona(_raiz, _rng, centro + lat * (float(k) - 1.5) * 0.62 - Vector3(0, centro.y, 0), [Color(0.15, 0.35, 0.8), Color(0.1, 0.12, 0.2)])
		if d.is_empty():
			continue
		(d["nodo"] as Node3D).rotation.y = atan2(-hacia.x, -hacia.z)
		_barrera.append(d)
	_pateador = Mini3D.persona(_raiz, _rng, Vector3.ZERO, [c1, c2])
	_balon = Node3D.new()
	_raiz.add_child(_balon)
	Mini3D.esfera(_balon, Vector3.ZERO, 0.11, Mini3D.mat(Color.WHITE, 0.4))
	for k in 6:
		var parche := Mini3D.esfera(_balon, Vector3(sin(float(k)), cos(float(k) * 1.7), sin(float(k) * 2.3)).normalized() * 0.085, 0.035, Mini3D.mat(Color(0.08, 0.08, 0.08), 0.4))
		parche.scale = Vector3(1, 1, 0.6)
	_cam.fov = 40.0
	_cam.fov = 46.0
	_cam.position = FALTA + Vector3(1.6, 3.4, 7.2)
	_cam.look_at(Vector3(-1.2, -0.3, 11.0), Vector3.UP)
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.45)
	banda.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 60
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	_poner_balon()
	## Zonas: botones transparentes sobre el arco (siguen al arco proyectado).
	for i in ZONAS.size():
		var b := Button.new()
		b.flat = true
		b.text = ""
		b.tooltip_text = NOMBRE_ZONA[i]
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.12)
		sb.border_color = Color(1, 0.85, 0.3, 0.9)
		sb.set_border_width_all(2)
		b.add_theme_stylebox_override("hover", sb)
		b.pressed.connect(func() -> void: _elegir(i))
		add_child(b)
		_botones.append(b)
	_marcador = _lbl("", 22, Color.WHITE)
	_marcador.position = Vector2(24, 20)
	add_child(_marcador)
	_aviso = _lbl("Toca la zona del arco a la que quieres patear.", 18, Color(1, 0.95, 0.75))
	_aviso.position = Vector2(tam.x - 660, tam.y - 170)
	_aviso.size = Vector2(600, 30)
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_aviso)
	_barra = ProgressBar.new()
	_barra.max_value = 1.0
	_barra.step = 0.001
	_barra.show_percentage = false
	_barra.position = Vector2(tam.x - 580, tam.y - 128)
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
	_boton_patear.position = Vector2(tam.x - 470, tam.y - 92)
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
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _punto_zona(z: int) -> Vector3:
	return Vector3(ZONAS[z].x * 2.5, 1.85 if ZONAS[z].y < 0 else 0.5, 0.0)

func _poner_balon() -> void:
	_balon.position = FALTA
	_balon.rotation = Vector3.ZERO
	if not _pateador.is_empty():
		var tn: Node3D = _pateador["nodo"]
		tn.position = FALTA + Vector3(-1.4, -FALTA.y, 2.4)
		tn.rotation.y = PI + 0.5
		Mini3D.anim(_pateador, "parado", "")
	if not _portero.is_empty():
		var pn: Node3D = _portero["nodo"]
		pn.position = Vector3(0.6, 0, 0.3)
		pn.rotation = Vector3.ZERO
		Mini3D.anim(_portero, "portero_listo", "")
	for d: Dictionary in _barrera:
		Mini3D.anim(d, "muralla", "")

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
	if _cam != null and _cam.is_inside_tree():
		for z in _botones.size():
			var c := _punto_zona(z)
			var a := _cam.unproject_position(c + Vector3(-1.22, 0.62, 0))
			var b := _cam.unproject_position(c + Vector3(1.22, -0.62, 0))
			_botones[z].position = Vector2(minf(a.x, b.x), minf(a.y, b.y))
			_botones[z].size = (b - a).abs()
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
	var destino := _punto_zona(_zona) + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.15, 0.15), 0)
	var texto := ""
	var gol := false
	var ataja := false
	var dir_portero := 0.0
	match cal:
		"barrera":
			destino = FALTA + (Vector3(-0.8, 0, 0) - FALTA).normalized() * 9.0 + Vector3(0, 1.5, 0)
			texto = "Floja: se la comió la barrera."
		"alto":
			destino = Vector3(destino.x, 3.8, -1.5)
			texto = "Demasiado fuerte: por encima del larguero."
		_:
			## El portero se tira: a la zona que más has repetido o al azar.
			var p := prob_atajada(_zona, _historial, cal)
			ataja = _rng.randf() < p
			dir_portero = signf(destino.x) if ataja else [-1.0, 1.0][_rng.randi() % 2]
			gol = not ataja
			if gol:
				destino.z = -1.4
			texto = ("¡GOLAZO! Con rosca, imposible." if cal == "justo" else "¡Gol!") if gol else "¡Atajada! El portero se lo olía."
	_historial.append(_zona)
	var tw := create_tween()
	## Carrera y golpeo.
	if not _pateador.is_empty():
		var tn: Node3D = _pateador["nodo"]
		Mini3D.anim(_pateador, "trotar", "")
		tw.tween_property(tn, "position", FALTA + Vector3(-0.45, -FALTA.y, 0.5), 0.55)
		tw.tween_callback(func() -> void: Mini3D.anim(_pateador, "patear", "parado", 0.1))
		tw.tween_interval(0.3)
	## La barrera salta y el portero vuela.
	tw.tween_callback(func() -> void:
		for d: Dictionary in _barrera:
			var bn: Node3D = d["nodo"]
			var tb := bn.create_tween()
			tb.tween_property(bn, "position:y", 0.45, 0.22).set_ease(Tween.EASE_OUT)
			tb.tween_property(bn, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN)
		if cal != "barrera" and not _portero.is_empty():
			var pn: Node3D = _portero["nodo"]
			var clip := "atajar_bajo" if dir_portero == 0.0 else ("atajar_der" if dir_portero < 0.0 else "atajar_izq")
			Mini3D.anim(_portero, clip, "", 0.05)
			var tp := pn.create_tween()
			tp.tween_interval(0.25)
			tp.tween_property(pn, "position", Vector3(dir_portero * 1.8, 0, 0.4), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	## El balón: curva de Bézier por encima de la barrera, con rosca hacia afuera.
	var desde := FALTA
	var rosca := Vector3(-2.2 if destino.x > desde.x else 2.2, 0, 0) * (1.4 if cal == "justo" else 1.0)
	var control := (desde + destino) * 0.5 + Vector3(0, 2.2 if cal != "barrera" else 0.8, 0) + rosca
	tw.tween_method(func(f: float) -> void:
		var q0 := desde.lerp(control, f)
		var q1 := control.lerp(destino, f)
		_balon.position = q0.lerp(q1, f)
		_balon.rotation.x -= 0.45
		_balon.rotation.y += 0.3, 0.0, 1.0, 0.75 if cal != "barrera" else 0.4)
	tw.tween_callback(func() -> void:
		if gol:
			var tr := _red.create_tween()
			tr.tween_property(_red, "scale", Vector3(1, 1, 1.25), 0.1)
			tr.tween_property(_red, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC)
			_balon.create_tween().tween_property(_balon, "position:y", 0.11, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			Mini3D.anim(_pateador, ["celebrar", "puno_al_aire", "celebrar_rodillas"][_rng.randi() % 3], "parado")
		else:
			var rebote := _balon.position + Vector3(_rng.randf_range(-4.0, 4.0), 0, 4.0)
			rebote.y = 0.11
			_balon.create_tween().tween_property(_balon, "position", rebote, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			Mini3D.anim(_pateador, "manos_cabeza", "parado")
		_aviso.text = texto)
	tw.tween_interval(1.6)
	tw.tween_callback(func() -> void:
		_tiros += 1
		if gol:
			_goles += 1
		_pintar_marcador()
		_poner_balon()
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
