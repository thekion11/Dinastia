class_name OnceAuto
## LA PRIMERA VUELTA DEL ONCE AUTOMÁTICO (M-469, 3-11-2026), sacada de `Club.once`: para cada ranura de la formación (porteros primero) el mejor de los libres según su media en ese
## puesto, su forma, su moral y lo cómodo que está ahí. Es el bucle que más pesa de la semana (466 onces × ~275 `media_en`): con la extensión nativa (`nativo/src`, `once_asignar_libres`)
## corre en C++ con las mismas cuentas; sin ella (Web, `DINASTIA_SIN_NATIVO=1`, binario viejo) corre `asignar_gd`, el bucle de siempre. `pruebas/probar_nativo.tscn` compara los dos.

## {ranura: Jugador} para las ranuras que algún libre pudo ocupar, insertadas en el orden de `orden`.
static func asignar(libres: Array, ranuras: Array, orden: Array) -> Dictionary:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("once_asignar_libres"):
		return _nativo(nat, libres, ranuras, orden)
	return asignar_gd(libres, ranuras, orden)

## demarcación → grupo (POR/DEF/MED/DEL), una vez: el nativo la pide para el encaje por línea.
static var _grupo_de: Dictionary = {}

## (10-11, paso a C++) Lo que solo depende de la formación se hace UNA vez: el orden de las ranuras (porteros primero) y las ranuras empaquetadas para la extensión. Misma salida que antes
## (se calcula con el mismo código, solo que se guarda); la clave es la propia lista de ranuras de `FORMS` (la misma instancia siempre).
static var _cache: Array = []   ## [ranuras, orden, paquete]

static func _entrada(ranuras: Array) -> Array:
	for e: Array in _cache:
		if is_same(e[0], ranuras):
			return e
	var orden: Array = []
	for i in ranuras.size():
		orden.append(i)
	orden.sort_custom(func(a: int, b: int) -> bool: return PesosPuesto.es_portero(String(ranuras[a][0])) and not PesosPuesto.es_portero(String(ranuras[b][0])))
	var puestos := PackedStringArray(); var ks: Array = []; var ws: Array = []
	var grupos := PackedStringArray(); var por_r := PackedByteArray()
	for r: Array in ranuras:
		var puesto := String(r[0])
		var e := PesosPuesto.de(puesto)
		puestos.append(puesto)
		ks.append(e[0] if not e.is_empty() else PackedStringArray())
		ws.append(e[1] if not e.is_empty() else PackedFloat64Array())
		grupos.append(PesosPuesto.grupo(puesto))
		por_r.append(1 if PesosPuesto.es_portero(puesto) else 0)
	var entrada := [ranuras, orden, {"puestos": puestos, "ks": ks, "ws": ws, "grupos": grupos, "por": por_r}]
	if _cache.size() >= 32:
		_cache.clear()
	_cache.append(entrada)
	return entrada

## El orden de las ranuras de una formación (porteros primero), ya calculado. Devuelve la lista compartida: no modificarla.
static func orden_de(ranuras: Array) -> Array:
	return _entrada(ranuras)[1]

static func _nativo(nat: Object, libres: Array, ranuras: Array, orden: Array) -> Dictionary:
	if _grupo_de.is_empty():
		for k: String in Datos.posd().keys():
			_grupo_de[k] = PesosPuesto.grupo(k)
	var o := PackedInt32Array()
	for i: int in orden:
		o.append(i)
	var res: PackedInt32Array = nat.once_asignar_libres(_entrada(ranuras)[2], libres, _grupo_de, o)
	var asignado := {}
	for i: int in orden:
		if res[i] >= 0:
			asignado[i] = libres[res[i]]
	return asignado

static func asignar_gd(libres: Array, ranuras: Array, orden: Array) -> Dictionary:
	var asignado := {}
	## Lo que no depende de la ranura, una vez por jugador (30-10, rendimiento): mismas cuentas.
	var n_libres := libres.size()
	var fa := PackedFloat64Array(); var fb := PackedFloat64Array(); var por := PackedByteArray()
	var ge := PackedStringArray()
	for j in libres:
		fa.append(0.7 + 0.003 * j.forma); fb.append(0.9 + 0.002 * j.moral)
		por.append(1 if j.pos_e == "POR" else 0); ge.append(PesosPuesto.grupo(j.pos_e))
	var tomado := PackedByteArray(); tomado.resize(n_libres)
	for i: int in orden:
		var puesto: String = ranuras[i][0]
		var puesto_por := 1 if PesosPuesto.es_portero(puesto) else 0
		var grupo_puesto := PesosPuesto.grupo(puesto)
		var mejor: Jugador = null
		var mejor_v := -1.0
		var mejor_k := -1
		for k in n_libres:
			if tomado[k] == 1 or por[k] != puesto_por:
				continue
			var j: Jugador = libres[k]
			## LA FAMILIARIDAD CON EL PUESTO. Antes solo se miraban los atributos, y por eso el once automático ponía a un extremo veloz de lateral por delante de un lateral
			## de verdad: el extremo tiene el ritmo que pide la posición. Pero saber jugar ahí es otra cosa. No es un veto: un extremo MUY superior sigue ganando el puesto.
			var encaja := 1.0
			if j.pos_e != puesto:
				encaja = 0.94 if j.pos_sec.has(puesto) else 0.86
				## Cambiar de LÍNEA (un delantero de lateral, un central de extremo) cuesta más que moverse dentro de ella (17-10).
				if not j.pos_sec.has(puesto) and grupo_puesto != ge[k]:
					encaja = 0.62
			## Fuera de su puesto no rinde más que en el suyo (los atributos de un delantero rápido daban 76 de lateral con 74 de media).
			var en_puesto := j.media_en(puesto) if j.pos_e == puesto else mini(j.media_en(puesto), j.ovr)
			var v := float(en_puesto) * encaja * fa[k] * fb[k]
			if v > mejor_v:
				mejor_v = v
				mejor = j
				mejor_k = k
		if mejor != null:
			tomado[mejor_k] = 1
			asignado[i] = mejor
	return asignado
