class_name PrologoArte
extends RefCounted
## EL ARTE FINAL DEL PRÓLOGO (orden del dueño, 9-11; hecho el 10-11). Las seis ilustraciones de `PrologoAnimado`, DIBUJADAS POR EL MOTOR (sin vídeo
## ni imágenes: pesan 0 bytes y se adaptan a cualquier pantalla) con perspectiva, luz y detalle, en los colores del club: el estadio de noche lleno,
## el vestuario con las camisetas colgadas, el túnel con la luz del campo al fondo, el banquillo mirando al césped, el despacho del presidente con la
## ciudad al atardecer y tu oficina con el PC encendido. `t` es el tiempo vivo (para lo que se mueve: flashes, focos, figuras que caminan).

static func dibujar(ci: CanvasItem, escena: String, w: float, h: float, c1: Color, c2: Color, t: float, club: Club) -> void:
	match escena:
		"estadio": _estadio(ci, w, h, c1, c2, t, club)
		"vestuario": _vestuario(ci, w, h, c1, c2, t, club)
		"tunel": _tunel(ci, w, h, c1, c2, t)
		"banquillo": _banquillo(ci, w, h, c1, c2, t)
		"despacho": _despacho(ci, w, h, c1, c2, t, club)
		"oficina": _oficina(ci, w, h, c1, c2, t, club)

## LO QUE SE MUEVE, encima de la ilustración fija (que se pinta UNA vez por plano en una textura: medido el 10-11, dibujar el público en cada
## cuadro costaba ~1.380 llamadas de dibujo). Aquí solo van unas pocas figuras: flashes de la grada, el equipo que camina por el túnel y el cursor del PC.
static func dibujar_vivo(ci: CanvasItem, escena: String, w: float, h: float, t: float) -> void:
	match escena:
		"estadio":
			for k in 8:
				var fase := fmod(t * 1.3 + k * 0.37, 1.0)
				if fase < 0.08:
					ci.draw_circle(Vector2(fmod(k * 389.0 + t * 31.0, w), h * (0.24 + 0.1 * (k % 3))), 5.0, Color(1, 1, 1, 0.9))
		"tunel":   ## el equipo camina hacia la luz (siluetas a contraluz)
			var boca := Rect2(w * 0.42, h * 0.3, w * 0.16, h * 0.3)
			for k in 4:
				var avance := fmod(t * 0.06 + k * 0.22, 1.0)
				var y := lerpf(h * 1.05, boca.end.y, avance)
				var alto := lerpf(h * 0.55, boca.size.y * 0.55, avance)
				var x := w * 0.5 + (float(k % 2) - 0.5) * lerpf(w * 0.25, boca.size.x * 0.5, avance)
				_figura(ci, Vector2(x, y), alto, Color(0.04, 0.05, 0.06))
		"oficina":
			var m := Rect2(w * 0.3, h * 0.3, w * 0.4, h * 0.3)
			ci.draw_rect(Rect2(m.position.x + m.size.x * 0.56, m.position.y + m.size.y * 0.84, 3, m.size.y * 0.07), Color(1, 1, 1, 0.5 + 0.5 * sin(t * 4.0)))

# ----------------------------------------------------------------- ayudantes

static func _cuad(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cd: Color = Color(0, 0, 0, -1)) -> void:
	var abajo := ca if cd.a < 0.0 else cd
	ci.draw_polygon(PackedVector2Array([a, b, c, d]), PackedColorArray([ca, ca, abajo, abajo]))

