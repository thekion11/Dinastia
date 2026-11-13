extends Node
func _ready() -> void:
	var m := Mundo.new()
	var ps: Array[String] = []
	ps.assign([OS.get_environment("PAISES")])
	m.generar(ps, 20261103)
	var c: Club = m.ligas[0].clubes[int(OS.get_environment("CLUBES"))]
	m.tomar_el_mando(c.id)
	print("reglas ", LeyesPais.reglas(c.pais))
	for s in 12:
		for k in 4:
			var ev := EventosClub.pendiente(m)
			if ev.is_empty():
				break
			EventosClub.aplicar(m, ev, 0)
		m.avanzar_semana()
		print("sem %2d plantel %d cupo %d tope_votado %d desde %d exceso %d infr %s caja %s" % [m.semana, c.plantilla.size(), LeyesPais.cuantos_cupo(c), m.federacion.tope_extranjeros, m.federacion.tope_desde, LeyesPais.exceso_plantel(c, m.federacion.tope_multable(m.anio, m.semana)), m.federacion.infracciones_de(m.anio), Eco.dinero(c.saldo)])
	get_tree().quit()
