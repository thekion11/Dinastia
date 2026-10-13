class_name TriviaClub
extends Control
## MINIJUEGO: LA TRIVIA DEL CLUB (7-10-2026; estaba en el plan C7 y nunca se
## hizo). Ocho preguntas sacadas de TU partida -tu plantel, tu estadio, tu
## tabla-, cada una con cuatro opciones y diez segundos. No son preguntas de
## memoria inventadas: la respuesta correcta sale de los datos del mundo en el
## momento de jugar, así que cambian a lo largo de la carrera. Con seis
## aciertos o más, la directiva aprecia que conozcas la casa (+1 de confianza,
## una vez por semana).

signal cerrado

const SEGUNDOS := 10.0
const POSICIONES := {"POR": "portero", "DEF": "defensa", "MED": "centrocampista", "DEL": "delantero"}

static var record := 0
static var _premio_semana := -1

var _mundo: Mundo
var _preguntas: Array = []
var _i := 0
var _aciertos := 0
var _tiempo := 0.0
var _activa := false
var _rotulo: Label
var _pregunta: Label
var _reloj: ProgressBar
var _opciones: VBoxContainer
var _aviso: Label

static func mostrar(padre: Control, mundo: Mundo) -> TriviaClub:
	var n := TriviaClub.new()
	n._mundo = mundo
	n.set_anchors_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	padre.add_child(n)
	n._montar()
	return n

## Las preguntas de un mundo: [{q, opciones: [4 textos], correcta: índice}].
static func preguntas(m: Mundo, rng: RandomNumberGenerator) -> Array:
	var sal: Array = []
	var c := m.mi_club() if m != null else null
	if c == null or c.plantilla.size() < 6:
		return sal
	var pl := c.plantilla.duplicate()
	## 1. El capitán.
	for j: Jugador in pl:
		if j.capitan:
			sal.append(_con_opciones("¿Quién lleva el brazalete de capitán?", j.nombre, _otros_nombres(pl, j, rng), rng))
			break
	## 2. El mejor de la plantilla por media.
	pl.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var mejor: Jugador = pl[0]
	if pl.size() > 1 and (pl[1] as Jugador).ovr < mejor.ovr:
		sal.append(_con_opciones("¿Quién es el jugador con más media del plantel?", mejor.nombre, _otros_nombres(pl, mejor, rng), rng))
	## 3. El dorsal de alguien.
	var j3: Jugador = pl[rng.randi() % pl.size()]
	if j3.dorsal > 0:
		var falsos: Array = []
		while falsos.size() < 3:
			var d := rng.randi_range(1, 35)
			if d != j3.dorsal and not falsos.has(str(d)):
				falsos.append(str(d))
		sal.append(_con_opciones("¿Qué dorsal lleva %s?" % j3.nombre, str(j3.dorsal), falsos, rng))
	## 4. El puesto de alguien.
	var j4: Jugador = pl[rng.randi() % pl.size()]
	var puesto := String(POSICIONES.get(j4.pos, j4.pos))
	var otros_p: Array = []
	for v: String in POSICIONES.values():
		if v != puesto:
			otros_p.append(v)
	sal.append(_con_opciones("¿En qué puesto juega %s?" % j4.nombre, puesto, otros_p, rng))
	## 5. La edad del más joven.
	pl.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.edad < b.edad)
	var joven: Jugador = pl[0]
	if pl.size() > 1 and (pl[1] as Jugador).edad > joven.edad:
		sal.append(_con_opciones("¿Quién es el más joven del plantel?", joven.nombre, _otros_nombres(pl, joven, rng), rng))
	## 6. El aforo del estadio.
	var aforo := c.estadio_aforo
	var falsos6: Array = []
	for f: float in [0.7, 1.25, 1.55]:
		falsos6.append(_miles(int(round(float(aforo) * f / 100.0)) * 100))
	sal.append(_con_opciones("¿Cuántas butacas tiene tu estadio?", _miles(aforo), falsos6, rng))
	## 7. El puesto en la tabla.
	var liga := m.liga_de(c)
	if liga != null and liga.clubes.size() >= 4:
		var t := liga.tabla()
		var puesto_t := 0
		for k in t.size():
			if t[k]["club"] == c:
				puesto_t = k + 1
		var falsos7: Array = []
		var cands: Array = range(1, t.size() + 1)
		cands.shuffle()
		for v in cands:
			if int(v) != puesto_t and falsos7.size() < 3:
				falsos7.append("%dº" % int(v))
		sal.append(_con_opciones("¿En qué puesto va tu club en la liga?", "%dº" % puesto_t, falsos7, rng))
	## 8. El país de un extranjero, si hay.
	for j: Jugador in c.plantilla:
		if j.pais != c.pais and j.pais != "":
			var paises: Array = ["ARG", "BRA", "URU", "ESP", "ITA", "FRA", "GER", "COL", "MEX", "POR", "CHI", "ENG"]
			var falsos8: Array = []
			for p in paises:
				if p != j.pais and falsos8.size() < 3:
					falsos8.append(p)
			sal.append(_con_opciones("¿De qué país es %s?" % j.nombre, j.pais, falsos8, rng))
			break
	return sal

