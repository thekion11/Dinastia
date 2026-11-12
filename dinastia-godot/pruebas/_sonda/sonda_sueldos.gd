extends Node
## Sonda: masa salarial sobre ingresos previstos, por país, al empezar una partida.
func _ready() -> void:
	for pais: String in OS.get_environment("PAISES").split(","):
		var m := Mundo.new()
		var ps: Array[String] = []
		ps.assign([pais])
		m.generar(ps, 20261103)
		var liga: Liga = m.ligas[0]
		var pcts: Array = []
		var rojos := 0
		for c: Club in liga.clubes:
			m.tomar_el_mando(c.id)
			var f: Finanzas = m._finanzas_de_la_semana(c)
			var proy := f.proyeccion_anual(int(liga.jornadas() / 2), m.ingreso_tienda(c))
			pcts.append(int(proy["pct_salarial"]))
			if int(proy["resultado"]) < 0:
				rojos += 1
		pcts.sort()
		print("%s clubes %2d  pct salarial min %3d  mediana %3d  max %3d  · sobre 70%%: %2d · ejercicio en rojo: %2d" % [pais, pcts.size(), pcts[0], pcts[pcts.size() / 2], pcts[pcts.size() - 1], pcts.filter(func(x: int) -> bool: return x > 70).size(), rojos])
	get_tree().quit()
