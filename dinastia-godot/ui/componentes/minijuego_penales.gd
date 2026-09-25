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
var _arco: Control
var _portero: Label
var _balon: Label
var _marcador: Label
var _ocupado := false
var _botones: Array[Button] = []

static var _premio_semana := -1

static func mostrar(padre: Control, mundo: Mundo) -> MinijuegoPenales:
	var n := MinijuegoPenales.new()
	n._mundo = mundo
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

## Todo con coordenadas absolutas de la pantalla (no anclas): el arco y el
## césped tienen que quedar en su sitio exacto para que las zonas y el tiro
## coincidan con lo que se ve.
var _arco_pos := Vector2.ZERO
const ARCO_TAM := Vector2(480, 170)

func _montar() -> void:
	_rng.seed = Time.get_ticks_usec()
	var tam := get_viewport_rect().size
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.10, 0.07)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_arco_pos = Vector2(tam.x / 2.0 - ARCO_TAM.x / 2.0, tam.y * 0.28)
	## Primero el césped (desde la línea de gol hacia abajo), después el arco.
	var cesped := ColorRect.new()
	cesped.color = Color(0.18, 0.45, 0.24)
	cesped.position = Vector2(tam.x / 2.0 - 420.0, _arco_pos.y + ARCO_TAM.y)
	cesped.size = Vector2(840, tam.y * 0.5)
	add_child(cesped)
	var area := ReferenceRect.new()
	area.border_color = Color(1, 1, 1, 0.7)
	area.border_width = 3
	area.editor_only = false
	area.position = Vector2(tam.x / 2.0 - 330.0, _arco_pos.y + ARCO_TAM.y)
	area.size = Vector2(660, 190)
	add_child(area)
	var red := ColorRect.new()
	red.color = Color(0.85, 0.9, 0.95, 0.08)
	red.position = _arco_pos
	red.size = ARCO_TAM
	add_child(red)
	for poste: Array in [[Vector2(-8, -8), Vector2(8, ARCO_TAM.y + 8)], [Vector2(ARCO_TAM.x, -8), Vector2(8, ARCO_TAM.y + 8)],
			[Vector2(-8, -8), Vector2(ARCO_TAM.x + 16, 8)]]:
		var r := ColorRect.new()
		r.color = Color.WHITE
		r.position = _arco_pos + (poste[0] as Vector2)
		r.size = poste[1]
		add_child(r)
	var titulo := Tema.etiqueta(Tema.TAM_TITULO, Tema.ORO, "🎯 Tanda de penales en el entrenamiento")
	titulo.position = Vector2(tam.x / 2.0 - 260.0, 30)
	add_child(titulo)
	_marcador = Tema.etiqueta(Tema.TAM_DESTACADO, Tema.TEXTO, "")
	_marcador.position = Vector2(tam.x / 2.0 - 260.0, 72)
	add_child(_marcador)
	_portero = Label.new()
	_portero.text = "🧤"
	_portero.add_theme_font_size_override("font_size", 64)
	add_child(_portero)
	_balon = Label.new()
	_balon.text = "⚽"
	_balon.add_theme_font_size_override("font_size", 34)
	add_child(_balon)
	## Seis zonas clicables sobre el arco.
	for z in ZONAS.size():
		var b := Button.new()
		b.flat = true
		b.tooltip_text = "Patear " + NOMBRE_ZONA[z]
		b.position = _arco_pos + Vector2((ZONAS[z].x + 1.0) * 160.0, (ZONAS[z].y + 1.0) * 42.5)
		b.size = Vector2(160, 85)
		b.pressed.connect(_patear.bind(z))
		add_child(b)
		_botones.append(b)
	var ayuda := Tema.etiqueta(Tema.TAM_CUERPO, Tema.SUAVE, "Haz clic en la esquina del arco donde quieres patear. El portero aprende de tus tiros.")
	ayuda.position = Vector2(tam.x / 2.0 - 330.0, tam.y - 60.0)
	add_child(ayuda)
	var salir := Button.new()
	salir.text = "Volver"
	salir.position = Vector2(tam.x - 120.0, 20)
	salir.pressed.connect(_cerrar)
	add_child(salir)
	_colocar_inicio()
	_pintar_marcador()

func _centro_zona(z: int) -> Vector2:
	return _arco_pos + Vector2((ZONAS[z].x + 1.0) * 160.0 + 80.0, (ZONAS[z].y + 1.0) * 42.5 + 42.0)

func _colocar_inicio() -> void:
	_portero.position = _arco_pos + Vector2(ARCO_TAM.x / 2.0 - 32.0, ARCO_TAM.y - 80.0)
	_balon.position = _arco_pos + Vector2(ARCO_TAM.x / 2.0 - 17.0, ARCO_TAM.y + 150.0)

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
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_balon, "position", _centro_zona(z) - Vector2(17, 20), 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_portero, "position", _centro_zona(p) - Vector2(32, 40), 0.3).set_trans(Tween.TRANS_BACK)
	tw.set_parallel(false)
	tw.tween_interval(0.6)
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
