extends RefCounted
## [Capa 1/3 de `fachada_estadio.gd`] estilo_de, cara, _paleta, _tramos, _ejes, _libre … (+2)

## LAS FACHADAS DE VERDAD (16-10-2026). El informe interno lo dejó como «lo más
## débil hoy»: por fuera cada estadio era el muro liso de `StadiumBuilder` (una
## caja gris por tribuna) con las torres de las esquinas, y desde la ciudad o en
## los planos generales del partido las tribunas se leían como decorado.
##
## Esto VISTE ese muro sin tocarlo (ni el interior, ni el aforo, ni las bandejas):
## estructura (pilastras, pórticos, contrafuertes o pilares de acero),
## revestimiento (arcos, almohadas de membrana, lamas, celosía o chapa grecada)
## con los colores del club, escaleras y rampas exteriores, puertas con tornos y
## su rótulo, la cubierta vista desde fuera (canto, mástiles con tirantes o
## cerchas) y la iluminación de fachada.
##
## SEIS ESTILOS, y el estilo sale del perfil del estadio (material de fachada,
## bandejas, color y la semilla del club), así que el mismo estadio es idéntico
## en el partido, en la ciudad y en el visor:
##   clasico   ladrillo o piedra clara: pilastras, arcadas, cornisas y lonas.
##   membrana  pórticos blancos inclinados y almohadas de lona encendidas.
##   lamas     muro cortina con lamas verticales de los colores del club.
##   celosia   malla de rombos de acero sobre un fondo oscuro.
##   porticos  hormigón de los setenta: contrafuertes y rampas en zigzag.
##   barrio    pilares de acero, cruces de San Andrés y chapa grecada.
##
## BARATO: toda la geometría se funde en DOS mallas (lo grande y el detalle de
## calle, que se apaga a `RANGO_DETALLE`), una superficie por material: unas
## ocho llamadas de dibujo para todo el recinto, más los rótulos de las puertas.

const ESTILOS := ["clasico", "membrana", "lamas", "celosia", "porticos", "barrio"]
const RANGO_DETALLE := 150.0
const RANGO_ROTULO := 120.0

## Las superficies de las dos mallas. El orden no importa; la clave sí.
const K_ESTRUCTURA := "estructura"
const K_REVEST := "revest"
const K_ACENTO := "acento"
const K_VIDRIO := "vidrio"
const K_LUZ := "luz"
const K_METAL := "metal"
const K_PANEL := "panel"

