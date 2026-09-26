class_name DisenosKit
extends RefCounted
## EL CATÁLOGO DE LA EQUIPACIÓN (26-9-2026). Pedido: *"más variantes de diseño de
## camiseta, colores de números, mínimo unos 50 diseños más, poder combinar hasta
## 5 colores, en polera, shorts, accesorios para jugadores, unos 30 tipos de
## botines y cambiar de colores"*.
##
## Cada diseño es una FAMILIA paramétrica (franjas, aros, banda, chevron,
## lunares, camuflaje...) con sus parámetros. La misma fórmula se evalúa en dos
## sitios, y por eso lo que eliges en el diseñador es lo que se ve en el partido:
##   - `visor/equipacion_q.gdshader` (el 3D, sobre el cuerpo del jugador);
##   - `color_en()` aquí (el 2D: galería, ficha y vista previa).
## Coordenadas del torso: u de −1 (costado derecho) a 1, v de 0 (cintura) a 1
## (cuello). Los 12 estilos de siempre siguen con su clave y su dibujo exacto
## (familias 100-111, la fórmula vieja del shader).
##
## La equipación completa de un club es un diccionario (`Club.kit_x`):
##   dis    clave del diseño
##   cols   5 colores (hex); el diseño usa los que necesite, en orden
##   trim   qué color (0-4) llevan cuello y puños
##   num    color de los números
##   pant   {dis, c1, c2}   pantalón
##   med    {dis, c1, c2}   medias
##   bot    {mod, c1, c2, c3}   botines: modelo y sus tres colores
##   acc    {clave: hex}    accesorios puestos y su color

