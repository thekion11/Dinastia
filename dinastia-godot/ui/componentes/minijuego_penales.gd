class_name MinijuegoPenales
extends Control
## MINIJUEGO: TANDA DE PENALES EN EL ENTRENAMIENTO (26-9-2026, plan maestro C7).
## Pedido: *"minijuegos dentro del juego"*. Cinco penales contra el portero del
## club: eliges la esquina (seis zonas) y el portero se tira. No es azar puro: el
## portero APRENDE, y se tira más a donde ya pateaste dos veces, así que repetir
## esquina sale caro. Si marcas cuatro o más, el plantel se lo pasa bien (moral
## +1, una vez por semana). El portero sortea con un generador local, no con
## `Azar`: jugar no cambia nada de la partida.

signal cerrado

const TIROS := 5
const ZONAS := [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]
const NOMBRE_ZONA := ["arriba a la izquierda", "arriba al medio", "arriba a la derecha",
	"abajo a la izquierda", "abajo al medio", "abajo a la derecha"]

var _mundo: Mundo
var _rng := RandomNumberGenerator.new()
var _tiros := 0
var _goles := 0
var _historial: Array[int] = []
var _marcador: Label
var _ocupado := false
var _botones: Array[Button] = []
## En 3D (7-10-2026, «los mini juegos también deben ser 3D con animaciones»):
## arco con red, el portero que se tira con las animaciones de atajada, tu
## jugador que toma carrera y patea, y el balón en su parábola. Las seis zonas
## clicables se calculan proyectando el arco a la pantalla.
var _v := {}
var _cam: Camera3D
var _raiz: Node3D
var _portero := {}
var _pateador := {}
var _balon: Node3D
var _red: Node3D

static var _premio_semana := -1

static func mostrar(padre: Control, mundo: Mundo) -> MinijuegoPenales:
	var n := MinijuegoPenales.new()
	n._mundo = mundo
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

const ARCO_ANCHO := 7.32
const ARCO_ALTO := 2.44
const PUNTO := 11.0

## Centro de cada zona sobre la boca del arco (x: tres columnas, y: dos alturas).
func _punto_zona(z: int) -> Vector3:
	return Vector3(ZONAS[z].x * 2.4, 1.75 if ZONAS[z].y < 0 else 0.55, 0.0)

