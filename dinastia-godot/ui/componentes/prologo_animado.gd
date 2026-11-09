class_name PrologoAnimado
extends EventoPantallaCompleta
## EL PRÓLOGO COMO ANIMACIÓN FIJA (9-11, PDF de la reestructuración «solo club»: «se reemplaza la caminata 3D por una animación predeterminada; el jugador no se mueve; se
## puede saltar tocando las fases de arriba o con el joystick»). SIN vídeo: seis planos DIBUJADOS POR EL MOTOR (como la intro de marca), cada uno con su escena en
## los colores de tu club, un lento acercamiento, un título y una frase que se escribe sola. Se ve al empezar una partida nueva (y al continuar si no llegó a verse).
## Controles: tocar un tramo de la barra de arriba salta a ese plano; Esc, Enter, Espacio, cualquier botón del mando o mover el stick lo salta entero.
## Emite `terminado` al acabar o saltarse (el que lo lanza marca el prólogo como visto).
const SEG_POR_PLANO := 5.5
const PLANOS := [
	{"escena": "estadio", "titulo": "Hoy empieza tu dinastía", "texto": "Un club, una ciudad y todo por construir."},
	{"escena": "vestuario", "titulo": "El vestuario", "texto": "Donde se ganan los partidos antes de jugarlos."},
	{"escena": "tunel", "titulo": "El túnel", "texto": "Por aquí sale el equipo cada partido. Ya se oye la grada."},
	{"escena": "banquillo", "titulo": "El banquillo", "texto": "Desde aquí dirigirás: cambios, órdenes y la charla del descanso."},
	{"escena": "despacho", "titulo": "El despacho del presidente", "texto": "Aquí se firma y aquí se despide. La directiva te mira."},
	{"escena": "oficina", "titulo": "Tu oficina", "texto": "Desde tu PC lo gestionas todo. Es hora de empezar."},
]

var _club: Club
var _i := -1
var _t := 0.0
var _vivo := 0.0
var _escena: Control
var _titulo: Label
var _texto: Label
var _segmentos: Array[Button] = []
var _acabado := false

static func mostrar(pr: Principal) -> PrologoAnimado:
	var v := PrologoAnimado.new()
	v._club = pr.mundo.mi_club()
	v._montar_base(pr)
	v._armar(pr)
	return v

func _armar(pr: Principal) -> void:
	_raiz.get_child(_raiz.get_child_count() - 1).queue_free()   ## el CenterContainer del contenido genérico: aquí no se usa
	_escena = Control.new()
	_escena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_escena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escena.draw.connect(_dibujar)
	_raiz.add_child(_escena)
	## La barra de fases de arriba: un tramo por plano; tocarlo salta a ese plano.
	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_left = 40
	barra.offset_right = -40
	barra.offset_top = 10
	barra.offset_bottom = 30
	barra.add_theme_constant_override("separation", 8)
	_raiz.add_child(barra)
	for k in PLANOS.size():
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 20)
		b.focus_mode = Control.FOCUS_NONE
		var idx := k
		b.pressed.connect(func() -> void: _ir(idx))
		barra.add_child(b)
		_segmentos.append(b)
	var saltar := boton(Idiomas.t("Saltar ▶▶"))
	saltar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	saltar.offset_left = -190
	saltar.offset_top = -100
	saltar.offset_right = -40
	saltar.offset_bottom = -44
	saltar.pressed.connect(_terminar)
	_raiz.add_child(saltar)
	var pie := VBoxContainer.new()
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.offset_left = 90
	pie.offset_right = -230
	pie.offset_top = -190
	pie.offset_bottom = -50
	pie.add_theme_constant_override("separation", 6)
	_raiz.add_child(pie)
	_titulo = etiqueta("", 40, Tema.ORO, false, false)
	pie.add_child(_titulo)
	_texto = etiqueta("", 20, Tema.TEXTO, false)
	pie.add_child(_texto)
	_ir(0)

func _ir(k: int) -> void:
	_i = clampi(k, 0, PLANOS.size() - 1)
	_t = 0.0
	var p: Dictionary = PLANOS[_i]
	_titulo.text = Idiomas.t(String(p["titulo"]))
	_texto.text = Idiomas.t(String(p["texto"]))
	_texto.visible_ratio = 0.0
	for n in _segmentos.size():
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Tema.ORO, 0.95) if n <= _i else Color(1, 1, 1, 0.18)
		sb.set_corner_radius_all(3)
		for estado in ["normal", "hover", "pressed", "focus"]:
			_segmentos[n].add_theme_stylebox_override(estado, sb)
	_escena.scale = Vector2.ONE
	_escena.queue_redraw()

