class_name CallesCiudad
extends RefCounted
## LOS NOMBRES DE LAS CALLES DE LA CIUDAD (28-10-2026, órdenes 16 y 17 del dueño: «los recorridos se crean basándose en el mapa, y de
## ahí salen… el nombre de las calles en el paradero»). Nombres chilenos inventados y creíbles: árboles y flores nativos, aves,
## lugares y oficios; NINGUNA persona. Una sola fuente para las placas de las esquinas (`CiudadExpansion._placas_de_calle`), el
## letrero del modo a pie, los paraderos «Red» (`RecorridosMapa`) y el mapa del transporte.
##  · La REJILLA de la ciudad grande (`CiudadExpansion`): cada fila (z fija, de oeste a este) y cada columna (x fija, de norte a sur)
##    tiene su nombre; las avenidas (una de cada tres y el bulevar que rodea el club) llevan «Av.», las calles van sin prefijo,
##    como en los letreros de Santiago («Av. Los Pimientos», «El Peumo»).
##  · El NÚCLEO del club (`CityBuilder`): el anillo, la circunvalación, el pasaje del barrio y el acceso. Los conectores con la
##    rejilla siguen su fila o su columna (x = ±330 es Av. Las Araucarias / Av. El Salitre; z = 0, Av. La Herradura).
## Todo es estático y no necesita la escena: `calle_en(posicion)` responde con la ciudad sin montar.

const CELDA := 110.0
const K := 12
const NUC_X0 := -550.0
const NUC_X1 := 440.0
const NUC_Z0 := -440.0
const NUC_Z1 := 660.0
const RIO_X := -470.0
const RIO_MEDIO := 50.0
const FINCA := Rect2(-220.0, 660.0, 220.0, 220.0)
const ANCHO_AV := 24.0
const ANCHO_CALLE := 14.0
const ACERA := 4.0

## Columnas (x = i · 110), de i = −12 a 12.
const COLUMNAS := ["Av. Las Tinajas", "Los Chincoles", "Los Talleres", "Av. La Chimba", "Los Tejares", "Las Bodegas",
	"Av. Los Pescadores", "Av. La Ribera", "El Molle", "Av. El Salitre", "Los Aromos", "El Peumo", "Av. Los Copihues",
	"Las Camelias", "Los Maitenes", "Av. Las Araucarias", "Av. Los Alerces", "El Coigüe", "Av. La Cordillera", "Los Litres",
	"Las Lilas", "Av. Los Andes", "Los Zorzales", "Las Diucas", "Av. Cerro Blanco"]
## Filas (z = j · 110), de j = −12 a 12.
const FILAS := ["Av. Las Vizcachas", "Los Canelos", "Los Espinos", "Av. El Algarrobo", "Los Jazmines", "El Arrayán",
	"Av. Los Pimientos", "Las Achiras", "Av. El Estadio", "Av. Las Golondrinas", "Los Tordos", "Las Loicas", "Av. La Herradura",
	"El Belloto", "Los Lingues", "Av. Los Quillayes", "El Ulmo", "Las Pataguas", "Av. El Sauce", "Los Raulíes", "El Chañar",
	"Av. Las Acacias", "Los Queltehues", "Las Tencas", "Av. Los Cóndores"]
