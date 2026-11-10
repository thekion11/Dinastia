class_name AscensosPais
extends RefCounted
## EL CIERRE DE LAS DIVISIONES DE CADA PAÍS (antes un bloque dentro de `Mundo._cerrar_campeonato`): quién baja de Primera y quién sube de
## Segunda, con las reglas de siempre o, en los países que las tienen, las REALES (`ReglasAscenso`: tres bajan en ENG/ESP/ITA, dos directos
## y un playoff de cuatro para el tercer ascenso, y la promoción 16.º contra 3.º en GER y FRA).

## Cierra todos los países con dos divisiones. `tablas` es la foto de las tablas ANTES de mover a nadie; `resumen` recoge bajan, suben y la promoción.
static func cerrar(m: Mundo, tablas: Dictionary, resumen: Dictionary) -> void:
	for primera in m.ligas:
		if primera.division() != 1:
			continue
		var segunda: Liga = m._segunda_de(primera.pais)
		if segunda == null:
			continue
		var t1: Array = tablas.get(primera, primera.tabla())
		var t2: Array = tablas.get(segunda, segunda.tabla())
		if t1.size() < 3 or t2.size() < 3:
			continue
		var bajan: Array[Club] = []
		var suben: Array[Club] = []
		if ReglasAscenso.tiene(primera.pais):
			_reales(m, t1, t2, ReglasAscenso.de(primera.pais), bajan, suben, resumen)
		else:
			_generales(m, primera, t1, t2, bajan, suben, resumen)
		## M-219: el intervenido por deudas baja (o no sube) por despacho.
		if m.insolvencia != null:
			var castigo: Array = m.insolvencia.descenso_administrativo(m, t1, t2, bajan, suben)
			if not castigo.is_empty():
				resumen["administrativo"] = (resumen.get("administrativo", []) as Array) + castigo
		for c in bajan:
			m._mover_de_liga(c, primera, segunda)
			m._clausula_descenso(c, true)
		for c in suben:
			m._mover_de_liga(c, segunda, primera)
			m._clausula_descenso(c, false)
		resumen["bajan"].append_array(bajan)
		resumen["suben"].append_array(suben)

## Lo de siempre: bajan los últimos de Primera y suben los primeros de Segunda (tantos como diga la Primera) y, si la asamblea aprobó la
## promoción, el antepenúltimo contra el tercero de Ascenso, ida y vuelta.
static func _generales(m: Mundo, primera: Liga, t1: Array, t2: Array, bajan: Array[Club], suben: Array[Club], resumen: Dictionary) -> void:
	var n_cambio := clampi(primera.plazas_descenso, 1, mini(t1.size(), t2.size()) - 2)
	for i_c in n_cambio:
		bajan.append(t1[t1.size() - 1 - i_c]["club"])
		suben.append(t2[i_c]["club"])
	if m.federacion != null and m.federacion.promocion and t1.size() >= n_cambio + 2 and t2.size() >= n_cambio + 2:
		var arriba: Club = t1[t1.size() - 1 - n_cambio]["club"]
		var abajo: Club = t2[n_cambio]["club"]
		var prom: Dictionary = m.jugar_promocion(arriba, abajo)
		resumen["promocion"] = prom
		if prom["ganador"] == abajo:
			bajan.append(arriba)
			suben.append(abajo)

## Las reglas reales de `ReglasAscenso`: bajan `bajan`; suben los `directos` primeros y la plaza que falta sale del playoff de ascenso o de la
## promoción contra el antepenúltimo (según el país).
static func _reales(m: Mundo, t1: Array, t2: Array, r: Dictionary, bajan: Array[Club], suben: Array[Club], resumen: Dictionary) -> void:
	var n := mini(int(r["bajan"]), mini(t1.size(), t2.size()) - 5)
	if n <= 0:
		return   ## circuito cerrado (México): nadie sube ni baja
	var directos := mini(int(r.get("directos", n)), n)
	for i in n:
		bajan.append(t1[t1.size() - 1 - i]["club"])
	for i in directos:
		suben.append(t2[i]["club"])
	if int(r.get("playoff", 0)) >= 4 and n > directos and t2.size() >= directos + 4:
		var cuatro: Array[Club] = []
		for i in 4:
			cuatro.append(t2[directos + i]["club"])
		var ganador := playoff_de_ascenso(m, cuatro)
		suben.append(ganador)
		resumen["playoff_ascenso"] = {"ganador": ganador, "participantes": cuatro}
	elif bool(r.get("relegacion", false)):
		var arriba: Club = t1[t1.size() - 1 - n]["club"]
		var abajo: Club = t2[directos]["club"]
		var prom: Dictionary = m.jugar_promocion(arriba, abajo)
		resumen["promocion"] = prom
		if prom["ganador"] == abajo:
			bajan.append(arriba)
			suben.append(abajo)

## Playoff de ascenso de cuatro (3.º-6.º de Segunda, de mejor a peor): semifinales 1.º contra 4.º y 2.º contra 3.º a ida y vuelta (la vuelta, en
## casa del mejor clasificado) y final a partido único en campo neutral. Empate global o en la final: penales.
static func playoff_de_ascenso(m: Mundo, cuatro: Array[Club]) -> Club:
	var f1 := _doble(m, cuatro[0], cuatro[3])
	var f2 := _doble(m, cuatro[1], cuatro[2])
	var p := Partido.new(f1, f2, true)
	p.simular()
	var ganador: Club = f1
	if p.goles_visita > p.goles_local:
		ganador = f2
	elif p.goles_local == p.goles_visita:
		var pen := p.penales()
		ganador = f2 if int(pen[1]) > int(pen[0]) else f1
	if m.prensa != null:
		m.prensa.noticia.emit("⚔️ Playoff de ascenso: ¡%s sube!" % ganador.nombre,
			"Final: %s %d-%d %s." % [f1.nombre, p.goles_local, p.goles_visita, f2.nombre])
	return ganador

## Eliminatoria a ida y vuelta entre el mejor (`a`) y el peor (`b`) clasificado: la ida en casa de `b`, la vuelta en casa de `a`.
## Con empate global pasa `a` (la ventaja de la clasificación).
static func _doble(_m: Mundo, a: Club, b: Club) -> Club:
	var ida := Partido.new(b, a)
	ida.simular()
	var vuelta := Partido.new(a, b)
	vuelta.simular()
	var ga := ida.goles_visita + vuelta.goles_local
	var gb := ida.goles_local + vuelta.goles_visita
	return b if gb > ga else a
