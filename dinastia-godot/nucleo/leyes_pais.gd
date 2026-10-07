class_name LeyesPais
extends RefCounted
## LAS REGLAS DE CADA PAÍS (7-10-2026, pedido: «las leyes deben ser por cada
## país en base al equipo según su país»). Cada club juega con las reglas de su
## liga, no con una regla única para todo el mundo:
##   · cupo de jugadores que cuentan como «de fuera» en el PLANTEL y en CANCHA;
##   · QUÉ cuenta como «de fuera» en esa liga: extranjero (la mayoría), no
##     comunitario (España, Francia, Italia) o no formado en el país (México,
##     Inglaterra con su regla de formados en casa);
##   · mínimo de nacionales en el plantel (Alemania);
##   · fichajes de no comunitarios por temporada (Italia);
##   · juveniles obligatorios en el once (Chile, Bolivia).
## La jornada laboral sigue en `Contratos` (también por país del club).
##
## Datos verificados el 7-10-2026 en la prensa de cada liga y en las normas
## publicadas (ver la nota de cada fila). `seguro = false` marca los que no se
## pudieron confirmar para 2026 y conviene revisar antes de publicar.
## La votación de la federación (`Federacion.tope_extranjeros`) sigue
## existiendo: si la asamblea vota un tope más estricto, manda el más estricto.

## pais -> {plantel, cancha, criterio, min_nac, no_ue_temp, juveniles, norma, seguro}
##   plantel/cancha: 0 = sin tope.  criterio: "extranjero" | "no_ue" | "no_formado".
##   juveniles: edades que deben estar en el once (una plaza por edad).
const REGLAS := {
	"ARG": {"plantel": 6, "cancha": 5, "criterio": "extranjero", "norma": "Reglamento LPF 2026: 6 extranjeros inscritos, 5 en cancha.", "seguro": true},
	"BRA": {"plantel": 0, "cancha": 9, "criterio": "extranjero", "norma": "Brasileirão: hasta 9 extranjeros por partido (baja a 5 en 2027).", "seguro": true},
	"CHI": {"plantel": 6, "cancha": 5, "criterio": "extranjero", "juveniles": [21], "norma": "ANFP 2026: 6 extranjeros, 5 en cancha, y minutos sub-21 obligatorios (1.890 por temporada).", "seguro": true},
	"URU": {"plantel": 6, "cancha": 5, "criterio": "extranjero", "norma": "Estatuto del Jugador AUF: 6 fichados, 5 en cancha.", "seguro": true},
	"PAR": {"plantel": 5, "cancha": 5, "criterio": "extranjero", "norma": "APF: cupo de extranjeros (cifra 2026 por confirmar).", "seguro": false},
	"PER": {"plantel": 7, "cancha": 7, "criterio": "extranjero", "norma": "Liga 1 2026: sube de 6 a 7 extranjeros, todos pueden jugar a la vez.", "seguro": true},
	"ECU": {"plantel": 8, "cancha": 0, "criterio": "extranjero", "norma": "LigaPro: 8 extranjeros por equipo desde 2023.", "seguro": true},
	"COL": {"plantel": 4, "cancha": 4, "criterio": "extranjero", "norma": "Dimayor 2026: 4 extranjeros inscritos y los 4 en cancha.", "seguro": true},
	"VEN": {"plantel": 6, "cancha": 6, "criterio": "extranjero", "norma": "Liga FUTVE: cupo de extranjeros (cifra 2026 por confirmar).", "seguro": false},
	"BOL": {"plantel": 6, "cancha": 4, "criterio": "extranjero", "juveniles": [20, 23], "norma": "FBF: 6 extranjeros, 4 en cancha; un sub-20 y un sub-23 obligatorios los 90'.", "seguro": true},
	"MEX": {"plantel": 9, "cancha": 7, "criterio": "no_formado", "norma": "Liga MX: 9 no formados en México, 7 en cancha.", "seguro": true},
	"USA": {"plantel": 8, "cancha": 0, "criterio": "extranjero", "norma": "MLS: unas 8 plazas internacionales por equipo (241 entre 30 clubes).", "seguro": true},
	"ESP": {"plantel": 3, "cancha": 0, "criterio": "no_ue", "norma": "RFEF/LaLiga: 3 extracomunitarios por plantel.", "seguro": true},
	"ENG": {"plantel": 17, "cancha": 0, "criterio": "no_formado", "norma": "Premier League: 25 por plantel con al menos 8 formados en casa (17 no formados).", "seguro": true},
	"ITA": {"plantel": 0, "cancha": 0, "criterio": "no_ue", "no_ue_temp": 2, "norma": "Serie A: tope de fichajes extracomunitarios del extranjero por temporada (2).", "seguro": true},
	"GER": {"plantel": 0, "cancha": 0, "criterio": "extranjero", "min_nac": 12, "norma": "Bundesliga: sin tope de extranjeros, pero 12 alemanes entre los jugadores con licencia.", "seguro": true},
	"FRA": {"plantel": 4, "cancha": 0, "criterio": "no_ue", "norma": "Ligue 1: 4 extracomunitarios.", "seguro": true},
	"JPN": {"plantel": 0, "cancha": 5, "criterio": "extranjero", "norma": "J1: extranjeros sin tope, 5 por convocatoria.", "seguro": true},
	"KOR": {"plantel": 0, "cancha": 5, "criterio": "extranjero", "norma": "K League 1 2026: se abre el registro, 5 extranjeros por convocatoria.", "seguro": true},
	"KSA": {"plantel": 10, "cancha": 8, "criterio": "extranjero", "norma": "Saudi Pro League: 10 extranjeros inscritos, 8 por convocatoria.", "seguro": true},
	"EGY": {"plantel": 5, "cancha": 5, "criterio": "extranjero", "norma": "Liga egipcia: 5 extranjeros mayores (más 3 menores), 5 en cancha.", "seguro": true},
	"MAR": {"plantel": 5, "cancha": 3, "criterio": "extranjero", "norma": "Botola Pro: 5 extranjeros inscritos, 3 en cancha.", "seguro": true},
	"RSA": {"plantel": 5, "cancha": 5, "criterio": "extranjero", "norma": "PSL: 5 extranjeros por plantel.", "seguro": true},
	"AUS": {"plantel": 5, "cancha": 0, "criterio": "extranjero", "norma": "A-League: 5 jugadores visados.", "seguro": true},
}