## Una sala en perspectiva: suelo, techo, paredes laterales y la pared del fondo (devuelve su rectángulo).
static func _sala(ci: CanvasItem, w: float, h: float, pared: Color, suelo: Color, techo: Color, fondo := Rect2()) -> Rect2:
	var f := fondo if fondo.size != Vector2.ZERO else Rect2(w * 0.3, h * 0.2, w * 0.4, h * 0.42)
	var tl := f.position
	var tr := Vector2(f.end.x, f.position.y)
	var br := f.end
	var bl := Vector2(f.position.x, f.end.y)
	_cuad(ci, Vector2(0, 0), Vector2(w, 0), tr, tl, techo.darkened(0.35), techo)
	_cuad(ci, bl, br, Vector2(w, h), Vector2(0, h), suelo.darkened(0.45), suelo)
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), tl, bl, Vector2(0, h)]), PackedColorArray([pared, pared.darkened(0.3), pared.darkened(0.3), pared]))
	ci.draw_polygon(PackedVector2Array([tr, Vector2(w, 0), Vector2(w, h), br]), PackedColorArray([pared.darkened(0.3), pared, pared, pared.darkened(0.3)]))
	ci.draw_rect(f, pared.darkened(0.2))
	for k in 3:   ## lámparas del techo que se alejan
		var p := Vector2(w * 0.5, h * (0.04 + 0.055 * k))
		var anc := w * (0.16 - 0.04 * k)
		ci.draw_rect(Rect2(p.x - anc * 0.5, p.y, anc, 6.0 - k), Color(1, 0.97, 0.88, 0.9))
		ci.draw_circle(p + Vector2(0, 8), anc * 0.45, Color(1, 0.95, 0.8, 0.05))
	return f

## Un punto de la pared izquierda o derecha a la profundidad `z` (0 = delante, 1 = pared del fondo) y altura relativa `y` (0 = techo, 1 = suelo).
static func _en_pared(w: float, h: float, f: Rect2, izquierda: bool, z: float, y: float) -> Vector2:
	var x_cerca := 0.0 if izquierda else w
	var x_lejos := f.position.x if izquierda else f.end.x
	var arriba := lerpf(0.0, f.position.y, z)
	var abajo := lerpf(h, f.end.y, z)
	return Vector2(lerpf(x_cerca, x_lejos, z), lerpf(arriba, abajo, y))

## Una figura humana en silueta (de pie). `alto` en píxeles, pies en `pie`.
static func _figura(ci: CanvasItem, pie: Vector2, alto: float, cuerpo: Color, cabeza: Color = Color(0, 0, 0, -1)) -> void:
	var ca := cuerpo if cabeza.a < 0.0 else cabeza
	var anc := alto * 0.26
	ci.draw_rect(Rect2(pie.x - anc * 0.42, pie.y - alto * 0.46, anc * 0.36, alto * 0.46), cuerpo.darkened(0.25))
	ci.draw_rect(Rect2(pie.x + anc * 0.06, pie.y - alto * 0.46, anc * 0.36, alto * 0.46), cuerpo.darkened(0.25))
	ci.draw_rect(Rect2(pie.x - anc * 0.5, pie.y - alto * 0.82, anc, alto * 0.4), cuerpo)
	ci.draw_circle(Vector2(pie.x, pie.y - alto * 0.9), alto * 0.085, ca)

static func _camiseta(ci: CanvasItem, centro: Vector2, anc: float, c1: Color, c2: Color, numero: int) -> void:
	ci.draw_rect(Rect2(centro.x - anc * 0.32, centro.y - anc * 0.4, anc * 0.64, anc * 0.8), c1)
	ci.draw_rect(Rect2(centro.x - anc * 0.5, centro.y - anc * 0.4, anc, anc * 0.2), c1)
	ci.draw_rect(Rect2(centro.x - anc * 0.32, centro.y - anc * 0.4, anc * 0.64, anc * 0.06), c2)
	if numero > 0 and anc > 18.0:
		ci.draw_string(ThemeDB.fallback_font, centro + Vector2(-anc * 0.26, anc * 0.22), str(numero), HORIZONTAL_ALIGNMENT_CENTER, anc * 0.52, int(anc * 0.42), c2)

static func _escudo(ci: CanvasItem, club: Club, rect: Rect2) -> void:
	if club != null:
		ci.draw_texture_rect(Escudo.textura(club, int(rect.size.y)), rect, false)

