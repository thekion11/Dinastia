class_name PlazasConti
extends RefCounted
## QUIÉN SE CLASIFICA A CADA TORNEO CONTINENTAL (antes vivía dentro de `Continental`; se sacó al crecer los formatos).
##
## Cuántas plazas tiene cada torneo y cómo se reparten por país sale de `FormatosConti` (tabla `cupos`). Aquí solo está
## el mecanismo: el orden de mérito de un país, el reparto sin repetir clubes y el relleno cuando faltan.

## El país que arma el reparto de Sudamérica: tres plazas de Libertadores (una para el campeón de la copa nacional) y
## tres de Sudamericana. Es la premisa del juego, igual que el HTML.
const PAIS_ANFITRION := "CHI"
## La copa grande de cada confederación va primero y comparte el conjunto de clasificados con la chica:
## por eso a la Sudamericana le llega el cuarto de Argentina y no el primero.
const EUROPA := ["ucl", "uel", "uecl"]

## Reputación, y el id como desempate (`sort_custom` no es estable: sin un criterio final la misma semilla podría dar
## dos órdenes distintos y se acaba la repetibilidad del banco).
static func mas_reputado(a: Club, b: Club) -> bool:
	if a.rep != b.rep:
		return a.rep > b.rep
	return a.id < b.id

## El orden de mérito de un país: la tabla de su Primera si ya se ha jugado algo, y la reputación si el mundo está
## recién generado.
static func orden_de_pais(clubes: Array, ligas: Array, pais: String) -> Array[Club]:
	for l: Liga in ligas:
		if l.pais != pais or l.division() != 1:
			continue
		var t := l.tabla()
		if not t.is_empty() and int(t[0].get("pj", 0)) > 0:
			var salida: Array[Club] = []
			for f: Dictionary in t:
				salida.append(f["club"])
			return salida
		break
	var pool: Array[Club] = []
	for c: Club in clubes:
		if c.pais == pais and c.division == 1:
			pool.append(c)
	pool.sort_custom(mas_reputado)
	return pool

## Reparte `n` plazas de la lista ordenada de un país saltándose a quien ya tiene plaza.
static func tomar(destino: Array[Club], candidatos: Array[Club], n: int, usado: Dictionary) -> void:
	var puestas := 0
	for c: Club in candidatos:
		if puestas >= n:
			break
		if usado.has(c.id):
			continue
		destino.append(c)
		usado[c.id] = true
		puestas += 1

## Completa una copa hasta sus plazas con los mejores clubes que queden de su confederación (cualquier división).
static func rellenar(lista: Array[Club], clubes: Array, k: String, usado: Dictionary) -> void:
	var plazas := FormatosConti.plazas(k)
	if lista.size() >= plazas:
		return
	var paises := FormatosConti.paises_de(k)
	var extra: Array[Club] = []
	for c: Club in clubes:
		if usado.has(c.id) or not paises.has(c.pais):
			continue
		extra.append(c)
	extra.sort_custom(mas_reputado)
	for c: Club in extra:
		if lista.size() >= plazas:
			break
		lista.append(c)
		usado[c.id] = true

static func _orden(clubes: Array, ligas: Array, cache: Dictionary, pais: String) -> Array[Club]:
	if cache.has(pais):
		return cache[pais]
	var lista := orden_de_pais(clubes, ligas, pais)
	cache[pais] = lista
	return lista

static func _por_cupos(destino: Array[Club], k: String, clubes: Array, ligas: Array, cache: Dictionary, usado: Dictionary) -> void:
	for fila: Array in FormatosConti.cupos(k):
		tomar(destino, _orden(clubes, ligas, cache, String(fila[0])), int(fila[1]), usado)
	rellenar(destino, clubes, k, usado)

## El cuadro de plazas de los torneos: clave -> Array[Club].
##
## `campeon_copa` es el campeón de la copa nacional, que se lleva una plaza directa de Libertadores. Solo entra si su país
## pertenece de verdad a la confederación; si no, la plaza vuelve al tercero de la liga anfitriona.
static func plazas(clubes: Array, ligas: Array, campeon_copa: Club = null) -> Dictionary:
	var cache := {}
	var salida := {}

	## Sudamérica: Libertadores primero y Sudamericana después, compartiendo el conjunto de clasificados.
	var usado_sur := {}
	var lib: Array[Club] = []
	var sud: Array[Club] = []
	tomar(lib, _orden(clubes, ligas, cache, PAIS_ANFITRION), 2, usado_sur)
	if campeon_copa != null and not usado_sur.has(campeon_copa.id) \
			and FormatosConti.paises_de("lib").has(campeon_copa.pais):
		lib.append(campeon_copa)
		usado_sur[campeon_copa.id] = true
	else:
		tomar(lib, _orden(clubes, ligas, cache, PAIS_ANFITRION), 1, usado_sur)
	_por_cupos(lib, "lib", clubes, ligas, cache, usado_sur)
	tomar(sud, _orden(clubes, ligas, cache, PAIS_ANFITRION), 3, usado_sur)
	_por_cupos(sud, "sud", clubes, ligas, cache, usado_sur)
	salida["lib"] = lib
	salida["sud"] = sud

	## Europa: Champions, Europa League y Conference comparten el conjunto de clasificados, en ese orden.
	var usado_eu := {}
	for k: String in EUROPA:
		var lista: Array[Club] = []
		_por_cupos(lista, k, clubes, ligas, cache, usado_eu)
		salida[k] = lista

	## Asia, África, Oceanía y Concacaf: sin cupos escritos, a partes iguales entre sus países (redondeo hacia arriba).
	## Oceanía es un solo país, así que se lleva todas las plazas.
	## La Confederación africana comparte clasificados con la Champions africana (la grande va primero).
	var usado_af := {}
	for k: String in ["asia", "afr", "afr2", "oce", "conc"]:
		var paises := FormatosConti.paises_de(k)
		if paises.is_empty():
			continue
		var n := FormatosConti.plazas(k)
		var cupo := n if paises.size() <= 1 else ceili(float(n) / float(paises.size()))
		var usado: Dictionary = usado_af if k.begins_with("afr") else {}
		var pool: Array[Club] = []
		for p in paises:
			tomar(pool, _orden(clubes, ligas, cache, String(p)), cupo, usado)
		rellenar(pool, clubes, k, usado)
		salida[k] = pool

	for k: String in salida.keys():
		var lista2: Array[Club] = salida[k]
		var tope := FormatosConti.plazas(k)
		if lista2.size() > tope:
			lista2.resize(tope)
	return salida