## ---------------------------------------------------------------------------
## LA MALLA FUNDIDA: una SurfaceTool por material
## ---------------------------------------------------------------------------
class _Malla:
	var _st := {}

	func _sup(k: String) -> SurfaceTool:
		if not _st.has(k):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_st[k] = st
		return _st[k]

	func cerrar(material_de: Callable) -> ArrayMesh:
		if _st.is_empty():
			return null
		var am := ArrayMesh.new()
		var claves: Array = _st.keys()
		claves.sort()
		for k: String in claves:
			var st: SurfaceTool = _st[k]
			st.set_material(material_de.call(k))
			st.commit(am)
		return am

	func _p(c: Dictionary, s: float, y: float, w: float) -> Vector3:
		return (c["o"] as Vector3) + (c["u"] as Vector3) * s + Vector3.UP * y + (c["n"] as Vector3) * w

	## Un cuadrilátero plano a-b-c-d (convexo). Godot dibuja la cara de delante
	## en sentido HORARIO: si con este orden la cara mira contra `fuera`, se da
	## la vuelta. `fuera` = ZERO deja el orden tal cual.
	func quad(k: String, a: Vector3, b: Vector3, cc: Vector3, d: Vector3, fuera := Vector3.ZERO) -> void:
		var nrm := -((b - a).cross(cc - a))
		if nrm.length_squared() < 1e-12:
			return
		nrm = nrm.normalized()
		var vuelta := fuera != Vector3.ZERO and nrm.dot(fuera) < 0.0
		if vuelta:
			nrm = -nrm
		## d == a: es un triángulo (los abanicos de los arcos).
		if d.is_equal_approx(a):
			tri(k, [a, cc, b] if vuelta else [a, b, cc], nrm)
			return
		if vuelta:
			tri(k, [a, d, cc], nrm)
			tri(k, [a, cc, b], nrm)
		else:
			tri(k, [a, b, cc], nrm)
			tri(k, [a, cc, d], nrm)

	## Un triángulo ya ordenado, con su normal (o las de cada vértice).
	func tri(k: String, v: Array, nrm: Variant) -> void:
		var st := _sup(k)
		var n0: Vector3 = nrm if nrm is Vector3 else (nrm as Array)[0]
		## UV en metros (las texturas de `Texturas` escalan por metro).
		var eje_u := Vector3.UP.cross(n0)
		if eje_u.length_squared() < 0.01:
			eje_u = Vector3.RIGHT
		eje_u = eje_u.normalized()
		var eje_v := n0.cross(eje_u).normalized()
		for i in 3:
			var p: Vector3 = v[i]
			st.set_normal(nrm if nrm is Vector3 else (nrm as Array)[i])
			st.set_uv(Vector2(p.dot(eje_u), -p.dot(eje_v)) * 0.25)
			st.add_vertex(p)

	## Un prisma de 8 esquinas: [0..3] abajo y [4..7] arriba, en el mismo orden.
	func prisma(k: String, e: Array) -> void:
		## Las seis caras con la normal hacia fuera (el orden lo da el centro).
		var centro := Vector3.ZERO
		for v: Vector3 in e:
			centro += v
		centro /= 8.0
		var caras := [[0, 1, 2, 3], [7, 6, 5, 4], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]
		for f: Array in caras:
			var a: Vector3 = e[f[0]]
			var b: Vector3 = e[f[1]]
			var cc: Vector3 = e[f[2]]
			var d: Vector3 = e[f[3]]
			quad(k, a, b, cc, d, (a + b + cc + d) * 0.25 - centro)

	## Caja alineada con la cara: [s0,s1] a lo largo, [y0,y1] de alto, [w0,w1] hacia fuera.
	func bloque(c: Dictionary, k: String, s0: float, s1: float, y0: float, y1: float, w0: float, w1: float) -> void:
		prisma(k, [_p(c, s0, y0, w0), _p(c, s1, y0, w0), _p(c, s1, y0, w1), _p(c, s0, y0, w1),
			_p(c, s0, y1, w0), _p(c, s1, y1, w0), _p(c, s1, y1, w1), _p(c, s0, y1, w1)])

	## Contrafuerte: abajo sale `w_pie`, arriba `w_cima`.
	func cuna(c: Dictionary, k: String, s0: float, s1: float, y0: float, y1: float, w_pie: float, w_cima: float) -> void:
		prisma(k, [_p(c, s0, y0, 0.0), _p(c, s1, y0, 0.0), _p(c, s1, y0, w_pie), _p(c, s0, y0, w_pie),
			_p(c, s0, y1, 0.0), _p(c, s1, y1, 0.0), _p(c, s1, y1, w_cima), _p(c, s0, y1, w_cima)])

	## Barra entre dos puntos en coordenadas de la cara (s, y, w).
	## `ancho` va en el plano de la cara; `canto`, hacia fuera.
	func barra(c: Dictionary, k: String, a_l: Vector3, b_l: Vector3, ancho: float, canto: float) -> void:
		var a := _p(c, a_l.x, a_l.y, a_l.z)
		var b := _p(c, b_l.x, b_l.y, b_l.z)
		var eje := b - a
		if eje.length() < 0.05:
			return
		var dir := eje.normalized()
		var n_c: Vector3 = c["n"]
		## Lado 1: perpendicular a la barra dentro del plano de la cara; si la
		## barra va hacia fuera (tirantes, vigas), se usa la vertical/el largo.
		var lado := dir.cross(n_c)
		if lado.length() < 0.2:
			lado = dir.cross(Vector3.UP)
			if lado.length() < 0.2:
				lado = dir.cross(c["u"] as Vector3)
		lado = lado.normalized()
		var arriba := lado.cross(dir).normalized()
		var la := lado * ancho * 0.5
		var lb := arriba * canto * 0.5
		prisma(k, [a - la - lb, a + la - lb, a + la + lb, a - la + lb,
			b - la - lb, b + la - lb, b + la + lb, b - la + lb])

	## Arco plano (hueco oscuro): rectángulo y medio punto encima.
	func arco(c: Dictionary, k: String, s_c: float, ancho: float, y0: float, alto: float, w: float) -> void:
		var r := ancho * 0.5
		var y_arr := y0 + maxf(alto - r, 0.2)
		var fuera: Vector3 = c["n"]
		quad(k, _p(c, s_c - r, y0, w), _p(c, s_c + r, y0, w), _p(c, s_c + r, y_arr, w), _p(c, s_c - r, y_arr, w), fuera)
		var segs := 8
		var centro := _p(c, s_c, y_arr, w)
		for i in segs:
			var a0 := PI * float(i) / float(segs)
			var a1 := PI * float(i + 1) / float(segs)
			var p0 := _p(c, s_c + r * cos(a0), y_arr + r * sin(a0), w)
			var p1 := _p(c, s_c + r * cos(a1), y_arr + r * sin(a1), w)
			quad(k, centro, p0, p1, centro, fuera)

	## El marco de piedra del arco: dovelas como barras cortas siguiendo la curva.
	func arco_marco(c: Dictionary, k: String, s_c: float, ancho: float, y0: float, alto: float,
			grosor: float, w0: float, w1: float) -> void:
		var r := ancho * 0.5 + grosor * 0.5
		var y_arr := y0 + maxf(alto - ancho * 0.5, 0.2)
		var segs := 6
		var wm := (w0 + w1) * 0.5
		for i in segs:
			var a0 := PI * float(i) / float(segs)
			var a1 := PI * float(i + 1) / float(segs)
			barra(c, k, Vector3(s_c + r * cos(a0), y_arr + r * sin(a0), wm),
				Vector3(s_c + r * cos(a1), y_arr + r * sin(a1), wm), grosor, w1 - w0)

	## Almohada de lona entre dos pórticos: abombada hacia fuera.
	func almohada(c: Dictionary, k: String, s0: float, s1: float, y0: float, y1: float,
			w_pie: float, w_cima: float, bombeo: float) -> void:
		var ns := 6
		var ny := 6
		var pts := []
		for j in ny + 1:
			var fila := []
			var ty := float(j) / float(ny)
			for i in ns + 1:
				var ts := float(i) / float(ns)
				var w := lerpf(w_pie, w_cima, ty) + bombeo * sin(PI * ts) * sin(PI * ty)
				fila.append(_p(c, lerpf(s0, s1, ts), lerpf(y0, y1, ty), w))
			pts.append(fila)
		var fuera: Vector3 = c["n"]
		for j in ny:
			for i in ns:
				quad(k, pts[j][i], pts[j][i + 1], pts[j + 1][i + 1], pts[j + 1][i], fuera)

	## Chapa grecada: ondas trapezoidales verticales.
	func chapa(c: Dictionary, k: String, s0: float, s1: float, y0: float, y1: float,
			w: float, prof: float, paso: float) -> void:
		var n := maxi(1, int((s1 - s0) / paso))
		var nc: Vector3 = c["n"]
		for i in n:
			var a := lerpf(s0, s1, float(i) / float(n))
			var b := lerpf(s0, s1, float(i + 1) / float(n))
			var m := (a + b) * 0.5
			## Dos faldones: subida a la cresta y bajada.
			quad(k, _p(c, a, y0, w), _p(c, m, y0, w + prof), _p(c, m, y1, w + prof), _p(c, a, y1, w), nc)
			quad(k, _p(c, m, y0, w + prof), _p(c, b, y0, w), _p(c, b, y1, w), _p(c, m, y1, w + prof), nc)

