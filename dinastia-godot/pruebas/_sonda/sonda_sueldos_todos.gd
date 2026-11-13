extends Node
## Sonda: masa salarial sobre ingresos previstos al empezar, en TODOS los países (una línea por país: mediana y clubes en rojo).
func _ready() -> void:
	var paises: Array = Array(LigasActivas.todos())
	if OS.get_environment("PAISES") != "":
		paises = Array(OS.get_environment("PAISES").split(","))
	for pais: String in paises:
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
		print("SUELDOS %s clubes %d mediana %d max %d rojo %d" % [pais, pcts.size(), pcts[pcts.size() / 2], pcts[pcts.size() - 1], rojos])
	get_tree().quit()
