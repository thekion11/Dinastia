extends "res://ui/disenos_kit_p2.gd"
## [Capa 3/5 de `disenos_kit.gd`] fórmulas 32-62
## Las fórmulas 32-62 (las 43-62 llevan un acento; ver la capa 2 para la convención).

## El acento de las familias 43-62: el color 2 en los de tres colores (d = 1) y el 1 en los de dos (d = 0).
static func _acento(d: Array, cols: Array[Color]) -> Color:
	return cols[2] if float(d[6]) > 0.5 else cols[1]

## 32 · marmol, marmol_fino
static func _fam_marmol(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var vena := absf(sin((u + _ruido(u * 2.0 + 1.0, v * 3.0) * 1.6) * a))
	return cols[1] if vena < 0.07 else cols[0].lerp(cols[2], 0.35 * _ruido(u * 3.0, v * 3.0 + 4.0))

## 33 · fragmentos, fragmentos_grandes
static func _fam_fragmentos(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var fx := (u + v * 0.6) * a
	var fy := (v - u * 0.4) * a
	var tri := 1.0 if fposmod(fx, 1.0) > fposmod(fy, 1.0) else 0.0
	var hf := _h21(floorf(fx) + tri * 7.0, floorf(fy))
	return cols[1] if hf < 0.33 else (cols[2] if hf < 0.55 else cols[0])

## 34 · mangas_contraste, mangas_canesu
static func _fam_mangas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	if absf(u) > 1.01:
		return cols[1]
	if a > 0.5 and v > 0.86:
		return cols[1]
	if absf(v - 0.86) < 0.02 and a > 0.5:
		return cols[2]
	return cols[0]

## 35 · diagonal_partida, diagonal_partida_inv
static func _fam_diagonal_partida(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var e3 := u * a * 0.5 + (v - 0.5)
	if absf(e3) < 0.025:
		return cols[2]
	return cols[1] if e3 > 0.0 else cols[0]

## 36 · relampago
static func _fam_relampago(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	return cols[1] if absf(v - 0.6 - (absf(fposmod(u * a, 1.0) - 0.5) - 0.25) * b) < 0.05 else cols[0]

## 37 · cuadricula, cuadricula_fina
static func _fam_cuadricula(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	return cols[1] if fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.06 or fposmod(v * a * 1.2, 1.0) < 0.06 else cols[0]

## 38 · estrellas
static func _fam_estrellas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var sx2 := (u + 1.0) * 0.5 * a
	var sy2 := v * a * 1.2
	var dv2 := Vector2(fposmod(sx2, 1.0) - 0.5, fposmod(sy2, 1.0) - 0.5)
	var th := atan2(dv2.y, dv2.x)
	return cols[1] if dv2.length() < b * (0.55 + 0.45 * cos(5.0 * th)) else cols[0]

## 39 · franjas_degradadas
static func _fam_franjas_degradadas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	return cols[1].lerp(cols[2], v) if fposmod((u + 1.0) * 0.5 * a, 1.0) < b else cols[0]

## 40 · faja_rayas
static func _fam_faja_rayas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	if absf(v - a) < b:
		return cols[2] if fposmod((u + 1.0) * 6.0, 1.0) < 0.15 else cols[1]
	return cols[0]

## 41 · resplandor
static func _fam_resplandor(_d: Array, cols: Array[Color], u: float, v: float) -> Color:
	return cols[0].lerp(cols[1], smoothstep(0.1, 1.1, Vector2(u, (v - 0.62) * 1.3).length()))

## 42 · puntos_diagonal
static func _fam_puntos_diagonal(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var hx := (u + 1.0) * 0.5 * a
	var hy := v * a * 1.2
	var rd := b * clampf((u + 1.0) * 0.5 * 0.6 + (1.0 - v) * 0.6, 0.0, 1.0)
	return cols[1] if Vector2(fposmod(hx, 1.0) - 0.5, fposmod(hy, 1.0) - 0.5).length() < rd else cols[0]

## 43 · v_ancha, v_ancha_3
static func _fam_v_ancha(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var e43 := v - (0.98 - absf(u) * a)
	if absf(e43) < b:
		return cols[1]
	return acento if absf(e43) < b + 0.035 else cols[0]

## 44 · raglan, raglan_3
static func _fam_raglan(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
	var t44 := 0.5 + (1.0 - absf(u)) * a
	if absf(v - t44) < 0.025:
		return acento
	return cols[1] if v > t44 else cols[0]

## 45 · doble_faja, doble_faja_3
static func _fam_doble_faja(d: Array, cols: Array[Color], _u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	if absf(v - a) < b:
		return cols[1]
	return acento if absf(v - a + 0.2) < b else cols[0]

## 46 · franjas_asim, franjas_asim_3
static func _fam_franjas_asim(d: Array, cols: Array[Color], u: float, _v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
	if absf(u) < 0.03:
		return acento
	if u < 0.0:
		return cols[1] if fposmod((u + 1.0) * a, 1.0) < 0.5 else cols[0]
	return cols[0]

## 47 · pecho_zigzag, pecho_zigzag_3
static func _fam_pecho_zigzag(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var z47 := a + (absf(fposmod(u * b, 1.0) - 0.5) - 0.25) * 0.12
	if v > z47 + 0.02:
		return cols[1]
	return acento if v > z47 - 0.02 else cols[0]

## 48 · panal, panal_3
static func _fam_panal(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
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

## 49 · triangulos, triangulos_3
static func _fam_triangulos(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
	var tx := (u + 1.0) * 0.5 * a
	var ty := v * a
	var tri := fposmod(tx + fposmod(floorf(ty), 2.0) * 0.5, 1.0)
	if fposmod(ty, 1.0) < 1.0 - absf(tri - 0.5) * 2.0:
		return cols[1] if int(fposmod(floorf(tx + fposmod(floorf(ty), 2.0) * 0.5) + floorf(ty), 2.0)) == 0 else acento
	return cols[0]

## 50 · olas_v, olas_v_3
static func _fam_olas_v(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var s50 := (u + sin(v * b) * 0.06) * a * 0.5
	if fposmod(s50, 1.0) < 0.5:
		return cols[1] if int(fposmod(floorf(s50), 2.0)) == 0 else acento
	return cols[0]

## 51 · cebra, cebra_3
static func _fam_cebra(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var dd := float(d[6])
	var acento := _acento(d, cols)
	var z51 := sin(u * a * 3.0 + _ruido(u * 2.0 + 3.0, v * 2.5) * b + v * 2.0)
	if z51 > 0.3:
		return cols[1]
	return acento if z51 > 0.1 and dd > 0.5 else cols[0]

## 52 · rayas_diag, rayas_diag_3
static func _fam_rayas_diag(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var dd := float(d[6])
	var acento := _acento(d, cols)
	var s52 := fposmod((u + v * a) * b, 1.0)
	if s52 < 0.35:
		return cols[1]
	return acento if s52 < 0.45 and dd > 0.5 else cols[0]

## 53 · espiga, espiga_3
static func _fam_espiga(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var dd := float(d[6])
	var acento := _acento(d, cols)
	var cx53 := (u + 1.0) * 0.5 * a
	if fposmod(cx53, 1.0) < 0.06:
		return acento if dd > 0.5 else cols[1]
	var sg := 1.0 if int(fposmod(floorf(cx53), 2.0)) == 0 else -1.0
	return cols[1] if fposmod(v * a * 1.2 + sg * fposmod(cx53, 1.0), 1.0) < 0.5 else cols[0]

## 54 · codigo_barras, codigo_barras_3
static func _fam_codigo_barras(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
	var dv54 := absf(v - a)
	if absf(dv54 - 0.12) < 0.012:
		return acento
	if dv54 < 0.12:
		return cols[1] if _h21(floorf((u + 1.0) * 40.0), 3.0) < 0.5 else cols[0]
	return cols[0]

## 55 · circulo, circulo_3
static func _fam_circulo(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var r55 := Vector2(u, (v - 0.6) * 1.2).length()
	if absf(r55 - a) < b:
		return cols[1]
	return acento if absf(r55 - a - b * 2.2) < b * 0.5 else cols[0]

## 56 · cuello_v, cuello_v_3
static func _fam_cuello_v(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var e56 := v - (0.72 + absf(u) * a)
	if absf(e56) < b:
		return cols[1]
	return acento if absf(e56 + 0.1) < b * 0.6 else cols[0]

## 57 · costados_rayados, costados_rayados_3
static func _fam_costados_rayados(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var dd := float(d[6])
	if absf(u) > a:
		if fposmod(v * b, 1.0) < 0.5:
			return cols[1]
		return cols[2] if dd > 0.5 else cols[0]
	return cols[0]

## 58 · llamas, llamas_3
static func _fam_llamas(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var fl := a + _ruido(u * 4.0, v * 2.0 + 7.0) * 0.25 + sin(u * b) * 0.05
	if v < fl:
		return cols[1]
	return acento if v < fl + 0.05 else cols[0]

## 59 · mosaico, mosaico_3
static func _fam_mosaico(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
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

## 60 · rombo_central, rombo_central_3
static func _fam_rombo_central(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var acento := _acento(d, cols)
	var d60 := absf(u) + absf(v - 0.58) * 1.3
	if d60 < a:
		return cols[1]
	return acento if absf(d60 - a - 0.06) < 0.02 else cols[0]

## 61 · vichy, vichy_3
static func _fam_vichy(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var dd := float(d[6])
	var sx61 := fposmod((u + 1.0) * 0.5 * a, 1.0) < 0.5
	var sy61 := fposmod(v * a * 1.2, 1.0) < 0.5
	if sx61 and sy61:
		return cols[1]
	if sx61 or sy61:
		return cols[2] if dd > 0.5 else cols[0]
	return cols[0]

## 62 · estela, estela_3
static func _fam_estela(d: Array, cols: Array[Color], u: float, v: float) -> Color:
	var a := float(d[3])
	var b := float(d[4])
	var acento := _acento(d, cols)
	var w62 := fposmod((v - u * a * 0.3) * b, 1.0)
	var an := 0.12 * (u + 1.0)
	if w62 < an:
		return cols[1]
	return acento if w62 < an + 0.03 else cols[0]
