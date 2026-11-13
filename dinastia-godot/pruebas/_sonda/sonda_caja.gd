extends Node
## Sonda (13-11): la caja del club del jugador al empezar y tras N semanas SIMULADAS sin gestionar nada (sin fichar, sin obras, sin subir
## la entrada). PAISES=USA,NED,ESP CLUBES=0,6,12 SEMANAS=14
func _ready() -> void:
	var semanas := maxi(1, int(OS.get_environment("SEMANAS")))
	for pais: String in OS.get_environment("PAISES").split(","):
		for idx: String in OS.get_environment("CLUBES").split(","):
			var m := Mundo.new()
			var ps: Array[String] = []
			ps.assign([pais])
			m.generar(ps, 20261103)
			var liga: Liga = m.ligas[0]
			var c: Club = liga.clubes[int(idx) % liga.clubes.size()]
			m.tomar_el_mando(c.id)
			var antes := c.saldo
			var sueldos := 0
			for j: Jugador in c.plantilla:
				sueldos += j.sueldo
			for s in semanas:
				for k in 4:
					var ev := EventosClub.pendiente(m)
					if ev.is_empty():
						break
					EventosClub.aplicar(m, ev, 0)
				m.avanzar_semana()
			print("%s %-20s rep %2d  caja %7.1f M → %7.1f M  (%+.1f M en %d sem)  sueldos %.2f M/sem" % [pais, c.nombre, c.rep, antes / 1e6, c.saldo / 1e6, (c.saldo - antes) / 1e6, semanas, sueldos / 1e6])
	get_tree().quit()