## [clave, nombre, familia, a, b, c, d, colores que usa]
const DISENOS := [
	## Los 12 de siempre (mismas claves y mismo dibujo).
	["liso", "Liso", 0, 0, 0, 0, 0, 1],
	["franjas", "Franjas clásicas", 101, 0, 0, 0, 0, 2],
	["banda", "Banda", 102, 0, 0, 0, 0, 2],
	["mitad", "Mitad y mitad", 103, 0, 0, 0, 0, 2],
	["hombros", "Hombros", 104, 0, 0, 0, 0, 2],
	["aros", "Aros", 105, 0, 0, 0, 0, 2],
	["diagonal", "Diagonal fina", 106, 0, 0, 0, 0, 2],
	["cuadros", "Cuadros", 107, 0, 0, 0, 0, 2],
	["vertical3", "Tres bastones", 108, 0, 0, 0, 0, 2],
	["degrade", "Degradé", 109, 0, 0, 0, 0, 2],
	["sash", "Banda ancha", 110, 0, 0, 0, 0, 2],
	["arlequin", "Arlequín", 111, 0, 0, 0, 0, 2],
	## Los nuevos.
	["franjas_finas", "Franjas finas", 1, 14, 0.5, 2, 0, 2],
	["franjas_anchas", "Franjas anchas", 1, 4, 0.5, 2, 0, 2],
	["franjas_tricolor", "Franjas tricolor", 1, 9, 0.66, 3, 0, 3],
	["bastones", "Bastones", 1, 7, 0.28, 2, 0, 2],
	["franjas_cinco", "Franjas de cinco colores", 1, 10, 0.8, 5, 0, 5],
	["aros_finos", "Aros finos", 2, 14, 0.5, 2, 0, 2],
	["aros_anchos", "Aros anchos", 2, 5, 0.5, 2, 0, 2],
	["aros_tricolor", "Aros tricolor", 2, 9, 0.66, 3, 0, 3],
	["banda_cruzada", "Banda cruzada", 3, 1.0, 0.13, 0, 0, 2],
	["doble_banda", "Doble banda", 3, 1.0, 0.09, 0, 1, 3],
	["banda_inversa", "Banda inversa", 3, -1.0, 0.13, 0, 0, 2],
	["banda_baja", "Banda baja", 3, 0.5, 0.1, 0.25, 0, 2],
	["tercios_v", "Tercios verticales", 4, 3, 0, 0, 0, 3],
	["cuartos_v", "Cuatro paños", 4, 4, 0, 0, 0, 4],
	["tercios_h", "Tercios horizontales", 5, 3, 0, 0, 0, 3],
	["bloques_h", "Bloques de cinco", 5, 5, 0, 0, 0, 5],
	["franja_pecho", "Franja al pecho", 6, 0.62, 0.09, 0, 0, 2],
	["pecho_ribete", "Pecho con ribetes", 6, 0.62, 0.08, 1, 0, 3],
	["canesu", "Canesú", 7, 0.78, 0, 0, 0, 2],
	["canesu_curvo", "Canesú curvo", 7, 0.72, 0.28, 1, 0, 3],
	["cuadros_chicos", "Cuadritos", 8, 12, 0, 0, 0, 2],
	["cuadros_grandes", "Cuadrados grandes", 8, 4, 0, 0, 0, 2],
	["ajedrez_tricolor", "Ajedrez tricolor", 8, 6, 1, 0, 0, 3],
	["degrade_diagonal", "Degradé diagonal", 9, 1, 0, 0, 0, 2],
	["degrade_lateral", "Degradé lateral", 9, 2, 0, 0, 0, 2],
	["chevron", "Chevrón", 10, 1.0, 0.12, 1, 0, 2],
	["chevron_doble", "Chevrones", 10, 1.0, 0, 4, 0, 2],
	["v_invertida", "V invertida", 10, -1.0, 0.12, 1, 0, 2],
	["cruz", "Cruz", 11, 0.12, 0.6, 0, 0, 2],
	["cruz_nordica", "Cruz nórdica", 11, 0.11, 0.62, -0.35, 0, 2],
	["paneles_lado", "Paneles laterales", 12, 0.68, 0, 0, 0, 2],
	["lado_ribete", "Lateral con ribete", 12, 0.78, 0, 1, 0, 3],
	["franja_central", "Franja central", 13, 0.22, 0, 0, 0, 2],
	["central_ribete", "Central con ribetes", 13, 0.2, 0, 1, 0, 3],
	["tiza", "Rayas de tiza", 14, 18, 0, 0, 0, 2],
	["ondas", "Ondas", 15, 7, 0.08, 6, 0, 2],
	["ondas_grandes", "Olas grandes", 15, 3.5, 0.15, 3, 0, 2],
	["zigzag", "Zigzag", 16, 3, 0.35, 5, 0, 2],
	["lunares", "Lunares", 17, 8, 0.28, 0, 0, 2],
	["lunares_bicolor", "Lunares de dos colores", 17, 5, 0.3, 1, 0, 3],
	["rombos", "Rombos", 18, 3, 0, 0, 0, 3],
	["rombos_escoceses", "Rombos escoceses", 18, 3, 1, 0, 0, 4],
	["escamas", "Escamas", 19, 7, 0, 0, 0, 2],
	["rayos", "Rayos de sol", 20, 12, 0, 0, 0, 2],
	["anillos", "Anillos", 21, 6, 0, 0, 0, 2],
	["camuflaje", "Camuflaje", 22, 3.5, 3, 0, 0, 3],
	["camuflaje_urbano", "Camuflaje urbano", 22, 6, 4, 0, 0, 4],
	["arcoiris_v", "Arcoíris vertical", 23, 0, 5, 0, 0, 5],
	["arcoiris_h", "Arcoíris horizontal", 23, 1, 5, 0, 0, 5],
	["marco", "Marco", 24, 0.12, 0, 0, 0, 2],
	["marco_doble", "Doble marco", 24, 0.1, 1, 0, 0, 3],
	["pinceladas", "Pinceladas", 25, 3, 0, 0, 0, 3],
	["tartan", "Tartán", 26, 4, 0, 0, 0, 3],
	["tartan_fino", "Tartán fino", 26, 8, 0, 0, 0, 4],
	["diamantes", "Diamantes", 27, 3, 0, 0, 0, 2],
	["franjas_crecientes", "Franjas que crecen", 28, 8, 0, 0, 0, 2],
	["pixel", "Píxeles", 29, 9, 0, 0, 0, 3],
	["gajos", "Gajos", 4, 6, 0, 0, 0, 2],
	## ESTILO MODERNO (26-9-2026, pedido: "replicar los estilos de los juegos
	## actuales"): plantillas genéricas de las que usan las marcas hoy, sin
	## copiar ninguna equipación concreta.
	["puntos_degradados", "Puntos degradados", 30, 14, 0.45, 0, 0, 2],
	["puntos_finos", "Puntos degradados finos", 30, 22, 0.42, 0, 0, 2],
	["curvas_nivel", "Curvas de nivel", 31, 3, 6, 0, 0, 2],
	["curvas_finas", "Curvas de nivel finas", 31, 5, 10, 0, 0, 2],
	["marmol", "Mármol", 32, 6, 0, 0, 0, 3],
	["marmol_fino", "Mármol fino", 32, 11, 0, 0, 0, 3],
	["fragmentos", "Fragmentos", 33, 4, 0, 0, 0, 3],
	["fragmentos_grandes", "Fragmentos grandes", 33, 2.5, 0, 0, 0, 3],
	["mangas_contraste", "Mangas de contraste", 34, 0, 0, 0, 0, 3],
	["mangas_canesu", "Mangas y canesú", 34, 1, 0, 0, 0, 3],
	["diagonal_partida", "Diagonal partida", 35, 1, 0, 0, 0, 3],
	["diagonal_partida_inv", "Diagonal partida inversa", 35, -1, 0, 0, 0, 3],
	["relampago", "Relámpago", 36, 3, 0.5, 0, 0, 2],
	["cuadricula", "Cuadrícula", 37, 10, 0, 0, 0, 2],
	["cuadricula_fina", "Cuadrícula fina", 37, 18, 0, 0, 0, 2],
	["estrellas", "Estrellas", 38, 6, 0.3, 0, 0, 2],
	["franjas_degradadas", "Franjas degradadas", 39, 8, 0.5, 0, 0, 3],
	["faja_rayas", "Faja con rayas", 40, 0.62, 0.11, 0, 0, 3],
	["resplandor", "Resplandor", 41, 0, 0, 0, 0, 2],
	["puntos_diagonal", "Puntos en diagonal", 42, 14, 0.5, 0, 0, 2],
	## 20 DE SOLO DOS COLORES Y 20 DE SOLO TRES (26-9-2026). Las mismas 20 familias
	## (43-62): con d = 0 el acento es el color 1; con d = 1 es el color 2.
	["v_ancha", "V ancha", 43, 0.55, 0.07, 0, 0, 2],
	["raglan", "Raglán", 44, 0.6, 0, 0, 0, 2],
	["doble_faja", "Doble faja", 45, 0.62, 0.06, 0, 0, 2],
	["franjas_asim", "Franjas a un lado", 46, 6, 0, 0, 0, 2],
	["pecho_zigzag", "Pecho en zigzag", 47, 0.6, 4, 0, 0, 2],
	["panal", "Panal", 48, 6, 0, 0, 0, 2],
	["triangulos", "Triángulos", 49, 5, 0, 0, 0, 2],
	["olas_v", "Olas verticales", 50, 8, 9, 0, 0, 2],
	["cebra", "Cebra", 51, 4, 6, 0, 0, 2],
	["rayas_diag", "Rayas diagonales", 52, 1, 5, 0, 0, 2],
	["espiga", "Espiga", 53, 8, 0, 0, 0, 2],
	["codigo_barras", "Código de barras", 54, 0.55, 0, 0, 0, 2],
	["circulo", "Círculo central", 55, 0.35, 0.05, 0, 0, 2],
	["cuello_v", "Cuello en V rayado", 56, 0.5, 0.035, 0, 0, 2],
	["costados_rayados", "Costados rayados", 57, 0.6, 14, 0, 0, 2],
	["llamas", "Llamas", 58, 0.3, 18, 0, 0, 2],
	["mosaico", "Mosaico", 59, 5, 0, 0, 0, 2],
	["rombo_central", "Rombo central", 60, 0.35, 0, 0, 0, 2],
	["vichy", "Vichy", 61, 7, 0, 0, 0, 2],
	["estela", "Estela", 62, 1, 10, 0, 0, 2],
	["v_ancha_3", "Banda en V tricolor", 43, 0.55, 0.07, 0, 1, 3],
	["raglan_3", "Raglán con costura tricolor", 44, 0.6, 0, 0, 1, 3],
	["doble_faja_3", "Fajas al pecho tricolor", 45, 0.62, 0.06, 0, 1, 3],
	["franjas_asim_3", "Medio rayado tricolor", 46, 8, 0, 0, 1, 3],
	["pecho_zigzag_3", "Pecho partido en sierra tricolor", 47, 0.6, 4, 0, 1, 3],
	["panal_3", "Colmena tricolor", 48, 8, 0, 0, 1, 3],
	["triangulos_3", "Pirámides tricolor", 49, 6, 0, 0, 1, 3],
	["olas_v_3", "Franjas onduladas tricolor", 50, 10, 9, 0, 1, 3],
	["cebra_3", "Rayas salvajes tricolor", 51, 5, 6, 0, 1, 3],
	["rayas_diag_3", "Diagonales anchas tricolor", 52, 1, 5, 0, 1, 3],
	["espiga_3", "Espiguilla tricolor", 53, 10, 0, 0, 1, 3],
	["codigo_barras_3", "Barras al pecho tricolor", 54, 0.55, 0, 0, 1, 3],
	["circulo_3", "Anillo al pecho tricolor", 55, 0.35, 0.05, 0, 1, 3],
	["cuello_v_3", "V desde el cuello tricolor", 56, 0.5, 0.035, 0, 1, 3],
	["costados_rayados_3", "Laterales a rayas tricolor", 57, 0.6, 14, 0, 1, 3],
	["llamas_3", "Fuego desde abajo tricolor", 58, 0.3, 18, 0, 1, 3],
	["mosaico_3", "Teselas tricolor", 59, 6, 0, 0, 1, 3],
	["rombo_central_3", "Diamante al pecho tricolor", 60, 0.35, 0, 0, 1, 3],
	["vichy_3", "Cuadros de mantel tricolor", 61, 9, 0, 0, 1, 3],
	["estela_3", "Líneas de velocidad tricolor", 62, 1, 10, 0, 1, 3],
]