# ----------------------------------------------------------------- escenas

static func _estadio(ci: CanvasItem, w: float, h: float, c1: Color, c2: Color, t: float, club: Club) -> void:
	_cuad(ci, Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.5), Vector2(0, h * 0.5), Color(0.02, 0.03, 0.08), Color(0.08, 0.1, 0.2))
	for k in 40:   ## estrellas
		ci.draw_circle(Vector2(fmod(k * 211.0, w), fmod(k * 67.0, h * 0.25)), 1.2, Color(1, 1, 1, 0.35 + 0.3 * sin(t * 2.0 + k)))
	## Las tres bandejas de la grada, de lejos a cerca, con el público como puntos de color.
	for nivel in 3:
		var y0 := h * (0.2 + 0.1 * nivel)
		var y1 := y0 + h * 0.12
		_cuad(ci, Vector2(-w * 0.05, y0), Vector2(w * 1.05, y0), Vector2(w * 1.05, y1), Vector2(-w * 0.05, y1), Color(0.1, 0.1, 0.13), Color(0.16, 0.16, 0.2))
		var paso := 7.0 + 2.5 * nivel
		var i := 0
		var x := 0.0
		while x < w:
			for fila in 3:
				var r := float(absi(hash(Vector2i(i, fila + nivel * 7))) % 100) / 100.0
				var col := c1 if r < 0.42 else (c2 if r < 0.72 else Color(0.85, 0.8, 0.72))
				ci.draw_circle(Vector2(x, y0 + 8 + fila * (h * 0.035)), 1.6 + nivel * 0.6, col.darkened(0.25 - 0.08 * nivel))
			x += paso
			i += 1
	## El césped en perspectiva, con franjas y líneas.
	var cesped_y := h * 0.56
	_cuad(ci, Vector2(-w * 0.1, cesped_y), Vector2(w * 1.1, cesped_y), Vector2(w * 1.6, h), Vector2(-w * 0.6, h), Color(0.1, 0.32, 0.14), Color(0.16, 0.5, 0.2))
	for k in 6:
		var a := cesped_y + (h - cesped_y) * pow(float(k) / 6.0, 1.5)
		var b := cesped_y + (h - cesped_y) * pow((float(k) + 0.5) / 6.0, 1.5)
		ci.draw_rect(Rect2(0, a, w, b - a), Color(1, 1, 1, 0.035))
	ci.draw_line(Vector2(w * 0.5, cesped_y), Vector2(w * 0.5, h), Color(1, 1, 1, 0.6), 3.0)
	ci.draw_set_transform(Vector2(w * 0.5, h * 0.78), 0.0, Vector2(1.0, 0.28))
	ci.draw_arc(Vector2.ZERO, w * 0.16, 0, TAU, 64, Color(1, 1, 1, 0.6), 7.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	## Las torres de focos con su halo, y los flashes de las cámaras en la grada.
	for fx: float in [0.1, 0.9]:
		ci.draw_rect(Rect2(w * fx - 3, h * 0.04, 6, h * 0.3), Color(0.35, 0.36, 0.4))
		ci.draw_rect(Rect2(w * fx - 40, h * 0.02, 80, 28), Color(1, 0.97, 0.86))
		for r in 4:
			ci.draw_circle(Vector2(w * fx, h * 0.035), 40.0 + r * 34.0, Color(1, 0.95, 0.8, 0.07))
	_escudo(ci, club, Rect2(w * 0.5 - h * 0.13, h * 0.3, h * 0.26, h * 0.26))

static func _vestuario(ci: CanvasItem, w: float, h: float, c1: Color, c2: Color, t: float, club: Club) -> void:
	var f := _sala(ci, w, h, Color(0.2, 0.22, 0.25), Color(0.32, 0.3, 0.28), Color(0.85, 0.85, 0.82))
	ci.draw_rect(Rect2(f.position.x, f.position.y + f.size.y * 0.55, f.size.x, f.size.y * 0.06), c1)   ## franja del club en el fondo
	_escudo(ci, club, Rect2(f.get_center().x - f.size.y * 0.2, f.position.y + f.size.y * 0.08, f.size.y * 0.4, f.size.y * 0.4))
	## Las taquillas de madera con las camisetas colgadas, a los dos lados.
	for izq: bool in [true, false]:
		for k in 5:
			var z0 := 0.08 + 0.18 * k
			var z1 := z0 + 0.16
			var a := _en_pared(w, h, f, izq, z0, 0.18)
			var b := _en_pared(w, h, f, izq, z1, 0.18)
			var c := _en_pared(w, h, f, izq, z1, 0.8)
			var d := _en_pared(w, h, f, izq, z0, 0.8)
			ci.draw_polygon(PackedVector2Array([a, b, c, d]), PackedColorArray([Color(0.42, 0.28, 0.16), Color(0.36, 0.24, 0.14), Color(0.3, 0.2, 0.12), Color(0.36, 0.24, 0.14)]))
			var cen := (a + b + c + d) * 0.25 + Vector2(0, -(d.y - a.y) * 0.08)
			_camiseta(ci, cen, absf(b.x - a.x) * 0.7, c1, c2, k * 2 + (1 if izq else 2) + 4)
		var banco_a := _en_pared(w, h, f, izq, 0.05, 0.86)
		var banco_b := _en_pared(w, h, f, izq, 0.95, 0.86)
		ci.draw_line(banco_a, banco_b, Color(0.6, 0.42, 0.24), 10.0)
	## La pizarra táctica en el centro y un balón en el suelo.
	ci.draw_rect(Rect2(w * 0.42, h * 0.55, w * 0.16, h * 0.18), Color(0.92, 0.94, 0.92))
	ci.draw_rect(Rect2(w * 0.42, h * 0.55, w * 0.16, h * 0.18), Color(0.3, 0.3, 0.3), false, 3.0)
	for k in 5:
		ci.draw_circle(Vector2(w * (0.44 + 0.03 * k), h * (0.6 + 0.02 * (k % 2))), 5, c1)
	ci.draw_line(Vector2(w * 0.45, h * 0.69), Vector2(w * 0.55, h * 0.6), Color(0.8, 0.2, 0.2), 3.0)
	ci.draw_circle(Vector2(w * 0.62, h * 0.86), h * 0.035, Color(0.95, 0.95, 0.95))
	ci.draw_circle(Vector2(w * 0.62, h * 0.86), h * 0.012, Color(0.15, 0.15, 0.15))

static func _tunel(ci: CanvasItem, w: float, h: float, c1: Color, c2: Color, t: float) -> void:
	var boca := Rect2(w * 0.42, h * 0.3, w * 0.16, h * 0.3)
	var f := _sala(ci, w, h, Color(0.16, 0.17, 0.19), Color(0.2, 0.2, 0.22), Color(0.12, 0.12, 0.14), boca)
	## La luz del campo al fondo: el césped, la grada y el resplandor.
	ci.draw_rect(boca, Color(0.85, 0.95, 0.85))
	ci.draw_rect(Rect2(boca.position.x, boca.position.y + boca.size.y * 0.62, boca.size.x, boca.size.y * 0.38), Color(0.3, 0.7, 0.32))
	for k in 30:
		ci.draw_circle(Vector2(boca.position.x + fmod(k * 13.0, boca.size.x), boca.position.y + boca.size.y * (0.3 + 0.08 * (k % 3))), 1.6, c1 if k % 2 == 0 else c2)
	for r in 6:
		ci.draw_rect(boca.grow(10.0 + r * 18.0), Color(1, 1, 0.9, 0.06), false, 18.0)
	## Las franjas del club en las paredes, alejándose.
	for izq: bool in [true, false]:
		ci.draw_line(_en_pared(w, h, f, izq, 0.0, 0.55), _en_pared(w, h, f, izq, 1.0, 0.55), c1, 14.0)
		ci.draw_line(_en_pared(w, h, f, izq, 0.0, 0.6), _en_pared(w, h, f, izq, 1.0, 0.6), c2, 6.0)

static func _banquillo(ci: CanvasItem, w: float, h: float, c1: Color, c2: Color, t: float) -> void:
	_cuad(ci, Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.32), Vector2(0, h * 0.32), Color(0.12, 0.12, 0.16), Color(0.2, 0.2, 0.25))
	for k in 260:   ## la grada de enfrente
		var r := float(absi(hash(k)) % 100) / 100.0
		ci.draw_circle(Vector2(fmod(k * 37.0, w), h * (0.05 + 0.25 * fmod(k * 0.618, 1.0))), 2.4, c1 if r < 0.45 else (c2 if r < 0.75 else Color(0.8, 0.76, 0.7)))
	_cuad(ci, Vector2(0, h * 0.32), Vector2(w, h * 0.32), Vector2(w, h), Vector2(0, h), Color(0.12, 0.36, 0.15), Color(0.18, 0.52, 0.22))
	ci.draw_line(Vector2(0, h * 0.4), Vector2(w, h * 0.4), Color(1, 1, 1, 0.7), 4.0)
	## El entrenador de pie en la línea, y el techo del banquillo (plexiglás) enmarcando la vista.
	_figura(ci, Vector2(w * 0.62, h * 0.62), h * 0.3, Color(0.08, 0.08, 0.1), Color(0.65, 0.5, 0.4))
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.1), Vector2(0, h * 0.16)]), PackedColorArray([Color(0.7, 0.85, 0.95, 0.25), Color(0.7, 0.85, 0.95, 0.25), Color(0.7, 0.85, 0.95, 0.1), Color(0.7, 0.85, 0.95, 0.1)]))
	ci.draw_line(Vector2(0, h * 0.16), Vector2(w, h * 0.1), Color(0.75, 0.75, 0.8), 6.0)
	## La fila de asientos con los suplentes de espaldas.
	ci.draw_rect(Rect2(0, h * 0.76, w, h * 0.24), Color(0.08, 0.08, 0.1))
	for k in 7:
		var x := w * (0.07 + 0.14 * k)
		ci.draw_rect(Rect2(x - w * 0.055, h * 0.74, w * 0.11, h * 0.2), c1.darkened(0.15))
		ci.draw_rect(Rect2(x - w * 0.04, h * 0.72, w * 0.08, h * 0.12), c1.lerp(c2, 0.2))
		ci.draw_circle(Vector2(x, h * 0.69), h * 0.035, Color(0.18, 0.12, 0.08))

