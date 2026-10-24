extends "res://ui/disenos_kit_p1.gd"
## [Capa 2/3 de `disenos_kit.gd`] color_en, _mascara_camiseta, _estampar_sponsors

## El color del diseño en (u, v) del torso. `x`, `y` son las coordenadas de
## reposo (para los 12 de siempre, que usan la fórmula vieja).
static func color_en(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var f := int(d[2])
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var dd := float(d[6])
	var x := u * 0.215
	var y := 1.0 + v * 0.52
	if f >= 100:
		return cols[0].lerp(cols[1], _legado(f - 100, x, y))
	## El acento de las familias 43-62: el color 2 en los de tres colores y el 1
	## en los de dos.
	var acento := cols[2] if dd > 0.5 else cols[1]
	match f:
		1:
			var s := (u + 1.0) * 0.5 * a
			return _banda(cols, floorf(s), c) if fposmod(s, 1.0) < b else cols[0]
		2:
			var s2 := v * a
			return _banda(cols, floorf(s2), c) if fposmod(s2, 1.0) < b else cols[0]
		3:
			var e := u * 0.5 - (v - 0.5) * a - c
			if absf(e) < b:
				return cols[1]
			if dd > 0.5 and absf(e - b * 2.6) < b * 0.5:
				return cols[2]
			return cols[0]
		4:
			return _ciclo(cols, floorf(clampf((u + 1.0) * 0.5, 0.0, 0.999) * a), minf(a, 5.0) if a <= 5.0 else 2.0)
		5:
			return _ciclo(cols, floorf(clampf(v, 0.0, 0.999) * a), a)
		6:
			var dv := absf(v - a)
			if dv < b:
				return cols[1]
			if c > 0.5 and dv < b + 0.035:
				return cols[2]
			return cols[0]
		7:
			var lim := a - u * u * b
			if v > lim:
				return cols[1]
			if c > 0.5 and v > lim - 0.04:
				return cols[2]
			return cols[0]
		8:
			var cu := floorf((u + 1.0) * 0.5 * a)
			var cv := floorf(v * a)
			if int(fposmod(cu + cv, 2.0)) == 1:
				return cols[2] if b > 0.5 and int(fposmod(cu, 2.0)) == 1 else cols[1]
			return cols[0]
		9:
			var t := v if a < 0.5 else ((u + 1.0) * 0.25 + v * 0.5 if a < 1.5 else (u + 1.0) * 0.5)
			return cols[0].lerp(cols[1], smoothstep(0.1, 0.9, 1.0 - t) if a < 0.5 else smoothstep(0.1, 0.9, t))
		10:
			var e2 := v - absf(u) * a * 0.5
			if c <= 1.0:
				return cols[1] if absf(e2 - 0.45) < b else cols[0]
			return cols[1] if fposmod(e2 * c, 1.0) < 0.35 else cols[0]
		11:
			return cols[1] if absf(u - c) < a or absf(v - b) < a * 0.9 else cols[0]
		12:
			if absf(u) > a:
				return cols[1]
			if c > 0.5 and absf(u) > a - 0.06:
				return cols[2]
			return cols[0]
		13:
			if absf(u) < a:
				return cols[1]
			if c > 0.5 and absf(u) < a + 0.07:
				return cols[2]
			return cols[0]
		14:
			return cols[1] if fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.07 else cols[0]
		15:
			return cols[1] if fposmod((v + sin(u * a) * b) * c, 1.0) < 0.5 else cols[0]
		16:
			return cols[1] if fposmod((v + absf(fposmod(u * a, 1.0) - 0.5) * b) * c, 1.0) < 0.5 else cols[0]
		17:
			var px := (u + 1.0) * 0.5 * a
			var py := v * a * 1.2
			var cx := floorf(px) + 0.5
			var cy := floorf(py) + 0.5
			if Vector2(px - cx, py - cy).length() < b:
				return cols[2] if c > 0.5 and int(fposmod(floorf(px) + floorf(py), 2.0)) == 1 else cols[1]
			return cols[0]
		18:
			var qx := (u + 1.0) * 0.5 * a
			var qy := v * a * 1.4
			var r := absf(fposmod(qx, 1.0) - 0.5) + absf(fposmod(qy, 1.0) - 0.5)
			if b > 0.5 and (absf(fposmod(qx + qy, 1.0) - 0.5) < 0.03 or absf(fposmod(qx - qy, 1.0) - 0.5) < 0.03):
				return cols[3]
			if r < 0.5:
				return cols[1] if int(fposmod(floorf(qx) + floorf(qy), 2.0)) == 0 else cols[2]
			return cols[0]
		19:
			var sx := (u + 1.0) * 0.5 * a
			var sy := v * a * 1.3
			var fila := floorf(sy)
			var ox := sx + (0.5 if int(fposmod(fila, 2.0)) == 1 else 0.0)
			var dx := fposmod(ox, 1.0) - 0.5
			var dy := fposmod(sy, 1.0)
			return cols[1] if Vector2(dx, dy).length() > 0.5 else cols[0]
		20:
			var ang := atan2(v - 0.62, u)
			return cols[1] if int(fposmod(floorf((ang + PI) / PI * a), 2.0)) == 1 else cols[0]
		21:
			return cols[1] if fposmod(Vector2(u, (v - 0.62) * 1.2).length() * a, 1.0) < 0.5 else cols[0]
		22:
			var n := _ruido((u + 3.0) * a, (v + 3.0) * a * 1.3)
			var k := int(b)
			return cols[clampi(int(n * float(k) * 1.15), 0, k - 1)]
		23:
			var pos := (u + 1.0) * 0.5 if a < 0.5 else v
			return _ciclo(cols, floorf(clampf(pos, 0.0, 0.999) * b), b)
		24:
			var borde := minf(1.0 - absf(u), minf(v, 1.0 - v) * 1.6)
			if borde < a:
				return cols[1]
			if b > 0.5 and borde < a + 0.05 and borde > a + 0.02:
				return cols[2]
			return cols[0]
		25:
			var w := fposmod((u + _ruido(v * a, 1.7) * 0.5) * 2.5, 1.0)
			return cols[1] if w < 0.3 else (cols[2] if w < 0.42 else cols[0])
		26:
			var vx := fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.3
			var vy := fposmod(v * a, 1.0) < 0.3
			if vx and vy:
				return cols[3] if int(d[7]) >= 4 else cols[1].lerp(cols[2], 0.5)
			if vx:
				return cols[1]
			if vy:
				return cols[2]
			return cols[0]
		27:
			var rx := (u + v) * a * 0.5
			var ry := (u - v) * a * 0.5
			return cols[1] if int(fposmod(floorf(rx) + floorf(ry), 2.0)) == 1 else cols[0]
		28:
			return cols[1] if fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.1 + v * 0.7 else cols[0]
		29:
			var hh := _h21(floorf((u + 1.0) * 0.5 * a), floorf(v * a))
			return cols[1] if hh < 0.3 else (cols[2] if hh < 0.45 else cols[0])
		30:
			var gx := (u + 1.0) * 0.5 * a
			var gy := v * a * 1.2
			var rr := b * clampf(1.0 - v, 0.0, 1.0)
			return cols[1] if Vector2(fposmod(gx, 1.0) - 0.5, fposmod(gy, 1.0) - 0.5).length() < rr else cols[0]
		31:
			return cols[1] if fposmod(_ruido(u * a + 5.0, v * a + 5.0) * b, 1.0) < 0.14 else cols[0]
		32:
			var vena := absf(sin((u + _ruido(u * 2.0 + 1.0, v * 3.0) * 1.6) * a))
			return cols[1] if vena < 0.07 else cols[0].lerp(cols[2], 0.35 * _ruido(u * 3.0, v * 3.0 + 4.0))
		33:
			var fx := (u + v * 0.6) * a
			var fy := (v - u * 0.4) * a
			var tri := 1.0 if fposmod(fx, 1.0) > fposmod(fy, 1.0) else 0.0
			var hf := _h21(floorf(fx) + tri * 7.0, floorf(fy))
			return cols[1] if hf < 0.33 else (cols[2] if hf < 0.55 else cols[0])
		34:
			if absf(u) > 1.01:
				return cols[1]
			if a > 0.5 and v > 0.86:
				return cols[1]
			if absf(v - 0.86) < 0.02 and a > 0.5:
				return cols[2]
			return cols[0]
		35:
			var e3 := u * a * 0.5 + (v - 0.5)
			if absf(e3) < 0.025:
				return cols[2]
			return cols[1] if e3 > 0.0 else cols[0]
		36:
			return cols[1] if absf(v - 0.6 - (absf(fposmod(u * a, 1.0) - 0.5) - 0.25) * b) < 0.05 else cols[0]
		37:
			return cols[1] if fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.06 or fposmod(v * a * 1.2, 1.0) < 0.06 else cols[0]
		38:
			var sx2 := (u + 1.0) * 0.5 * a
			var sy2 := v * a * 1.2
			var dv2 := Vector2(fposmod(sx2, 1.0) - 0.5, fposmod(sy2, 1.0) - 0.5)
			var th := atan2(dv2.y, dv2.x)
			return cols[1] if dv2.length() < b * (0.55 + 0.45 * cos(5.0 * th)) else cols[0]
		39:
			return cols[1].lerp(cols[2], v) if fposmod((u + 1.0) * 0.5 * a, 1.0) < b else cols[0]
		40:
			if absf(v - a) < b:
				return cols[2] if fposmod((u + 1.0) * 6.0, 1.0) < 0.15 else cols[1]
			return cols[0]
		41:
			return cols[0].lerp(cols[1], smoothstep(0.1, 1.1, Vector2(u, (v - 0.62) * 1.3).length()))
		42:
			var hx := (u + 1.0) * 0.5 * a
			var hy := v * a * 1.2
			var rd := b * clampf((u + 1.0) * 0.5 * 0.6 + (1.0 - v) * 0.6, 0.0, 1.0)
			return cols[1] if Vector2(fposmod(hx, 1.0) - 0.5, fposmod(hy, 1.0) - 0.5).length() < rd else cols[0]
		43:
			var e43 := v - (0.98 - absf(u) * a)
			if absf(e43) < b:
				return cols[1]
			return acento if absf(e43) < b + 0.035 else cols[0]
		44:
			var t44 := 0.5 + (1.0 - absf(u)) * a
			if absf(v - t44) < 0.025:
				return acento
			return cols[1] if v > t44 else cols[0]
		45:
			if absf(v - a) < b:
				return cols[1]
			return acento if absf(v - a + 0.2) < b else cols[0]
		46:
			if absf(u) < 0.03:
				return acento
			if u < 0.0:
				return cols[1] if fposmod((u + 1.0) * a, 1.0) < 0.5 else cols[0]
			return cols[0]
		47:
			var z47 := a + (absf(fposmod(u * b, 1.0) - 0.5) - 0.25) * 0.12
			if v > z47 + 0.02:
				return cols[1]
			return acento if v > z47 - 0.02 else cols[0]
		48:
			var p48 := Vector2(u * a, v * a * 1.15)
			var r48 := Vector2(1.0, 1.732)
			var a48 := Vector2(fposmod(p48.x, r48.x), fposmod(p48.y, r48.y)) - r48 * 0.5
			var q48 := p48 - r48 * 0.5
			var b48 := Vector2(fposmod(q48.x, r48.x), fposmod(q48.y, r48.y)) - r48 * 0.5
			var g48 := a48 if a48.dot(a48) < b48.dot(b48) else b48
			var dh := maxf(absf(g48.x), absf(g48.x) * 0.5 + absf(g48.y) * 0.866)
			if dh > 0.45:
				return cols[1]
			var c48 := p48 - g48
			return acento if _h21(floorf(c48.x * 2.0), floorf(c48.y * 2.0)) < 0.22 else cols[0]
		49:
			var tx := (u + 1.0) * 0.5 * a
			var ty := v * a
			var tri := fposmod(tx + fposmod(floorf(ty), 2.0) * 0.5, 1.0)
			if fposmod(ty, 1.0) < 1.0 - absf(tri - 0.5) * 2.0:
				return cols[1] if int(fposmod(floorf(tx + fposmod(floorf(ty), 2.0) * 0.5) + floorf(ty), 2.0)) == 0 else acento
			return cols[0]
		50:
			var s50 := (u + sin(v * b) * 0.06) * a * 0.5
			if fposmod(s50, 1.0) < 0.5:
				return cols[1] if int(fposmod(floorf(s50), 2.0)) == 0 else acento
			return cols[0]
		51:
			var z51 := sin(u * a * 3.0 + _ruido(u * 2.0 + 3.0, v * 2.5) * b + v * 2.0)
			if z51 > 0.3:
				return cols[1]
			return acento if z51 > 0.1 and dd > 0.5 else cols[0]
		52:
			var s52 := fposmod((u + v * a) * b, 1.0)
			if s52 < 0.35:
				return cols[1]
			return acento if s52 < 0.45 and dd > 0.5 else cols[0]
		53:
			var cx53 := (u + 1.0) * 0.5 * a
			if fposmod(cx53, 1.0) < 0.06:
				return acento if dd > 0.5 else cols[1]
			var sg := 1.0 if int(fposmod(floorf(cx53), 2.0)) == 0 else -1.0
			return cols[1] if fposmod(v * a * 1.2 + sg * fposmod(cx53, 1.0), 1.0) < 0.5 else cols[0]
		54:
			var dv54 := absf(v - a)
			if absf(dv54 - 0.12) < 0.012:
				return acento
			if dv54 < 0.12:
				return cols[1] if _h21(floorf((u + 1.0) * 40.0), 3.0) < 0.5 else cols[0]
			return cols[0]
		55:
			var r55 := Vector2(u, (v - 0.6) * 1.2).length()
			if absf(r55 - a) < b:
				return cols[1]
			return acento if absf(r55 - a - b * 2.2) < b * 0.5 else cols[0]
		56:
			var e56 := v - (0.72 + absf(u) * a)
			if absf(e56) < b:
				return cols[1]
			return acento if absf(e56 + 0.1) < b * 0.6 else cols[0]
		57:
			if absf(u) > a:
				if fposmod(v * b, 1.0) < 0.5:
					return cols[1]
				return cols[2] if dd > 0.5 else cols[0]
			return cols[0]
		58:
			var fl := a + _ruido(u * 4.0, v * 2.0 + 7.0) * 0.25 + sin(u * b) * 0.05
			if v < fl:
				return cols[1]
			return acento if v < fl + 0.05 else cols[0]
		59:
			var mx := (u + 1.0) * 0.5 * a
			var my := v * a * 1.2
			var md := 9.0
			var mh := 0.0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var cxm := floorf(mx) + float(ox)
					var cym := floorf(my) + float(oy)
					var px := cxm + 0.5 + (_h21(cxm, cym) - 0.5) * 0.7
					var py := cym + 0.5 + (_h21(cym + 3.1, cxm) - 0.5) * 0.7
					var dm := Vector2(mx - px, my - py).length()
					if dm < md:
						md = dm
						mh = _h21(cxm + 9.0, cym + 9.0)
			if mh < 0.35:
				return cols[1]
			return acento if mh < 0.55 else cols[0]
		60:
			var d60 := absf(u) + absf(v - 0.58) * 1.3
			if d60 < a:
				return cols[1]
			return acento if absf(d60 - a - 0.06) < 0.02 else cols[0]
		61:
			var sx61 := fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.5
			var sy61 := fposmod(v * a * 1.2, 1.0) < 0.5
			if sx61 and sy61:
				return cols[1]
			if sx61 or sy61:
				return cols[2] if dd > 0.5 else cols[0]
			return cols[0]
		62:
			var w62 := fposmod((v - u * a * 0.3) * b, 1.0)
			var an := 0.12 * (u + 1.0)
			if w62 < an:
				return cols[1]
			return acento if w62 < an + 0.03 else cols[0]
	return cols[0]

## La silueta de la camiseta (la misma de `Jersey.svg_de`), en blanco.
static func _mascara_camiseta(escala: float) -> Image:
	var svg := '<svg width="64" height="52" viewBox="0 0 64 52" xmlns="http://www.w3.org/2000/svg"><path d="M20 4 8 10l4 10 6-3v29h28V17l6 3 4-10L44 4l-6 3h-12z" fill="#fff"/></svg>'
	var img := Image.new()
	img.load_svg_from_string(svg, escala)
	return img

## Los patrocinadores sobre la camiseta 2D: el del pecho entre el escudo y el
## bajo, el de la manga en la manga izquierda del jugador y el de la espalda
## debajo del número. Se estampan con la luz del tejido (se multiplican por la
## luminosidad que ya tiene la tela) para que no parezcan pegatinas.
static func _estampar_sponsors(out: Image, escala: float, fondo: Color, sp: Dictionary, espalda: bool) -> void:
	var zonas: Array = []
	if not espalda and sp.has("pecho"):
		zonas.append(["pecho", Rect2(20.0, 20.0, 24.0, 9.5), false])
	if not espalda and sp.has("manga"):
		zonas.append(["manga", Rect2(47.5, 10.0, 5.5, 5.5), true])
	if espalda and sp.has("espalda"):
		zonas.append(["espalda", Rect2(23.0, 8.5, 18.0, 5.0), false])
	for z: Array in zonas:
		var info: Dictionary = sp[String(z[0])]
		var letras := SponsorKit.color_letras(String(info.get("color", "#ffffff")), fondo)
		var img := SponsorKit.imagen(String(info.get("marca", "")), String(info.get("color", "#ffffff")), letras, bool(z[2])).duplicate() as Image
		var zona: Rect2 = z[1]
		## Encajar sin deformar, centrado en la zona.
		var asp := float(img.get_width()) / float(img.get_height())
		var r := zona
		if asp > zona.size.x / zona.size.y:
			r.size.y = zona.size.x / asp
		else:
			r.size.x = zona.size.y * asp
		r.position = zona.position + (zona.size - r.size) * 0.5
		var rw := int(r.size.x * escala)
		var rh := int(r.size.y * escala)
		img.resize(maxi(rw, 1), maxi(rh, 1), Image.INTERPOLATE_LANCZOS)
		var ox := int(r.position.x * escala)
		var oy := int(r.position.y * escala)
		for py in img.get_height():
			for px in img.get_width():
				var src := img.get_pixel(px, py)
				if src.a <= 0.02:
					continue
				var tx := ox + px
				var ty := oy + py
				if tx < 0 or ty < 0 or tx >= out.get_width() or ty >= out.get_height():
					continue
				var dst := out.get_pixel(tx, ty)
				if dst.a <= 0.01:
					continue
				## La luz de la tela en ese punto, respecto del color base.
				var luz := clampf(dst.get_luminance() / maxf(fondo.get_luminance(), 0.05), 0.75, 1.15)
				var c := dst.lerp(Color(src.r * luz, src.g * luz, src.b * luz), src.a * 0.96)
				c.a = dst.a
				out.set_pixel(tx, ty, c)