static func _otros_nombres(pl: Array, fuera: Jugador, rng: RandomNumberGenerator) -> Array:
	var otros: Array = []
	var copia := pl.duplicate()
	copia.shuffle()
	for j: Jugador in copia:
		if j != fuera and j.nombre != fuera.nombre and otros.size() < 3:
			otros.append(j.nombre)
	return otros

static func _con_opciones(q: String, buena: String, malas: Array, rng: RandomNumberGenerator) -> Dictionary:
	var ops: Array = [buena]
	for x in malas:
		if ops.size() < 4 and not ops.has(String(x)):
			ops.append(String(x))
	## Barajado con el generador propio (no con `Azar`).
	for k in range(ops.size() - 1, 0, -1):
		var r := rng.randi_range(0, k)
		var tmp = ops[k]
		ops[k] = ops[r]
		ops[r] = tmp
	return {"q": q, "opciones": ops, "correcta": ops.find(buena)}

static func _miles(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _montar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_usec()
	_preguntas = preguntas(_mundo, rng)
	var fondo := ColorRect.new()
	fondo.color = Color(0.06, 0.07, 0.11, 0.97)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(minf(720.0, get_viewport_rect().size.x - 32.0), 0)
	v.add_theme_constant_override("separation", 14)
	centro.add_child(v)
	_rotulo = _lbl("", 15, Color(0.6, 0.8, 1.0))
	v.add_child(_rotulo)
	_pregunta = _lbl("", 26, Color.WHITE)
	_pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_pregunta)
	_reloj = ProgressBar.new()
	_reloj.max_value = SEGUNDOS
	_reloj.show_percentage = false
	_reloj.custom_minimum_size = Vector2(0, 10)
	v.add_child(_reloj)
	_opciones = VBoxContainer.new()
	_opciones.add_theme_constant_override("separation", 8)
	v.add_child(_opciones)
	_aviso = _lbl("", 16, Color(1, 0.9, 0.6))
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_aviso)
	var cerrar := Button.new()
	cerrar.text = "Salir"
	cerrar.pressed.connect(func() -> void:
		cerrado.emit()
		queue_free())
	v.add_child(cerrar)
	if _preguntas.is_empty():
		_pregunta.text = "Hace falta un club con plantel para jugar la trivia."
		return
	_siguiente()

func _lbl(t: String, tam: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", col)
	return l

func _siguiente() -> void:
	for h in _opciones.get_children():
		h.queue_free()
	if _i >= _preguntas.size():
		_fin()
		return
	var pr: Dictionary = _preguntas[_i]
	_rotulo.text = "TRIVIA DEL CLUB  ·  pregunta %d de %d  ·  aciertos: %d  ·  récord: %d" % [_i + 1, _preguntas.size(), _aciertos, record]
	_pregunta.text = String(pr["q"])
	for k in (pr["opciones"] as Array).size():
		var b := Button.new()
		b.text = String(pr["opciones"][k])
		b.custom_minimum_size = Vector2(0, 46)
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(func() -> void: _responder(k))
		_opciones.add_child(b)
	_tiempo = SEGUNDOS
	_activa = true

func _process(delta: float) -> void:
	if not _activa:
		return
	_tiempo -= delta
	_reloj.value = maxf(0.0, _tiempo)
	if _tiempo <= 0.0:
		_responder(-1)

func _responder(k: int) -> void:
	if not _activa:
		return
	_activa = false
	var pr: Dictionary = _preguntas[_i]
	var buena := int(pr["correcta"])
	if k == buena:
		_aciertos += 1
		_aviso.text = "✅ ¡Correcto!"
	else:
		_aviso.text = ("⏱️ Se acabó el tiempo. " if k < 0 else "❌ No. ") + "Era: %s." % String(pr["opciones"][buena])
	_i += 1
	get_tree().create_timer(1.3).timeout.connect(_siguiente)

func _fin() -> void:
	record = maxi(record, _aciertos)
	_rotulo.text = "TRIVIA DEL CLUB  ·  récord: %d" % record
	_pregunta.text = "%d aciertos de %d." % [_aciertos, _preguntas.size()]
	if _aciertos >= 6 and _mundo != null and _mundo.directiva != null:
		var marca := _mundo.anio * 60 + _mundo.semana
		if marca != _premio_semana:
			_premio_semana = marca
			_mundo.directiva.mover_confianza(1, "conoce la casa")
			_aviso.text = "La directiva aprecia que conozcas el club (+1 de confianza)."
