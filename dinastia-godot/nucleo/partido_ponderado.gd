class_name PartidoPonderado
extends RefCounted
## EL SORTEO PONDERADO DEL GOLEADOR Y DEL ASISTENTE (10-11-2026, paso a C++), sacado de `Partido` (partido_p2.gd): es lo que más pesa de cada llegada (~23 µs c/u en GDScript).
## Con la extensión nativa (`nativo/src/partido_nativo.cpp`, `elegir_ponderado`) corre en C++ con las mismas cuentas y la misma tirada de `Azar`; sin ella (Web, `DINASTIA_SIN_NATIVO=1`,
## binario viejo) corren `goleador_gd` / `asistente_gd`, los bucles de siempre. `pruebas/probar_nativo.tscn` compara los dos con la misma semilla.

const BASES_GOL := {"DEL": 1.0, "MED": 0.42, "DEF": 0.11, "POR": 0.004}
const BASES_ASIST := {"MED": 1.0, "DEL": 0.55, "DEF": 0.22, "POR": 0.02}

static func goleador(p: Partido, once: Array[Jugador]) -> Jugador:
	var nat := Nativo.obj()
	if nat == null or once.is_empty() or not nat.has_method("elegir_ponderado"):
		return goleador_gd(p, once)
	var roles := PackedFloat64Array()
	var tac := p._tactica_de(once)
	if tac != null and not tac.roles.is_empty():
		for j in once:
			roles.append(RolTactico.peso(tac, j, "gol"))
	var i: int = nat.elegir_ponderado(once, Datos.mapa_grupos(), BASES_GOL, 0.02, "tir", roles, Azar.f(), null)
	return once[i] if i >= 0 else null

static func asistente(p: Partido, once: Array[Jugador], autor: Jugador, minuto: int) -> Jugador:
	var nat := Nativo.obj()
	if nat == null or not nat.has_method("elegir_ponderado"):
		return asistente_gd(p, once, autor, minuto)
	var roles := PackedFloat64Array()
	var tac := p._tactica_de(once)
	if tac != null and not tac.roles.is_empty():
		for j in once:
			if j != autor:
				roles.append(RolTactico.peso(tac, j, "asist"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(autor.id if autor != null else "") + "_" + str(minuto))
	var i: int = nat.elegir_ponderado(once, Datos.mapa_grupos(), BASES_ASIST, 0.05, "pas", roles, rng.randf(), autor)
	return once[i] if i >= 0 else null

static func goleador_gd(p: Partido, once: Array[Jugador]) -> Jugador:
	if once.is_empty():
		return null
	var pesos: Array[float] = []
	var total := 0.0
	var tac := p._tactica_de(once); var con_roles := tac != null and not tac.roles.is_empty()  ## sin roles, peso 1
	for j in once:
		var base := 0.02
		match Datos.grupo(j.pos_e):
			"DEL": base = 1.0
			"MED": base = 0.42
			"DEF": base = 0.11
			"POR": base = 0.004
		base *= 0.5 + float(j.atributos.get("tir", 50)) / 100.0
		base *= RolTactico.peso(tac, j, "gol") if con_roles else 1.0
		pesos.append(base)
		total += base
	var r := Azar.f() * total
	for i in once.size():
		r -= pesos[i]
		if r <= 0.0:
			return once[i]
	return once[once.size() - 1]

static func asistente_gd(p: Partido, once: Array[Jugador], autor: Jugador, minuto: int) -> Jugador:
	var candidatos: Array[Jugador] = []
	for j in once:
		if j != autor:
			candidatos.append(j)
	if candidatos.is_empty():
		return null
	var pesos: Array[float] = []
	var total := 0.0
	var tac := p._tactica_de(once); var con_roles := tac != null and not tac.roles.is_empty()
	for j in candidatos:
		var base := 0.05
		match Datos.grupo(j.pos_e):
			"MED": base = 1.0
			"DEL": base = 0.55
			"DEF": base = 0.22
			"POR": base = 0.02
		base *= 0.5 + float(j.atributos.get("pas", 50)) / 100.0
		base *= RolTactico.peso(tac, j, "asist") if con_roles else 1.0
		pesos.append(base)
		total += base
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(autor.id if autor != null else "") + "_" + str(minuto))
	var r := rng.randf() * total
	for i in candidatos.size():
		r -= pesos[i]
		if r <= 0.0:
			return candidatos[i]
	return candidatos[candidatos.size() - 1]
