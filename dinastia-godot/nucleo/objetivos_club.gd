class_name ObjetivosClub
extends RefCounted
## LOS OBJETIVOS POR CLUB (10-11, encargo del dueño «4 OBJETIVOS POR CLUB»). Antes la directiva daba cinco metas fijas según el puesto de reputación (el «top 4»
## y el «14» valían igual con 12 que con 24 equipos). Ahora cada club recibe un PAQUETE que sale de lo que ES:
##   · PRINCIPAL (liga): se ajusta al tamaño de su liga, a sus descensos y a sus plazas continentales reales (`Continental.CUPOS_*`); la exigencia sube con el
##     palmarés (`HistoriaClub`) y la masa social, y baja con las deudas.
##   · SECUNDARIOS (varios a la vez, cada uno con su peso en la confianza): copa, copa continental (si es de los de arriba), economía, y dos de cantera /
##     masa social / estilo de juego.
##   · PROYECTO a 3 temporadas (sanear las cuentas, volver a Europa/Libertadores, consolidarse, ganar la liga, mejorar el puesto).
## Todo es DETERMINISTA por club (sin `Azar`) y solo lee: no toca el motor del partido. `Directiva.generar_objetivos` lo guarda y `cerrar_temporada` lo juzga.
## Cada objetivo: {id, tipo, texto, meta, peso} (+ {estado, cumplido, aplica} al juzgarlo). Textos con `Idiomas.t` en la pantalla.

const PESO_PROYECTO_OK := 20
const PESO_PROYECTO_MAL := 12
const TEMPORADAS_PROYECTO := 3

## ¿Qué copa grande le toca a ese país? "ucl" (Champions), "lib" (Libertadores) o "" (genérica).
static func copa_grande(pais: String) -> String:
	for f: Array in Continental.CUPOS_UCL:
		if String(f[0]) == pais:
			return "ucl"
	if pais == Continental.PAIS_ANFITRION:
		return "lib"
	for f2: Array in Continental.CUPOS_SUDAMERICA:
		if String(f2[0]) == pais:
			return "lib"
	return ""

## Plazas continentales de una liga de `n` clubes: {elite: copa grande, segunda: la menor}. Con la tabla real de cupos si el país la tiene; si no, ~1/8 de la liga.
static func plazas_continentales(pais: String, n: int) -> Dictionary:
	var elite := 0
	var segunda := 0
	for f: Array in Continental.CUPOS_UCL:
		if String(f[0]) == pais:
			elite = int(f[1])
	for f2: Array in Continental.CUPOS_UEL:
		if String(f2[0]) == pais:
			segunda = int(f2[1])
	if elite == 0:
		if pais == Continental.PAIS_ANFITRION:
			elite = 3
			segunda = 3
		else:
			for f3: Array in Continental.CUPOS_SUDAMERICA:
				if String(f3[0]) == pais:
					elite = int(f3[1])
					segunda = int(f3[1])
	if elite == 0:
		elite = clampi(int(round(float(n) / 8.0)), 1, 3)
		segunda = clampi(int(round(float(n) / 8.0)), 1, 3)
	## Una liga chica no reparte más plazas que equipos.
	elite = clampi(elite, 1, maxi(1, n / 3))
	segunda = clampi(segunda, 0, maxi(0, n / 3))
	return {"elite": elite, "segunda": segunda}

## La exigencia del club en la tabla (1 = el favorito): su puesto por reputación, corregido por palmarés, masa social y caja.
static func puesto_exigido(c: Club, rank: int, n: int, historia: Dictionary) -> int:
	if n <= 1:
		return 1
	var q := float(rank - 1) / float(n - 1)
	q -= minf(float(historia.get("titulos", 0)), 20.0) / 20.0 * 0.15   ## un grande de historia no se conforma con la mitad de la tabla
	var aforo := float(maxi(c.estadio_aforo, 1))
	if c.socios > 0:
		var ratio := float(c.socios) / aforo
		q += (-0.05 if ratio > 1.2 else (0.05 if ratio < 0.4 else 0.0))   ## mucha masa social = más presión
	if c.saldo < 0:
		q += 0.06   ## con las cuentas en rojo no se le exige tanto
	elif c.saldo > Eco.escalar(20000000.0, float(c.rep)):
		q -= 0.05
	return clampi(1 + int(round(clampf(q, 0.0, 1.0) * float(n - 1))), 1, n)

