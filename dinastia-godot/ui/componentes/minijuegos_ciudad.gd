class_name MinijuegosCiudad
extends Control
## LOS MINIJUEGOS DE LA CIUDAD (7-10-2026, pedido: «puedes crear minijuegos
## dentro de la ciudad»). Se abren al llegar a un lugar (E en el modo a pie o
## al volante, o clic en el mapa):
##   · Plaza Mayor → AUTÓGRAFOS: los hinchas asoman entre la gente; tócalos
##     antes de que se vayan (30 s). Más reputación del club, más hinchas.
##   · Puerto → PESCA: el corcho flota; cuando grita «¡PICA!», tienes un
##     instante para tirar. Seis lanzadas.
##   · Karting → CONTRARRELOJ: tres vueltas al óvalo con tu kart (flechas o
##     WASD); salirte del asfalto te frena.
##   · Universidad / Cine → la TRIVIA del club.  · Parques → PENALES con los
##     chicos del barrio.
## Todo con un generador propio: jugar no cambia la partida.

const LUGARES := {
	"ciudad_plaza_mayor": "autografos", "ciudad_puerto": "pesca", "karting": "karting",
	"ciudad_universidad": "trivia", "ciudad_cine": "trivia", "ciudad_parque": "penales",
	"ciudad_parque_lago": "penales", "ciudad_instituto": "trivia",
}

static var records := {"autografos": 0, "pesca": 0, "karting": 0.0}

static func juego_de(k: String) -> String:
	return String(LUGARES.get(k, ""))

static func abrir(padre: Control, juego: String, club: Club) -> Control:
	var mundo: Mundo = null
	var p := padre
	while p != null and mundo == null:
		if p.get("mundo") is Mundo:
			mundo = p.get("mundo")
		p = p.get_parent() as Control
	match juego:
		"trivia":
			if mundo != null:
				return TriviaClub.mostrar(padre, mundo)
			return null
		"penales":
			if mundo != null:
				return MinijuegoPenales.mostrar(padre, mundo)
			return null
	var n := MinijuegosCiudad.new()
	n.juego = juego
	n.rep = club.rep if club != null else 60
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

var juego := ""
var rep := 60
var _rng := RandomNumberGenerator.new()
var _titulo: Label
var _aviso: Label
var _zona: Control
var _t := 0.0
var _puntos := 0
var _activo := false

func _montar() -> void:
	_rng.seed = Time.get_ticks_usec()
	var fondo := ColorRect.new()
	fondo.color = {"autografos": Color(0.12, 0.1, 0.08), "pesca": Color(0.06, 0.14, 0.2), "karting": Color(0.12, 0.14, 0.12)}.get(juego, Color.BLACK)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_titulo = _lbl("", 22, Color.WHITE)
	_titulo.position = Vector2(24, 18)
	add_child(_titulo)
	_aviso = _lbl("", 18, Color(1, 0.92, 0.6))
	_aviso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_aviso.offset_top = -70
	_aviso.offset_left = -400
	_aviso.offset_right = 400
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_aviso)
	_zona = Control.new()
	_zona.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zona.offset_top = 60
	_zona.offset_bottom = -90
	add_child(_zona)
	var salir := Button.new()
	salir.text = "Salir"
	salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	salir.offset_left = -110
	salir.offset_right = -20
	salir.offset_top = 16
	salir.offset_bottom = 52
	salir.pressed.connect(queue_free)
	add_child(salir)
	match juego:
		"autografos":
			_t = 30.0
			_activo = true
			_aviso.text = "¡Toca a los hinchas que piden autógrafo antes de que se vayan!"
		"pesca":
			_pesca_empezar()
		"karting":
			_kart_empezar()

