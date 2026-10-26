extends "res://visor/fachada_estadio_p1.gd"
## [Capa 2/3 de `fachada_estadio.gd`] _lamas, _celosia, _porticos, _barrio, _torre_esquina, _punto … (+5)

## --- lamas: muro cortina y lamas de los colores del club ---------------------
static func _lamas(ctx: Dictionary, c: Dictionary, pisos: Array) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var h: int = ctx["h"]
	var patron: int = (h >> 3) % 3   ## 0 degradado, 1 franjas, 2 píxel
	var y_lob := 4.4
	var cortes: Array = [y_lob]
	cortes.append_array(pisos.filter(func(y: float) -> bool: return y > y_lob + 2.0))
	cortes.append(H - 0.3)
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.bloque(c, K_VIDRIO, a, b, 0.7, H - 0.3, 0.0, 0.25)
		for y: float in cortes:
			g.bloque(c, K_ESTRUCTURA, a, b, y - 0.3, y + 0.3, 0.0, 1.3)
			(ctx["detalle"] as _Malla).bloque(c, K_LUZ, a, b, y + 0.22, y + 0.3, 1.3, 1.36))
	## Columnas del vestíbulo.
	for s: float in _ejes(L, 7.5):
		if _libre(c, s - 0.35, s + 0.35):
			g.bloque(c, K_ESTRUCTURA, s - 0.35, s + 0.35, 0.0, y_lob - 0.3, 0.25, 0.95)
	var paso := 1.3
	var n := int(L / paso)
	for k in cortes.size() - 1:
		var y0: float = cortes[k] + 0.3
		var y1: float = cortes[k + 1] - 0.3
		if y1 - y0 < 0.8:
			continue
		for i in n:
			var s := (float(i) + 0.5) * L / float(n)
			if not _libre(c, s - 0.15, s + 0.15):
				continue
			var t := s / L
			var clave := K_REVEST
			match patron:
				0:
					var r := absf(t - 0.5) * 2.0
					var dado := float(absi(("lama:%d:%d:%d" % [h, i, k]).hash()) % 1000) / 1000.0
					clave = K_REVEST if dado < r * 0.9 + 0.1 else (K_ACENTO if dado < r + 0.55 else K_ESTRUCTURA)
				1:
					var grupo := int(i / 5.0) % 3
					clave = [K_REVEST, K_ESTRUCTURA, K_ACENTO][grupo]
				_:
					var dado2 := absi(("pix:%d:%d:%d" % [h, i, k]).hash()) % 7
					clave = K_ACENTO if dado2 == 0 else (K_ESTRUCTURA if dado2 < 3 else K_REVEST)
			g.bloque(c, clave, s - 0.11, s + 0.11, y0, y1, 0.3, 1.15)

## --- celosía: rombos de acero sobre fondo oscuro -----------------------------
static func _celosia(ctx: Dictionary, c: Dictionary) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var y0 := 4.6
	var y1 := H - 0.4
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.bloque(c, K_VIDRIO, a, b, 0.7, H - 0.3, 0.0, 0.25)
		g.bloque(c, K_ESTRUCTURA, a, b, y0 - 0.45, y0, 0.0, 1.2)
		g.bloque(c, K_ESTRUCTURA, a, b, y1, y1 + 0.5, 0.0, 1.2)
		g.bloque(c, K_LUZ, a, b, y0 - 0.58, y0 - 0.45, 0.7, 1.15))
	for s: float in _ejes(L, 7.5):
		if _libre(c, s - 0.35, s + 0.35):
			g.bloque(c, K_ESTRUCTURA, s - 0.35, s + 0.35, 0.0, y0 - 0.45, 0.25, 0.95)
	if y1 - y0 < 2.0:
		return
	## Las diagonales a ±45°: cada una se recorta al paño y a los huecos.
	var d := 3.2 + float(int(ctx["h"]) % 3) * 0.4
	var alto := y1 - y0
	var k0 := int(floor(-alto / d)) - 1
	var k1 := int(ceil(L / d)) + 1
	for k in range(k0, k1 + 1):
		for sentido: float in [1.0, -1.0]:
			## s = s_ini + sentido*(y - y0); se recorta a [0, L].
			var s_ini: float = float(k) * d if sentido > 0.0 else float(k) * d + alto
			var ta := 0.0
			var tb := alto
			## Recorte contra 0 y L.
			var sa: float = s_ini
			var sb: float = s_ini + sentido * alto
			if sentido > 0.0:
				ta = maxf(ta, -s_ini)
				tb = minf(tb, L - s_ini)
			else:
				ta = maxf(ta, s_ini - L)
				tb = minf(tb, s_ini)
			if tb - ta < 0.4:
				continue
			sa = s_ini + sentido * ta
			sb = s_ini + sentido * tb
			if not _libre(c, minf(sa, sb), maxf(sa, sb)):
				continue
			g.barra(c, K_REVEST, Vector3(sa, y0 + ta, 0.75), Vector3(sb, y0 + tb, 0.75), 0.32, 0.4)

