class_name EditorFormacion
extends VBoxContainer
## EL EDITOR DE FORMACIONES PROPIAS (10-11-2026, pedido del dueño; «Editar posición» del Plan de juego del PES 2020). Se abre
## desde la pizarra de Táctica con la formación actual como base. Cada ficha (el puesto y el apellido del titular de esa
## casilla) se ARRASTRA con el ratón o el dedo. Con teclado o mando (auditoría de foco, 10-11): la cruceta ELIGE ficha (la más
## cercana en esa dirección; si no hay ninguna, el foco sale del campo, que no es una trampa), Aceptar la AGARRA, la cruceta la
## mueve y Aceptar (o Atrás) la suelta; Tab también cambia de ficha. El puesto cambia solo según la zona (`FormacionPropia.puesto_de`); el portero no se mueve y siempre quedan al menos
## 3 defensas. «Guardar» la deja en la pizarra con su nombre (★) y la pone en uso; el once no se toca (mismas casillas).

signal cerrado(nombre: String)

const ALTO := 380.0
const RADIO := 17.0
const PASO_TECLA := 2.0

var club: Club
var forma: Dictionary = {}
var sel := 1
var _lienzo: Control
var _aviso: Label
var _nombre: LineEdit
var _arrastra := false
## con teclado o mando: la ficha elegida está agarrada y la cruceta la mueve
var agarrada := false

static func crear(c: Club) -> EditorFormacion:
	var e := EditorFormacion.new()
	e.club = c
	e.forma = FormacionPropia.desde(c.tactica.formacion)
	return e

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	var tit := Label.new()
	tit.text = Idiomas.t("EDITAR POSICIONES")
	tit.add_theme_font_size_override("font_size", 12)
	add_child(tit)
	var ayuda := Label.new()
	ayuda.text = Idiomas.t("Arrastra cada ficha a donde quieras: el puesto cambia solo según la zona. Con mando o teclado: la cruceta elige la ficha, Aceptar la agarra, la cruceta la mueve y Aceptar la suelta.")
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ayuda.add_theme_font_size_override("font_size", 11)
	add_child(ayuda)
	_lienzo = Control.new()
	_lienzo.custom_minimum_size = Vector2(0, ALTO)
	_lienzo.focus_mode = Control.FOCUS_ALL
	_lienzo.mouse_filter = Control.MOUSE_FILTER_STOP
	_lienzo.draw.connect(_dibujar)
	_lienzo.gui_input.connect(_entrada)
	_lienzo.focus_entered.connect(_lienzo.queue_redraw)
	_lienzo.focus_exited.connect(func() -> void:
		agarrada = false
		_lienzo.queue_redraw())
	_lienzo.set_meta("foco_visible", true)   ## dibuja su propio marco de foco (`_dibujar`)
	_lienzo.set_meta("cruceta_propia", func(dir: int) -> bool: return agarrada or _vecina(Vector2(0, dir)) >= 0)   ## `GuardianFoco` no se la quita
	add_child(_lienzo)
	_aviso = Label.new()
	_aviso.add_theme_font_size_override("font_size", 11)
	add_child(_aviso)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	add_child(fila)
	_nombre = LineEdit.new()
	_nombre.placeholder_text = Idiomas.t("Nombre de la formación")
	_nombre.text = club.tactica.formacion.replace(FormacionPropia.PREFIJO, "") if FormacionPropia.es_propia(club.tactica.formacion) else ""
	_nombre.max_length = 24
	_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_nombre)
	for b: Array in [["Guardar", _guardar], ["Restablecer", _restablecer], ["Cancelar", _cancelar]]:
		var bt := Button.new()
		bt.text = Idiomas.t(String(b[0]))
		bt.pressed.connect(b[1])
		fila.add_child(bt)
		bt.focus_neighbor_top = bt.get_path_to(_lienzo)   ## con la cruceta, del campo a «Guardar» y de vuelta (no a la táctica de al lado)
		if b[0] == "Guardar":
			_lienzo.focus_neighbor_bottom = _lienzo.get_path_to(bt)
	_nombre.focus_neighbor_top = _nombre.get_path_to(_lienzo)
	_contar()
	_lienzo.grab_focus.call_deferred()   ## el botón que lo abrió queda desactivado: sin esto, con mando no habría foco

