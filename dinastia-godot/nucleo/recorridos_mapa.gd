class_name RecorridosMapa
extends RefCounted
## LOS RECORRIDOS «RED» SOBRE EL MAPA (28-10-2026, órdenes 16 y 17 del dueño: «los recorridos se crean basándose en el mapa, y de ahí
## salen los códigos de paradero, las patentes, los números de recorrido y el nombre de las calles en el paradero»).
## Cada recorrido es una lista de ESQUINAS por calles que existen de verdad (la rejilla de `CiudadExpansion` y el anillo, la
## circunvalación y los conectores del club de `CityBuilder`); la prueba `red_app` comprueba que cada tramo está en la red vial.
##  · NÚMERO por el SECTOR donde nace (`RecorridosRed.sector_de` de su primera esquina): 1xx el club, 2xx el centro, 3xx el este,
##    4xx el sur, 5xx el oeste y el puerto, 6xx la periferia. La VUELTA es el mismo número con «c» (las esquinas al revés).
##    «e» = alternativa por un desvío: el 301e va del Mall a Villa Sur por Av. Los Andes en vez de Av. La Cordillera y vuelve
##    como 301c. Dos LOCALES de barrio: C02 (Barrio ↔ Mercado) y C09 (Universidad ↔ Parque El Lago).
##  · LOS PARADEROS salen de los recorridos: en cada eje de la rejilla, uno a mitad de la cuadra central entre dos avenidas
##    (cada 330 m: coordenada ≡ 165 m), a cada lado de la calle según el sentido; en el núcleo, los cuatro del anillo del club.
##    Los recorridos que pasan por el mismo punto y en el mismo sentido comparten paradero. Así cada uno tiene de 2 a 5.
##  · NOMBRE = calle / próxima esquina (`CallesCiudad`); CÓDIGO = «PA» + sector + 3 cifras, numerados en orden por sector.
##  · Todo es determinista y no necesita la escena: la app del móvil lo consulta aunque la ciudad no esté montada.

const PASO := 330.0
const DESFASE := 165.0
const MARGEN := 20.0
const LADO_RIO := 60.0              ## sin paraderos sobre los puentes
const ACERA_NUCLEO := 13.0          ## como las marquesinas del anillo (`CityBuilder._paradas_bus`)
const ACERA_AV := 14.4              ## media avenida (12) + 0,6 de acera
const ACERA_CALLE := 9.4