func _process(delta: float) -> void:
	if _acabado or _i < 0:
		return
	_vivo += delta
	_t += delta
	_texto.visible_ratio = clampf(_t / 2.2, 0.0, 1.0)
	## El lento acercamiento de la escena (desde el centro de la pantalla).
	_escena.pivot_offset = _escena.size * 0.5
	_escena.queue_redraw()   ## el haz de luz y el polvo se mueven
	var z := 1.0 + 0.07 * clampf(_t / SEG_POR_PLANO, 0.0, 1.0)
	_escena.scale = Vector2(z, z)
	if _t >= SEG_POR_PLANO:
		if _i >= PLANOS.size() - 1:
			_terminar()
		else:
			_ir(_i + 1)

## Saltarlo entero: Esc / Enter / Espacio, un botón del mando o mover el stick (con un margen al empezar, para no saltarlo por el pulso del stick).
func _input(ev: InputEvent) -> void:
	if _acabado or _vivo < 0.8:
		return
	if (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]) \
			or (ev is InputEventJoypadButton and ev.pressed) \
			or (ev is InputEventJoypadMotion and absf((ev as InputEventJoypadMotion).axis_value) > 0.7):
		get_viewport().set_input_as_handled()
		_terminar()

func _terminar() -> void:
	if _acabado:
		return
	_acabado = true
	terminado.emit()

# ---------------------------------------------------------------- las escenas

