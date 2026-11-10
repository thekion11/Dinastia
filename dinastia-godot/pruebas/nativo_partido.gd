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