## [número, esquinas de la ida, destino de la ida, destino de la vuelta]. El «e» no tiene «c»: vuelve como su base.
const DEFS := [
	["101", [Vector2(205, 262), Vector2(205, -282), Vector2(330, -282), Vector2(330, -660), Vector2(0, -660), Vector2(0, -990)], "Centro Financiero", "Estadio"],
	["122", [Vector2(-205, 262), Vector2(-205, -282), Vector2(-330, -282), Vector2(-330, -660), Vector2(-660, -660)], "Puerto", "Estadio"],
	["150", [Vector2(-60, 425), Vector2(-60, 350), Vector2(205, 350), Vector2(205, 262), Vector2(330, 262), Vector2(330, 990), Vector2(660, 990)], "Universidad", "Barrio"],
	["190", [Vector2(205, -282), Vector2(205, 262), Vector2(330, 262), Vector2(330, 660), Vector2(440, 660), Vector2(440, 0), Vector2(660, 0)], "Hospital", "Estadio"],
	["C02", [Vector2(-60, 425), Vector2(-60, 350), Vector2(-205, 350), Vector2(-205, -282), Vector2(-330, -282), Vector2(-330, -660), Vector2(-110, -660)], "Mercado", "Barrio"],
	["203", [Vector2(0, -990), Vector2(0, -660), Vector2(-660, -660)], "Puerto", "Centro Financiero"],
	["217", [Vector2(-330, -660), Vector2(660, -660), Vector2(660, -330), Vector2(990, -330)], "Mall Oriente", "Mercado"],
	["226", [Vector2(0, -660), Vector2(660, -660), Vector2(660, 0), Vector2(440, 0)], "Hospital", "Municipalidad"],
	["278", [Vector2(0, -990), Vector2(0, -660), Vector2(330, -660), Vector2(330, -440), Vector2(440, -440), Vector2(440, 660), Vector2(330, 660), Vector2(330, 990), Vector2(0, 990)], "Parque El Lago", "Centro Financiero"],
	["301", [Vector2(990, -330), Vector2(660, -330), Vector2(660, 660), Vector2(330, 660), Vector2(330, 990)], "Villa Sur", "Mall Oriente"],
	["301e", [Vector2(990, -330), Vector2(990, 660), Vector2(330, 660), Vector2(330, 990)], "Villa Sur", ""],
	["307", [Vector2(990, -330), Vector2(990, 660), Vector2(660, 660), Vector2(660, 990)], "Universidad", "Mall Oriente"],
	["341", [Vector2(990, -330), Vector2(990, 660), Vector2(330, 660), Vector2(330, 990), Vector2(0, 990)], "Parque El Lago", "Mall Oriente"],
	["405", [Vector2(0, 990), Vector2(660, 990), Vector2(660, 0), Vector2(440, 0), Vector2(440, -220)], "Hospital", "Parque El Lago"],
	["C09", [Vector2(660, 990), Vector2(0, 990)], "Parque El Lago", "Universidad"],
	["502", [Vector2(-660, -660), Vector2(-660, 0), Vector2(-392, 0), Vector2(-392, -282), Vector2(-205, -282), Vector2(-205, 262)], "Estadio", "Puerto"],
	["506", [Vector2(-990, 660), Vector2(-990, 0), Vector2(-392, 0), Vector2(-392, -282), Vector2(-205, -282), Vector2(-205, 262)], "Estadio", "Cocheras Poniente"],
	["511", [Vector2(-990, 660), Vector2(-990, 0), Vector2(-660, 0), Vector2(-660, -660)], "Puerto", "Cocheras Poniente"],
	["604", [Vector2(0, -1320), Vector2(1320, -1320), Vector2(1320, 1320), Vector2(0, 1320)], "Villa Los Cóndores", "Villa Las Vizcachas"],
	["610", [Vector2(0, -1320), Vector2(-1320, -1320), Vector2(-1320, 1320), Vector2(0, 1320)], "Villa Los Cóndores", "Villa Las Vizcachas"],
	["630", [Vector2(1320, 0), Vector2(1320, 1320), Vector2(-1320, 1320), Vector2(-1320, 0)], "Las Tinajas", "Cerro Blanco"],
	["648", [Vector2(-1320, 0), Vector2(-1320, -1320), Vector2(1320, -1320), Vector2(1320, 0)], "Cerro Blanco", "Las Tinajas"],
]
## Los cuatro paraderos del anillo del club (los monta `CityBuilder._paradas_bus`): [punto del eje, sentido, esquina con nombre].
const DEL_CLUB := [
	[Vector2(205, -170), Vector2(0, 1), "Estadio"],
	[Vector2(205, 140), Vector2(0, 1), "Zona Industrial"],
	[Vector2(-205, 110), Vector2(0, -1), "Centro Comercial"],
	[Vector2(-60, 410), Vector2(0, -1), "Barrio"],
]

static var _datos: Dictionary = {}

## {servicios: {número: S}, paraderos: {código: P}, orden: [códigos]}.
##   S = {numero, base, local, sector, destino, ejes: PackedVector2Array, largo, paraderos: [código], dist: [m desde la cabecera]}
##   P = {codigo, nombre, calle, cruce, eje: Vector2, dir: Vector2, lado: Vector2, pos: Vector3, giro, sector, club, recorridos}
static func datos() -> Dictionary:
	if _datos.is_empty():
		_datos = _armar()
	return _datos