## --- pórticos: hormigón de los setenta ---------------------------------------
static func _porticos(ctx: Dictionary, c: Dictionary, pisos: Array) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var paso := 9.0 + float(int(ctx["h"]) % 3) * 0.75
	var ejes := _ejes(L, paso)
	var pie := clampf(H * 0.16, 1.6, 4.2) if c["tipo"] == "tribuna" else 1.2
	for s: float in ejes:
		if _libre(c, s - 0.7, s + 0.7):
			g.cuna(c, K_ESTRUCTURA, s - 0.65, s + 0.65, 0.0, H + 0.2, pie, 0.7)
			(ctx["detalle"] as _Malla).bloque(c, K_LUZ, s - 0.25, s + 0.25, H - 1.9, H - 1.6, 0.7, 1.0)
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		for y: float in pisos:
			g.bloque(c, K_ESTRUCTURA, a, b, y - 0.45, y + 0.45, 0.0, 1.0)
		g.bloque(c, K_REVEST, a, b, H - 1.1, H + 0.2, 0.0, 0.9)
		g.bloque(c, K_ACENTO, a, b, H - 1.3, H - 1.1, 0.0, 0.92))
	## PANELES PREFABRICADOS (16-10-2026): entre contrafuertes se veía el muro
	## liso de la tribuna (el material oscuro de las gradas) y con la luz de la
	## tarde la fachada entera era un agujero marrón. Ahora cada vano se cierra
	## con paneles de hormigón claro, con una banda de ventanas bajo cada forjado.
	var bandas: Array = [0.7]
	for y: float in pisos:
		bandas.append(y)
	bandas.append(H - 1.3)
	for i in ejes.size() - 1:
		var a: float = ejes[i] + 0.65
		var b: float = ejes[i + 1] - 0.65
		_tramos(c, a, b, func(a2: float, b2: float) -> void:
			g.bloque(c, K_PANEL, a2, b2, 0.7, H - 1.3, 0.0, 0.22)
			for k in range(1, bandas.size() - 1):
				var yv: float = bandas[k]
				if yv - 2.0 > float(bandas[k - 1]) + 0.6:
					g.bloque(c, K_VIDRIO, a2 + 0.5, b2 - 0.5, yv - 1.75, yv - 0.6, 0.0, 0.3))
	## Las puertas van al centro de un vano: entre dos contrafuertes y nunca
	## detrás de uno (antes un pilar tapaba medio rótulo «PUERTA 6»).
	var vanos: Array = []
	for i in ejes.size() - 1:
		vanos.append(Vector2(float(ejes[i]), float(ejes[i + 1])))
	ctx["vanos"] = vanos
	if c["tipo"] != "tribuna" or H < 9.0:
		return
	## Las rampas en zigzag entre contrafuertes, en vanos alternos.
	var subida := 3.6
	for i in range(1, ejes.size() - 1, 3):
		var a: float = ejes[i] + 0.8
		var b: float = ejes[i + 1] - 0.8
		if not _libre(c, a, b):
			continue
		(ctx["vanos"] as Array).erase(Vector2(float(ejes[i]), float(ejes[i + 1])))
		var y := 0.6
		var ida := true
		while y + subida < H - 1.6:
			var s0: float = a if ida else b
			var s1: float = b if ida else a
			g.barra(c, K_ESTRUCTURA, Vector3(s0, y, 1.6), Vector3(s1, y + subida, 1.6), 1.0, 2.4)
			(ctx["detalle"] as _Malla).barra(c, K_ACENTO, Vector3(s0, y + 1.05, 2.75), Vector3(s1, y + subida + 1.05, 2.75), 0.12, 0.12)
			y += subida
			ida = not ida
			## Rellano.
			g.bloque(c, K_ESTRUCTURA, s1 - 1.0, s1 + 1.0, y - 0.25, y + 0.25, 0.4, 2.8)