## Países de la Unión Europea (para los cupos «extracomunitarios»).
const UE := ["ESP", "FRA", "ITA", "GER", "POR", "NED", "BEL", "AUT", "IRL", "GRE", "SWE", "DEN", "FIN",
	"POL", "CZE", "HUN", "ROU", "BUL", "CRO", "SVK", "SVN", "EST", "LVA", "LTU", "LUX", "MLT", "CYP"]

static func reglas(pais: String) -> Dictionary:
	return REGLAS.get(pais, {})

## ¿Este jugador ocupa cupo en un club de este país?
static func ocupa_cupo(j: Jugador, pais: String, clubes: Dictionary = {}) -> bool:
	if j == null:
		return false
	if clubes.is_empty():
		clubes = clubes_mundo
	var r := reglas(pais)
	match String(r.get("criterio", "extranjero")):
		"no_ue":
			return j.pais != pais and not (j.pais in UE and pais in UE)
		"no_formado":
			if j.pais == pais:
				return false
			## Formado en el país: su club de formación es de esta liga.
			var cf: Variant = clubes.get(j.club_formacion)
			return not (cf is Club and (cf as Club).pais == pais)
		_:
			return j.pais != pais

## OPTIMIZADO: el mercado de la IA pregunta esto por cada candidato de cada
## club; se recuerda por club mientras no cambie la semana ni el plantel.
static var tick := 0

