class_name SorteoNombre
## LAS BOLSAS DE NOMBRES YA RESUELTAS (M-349, 3-11-2026). `Mundo._sortear_nombre` buscaba en cada intento las tablas, la bolsa regional, la de Europa o Brasil y la
## extra: ~3,5 µs por intento y varios intentos por jugador (los nombres repetidos se reintentan). El resultado solo depende del país y la región, así que se
## resuelve una vez y se guarda. Las bolsas son exactamente las de antes: sortear de ellas consume el azar igual y el mundo sale con la misma huella.
static var _pares: Dictionary = {}

## `Datos.usar_base_real()` la llama al cambiar de base: las tablas de nombres pueden ser otras.
static func invalidar() -> void:
	_pares = {}

## [nombres, apellidos] del país y la región, o [] si no hay bolsa (entonces el nombre es «Jugador N»).
static func bolsas(pais: String, region: String = "") -> Array:
	var clave := pais + "|" + region
	if _pares.has(clave):
		return _pares[clave]
	var par := _resolver(pais, region)
	_pares[clave] = par
	return par

static func _resolver(pais: String, region: String) -> Array:
	var n: Array = Datos.tabla("NOMBRES")
	var a: Array = Datos.tabla("APELLIDOS")
	var pools: Variant = Datos.tabla("POOLS_EU")
	## España con su región (C3): bolsa general o vasca, ya no todos vascos.
	var propias := Regiones.bolsas(pais, region)
	if not propias.is_empty():
		n = propias[0]
		a = propias[1]
	elif pools is Dictionary and (pools as Dictionary).has(pais):
		var par: Array = (pools as Dictionary)[pais]
		if par.size() >= 2 and not (par[0] as Array).is_empty() and not (par[1] as Array).is_empty():
			n = par[0]
			a = par[1]
	elif pais == "BRA":
		var nb: Variant = Datos.tabla("NOMBRES_BRA")
		var ab: Variant = Datos.tabla("APELLIDOS_BRA")
		if nb is Array and not (nb as Array).is_empty() and ab is Array and not (ab as Array).is_empty():
			n = nb
			a = ab
	if n == null or a == null or n.is_empty() or a.is_empty():
		return []
	## M-331: las bolsas de la base eran de 14×14; se suman las de `datos/bolsas_nombres.json` (la vasca se deja tal cual: es un sabor).
	if region != "EUS":
		var extra := Mundo._bolsa_extra(pais)
		if not extra.is_empty():
			n = n + (extra[0] as Array)
			a = a + (extra[1] as Array)
	return [n, a]