## --- barrio: acero, cruces y chapa -------------------------------------------
static func _barrio(ctx: Dictionary, c: Dictionary) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var ejes := _ejes(L, 6.0)
	var y_chapa := minf(2.8, H * 0.4)
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.chapa(c, K_REVEST, a, b, y_chapa, H + 0.3, 0.32, 0.18, 0.3)
		g.bloque(c, K_ESTRUCTURA, a, b, y_chapa - 0.25, y_chapa, 0.0, 0.62)
		g.bloque(c, K_ESTRUCTURA, a, b, H + 0.3, H + 0.65, 0.0, 0.62))
	for i in ejes.size():
		var s: float = ejes[i]
		if _libre(c, s - 0.25, s + 0.25):
			g.bloque(c, K_ESTRUCTURA, s - 0.22, s + 0.22, 0.0, H + 0.65, 0.0, 0.6)
			if i % 2 == 0:
				(ctx["detalle"] as _Malla).bloque(c, K_LUZ, s - 0.2, s + 0.2, y_chapa - 0.6, y_chapa - 0.35, 0.6, 0.9)
		if i < ejes.size() - 1 and i % 2 == 1 and _libre(c, s, ejes[i + 1]):
			var s2: float = ejes[i + 1]
			g.barra(c, K_ESTRUCTURA, Vector3(s + 0.2, y_chapa, 0.68), Vector3(s2 - 0.2, H + 0.2, 0.68), 0.14, 0.1)
			g.barra(c, K_ESTRUCTURA, Vector3(s2 - 0.2, y_chapa, 0.68), Vector3(s + 0.2, H + 0.2, 0.68), 0.14, 0.1)

## --- torres de las esquinas: núcleos de escalera -----------------------------
static func _torre_esquina(ctx: Dictionary, c: Dictionary) -> void:
	var estilo: String = ctx["estilo"]
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	if estilo in ["membrana", "lamas", "celosia"]:
		## Una raja de luz vertical: la escalera encendida tras la piel.
		g.bloque(c, K_LUZ, L * 0.5 - 0.3, L * 0.5 + 0.3, 1.2, H - 1.5, 1.25, 1.35)
		return
	## La escalera se lee en la fachada: ventanas que suben en diagonal.
	var n := int((H - 3.0) / 2.6)
	for k in n:
		var t := float(k) / maxf(1.0, float(n - 1))
		var s := lerpf(L * 0.22, L * 0.78, t if int(k / 4.0) % 2 == 0 else 1.0 - t)
		var y := 2.2 + float(k) * 2.6
		g.bloque(c, K_VIDRIO, s - 0.7, s + 0.7, y, y + 1.3, 0.0, 0.62)
		g.bloque(c, K_ESTRUCTURA, s - 0.85, s + 0.85, y - 0.15, y, 0.0, 0.75)

## LA JUNTA DE LA TORRE CON LA TRIBUNA (25-10-2026, visto con `captura_exterior`): el
## tramo de los costados de la torre que se junta con la tribuna (`excluir`) se dejaba
## sin vestir para que su piel no chocara con la de la tribuna, y desde la calle era un
## paño negro de 5 m de alto a alto: el muro desnudo. Ahora lleva un chapado plano (casi
## sin vuelo, no choca con nada) con las líneas de los forjados.
static func _tapar_junta(ctx: Dictionary, c: Dictionary, pisos: Array) -> void:
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	for ex: Vector2 in c["excluir"]:
		var a := clampf(ex.x, 0.0, L)
		var b := clampf(ex.y, 0.0, L)
		if b - a < 0.3:
			continue
		g.bloque(c, K_ESTRUCTURA, a, b, 0.0, H + 0.3, 0.0, 0.12)
		for y: float in [0.7] + pisos + [H - 0.2]:
			g.bloque(c, K_ACENTO, a, b, y - 0.12, y + 0.12, 0.12, 0.2)