func _montar() -> void:
	_rng.seed = Time.get_ticks_usec()
	_v = Mini3D.vista(self, Calidad.TARDE)
	_cam = _v["cam"]
	_raiz = _v["raiz"]
	## El césped a franjas y las líneas del área.
	for k in 16:
		Mini3D.caja(_raiz, Vector3(0, -0.05, -10.0 + float(k) * 3.0), Vector3(70, 0.1, 3.0),
			Mini3D.mat(Color(0.2, 0.47, 0.22) if k % 2 == 0 else Color(0.24, 0.53, 0.26), 0.9))
	var cal := Mini3D.mat(Color(0.95, 0.95, 0.95), 0.6)
	Mini3D.caja(_raiz, Vector3(0, 0.01, 0), Vector3(40.3, 0.02, 0.12), cal)
	for x: float in [-9.16, 9.16]:
		Mini3D.caja(_raiz, Vector3(x, 0.01, 2.75), Vector3(0.12, 0.02, 5.5), cal)
	Mini3D.caja(_raiz, Vector3(0, 0.01, 5.5), Vector3(18.32, 0.02, 0.12), cal)
	for x: float in [-20.16, 20.16]:
		Mini3D.caja(_raiz, Vector3(x, 0.01, 8.25), Vector3(0.12, 0.02, 16.5), cal)
	Mini3D.caja(_raiz, Vector3(0, 0.01, 16.5), Vector3(40.3, 0.02, 0.12), cal)
	Mini3D.cilindro(_raiz, Vector3(0, 0.01, PUNTO), 0.12, 0.02, cal)
	## El arco: postes, travesaño y la red (lados, techo y fondo).
	var blanco := Mini3D.mat(Color.WHITE, 0.3)
	for x: float in [-ARCO_ANCHO * 0.5, ARCO_ANCHO * 0.5]:
		Mini3D.cilindro(_raiz, Vector3(x, ARCO_ALTO * 0.5, 0), 0.06, ARCO_ALTO + 0.06, blanco)
	var trav := Mini3D.cilindro(_raiz, Vector3(0, ARCO_ALTO, 0), 0.06, ARCO_ANCHO + 0.12, blanco)
	trav.rotation.z = PI * 0.5
	_red = Node3D.new()
	_raiz.add_child(_red)
	var red_m := Mini3D.mat(Color(0.95, 0.95, 0.95, 0.28), 0.8)
	red_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	Mini3D.caja(_red, Vector3(0, ARCO_ALTO * 0.5, -2.0), Vector3(ARCO_ANCHO, ARCO_ALTO, 0.02), red_m)
	Mini3D.caja(_red, Vector3(0, ARCO_ALTO, -1.0), Vector3(ARCO_ANCHO, 0.02, 2.0), red_m)
	for x: float in [-ARCO_ANCHO * 0.5, ARCO_ANCHO * 0.5]:
		Mini3D.caja(_red, Vector3(x, ARCO_ALTO * 0.5, -1.0), Vector3(0.02, ARCO_ALTO, 2.0), red_m)
	## La cuadrícula de la red, en hilos.
	var hilo := Mini3D.mat(Color(0.9, 0.9, 0.9, 0.6), 0.8)
	for k in 25:
		Mini3D.caja(_red, Vector3(-ARCO_ANCHO * 0.5 + float(k) * ARCO_ANCHO / 24.0, ARCO_ALTO * 0.5, -2.0), Vector3(0.015, ARCO_ALTO, 0.015), hilo)
	for k in 9:
		Mini3D.caja(_red, Vector3(0, float(k) * ARCO_ALTO / 8.0, -2.0), Vector3(ARCO_ANCHO, 0.015, 0.015), hilo)
	## Vallas de publicidad y una grada al fondo.
	for k in 6:
		Mini3D.caja(_raiz, Vector3(-17.5 + float(k) * 7.0, 0.5, -5.0), Vector3(6.8, 1.0, 0.2),
			Mini3D.mat(Color.from_hsv(float(k) * 0.17, 0.6, 0.8), 0.5, 0.25))
	for f in 6:
		Mini3D.caja(_raiz, Vector3(0, 1.4 + float(f) * 0.9, -8.0 - float(f) * 1.2), Vector3(48, 0.9, 1.2), Mini3D.mat(Color(0.3, 0.32, 0.38), 0.8))
	## El portero (de verde, manga larga) y tu jugador con los colores del club.
	var c1 := Color(0.8, 0.12, 0.12)
	var c2 := Color.WHITE
	if _mundo != null and _mundo.mi_club() != null:
		c1 = Color(_mundo.mi_club().color1)
		c2 = Color(_mundo.mi_club().color2)
	_portero = Mini3D.persona(_raiz, _rng, Vector3(0, 0, 0.3), [Color(0.15, 0.7, 0.3), Color(0.08, 0.08, 0.08), true])
	if not _portero.is_empty():
		Mini3D.anim(_portero, "portero_listo", "")
	_pateador = Mini3D.persona(_raiz, _rng, Vector3(-1.2, 0, PUNTO + 2.2), [c1, c2])
	if not _pateador.is_empty():
		(_pateador["nodo"] as Node3D).rotation.y = PI + 0.45
	_balon = Node3D.new()
	_raiz.add_child(_balon)
	Mini3D.esfera(_balon, Vector3.ZERO, 0.11, Mini3D.mat(Color.WHITE, 0.4))
	for k in 6:
		var parche := Mini3D.esfera(_balon, Vector3(sin(float(k)) , cos(float(k) * 1.7), sin(float(k) * 2.3)).normalized() * 0.085, 0.035, Mini3D.mat(Color(0.08, 0.08, 0.08), 0.4))
		parche.scale = Vector3(1, 1, 0.6)
	_cam.position = Vector3(0.6, 2.5, PUNTO + 7.5)
	_cam.fov = 36.0
	_cam.look_at(Vector3(0, 1.0, 2.0), Vector3.UP)
	## La interfaz.
	var banda := ColorRect.new()
	banda.color = Color(0, 0, 0, 0.45)
	banda.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banda.offset_bottom = 96
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banda)
	var titulo := Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, "🎯 Tanda de penales en el entrenamiento")
	titulo.position = Vector2(24, 14)
	add_child(titulo)
	_marcador = Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "")
	_marcador.position = Vector2(24, 56)
	add_child(_marcador)
	## Seis zonas clicables sobre el arco (se recolocan cada cuadro).
	for z in ZONAS.size():
		var b := Button.new()
		b.flat = true
		b.tooltip_text = "Patear " + NOMBRE_ZONA[z]
		b.pressed.connect(_patear.bind(z))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.12)
		sb.border_color = Color(1, 0.85, 0.3, 0.9)
		sb.set_border_width_all(2)
		b.add_theme_stylebox_override("hover", sb)
		add_child(b)
		_botones.append(b)
	var ayuda := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Haz clic en la esquina del arco donde quieres patear. El portero aprende de tus tiros.")
	ayuda.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ayuda.offset_top = -50
	ayuda.offset_left = -400
	ayuda.offset_right = 400
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(ayuda)
	var salir := Button.new()
	salir.text = "Volver"
	salir.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -120
	salir.offset_right = -20
	salir.offset_top = 20
	salir.offset_bottom = 56
	salir.pressed.connect(_cerrar)
	add_child(salir)
	_colocar_inicio()
	_pintar_marcador()