## ---------------------------------------------------------------------------
## EL ESTILO
## ---------------------------------------------------------------------------
## `niveles`: las bandejas que de verdad se dibujan (`StadiumBuilder.niveles_de`).
static func estilo_de(est: Dictionary, seed_val: int, niveles: int = -1) -> String:
	var forzado := str(est.get("fachadaEstilo", ""))
	if forzado in ESTILOS:
		return forzado
	var niv := niveles if niveles > 0 else int(est.get("niveles", 2))
	match str(est.get("fachada", "hormigon")):
		"ladrillo":
			return "clasico"
		"membrana":
			return "membrana"
		"vidrio":
			return "lamas"
		"metal":
			return "celosia" if niv >= 2 else "barrio"
	## Hormigón (el de casi todos los rivales): manda el tamaño, luego el color
	## que se haya elegido y por último la semilla del club.
	if niv <= 1:
		return "barrio"
	var col := str(est.get("fachadaCol", ""))
	if col != "":
		var c := Color.from_string(col, Color(0.4, 0.4, 0.4))
		return "clasico" if c.get_luminance() > 0.55 else "porticos"
	var h := absi(("fachada:%d" % seed_val).hash())
	var bolsa := ["porticos", "porticos", "porticos", "clasico", "clasico", "lamas", "lamas", "celosia", "celosia", "membrana"]
	if niv >= 4:
		bolsa = ["lamas", "lamas", "membrana", "membrana", "celosia", "celosia", "porticos", "clasico"]
	return bolsa[h % bolsa.size()]