## Pantalones: [clave, nombre]
const PANTALONES := [["liso", "Liso"], ["lateral", "Franja lateral"], ["ribete", "Ribete abajo"],
	["bicolor", "Bicolor"], ["degrade", "Degradé"], ["doble_lateral", "Doble franja lateral"]]
## Medias: [clave, nombre]
const MEDIAS := [["lisas", "Lisas"], ["aros", "Con aros"], ["franja", "Franja arriba"],
	["dos_franjas", "Dos franjas"], ["bicolor", "Bicolor"], ["rombos", "Rombos"]]
## Botines: [clave, nombre, dibujo, base, acento, suela]
## Dibujos: 0 liso, 1 punta, 2 talón, 3 franja lateral, 4 degradé, 5 rayas,
## 6 camuflaje, 7 mitad, 8 onda.
const BOTINES := [
	["clasico", "Clásico negro", 0, "111111", "ffffff", "222222"],
	["blanco", "Blanco total", 0, "f2f2f2", "d0d0d0", "bbbbbb"],
	["rayo", "Rayo dorado", 3, "1b1b1b", "d4af37", "d4af37"],
	["fuego", "Fuego", 4, "ff3d00", "ffd600", "1a1a1a"],
	["hielo", "Hielo", 4, "e3f2fd", "4fc3f7", "ffffff"],
	["neon", "Neón", 1, "39ff14", "111111", "39ff14"],
	["carbono", "Carbono", 5, "2b2b2b", "4a4a4a", "000000"],
	["camuflaje", "Camuflaje", 6, "556b2f", "8b7d5a", "2f2f2f"],
	["talon_rojo", "Talón rojo", 2, "111111", "e53935", "111111"],
	["punta_plata", "Punta plateada", 1, "263238", "cfd8dc", "90a4ae"],
	["leyenda", "Leyenda", 8, "000000", "c9a227", "ffffff"],
	["aurora", "Aurora", 4, "7c4dff", "18ffff", "ffffff"],
	["pantera", "Pantera", 7, "111111", "ff4081", "111111"],
	["tormenta", "Tormenta", 5, "37474f", "ffeb3b", "212121"],
	["esmeralda", "Esmeralda", 3, "00695c", "a7ffeb", "ffffff"],
	["coral", "Coral", 1, "ff7043", "ffffff", "ff7043"],
	["galaxia", "Galaxia", 6, "1a237e", "ab47bc", "000000"],
	["solar", "Solar", 4, "ffab00", "ff1744", "ffffff"],
	["medianoche", "Medianoche", 8, "0d1b2a", "4cc9f0", "0d1b2a"],
	["sangre_oro", "Sangre y oro", 7, "b71c1c", "ffc107", "000000"],
	["menta", "Menta", 2, "e0f2f1", "26a69a", "ffffff"],
	["lava", "Lava", 6, "212121", "ff5722", "ff5722"],
	["glaciar", "Glaciar", 3, "ffffff", "29b6f6", "0277bd"],
	["cobre", "Cobre", 0, "b87333", "5d4037", "3e2723"],
	["arcoiris", "Arcoíris", 5, "e53935", "1e88e5", "ffffff"],
	["retro", "Retro marrón", 3, "3e2723", "ffffff", "d7ccc8"],
	["tricolor", "Tricolor", 7, "1565c0", "ffffff", "c62828"],
	["veloz", "Veloz", 8, "ffff00", "000000", "ffff00"],
	["precision", "Precisión", 2, "eceff1", "e91e63", "37474f"],
	["control", "Control", 1, "004d40", "ffffff", "004d40"],
]
## Cortes de cuello (`kit.cuello`).
const CUELLOS := ["En pico (V)", "Redondo", "Polo con tapeta", "Mao (alto)"]
## Accesorios: [clave, nombre, color por defecto]
const ACCESORIOS := [
	["cintillo", "Cintillo", "ffffff"],
	["manguitos", "Camiseta térmica (manga larga)", "111111"],
	["guantes", "Guantes", "111111"],
	["munequeras", "Muñequeras", "ffffff"],
	["brazalete", "Brazalete de capitán", "ffd600"],
	["cuello", "Cuello térmico", "111111"],
	["tobilleras", "Tobilleras (tape)", "ffffff"],
]

