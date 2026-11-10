class_name FaseFinalLiga
extends RefCounted
## LAS LIGAS CON FASE FINAL (10-11-2026, sesión 6): Egipto, Argentina y la MLS no se juegan «todos contra todos».
##   · EGY («grupos»): 21 clubes a UNA vuelta (20 fechas); los 7 mejores forman el grupo del campeonato (ida y vuelta) y los 14 restantes el del
##     descenso (una vuelta, bajan 4). Los puntos se arrastran. El campeón sale del primer grupo y los que bajan, del segundo.
##   · ARG («zonas»): dos zonas de 15 (14 partidos de zona + 1 interzonal) y los 8 mejores de cada una juegan octavos, cuartos, semifinales
##     (final de zona) y la final en cancha neutral, todo a partido único (penales si empatan). Baja quien termina último de la tabla.
##   · USA («conferencias»): Este y Oeste de 15 a ida y vuelta (30 fechas; el interconferencia real se omite para no pasar de 38 semanas), los 7
##     mejores de cada una entran directos, 8.º y 9.º juegan el Wild Card; la Ronda 1 es al mejor de 3, luego semifinal y final de conferencia
##     y la MLS Cup, a partido único.
## La liga sigue siendo una `Liga`: `tabla()` devuelve el ORDEN FINAL (campeón primero), así que quien lee el campeón o el descenso no cambia.
## El calendario de la fase final nace con huecos vacíos (para que `jornadas()` ya cuente todo) y se rellena al terminar cada fecha. Lo que no se
## puede deducir del orden de los clubes (grupos, cruces, resultados) va en `estado`, que la partida guarda y devuelve con `cargar`.

const PAISES := {"EGY": ["grupos", 12], "ARG": ["zonas", 20], "USA": ["conferencias", 20]}
## Huecos de la fase final de las eliminatorias: [ronda, juego] por fecha.
const SLOTS_ZONAS := [[0, 0], [1, 0], [2, 0], [3, 0]]
const SLOTS_CONF := [[0, 0], [1, 0], [1, 1], [1, 2], [2, 0], [3, 0], [4, 0]]

var tipo := ""
var f1 := 0                 ## fechas de la fase regular
var extra := 0              ## fechas de la fase final
var estado: Dictionary = {}


## El formato de esta liga, o null si se juega de la forma de siempre.
static func para(l: Liga) -> FaseFinalLiga:
	if l.div != 1 or not PAISES.has(l.pais) or l.clubes.size() < int(PAISES[l.pais][1]):
		return null
	var f := FaseFinalLiga.new()
	f.tipo = String(PAISES[l.pais][0])
	return f

func eliminatoria(j: int) -> bool:
	return tipo != "grupos" and j >= f1

func _slots() -> Array:
	return SLOTS_ZONAS if tipo == "zonas" else SLOTS_CONF


## --- FASE REGULAR ---------------------------------------------------------

func _mitades(l: Liga) -> Array:
	var ids: Array = []
	for c: Club in l.clubes:
		ids.append(c.id)
	ids.sort()
	var a: Array[Club] = []
	var b: Array[Club] = []
	for i in ids.size():
		(a if i % 2 == 0 else b).append(_club(l, String(ids[i])))
	return [a, b]

static func _club(l: Liga, id: String) -> Club:
	for c: Club in l.clubes:
		if c.id == id:
			return c
	return null

static func _unir(x: Array, y: Array) -> Array:
	var sal: Array = []
	for i in maxi(x.size(), y.size()):
		sal.append((x[i] if i < x.size() else []) + (y[i] if i < y.size() else []))
	return sal

static func _vuelta(r: Array) -> Array:
	var sal: Array = []
	for j: Array in r:
		var v: Array = []
		for par: Array in j:
			v.append([par[1], par[0]])
		sal.append(v)
	return sal

## El calendario de la fase regular + los huecos de la final.
func armar(l: Liga) -> Array:
	var cal: Array = []
	if tipo == "grupos":
		cal = Liga.rondas(l.clubes)
		var na := _tam_grupo(l.clubes.size())
		extra = maxi(2 * _rr(na), _rr(l.clubes.size() - na))
	else:
		var m := _mitades(l)
		var ra := Liga.rondas(m[0])
		var rb := Liga.rondas(m[1])
		cal = _unir(ra, rb)
		if tipo == "zonas":
			var inter: Array = []
			for i in mini((m[0] as Array).size(), (m[1] as Array).size()):
				inter.append([m[0][i], m[1][i]] if i % 2 == 0 else [m[1][i], m[0][i]])
			cal.append(inter)
			extra = SLOTS_ZONAS.size()
		else:
			cal += _unir(_vuelta(ra), _vuelta(rb))
			extra = SLOTS_CONF.size()
	f1 = cal.size()
	for i in extra:
		cal.append([])
	return cal