## Casilla (en %) → punto del lienzo, con la misma compresión vertical que `PizarraTactica`.
func _a_lienzo(x: float, y: float) -> Vector2:
	return Vector2(x / 100.0 * _lienzo.size.x, (0.11 + clampf(y / 100.0, 0.0, 1.0) * 0.76) * _lienzo.size.y)

func _a_casilla(p: Vector2) -> Vector2:
	return Vector2(p.x / maxf(_lienzo.size.x, 1.0) * 100.0, (p.y / maxf(_lienzo.size.y, 1.0) - 0.11) / 0.76 * 100.0)

func _dibujar() -> void:
	var w := _lienzo.size.x
	var h := _lienzo.size.y
	_lienzo.draw_rect(Rect2(Vector2.ZERO, _lienzo.size), Color("2f6b3a"))
	var linea := Color(1, 1, 1, 0.35)
	_lienzo.draw_rect(Rect2(Vector2(6, 6), _lienzo.size - Vector2(12, 12)), linea, false, 2.0)
	_lienzo.draw_line(Vector2(6, h * 0.5), Vector2(w - 6, h * 0.5), linea, 2.0)
	_lienzo.draw_arc(Vector2(w * 0.5, h * 0.5), h * 0.11, 0.0, TAU, 32, linea, 2.0)
	_lienzo.draw_rect(Rect2(Vector2(w * 0.25, 6), Vector2(w * 0.5, h * 0.14)), linea, false, 2.0)
	_lienzo.draw_rect(Rect2(Vector2(w * 0.25, h - 6 - h * 0.14), Vector2(w * 0.5, h * 0.14)), linea, false, 2.0)
	var once := club.once()
	var letra := ThemeDB.fallback_font
	var s: Array = forma["s"]
	for i in s.size():
		var c: Array = s[i]
		var p := _a_lienzo(float(c[1]), float(c[2]))
		var col: Color = Tema.POS.get(FormacionPropia.linea_de(String(c[0])), Color.WHITE)
		if i == sel:
			_lienzo.draw_circle(p, RADIO + (7.0 if agarrada else 4.0), Tema.ORO if agarrada else Color(1, 1, 1, 0.85))
		_lienzo.draw_circle(p, RADIO, col)
		_lienzo.draw_string(letra, p + Vector2(-RADIO, 5), String(c[0]), HORIZONTAL_ALIGNMENT_CENTER, RADIO * 2.0, 12, Color.WHITE)
		if i < once.size():
			var ap := (once[i] as Jugador).nombre.get_slice(" ", (once[i] as Jugador).nombre.get_slice_count(" ") - 1)
			_lienzo.draw_string(letra, p + Vector2(-50, RADIO + 13), ap, HORIZONTAL_ALIGNMENT_CENTER, 100, 11, Color(1, 1, 1, 0.9))
	if _lienzo.has_focus():   ## el marco del foco, como el de los botones
		_lienzo.draw_rect(Rect2(Vector2(1.5, 1.5), _lienzo.size - Vector2(3, 3)), Tema.ORO, false, 3.0)

func _ficha_en(p: Vector2) -> int:
	var mejor := -1
	var md := RADIO * 1.6
	var s: Array = forma["s"]
	for i in s.size():
		var d := _a_lienzo(float(s[i][1]), float(s[i][2])).distance_to(p)
		if d < md:
			md = d
			mejor = i
	return mejor