static func claves() -> Array:
	return DISENOS.map(func(d: Array) -> String: return String(d[0]))

static func diseno(clave: String) -> Array:
	for d: Array in DISENOS:
		if String(d[0]) == clave:
			return d
	return DISENOS[0]

static func indice_diseno(clave: String) -> int:
	for i in DISENOS.size():
		if String(DISENOS[i][0]) == clave:
			return i
	return 0

static func indice_de(tabla: Array, clave: String) -> int:
	for i in tabla.size():
		if String(tabla[i][0]) == clave:
			return i
	return 0

## La equipación completa de un club: la guardada (`kit_x`) sobre los valores
## que salen de sus colores de siempre.
static func kit_de_club(c: Club) -> Dictionary:
	var c1 := c.color_kit1()
	var c2 := c.color_kit2()
	var base := {
		"dis": Jersey.kit_de(c, c.kit_estilo),
		"cols": [c1, c2, Color(c2).darkened(0.35).to_html(false), "ffffff", "111111"],
		"trim": 1,
		"num": Jersey._lum_tx(c1).trim_prefix("#"),
		"pant": {"dis": "liso", "c1": c2 if Jersey.kit_de(c, c.kit_estilo) == "liso" else c1, "c2": c1},
		"med": {"dis": "lisas", "c1": c1, "c2": c2},
		"bot": {"mod": "clasico", "c1": "111111", "c2": "ffffff", "c3": "222222"},
		"acc": {},
		"cuello": absi(hash(c.id)) % CUELLOS.size(),
	}
	for k: String in c.kit_x:
		base[k] = c.kit_x[k]
	## Los patrocinadores no se guardan en el kit: salen de los contratos (o del
	## hash del club) cada vez, así un contrato nuevo cambia la camiseta sola.
	var sp := SponsorKit.de_club(c, Mundo.actual())
	for z: String in base.get("sp_ocultar", []):
		sp.erase(z)
	base["sp"] = sp
	return base

static func _col(hexa: Variant) -> Color:
	var s := String(hexa)
	if s == "":
		return Color.WHITE
	return Color(s if s.begins_with("#") else "#" + s)

static func colores(kit: Dictionary) -> Array[Color]:
	var r: Array[Color] = []
	var cols: Array = kit.get("cols", [])
	for i in 5:
		r.append(_col(cols[i]) if i < cols.size() else Color.WHITE)
	return r