static func _tam_grupo(n: int) -> int:
	return maxi(2, roundi(n / 3.0))

static func _rr(n: int) -> int:
	return n if n % 2 == 1 else n - 1


## --- FASE FINAL -----------------------------------------------------------

## Se llama al terminar la fecha `j` (ya anotada en la tabla). Prepara la siguiente y, al final, deja el orden.
func tras_jornada(l: Liga, j: int, resultados: Array) -> void:
	if j == f1 - 1:
		_iniciar(l)
	elif eliminatoria(j):
		_registrar(resultados)
		_avanzar_ronda()
	if j + 1 < l.calendario.size() and eliminatoria(j + 1):
		l.calendario[j + 1] = _pares(l, j + 1)
	if j == l.calendario.size() - 1:
		_cerrar(l)

func _ids(l: Liga) -> Array:
	var ids: Array = []
	for fila: Dictionary in l.tabla():
		ids.append((fila["club"] as Club).id)
	return ids

func _iniciar(l: Liga) -> void:
	var reg := _ids(l)
	estado["reg"] = reg
	if tipo == "grupos":
		var na := _tam_grupo(reg.size())
		estado["grupos"] = [reg.slice(0, na), reg.slice(na)]
		_llenar_grupos(l)
		return
	estado["rondas"] = []
	var cruces: Array = []
	var confs: Array = []
	for z: Array in _mitades(l):
		var orden: Array = []
		for id: String in reg:
			if z.has(_club(l, id)):
				orden.append(id)
		confs.append(orden)
		if tipo == "zonas":
			cruces += _bracket(orden.slice(0, 8), 8)
		else:
			cruces += [_cruce(orden[7], orden[8])]
	(estado["rondas"] as Array).append({"n": "Octavos de final" if tipo == "zonas" else "Wild Card", "c": cruces, "j": 1, "neutral": false})
	estado["confs"] = confs

func _llenar_grupos(l: Liga) -> void:
	var g: Array = estado["grupos"]
	var a: Array[Club] = []
	var b: Array[Club] = []
	for id: String in g[0]:
		a.append(_club(l, id))
	for id: String in g[1]:
		b.append(_club(l, id))
	var ra := Liga.rondas(a)
	ra += _vuelta(ra)
	var fusion := _unir(ra, Liga.rondas(b))
	for i in extra:
		l.calendario[f1 + i] = fusion[i] if i < fusion.size() else []

static func _cruce(a: String, b: String) -> Dictionary:
	return {"a": a, "b": b, "r": [], "g": ""}

## Cruces 1-8, 4-5, 2-7, 3-6 (así los ganadores contiguos se cruzan después).
static func _bracket(top: Array, n: int) -> Array:
	var sal: Array = []
	for par: Array in [[0, n - 1], [3, n - 4], [1, n - 2], [2, n - 3]]:
		sal.append(_cruce(String(top[par[0]]), String(top[par[1]])))
	return sal

func _ronda_de(j: int) -> Array:
	return _slots()[j - f1]

## Los partidos de la fecha `j` de la fase final (local primero).
func _pares(l: Liga, j: int) -> Array:
	var slot: Array = _ronda_de(j)
	var rondas: Array = estado.get("rondas", [])
	if int(slot[0]) >= rondas.size():
		return []
	var r: Dictionary = rondas[int(slot[0])]
	var sal: Array = []
	for c: Dictionary in r["c"]:
		if String(c["g"]) != "" or (c["r"] as Array).size() != int(slot[1]):
			continue
		var a := _club(l, String(c["a"]))
		var b := _club(l, String(c["b"]))
		## Al mejor de 3: el mejor sembrado recibe el 1.º y el 3.º.
		sal.append([b, a] if int(slot[1]) == 1 else [a, b])
	return sal

func _registrar(resultados: Array) -> void:
	var rondas: Array = estado["rondas"]
	for res: Dictionary in resultados:
		var l_id := (res["local"] as Club).id
		var v_id := (res["visita"] as Club).id
		for r: Dictionary in rondas:
			for c: Dictionary in r["c"]:
				if String(c["g"]) != "" or not ([c["a"], c["b"]].has(l_id) and [c["a"], c["b"]].has(v_id)):
					continue
				var ga := int(res["gl"]) if c["a"] == l_id else int(res["gv"])
				var gb := int(res["gv"]) if c["a"] == l_id else int(res["gl"])
				if ga == gb:   ## tanda de penales: 50-50
					if Azar.suerte(0.5):
						ga += 1
					else:
						gb += 1
				(c["r"] as Array).append([ga, gb])
				var ja := 0
				var jb := 0
				for x: Array in c["r"]:
					if int(x[0]) > int(x[1]):
						ja += 1
					else:
						jb += 1
				var falta := (int(r["j"]) + 1) / 2
				if ja >= falta:
					c["g"] = c["a"]
				elif jb >= falta:
					c["g"] = c["b"]

