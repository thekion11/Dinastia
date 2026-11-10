class_name EscenaFestejo
extends Control
## LA ESCENA 2D DE UN FESTEJO DE TÍTULO (10-11). Dibujada con formas (sin texturas nuevas: barata en móvil y equipos modestos), con los
## colores del club. Modos (`TipoTitulo`): escenario, palco, fuegos, sobrio, foto, manteo, champan, desfile, pasillo.
## Los jugadores son figuras simples (cabeza, cuerpo con la camiseta del club y brazos) que se animan con el tiempo: saltan, levantan la
## copa, aplauden. El confeti es una lista corta de papelitos que caen (≤ 90); los fuegos, rayos que se abren. Solo se anima mientras se ve.

const N_CONFETI := 90
var modo := "escenario"
var c1 := Color("2b6b45")
var c2 := Color.WHITE
var rival1 := Color("8a1c1c")
var rival2 := Color.WHITE
var _t := 0.0
var _confeti: Array = []   ## [pos, vel, color, giro]
var _grada: PackedVector2Array = PackedVector2Array()   ## puntos de público (en fracción del ancho/alto), fijos

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(760, 330)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 260:
		_grada.append(Vector2(rng.randf(), rng.randf()))

## Colores del club (y del rival, para el pasillo).
func colores(club: Club, rival: Club = null) -> void:
	c1 = Color(club.color1)
	c2 = Color(club.color2)
	if rival != null:
		rival1 = Color(rival.color1)
		rival2 = Color(rival.color2)

func poner(m: String) -> void:
	modo = m
	_t = 0.0
	_confeti.clear()
	queue_redraw()

func con_confeti() -> bool:
	return modo in ["escenario", "palco", "fuegos", "foto", "desfile"]

func _process(d: float) -> void:
	if not is_visible_in_tree():
		return
	_t += d
	if con_confeti():
		_mover_confeti(d)
	queue_redraw()

func _mover_confeti(d: float) -> void:
	var paleta := [c1, c2, Tema.ORO, Color.WHITE]
	while _confeti.size() < N_CONFETI:
		_confeti.append([Vector2(randf() * size.x, -randf() * size.y * 0.6), Vector2(randf_range(-20, 20), randf_range(50, 110)),
			paleta[randi() % paleta.size()], randf() * TAU])
	for p: Array in _confeti:
		p[0] = (p[0] as Vector2) + (p[1] as Vector2) * d + Vector2(sin(_t * 3.0 + float(p[3])) * 18.0 * d, 0)
		p[3] = float(p[3]) + d * 4.0
		if (p[0] as Vector2).y > size.y:
			p[0] = Vector2(randf() * size.x, -8.0)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if modo == "champan":
		_vestuario(w, h)
	elif modo == "desfile":
		_calle(w, h)
	else:
		_estadio(w, h)
	match modo:
		"escenario", "fuegos": _escenario(w, h)
		"palco": _palco(w, h)
		"sobrio": _sobrio(w, h)
		"foto": _foto(w, h)
		"manteo": _manteo(w, h)
		"champan": _champan(w, h)
		"desfile": _desfile(w, h)
		"pasillo": _pasillo(w, h)
	if modo == "fuegos":
		_fuegos(w, h)
	if con_confeti():
		for p: Array in _confeti:
			var q := p[0] as Vector2
			var a := float(p[3])
			draw_rect(Rect2(q, Vector2(6.0 * absf(cos(a)) + 1.0, 4.0)), p[2] as Color)

