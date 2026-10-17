class_name FachadaEstadio
extends RefCounted
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

## ---------------------------------------------------------------------------
## EL MONTAJE
## ---------------------------------------------------------------------------
static func montar(root: Node3D, est: Dictionary, caras: Array, seed_val: int, niveles: int,
		escudo: Texture2D = null) -> Node3D:
	var estilo := estilo_de(est, seed_val, niveles)
	var h := absi(("fachada_var:%d" % seed_val).hash())
	var p := _paleta(est, estilo, h)
	var nodo := Node3D.new()
	nodo.name = "Fachada"
	nodo.set_meta("estilo", estilo)
	root.add_child(nodo)
	var grande := _Malla.new()
	var detalle := _Malla.new()
	var ctx := {"estilo": estilo, "h": h, "p": p, "grande": grande, "detalle": detalle,
		"nodo": nodo, "puerta": 0, "escudo": escudo, "escudo_puesto": false}
	## Las puertas se numeran en el orden de las caras (tribunas y luego esquinas).
	for c: Dictionary in caras:
		if float(c["L"]) < 2.0 or float(c["H"]) < 2.0:
			continue
		_vestir(ctx, c)
	_volcar(nodo, "FachadaEstructura", grande, p, 0.0)
	_volcar(nodo, "FachadaDetalle", detalle, p, RANGO_DETALLE)
	return nodo

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

static func _material(clave: String, p: Dictionary) -> StandardMaterial3D:
	var m: StandardMaterial3D
	var estilo: String = p["estilo"]
	match clave:
		K_ESTRUCTURA:
			if estilo in ["clasico", "porticos"]:
				m = Texturas.hormigon(p["estructura"], 73).duplicate()
			else:
				m = StandardMaterial3D.new()
				m.albedo_color = p["estructura"]
				m.roughness = 0.55
				m.metallic = 0.15
		K_REVEST:
			if estilo == "membrana":
				m = Texturas.tela(p["revest"], 0.6).duplicate()
				## La trama a escala de lona (las UV van a 4 m por unidad).
				m.uv1_scale = Vector3(4.0, 4.0, 1.0)
				## De noche la membrana se enciende por dentro, como las de verdad.
				if p["noche"] == "noche":
					m.emission_enabled = true
					m.emission = (p["luz"] as Color).lerp(Color.WHITE, 0.5)
					m.emission_energy_multiplier = 0.35
			else:
				m = StandardMaterial3D.new()
				m.albedo_color = p["revest"]
				m.roughness = 0.5
				m.metallic = 0.25 if estilo in ["celosia", "barrio"] else 0.05
		K_PANEL:
			## Hormigón prefabricado más claro que la estructura (se lee el
			## despiece aunque la cara quede a la sombra).
			m = Texturas.hormigon((p["estructura"] as Color).lerp(Color(0.93, 0.92, 0.88), 0.55), 29).duplicate()
		K_ACENTO:
			m = StandardMaterial3D.new()
			m.albedo_color = p["acento"]
			m.roughness = 0.55
		K_VIDRIO:
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.035, 0.04, 0.05)
			m.metallic = 0.0
			m.roughness = 0.3
			m.metallic_specular = 0.55
			## Algo de luz dentro: vestíbulos y escaleras encendidas.
			m.emission_enabled = true
			m.emission = Color(1.0, 0.86, 0.62)
			m.emission_energy_multiplier = 0.55 if p["noche"] == "noche" else 0.0
		K_LUZ:
			m = StandardMaterial3D.new()
			m.albedo_color = p["luz"]
			m.emission_enabled = true
			m.emission = p["luz"]
			var energia := {"noche": 2.6, "tarde": 1.1, "niebla": 1.2, "lluvia": 1.2}
			m.emission_energy_multiplier = float(energia.get(p["noche"], 0.45))
		_:  # metal de calle: tornos, barandillas
			m = StandardMaterial3D.new()
			m.albedo_color = Color(0.62, 0.64, 0.67)
			m.roughness = 0.35
			m.metallic = 0.45
	return m

static func _volcar(nodo: Node3D, nombre: String, malla: _Malla, p: Dictionary, rango: float) -> void:
	var am := malla.cerrar(func(k: String) -> Material: return _material(k, p))
	if am == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = am
	if rango > 0.0:
		mi.visibility_range_end = rango
		mi.visibility_range_end_margin = rango * 0.1
	nodo.add_child(mi)

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

static func _libre(c: Dictionary, a: float, b: float) -> bool:
	if a < 0.0 or b > float(c["L"]):
		return false
	for ex: Vector2 in c["excluir"]:
		if not (ex.y <= a or ex.x >= b):
			return false
	return true

## Las posiciones de los ejes estructurales (vanos iguales de ~`paso` m).
static func _ejes(L: float, paso: float) -> Array:
	var nb := maxi(1, roundi(L / paso))
	var sal: Array = []
	for i in nb + 1:
		sal.append(L * float(i) / float(nb))
	return sal

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

static func _punto(c: Dictionary, s: float, y: float, w: float) -> Vector3:
	return (c["o"] as Vector3) + (c["u"] as Vector3) * s + Vector3.UP * y + (c["n"] as Vector3) * w

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