static func _despacho(ci: CanvasItem, w: float, h: float, c1: Color, c2: Color, t: float, club: Club) -> void:
	var f := _sala(ci, w, h, Color(0.32, 0.2, 0.12), Color(0.3, 0.12, 0.1), Color(0.7, 0.66, 0.6), Rect2(w * 0.24, h * 0.16, w * 0.52, h * 0.46))
	## El ventanal con la ciudad al atardecer.
	var v := Rect2(f.position.x + f.size.x * 0.08, f.position.y + f.size.y * 0.08, f.size.x * 0.84, f.size.y * 0.66)
	_cuad(ci, v.position, Vector2(v.end.x, v.position.y), v.end, Vector2(v.position.x, v.end.y), Color(0.25, 0.2, 0.45), Color(0.98, 0.58, 0.3))
	ci.draw_circle(Vector2(v.position.x + v.size.x * 0.7, v.end.y - v.size.y * 0.12), v.size.y * 0.16, Color(1, 0.8, 0.45, 0.9))
	var x := v.position.x
	var i := 0
	while x < v.end.x:
		var anc := v.size.x * (0.05 + 0.04 * float(absi(hash(i)) % 3))
		var alto := v.size.y * (0.25 + 0.4 * float(absi(hash(i * 7)) % 10) / 10.0)
		var ed := Rect2(x, v.end.y - alto, minf(anc, v.end.x - x), alto)
		ci.draw_rect(ed, Color(0.1, 0.08, 0.14))
		for vy in int(alto / 14.0):
			if (i + vy) % 3 == 0:
				ci.draw_rect(Rect2(ed.position.x + 4, ed.position.y + 6 + vy * 14, 4, 5), Color(1, 0.85, 0.5, 0.8))
		x += anc + 3.0
		i += 1
	for k in 3:   ## los parteluces del ventanal
		ci.draw_line(Vector2(v.position.x + v.size.x * (0.25 * (k + 1)), v.position.y), Vector2(v.position.x + v.size.x * (0.25 * (k + 1)), v.end.y), Color(0.15, 0.1, 0.06), 5.0)
	ci.draw_rect(v, Color(0.2, 0.13, 0.08), false, 8.0)
	## La vitrina de trofeos en la pared izquierda y la bandera del club en la derecha.
	for k in 3:
		var p := _en_pared(w, h, f, true, 0.3 + 0.22 * k, 0.5)
		var s := lerpf(h * 0.09, h * 0.05, 0.3 + 0.22 * k)
		ci.draw_rect(Rect2(p.x - s * 0.15, p.y - s * 0.2, s * 0.3, s * 0.35), Color(0.85, 0.66, 0.2))
		ci.draw_circle(p + Vector2(0, -s * 0.45), s * 0.32, Color(0.95, 0.78, 0.3))
	var b0 := _en_pared(w, h, f, false, 0.35, 0.15)
	var b1 := _en_pared(w, h, f, false, 0.7, 0.15)
	var b2 := _en_pared(w, h, f, false, 0.7, 0.5)
	var b3 := _en_pared(w, h, f, false, 0.35, 0.5)
	ci.draw_polygon(PackedVector2Array([b0, b1, b2, b3]), PackedColorArray([c1, c1, c1, c1]))
	ci.draw_line((b0 + b3) * 0.5, (b1 + b2) * 0.5, c2, 8.0)
	## La mesa del presidente y su sillón, de espaldas a la ventana.
	ci.draw_rect(Rect2(w * 0.43, h * 0.5, w * 0.14, h * 0.2), Color(0.12, 0.08, 0.06))
	ci.draw_circle(Vector2(w * 0.5, h * 0.48), h * 0.05, Color(0.12, 0.08, 0.06))
	_cuad(ci, Vector2(w * 0.18, h * 0.66), Vector2(w * 0.82, h * 0.66), Vector2(w * 0.9, h * 0.78), Vector2(w * 0.1, h * 0.78), Color(0.45, 0.28, 0.16), Color(0.36, 0.22, 0.12))
	ci.draw_rect(Rect2(w * 0.12, h * 0.78, w * 0.76, h * 0.06), Color(0.28, 0.17, 0.1))
	ci.draw_rect(Rect2(w * 0.3, h * 0.68, w * 0.12, h * 0.02), Color(0.92, 0.9, 0.85))   ## el contrato sobre la mesa
	ci.draw_line(Vector2(w * 0.44, h * 0.685), Vector2(w * 0.5, h * 0.675), Color(0.85, 0.7, 0.2), 4.0)
	_escudo(ci, club, Rect2(w * 0.62, h * 0.665, h * 0.06, h * 0.06))