static func _punto(c: Dictionary, s: float, y: float, w: float) -> Vector3:
	return (c["o"] as Vector3) + (c["u"] as Vector3) * s + Vector3.UP * y + (c["n"] as Vector3) * w

## El escudo del club en la fachada, sobre un paño liso para que no flote.
static func _escudo_fachada(ctx: Dictionary, c: Dictionary) -> void:
	var tex: Texture2D = ctx["escudo"]
	if tex == null or bool(ctx["escudo_puesto"]) or not bool(c.get("escudo", false)):
		return
	var L: float = c["L"]
	var H: float = c["H"]
	var tam := clampf(H * 0.4, 3.0, 9.0)
	var s := float(c.get("escudo_s", L * 0.5))
	if not _libre(c, s - tam * 0.6, s + tam * 0.6):
		return
	var y := clampf(H * 0.55, tam * 0.5 + 4.8, H - tam * 0.5 - 1.0)
	if y - tam * 0.5 < 4.5:
		return
	ctx["escudo_puesto"] = true
	var prof := 2.8
	var g: _Malla = ctx["grande"]
	g.bloque(c, K_ACENTO, s - tam * 0.62, s + tam * 0.62, y - tam * 0.62, y + tam * 0.62, 0.0, prof)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := MeshInstance3D.new()
	q.name = "EscudoFachada"
	var qm := QuadMesh.new()
	qm.size = Vector2(tam, tam)
	q.mesh = qm
	q.material_override = mat
	var n_v: Vector3 = c["n"]
	q.position = _punto(c, s, y, prof + 0.04)
	q.rotation.y = atan2(n_v.x, n_v.z)
	(ctx["nodo"] as Node3D).add_child(q)

## ---------------------------------------------------------------------------
## LO COMÚN: PUERTAS, ESCALERAS, CUBIERTA Y ESCUDO
## ---------------------------------------------------------------------------
static func _puertas(ctx: Dictionary, c: Dictionary) -> int:
	var L: float = c["L"]
	var g: _Malla = ctx["grande"]
	var d: _Malla = ctx["detalle"]
	var n := clampi(int(L / 34.0), 1, 3)
	for i in n:
		var s := L * (float(i) + 0.5) / float(n)
		## Si cae en un hueco, se corre hasta encontrar sitio.
		var tope := 0
		while not _libre(c, s - 3.2, s + 3.2) and tope < 12:
			s += 4.0 if s < L * 0.5 else -4.0
			tope += 1
		var vanos: Array = ctx.get("vanos", [])
		if not vanos.is_empty():
			## Al centro del vano libre más cercano (y lo gasta).
			var mejor := -1
			for k in vanos.size():
				var v: Vector2 = vanos[k]
				var m := (v.x + v.y) * 0.5
				if v.y - v.x < 7.2 or not _libre(c, m - 3.2, m + 3.2):
					continue
				if mejor < 0 or absf(m - s) < absf((vanos[mejor].x + vanos[mejor].y) * 0.5 - s):
					mejor = k
			if mejor >= 0:
				s = (vanos[mejor].x + vanos[mejor].y) * 0.5
				vanos.remove_at(mejor)
		if not _libre(c, s - 3.2, s + 3.2):
			continue
		ctx["puerta"] = int(ctx["puerta"]) + 1
		## Hueco oscuro, marco y marquesina con el color del club.
		g.bloque(c, K_VIDRIO, s - 2.2, s + 2.2, 0.0, 3.4, 0.0, 0.45)
		g.bloque(c, K_ESTRUCTURA, s - 2.6, s - 2.2, 0.0, 3.8, 0.0, 0.9)
		g.bloque(c, K_ESTRUCTURA, s + 2.2, s + 2.6, 0.0, 3.8, 0.0, 0.9)
		g.bloque(c, K_ACENTO, s - 3.0, s + 3.0, 3.8, 4.15, 0.0, 2.6)
		g.bloque(c, K_LUZ, s - 2.8, s + 2.8, 3.72, 3.8, 1.4, 2.4)
		## La fila de tornos, con sus brazos.
		for k in 5:
			var st := s - 1.8 + float(k) * 0.9
			d.bloque(c, K_METAL, st - 0.12, st + 0.12, 0.0, 1.0, 0.9, 1.6)
			if k < 4:
				d.bloque(c, K_METAL, st + 0.12, st + 0.6, 0.86, 0.9, 1.22, 1.28)
		## Valla de colas delante.
		d.bloque(c, K_METAL, s - 3.0, s - 2.95, 0.0, 1.0, 1.6, 5.0)
		d.bloque(c, K_METAL, s + 2.95, s + 3.0, 0.0, 1.0, 1.6, 5.0)
		d.bloque(c, K_METAL, s - 3.0, s - 2.0, 0.95, 1.0, 4.95, 5.0)
		d.bloque(c, K_METAL, s + 2.0, s + 3.0, 0.95, 1.0, 4.95, 5.0)
		var r := Label3D.new()
		r.text = Idiomas.t("PUERTA %d") % int(ctx["puerta"])
		r.font_size = 72
		r.pixel_size = 0.012
		r.outline_size = 10
		r.modulate = Color(1, 1, 1)
		r.visibility_range_end = RANGO_ROTULO
		var n_v: Vector3 = c["n"]
		r.position = _punto(c, s, 4.72, 2.62)
		r.rotation.y = atan2(n_v.x, n_v.z)
		(ctx["nodo"] as Node3D).add_child(r)
	return n