## Si la ronda en curso terminó, crea la siguiente con los ganadores contiguos.
func _avanzar_ronda() -> void:
	var rondas: Array = estado["rondas"]
	var r: Dictionary = rondas[rondas.size() - 1]
	for c: Dictionary in r["c"]:
		if String(c["g"]) == "":
			return
	var gan: Array = []
	for c: Dictionary in r["c"]:
		gan.append(String(c["g"]))
	if tipo == "zonas":
		if gan.size() == 1:
			return
		var nombres := {4: "Cuartos de final", 2: "Semifinales (final de zona)", 1: "Final"}
		var cr: Array = []
		for i in gan.size() / 2:
			cr.append(_cruce(String(gan[2 * i]), String(gan[2 * i + 1])))
		rondas.append({"n": nombres[cr.size()], "c": cr, "j": 1, "neutral": cr.size() == 1})
		return
	if rondas.size() == 1:   ## tras el Wild Card: 7 directos + 1 ganador por conferencia, al mejor de 3
		var cr2: Array = []
		for z in gan.size():
			var top: Array = (estado["confs"][z] as Array).slice(0, 7) + [gan[z]]
			cr2 += _bracket(top, 8)
		rondas.append({"n": "Ronda 1 (al mejor de 3)", "c": cr2, "j": 3, "neutral": false})
		return
	if gan.size() == 1:
		return
	var nom := {4: "Semifinales de Conferencia", 2: "Final de Conferencia", 1: "MLS Cup"}
	var cr3: Array = []
	for i in gan.size() / 2:
		cr3.append(_cruce(String(gan[2 * i]), String(gan[2 * i + 1])))
	rondas.append({"n": nom[cr3.size()], "c": cr3, "j": 1, "neutral": cr3.size() == 1})

func _cerrar(l: Liga) -> void:
	var orden: Array = []
	if tipo == "grupos":
		var g: Array = estado["grupos"]
		for grupo: Array in g:
			for fila: Dictionary in l.tabla():
				if grupo.has((fila["club"] as Club).id):
					orden.append((fila["club"] as Club).id)
	else:
		var reg: Array = estado["reg"]
		var rondas: Array = estado["rondas"]
		var ult: Dictionary = rondas[rondas.size() - 1]
		orden.append(String(ult["c"][0]["g"]))
		for k in range(rondas.size() - 1, -1, -1):
			var perd: Array = []
			for c: Dictionary in (rondas[k] as Dictionary)["c"]:
				var p := String(c["b"]) if c["g"] == c["a"] else String(c["a"])
				if not orden.has(p):
					perd.append(p)
			perd.sort_custom(func(x: String, y: String) -> bool: return reg.find(x) < reg.find(y))
			orden += perd
		for id: String in reg:
			if not orden.has(id):
				orden.append(id)
	estado["orden"] = orden
	l.orden_final = orden

## Al abrir una partida: devuelve el estado guardado y rellena la fecha en curso.
func cargar(l: Liga, d: Dictionary) -> void:
	estado = d.duplicate(true)
	var j := l.jornada_actual
	if tipo == "grupos" and estado.has("grupos"):
		_llenar_grupos(l)
	elif eliminatoria(j) and j < l.calendario.size():
		l.calendario[j] = _pares(l, j)
	if estado.has("orden"):
		l.orden_final = Array(estado["orden"])


## Lo que la pantalla de competición enseña de la fase final: [{titulo, clubes}] en los grupos de Egipto, [{titulo, cruces}] en los cuadros
## (cada cruce: {a, b, r: [[ga, gb]…], g: ganador o null}). Vacío mientras la fase regular no ha terminado.
func secciones(l: Liga) -> Array:
	var sal: Array = []
	if tipo == "grupos":
		if not estado.has("grupos"):
			return sal
		var nombres := ["Grupo del campeonato", "Grupo del descenso"]
		for i in 2:
			var filas: Array = []
			for fila: Dictionary in l.tabla():
				if (estado["grupos"][i] as Array).has((fila["club"] as Club).id):
					filas.append(fila)
			sal.append({"titulo": nombres[i], "filas": filas})
		return sal
	for r: Dictionary in estado.get("rondas", []):
		var cruces: Array = []
		for c: Dictionary in r["c"]:
			cruces.append({"a": _club(l, String(c["a"])), "b": _club(l, String(c["b"])), "r": c["r"],
				"g": _club(l, String(c["g"])) if String(c["g"]) != "" else null})
		sal.append({"titulo": String(r["n"]), "cruces": cruces})
	return sal