## Las calles del núcleo: [desde, hasta, nombre, medio ancho de calzada]. Medidas de `CityBuilder` (RING_X 205, RING_Z −320/350,
## circunvalación ±392 / −282 / 262, ramal del barrio en x = −60 hasta el portón y acceso al estadio en x = 0).
const NUCLEO := [
	[Vector2(205, -320), Vector2(205, 350), "Av. Los Hinchas", 8.0],
	[Vector2(-205, -320), Vector2(-205, 350), "Av. La Galería", 8.0],
	[Vector2(-205, -320), Vector2(205, -320), "Av. Los Campeones", 8.0],
	[Vector2(-205, 350), Vector2(205, 350), "Av. La Cantera", 8.0],
	[Vector2(392, -282), Vector2(392, 262), "Circunvalación Oriente", 8.0],
	[Vector2(-392, -282), Vector2(-392, 262), "Circunvalación Poniente", 8.0],
	[Vector2(-392, -282), Vector2(392, -282), "Circunvalación Norte", 8.0],
	[Vector2(-392, 262), Vector2(392, 262), "Circunvalación Sur", 8.0],
	[Vector2(392, 0), Vector2(440, 0), "Av. La Herradura", 8.0],
	[Vector2(-550, 0), Vector2(-392, 0), "Av. La Herradura", 8.0],
	[Vector2(330, -440), Vector2(330, -282), "Av. Las Araucarias", 8.0],
	[Vector2(-330, -440), Vector2(-330, -282), "Av. El Salitre", 8.0],
	[Vector2(330, 262), Vector2(330, 660), "Av. Las Araucarias", 8.0],
	[Vector2(-330, 262), Vector2(-330, 660), "Av. El Salitre", 8.0],
	[Vector2(-60, 350), Vector2(-60, 425), "Pasaje Las Azucenas", 8.0],
	[Vector2(0, -85), Vector2(0, 340), "Av. Los Copihues", 8.0],
]

static func nombre_columna(i: int) -> String:
	return String(COLUMNAS[clampi(i + K, 0, COLUMNAS.size() - 1)])

static func nombre_fila(j: int) -> String:
	return String(FILAS[clampi(j + K, 0, FILAS.size() - 1)])

static func es_avenida_columna(i: int) -> bool:
	return i % 3 == 0 or i == -5 or i == 4

static func es_avenida_fila(j: int) -> bool:
	return j % 3 == 0 or j == -4 or j == 6

static func dentro_nucleo(x: float, z: float, margen: float = 0.0) -> bool:
	return x > NUC_X0 + margen and x < NUC_X1 - margen and z > NUC_Z0 + margen and z < NUC_Z1 - margen

## ¿Existe la cuadra de la rejilla entre dos cruces vecinos? La misma regla que `CiudadExpansion._tramo_rejilla` y `armar_red`
## (la prueba `red_app` lo compara con los tramos de la ciudad montada): ni dentro del club salvo su borde, ni en la finca, ni
## calles a lo largo del río.
static func existe_tramo(ka: Vector2i, kb: Vector2i) -> bool:
	if absi(ka.x) > K or absi(ka.y) > K or absi(kb.x) > K or absi(kb.y) > K or absi(ka.x - kb.x) + absi(ka.y - kb.y) != 1:
		return false
	var a := Vector2(ka) * CELDA
	var c := Vector2(kb) * CELDA
	var m := (a + c) * 0.5
	if ka.x == kb.x and absf(a.x - RIO_X) < RIO_MEDIO + 10.0:
		return false
	if FINCA.grow(-1.0).has_point(m):
		return false
	var borde := false
	if ka.x == kb.x:
		borde = (absf(a.x - NUC_X0) < 0.1 or absf(a.x - NUC_X1) < 0.1) and m.y >= NUC_Z0 - 1.0 and m.y <= NUC_Z1 + 1.0
	else:
		borde = (absf(a.y - NUC_Z0) < 0.1 or absf(a.y - NUC_Z1) < 0.1) and m.x >= NUC_X0 - 1.0 and m.x <= NUC_X1 + 1.0
	return borde or not dentro_nucleo(m.x, m.y, -1.0)

