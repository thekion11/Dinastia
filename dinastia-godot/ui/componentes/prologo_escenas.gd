class_name PrologoEscenas
extends RefCounted
## LAS ESCENAS DEL PRÓLOGO DE CINE (10-11). Por escena: el PRIMER PLANO (`frente`, una capa fija que la cámara mueve más rápido que el fondo: paralaje),
## las LUCES (`luces`, con mezcla aditiva: focos que se encienden, la luz del campo en el túnel, el sol, el monitor) y lo VIVO (`vivo`: banderas,
## el equipo caminando, el DT gesticulando, la firma del contrato). El fondo de cada escena es `PrologoArte`. Todo en coordenadas de la capa grande
## (`w`, `h` = pantalla × (1 + 2·MARGEN)), igual que el fondo, para que encajen.

# ---------------------------------------------------------------- primer plano (fijo)

static func frente(ci: CanvasItem, escena: String, w: float, h: float, c1: Color, c2: Color) -> void:
	var negro := Color(0.02, 0.02, 0.03)
	match escena:
		"estadio":   ## la primera fila de hinchas, de espaldas, con bufandas en alto
			for k in 15:
				var x := w * (0.02 + 0.07 * k) + float(k % 3) * 9.0
				var alto := h * (0.42 + 0.05 * float((k * 7) % 3))
				var brazo := 0.9 if k % 3 == 0 else (0.5 if k % 3 == 1 else 0.0)
				PrologoCine.figura(ci, Vector2(x, h * 1.12 + alto * 0.15), alto, negro, 0.0, brazo)
				if k % 3 == 0:   ## la bufanda estirada entre las manos
					ci.draw_line(Vector2(x - alto * 0.18, h * 1.12 - alto * 0.95), Vector2(x + alto * 0.28, h * 1.12 - alto * 1.02), c1, alto * 0.05)
					ci.draw_line(Vector2(x - alto * 0.1, h * 1.12 - alto * 0.965), Vector2(x + alto * 0.2, h * 1.12 - alto * 1.0), c2, alto * 0.018)
		"vestuario":   ## la camiseta del 10 colgada en primer plano, a la izquierda
			var cx := w * 0.12
			var cy := h * 0.56
			var a := h * 0.4
			ci.draw_line(Vector2(cx, cy - a * 0.62), Vector2(cx, cy - a * 0.5), Color(0.6, 0.6, 0.62), 4.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - a * 0.5, cy - a * 0.38), Vector2(cx - a * 0.15, cy - a * 0.5), Vector2(cx + a * 0.15, cy - a * 0.5),
				Vector2(cx + a * 0.5, cy - a * 0.38), Vector2(cx + a * 0.42, cy - a * 0.18), Vector2(cx + a * 0.3, cy - a * 0.22), Vector2(cx + a * 0.3, cy + a * 0.42),
				Vector2(cx - a * 0.3, cy + a * 0.42), Vector2(cx - a * 0.3, cy - a * 0.22), Vector2(cx - a * 0.42, cy - a * 0.18)]), c1.lerp(Color(0.5, 0.5, 0.5), 0.15))
			ci.draw_line(Vector2(cx + a * 0.3, cy - a * 0.22), Vector2(cx + a * 0.3, cy + a * 0.42), Color(1, 0.95, 0.8, 0.5), 3.0)   ## filo de luz
			ci.draw_line(Vector2(cx - a * 0.15, cy - a * 0.5), Vector2(cx + a * 0.15, cy - a * 0.5), c2, a * 0.04)
			ci.draw_string(ThemeDB.fallback_font, Vector2(cx - a * 0.22, cy + a * 0.18), "10", HORIZONTAL_ALIGNMENT_CENTER, a * 0.44, int(a * 0.4), c2)
			ci.draw_rect(Rect2(0, h * 0.86, w * 0.42, h * 0.05), Color(0.36, 0.24, 0.14))   ## el canto del banco
		"tunel":   ## las columnas de hormigón del túnel, muy cerca, enmarcando
			for lado: float in [0.0, 1.0]:
				var x0 := w * (0.0 if lado == 0.0 else 0.86)
				PrologoCine.degradado(ci, Rect2(x0, 0, w * 0.14, h), negro, Color(0.08, 0.08, 0.1))
				ci.draw_rect(Rect2(x0 + (w * 0.13 if lado == 0.0 else 0.0), 0, 3, h), Color(c1, 0.6))
		"banquillo":   ## los postes del banquillo y una botella en el césped
			for x: float in [w * 0.06, w * 0.94]:
				ci.draw_rect(Rect2(x - 9, 0, 18, h), negro)
			ci.draw_rect(Rect2(w * 0.8, h * 0.8, w * 0.025, h * 0.12), Color(0.35, 0.6, 0.85, 0.85))
			ci.draw_rect(Rect2(w * 0.8, h * 0.79, w * 0.025, h * 0.015), c1)
		"despacho":   ## la lámpara de mesa a la izquierda y el respaldo de una silla a la derecha
			ci.draw_line(Vector2(w * 0.1, h * 0.95), Vector2(w * 0.12, h * 0.6), negro, 8.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(w * 0.06, h * 0.6), Vector2(w * 0.18, h * 0.6), Vector2(w * 0.15, h * 0.5), Vector2(w * 0.09, h * 0.5)]), Color(0.1, 0.25, 0.15))
			ci.draw_circle(Vector2(w * 0.92, h * 1.0), h * 0.22, negro)
		"oficina":   ## la taza humeante y hojas de una planta, desenfocadas en primer plano
			ci.draw_rect(Rect2(w * 0.83, h * 0.78, w * 0.06, h * 0.12), Color(0.85, 0.85, 0.82))
			ci.draw_arc(Vector2(w * 0.895, h * 0.83), h * 0.03, -PI * 0.5, PI * 0.5, 12, Color(0.85, 0.85, 0.82), 6.0)
			for k in 4:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(w * 0.02, h * (0.75 + 0.06 * k)), Vector2(w * (0.1 + 0.03 * k), h * (0.62 + 0.05 * k)), Vector2(w * 0.05, h * (0.8 + 0.05 * k))]), Color(0.08, 0.2, 0.1))