func _lbl(t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _process(delta: float) -> void:
	match juego:
		"autografos":
			_autografos(delta)
		"pesca":
			_pesca(delta)
		"karting":
			_kart(delta)
			if _pista != null:
				_pista.queue_redraw()

# ------------------------------------------------------------- AUTÓGRAFOS

var _prox_hincha := 0.0

func _autografos(delta: float) -> void:
	if not _activo:
		return
	_t -= delta
	_titulo.text = "✍️ Autógrafos en la Plaza Mayor  ·  %d s  ·  firmados: %d  ·  récord: %d" % [int(ceil(_t)), _puntos, records["autografos"]]
	if _t <= 0.0:
		_activo = false
		records["autografos"] = maxi(int(records["autografos"]), _puntos)
		_aviso.text = "¡Firmaste %d autógrafos! %s" % [_puntos, "La plaza entera coreó tu nombre." if _puntos >= 20 else "La gente se fue contenta."]
		for h in _zona.get_children():
			h.queue_free()
		return
	_prox_hincha -= delta
	if _prox_hincha <= 0.0:
		## Con más reputación, aparecen más rápido.
		_prox_hincha = _rng.randf_range(0.35, 0.9) * lerpf(1.3, 0.7, float(rep) / 100.0)
		var b := Button.new()
		b.text = ["🙋", "🙋‍♀️", "🧒", "👴", "👩", "🧑‍🦱"][_rng.randi() % 6]
		b.flat = true
		b.add_theme_font_size_override("font_size", 46)
		var tam := _zona.size
		b.position = Vector2(_rng.randf_range(20.0, maxf(40.0, tam.x - 80.0)), _rng.randf_range(10.0, maxf(30.0, tam.y - 80.0)))
		b.pressed.connect(func() -> void:
			_puntos += 1
			b.text = "✍️"
			b.disabled = true
			get_tree().create_timer(0.3).timeout.connect(b.queue_free))
		_zona.add_child(b)
		get_tree().create_timer(_rng.randf_range(1.1, 1.8)).timeout.connect(func() -> void:
			if is_instance_valid(b) and not b.disabled:
				b.queue_free())

# ------------------------------------------------------------- PESCA

var _lanzadas := 0
var _estado_pesca := "espera"   ## espera / pica / fin
var _corcho: Label
var _capturas: Array = []
const PECES := [["🐟 una mojarra", 1], ["🐠 un pez payaso (¿en un río?)", 2], ["🐡 un pez globo", 2], ["🦈 ¡un tiburón de río!", 5], ["🥾 una bota vieja", 0], ["🐟 una trucha", 3]]

func _pesca_empezar() -> void:
	_corcho = _lbl("🎣", 64, Color.WHITE)
	_corcho.set_anchors_preset(Control.PRESET_CENTER)
	_zona.add_child(_corcho)
	var tirar := Button.new()
	tirar.text = "¡TIRAR! (espacio)"
	tirar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tirar.offset_top = -50
	tirar.offset_left = -110
	tirar.offset_right = 110
	tirar.pressed.connect(_tirar)
	_zona.add_child(tirar)
	_nueva_lanzada()

func _nueva_lanzada() -> void:
	if _lanzadas >= 6:
		_estado_pesca = "fin"
		records["pesca"] = maxi(int(records["pesca"]), _puntos)
		_aviso.text = "Fin de la pesca: %d puntos. %s" % [_puntos, ", ".join(_capturas) if not _capturas.is_empty() else "Hoy no picó nada."]
		return
	_estado_pesca = "espera"
	_t = _rng.randf_range(1.5, 4.5)
	_aviso.text = "Lanzada %d de 6. Espera a que pique…" % (_lanzadas + 1)

func _pesca(delta: float) -> void:
	_titulo.text = "🎣 Pesca en el puerto fluvial  ·  puntos: %d  ·  récord: %d" % [_puntos, records["pesca"]]
	if _corcho != null:
		_corcho.position.y = _zona.size.y * 0.4 + sin(Time.get_ticks_msec() * 0.004) * (12.0 if _estado_pesca == "pica" else 4.0)
	if _estado_pesca == "fin":
		return
	_t -= delta
	if _estado_pesca == "espera" and _t <= 0.0:
		_estado_pesca = "pica"
		_t = 0.75
		_aviso.text = "¡¡PICA!!"
	elif _estado_pesca == "pica" and _t <= 0.0:
		_lanzadas += 1
		_aviso.text = "Se escapó… demasiado lento."
		get_tree().create_timer(1.0).timeout.connect(_nueva_lanzada)
		_estado_pesca = "espera"
		_t = 99.0

func _tirar() -> void:
	if _estado_pesca == "pica":
		var pez: Array = PECES[_rng.randi() % PECES.size()]
		_puntos += int(pez[1])
		_capturas.append(String(pez[0]).split(" ", true, 1)[0])
		_aviso.text = "¡Sacaste %s! (+%d)" % [pez[0], pez[1]]
	elif _estado_pesca == "espera" and _t < 90.0:
		_aviso.text = "Tiraste antes de tiempo: se espantó el pez."
	else:
		return
	_lanzadas += 1
	_estado_pesca = "espera"
	_t = 99.0
	get_tree().create_timer(1.2).timeout.connect(_nueva_lanzada)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo:
		if (ev as InputEventKey).keycode == KEY_SPACE and juego == "pesca":
			_tirar()
			get_viewport().set_input_as_handled()
		elif (ev as InputEventKey).keycode == KEY_ESCAPE:
			queue_free()
			get_viewport().set_input_as_handled()

# ------------------------------------------------------------- KARTING

var _kp := Vector2.ZERO
var _kr := 0.0
var _kv := 0.0
var _vueltas := 0
var _crono := 0.0
var _ultimo_lado := 0
var _empezado := false
var _fin_kart := false
const KART_VEL := 260.0

var _pista: Control

func _kart_empezar() -> void:
	## La pista se dibuja en su propia capa: el `_draw` del nodo padre queda
	## debajo del fondo (los hijos se pintan encima) y no se veía nada.
	_pista = Control.new()
	_pista.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pista.draw.connect(_dibujar_pista)
	_zona.add_child(_pista)
	_kp = Vector2(0, 0)
	_aviso.text = "Flechas o WASD. Tres vueltas al óvalo. ¡Que no se te vaya del asfalto!"

func _centro() -> Vector2:
	return _zona.size * 0.5

func _radios() -> Vector2:
	return Vector2(_zona.size.x * 0.38, _zona.size.y * 0.36)

## Distancia «normalizada» al eje del óvalo: 1 = sobre la línea central.
func _en_pista(p: Vector2) -> bool:
	var r := _radios()
	var q := Vector2(p.x / r.x, p.y / r.y).length()
	return q > 0.72 and q < 1.28

func _kart(delta: float) -> void:
	if _kp == Vector2.ZERO:
		var r := _radios()
		_kp = Vector2(0, r.y)
		_kr = PI
	if _fin_kart:
		return
	var x := float(Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
	var y := float(Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S))
	if y != 0.0:
		_empezado = true
	var tope := KART_VEL if _en_pista(_kp) else KART_VEL * 0.35
	_kv = clampf(_kv + y * 320.0 * delta, -80.0, tope)
	if y == 0.0:
		_kv = move_toward(_kv, 0.0, 140.0 * delta)
	if _kv > tope:
		_kv = move_toward(_kv, tope, 400.0 * delta)
	_kr += x * 2.6 * delta * clampf(absf(_kv) / 120.0, 0.0, 1.0)
	_kp += Vector2(cos(_kr), sin(_kr)) * _kv * delta
	if _empezado:
		_crono += delta
	## Vuelta: cruzar la meta (abajo, x > 0 → x < 0 yendo hacia la izquierda).
	var lado := 1 if _kp.x > 0.0 else -1
	if _kp.y > 0.0 and lado != _ultimo_lado and _ultimo_lado == 1 and lado == -1:
		_vueltas += 1
	_ultimo_lado = lado
	_titulo.text = "🏎️ Karting · vuelta %d de 3 · %.1f s · récord: %s" % [mini(_vueltas + 1, 3), _crono, ("%.1f s" % records["karting"]) if float(records["karting"]) > 0.0 else "—"]
	if _vueltas >= 3:
		_fin_kart = true
		var mejor := float(records["karting"])
		if mejor <= 0.0 or _crono < mejor:
			records["karting"] = _crono
			_aviso.text = "¡Nuevo récord del circuito: %.1f s!" % _crono
		else:
			_aviso.text = "Tiempo: %.1f s (récord %.1f s)." % [_crono, mejor]

func _dibujar_pista() -> void:
	if _pista == null:
		return
	var c := _centro()
	var r := _radios()
	var pts_ext := PackedVector2Array()
	var pts_int := PackedVector2Array()
	for k in 65:
		var a := TAU * float(k) / 64.0
		pts_ext.append(c + Vector2(cos(a) * r.x * 1.28, sin(a) * r.y * 1.28))
		pts_int.append(c + Vector2(cos(a) * r.x * 0.72, sin(a) * r.y * 0.72))
	_pista.draw_colored_polygon(pts_ext, Color(0.25, 0.25, 0.27))
	_pista.draw_colored_polygon(pts_int, Color(0.2, 0.42, 0.22))
	_pista.draw_polyline(pts_ext, Color(0.9, 0.2, 0.2), 4.0)
	_pista.draw_polyline(pts_int, Color(0.95, 0.95, 0.95), 4.0)
	_pista.draw_line(c + Vector2(0, r.y * 0.72), c + Vector2(0, r.y * 1.28), Color.WHITE, 6.0)
	var kp := c + _kp
	var dir := Vector2(cos(_kr), sin(_kr))
	var lat := Vector2(-dir.y, dir.x)
	_pista.draw_colored_polygon(PackedVector2Array([kp + dir * 14.0, kp - dir * 10.0 + lat * 8.0, kp - dir * 10.0 - lat * 8.0]), Color(1.0, 0.8, 0.1))
