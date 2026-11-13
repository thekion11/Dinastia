extends Node
## Sonda (13-11): semanas perdidas por lesión del club del jugador tras media temporada simulada, contra la referencia que
## `Medico.ranking_liga` estima para los rivales. PAISES=ESP,ARG CLUBES=0,7,15 SEMANAS=19
func _ready() -> void:
	var semanas := maxi(1, int(OS.get_environment("SEMANAS")))
	for pais: String in OS.get_environment("PAISES").split(","):
		for idx: String in OS.get_environment("CLUBES").split(","):
			var m := Mundo.new()
			var ps: Array[String] = []
			ps.assign([pais])
			m.generar(ps, 20261103 + int(idx))
			var liga: Liga = m.ligas[0]
			var c: Club = liga.clubes[int(idx) % liga.clubes.size()]
			m.tomar_el_mando(c.id)
			for s in semanas:
				for k in 4:
					var ev := EventosClub.pendiente(m)
					if ev.is_empty():
						break
					EventosClub.aplicar(m, ev, 0)
				m.avanzar_semana()
			var jugado := float(m.semana - 1) / Medico.SEMANAS_TEMPORADA
			var r: Dictionary = m.medico.ranking_liga(c, liga, jugado)
			print("%s %-22s rep %2d  jornada %2d/%2d  mías %3d sem  media rivales %3d sem  puesto %2d de %2d" % [pais, c.nombre, c.rep, liga.jornada_actual, liga.jornadas(), int(r["mias"]), int(r["media"]), int(r["puesto"]), int(r["total"])])
	get_tree().quit()
