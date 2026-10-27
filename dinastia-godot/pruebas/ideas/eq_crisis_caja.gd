extends BaseIdea
## CRISIS DE CAJA (27-10-2026, M-208): golpes que crecen con la caja, deterministas, que se cobran, se apuntan y no caen seguidos.

func _probar() -> void:
	_titulo("BALANCE · CRISIS DE CAJA")
	var ref := 6.6e6
	var n_rico := 0
	var n_pobre := 0
	var suma_rico := 0.0
	var suma_pobre := 0.0
	var tipos := {}
	var igual := true
	for anio in range(2026, 2076):
		for semana in range(1, 35):
			var a := CrisisCaja.tirada(7, anio, semana, int(ref * 6.0), ref)
			igual = igual and a == CrisisCaja.tirada(7, anio, semana, int(ref * 6.0), ref)
			if not a.is_empty():
				n_rico += 1
				suma_rico += float(a["importe"])
				tipos[a["tipo"]] = true
			var b := CrisisCaja.tirada(7, anio, semana, int(ref * 0.5), ref)
			if not b.is_empty():
				n_pobre += 1
				suma_pobre += float(b["importe"])
	_comprobar(igual, "misma semilla, año, semana y caja → mismo golpe")
	_comprobar(tipos.size() == 3, "salen los tres tipos: %s" % str(tipos.keys()))
	_comprobar(n_rico > n_pobre, "al club rico le llegan más golpes (%d frente a %d en 50 años)" % [n_rico, n_pobre])
	_comprobar(suma_rico / maxf(1.0, float(n_rico)) > 2.0 * suma_pobre / maxf(1.0, float(n_pobre)), "y más grandes (media %.2f M frente a %.2f M)" % [suma_rico / float(n_rico) / 1e6, suma_pobre / maxf(1.0, float(n_pobre)) / 1e6])
	_comprobar(float(n_rico) / 50.0 > 1.0 and float(n_rico) / 50.0 < 8.0, "unos %.1f golpes por temporada al rico (sin cuatro seguidos: el enfriamiento lo recorta aún)" % (float(n_rico) / 50.0))
	## Aplicado a la partida: cobra, apunta y no se repite en seguida.
	var m := Mundo.new()
	m.generar(["CHI"], 71)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = int(Eco.ref_caja(float(c.rep)) * 6.0)
	var antes := c.saldo
	var golpe := {}
	for s in range(1, 60):
		m.semana = s
		golpe = CrisisCaja.semana(m)
		if not golpe.is_empty():
			break
	_comprobar(not golpe.is_empty() and c.saldo == antes - int(golpe["importe"]), "un golpe cobra su importe de la caja (%d → %d)" % [antes, c.saldo])
	var ultimo: Dictionary = m.libro_financiero[m.libro_financiero.size() - 1]
	_comprobar(String(ultimo["concepto"]) == CrisisCaja.concepto(String(golpe["tipo"])) and int(ultimo["monto"]) == -int(golpe["importe"]), "y se apunta en el libro de movimientos como «%s»" % String(ultimo["concepto"]))
	_comprobar(CrisisCaja.reciente(m), "queda en enfriamiento: no vuelve a caer enseguida")
	var seguidos := 0
	for s in range(m.semana + 1, m.semana + CrisisCaja.ENFRIAMIENTO):
		m.semana = s
		if not CrisisCaja.semana(m).is_empty():
			seguidos += 1
	_comprobar(seguidos == 0, "ni en las %d semanas siguientes" % (CrisisCaja.ENFRIAMIENTO - 1))