static func _oficina(ci: CanvasItem, w: float, h: float, c1: Color, c2: Color, t: float, club: Club) -> void:
	var f := _sala(ci, w, h, Color(0.24, 0.27, 0.3), Color(0.26, 0.24, 0.22), Color(0.8, 0.8, 0.78))
	ci.draw_rect(Rect2(f.position.x + f.size.x * 0.06, f.position.y + f.size.y * 0.1, f.size.x * 0.3, f.size.y * 0.4), Color(0.6, 0.78, 0.9))   ## ventana de día
	## La pantalla del PC con el menú del club: cabecera del color del club, tabla y la noticia del día.
	var m := Rect2(w * 0.3, h * 0.3, w * 0.4, h * 0.3)
	ci.draw_rect(m.grow(10), Color(0.08, 0.08, 0.1))
	ci.draw_rect(m, Color(0.05, 0.1, 0.07))
	ci.draw_rect(Rect2(m.position, Vector2(m.size.x, m.size.y * 0.14)), c1.lerp(Tema.ACENTO, 0.3))
	_escudo(ci, club, Rect2(m.position.x + 6, m.position.y + 3, m.size.y * 0.12, m.size.y * 0.12))   ## el escudo en la cabecera del menú
	for k in 7:
		var y := m.position.y + m.size.y * (0.2 + 0.1 * k)
		ci.draw_rect(Rect2(m.end.x - m.size.x * 0.4, y, m.size.x * 0.36, m.size.y * 0.07), Color(1, 1, 1, 0.08 if k % 2 else 0.14))
		ci.draw_rect(Rect2(m.end.x - m.size.x * 0.4, y, m.size.x * 0.03, m.size.y * 0.07), Tema.ORO if k == 0 else Color(1, 1, 1, 0.3))
	ci.draw_rect(Rect2(m.position.x + m.size.x * 0.04, m.position.y + m.size.y * 0.2, m.size.x * 0.5, m.size.y * 0.5), c2.lerp(c1, 0.6).darkened(0.3))
	ci.draw_rect(Rect2(m.position.x + m.size.x * 0.04, m.position.y + m.size.y * 0.74, m.size.x * 0.5, m.size.y * 0.06), Tema.ORO)
	for r in 4:
		ci.draw_rect(m.grow(14.0 + r * 16.0), Color(0.5, 0.9, 0.6, 0.03), false, 16.0)
	## La mesa, el teclado, la lámpara encendida, la taza y la planta.
	ci.draw_rect(Rect2(w * 0.47, m.end.y + 10, w * 0.06, h * 0.06), Color(0.15, 0.15, 0.17))
	_cuad(ci, Vector2(w * 0.12, h * 0.7), Vector2(w * 0.88, h * 0.7), Vector2(w * 0.95, h * 0.8), Vector2(w * 0.05, h * 0.8), Color(0.5, 0.36, 0.22), Color(0.42, 0.3, 0.18))
	ci.draw_rect(Rect2(w * 0.05, h * 0.8, w * 0.9, h * 0.05), Color(0.3, 0.2, 0.12))
	_cuad(ci, Vector2(w * 0.38, h * 0.72), Vector2(w * 0.62, h * 0.72), Vector2(w * 0.64, h * 0.76), Vector2(w * 0.36, h * 0.76), Color(0.2, 0.2, 0.22))
	ci.draw_line(Vector2(w * 0.2, h * 0.72), Vector2(w * 0.22, h * 0.55), Color(0.2, 0.2, 0.22), 6.0)
	ci.draw_line(Vector2(w * 0.22, h * 0.55), Vector2(w * 0.27, h * 0.57), Color(0.2, 0.2, 0.22), 6.0)
	for r in 5:
		ci.draw_circle(Vector2(w * 0.27, h * 0.62), 20.0 + r * 22.0, Color(1, 0.85, 0.5, 0.05))
	ci.draw_rect(Rect2(w * 0.72, h * 0.66, w * 0.025, h * 0.05), Color(0.92, 0.92, 0.9))
	ci.draw_rect(Rect2(w * 0.8, h * 0.62, w * 0.03, h * 0.09), Color(0.45, 0.3, 0.2))
	for k in 5:
		ci.draw_circle(Vector2(w * (0.8 + 0.012 * k), h * (0.57 + 0.015 * (k % 2))), h * 0.025, Color(0.2, 0.5, 0.24))