## La calle de un punto de la calzada o de su acera («» si cae dentro de una manzana). En un cruce de la rejilla, «Fila con Columna».
static func calle_en(p: Vector3) -> String:
	if dentro_nucleo(p.x, p.z, -1.0):
		var mejor := ""
		var dmin := INF
		for s: Array in NUCLEO:
			var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), s[0], s[1])
			var d := q.distance_to(Vector2(p.x, p.z))
			if d < float(s[3]) + ACERA and d < dmin:
				dmin = d
				mejor = String(s[2])
		## El bulevar que rodea el club es de la rejilla (Av. La Ribera, Av. Los Alerces, Av. El Estadio, Av. El Sauce).
		var medio := ANCHO_AV * 0.5 + ACERA
		if mejor == "" and (absf(p.x - NUC_X0) < medio or absf(p.x - NUC_X1) < medio):
			mejor = nombre_columna(roundi(p.x / CELDA))
		elif mejor == "" and (absf(p.z - NUC_Z0) < medio or absf(p.z - NUC_Z1) < medio):
			mejor = nombre_fila(roundi(p.z / CELDA))
		return mejor
	var i := roundi(p.x / CELDA)
	var j := roundi(p.z / CELDA)
	if absi(i) > K or absi(j) > K:
		return ""
	var en_col := absf(p.x - float(i) * CELDA) < ((ANCHO_AV if es_avenida_columna(i) else ANCHO_CALLE) * 0.5 + ACERA)
	var en_fila := absf(p.z - float(j) * CELDA) < ((ANCHO_AV if es_avenida_fila(j) else ANCHO_CALLE) * 0.5 + ACERA)
	if en_col and en_fila:
		return "%s con %s" % [nombre_fila(j), nombre_columna(i)]
	if en_col:
		return nombre_columna(i)
	if en_fila:
		return nombre_fila(j)
	return ""

## La calle de un eje recto (el que recorre un bus): fila, columna o calle del núcleo. `a` y `c` son puntos del eje (x, z).
static func calle_del_eje(a: Vector2, c: Vector2) -> String:
	var m := (a + c) * 0.5
	if dentro_nucleo(m.x, m.y, -1.0):
		for s: Array in NUCLEO:
			if _sobre(a, s) and _sobre(c, s):
				return String(s[2])
	if absf(a.x - c.x) < 0.5:
		return nombre_columna(roundi(a.x / CELDA))
	return nombre_fila(roundi(a.y / CELDA))

static func _sobre(p: Vector2, s: Array) -> bool:
	return Geometry2D.get_closest_point_to_segment(p, s[0], s[1]).distance_to(p) < 0.6

## La esquina con nombre de un punto del eje que va hacia `dir`: la próxima calle que lo cruza en el sentido de la marcha (a menos
## de 200 m); si no hay, la más cercana por detrás. Cuentan las cuadras de la rejilla que existen y las calles del núcleo.
static func cruce(p: Vector2, dir: Vector2) -> String:
	var horizontal := absf(dir.x) > absf(dir.y)
	var cands: Array = []   ## [avance sobre el eje, nombre]
	var base := roundi((p.x if horizontal else p.y) / CELDA)
	var fija := roundi((p.y if horizontal else p.x) / CELDA)
	var en_rejilla := absf((p.y if horizontal else p.x) - float(fija) * CELDA) < 0.6
	for k in range(base - 3, base + 4):
		if not en_rejilla:
			break
		var nodo := Vector2i(k, fija) if horizontal else Vector2i(fija, k)
		var perp := Vector2i(0, 1) if horizontal else Vector2i(1, 0)
		if existe_tramo(nodo, nodo + perp) or existe_tramo(nodo, nodo - perp):
			var q := Vector2(nodo) * CELDA
			cands.append([(q - p).dot(dir), nombre_columna(k) if horizontal else nombre_fila(k)])
	for s: Array in NUCLEO:
		var sa: Vector2 = s[0]
		var sb: Vector2 = s[1]
		if (absf(sa.x - sb.x) < 0.5) == (not horizontal):
			continue   ## paralela
		var corte: Variant = Geometry2D.segment_intersects_segment(p - dir * 400.0, p + dir * 400.0, sa, sb)
		if corte != null:
			cands.append([((corte as Vector2) - p).dot(dir), String(s[2])])
	var delante := ""
	var dd := 200.0
	var cerca := ""
	var dc := INF
	for c: Array in cands:
		var t := float(c[0])
		if t > 1.0 and t < dd:
			dd = t
			delante = String(c[1])
		if absf(t) < dc and absf(t) > 1.0:
			dc = absf(t)
			cerca = String(c[1])
	return delante if delante != "" else cerca