## ------------------------------------------------ LA FÓRMULA (espejo del shader)

static func _h21(x: float, y: float) -> float:
	return fposmod(sin(x * 127.1 + y * 311.7) * 43758.5453, 1.0)

static func _ruido(x: float, y: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_h21(ix, iy), _h21(ix + 1.0, iy), fx), lerpf(_h21(ix, iy + 1.0), _h21(ix + 1.0, iy + 1.0), fx), fy)

static func _ciclo(cols: Array[Color], idx: float, k: float) -> Color:
	return cols[clampi(int(fposmod(idx, maxf(k, 1.0))), 0, 4)]

## La franja número `id` de un diseño de `k` colores: recorre los colores 1..k-1
## (el 0 es el fondo).
static func _banda(cols: Array[Color], id: float, k: float) -> Color:
	return cols[clampi(1 + int(fposmod(id, maxf(k - 1.0, 1.0))), 0, 4)]

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

## La fórmula vieja de los 12 estilos (mismos números que el shader).
static func _legado(e: int, x: float, y: float) -> float:
	match e:
		1: return 1.0 if fposmod(x * 7.7 + 0.25, 1.0) >= 0.5 else 0.0
		2: return 1.0 if absf(x + (y - 1.27)) < 0.07 else 0.0
		3: return 1.0 if x >= 0.0 else 0.0
		4: return 1.0 if y >= 1.42 else 0.0
		5: return 1.0 if fposmod(y * 8.3, 1.0) >= 0.5 else 0.0
		6: return 1.0 if absf(x - (y - 1.27)) < 0.045 else 0.0
		7: return fposmod(floorf(x * 14.0) + floorf(y * 14.0), 2.0)
		8: return 1.0 if fposmod(x * 13.3 + 0.36, 1.0) >= 0.72 else 0.0
		9: return smoothstep(1.42, 1.02, y) * 0.95
		10: return 1.0 if absf(x + (y - 1.27)) < 0.095 else 0.0
		11: return 1.0 if (x > 0.0) != (y > 1.27) else 0.0
	return 0.0

## ------------------------------------------------------------ EL DIBUJO 2D

static var _cache: Dictionary = {}
static var _silueta: Image = null

## La silueta de la camiseta (la misma de `Jersey.svg_de`), en blanco.
static func _mascara_camiseta(escala: float) -> Image:
	var svg := '<svg width="64" height="52" viewBox="0 0 64 52" xmlns="http://www.w3.org/2000/svg"><path d="M20 4 8 10l4 10 6-3v29h28V17l6 3 4-10L44 4l-6 3h-12z" fill="#fff"/></svg>'
	var img := Image.new()
	img.load_svg_from_string(svg, escala)
	return img

## La camiseta 2D de un diseño, con el cuello y los puños del color de trim.
## REALISMO (26-9-2026, pedido: "se ven poco realistas"):
##   - se dibuja al doble de tamaño y se reduce (bordes suaves, sin escalones);
##   - volumen: el torso más oscuro hacia los costados, brillo en el pecho y los
##     hombros, sombra bajo las mangas y arrugas suaves de tela;
##   - confección: cuello en pico acanalado, puños acanalados, costuras de
##     hombro y laterales, doble pespunte en el bajo;
##   - escudo del club (izquierda del pecho) y marca de ropa (derecha);
##   - la trama del tejido, un punto fino que se nota de cerca.
static func textura_camiseta(clave: String, cols: Array[Color], trim: int = 1, ancho_px: int = 128) -> Texture2D:
	var k := "%s|%s|%d|%d" % [clave, ",".join(cols.map(func(c: Color) -> String: return c.to_html(false))), trim, ancho_px]
	if _cache.has(k):
		return _cache[k]
	var out := _imagen_camiseta(clave, cols, trim, ancho_px)
	var t := ImageTexture.create_from_image(out)
	_cache[k] = t
	return t