func _process(_d: float) -> void:
	## Las zonas siguen al arco proyectado en pantalla.
	if _cam == null or not _cam.is_inside_tree():
		return
	for z in _botones.size():
		var c := _punto_zona(z)
		var a := _cam.unproject_position(c + Vector3(-1.2, 0.6, 0))
		var b := _cam.unproject_position(c + Vector3(1.2, -0.6, 0))
		_botones[z].position = Vector2(minf(a.x, b.x), minf(a.y, b.y))
		_botones[z].size = (b - a).abs()

func _colocar_inicio() -> void:
	if _balon != null:
		_balon.position = Vector3(0, 0.11, PUNTO)
		_balon.rotation = Vector3.ZERO
	if not _portero.is_empty():
		var pn: Node3D = _portero["nodo"]
		pn.position = Vector3(0, 0, 0.3)
		pn.rotation = Vector3.ZERO
		Mini3D.anim(_portero, "portero_listo", "")
	if not _pateador.is_empty():
		var tn: Node3D = _pateador["nodo"]
		tn.position = Vector3(-1.2, 0, PUNTO + 2.2)
		tn.rotation.y = PI + 0.45
		Mini3D.anim(_pateador, "parado", "")

func _pintar_marcador() -> void:
	_marcador.text = "Tiro %d de %d  ·  Goles: %d" % [mini(_tiros + 1, TIROS), TIROS, _goles]

## Adónde se tira el portero: si ya pateaste dos veces a la misma zona, se
## tira ahí; si no, al azar local.
func eleccion_portero() -> int:
	var cuenta := {}
	for h in _historial:
		cuenta[h] = int(cuenta.get(h, 0)) + 1
	for z: int in cuenta:
		if int(cuenta[z]) >= 2 and _rng.randf() < 0.75:
			return z
	return _rng.randi() % ZONAS.size()

