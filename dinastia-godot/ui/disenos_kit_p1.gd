extends RefCounted
## [Capa 1/5 de `disenos_kit.gd`] claves, diseno, indice_diseno, indice_de, _diseno_de, marca_de … (+8)

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

## EL FABRICANTE DE LA ROPA (21-10-2026, M-057): el de tu club es el proveedor
## que firmaste (`Comercial.proveedor`); el de los demás, uno fijo por club.
const MARCA_FORMA := {"propia": 0, "korrida": 1, "adistar": 2, "numbra": 3, "pumba": 4, "volk": 5}

## ------------------------------------------------------------ EL DIBUJO 2D

static var _cache: Dictionary = {}
static var _silueta: Image = null

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

## El diseño de la camiseta: el que eligió el jugador; si no, el del club real al
## que representa (tabla ESTADIO_CLUB, campo «camiseta»); si no, el del hash.
static func _diseno_de(c: Club) -> String:
	if c.kit_estilo == "":
		var real := String(c.fila_estadio_real().get("camiseta", ""))
		if real != "":
			return real
	return Jersey.kit_de(c, c.kit_estilo)
static func marca_de(c: Club) -> String:
	var m := Mundo.actual()
	if m != null and m.comercial != null and m.mi_club() == c:
		return m.comercial.proveedor
	var ids: Array = MARCA_FORMA.keys()
	return String(ids[1 + absi(hash(c.id + "proveedor")) % (ids.size() - 1)])

## La equipación completa de un club: la guardada (`kit_x`) sobre los valores
## que salen de sus colores de siempre.
static func kit_de_club(c: Club) -> Dictionary:
	var c1 := c.color_kit1()
	var c2 := c.color_kit2()
	var base := {
		"dis": _diseno_de(c),
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
	## EL ESCUDO DEL CLUB EN LA CAMISETA (14-10-2026): el mismo escudo que se ve en
	## las fichas, no un escudete genérico.
	base["escudo_tex"] = Escudo.textura(c, 64)
	base["marca"] = marca_de(c)
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