## ---------------------------------------------------------------------------
## LAS CARAS
## ---------------------------------------------------------------------------
## Una cara es un paño vertical del exterior: `o` es su pie izquierdo visto desde
## fuera, `u` corre a lo largo, `n` mira a la calle. `fondo` es lo que mide la
## tribuna (con el vuelo del techo) hacia el campo, para la cubierta.
static func cara(centro_pie: Vector3, n: Vector3, largo: float, alto: float, tipo: String,
		techo: bool, fondo: float, niveles: int, excluir: Array = []) -> Dictionary:
	var u := Vector3.UP.cross(n).normalized()
	return {"o": centro_pie - u * largo / 2.0, "u": u, "n": n.normalized(), "L": largo, "H": alto,
		"tipo": tipo, "techo": techo, "fondo": fondo, "niv": niveles, "excluir": excluir}

## Los materiales de cada estilo. Pintura y no metal pulido: el metal sin cielo
## que reflejar sale negro (ya pasó con las taquillas).
static func _paleta(est: Dictionary, estilo: String, h: int) -> Dictionary:
	var c1 := StadiumBuilder._c(est.get("asiento1"), "#2b6b45")
	var c2 := StadiumBuilder._c(est.get("asiento2"), "#ffffff")
	var fcol := str(est.get("fachadaCol", ""))
	## Un club de negro no puede tener la fachada como un agujero.
	if c1.get_luminance() < 0.12:
		c1 = c1.lerp(Color(0.5, 0.52, 0.55), 0.35)
	if absf(c1.get_luminance() - c2.get_luminance()) < 0.08:
		c2 = Color(0.92, 0.92, 0.9) if c1.get_luminance() < 0.5 else Color(0.12, 0.13, 0.15)
	var estructura: Color
	var revest: Color = c1
	var acento: Color = c2
	var luz: Color = c1.lerp(Color.WHITE, 0.35)
	match estilo:
		"clasico":
			## Piedra clara para pilastras y cornisas, sobre el ladrillo o el
			## hormigón del muro.
			estructura = Color(0.88, 0.78, 0.62)
			luz = Color(1.0, 0.78, 0.48)
		"membrana":
			estructura = Color(0.93, 0.94, 0.95)
			revest = StadiumBuilder._c(fcol, "#f1f1ec") if fcol != "" else Color(0.95, 0.95, 0.92)
		"lamas":
			estructura = Color(0.88, 0.89, 0.9)
		"celosia":
			estructura = Color(0.26, 0.28, 0.31)
			if fcol != "":
				revest = StadiumBuilder._c(fcol, "#c9a227")
		"porticos":
			estructura = StadiumBuilder._c(fcol, "#8d8f8f") if fcol != "" else Color(0.62, 0.62, 0.6)
			estructura = estructura.lerp(Color(0.78, 0.77, 0.73), 0.5)
		_:  # barrio
			estructura = Color(0.36, 0.38, 0.41) if h % 2 == 0 else c2.lerp(Color(0.4, 0.42, 0.45), 0.6)
			revest = c1.lerp(Color(0.72, 0.73, 0.74), 0.25)
	return {"estructura": estructura, "revest": revest, "acento": acento, "luz": luz,
		"noche": str(est.get("clima", "noche")), "estilo": estilo}

