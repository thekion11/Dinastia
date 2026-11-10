class_name ObjetivosCierre
extends RefCounted
## EL CIERRE DE LOS OBJETIVOS POR CLUB (10-11, encargo «4 OBJETIVOS POR CLUB»): juzga los objetivos SECUNDARIOS y el PROYECTO a 3 temporadas que generó
## `ObjetivosClub` y mueve la confianza de la directiva con el peso de cada uno (cumplir suma, fallar resta). El de liga lo sigue juzgando
## `Directiva.tras_temporada`. Solo lee el mundo; no toca el motor del partido.

## Juzga un secundario. Devuelve {cumplido, aplica}. `aplica` = falso si no hubo ocasión de cumplirlo (p. ej. no jugó la copa continental).
static func juzgar(m: Mundo, c: Club, liga: Liga, o: Dictionary, bases: Dictionary) -> Dictionary:
	var meta := int(o.get("meta", 0))
	match String(o.get("tipo", "")):
		"copa":
			var copa: Copa = m.copa
			if copa == null or not copa.participantes.has(c):
				return {"cumplido": false, "aplica": false}
			if copa.campeon == c:
				return {"cumplido": true, "aplica": true}
			var need := ObjetivosClub.rondas_para(copa, meta)
			if meta >= 16:
				need = maxi(1, need)
			return {"cumplido": ObjetivosClub.rondas_ganadas(copa, c) >= need, "aplica": true}
		"continental":
			for k: Variant in m.continentales:
				var cont: Continental = m.continentales[k]
				if cont == null or not cont.participa(c):
					continue
				var g := ObjetivosClub.rondas_ganadas(cont, c)
				var pasa := cont.campeon == c or cont.clasificados().has(c) or g > 0
				if meta <= 4:   ## semifinales: ganar los cuartos (con grupos) o dos eliminatorias (a cuadro directo)
					return {"cumplido": cont.campeon == c or g >= (1 if cont.por_grupos else 2), "aplica": true}
				return {"cumplido": pasa, "aplica": true}
			return {"cumplido": false, "aplica": false}
		"economia":
			var base := int(bases.get("saldo", 0))
			var ok := false
			if meta == 0:
				ok = c.saldo >= 0
			elif meta > 0:
				ok = c.saldo >= base + maxi(int(absf(float(base)) * 0.1), Eco.escalar(300000.0, float(c.rep)))
			else:
				ok = float(c.saldo) >= float(base) * 0.9
			return {"cumplido": ok, "aplica": true}
		"cantera":
			var jovenes := 0
			for j: Jugador in c.plantilla:
				if j.edad <= 21:
					jovenes += 1
			return {"cumplido": jovenes >= meta, "aplica": true}
		"social":
			var b := int(bases.get("socios", 0))
			return {"cumplido": b > 0 and float(c.socios) >= float(b) * 1.05, "aplica": b > 0}
		"estilo":
			return {"cumplido": _estilo(liga, c, meta), "aplica": liga != null and liga.jornada_actual > 0}
	return {"cumplido": false, "aplica": false}

static func _estilo(liga: Liga, c: Club, meta: int) -> bool:
	if liga == null:
		return false
	var filas: Array = liga.tabla()
	var mias := {}
	var gc_tot := 0.0
	var pj_tot := 0.0
	for f: Dictionary in filas:
		gc_tot += float(f["gc"])
		pj_tot += float(f["pj"])
		if f["club"] == c:
			mias = f
	if mias.is_empty() or pj_tot <= 0.0:
		return false
	if meta > 0:   ## ser de los N más goleadores
		var mejores := 0
		for f2: Dictionary in filas:
			if int(f2["gf"]) > int(mias["gf"]):
				mejores += 1
		return mejores < meta
	return float(mias["gc"]) / maxf(float(mias["pj"]), 1.0) < gc_tot / pj_tot

## Juzga el proyecto con lo que pasó esta temporada y devuelve {texto, cumplido, delta} si terminó (o {} si sigue en marcha).
static func avanzar_proyecto(m: Mundo, d: Directiva, c: Club, puesto: int, campeon_liga: bool) -> Dictionary:
	var p: Dictionary = d.proyecto
	if p.is_empty():
		return {}
	var liga: Liga = m.liga_de(c)
	var n := liga.clubes.size() if liga != null else 16
	p["cierres"] = int(p.get("cierres", 0)) + 1
	var mejor := int(p.get("mejor_puesto", 0))
	p["mejor_puesto"] = puesto if mejor <= 0 else mini(mejor, puesto)
	if campeon_liga:
		p["titulos"] = int(p.get("titulos", 0)) + 1
	if liga != null and c.division == 1 and puesto > n - liga.plazas_descenso:
		p["sin_descender"] = false
	if puesto <= int(p.get("meta", 0)) and String(p.get("id", "")) == "volver":
		p["con_conti"] = true
	if int(p["cierres"]) < int(p.get("temporadas", ObjetivosClub.TEMPORADAS_PROYECTO)):
		return {}
	var ok := false
	match String(p.get("id", "")):
		"sanear": ok = c.saldo >= 0
		"ascender": ok = c.division == 1
		"titulo": ok = int(p.get("titulos", 0)) >= 1
		"volver": ok = bool(p.get("con_conti", false))
		"consolidar": ok = bool(p.get("sin_descender", true)) and c.division == 1
		_: ok = int(p.get("puesto_base", puesto)) - int(p["mejor_puesto"]) >= int(p.get("meta", 3))
	var delta := ObjetivosClub.PESO_PROYECTO_OK if ok else -ObjetivosClub.PESO_PROYECTO_MAL
	return {"texto": String(p.get("texto", "")), "cumplido": ok, "delta": delta, "terminado": true}

## EL CIERRE: juzga todo, mueve la confianza una sola vez y deja listo el paquete de la temporada siguiente. Devuelve el resumen para `ResumenTemporada`.
static func cerrar(m: Mundo, d: Directiva, puesto: int, campeon_liga: bool) -> Dictionary:
	var c: Club = d.club
	var liga: Liga = m.liga_de(c) if m != null and c != null else null
	var salida := {"secundarios": [], "proyecto": {}, "delta": 0}
	if m == null or c == null or d.objetivos.is_empty() and d.proyecto.is_empty():
		return salida
	var delta := 0
	for o: Dictionary in d.objetivos:
		var r := juzgar(m, c, liga, o, d.bases)
		var peso := int(o.get("peso", 0))
		var item := {"texto": String(o.get("texto", "")), "meta": int(o.get("meta", 0)), "peso": peso,
			"cumplido": bool(r["cumplido"]), "aplica": bool(r["aplica"])}
		if bool(r["aplica"]):
			delta += peso if bool(r["cumplido"]) else -peso
		(salida["secundarios"] as Array).append(item)
	var pr := avanzar_proyecto(m, d, c, puesto, campeon_liga)
	if not pr.is_empty():
		delta += int(pr["delta"])
		salida["proyecto"] = pr
	if delta != 0:
		d.mover_confianza(delta, "objetivos secundarios y proyecto")
	salida["delta"] = delta
	return salida