## ---- FONDOS ----
func _estadio(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("0b1222"))
	var tope := h * 0.18
	var base := h * 0.58
	draw_rect(Rect2(0, tope, w, base - tope), Color("18213a"))
	for i in _grada.size():   ## el público: puntos con los colores del club que saltan
		var g := _grada[i]
		var salto := absf(sin(_t * 5.0 + float(i))) * 3.0 if modo != "pasillo" else 0.0
		var pos := Vector2(g.x * w, tope + 6.0 + g.y * (base - tope - 12.0) - salto)
		draw_circle(pos, 2.6, c1 if i % 3 != 0 else c2)
	for k in 4:   ## focos
		var x := w * (0.12 + 0.25 * k)
		draw_circle(Vector2(x, tope * 0.45), 7.0, Color(1, 1, 0.85, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, tope * 0.45), Vector2(x + 6, tope * 0.45), Vector2(x + 70, h), Vector2(x - 70, h)]), Color(1, 1, 0.85, 0.035))
	for s in 8:   ## el césped a franjas
		draw_rect(Rect2(s * w / 8.0, base, w / 8.0 + 1.0, h - base), Color("2f7a3a") if s % 2 == 0 else Color("2a6e34"))

func _vestuario(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("1c2333"))
	for i in 9:   ## taquillas con dorsal
		var r := Rect2(20 + i * (w - 40) / 9.0, h * 0.08, (w - 40) / 9.0 - 8.0, h * 0.5)
		draw_rect(r, c1.darkened(0.35))
		draw_rect(Rect2(r.position + Vector2(6, 10), Vector2(r.size.x - 12, 26)), c2.darkened(0.1))
		draw_string(get_theme_default_font(), r.position + Vector2(r.size.x * 0.5 - 8, 30), str(i + 2), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, c1.darkened(0.4))
	draw_rect(Rect2(0, h * 0.62, w, h * 0.38), Color("3a3f4a"))
	draw_rect(Rect2(0, h * 0.6, w, 10), Color("6b4e2e"))   ## el banco

func _calle(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("f2a65a").lerp(Color("2a3a6a"), 0.35))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var x := 0.0
	while x < w:   ## siluetas de edificios
		var ancho := rng.randf_range(40, 90)
		var alto := rng.randf_range(h * 0.2, h * 0.5)
		draw_rect(Rect2(x, h * 0.62 - alto, ancho - 4, alto), Color("2b3046"))
		x += ancho
	draw_rect(Rect2(0, h * 0.62, w, h * 0.38), Color("3b3b42"))
	for i in 40:   ## la gente a los lados, con banderas
		var px := fmod(i * 37.0, w)
		draw_circle(Vector2(px, h * 0.64 - absf(sin(_t * 6 + i)) * 4.0), 4.0, c1 if i % 2 == 0 else c2)
		draw_circle(Vector2(fmod(px + 17.0, w), h * 0.96 - absf(sin(_t * 5 + i)) * 4.0), 4.0, c2 if i % 2 == 0 else c1)

## ---- ESCENAS ----
func _escenario(w: float, h: float) -> void:
	var cx := w * 0.5
	var base := h * 0.82
	draw_rect(Rect2(cx - 190, base - 26, 380, 26), Color("1a1d26"))   ## la tarima
	draw_rect(Rect2(cx - 190, base - 30, 380, 5), Tema.ORO)
	draw_string(get_theme_default_font(), Vector2(cx - 60, base - 8), "CAMPEONES", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Tema.ORO)
	for i in 9:
		var dx := (i - 4) * 40.0
		var salto := absf(sin(_t * 4.0 + i * 0.7)) * 10.0
		_figura(Vector2(cx + dx, base - 30 - salto), 1.0, c1, c2, true)
	var alto := 40.0 + sin(_t * 2.0) * 6.0   ## el capitán, en medio, sube y baja la copa
	_copa(Vector2(cx, base - 30 - 70 - alto), 1.2)