func _dibujar() -> void:
	if _i < 0 or _escena == null:
		return
	var w := _escena.size.x
	var h := _escena.size.y
	var c1 := Color(_club.color1) if _club != null else Tema.ACENTO
	var c2 := Color(_club.color2) if _club != null else Tema.ORO
	var oscuro := Color(0.03, 0.06, 0.04)
	## El fondo: un degradado vertical (arriba oscuro, abajo con un toque dorado y del color del club), no un color plano.
	var arriba := c1.lerp(oscuro, 0.9)
	var abajo := c1.lerp(Tema.ORO, 0.16).lerp(oscuro, 0.72)
	_escena.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([arriba, arriba, abajo, abajo]))
	_escena.draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color(0, 0, 0, 0.22))   ## el suelo, más oscuro
	var luz := Color(1, 0.92, 0.7, 0.10)
	_escena.draw_circle(Vector2(w * 0.5, h * 0.4), h * 0.42, luz)
	_escena.draw_circle(Vector2(w * 0.5, h * 0.4), h * 0.26, Color(luz, 0.10))
	## Un haz de luz que cruza despacio y motas de polvo en el aire: la escena respira aunque sea fija.
	var bx := fmod(_vivo * 70.0, w * 1.4) - w * 0.2
	_escena.draw_polygon(PackedVector2Array([Vector2(bx, 0), Vector2(bx + 150, 0), Vector2(bx + 150 - h * 0.3, h * 0.7), Vector2(bx - h * 0.3, h * 0.7)]),
		PackedColorArray([Color(1, 0.95, 0.75, 0.0), Color(1, 0.95, 0.75, 0.0), Color(1, 0.95, 0.75, 0.07), Color(1, 0.95, 0.75, 0.07)]))
	for k in 26:
		var px := fmod(float(k) * 173.0 + _vivo * (8.0 + float(k % 5) * 3.0), w)
		var py := fmod(float(k) * 97.0 - _vivo * (5.0 + float(k % 4) * 2.0) + h, h * 0.66)
		_escena.draw_circle(Vector2(px, py), 1.5 + float(k % 3), Color(1, 0.95, 0.8, 0.10 + 0.04 * float(k % 4)))
	match String(PLANOS[_i]["escena"]):
		"estadio":
			## La grada en arco con sus focos y el escudo del club encima.
			for k in 4:
				var r := h * (0.62 - 0.07 * k)
				_escena.draw_arc(Vector2(w * 0.5, h * 0.78), r * 1.6, PI * 1.07, PI * 1.93, 60, c2.lerp(c1, 0.5 + 0.1 * k), 6.0)
			for fx: float in [0.18, 0.82]:
				_escena.draw_rect(Rect2(w * fx - 4, h * 0.26, 8, h * 0.4), Color(0.7, 0.72, 0.7, 0.9))
				_escena.draw_rect(Rect2(w * fx - 34, h * 0.2, 68, 34), Color(1, 0.95, 0.75, 0.95))
			if _club != null:
				var tex := Escudo.textura(_club, 220)
				_escena.draw_texture_rect(tex, Rect2(w * 0.5 - 110, h * 0.2, 220, 220), false)
		"vestuario":
			for k in 8:
				var x := w * 0.08 + k * (w * 0.84 / 8.0)
				_escena.draw_rect(Rect2(x, h * 0.18, w * 0.84 / 8.0 - 14, h * 0.5), c1.lerp(Color(0.5, 0.35, 0.2), 0.45))
				_escena.draw_rect(Rect2(x + 8, h * 0.22, w * 0.84 / 8.0 - 30, 26), Color(c2, 0.9))
			_escena.draw_rect(Rect2(w * 0.08, h * 0.7, w * 0.84, 22), Color(0.55, 0.38, 0.22))
		"tunel":
			for k in 7:
				var f := 1.0 - 0.13 * k
				var anc := w * 0.62 * f
				var alt := h * 0.8 * f
				_escena.draw_rect(Rect2(w * 0.5 - anc * 0.5, h * 0.62 - alt * 0.95, anc, alt), c1.lerp(oscuro, 0.5 + 0.07 * k), false, 6.0)
			_escena.draw_rect(Rect2(w * 0.5 - 70, h * 0.62 - 150, 140, 150), Color(0.55, 0.85, 0.5, 0.95))   ## la luz del campo al fondo
		"banquillo":
			_escena.draw_rect(Rect2(w * 0.2, h * 0.5, w * 0.6, 26), Color(c2, 0.9))
			for k in 6:
				_escena.draw_circle(Vector2(w * 0.24 + k * (w * 0.52 / 5.0), h * 0.44), 22, Color(0.75, 0.6, 0.45))
				_escena.draw_rect(Rect2(w * 0.24 + k * (w * 0.52 / 5.0) - 22, h * 0.46, 44, 46), c1.lerp(c2, 0.35))
			_escena.draw_rect(Rect2(0, h * 0.7, w, 5), Color(1, 1, 1, 0.5))
		"despacho":
			_escena.draw_rect(Rect2(w * 0.18, h * 0.5, w * 0.64, 28), Color(0.5, 0.33, 0.2))
			_escena.draw_rect(Rect2(w * 0.2, h * 0.52, 16, h * 0.18), Color(0.4, 0.26, 0.16))
			_escena.draw_rect(Rect2(w * 0.78, h * 0.52, 16, h * 0.18), Color(0.4, 0.26, 0.16))
			_escena.draw_rect(Rect2(w * 0.38, h * 0.14, w * 0.24, h * 0.26), Color(0.5, 0.75, 0.9, 0.55))   ## la ventana
			_escena.draw_rect(Rect2(w * 0.36, h * 0.38, w * 0.28, 12), Color(c2, 0.9))
			for k in 3:
				_escena.draw_circle(Vector2(w * (0.3 + 0.2 * k), h * 0.46), 26, Color(0.2, 0.2, 0.25))
		"oficina":
			_escena.draw_rect(Rect2(w * 0.3, h * 0.26, w * 0.4, h * 0.3), Color(0.05, 0.06, 0.08))
			_escena.draw_rect(Rect2(w * 0.3, h * 0.26, w * 0.4, h * 0.3), Color(c2, 0.9), false, 5.0)
			_escena.draw_rect(Rect2(w * 0.32, h * 0.29, w * 0.36, h * 0.24), Color(c1.lerp(Tema.ACENTO, 0.5), 0.55))
			_escena.draw_rect(Rect2(w * 0.46, h * 0.56, w * 0.08, h * 0.08), Color(0.3, 0.3, 0.33))
			_escena.draw_rect(Rect2(w * 0.4, h * 0.64, w * 0.2, 14), Color(0.3, 0.3, 0.33))
			_escena.draw_rect(Rect2(w * 0.18, h * 0.7, w * 0.64, 20), Color(0.5, 0.33, 0.2))
	## La banda oscura de abajo (detrás del título y del texto), con un degradado hacia arriba.
	var y0 := h * 0.74
	_escena.draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.78), Color(0, 0, 0, 0.78)]))