static func _imagen_camiseta(clave: String, cols: Array[Color], trim: int, ancho_px: int, espalda: bool = false, sp: Dictionary = {}, cuello: int = 0) -> Image:
	var ss := 2 if ancho_px <= 200 else 1
	var escala := float(ancho_px * ss) / 64.0
	var m := _mascara_camiseta(escala)
	var w := m.get_width()
	var h := m.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var d := diseno(clave)
	var c_trim: Color = cols[clampi(trim, 0, 4)]
	var detalle := ancho_px >= 96
	for py in h:
		for px in w:
			var al := m.get_pixel(px, py).a
			if al <= 0.01:
				continue
			var sx := float(px) / escala
			var sy := float(py) / escala
			var manga := sx < 18.0 or sx > 46.0
			## La manga va con u = ±1,05 (fuera del torso), igual que en el 3D.
			var u := clampf((sx - 32.0) / 14.0, -1.0, 1.0) if not manga else signf(sx - 32.0) * 1.05
			var v := clampf(1.0 - (sy - 6.0) / 40.0, 0.0, 1.0)
			var col := color_en(d, cols, u, v)
			## Cuello en pico, acanalado.
			## De espaldas el cuello es redondo y bajo.
			## El corte: pico (0) delante; redondo, polo y mao, redondos.
			var pico := cuello == 0 and not espalda
			var borde_cuello := (7.5 - (sy - 4.0) * 0.9) if pico else (6.0 - pow(maxf(sy - 4.0, 0.0), 1.4) * 0.9)
			var grosor := 2.4 if cuello == 3 else 1.2
			var cuello_v := absf(sx - 32.0) < borde_cuello and sy < (12.0 if pico else 7.0) and not manga
			var ribete_cuello := not manga and sy < (12.5 if pico else 8.0 + (1.2 if cuello == 3 else 0.0)) and absf(absf(sx - 32.0) - borde_cuello) < grosor and sy > 3.5
			if ribete_cuello:
				col = c_trim * (0.92 + 0.08 * float(int(sx * 2.0) % 2))
			elif cuello_v and sy < (11.0 if not espalda else 6.5):
				## Por dentro del pico se ve la tela de atrás, en sombra.
				col = cols[0] * 0.55
			## Polo: la tapeta con dos botones.
			if cuello == 2 and not espalda and not manga and absf(sx - 32.0) < 1.1 and sy > 5.5 and sy < 13.5:
				col = c_trim
				if absf(sx - 32.0) < 0.45 and (absf(sy - 9.0) < 0.45 or absf(sy - 12.0) < 0.45):
					col = cols[0].darkened(0.3)
			## Puños acanalados.
			var dist_puno := minf(absf(sx - 10.0 - (sy - 10.0) * 0.28), absf(sx - 54.0 + (sy - 10.0) * 0.28))
			if manga and dist_puno < 1.6 and sy > 12.0:
				col = c_trim * (0.9 + 0.1 * float(int(sy * 2.0) % 2))
			var luz := 1.0
			if not manga:
				## Volumen del torso: cilindro con la luz arriba a la izquierda.
				var cx := (sx - 32.0) / 14.0
				luz = 0.78 + 0.28 * sqrt(maxf(0.0, 1.0 - cx * cx)) - 0.06 * cx
				## Brillo del pecho y caída hacia el bajo.
				luz += 0.07 * exp(-pow((sy - 16.0) / 6.0, 2.0)) - 0.05 * clampf((sy - 38.0) / 8.0, 0.0, 1.0)
				## Arrugas suaves de tela (más en la cintura).
				luz -= 0.045 * (_ruido(sx * 0.35, sy * 0.12) - 0.5) * (0.6 + clampf((sy - 30.0) / 16.0, 0.0, 1.0))
				## Sombra bajo las mangas.
				if absf(sx - 32.0) > 11.0 and sy > 12.0 and sy < 22.0:
					luz -= 0.12 * (absf(sx - 32.0) - 11.0) / 3.0
			else:
				luz = 0.82 + 0.08 * (1.0 - clampf(absf(sy - 12.0) / 10.0, 0.0, 1.0))
			## Costuras: hombros, laterales y doble pespunte del bajo.
			if (absf(sx - 18.0) < 0.35 or absf(sx - 46.0) < 0.35) and sy > 9.0:
				luz *= 0.8
			if not manga and sy > 43.0 and (absf(sy - 43.8) < 0.25 or absf(sy - 44.8) < 0.25):
				luz *= 0.82
			if detalle and not manga and not espalda:
				## Escudo: izquierda del pecho (derecha del dibujo).
				var ex := (sx - 38.5) / 3.2
				var ey := (sy - 15.5) / 3.8
				var ancho_e := 1.0 if ey < 0.0 else sqrt(maxf(0.0, 1.0 - ey * ey))
				if absf(ex) < ancho_e and ey > -1.0 and ey < 1.0:
					col = cols[1] if absf(ex) < ancho_e - 0.25 and ey > -0.75 else c_trim
					if absf(ex) < 0.3 and absf(ey) < 0.35:
						col = c_trim
				## Marca: un "ala" a la derecha del pecho (izquierda del dibujo).
				var mx := (sx - 25.5) / 2.6
				var my := (sy - 15.8) / 1.6
				if absf(mx) < 1.0 and absf(my - (mx * mx * 0.6 - 0.25)) < 0.3 - mx * 0.1:
					col = c_trim
			## Trama del tejido.
			var trama := 1.0 + 0.03 * (float((px + py) % 3 == 0) - 0.33)
			luz *= trama
			out.set_pixel(px, py, Color(clampf(col.r * luz, 0.0, 1.0), clampf(col.g * luz, 0.0, 1.0), clampf(col.b * luz, 0.0, 1.0), al))
	_estampar_sponsors(out, escala, cols[0], sp, espalda)
	if ss > 1:
		out.resize(w / ss, h / ss, Image.INTERPOLATE_LANCZOS)
	return out

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