# ---------------------------------------------------------------- luces (aditivas, cada cuadro)

## `t`: segundos dentro del plano.
static func luces(ci: CanvasItem, escena: String, w: float, h: float, t: float, c1: Color) -> void:
	var calida := Color(1.0, 0.92, 0.75)
	match escena:
		"estadio":   ## las torres se encienden una tras otra (con su fogonazo) y bañan el césped
			for k in 2:
				var on := clampf((t - 1.4 - 0.7 * k) * 3.0, 0.0, 1.0)
				if on <= 0.0:
					continue
				var fx := w * (0.1 if k == 0 else 0.9)
				var fogonazo := clampf(1.0 - (t - 1.4 - 0.7 * k) * 1.5, 0.0, 1.0)
				PrologoCine.brillo(ci, Vector2(fx, h * 0.035), h * (0.18 + 0.25 * fogonazo), calida, on)
				PrologoCine.cono(ci, Vector2(fx, h * 0.04), Vector2(w * 0.5 + (w * 0.05 if k == 0 else -w * 0.05), h * 0.95), w * 0.55, calida, 0.35 * on)
			PrologoCine.brillo(ci, Vector2(w * 0.5, h * 0.43), h * 0.2, Color(c1.lerp(Color.WHITE, 0.6), 0.5), 0.6 + 0.2 * sin(t * 2.0))
		"vestuario":
			for k in 3:
				PrologoCine.brillo(ci, Vector2(w * 0.5, h * (0.05 + 0.055 * k)), h * (0.14 - 0.03 * k), calida, 0.55)
			PrologoCine.cono(ci, Vector2(w * 0.5, h * 0.06), Vector2(w * 0.5, h * 0.95), w * 0.5, calida, 0.22)
		"tunel":   ## la luz del campo crece al acercarse a la boca, con rayos hacia la cámara
			var crece := 0.6 + 0.4 * clampf(t / 6.0, 0.0, 1.0)
			var boca := Vector2(w * 0.5, h * 0.45)
			PrologoCine.brillo(ci, boca, h * 0.45 * crece, Color(0.85, 1.0, 0.85), 0.9)
			for k in 5:
				var ang := -0.5 + 0.25 * k + sin(t * 0.7 + k) * 0.03
				PrologoCine.cono(ci, boca, boca + Vector2(sin(ang), cos(ang) * 0.6 + 0.4).normalized() * h, w * 0.12, Color(0.9, 1.0, 0.9), 0.18 * crece)
		"banquillo":
			for fx: float in [0.02, 0.98]:
				PrologoCine.brillo(ci, Vector2(w * fx, h * 0.02), h * 0.3, calida, 0.6)
		"despacho":   ## el sol del atardecer entra por el ventanal
			PrologoCine.brillo(ci, Vector2(w * 0.62, h * 0.48), h * 0.35, Color(1.0, 0.65, 0.35), 0.55)
			PrologoCine.cono(ci, Vector2(w * 0.55, h * 0.3), Vector2(w * 0.4, h * 1.0), w * 0.5, Color(1.0, 0.7, 0.4), 0.18)
		"oficina":   ## el monitor y la lámpara
			PrologoCine.brillo(ci, Vector2(w * 0.5, h * 0.45), h * 0.42, Color(0.5, 0.95, 0.65), 0.35 + 0.05 * sin(t * 3.0))
			PrologoCine.brillo(ci, Vector2(w * 0.27, h * 0.62), h * 0.2, calida, 0.6)