## Escaleras exteriores: tramos en zigzag hasta el último piso.
static func _escaleras(ctx: Dictionary, c: Dictionary, fracciones: Array) -> void:
	var g: _Malla = ctx["grande"]
	var d: _Malla = ctx["detalle"]
	var L: float = c["L"]
	var H: float = c["H"]
	var w0 := 1.45 if ctx["estilo"] in ["lamas", "celosia"] else 0.75
	var tramo := 6.0
	var sube := 3.0
	for frac: float in fracciones:
		var s_c: float = L * frac
		if not _libre(c, s_c - tramo * 0.5 - 1.6, s_c + tramo * 0.5 + 1.6):
			continue
		var a := s_c - tramo * 0.5
		var b := s_c + tramo * 0.5
		var y := 0.0
		var ida := frac < 0.5
		var cima := H - 2.0
		while y + sube <= cima:
			var s0 := a if ida else b
			var s1 := b if ida else a
			g.barra(c, K_ESTRUCTURA, Vector3(s0, y + 0.15, w0 + 1.2), Vector3(s1, y + sube, w0 + 1.2), 0.25, 2.2)
			d.barra(c, K_METAL, Vector3(s0, y + 1.1, w0 + 2.3), Vector3(s1, y + sube + 0.95, w0 + 2.3), 0.06, 0.06)
			y += sube
			## Rellano en el extremo al que llega el tramo.
			g.bloque(c, K_ESTRUCTURA, s1 - 1.4 if not ida else s1, s1 if not ida else s1 + 1.4, y - 0.2, y, w0, w0 + 2.4)
			ida = not ida
		## Los dos pilares que la sostienen.
		for s_p: float in [a - 1.2, b + 1.2]:
			g.bloque(c, K_ESTRUCTURA, s_p - 0.15, s_p + 0.15, 0.0, y + 1.0, w0 + 2.1, w0 + 2.4)