static func cuantos_cupo(c: Club, clubes: Dictionary = {}) -> int:
	var cache: Dictionary = c.cupo_cache
	if int(cache.get("t", -1)) == tick and int(cache.get("n", -1)) == c.plantilla.size():
		return int(cache["v"])
	var n := 0
	for x: Jugador in c.plantilla:
		if ocupa_cupo(x, c.pais, clubes):
			n += 1
	c.cupo_cache = {"t": tick, "n": c.plantilla.size(), "v": n}
	return n

static func nacionales(c: Club) -> int:
	var n := 0
	for x: Jugador in c.plantilla:
		if x.pais == c.pais:
			n += 1
	return n

## ¿Puede este club fichar a este jugador según las reglas de su país?
## "" si puede; si no, el motivo. `tope_votado` es el de la federación (0 = no).
static func motivo_fichaje(c: Club, j: Jugador, clubes: Dictionary = {}, tope_votado: int = 0) -> String:
	if c == null or j == null:
		return ""
	var r := reglas(c.pais)
	if ocupa_cupo(j, c.pais, clubes):
		var tope := int(r.get("plantel", 0))
		if tope_votado > 0:
			tope = tope_votado if tope <= 0 else mini(tope, tope_votado)
		if tope > 0 and cuantos_cupo(c, clubes) >= tope:
			return "Cupo lleno (%d %s): %s" % [tope, _que_cuenta(String(r.get("criterio", "extranjero"))), String(r.get("norma", "regla de la liga"))]
		var temp := int(r.get("no_ue_temp", 0))
		if temp > 0 and int(c.fichajes_cupo.get(str(anio_actual), 0)) >= temp:
			return "Ya fichaste %d extracomunitarios esta temporada: %s" % [temp, String(r.get("norma", ""))]
	var min_nac := int(r.get("min_nac", 0))
	if min_nac > 0 and j.pais != c.pais and nacionales(c) < min_nac:
		return "La liga exige %d jugadores %s en el plantel: %s" % [min_nac, "nacionales", String(r.get("norma", ""))]
	return ""

static func _que_cuenta(criterio: String) -> String:
	return {"no_ue": "extracomunitarios", "no_formado": "no formados en el país"}.get(criterio, "extranjeros")

## El año en curso (lo fija `Mundo` cada semana) para los topes por temporada.
static var anio_actual := 0
## Los clubes del mundo (para saber dónde se formó cada uno); lo fija `Mundo`.
static var clubes_mundo: Dictionary = {}

## El once con las reglas del país: si hay más «de fuera» que los permitidos en
## cancha, salen los peores de ellos por el mejor disponible que no ocupe cupo
## (de su misma línea si se puede); y si la liga exige juveniles, entran.
static func ajustar_once(c: Club, once: Array[Jugador], clubes: Dictionary = {}) -> Array[Jugador]:
	var r := reglas(c.pais)
	## Salida rápida: ligas sin tope en cancha ni juveniles obligatorios.
	if r.is_empty() or once.is_empty() or (int(r.get("cancha", 0)) <= 0 and (r.get("juveniles", []) as Array).is_empty()):
		return once
	var res: Array[Jugador] = once.duplicate()
	var banca: Array[Jugador] = []
	for j: Jugador in c.disponibles():
		if not res.has(j):
			banca.append(j)
	var tope := int(r.get("cancha", 0))
	if tope > 0:
		var de_fuera: Array[Jugador] = res.filter(func(j: Jugador) -> bool: return ocupa_cupo(j, c.pais, clubes))
		de_fuera.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr < b.ovr)
		var sobran := de_fuera.size() - tope
		## De peor a mejor; si a uno no hay con quién cambiarlo (un portero sin
		## suplente local), sale el siguiente.
		for sale: Jugador in de_fuera:
			if sobran <= 0:
				break
			var entra := _mejor_reemplazo(sale, banca, func(j: Jugador) -> bool: return not ocupa_cupo(j, c.pais, clubes))
			if entra != null:
				res[res.find(sale)] = entra
				banca.erase(entra)
				sobran -= 1
	for edad: int in r.get("juveniles", []):
		var hay := false
		for j: Jugador in res:
			if j.edad <= edad:
				hay = true
		if hay:
			continue
		## Sale el peor de campo que no sea portero ni juvenil.
		var peor: Jugador = null
		for j: Jugador in res:
			if j.es_portero() or j.edad <= edad:
				continue
			if peor == null or j.ovr < peor.ovr:
				peor = j
		if peor == null:
			continue
		var joven := _mejor_reemplazo(peor, banca, func(j: Jugador) -> bool: return j.edad <= edad and not j.es_portero() \
			and (not ocupa_cupo(j, c.pais, clubes) or not ocupa_cupo(peor, c.pais, clubes)))
		if joven != null:
			res[res.find(peor)] = joven
			banca.erase(joven)
	return res

