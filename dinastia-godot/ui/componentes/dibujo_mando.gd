class_name DibujoMando
extends Control
## EL MANDO DIBUJADO de la pantalla de controles (14-10-2026, pedido: «que en
## el menú esté ejemplificado cómo se ven los controles y qué parte del control
## es cada una»). Dibuja un mando de PlayStation, uno de Xbox o un teclado, con
## una etiqueta y su línea para cada botón diciendo qué hace en la sección que
## se está mirando, y hace latir en dorado los botones de la combinación que
## está seleccionada.

var dispositivo := "xbox"
## pieza ("A", "LB", "LS"…) -> lo que hace.
var etiquetas := {}
## Las piezas de la combinación seleccionada (se iluminan).
var iluminadas: Array = []
## Teclas iluminadas (modo teclado).
var teclas_iluminadas: Array = []
var _fuente: Font

var _giratorio: MandoGiratorio

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_fuente = ThemeDB.fallback_font
	## El mando de PlayStation y de Xbox es 3D y se gira (`MandoGiratorio`); aquí
	## queda el teclado, que se dibuja en plano.
	_giratorio = MandoGiratorio.new()
	_giratorio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_giratorio)

func _process(_d: float) -> void:
	if _giratorio != null:
		_giratorio.visible = dispositivo != "teclado"
		_giratorio.dispositivo = dispositivo
		_giratorio.etiquetas = etiquetas
		_giratorio.iluminadas = iluminadas
	if dispositivo == "teclado" and (not teclas_iluminadas.is_empty() or not iluminadas.is_empty()):
		queue_redraw()

func _draw() -> void:
	## El mando (PlayStation o Xbox) es 3D: lo dibuja `MandoGiratorio`.
	if dispositivo == "teclado":
		_dibujar_teclado()

func _cortar(txt: String, tam: int, ancho: float) -> String:
	if ancho <= 20.0:
		return ""
	if _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
		return txt
	var t := txt
	while t.length() > 3 and _fuente.get_string_size(t + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
		t = t.substr(0, t.length() - 1)
	return t + "…"

func _caja(r: Rect2, col: Color, radio: float, borde := Color(0, 0, 0, 0)) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(radio))
	if borde.a > 0.0:
		sb.border_color = borde
		sb.set_border_width_all(2)
	draw_style_box(sb, r)

func _texto_centrado(c: Vector2, txt: String, tam: int, col: Color) -> void:
	var w := _fuente.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam)
	draw_string(_fuente, c + Vector2(-w.x * 0.5, tam * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

# ------------------------------------------------------------------ teclado

const FILAS_TECLADO := [
	[[KEY_ESCAPE, 1.0], [KEY_F1, 1.0], [KEY_F2, 1.0], [KEY_F3, 1.0], [KEY_F4, 1.0]],
	[[KEY_Q, 1.0], [KEY_W, 1.0], [KEY_E, 1.0], [KEY_R, 1.0], [KEY_T, 1.0], [KEY_Y, 1.0], [KEY_U, 1.0], [KEY_I, 1.0], [KEY_O, 1.0], [KEY_P, 1.0]],
	[[KEY_A, 1.0], [KEY_S, 1.0], [KEY_D, 1.0], [KEY_F, 1.0], [KEY_G, 1.0], [KEY_H, 1.0], [KEY_J, 1.0], [KEY_K, 1.0], [KEY_L, 1.0]],
	[[KEY_SHIFT, 1.6], [KEY_Z, 1.0], [KEY_X, 1.0], [KEY_C, 1.0], [KEY_V, 1.0], [KEY_B, 1.0], [KEY_N, 1.0], [KEY_M, 1.0]],
	[[KEY_CTRL, 1.4], [KEY_SPACE, 4.6]],
]
const NUMPAD := [[KEY_KP_8, Vector2(1, 0)], [KEY_KP_4, Vector2(0, 1)], [KEY_KP_5, Vector2(1, 1)], [KEY_KP_6, Vector2(2, 1)], [KEY_KP_2, Vector2(1, 2)]]

func _dibujar_teclado() -> void:
	var lado := minf((size.x - 10.0) / 14.0, (size.y * 0.55) / 6.0)
	var origen := Vector2((size.x - lado * 14.0) * 0.5, 14.0)
	var latido := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
	for fi in FILAS_TECLADO.size():
		var x := origen.x + float(fi) * lado * 0.25
		for tecla: Array in FILAS_TECLADO[fi]:
			var ancho := lado * float(tecla[1])
			_tecla(Rect2(Vector2(x, origen.y + float(fi) * lado * 1.1), Vector2(ancho - 4.0, lado - 4.0)), int(tecla[0]), latido)
			x += ancho
	## El teclado numérico (las filigranas), a la derecha.
	var o2 := Vector2(origen.x + lado * 11.3, origen.y + lado * 1.1)
	for t: Array in NUMPAD:
		var v: Vector2 = t[1]
		_tecla(Rect2(o2 + v * lado, Vector2(lado - 4.0, lado - 4.0)), int(t[0]), latido)
	_texto_centrado(o2 + Vector2(lado * 1.5, lado * 3.4), Idiomas.t("Filigranas"), 11, Color(1, 1, 1, 0.6))
	## La leyenda: cada tecla de la sección y lo que hace (las elegidas, en dorado).
	var y := origen.y + lado * 6.0 + 10.0
	var claves: Array = etiquetas.keys()
	var col := 0
	for k: String in claves:
		var kc := int(k)
		if kc == 0:
			continue
		var activa := teclas_iluminadas.has(kc)
		var nombre := OS.get_keycode_string(kc as Key).replace("Kp ", "Num ").replace("Escape", "Esc").replace("Space", "Espacio")
		var x := 10.0 + float(col) * (size.x * 0.5)
		draw_string(_fuente, Vector2(x, y), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffd23f") if activa else Color("c9a227"))
		draw_string(_fuente, Vector2(x + 62.0, y), _cortar(String(etiquetas[k]), 12, size.x * 0.5 - 72.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if activa else Color(1, 1, 1, 0.75))
		col += 1
		if col == 2:
			col = 0
			y += 18.0
		if y > size.y - 6.0:
			break

func _tecla(r: Rect2, k: int, latido: float) -> void:
	var activa := teclas_iluminadas.has(k)
	var asignada := etiquetas.has(str(k))
	var fondo := Color("2a3a30") if asignada else Color("1b221d")
	_caja(r, fondo, 5.0, Color(1, 1, 1, 0.12))
	if activa:
		_caja(r.grow(2.0), Color(1.0, 0.82, 0.25, 0.25 * latido), 6.0, Color(1.0, 0.82, 0.25, 0.9 * latido))
	var nombre := OS.get_keycode_string(k as Key).replace("Kp ", "").replace("Escape", "Esc").replace("Space", "Espacio")
	_texto_centrado(r.get_center() + Vector2(0, -5), nombre, 11, Color("ffd23f") if activa else Color(1, 1, 1, 0.85))
	if asignada:
		var que := _cortar(String(etiquetas[str(k)]), 9, r.size.x - 4.0)
		_texto_centrado(r.get_center() + Vector2(0, 10), que, 9, Color(0.75, 0.9, 0.8, 0.9))
