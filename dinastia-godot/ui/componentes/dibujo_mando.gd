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

## Dónde está cada pieza en el mando (coordenadas de un dibujo de 300 x 200).
const POS_PS := {"LT": Vector2(62, 14), "LB": Vector2(62, 34), "RT": Vector2(238, 14), "RB": Vector2(238, 34),
	"DPAD": Vector2(70, 86), "Y": Vector2(230, 64), "B": Vector2(254, 88), "A": Vector2(230, 112), "X": Vector2(206, 88),
	"LS": Vector2(112, 138), "RS": Vector2(188, 138), "BACK": Vector2(104, 58), "START": Vector2(196, 58)}
const POS_XBOX := {"LT": Vector2(62, 14), "LB": Vector2(62, 34), "RT": Vector2(238, 14), "RB": Vector2(238, 34),
	"LS": Vector2(78, 84), "DPAD": Vector2(116, 134), "RS": Vector2(184, 134), "Y": Vector2(226, 62), "B": Vector2(250, 86),
	"A": Vector2(226, 110), "X": Vector2(202, 86), "BACK": Vector2(128, 72), "START": Vector2(172, 72)}
## Qué lado ocupa cada etiqueta.
const IZQ := ["LT", "LB", "DPAD", "LS", "BACK"]

const COL_PS := {"A": Color("6ea8ff"), "B": Color("ff6b6b"), "X": Color("f29ad8"), "Y": Color("5fe0b0")}
const COL_XBOX := {"A": Color("5cc85c"), "B": Color("e8504a"), "X": Color("3f8fe8"), "Y": Color("f2c230")}
const SIMBOLO_PS := {"A": "✖", "B": "◯", "X": "▢", "Y": "△"}
const NOMBRE_PIEZA := {
	"ps": {"LT": "L2", "LB": "L1", "RT": "R2", "RB": "R1", "LS": "L3", "RS": "R3", "DPAD": "Cruceta", "BACK": "Crear", "START": "Options"},
	"xbox": {"LT": "LT", "LB": "LB", "RT": "RT", "RB": "RB", "LS": "LS", "RS": "RS", "DPAD": "Cruceta", "BACK": "Vista", "START": "Menú"},
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuente = ThemeDB.fallback_font

func _process(_d: float) -> void:
	if not iluminadas.is_empty() or not teclas_iluminadas.is_empty():
		queue_redraw()

func _draw() -> void:
	if dispositivo == "teclado":
		_dibujar_teclado()
		return
	## El mando, centrado y escalado al hueco.
	var escala := minf((size.x - 200.0) / 300.0, (size.y - 40.0) / 200.0)
	escala = maxf(escala, 0.6)
	var origen := Vector2((size.x - 300.0 * escala) * 0.5, (size.y - 200.0 * escala) * 0.5 + 6.0)
	var tr := func(v: Vector2) -> Vector2: return origen + v * escala
	var ps := dispositivo == "ps"
	var cuerpo := Color("dfe2e8") if ps else Color("3a3f48")
	var borde := Color("ffffff40") if not ps else Color("00000030")
	var oscuro := Color("1e2127") if ps else Color("23262c")
	var pos_t: Dictionary = POS_PS if ps else POS_XBOX
	## Gatillos y bumpers.
	for k: String in ["LT", "RT"]:
		_caja(Rect2(tr.call(pos_t[k] - Vector2(26, 8)), Vector2(52, 16) * escala), oscuro.lightened(0.15), 6 * escala)
	for k: String in ["LB", "RB"]:
		_caja(Rect2(tr.call(pos_t[k] - Vector2(30, 6)), Vector2(60, 12) * escala), oscuro.lightened(0.25), 5 * escala)
	## Cuerpo: un rectángulo redondeado y dos empuñaduras.
	for c: Vector2 in [Vector2(82, 132), Vector2(218, 132)]:
		draw_circle(tr.call(c), 58.0 * escala, borde)
		draw_circle(tr.call(c), 56.0 * escala, cuerpo)
	_caja(Rect2(tr.call(Vector2(36, 40)), Vector2(228, 110) * escala), cuerpo, 40 * escala, borde)
	if ps:
		## El panel táctil y la zona negra del centro.
		_caja(Rect2(tr.call(Vector2(112, 46)), Vector2(76, 44) * escala), oscuro, 8 * escala)
	## Cruceta.
	var dp: Vector2 = tr.call(pos_t["DPAD"])
	draw_rect(Rect2(dp - Vector2(7, 20) * escala, Vector2(14, 40) * escala), oscuro)
	draw_rect(Rect2(dp - Vector2(20, 7) * escala, Vector2(40, 14) * escala), oscuro)
	## Sticks.
	for k: String in ["LS", "RS"]:
		var c2: Vector2 = tr.call(pos_t[k])
		draw_circle(c2, 17.0 * escala, oscuro)
		draw_circle(c2, 12.0 * escala, oscuro.lightened(0.2))
	## Los cuatro botones.
	var cols: Dictionary = COL_PS if ps else COL_XBOX
	for k: String in ["A", "B", "X", "Y"]:
		var c3: Vector2 = tr.call(pos_t[k])
		draw_circle(c3, 11.0 * escala, oscuro)
		var txt := String(SIMBOLO_PS[k]) if ps else k
		_texto_centrado(c3, txt, int(13 * escala), cols[k])
	for k: String in ["BACK", "START"]:
		var c4: Vector2 = tr.call(pos_t[k])
		_caja(Rect2(c4 - Vector2(7, 4) * escala, Vector2(14, 8) * escala), oscuro, 3 * escala)
	## Los botones de la combinación elegida laten en dorado.
	var latido := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
	for k: String in iluminadas:
		if not pos_t.has(k):
			continue
		var c5: Vector2 = tr.call(pos_t[k])
		var r := (20.0 if k in ["LS", "RS", "DPAD"] else (16.0 if k.length() == 1 else 22.0)) * escala
		draw_arc(c5, r + 3.0, 0, TAU, 40, Color(1.0, 0.82, 0.25, 0.9 * latido), 3.0)
		draw_circle(c5, r, Color(1.0, 0.82, 0.25, 0.22 * latido))
	## Etiquetas con su línea.
	var izq: Array = []
	var der: Array = []
	for k: String in pos_t:
		if not etiquetas.has(k):
			continue
		(izq if k in IZQ else der).append(k)
	izq.sort_custom(func(a: String, b: String) -> bool: return pos_t[a].y < pos_t[b].y)
	der.sort_custom(func(a: String, b: String) -> bool: return pos_t[a].y < pos_t[b].y)
	_columna(izq, true, pos_t, tr, escala, origen)
	_columna(der, false, pos_t, tr, escala, origen)

func _columna(lista: Array, izquierda: bool, pos_t: Dictionary, tr: Callable, escala: float, origen: Vector2) -> void:
	if lista.is_empty():
		return
	var paso := minf(52.0, (size.y - 20.0) / float(lista.size()))
	var y0 := (size.y - paso * float(lista.size() - 1)) * 0.5
	var x_borde := origen.x - 6.0 if izquierda else origen.x + 300.0 * escala + 6.0
	var ancho_max := (x_borde - 4.0) if izquierda else (size.x - x_borde - 4.0)
	for i in lista.size():
		var k: String = lista[i]
		var punto: Vector2 = tr.call(pos_t[k])
		var y := y0 + paso * float(i)
		var activa: bool = iluminadas.has(k)
		var col := Color(1.0, 0.82, 0.25) if activa else Color(1, 1, 1, 0.4)
		var codo := Vector2(lerpf(punto.x, x_borde, 0.6), y)
		draw_line(punto, codo, col, 1.3, true)
		draw_line(codo, Vector2(x_borde, y), col, 1.3, true)
		draw_circle(punto, 2.5, col)
		## Dos líneas: el botón (dorado) y lo que hace.
		var nombre := String((NOMBRE_PIEZA[dispositivo] as Dictionary).get(k, k))
		if dispositivo == "ps" and SIMBOLO_PS.has(k):
			nombre = String(SIMBOLO_PS[k])
		var que := _cortar(String(etiquetas[k]), 12, ancho_max)
		var w1 := _fuente.get_string_size(nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var w2 := _fuente.get_string_size(que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var x1 := x_borde - w1 - 2.0 if izquierda else x_borde + 2.0
		var x2 := x_borde - w2 - 2.0 if izquierda else x_borde + 2.0
		draw_string(_fuente, Vector2(x1, y - 2.0), nombre, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("ffd23f") if activa else Color("c9a227"))
		draw_string(_fuente, Vector2(x2, y + 12.0), que, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE if activa else Color(1, 1, 1, 0.8))

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