## La equipación entera en 2D (camiseta, pantalón, medias y botines), de
## frente o de espaldas con el número.
static func textura_completa(kit: Dictionary, espalda: bool = false, ancho_px: int = 160) -> Texture2D:
	var cols := colores(kit)
	var ss := 2
	var camiseta := _imagen_camiseta(String(kit.get("dis", "liso")), cols, int(kit.get("trim", 1)), ancho_px * ss, espalda, kit.get("sp", {}), int(kit.get("cuello", 0)))
	var w := camiseta.get_width()
	var escala := float(w) / 64.0
	var h := int(escala * 112.0)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var pant: Dictionary = kit.get("pant", {})
	var med: Dictionary = kit.get("med", {})
	var bot: Dictionary = kit.get("bot", {})
	var pc1 := _col(pant.get("c1", "ffffff"))
	var pc2 := _col(pant.get("c2", "000000"))
	var mc1 := _col(med.get("c1", "ffffff"))
	var mc2 := _col(med.get("c2", "000000"))
	var bm: Array = BOTINES[indice_de(BOTINES, String(bot.get("mod", "clasico")))]
	var bc1 := _col(bot.get("c1", bm[3]))
	var bc2 := _col(bot.get("c2", bm[4]))
	var bc3 := _col(bot.get("c3", bm[5]))
	var pdis := String(pant.get("dis", "liso"))
	var mdis := String(med.get("dis", "lisas"))
	for py in range(int(40.0 * escala), h):
		var sy := float(py) / escala
		for px in w:
			var sx := float(px) / escala
			var col := Color(0, 0, 0, 0)
			var luz := 1.0
			## Pantalón: de 44 a 64, con la entrepierna y bajos acampanados.
			var abre := (sy - 44.0) * 0.12
			var entrepierna := sy > 54.0 and absf(sx - 32.0) < (sy - 54.0) * 0.3
			if sy >= 44.0 and sy < 64.0 and sx > 18.5 - abre and sx < 45.5 + abre and not entrepierna:
				var lado := sx < 32.0
				var ex := clampf(absf(sx - 32.0) / (13.5 + abre), 0.0, 1.0)
				col = pc1
				match pdis:
					"lateral": col = pc2 if ex > 0.85 else pc1
					"doble_lateral": col = pc2 if (ex > 0.78 and ex < 0.84) or ex > 0.9 else pc1
					"ribete": col = pc2 if sy > 61.5 else pc1
					"bicolor": col = pc2 if not lado else pc1
					"degrade": col = pc1.lerp(pc2, clampf((sy - 44.0) / 20.0, 0.0, 1.0))
				## Volumen de cada pernera, cintura elástica y pliegues.
				var cpierna := (sx - (25.0 if lado else 39.0)) / 8.0
				luz = 0.8 + 0.22 * sqrt(maxf(0.0, 1.0 - cpierna * cpierna * 0.8))
				if sy < 46.0:
					luz *= 0.88 + 0.06 * float(int(sy * 3.0) % 2)
				luz -= 0.05 * (_ruido(sx * 0.4, sy * 0.2) - 0.5)
			## Medias: de 66 a 96, con la pantorrilla más ancha.
			elif sy >= 66.0 and sy < 96.0:
				var anchom := 4.2 + 0.9 * sin(clampf((sy - 66.0) / 18.0, 0.0, 1.0) * PI)
				var ci := 25.0
				var cd := 39.0
				if absf(sx - ci) < anchom or absf(sx - cd) < anchom:
					var t := (sy - 66.0) / 30.0
					col = mc1
					match mdis:
						"aros": col = mc2 if fposmod(t * 8.0, 1.0) < 0.4 else mc1
						"franja": col = mc2 if t < 0.18 else mc1
						"dos_franjas": col = mc2 if (t > 0.05 and t < 0.12) or (t > 0.17 and t < 0.24) else mc1
						"bicolor": col = mc2 if t > 0.55 else mc1
						"rombos": col = mc2 if absf(fposmod(t * 6.0, 1.0) - 0.5) + absf(fposmod((sx - 21.0) / 8.0, 1.0) - 0.5) < 0.35 else mc1
					var cm := (sx - (ci if sx < 32.0 else cd)) / anchom
					luz = 0.78 + 0.25 * sqrt(maxf(0.0, 1.0 - cm * cm))
					## Canalé de la media y la vuelta de arriba.
					luz *= 0.96 + 0.04 * float(int(sx * 2.5) % 2)
					if t < 0.07:
						luz *= 0.9
			## Botines: de 96 a 105, con brillo, cordones y tacos.
			if sy >= 95.5 and sy < 105.0:
				var izq := sx < 32.0
				var z := (30.0 - sx) / 14.0 if izq else (sx - 34.0) / 14.0
				var alto := (104.0 - sy) / 8.5
				var techo := 0.95 - smoothstep(0.35, 1.0, z) * 0.5
				if z >= -0.05 and z <= 1.0 and alto >= 0.0 and alto <= techo:
					col = _color_botin(int(bm[2]), bc1, bc2, z, alto)
					luz = 0.85 + 0.35 * exp(-pow((alto - 0.62) / 0.15, 2.0)) * smoothstep(0.2, 0.7, z)
					if alto < 0.14:
						col = bc3
						luz = 0.9
					## Cordones.
					if z > 0.45 and z < 0.8 and alto > techo - 0.16 and int(z * 20.0) % 2 == 0:
						col = Color(0.95, 0.95, 0.95)
				elif z >= 0.0 and z <= 0.95 and alto < 0.0 and alto > -0.1 and fposmod(z * 6.0, 1.0) < 0.35:
					col = bc3 * 0.8
			if col.a > 0.0:
				out.set_pixel(px, py, Color(clampf(col.r * luz, 0.0, 1.0), clampf(col.g * luz, 0.0, 1.0), clampf(col.b * luz, 0.0, 1.0), 1.0))
	## La camiseta, encima del pantalón (el bajo cae por delante de la cintura).
	out.blend_rect(camiseta, Rect2i(0, 0, w, camiseta.get_height()), Vector2i(0, 0))
	out.resize(w / ss, h / ss, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(out)

## El color de un botín: `z` de 0 (talón) a 1 (punta), `alto` de 0 (suela) a 1.
static func _color_botin(dibujo: int, c1: Color, c2: Color, z: float, alto: float) -> Color:
	match dibujo:
		1: return c2 if z > 0.72 else c1
		2: return c2 if z < 0.25 else c1
		3: return c2 if absf(alto - 0.5) < 0.14 else c1
		4: return c1.lerp(c2, z)
		5: return c2 if fposmod(z * 6.0, 1.0) < 0.3 else c1
		6: return c2 if _ruido(z * 5.0, alto * 3.0) > 0.55 else c1
		7: return c2 if alto > 0.5 else c1
		8: return c2 if absf(alto - 0.45 - sin(z * 6.0) * 0.18) < 0.1 else c1
	return c1

## Una miniatura de botín (galería).
static func textura_botin(clave: String, c1: Color, c2: Color, c3: Color, ancho_px: int = 72) -> Texture2D:
	var k := "bot|%s|%s|%s|%s|%d" % [clave, c1.to_html(false), c2.to_html(false), c3.to_html(false), ancho_px]
	if _cache.has(k):
		return _cache[k]
	var bm: Array = BOTINES[indice_de(BOTINES, clave)]
	var w := ancho_px
	var h := int(float(ancho_px) * 0.5)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for py in h:
		for px in w:
			var z := float(px) / float(w)
			var alto := 1.0 - float(py) / float(h)
			## Silueta de botín: contrafuerte alto atrás, el hueco del tobillo,
			## el empeine que baja y la puntera redondeada.
			var techo: float
			if z < 0.12:
				techo = 0.88
			elif z < 0.3:
				techo = lerpf(0.88, 0.72, (z - 0.12) / 0.18)
			elif z < 0.88:
				techo = lerpf(0.72, 0.44, (z - 0.3) / 0.58)
			else:
				techo = 0.44 * sqrt(maxf(0.0, 1.0 - pow((z - 0.88) / 0.12, 2.0)))
			if alto > techo or (z < 0.03 and alto > 0.2):
				continue
			var col := _color_botin(int(bm[2]), c1, c2, z, alto)
			if alto < 0.13:
				col = c3
			## Tacos.
			if alto < 0.04 and fposmod(z * 7.0, 1.0) > 0.5:
				continue
			img.set_pixel(px, py, col)
	var t := ImageTexture.create_from_image(img)
	_cache[k] = t
	return t

## Uniforms del shader para esta equipación (los usa `VestidorQ`).
static func uniforms(kit: Dictionary, dorsal: int) -> Dictionary:
	var cols := colores(kit)
	var d := diseno(String(kit.get("dis", "liso")))
	var pant: Dictionary = kit.get("pant", {})
	var med: Dictionary = kit.get("med", {})
	var bot: Dictionary = kit.get("bot", {})
	var bm: Array = BOTINES[indice_de(BOTINES, String(bot.get("mod", "clasico")))]
	var acc: Dictionary = kit.get("acc", {})
	var u := {
		"familia": int(d[2]), "prm": Vector4(float(d[3]), float(d[4]), float(d[5]), float(d[6])),
		"n_cols": int(d[7]), "trim": int(kit.get("trim", 1)),
		"cols": PackedColorArray(cols),
		"color_pantalon": _col(pant.get("c1", "ffffff")), "pant_c2": _col(pant.get("c2", "000000")),
		"pant_dis": indice_de(PANTALONES, String(pant.get("dis", "liso"))),
		"color_medias": _col(med.get("c1", "ffffff")), "med_c2": _col(med.get("c2", "000000")),
		"med_dis": indice_de(MEDIAS, String(med.get("dis", "lisas"))),
		"color_botines": _col(bot.get("c1", bm[3])), "bot_c2": _col(bot.get("c2", bm[4])), "bot_c3": _col(bot.get("c3", bm[5])),
		"bot_dis": int(bm[2]),
		"dorsal": dorsal, "color_num": _col(kit.get("num", "ffffff")),
		"cuello": int(kit.get("cuello", 0)),
	}
	for a: Array in ACCESORIOS:
		var k := String(a[0])
		u["acc_" + k] = _col(acc[k]) if acc.has(k) else Color(0, 0, 0, 0)
	## Los patrocinadores (pecho, manga, espalda y pantalón).
	var sp: Dictionary = kit.get("sp", {})
	for z: String in ["pecho", "manga", "espalda", "short"]:
		u["hay_sp_" + z] = sp.has(z)
		if sp.has(z):
			var info: Dictionary = sp[z]
			var fondo: Color = cols[0]
			if z == "short":
				fondo = _col(pant.get("c1", "ffffff"))
			var hx := String(info.get("color", "#ffffff"))
			var solo := z == "manga" or z == "short"
			u["sp_" + z] = SponsorKit.textura(String(info.get("marca", "")), hx, SponsorKit.color_letras(hx, fondo), solo)
			u["sp_asp_" + z] = SponsorKit.aspecto(String(info.get("marca", "")), hx, SponsorKit.color_letras(hx, fondo), solo)
	return u