## El objetivo de liga: {texto, meta}.
static func principal(c: Club, exigido: int, n: int, plazas_desc: int, pl: Dictionary) -> Dictionary:
	if c.division == 2:
		var asc := clampi(2, 1, maxi(1, n / 4))
		if exigido <= maxi(1, int(round(float(n) * 0.2))):
			return {"texto": "Ascender a Primera", "meta": asc}
		if exigido <= int(round(float(n) * 0.5)):
			return {"texto": "Pelear el ascenso (top %d)", "meta": clampi(asc + 4, 1, n)}
		return {"texto": "Terminar en mitad de tabla (top %d)", "meta": clampi(int(round(float(n) * 0.6)), 1, n)}
	var e := int(pl["elite"])
	var s := int(pl["segunda"])
	if exigido <= maxi(1, int(round(float(n) * 0.1))):
		return {"texto": "Salir campeón", "meta": 1}
	if exigido <= e + int(round(float(n) * 0.12)):
		var k := copa_grande(c.pais)
		return {"texto": "Clasificar a la Champions League (top %d)" if k == "ucl" else ("Clasificar a la Libertadores (top %d)" if k == "lib" else "Clasificar a copa internacional (top %d)"), "meta": e}
	if s > 0 and exigido <= e + s + int(round(float(n) * 0.1)):
		return {"texto": "Clasificar a copa internacional (top %d)", "meta": e + s}
	if exigido <= int(round(float(n) * 0.55)):
		return {"texto": "Terminar en la mitad superior (top %d)", "meta": clampi(int(round(float(n) * 0.5)), 1, n)}
	var salvo := clampi(n - plazas_desc, 1, n)
	if exigido <= int(round(float(n) * 0.75)) and salvo - 2 >= 1:
		return {"texto": "Salvarse con holgura (top %d)", "meta": salvo - 2}
	return {"texto": "Evitar el descenso", "meta": salvo}

## Todo el paquete para el club `c` (el que dirige el jugador) en su liga. Devuelve {} si no hay liga.
static func generar(m: Mundo, c: Club) -> Dictionary:
	var liga: Liga = m.liga_de(c) if m != null and c != null else null
	if liga == null:
		return {}
	var n := liga.clubes.size()
	var orden := liga.clubes.duplicate()
	orden.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	var rank := orden.find(c) + 1
	var hi := HistoriaClub.de(c, liga.clubes)
	var pl := plazas_continentales(c.pais, n)
	var exigido := puesto_exigido(c, rank, n, hi)
	var pr := principal(c, exigido, n, liga.plazas_descenso, pl)
	var h := absi(("obj|" + c.id).hash())
	var tope := exigido <= maxi(1, int(round(float(n) * 0.34)))   ## de los de arriba
	var sec: Array[Dictionary] = []
	## Copa: cuánto se le pide según su altura.
	if m.copa != null and m.copa.participantes.has(c):
		var cupo := 4 if exigido <= int(round(float(n) * 0.25)) else (8 if exigido <= int(round(float(n) * 0.6)) else 16)
		if exigido <= maxi(1, int(round(float(n) * 0.1))) and int(hi.get("copas", 0)) >= 4:
			cupo = 2   ## ¡a por la final!
		var texto := "Llegar a la final de copa" if cupo == 2 else ("Llegar a semifinales de copa" if cupo == 4 else ("Llegar a cuartos de copa" if cupo == 8 else "Superar la primera ronda de copa"))
		sec.append({"id": "copa", "tipo": "copa", "texto": texto, "meta": cupo, "peso": 6 if cupo <= 4 else 4})
	## Copa continental para los de arriba.
	if exigido <= pl["elite"] + pl["segunda"] + int(round(float(n) * 0.1)) and c.division == 1:
		var grande := exigido <= int(pl["elite"]) + 1
		sec.append({"id": "conti", "tipo": "continental", "texto": "Llegar a semifinales de la copa continental" if grande else "Superar la fase de grupos continental",
			"meta": 4 if grande else 8, "peso": 8 if grande else 5})
	## Economía.
	if c.saldo < 0:
		sec.append({"id": "eco", "tipo": "economia", "texto": "Salir de los números rojos", "meta": 0, "peso": 8})
	elif c.saldo < Eco.escalar(2000000.0, float(c.rep)):
		sec.append({"id": "eco", "tipo": "economia", "texto": "Aumentar la caja un 10 %", "meta": 10, "peso": 5})
	else:
		sec.append({"id": "eco", "tipo": "economia", "texto": "No gastar más del 10 % de la caja", "meta": -10, "peso": 5})
	## Dos más según el club: cantera, masa social o estilo (por hash, el mismo club siempre los mismos).
	var extras := ["cantera", "social", "estilo"]
	extras.remove_at(h % 3)
	for k: String in extras:
		match k:
			"cantera":
				var nj := 2 if tope else (3 if exigido <= int(round(float(n) * 0.6)) else 4)
				sec.append({"id": "cantera", "tipo": "cantera", "texto": "Tener %d jugadores sub-21 en la plantilla", "meta": nj, "peso": 5})
			"social":
				if c.socios > 0:
					sec.append({"id": "social", "tipo": "social", "texto": "Aumentar la masa social un 5 %", "meta": 5, "peso": 4})
			"estilo":
				if tope:
					sec.append({"id": "estilo", "tipo": "estilo", "texto": "Ser de los tres equipos más goleadores", "meta": 3, "peso": 5})
				else:
					sec.append({"id": "estilo", "tipo": "estilo", "texto": "Encajar menos goles que la media de la liga", "meta": 0, "peso": 5})
	return {
		"principal": pr, "secundarios": sec, "proyecto": _proyecto(c, exigido, n, pl, hi, rank),
		"bases": {"saldo": c.saldo, "socios": c.socios, "puesto": exigido, "anio": m.anio},
	}