func _entrada(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			var i := _ficha_en((ev as InputEventMouseButton).position)
			if i >= 0:
				sel = i
				_arrastra = true
			_lienzo.grab_focus()
		else:
			_arrastra = false
		_lienzo.queue_redraw()
		_lienzo.accept_event()
	elif ev is InputEventMouseMotion and _arrastra:
		var c := _a_casilla((ev as InputEventMouseMotion).position)
		_mover(c.x, c.y)
		_lienzo.accept_event()
	elif ev.is_action_pressed("ui_accept") or (agarrada and ev.is_action_pressed("ui_cancel")):
		agarrada = not agarrada and ev.is_action_pressed("ui_accept")
		_lienzo.queue_redraw()
		_lienzo.accept_event()
	elif ev.is_action_pressed("ui_focus_next"):
		agarrada = false
		sel = (sel + 1) % (forma["s"] as Array).size()
		if String(forma["s"][sel][0]) == "POR":
			sel = (sel + 1) % (forma["s"] as Array).size()
		_lienzo.queue_redraw()
		_lienzo.accept_event()
	else:
		var d := Vector2.ZERO
		for a: Array in [["ui_left", Vector2(-1, 0)], ["ui_right", Vector2(1, 0)], ["ui_up", Vector2(0, -1)], ["ui_down", Vector2(0, 1)]]:
			if ev.is_action_pressed(String(a[0]), true):
				d = a[1]
		if d == Vector2.ZERO or sel < 0:
			return
		if agarrada:
			var c: Array = forma["s"][sel]
			_mover(float(c[1]) + d.x * PASO_TECLA, float(c[2]) + d.y * PASO_TECLA)
			_lienzo.accept_event()
			return
		var j := _vecina(d)
		if j >= 0:   ## si no hay ficha en esa dirección no se consume: el foco sale del campo
			sel = j
			_lienzo.queue_redraw()
			_lienzo.accept_event()

## La ficha (sin el portero, que no se mueve) más cercana a la elegida en la dirección `d`, primando lo que está en línea; -1 si no hay.
func _vecina(d: Vector2) -> int:
	var s: Array = forma["s"]
	if sel < 0 or sel >= s.size():
		return -1
	var o := Vector2(float(s[sel][1]), float(s[sel][2]))
	var mejor := -1
	var md := INF
	for i in s.size():
		if i == sel or String(s[i][0]) == "POR":
			continue
		var v := Vector2(float(s[i][1]), float(s[i][2])) - o
		var avance := v.dot(d)
		if avance <= 0.5:
			continue
		var coste := avance + 2.0 * absf(v.cross(d))
		if coste < md:
			md = coste
			mejor = i
	return mejor

func _mover(x: float, y: float) -> void:
	var r := FormacionPropia.mover(forma, sel, x, y)
	if r == "portero":
		_aviso.text = Idiomas.t("El portero no se mueve.")
	elif r == "defensas":
		_aviso.text = Idiomas.t("Tienen que quedar al menos 3 defensas.")
	else:
		_contar()
	_lienzo.queue_redraw()

func _contar() -> void:
	_aviso.text = "%d-%d-%d" % [int(forma["DEF"]), int(forma["MED"]), int(forma["DEL"])]

func _guardar() -> void:
	DeshacerTactica.apuntar(club)
	var n := FormacionPropia.guardar(club.tactica, _nombre.text, forma)
	if n == "":
		_aviso.text = Idiomas.t("Ya tienes 6 formaciones propias: borra una para guardar otra.")
		return
	club.tactica.formacion = n
	cerrado.emit(n)

func _restablecer() -> void:
	forma = FormacionPropia.desde(String(forma.get("base", "4-3-3")))
	_contar()
	_lienzo.queue_redraw()

func _cancelar() -> void:
	cerrado.emit("")

## La fila de la pizarra de Táctica: «Editar posiciones» abre el editor debajo; con una formación propia en uso, «Borrar».
## `p` es la pantalla principal (`_lista_tactica`, `_refrescar`).
static func botones(p: Object, c: Club) -> void:
	var lista: Control = p.get("_lista_tactica")
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	lista.add_child(fila)
	var be := Button.new()
	be.text = "✏ " + Idiomas.t("Editar posiciones")
	be.add_theme_font_size_override("font_size", 11)
	fila.add_child(be)
	be.pressed.connect(func() -> void:
		be.disabled = true
		var ed := EditorFormacion.crear(c)
		lista.add_child(ed)
		lista.move_child(ed, fila.get_index() + 1)
		ed.cerrado.connect(func(_n: String) -> void: p.call("_refrescar")))
	if FormacionPropia.es_propia(c.tactica.formacion):
		var bb := Button.new()
		bb.text = "🗑 " + Idiomas.t("Borrar esta formación")
		bb.add_theme_font_size_override("font_size", 11)
		fila.add_child(bb)
		bb.pressed.connect(func() -> void:
			DeshacerTactica.apuntar(c)
			FormacionPropia.borrar(c.tactica, c.tactica.formacion)
			c.limpiar_once()
			p.call("_refrescar"))
