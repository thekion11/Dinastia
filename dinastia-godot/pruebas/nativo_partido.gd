class_name NativoPartido
extends RefCounted
## EL PARTIDO SIMULADO EN C++ = EL DE GDSCRIPT (10-11-2026, paso a C++; lo llama `probar_nativo.gd`). Para varios mundos (países y estilos distintos) simula las mismas jornadas dos veces con la misma semilla:
## `Partido.simular()` (la referencia, GDScript) y `PartidoRapido.simular()` (C++), y compara marcadores, estadísticas del partido, TODO el estado de los jugadores (goles, tarjetas, sanciones, lesiones, notas,
## forma, partidos…) y el estado del generador de azar al final (si un solo número del azar se hubiera gastado distinto, ya no coincidiría).

const MUNDOS := [[11, ["CHI", "ESP"]], [23, ["ENG", "ARG", "BRA"]], [37, ["GER", "ITA", "FRA"]], [51, []]]

## Devuelve {fallos: Array[String], cruces: int, rapidos: int, t_gd_us: int, t_cpp_us: int}.
static func probar(jornadas: int) -> Dictionary:
	var fallos: Array[String] = []
	var cruces := 0
	var t := [0, 0]
	var rapidos0 := PartidoRapido.por_ruta_nativa
	for mundo: Array in MUNDOS:
		var salidas: Array = [null, null]
		for modo in 2:
			var m := Mundo.new()
			var paises: Array[String] = []
			for c: String in mundo[1]:
				paises.append(c)
			m.generar(paises, int(mundo[0]))
			Azar.sembrar(int(mundo[0]) + 1000)
			Partido.ctx_anio = m.anio
			Partido.ctx_semana = m.semana
			var marcadores: Array = []
			var clubes_vistos := {}
			for liga: Liga in m.ligas:
				for j in mini(jornadas, liga.calendario.size()):
					for par: Array in liga.calendario[j]:
						var p := Partido.new(par[0], par[1])
						var t0 := Time.get_ticks_usec()
						var r := p.simular() if modo == 0 else PartidoRapido.simular(p)
						t[modo] += Time.get_ticks_usec() - t0
						marcadores.append([r["local"], r["visita"], p.remates_local, p.remates_visita, p.tiros_puerta_local, p.tiros_puerta_visita, p.xg_local, p.xg_visita, p.corners_local, p.corners_visita,
							p.faltas_local, p.faltas_visita, p.fueras_local, p.fueras_visita, p.posesion_local, p.minuto, p.suspendido, p.once_local.size(), p.once_visita.size()])
						clubes_vistos[(par[0] as Club).id] = par[0]
						clubes_vistos[(par[1] as Club).id] = par[1]
						if modo == 0:
							cruces += 1
			var jugadores: Array = []
			for id: String in clubes_vistos:
				for jug: Jugador in (clubes_vistos[id] as Club).plantilla:
					jugadores.append(var_to_str(inst_to_dict(jug)))
			salidas[modo] = {"marcadores": marcadores, "jugadores": jugadores, "azar": Azar._rng.state}
		if salidas[0]["marcadores"] != salidas[1]["marcadores"]:
			var n := 0
			for i in (salidas[0]["marcadores"] as Array).size():
				if salidas[0]["marcadores"][i] != salidas[1]["marcadores"][i]:
					n += 1
					if n == 1:
						fallos.append("mundo %s: primer cruce distinto (%d): %s frente a %s" % [mundo[0], i, salidas[0]["marcadores"][i], salidas[1]["marcadores"][i]])
			fallos.append("mundo %s: %d cruces con estadísticas distintas" % [mundo[0], n])
		if salidas[0]["jugadores"] != salidas[1]["jugadores"]:
			var n := 0
			for i in (salidas[0]["jugadores"] as Array).size():
				if salidas[0]["jugadores"][i] != salidas[1]["jugadores"][i]:
					n += 1
			fallos.append("mundo %s: %d jugadores en estado distinto" % [mundo[0], n])
		if salidas[0]["azar"] != salidas[1]["azar"]:
			fallos.append("mundo %s: el generador de azar acabó en otro estado" % mundo[0])
	return {"fallos": fallos, "cruces": cruces, "rapidos": PartidoRapido.por_ruta_nativa - rapidos0, "t_gd_us": t[0], "t_cpp_us": t[1]}