static func servicio(num: String) -> Dictionary:
	return datos()["servicios"].get(num, {})

static func paradero(cod: String) -> Dictionary:
	return datos()["paraderos"].get(cod, {})

## Los números en orden (troncales por número, cada uno con su «c»; los locales al final).
static func servicios() -> Array[String]:
	var out: Array[String] = []
	for k: String in datos()["servicios"]:
		out.append(k)
	out.sort_custom(RecorridosMapa.antes)
	return out

static func antes(a: String, c: String) -> bool:
	var la := a.begins_with("C")
	var lc := c.begins_with("C")
	return a < c if la == lc else lc

## La vuelta de un servicio de ida («122» → «122c»; el «301e» vuelve como «301c»).
static func vuelta_de(num: String) -> String:
	return num.trim_suffix("e") + "c" if not num.ends_with("c") else num.trim_suffix("c")

## El paradero más cercano a `pos` (en el plano), o "" si no hay ninguno a menos de `radio` metros.
static func cercano(pos: Vector3, radio := 40.0) -> String:
	var mejor := ""
	var dmin := radio
	for cod: String in datos()["orden"]:
		var d := (paradero(cod)["pos"] as Vector3).distance_to(Vector3(pos.x, 0.0, pos.z))
		if d <= dmin:
			dmin = d
			mejor = cod
	return mejor

static func _armar() -> Dictionary:
	var servs := {}
	var tmp := {}   ## clave del punto y sentido → {eje, dir, calle, cruce, servicios}
	for d: Array in DEFS:
		var num := String(d[0])
		var ida := PackedVector2Array(d[1])
		servs[num] = _servicio(num, ida, String(d[2]), tmp)
		if not num.ends_with("e"):
			var vuelta := ida.duplicate()
			vuelta.reverse()
			servs[num + "c"] = _servicio(num + "c", vuelta, String(d[3]), tmp)
	## Los códigos, en orden por sector (y dentro, de norte a sur y de oeste a este).
	var claves: Array = tmp.keys()
	claves.sort_custom(func(a: String, c: String) -> bool:
		var pa: Dictionary = tmp[a]
		var pc: Dictionary = tmp[c]
		if int(pa["sector"]) != int(pc["sector"]):
			return int(pa["sector"]) < int(pc["sector"])
		var ea: Vector2 = pa["eje"]
		var ec: Vector2 = pc["eje"]
		if not is_equal_approx(ea.y, ec.y):
			return ea.y < ec.y
		if not is_equal_approx(ea.x, ec.x):
			return ea.x < ec.x
		return a < c)
	var pars := {}
	var orden: Array[String] = []
	var cuenta := {}
	var de_clave := {}
	for k: String in claves:
		var p: Dictionary = tmp[k]
		var s := int(p["sector"])
		cuenta[s] = int(cuenta.get(s, 0)) + 1
		var cod := "PA%d%03d" % [s / 100, int(cuenta[s])]
		p["codigo"] = cod
		p["nombre"] = "%s / %s" % [p["calle"], p["cruce"]] if String(p["cruce"]) != "" else String(p["calle"])
		var rs: Array[String] = []
		for r: String in p["servicios"]:
			rs.append(r)
		rs.sort_custom(RecorridosMapa.antes)
		p["recorridos"] = rs
		p.erase("servicios")
		pars[cod] = p
		orden.append(cod)
		de_clave[k] = cod
	for num: String in servs:
		var cods: Array[String] = []
		for k: String in servs[num]["claves"]:
			cods.append(String(de_clave[k]))
		servs[num]["paraderos"] = cods
		servs[num].erase("claves")
	return {"servicios": servs, "paraderos": pars, "orden": orden}

