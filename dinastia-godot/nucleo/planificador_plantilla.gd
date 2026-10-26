class_name PlanificadorPlantilla
extends RefCounted
## EL PLANIFICADOR DE PLANTILLA (26-10-2026, fila 21 de la propuesta de la s4:
## «FM Squad Planner y el centro de fichajes de FM26; hoy no existe»). Solo lee:
## mira la plantilla por líneas (POR/DEF/MED/DEL) y avisa de lo que se va a
## romper antes de que se rompa:
##  · CARENCIA: hoy tienes menos jugadores de una línea de los imprescindibles: los
##    titulares de la línea más uno, y al menos el 75 % de lo que trae una plantilla
##    normal (`PLAN_PLANTEL`, la tabla con la que se puebla el mundo; las reales
##    varían ±1 por línea con el mercado, por eso no se exige la cifra exacta);
##  · VERANO: al cerrar la temporada te quedarás corto, contando los contratos que
##    vencen (`anios_contrato <= 1`) y los veteranos que probablemente se retiran
##    (las mismas edades que `Mundo.nueva_temporada()`: 38 seguro, 35+ a veces);
##  · TITULAR QUE SE VA: vence el contrato de alguien del once;
##  · SIN RELEVO: el titular de una línea tiene 32+ y no hay nadie joven detrás.
## Devuelve datos, no frases: la interfaz las monta y las traduce.
##   PlanificadorPlantilla.analizar(club) -> {"lineas": {...}, "avisos": [...]}

const LINEAS := ["POR", "DEF", "MED", "DEL"]
## Edades de retiro de `Mundo.nueva_temporada()`: a los 38 siempre; desde los 35,
## el 40 % de los años. Aquí cuentan como «probable» desde los 35.
const EDAD_RETIRO_PROBABLE := 35
const EDAD_SIN_RELEVO := 32
const EDAD_RELEVO := 23
## Titulares por línea en un 4-3-3.
const TITULARES := {"POR": 1, "DEF": 4, "MED": 3, "DEL": 3}

## Cuántos de cada línea trae una plantilla normal (suma de `PLAN_PLANTEL` por grupo).
static func minimos() -> Dictionary:
	var m := {"POR": 0, "DEF": 0, "MED": 0, "DEL": 0}
	var plan: Variant = Datos.tabla("PLAN_PLANTEL")
	if plan is Array:
		for e: Array in plan:
			var g := Datos.grupo(String(e[0]))
			if m.has(g):
				m[g] = int(m[g]) + int(e[1])
	return m

## Los imprescindibles de una línea (ver la cabecera).
static func umbral(g: String, minimo: int) -> int:
	return maxi(int(TITULARES.get(g, 1)) + 1, int(floor(float(minimo) * 0.75)))

static func se_va_en_verano(j: Jugador) -> bool:
	return j.anios_contrato <= 1 or j.edad >= EDAD_RETIRO_PROBABLE

static func analizar(c: Club) -> Dictionary:
	var minimo := minimos()
	var once_ids := {}
	if c != null:
		for j: Jugador in c.once():
			once_ids[j.id] = true
	var lineas := {}
	for g: String in LINEAS:
		lineas[g] = {"total": 0, "sanos": 0, "media": 0, "vencen": [], "retiro": [], "quedan": 0, "minimo": int(minimo[g]),
			"umbral": umbral(g, int(minimo[g])), "jovenes": 0}
	if c == null:
		return {"lineas": lineas, "avisos": []}
	var sumas := {}
	for j: Jugador in c.plantilla:
		if not lineas.has(j.pos):
			continue
		var l: Dictionary = lineas[j.pos]
		l["total"] = int(l["total"]) + 1
		sumas[j.pos] = int(sumas.get(j.pos, 0)) + j.ovr
		if j.lesion <= 0 and j.suspension <= 0:
			l["sanos"] = int(l["sanos"]) + 1
		if j.anios_contrato <= 1:
			(l["vencen"] as Array).append(j)
		elif j.edad >= EDAD_RETIRO_PROBABLE:
			(l["retiro"] as Array).append(j)
		if j.edad <= EDAD_RELEVO:
			l["jovenes"] = int(l["jovenes"]) + 1
	var avisos: Array[Dictionary] = []
	for g: String in LINEAS:
		var l: Dictionary = lineas[g]
		var total := int(l["total"])
		l["media"] = int(round(float(sumas.get(g, 0)) / float(total))) if total > 0 else 0
		l["quedan"] = total - (l["vencen"] as Array).size() - (l["retiro"] as Array).size()
		if total < int(l["umbral"]):
			avisos.append({"tipo": "carencia", "grupo": g, "n": int(l["umbral"]) - total, "nivel": 2})
		elif int(l["quedan"]) < int(l["umbral"]):
			avisos.append({"tipo": "verano", "grupo": g, "n": int(l["umbral"]) - int(l["quedan"]),
				"vencen": (l["vencen"] as Array).size(), "retiro": (l["retiro"] as Array).size(), "nivel": 1})
		## El titular de la línea (el mejor del once en ella) es mayor y no hay relevo joven.
		var titular: Jugador = null
		for j: Jugador in c.plantilla:
			if j.pos == g and once_ids.has(j.id) and (titular == null or j.ovr > titular.ovr):
				titular = j
		if titular != null and titular.edad >= EDAD_SIN_RELEVO and int(l["jovenes"]) == 0:
			avisos.append({"tipo": "sin_relevo", "grupo": g, "jugador": titular, "nivel": 1})
	for j: Jugador in c.plantilla:
		if once_ids.has(j.id) and j.anios_contrato <= 1:
			avisos.append({"tipo": "titular_se_va", "grupo": j.pos, "jugador": j, "nivel": 2})
	avisos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["nivel"]) > int(b["nivel"]))
	return {"lineas": lineas, "avisos": avisos}