## Las cuatro medias por línea de `fuerza`: C++ = las 4 llamadas a `_media_linea`, con onces de mundos distintos y con arengas, exes y laterales de los dos pies puestos al azar.
static func probar_medias(n_cruces: int) -> Dictionary:
	var m := Mundo.new()
	var paises: Array[String] = ["ESP", "ARG", "ENG"]
	m.generar(paises, 61)
	Partido.ctx_anio = m.anio
	Partido.ctx_semana = m.semana
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var nat := Nativo.obj()
	var comparados := 0
	var distintos := 0
	var t_gd := 0
	var t_cpp := 0
	var clubes: Array = m.clubes.values()
	Partido.ex_de_mi_club = {}
	for i in n_cruces:
		var a: Club = clubes[rng.randi() % clubes.size()]
		var b: Club = clubes[rng.randi() % clubes.size()]
		if a == b:
			continue
		var p := Partido.new(a, b)
		p.sin_rastro = true
		p.preparar()
		p.minuto = rng.randi_range(0, 90)
		p.impulsos = {}
		p._factor_arenga = 1.0 + rng.randf() * 0.5 if rng.randf() < 0.5 else 1.0
		for once: Array[Jugador] in [p.once_local, p.once_visita]:
			for j: Jugador in once:
				j.forma = rng.randi_range(20, 99)
				j.fisico = rng.randi_range(40, 100)
				j.moral = rng.randi_range(20, 100)
				if rng.randf() < 0.3:
					p.impulsos[j.id] = rng.randi_range(0, 120)
				if rng.randf() < 0.1:
					Partido.ex_de_mi_club[j.id] = (b if once == p.once_local else a).id
		for once: Array[Jugador] in [p.once_local, p.once_visita]:
			var t0 := Time.get_ticks_usec()
			var g := PartidoMedias.gd(p, once)
			var t1 := Time.get_ticks_usec()
			var c := PartidoMedias.nativo(p, once, nat)
			var t2 := Time.get_ticks_usec()
			t_gd += t1 - t0
			t_cpp += t2 - t1
			comparados += 1
			if var_to_bytes(g) != var_to_bytes(c):
				distintos += 1
	Partido.ex_de_mi_club = {}
	return {"comparados": comparados, "distintos": distintos, "t_gd_us": t_gd, "t_cpp_us": t_cpp}

## (10-11, paso a C++) `Partido._cerrar_notas`: la versión C++ y su gemela GDScript sobre el mismo cruce (marcadores y notas al azar), misma semilla: mismas notas, forma, partidos, lista de notas y azar al final.
## Devuelve {comparados, distintos, t_gd_us, t_cpp_us}.
static func probar_notas(cruces: int) -> Dictionary:
	var comparados := 0
	var distintos := 0
	var t := [0, 0]
	var m := Mundo.new()
	m.generar(["ESP", "ENG", "CHI"], 91)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in cruces:
		var l: Liga = m.ligas[rng.randi_range(0, m.ligas.size() - 1)]
		var a: Club = l.clubes[rng.randi_range(0, l.clubes.size() - 1)]
		var b: Club = l.clubes[rng.randi_range(0, l.clubes.size() - 1)]
		if a == b:
			continue
		var p := Partido.new(a, b)
		p.preparar()
		p.goles_local = rng.randi_range(0, 4)
		p.goles_visita = rng.randi_range(0, 4) if i % 3 != 0 else p.goles_local
		for j in p._todos:
			p._notas[j.id] = rng.randf_range(3.0, 10.0)
		var antes: Array = []
		for j in p._todos:
			antes.append([j.forma, j.partidos, j.notas.duplicate()])
		var res: Array = [null, null]
		for modo in 2:
			for k in p._todos.size():
				var j: Jugador = p._todos[k]
				j.forma = antes[k][0]; j.partidos = antes[k][1]; j.notas = (antes[k][2] as Array).duplicate()
			p._notas_cerradas = false
			Azar.sembrar(1000 + i)
			var t0 := Time.get_ticks_usec()
			if modo == 0:
				p._cerrar_notas_gd()
			else:
				Nativo.obj().cerrar_notas(p, Azar._rng)
			t[modo] += Time.get_ticks_usec() - t0
			var est: Array = [p._notas_cerradas, Azar._rng.state]
			for j in p._todos:
				est.append([j.forma, j.partidos, j.notas])
			res[modo] = var_to_bytes(est)
		comparados += 1
		if res[0] != res[1]:
			distintos += 1
	return {"comparados": comparados, "distintos": distintos, "t_gd_us": t[0], "t_cpp_us": t[1]}