static func _servicio(num: String, ejes: PackedVector2Array, destino: String, tmp: Dictionary) -> Dictionary:
	var claves: Array[String] = []
	var dist: Array[float] = []
	var hecho := 0.0
	for i in ejes.size() - 1:
		var a := ejes[i]
		var c := ejes[i + 1]
		var dir := (c - a).normalized()
		for q: Array in _paradas_tramo(a, c):
			var e: Vector2 = q[0]
			var k := "%d,%d,%d,%d" % [roundi(e.x), roundi(e.y), roundi(dir.x), roundi(dir.y)]
			if not tmp.has(k):
				var lado := Vector2(-dir.y, dir.x)   ## a la derecha de la marcha (en Chile se circula por la derecha)
				var ancho := _acera(a, c)
				var pos := e + lado * ancho
				tmp[k] = {"eje": e, "dir": dir, "lado": lado, "pos": Vector3(pos.x, 0.0, pos.y),
					"giro": atan2(-lado.x, -lado.y), "sector": RecorridosRed.sector_de(Vector3(e.x, 0.0, e.y)),
					"calle": CallesCiudad.calle_del_eje(a, c), "cruce": String(q[1]) if String(q[1]) != "" else CallesCiudad.cruce(e, dir),
					"club": String(q[1]) != "", "servicios": []}
			if not (tmp[k]["servicios"] as Array).has(num):
				(tmp[k]["servicios"] as Array).append(num)
				claves.append(k)
				dist.append(hecho + a.distance_to(e))
		hecho += a.distance_to(c)
	var sector := RecorridosRed.sector_de(Vector3(ejes[0].x, 0.0, ejes[0].y))
	return {"numero": num, "base": RecorridosRed.base_de(num), "local": num.begins_with("C"), "sector": sector,
		"destino": destino, "ejes": ejes, "largo": hecho, "claves": claves, "dist": dist}

## Medio ancho de calzada más acera del tramo: las calles del club, las avenidas (y el bulevar) y las calles de la rejilla.
static func _acera(a: Vector2, c: Vector2) -> float:
	var vertical := absf(a.x - c.x) < 0.5
	var linea := (a.x if vertical else a.y) / CallesCiudad.CELDA
	if absf(linea - roundf(linea)) > 0.001:
		return ACERA_NUCLEO
	if vertical:
		return ACERA_AV if CallesCiudad.es_avenida_columna(roundi(linea)) else ACERA_CALLE
	return ACERA_AV if CallesCiudad.es_avenida_fila(roundi(linea)) else ACERA_CALLE

## Los paraderos de un tramo recto de `a` a `c`, en orden: [punto del eje, esquina con nombre ("" = la calcula `CallesCiudad`)].
static func _paradas_tramo(a: Vector2, c: Vector2) -> Array:
	var out: Array = []
	var horizontal := absf(c.x - a.x) > absf(c.y - a.y)
	var eje := a.y if horizontal else a.x
	var v0 := a.x if horizontal else a.y
	var v1 := c.x if horizontal else c.y
	var lo := minf(v0, v1)
	var hi := maxf(v0, v1)
	var dir := (c - a).normalized()
	if absf(eje / CallesCiudad.CELDA - roundf(eje / CallesCiudad.CELDA)) < 0.001:
		var k := ceili((lo - DESFASE) / PASO)
		while DESFASE + PASO * float(k) <= hi:
			var v := DESFASE + PASO * float(k)
			var pt := Vector2(v, eje) if horizontal else Vector2(eje, v)
			if v > lo + MARGEN and v < hi - MARGEN and absf(pt.x - CallesCiudad.RIO_X) >= LADO_RIO:
				out.append([pt, ""])
			k += 1
	for q: Array in DEL_CLUB:
		var p: Vector2 = q[0]
		if (q[1] as Vector2).is_equal_approx(dir) and Geometry2D.get_closest_point_to_segment(p, a, c).distance_to(p) < 0.5:
			out.append([p, String(q[2])])
	out.sort_custom(func(x: Array, y: Array) -> bool: return a.distance_to(x[0]) < a.distance_to(y[0]))
	return out