## La cubierta vista desde fuera: canto, y mástiles con tirantes o cerchas.
static func _cubierta(ctx: Dictionary, c: Dictionary) -> void:
	var estilo: String = ctx["estilo"]
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var fondo: float = c["fondo"]
	var y_t := H + 0.65   ## la cara de arriba de la losa del techo
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.bloque(c, K_ACENTO if estilo in ["lamas", "celosia"] else K_ESTRUCTURA, a, b, H + 0.1, H + 1.5, -0.3, 0.35))
	if c["tipo"] != "tribuna":
		return
	match estilo:
		"membrana", "lamas", "celosia":
			## Mástiles con tirantes que cuelgan la cubierta.
			for s: float in _ejes(L, 18.0):
				if not _libre(c, s - 0.5, s + 0.5):
					continue
				var cima := Vector3(s, y_t + 10.0, 0.6)
				g.barra(c, K_ESTRUCTURA, Vector3(s, H - 2.0, 1.0), cima, 0.5, 0.5)
				for f: float in [0.45, 0.95]:
					g.barra(c, K_ESTRUCTURA, cima, Vector3(s, y_t + 0.05, -fondo * f), 0.09, 0.09)
				g.barra(c, K_ESTRUCTURA, cima, Vector3(s, H - 4.0, 4.5), 0.08, 0.08)
		"porticos":
			## Vigas en ménsula de hormigón sobre la losa.
			for s: float in _ejes(L, 9.0):
				if _libre(c, s - 0.4, s + 0.4):
					g.barra(c, K_ESTRUCTURA, Vector3(s, y_t + 1.6, 0.5), Vector3(s, y_t + 0.15, -fondo * 0.95), 0.5, 0.9)
		_:
			## Cerchas triangulares.
			for s: float in _ejes(L, 12.0):
				if not _libre(c, s - 0.4, s + 0.4):
					continue
				var alto_c := clampf(fondo * 0.18, 1.6, 3.5)
				var a := Vector3(s, y_t, 0.2)
				var b := Vector3(s, y_t, -fondo * 0.92)
				var cima := Vector3(s, y_t + alto_c, -fondo * 0.3)
				for par: Array in [[a, cima], [cima, b], [a, b]]:
					g.barra(c, K_ESTRUCTURA, par[0], par[1], 0.16, 0.16)
				for f: float in [0.1, 0.2, 0.45, 0.7]:
					var pz := a.lerp(b, f)
					var arriba := a.lerp(cima, f / 0.3) if f < 0.3 else cima.lerp(b, (f - 0.3) / 0.7)
					g.barra(c, K_ESTRUCTURA, pz, arriba, 0.1, 0.1)

## ---------------------------------------------------------------------------
## VESTIR UNA CARA
## ---------------------------------------------------------------------------
static func _vestir(ctx: Dictionary, c: Dictionary) -> void:
	var estilo: String = ctx["estilo"]
	var g: _Malla = ctx["grande"]
	var L: float = c["L"]
	var H: float = c["H"]
	var es_tribuna: bool = c["tipo"] == "tribuna"
	## Los pisos: donde acaba cada bandeja por fuera (los forjados).
	var pisos: Array = []
	var paso_piso := StadiumBuilder.subida_bandeja() + StadiumBuilder.FRENTE_BANDEJA
	for k in range(1, int(c["niv"])):
		var y := StadiumBuilder.ALTURA_PIE + float(k) * paso_piso - StadiumBuilder.FRENTE_BANDEJA * 0.5
		if y < H - 2.5:
			pisos.append(y)
	ctx["vanos"] = []
	## Zócalo común: todos los estadios se apoyan en algo.
	_tramos(c, 0.0, L, func(a: float, b: float) -> void:
		g.bloque(c, K_ESTRUCTURA, a, b, 0.0, 0.7, 0.0, 0.3))
	match estilo:
		"clasico":
			_clasico(ctx, c, pisos)
		"membrana":
			_membrana(ctx, c)
		"lamas":
			_lamas(ctx, c, pisos)
		"celosia":
			_celosia(ctx, c)
		"porticos":
			_porticos(ctx, c, pisos)
		_:
			_barrio(ctx, c)
	if not es_tribuna:
		_tapar_junta(ctx, c, pisos)
		_torre_esquina(ctx, c)
	else:
		_escudo_fachada(ctx, c)
		var n_puertas := _puertas(ctx, c)
		## (Los pórticos ya suben por sus rampas entre contrafuertes: una escalera
		## más se cruzaba con los pilares.)
		if estilo in ["barrio", "lamas", "celosia"] and L > 50.0 and H > 8.0:
			## Entre puertas, nunca delante de una.
			var fr: Array = [0.2, 0.8] if n_puertas <= 1 else []
			for k in range(1, n_puertas):
				fr.append(float(k) / float(n_puertas))
			_escaleras(ctx, c, fr.slice(0, 2))
	if bool(c["techo"]):
		_cubierta(ctx, c)