# ---------------------------------------------------------------- lo vivo (cada cuadro)

static func vivo(ci: CanvasItem, escena: String, w: float, h: float, t: float, c1: Color, c2: Color) -> void:
	match escena:
		"estadio":
			for k in 6:   ## banderas que ondean en la grada
				PrologoCine.bandera(ci, Vector2(w * (0.12 + 0.15 * k), h * (0.4 + 0.04 * (k % 2))), Vector2(h * 0.07, h * 0.045), c1, c2, t, k * 1.3)
			PrologoArte.dibujar_vivo(ci, escena, w, h, t)   ## los flashes de la grada
		"vestuario":   ## el vapor de las duchas sube despacio entre las taquillas
			for k in 6:
				var sube := fmod(t * 0.12 + k * 0.17, 1.0)
				PrologoCine.brillo(ci, Vector2(w * (0.3 + 0.08 * k), lerpf(h * 0.8, h * 0.3, sube)), h * 0.09, Color(1, 1, 1, 0.08 * (1.0 - sube)))
		"tunel":   ## el equipo camina hacia la luz, de espaldas y a contraluz
			var boca := Rect2(w * 0.42, h * 0.3, w * 0.16, h * 0.3)
			for k in 4:
				var avance := fmod(t * 0.06 + k * 0.25 + 0.15, 1.0)
				var y := lerpf(h * 0.98, boca.end.y, avance)
				var alto := lerpf(h * 0.46, boca.size.y * 0.45, avance)
				var x := w * 0.5 + (float(k % 2) * 2.0 - 1.0) * lerpf(w * 0.09, boca.size.x * 0.18, avance)
				PrologoCine.figura(ci, Vector2(x, y), alto, Color(0.02, 0.025, 0.03), t * 6.5 + k * 1.7, 0.0, Color(0.55, 0.85, 0.55, 0.25 * (1.0 - avance)))
		"banquillo":   ## el DT en la línea, dando órdenes con el brazo
			var gesto := clampf(sin(t * 1.6) * 1.3, 0.0, 1.0)
			PrologoCine.figura(ci, Vector2(w * 0.62, h * 0.66), h * 0.34, Color(0.07, 0.07, 0.09), 0.0, gesto, Color(1, 0.95, 0.8, 0.25), Color(0.62, 0.48, 0.38))
		"despacho":   ## la firma se escribe sola sobre el contrato
			var papel := Rect2(w * 0.4, h * 0.645, w * 0.12, h * 0.042)
			ci.draw_rect(papel, Color(0.95, 0.94, 0.9))
			var hasta := clampf((t - 1.0) / 3.0, 0.0, 1.0)
			var prev := papel.position + Vector2(papel.size.x * 0.1, papel.size.y * 0.6)
			for k in int(hasta * 40.0):
				var u := float(k) / 40.0
				var p := papel.position + Vector2(papel.size.x * (0.1 + 0.8 * u), papel.size.y * (0.6 + 0.22 * sin(u * 26.0)))
				ci.draw_line(prev, p, Color(0.1, 0.12, 0.35), 2.0)
				prev = p
			if hasta < 1.0:
				ci.draw_line(prev, prev + Vector2(h * 0.05, -h * 0.06), Color(0.85, 0.7, 0.2), 4.0)   ## la pluma
		"oficina":   ## el menú del PC se va armando y el cursor parpadea
			var m := Rect2(w * 0.3, h * 0.3, w * 0.4, h * 0.3)
			for k in 7:
				var aparece := clampf((t - 0.4 - 0.25 * k) * 3.0, 0.0, 1.0)
				ci.draw_rect(Rect2(m.end.x - m.size.x * 0.4, m.position.y + m.size.y * (0.2 + 0.1 * k), m.size.x * 0.36 * aparece, m.size.y * 0.07), Color(c1.lerp(Color.WHITE, 0.4), 0.25))
			PrologoArte.dibujar_vivo(ci, escena, w, h, t)
