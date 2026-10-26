extends "res://ui/disenos_kit_p1.gd"
## [Capa 2/5 de `disenos_kit.gd`] fórmulas 1-31
## LAS FÓRMULAS DE LAS FAMILIAS DE CAMISETA (espejo de `visor/equipacion_q.gdshader`). Cada una recibe la
## fila del diseño `d` (parámetros a, b, c, d = d[3..6]; colores que usa = d[7]), los 5 colores y (u, v) del
## torso, y devuelve el color. No se llaman a mano: `color_en` (capa 4) las busca en la tabla FORMULAS.
## Encima de cada una, su número de familia y los diseños de DISENOS que la usan.

## 1 · franjas_finas, franjas_anchas, franjas_tricolor, bastones, franjas_cinco
static func _fam_franjas(d: Array, cols: Array[Color], u: float, _v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var s := (u + 1.0) * 0.5 * a
	return _banda(cols, floorf(s), c) if fposmod(s, 1.0) < b else cols[0]

## 2 · aros_finos, aros_anchos, aros_tricolor
static func _fam_aros(d: Array, cols: Array[Color], _u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var s2 := v * a
	return _banda(cols, floorf(s2), c) if fposmod(s2, 1.0) < b else cols[0]

## 3 · banda_cruzada, doble_banda, banda_inversa, banda_baja
static func _fam_banda(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var dd := float(d[6])
	var e := u * 0.5 - (v - 0.5) * a - c
	if absf(e) < b:
		return cols[1]
	if dd > 0.5 and absf(e - b * 2.6) < b * 0.5:
		return cols[2]
	return cols[0]

## 4 · tercios_v, cuartos_v, gajos
static func _fam_panos_v(d: Array, cols: Array[Color], u: float, _v: float) -> Color:
	var a := float(d[3])
	return _ciclo(cols, floorf(clampf((u + 1.0) * 0.5, 0.0, 0.999) * a), minf(a, 5.0) if a <= 5.0 else 2.0)

## 5 · tercios_h, bloques_h
static func _fam_bloques_h(d: Array, cols: Array[Color], _u: float, v: float) -> Color:
	var a := float(d[3])
	return _ciclo(cols, floorf(clampf(v, 0.0, 0.999) * a), a)

## 6 · franja_pecho, pecho_ribete
static func _fam_franja_pecho(d: Array, cols: Array[Color], _u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var dv := absf(v - a)
	if dv < b:
		return cols[1]
	if c > 0.5 and dv < b + 0.035:
		return cols[2]
	return cols[0]

## 7 · canesu, canesu_curvo
static func _fam_canesu(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var lim := a - u * u * b
	if v > lim:
		return cols[1]
	if c > 0.5 and v > lim - 0.04:
		return cols[2]
	return cols[0]

## 8 · cuadros_chicos, cuadros_grandes, ajedrez_tricolor
static func _fam_cuadros(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var cu := floorf((u + 1.0) * 0.5 * a)
	var cv := floorf(v * a)
	if int(fposmod(cu + cv, 2.0)) == 1:
		return cols[2] if b > 0.5 and int(fposmod(cu, 2.0)) == 1 else cols[1]
	return cols[0]

## 9 · degrade_diagonal, degrade_lateral
static func _fam_degrade(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var t := v if a < 0.5 else ((u + 1.0) * 0.25 + v * 0.5 if a < 1.5 else (u + 1.0) * 0.5)
	return cols[0].lerp(cols[1], smoothstep(0.1, 0.9, 1.0 - t) if a < 0.5 else smoothstep(0.1, 0.9, t))

## 10 · chevron, chevron_doble, v_invertida
static func _fam_chevron(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var e2 := v - absf(u) * a * 0.5
	if c <= 1.0:
		return cols[1] if absf(e2 - 0.45) < b else cols[0]
	return cols[1] if fposmod(e2 * c, 1.0) < 0.35 else cols[0]

## 11 · cruz, cruz_nordica
static func _fam_cruz(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	return cols[1] if absf(u - c) < a or absf(v - b) < a * 0.9 else cols[0]

## 12 · paneles_lado, lado_ribete
static func _fam_paneles_lado(d: Array, cols: Array[Color], u: float, _v: float) -> Color:
	var a := float(d[3])
	var c := float(d[5])
	if absf(u) > a:
		return cols[1]
	if c > 0.5 and absf(u) > a - 0.06:
		return cols[2]
	return cols[0]

## 13 · franja_central, central_ribete
static func _fam_franja_central(d: Array, cols: Array[Color], u: float, _v: float) -> Color:
	var a := float(d[3])
	var c := float(d[5])
	if absf(u) < a:
		return cols[1]
	if c > 0.5 and absf(u) < a + 0.07:
		return cols[2]
	return cols[0]

## 14 · tiza
static func _fam_tiza(d: Array, cols: Array[Color], u: float, _v: float) -> Color:
	var a := float(d[3])
	return cols[1] if fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.07 else cols[0]

## 15 · ondas, ondas_grandes
static func _fam_ondas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	return cols[1] if fposmod((v + sin(u * a) * b) * c, 1.0) < 0.5 else cols[0]

## 16 · zigzag
static func _fam_zigzag(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	return cols[1] if fposmod((v + absf(fposmod(u * a, 1.0) - 0.5) * b) * c, 1.0) < 0.5 else cols[0]

## 17 · lunares, lunares_bicolor
static func _fam_lunares(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var c := float(d[5])
	var px := (u + 1.0) * 0.5 * a
	var py := v * a * 1.2
	var cx := floorf(px) + 0.5
	var cy := floorf(py) + 0.5
	if Vector2(px - cx, py - cy).length() < b:
		return cols[2] if c > 0.5 and int(fposmod(floorf(px) + floorf(py), 2.0)) == 1 else cols[1]
	return cols[0]

## 18 · rombos, rombos_escoceses
static func _fam_rombos(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var qx := (u + 1.0) * 0.5 * a
	var qy := v * a * 1.4
	var r := absf(fposmod(qx, 1.0) - 0.5) + absf(fposmod(qy, 1.0) - 0.5)
	if b > 0.5 and (absf(fposmod(qx + qy, 1.0) - 0.5) < 0.03 or absf(fposmod(qx - qy, 1.0) - 0.5) < 0.03):
		return cols[3]
	if r < 0.5:
		return cols[1] if int(fposmod(floorf(qx) + floorf(qy), 2.0)) == 0 else cols[2]
	return cols[0]

## 19 · escamas
static func _fam_escamas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var sx := (u + 1.0) * 0.5 * a
	var sy := v * a * 1.3
	var fila := floorf(sy)
	var ox := sx + (0.5 if int(fposmod(fila, 2.0)) == 1 else 0.0)
	var dx := fposmod(ox, 1.0) - 0.5
	var dy := fposmod(sy, 1.0)
	return cols[1] if Vector2(dx, dy).length() > 0.5 else cols[0]

## 20 · rayos
static func _fam_rayos(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var ang := atan2(v - 0.62, u)
	return cols[1] if int(fposmod(floorf((ang + PI) / PI * a), 2.0)) == 1 else cols[0]

## 21 · anillos
static func _fam_anillos(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	return cols[1] if fposmod(Vector2(u, (v - 0.62) * 1.2).length() * a, 1.0) < 0.5 else cols[0]

## 22 · camuflaje, camuflaje_urbano
static func _fam_camuflaje(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var n := _ruido((u + 3.0) * a, (v + 3.0) * a * 1.3)
	var k := int(b)
	return cols[clampi(int(n * float(k) * 1.15), 0, k - 1)]

## 23 · arcoiris_v, arcoiris_h
static func _fam_arcoiris(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var pos := (u + 1.0) * 0.5 if a < 0.5 else v
	return _ciclo(cols, floorf(clampf(pos, 0.0, 0.999) * b), b)

## 24 · marco, marco_doble
static func _fam_marco(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var borde := minf(1.0 - absf(u), minf(v, 1.0 - v) * 1.6)
	if borde < a:
		return cols[1]
	if b > 0.5 and borde < a + 0.05 and borde > a + 0.02:
		return cols[2]
	return cols[0]

## 25 · pinceladas
static func _fam_pinceladas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var w := fposmod((u + _ruido(v * a, 1.7) * 0.5) * 2.5, 1.0)
	return cols[1] if w < 0.3 else (cols[2] if w < 0.42 else cols[0])

## 26 · tartan, tartan_fino
static func _fam_tartan(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var vx := fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.3
	var vy := fposmod(v * a, 1.0) < 0.3
	if vx and vy:
		return cols[3] if int(d[7]) >= 4 else cols[1].lerp(cols[2], 0.5)
	if vx:
		return cols[1]
	if vy:
		return cols[2]
	return cols[0]

## 27 · diamantes
static func _fam_diamantes(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var rx := (u + v) * a * 0.5
	var ry := (u - v) * a * 0.5
	return cols[1] if int(fposmod(floorf(rx) + floorf(ry), 2.0)) == 1 else cols[0]

## 28 · franjas_crecientes
static func _fam_franjas_crecientes(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	return cols[1] if fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.1 + v * 0.7 else cols[0]

## 29 · pixel
static func _fam_pixel(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var hh := _h21(floorf((u + 1.0) * 0.5 * a), floorf(v * a))
	return cols[1] if hh < 0.3 else (cols[2] if hh < 0.45 else cols[0])

## 30 · puntos_degradados, puntos_finos
static func _fam_puntos_degradados(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var gx := (u + 1.0) * 0.5 * a
	var gy := v * a * 1.2
	var rr := b * clampf(1.0 - v, 0.0, 1.0)
	return cols[1] if Vector2(fposmod(gx, 1.0) - 0.5, fposmod(gy, 1.0) - 0.5).length() < rr else cols[0]

## 31 · curvas_nivel, curvas_finas
static func _fam_curvas_nivel(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	return cols[1] if fposmod(_ruido(u * a + 5.0, v * a + 5.0) * b, 1.0) < 0.14 else cols[0]