## Recorre [a, b] saltándose los huecos de `excluir` (el vestuario del túnel).
static func _tramos(c: Dictionary, a: float, b: float, f: Callable) -> void:
	var trozos: Array = [Vector2(a, b)]
	for ex: Vector2 in c["excluir"]:
		var nuevos: Array = []
		for t: Vector2 in trozos:
			if ex.y <= t.x or ex.x >= t.y:
				nuevos.append(t)
				continue
			if ex.x > t.x + 0.05:
				nuevos.append(Vector2(t.x, ex.x))
			if t.y > ex.y + 0.05:
				nuevos.append(Vector2(ex.y, t.y))
		trozos = nuevos
	for t: Vector2 in trozos:
		if t.y - t.x > 0.3:
			f.call(t.x, t.y)

## Las posiciones de los ejes estructurales (vanos iguales de ~`paso` m).
static func _ejes(L: float, paso: float) -> Array:
	var nb := maxi(1, roundi(L / paso))
	var sal: Array = []
	for i in nb + 1:
		sal.append(L * float(i) / float(nb))
	return sal

static func _libre(c: Dictionary, a: float, b: float) -> bool:
	if a < 0.0 or b > float(c["L"]):
		return false
	for ex: Vector2 in c["excluir"]:
		if not (ex.y <= a or ex.x >= b):
			return false
	return true