static func _mejor_reemplazo(sale: Jugador, banca: Array[Jugador], vale: Callable) -> Jugador:
	var mejor: Jugador = null
	for j: Jugador in banca:
		if not vale.call(j) or j.es_portero() != sale.es_portero():
			continue
		var misma := j.pos == sale.pos
		if mejor == null or (misma and mejor.pos != sale.pos) or (misma == (mejor.pos == sale.pos) and j.ovr > mejor.ovr):
			mejor = j
	return mejor

## Lo que incumple un once según la liga de su club: [{tipo, texto}].
static func infracciones_once(c: Club, once: Array[Jugador]) -> Array:
	var r := reglas(c.pais)
	var l: Array = []
	if r.is_empty():
		return l
	var tope := int(r.get("cancha", 0))
	if tope > 0:
		var n := 0
		for j: Jugador in once:
			if ocupa_cupo(j, c.pais):
				n += 1
		if n > tope:
			l.append({"tipo": "cancha", "texto": "%d %s en cancha (máximo %d)" % [n, _que_cuenta(String(r.get("criterio", "extranjero"))), tope]})
	for edad: int in r.get("juveniles", []):
		var hay := false
		for j: Jugador in once:
			if j.edad <= edad:
				hay = true
		if not hay:
			l.append({"tipo": "juvenil", "texto": "sin ningún sub-%d en el once" % edad})
	return l

## Cuántos «de fuera» sobran en el plantel (0 si cumple).
static func exceso_plantel(c: Club, tope_votado: int = 0) -> int:
	var r := reglas(c.pais)
	var tope := int(r.get("plantel", 0))
	if tope_votado > 0:
		tope = tope_votado if tope <= 0 else mini(tope, tope_votado)
	if tope <= 0:
		return 0
	return maxi(0, cuantos_cupo(c) - tope)

## Las reglas del país en frases, para la pantalla de Federación y la ficha.
static func resumen(pais: String) -> Array:
	var r := reglas(pais)
	if r.is_empty():
		return []
	var l: Array = []
	var que := _que_cuenta(String(r.get("criterio", "extranjero")))
	if int(r.get("plantel", 0)) > 0:
		l.append("Máximo %d %s en el plantel" % [int(r["plantel"]), que])
	if int(r.get("cancha", 0)) > 0:
		l.append("Máximo %d %s en cancha" % [int(r["cancha"]), que])
	if int(r.get("no_ue_temp", 0)) > 0:
		l.append("Máximo %d fichajes extracomunitarios por temporada" % int(r["no_ue_temp"]))
	if int(r.get("min_nac", 0)) > 0:
		l.append("Al menos %d nacionales en el plantel" % int(r["min_nac"]))
	for e: int in r.get("juveniles", []):
		l.append("Un sub-%d obligatorio en el once" % e)
	l.append("📜 " + String(r.get("norma", "")) + ("" if bool(r.get("seguro", true)) else " (por verificar)"))
	return l