func _patear(z: int) -> void:
	if _ocupado or _tiros >= TIROS:
		return
	_ocupado = true
	var p := eleccion_portero()
	_historial.append(z)
	## Mismo lado y misma altura = atajada; mismo lado distinta altura, la
	## toca a veces (las de arriba al ángulo son las más difíciles).
	var atajada: bool = p == z or (int(ZONAS[p].x) == int(ZONAS[z].x) and ZONAS[z].y > 0 and _rng.randf() < 0.35)
	var destino := _punto_zona(z) + Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.2, 0.2), 0)
	var tw := create_tween()
	## La carrera: tres pasos hasta el balón y el golpe.
	if not _pateador.is_empty():
		var tn: Node3D = _pateador["nodo"]
		Mini3D.anim(_pateador, "trotar", "")
		tw.tween_property(tn, "position", Vector3(-0.35, 0, PUNTO + 0.45), 0.55)
		tw.tween_callback(func() -> void: Mini3D.anim(_pateador, "penal", "parado", 0.1))
		tw.tween_interval(0.28)
	## El portero se tira hacia su zona (su derecha es nuestra izquierda).
	tw.tween_callback(func() -> void:
		if _portero.is_empty():
			return
		var px := float(ZONAS[p].x)
		var clip := "atajar_bajo" if px == 0.0 else ("atajar_der" if px < 0.0 else "atajar_izq")
		Mini3D.anim(_portero, clip, "", 0.05)
		var pn: Node3D = _portero["nodo"]
		var tp := pn.create_tween()
		tp.tween_property(pn, "position", Vector3(px * 1.5, 0, 0.4), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	## El balón vuela en parábola; si lo ataja, sale rebotado hacia un lado.
	var desde := Vector3(0, 0.11, PUNTO)
	var hasta := destino + (Vector3(0, 0, 0) if atajada else Vector3(0, 0, -1.6))
	tw.tween_method(func(f: float) -> void:
		_balon.position = desde.lerp(hasta, f) + Vector3(0, sin(f * PI) * 0.6, 0)
		_balon.rotation.x -= 0.5, 0.0, 1.0, 0.42 if not atajada else 0.36)
	tw.tween_callback(func() -> void:
		if atajada:
			var rebote := _balon.position + Vector3(signf(_balon.position.x + 0.01) * 4.0, -0.5, 5.0)
			rebote.y = 0.11
			var tb := _balon.create_tween()
			tb.tween_property(_balon, "position", rebote, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			Mini3D.anim(_pateador, "manos_cabeza", "parado")
		else:
			## La red se infla con el gol.
			var tr := _red.create_tween()
			tr.tween_property(_red, "scale", Vector3(1, 1, 1.25), 0.1)
			tr.tween_property(_red, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC)
			var tb := _balon.create_tween()
			tb.tween_property(_balon, "position:y", 0.11, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			Mini3D.anim(_pateador, ["celebrar", "puno_al_aire", "celebrar_carrera"][_rng.randi() % 3], "parado"))
	tw.tween_interval(1.6)
	tw.tween_callback(func() -> void:
		_tiros += 1
		if not atajada:
			_goles += 1
			Sonido.toca("gol" if Sonido.NOMBRES.has("gol") else "cambio", Sonido.Bus.INTERFAZ)
		_colocar_inicio()
		_pintar_marcador()
		_ocupado = false
		if _tiros >= TIROS:
			_final())

func _final() -> void:
	var t := "%d de %d." % [_goles, TIROS]
	if _goles >= 4 and _mundo != null and _premio_semana != _mundo.semana:
		_premio_semana = _mundo.semana
		for j: Jugador in _mundo.mi_club().plantilla:
			j.moral = clampi(j.moral + 1, 10, 99)
		t += " El plantel se lo pasó en grande: moral +1."
	_marcador.text = "🏁 " + t
	for b in _botones:
		b.disabled = true

func _cerrar() -> void:
	cerrado.emit()
	queue_free()