## --- clásico: pilastras, arcos, cornisas y lonas -----------------------------
static func _clasico(ctx: Dictionary, c: Dictionary, pisos: Array) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var paso := 5.6 + float(int(ctx["h"]) % 4) * 0.45
	var ejes := _ejes(L, paso)
	var y_arcada: float = (pisos[0] - 0.9) if not pisos.is_empty() else minf(H * 0.55, 6.0)
	y_arcada = clampf(y_arcada, 3.4, 7.5)
	for i in ejes.size():
		var s: float = ejes[i]
		if _libre(c, s - 0.5, s + 0.5):
			g.bloque(c, K_ESTRUCTURA, s - 0.5, s + 0.5, 0.0, H - 0.9, 0.0, 0.55)
			## Farol en cada pilastra.
			(ctx["detalle"] as _Malla).bloque(c, K_LUZ, s - 0.16, s + 0.16, y_arcada + 0.5, y_arcada + 0.95, 0.55, 0.8)
		if i == ejes.size() - 1:
			break
		var a: float = s + 0.5
		var b: float = ejes[i + 1] - 0.5
		if not _libre(c, a, b):
			continue
		var cx := (a + b) * 0.5
		var ancho := b - a
		## La arcada de la calle.
		g.arco(c, K_VIDRIO, cx, ancho * 0.78, 0.7, y_arcada - 0.7, 0.12)
		g.arco_marco(c, K_ESTRUCTURA, cx, ancho * 0.78, 0.7, y_arcada - 0.7, 0.32, 0.12, 0.3)
		## Ventanas en arco en cada piso de arriba.
		var bandas: Array = [y_arcada + 0.6]
		bandas.append_array(pisos.filter(func(y: float) -> bool: return y > y_arcada + 2.0))
		bandas.append(H - 1.0)
		for k in bandas.size() - 1:
			var y0: float = bandas[k] + 0.7
			var y1: float = bandas[k + 1] - 0.5
			if y1 - y0 > 1.6:
				g.arco(c, K_VIDRIO, cx, ancho * 0.42, y0, y1 - y0, 0.12)
		## Lonas del club cada tres vanos.
		if i % 3 == 1 and H > 10.0:
			g.bloque(c, K_REVEST, cx - ancho * 0.3, cx + ancho * 0.3, y_arcada + 1.2, H - 1.6, 0.6, 0.66)
			g.bloque(c, K_ACENTO, cx - ancho * 0.07, cx + ancho * 0.07, y_arcada + 1.2, H - 1.6, 0.66, 0.7)
	## Cornisas: en cada piso, sobre la arcada y la de coronación.
	var cornisas: Array = [y_arcada + 0.3]
	cornisas.append_array(pisos)
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		for y: float in cornisas:
			if y < H - 2.0:
				g.bloque(c, K_ESTRUCTURA, a, b, y - 0.22, y + 0.22, 0.0, 0.72)
		g.bloque(c, K_ESTRUCTURA, a, b, H - 1.1, H - 0.2, 0.0, 0.95)
		g.bloque(c, K_ESTRUCTURA, a, b, H - 0.2, H + 0.25, 0.0, 0.6)
		(ctx["detalle"] as _Malla).bloque(c, K_LUZ, a, b, H - 1.25, H - 1.1, 0.75, 0.9))

## --- membrana: pórticos inclinados y almohadas de lona -----------------------
static func _membrana(ctx: Dictionary, c: Dictionary) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var paso := 8.0 + float(int(ctx["h"]) % 3)
	var ejes := _ejes(L, paso)
	var y_base := 4.6
	var vuelo := 1.8 if c["tipo"] == "tribuna" else 1.2
	## El vestíbulo acristalado a pie de calle.
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.bloque(c, K_VIDRIO, a, b, 0.7, y_base - 0.3, 0.0, 0.32)
		g.bloque(c, K_ESTRUCTURA, a, b, y_base - 0.3, y_base, 0.0, 1.0)
		g.bloque(c, K_LUZ, a, b, y_base - 0.42, y_base - 0.3, 0.6, 0.95))
	for i in ejes.size():
		var s: float = ejes[i]
		if not _libre(c, s - 0.4, s + 0.4):
			continue
		## El pórtico se abre hacia fuera al subir.
		g.barra(c, K_ESTRUCTURA, Vector3(s, 0.0, 0.5), Vector3(s, H + 1.4, vuelo + 0.4), 0.55, 0.75)
		if i == ejes.size() - 1:
			break
		var a: float = s + 0.35
		var b: float = ejes[i + 1] - 0.35
		if not _libre(c, a, b) or H - y_base < 3.0:
			continue
		g.almohada(c, K_REVEST, a, b, y_base + 0.2, H + 1.0, 0.55, vuelo + 0.2, minf(0.9, (b - a) * 0.12))
	## El aro de luz de la coronación.
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.bloque(c, K_ESTRUCTURA, a, b, H + 1.0, H + 1.45, 0.0, vuelo + 0.6)
		g.bloque(c, K_LUZ, a, b, H + 0.85, H + 1.0, vuelo + 0.2, vuelo + 0.55))