## El proyecto a 3 temporadas según la situación del club.
static func _proyecto(c: Club, exigido: int, n: int, pl: Dictionary, hi: Dictionary, rank: int) -> Dictionary:
	var kind := "mejorar"
	var texto := "Mejorar 3 puestos en la tabla en 3 temporadas"
	var meta := 3
	if c.saldo < 0:
		kind = "sanear"
		texto = "Sanear las cuentas: caja en positivo en 3 temporadas"
		meta = 0
	elif c.division == 2:
		kind = "ascender"
		texto = "Subir a Primera en 3 temporadas"
		meta = 2
	elif exigido <= maxi(1, int(round(float(n) * 0.1))):
		kind = "titulo"
		texto = "Ganar el título de liga en 3 temporadas"
		meta = 1
	elif int(hi.get("titulos", 0)) >= 8 and exigido > int(pl["elite"]) + int(pl["segunda"]):
		kind = "volver"
		texto = "Volver a la copa continental en 3 temporadas"
		meta = int(pl["elite"]) + int(pl["segunda"])
	elif exigido > int(round(float(n) * 0.6)):
		kind = "consolidar"
		texto = "Consolidarse: 3 temporadas seguidas sin descender"
		meta = n - 1
	return {"id": kind, "texto": texto, "meta": meta, "temporadas": TEMPORADAS_PROYECTO, "cierres": 0, "mejor_puesto": 0,
		"titulos": 0, "puesto_base": rank, "saldo_base": c.saldo, "sin_descender": true, "con_conti": false}

## ¿Cuántas rondas ganó el club en esa copa (o copa continental)? El campeón las ganó todas.
static func rondas_ganadas(copa: Copa, c: Club) -> int:
	var g := 0
	for ronda: Dictionary in copa.historial:
		for r: Dictionary in ronda.get("resultados", []):
			if r.get("pasa") == c:
				g += 1
	return g

## Cuántas rondas hacen falta para «llegar a» la ronda de `cupo` equipos (2 = final, 4 = semifinales, 8 = cuartos, 16 = octavos…).
static func rondas_para(copa: Copa, cupo: int) -> int:
	var total := 0
	var p := copa.participantes.size()
	while p > 1:
		p /= 2
		total += 1
	var restantes := 0
	var q := cupo
	while q > 1:
		q /= 2
		restantes += 1
	return maxi(0, total - restantes)