func _palco(w: float, h: float) -> void:
	var y := h * 0.5
	draw_rect(Rect2(w * 0.18, y - 6, w * 0.64, 70), Color("232a3c"))   ## el palco
	draw_rect(Rect2(w * 0.18, y + 10, w * 0.64, 6), Color("c8ccd6"))   ## la baranda
	for i in 8:
		var x := w * 0.24 + i * w * 0.075
		var entregado := _t > 0.6 + i * 0.5   ## las medallas se cuelgan de una en una
		_figura(Vector2(x, y + 8), 0.9, c1, c2, entregado and i == 3)
		if entregado:
			draw_circle(Vector2(x, y - 16), 5.0, Tema.ORO)
			draw_line(Vector2(x - 5, y - 30), Vector2(x, y - 20), Color("b52a2a"), 2.0)
			draw_line(Vector2(x + 5, y - 30), Vector2(x, y - 20), Color("b52a2a"), 2.0)
	_figura(Vector2(w * 0.2, y + 8), 0.9, Color("2c2f38"), Color("e0e0e0"), false)   ## el dirigente que entrega
	if _t > 4.5:
		_copa(Vector2(w * 0.24 + 3 * w * 0.075, y - 92 - sin(_t * 2.0) * 5.0), 1.0)

func _sobrio(w: float, h: float) -> void:
	var c := Vector2(w * 0.5, h * 0.78)
	draw_arc(c, 80, 0, TAU, 48, Color(1, 1, 1, 0.5), 2.0)   ## el círculo central
	for i in 11:   ## el corro abrazado, que se balancea
		var a := TAU * i / 11.0 + sin(_t * 1.5) * 0.05
		_figura(c + Vector2(cos(a) * 58, sin(a) * 18 - 6), 0.9, c1, c2, false)

func _foto(w: float, h: float) -> void:
	var cx := w * 0.5
	var flash := maxf(0.0, 1.0 - fmod(_t, 3.0) * 3.0)
	for fila in 2:   ## dos filas: de pie detrás y en cuclillas delante
		for i in 7:
			var pos := Vector2(cx + (i - 3) * 52.0 + fila * 26.0 - 13.0, h * (0.66 if fila == 0 else 0.86))
			_figura(pos, 0.95 + fila * 0.1, c1, c2, false)
	_copa(Vector2(cx, h * 0.62), 1.1)
	draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, flash * 0.7))   ## el flash

func _manteo(w: float, h: float) -> void:
	var cx := w * 0.5
	var base := h * 0.86
	for i in 10:
		var a := TAU * i / 10.0
		_figura(Vector2(cx + cos(a) * 90, base + sin(a) * 14), 1.0, c1, c2, true)
	var vuelo := absf(sin(_t * 2.4)) * h * 0.42   ## el DT, por los aires
	var dt := Vector2(cx, base - 70 - vuelo)
	_figura(dt, 1.0, Color("20232c"), Color("f0f0f0"), true, (_t * 2.4))

func _champan(w: float, h: float) -> void:
	for i in 8:
		var pos := Vector2(60 + i * (w - 120) / 7.0, h * 0.92)
		_figura(pos, 1.0, c1, c2, i % 2 == 0)
		if i % 2 == 0:   ## botella y chorro
			var tapon := pos + Vector2(14, -78)
			draw_line(pos + Vector2(6, -60), tapon, Color("2e5e2e"), 6.0)
			for k in 7:
				var f := fmod(_t * 1.6 + k / 7.0, 1.0)
				var gota := tapon + Vector2(f * 70.0 * (1 if i % 4 == 0 else -1), -f * 90.0 + f * f * 120.0)
				draw_circle(gota, 3.0 + (1.0 - f) * 3.0, Color(1, 0.92, 0.6, 1.0 - f))

func _desfile(w: float, h: float) -> void:
	var x := fmod(_t * 60.0 + w * 0.55, w + 360.0) - 300.0   ## el bus cruza la calle sin parar
	var y := h * 0.8
	draw_rect(Rect2(x, y - 60, 280, 60), c1)
	draw_rect(Rect2(x, y - 70, 280, 12), c2)
	draw_string(get_theme_default_font(), Vector2(x + 70, y - 22), "CAMPEONES", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, c2)
	for r in [40.0, 230.0]:
		draw_circle(Vector2(x + r, y + 2), 16, Color("15161a"))
	for i in 7:   ## en el piso de arriba, descubierto
		_figura(Vector2(x + 25 + i * 38, y - 70), 0.85, c1.lightened(0.15), c2, true)
	_copa(Vector2(x + 140, y - 160 - sin(_t * 3.0) * 6.0), 0.9)

