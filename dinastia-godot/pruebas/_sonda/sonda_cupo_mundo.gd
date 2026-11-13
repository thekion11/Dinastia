extends Node
## SONDA: cuántos clubes nacen con más jugadores de cupo que el tope de su país, por país.
func _ready() -> void:
	var m := Mundo.new()
	m.generar(LigasActivas.para_generar(), 5)
	var por_pais := {}
	for c: Club in m.clubes.values():
		var e := LeyesPais.exceso_plantel(c)
		var d: Array = por_pais.get(c.pais, [0, 0, 0, 0])
		d[0] += 1
		if e > 0:
			d[1] += 1
			d[2] += e
			d[3] = maxi(d[3], e)
		por_pais[c.pais] = d
	var total := 0
	for p: String in por_pais:
		var d2: Array = por_pais[p]
		if int(d2[1]) > 0:
			total += int(d2[1])
			print("CUPO %s tope %d (%s): %d de %d clubes fuera, %d jugadores de más, peor caso %d" % [p, int(LeyesPais.reglas(p).get("plantel", 0)), String(LeyesPais.reglas(p).get("criterio", "extranjero")), d2[1], d2[0], d2[2], d2[3]])
	print("CUPO TOTAL: %d clubes fuera de %d" % [total, m.clubes.size()])
	get_tree().quit()
