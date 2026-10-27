extends BaseIdea
func _probar() -> void:
	for s in [101, 202, 303]:
		var m := Mundo.new()
		m.generar(["CHI"], s)
		var primera: Array = m.ligas[0].clubes.duplicate()
		primera.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
		m.tomar_el_mando(primera[0].id)
		var yo: Club = m.mi_club()
		var linea := "s%d ref %.1f M caja0 %.1f :" % [s, Eco.ref_caja(float(yo.rep)) / 1e6, float(yo.saldo) / 1e6]
		var neg := 0
		for t in 10:
			var antes := yo.saldo
			m.jugar_temporada()
			var golpes := 0
			for e: Dictionary in m.libro_financiero:
				if int(e["anio"]) == m.anio and String(e["concepto"]) in ["Multa de la federación", "Recorte del patrocinador", "Sobrecoste de obra"]:
					golpes += 1
			m.nueva_temporada()
			var d := float(yo.saldo - antes) / 1e6
			if d < 0.0:
				neg += 1
			linea += " %+.1f(%d)" % [d, golpes]
		print(linea, " | caja final ", float(yo.saldo) / 1e6, " negativas ", neg)
	_comprobar(true, "x")