func _pasillo(w: float, h: float) -> void:
	var y := h * 0.86
	for i in 7:   ## el rival, en dos filas, aplaude
		var dx := 90 + i * (w - 180) / 6.0
		_figura(Vector2(dx, y - 70), 0.9, rival1, rival2, sin(_t * 9.0 + i) > 0.0)
		_figura(Vector2(dx, y + 10), 0.9, rival1, rival2, sin(_t * 9.0 + i + 1.0) > 0.0)
	for i in 6:   ## el campeón pasa por el medio
		var px := fmod(_t * 70.0 + i * 46.0, w + 80.0) - 40.0
		_figura(Vector2(px, y - 30), 0.95, c1, c2, false)

func _fuegos(w: float, h: float) -> void:
	for k in 4:
		var f := fmod(_t * 0.6 + k * 0.27, 1.0)
		var centro := Vector2(w * (0.15 + 0.23 * k), h * (0.12 + 0.08 * (k % 2)))
		var col: Color = [Tema.ORO, c1.lightened(0.3), c2, Color("ff6a6a")][k]
		for r in 14:
			var a := TAU * r / 14.0
			draw_line(centro + Vector2(cos(a), sin(a)) * f * 45.0, centro + Vector2(cos(a), sin(a)) * f * 95.0, Color(col, 1.0 - f), 3.0)

## ---- PIEZAS ----
## Una figura: piernas, cuerpo con la camiseta (c1) y una franja (c2), cabeza y brazos (arriba si celebra).
func _figura(pie: Vector2, e: float, cam: Color, franja: Color, arriba: bool, giro := 0.0) -> void:
	var piel := Color("e0b48c")
	var t := Transform2D(sin(giro) * 0.4 if giro != 0.0 else 0.0, pie)
	draw_set_transform_matrix(t)
	draw_line(Vector2(-5, 0) * e, Vector2(-4, -22) * e, Color("1b1b1f"), 5.0 * e)
	draw_line(Vector2(5, 0) * e, Vector2(4, -22) * e, Color("1b1b1f"), 5.0 * e)
	draw_rect(Rect2(Vector2(-11, -50) * e, Vector2(22, 30) * e), cam)
	draw_rect(Rect2(Vector2(-11, -40) * e, Vector2(22, 5) * e), franja)
	var hombro_i := Vector2(-11, -46) * e
	var hombro_d := Vector2(11, -46) * e
	var mano := Vector2(0, -26) * e if arriba else Vector2(0, 22) * e
	draw_line(hombro_i, hombro_i + Vector2(-6 * e, mano.y), piel, 4.0 * e)
	draw_line(hombro_d, hombro_d + Vector2(6 * e, mano.y), piel, 4.0 * e)
	draw_circle(Vector2(0, -60) * e, 9.0 * e, piel)
	draw_set_transform_matrix(Transform2D.IDENTITY)

## Una copa dorada sencilla (asas, cáliz, pie).
func _copa(c: Vector2, e: float) -> void:
	var oro := Tema.ORO
	draw_colored_polygon(PackedVector2Array([c + Vector2(-20, -30) * e, c + Vector2(20, -30) * e, c + Vector2(10, 0) * e, c + Vector2(-10, 0) * e]), oro)
	draw_arc(c + Vector2(-20, -20) * e, 9 * e, PI * 0.5, PI * 1.5, 12, oro, 3.0 * e)
	draw_arc(c + Vector2(20, -20) * e, 9 * e, -PI * 0.5, PI * 0.5, 12, oro, 3.0 * e)
	draw_rect(Rect2(c + Vector2(-3, 0) * e, Vector2(6, 12) * e), oro.darkened(0.2))
	draw_rect(Rect2(c + Vector2(-12, 12) * e, Vector2(24, 7) * e), oro.darkened(0.35))
	draw_circle(c + Vector2(-8, -22) * e, 3.0 * e, Color(1, 1, 1, 0.6))
