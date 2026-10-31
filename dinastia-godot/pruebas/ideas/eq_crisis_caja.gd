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
	## Aplicado a la partida: primero AVISA (sin cobrar), tres semanas después cobra y lo apunta.
	var m := Mundo.new()
	m.generar(["CHI"], 71)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = int(Eco.ref_caja(float(c.rep)) * 6.0)
	var antes := c.saldo
	var aviso := {}
	var semana_aviso := 0
	for s_ in range(1, 80):
		m.semana = s_
		CrisisCaja.semana(m)
		if not m.roles.crisis_pendiente.is_empty():
			aviso = (m.roles.crisis_pendiente[0] as Dictionary).duplicate()
			semana_aviso = s_
			break
	_comprobar(not aviso.is_empty() and c.saldo == antes, "primero AVISA y no cobra todavía (semana %d: %s por %d)" % [semana_aviso, str(aviso.get("tipo")), int(aviso.get("importe", 0))])
	_comprobar(int(aviso["vence"]) == m.anio * 60 + semana_aviso + CrisisCaja.AVISO_SEMANAS, "el cobro vence a las %d semanas" % CrisisCaja.AVISO_SEMANAS)
	var m_copia := Partida.desde_instantanea(Partida.instantanea(m))
	_comprobar(m_copia.roles.crisis_pendiente.size() == 1 and int(m_copia.roles.crisis_pendiente[0]["vence"]) == int(aviso["vence"]), "el aviso se guarda con la partida")
	m.semana = semana_aviso + CrisisCaja.AVISO_SEMANAS - 1
	CrisisCaja.semana(m)
	_comprobar(c.saldo == antes and m.roles.crisis_pendiente.size() == 1, "una semana antes de vencer sigue sin cobrar")
	m.semana = semana_aviso + CrisisCaja.AVISO_SEMANAS
	var cobrado := CrisisCaja.semana(m)
	_comprobar(not cobrado.is_empty() and c.saldo == antes - int(aviso["importe"]) and m.roles.crisis_pendiente.is_empty(), "al vencer cobra todo (%d → %d)" % [antes, c.saldo])
	var ultimo: Dictionary = m.libro_financiero[m.libro_financiero.size() - 1]
	_comprobar(String(ultimo["concepto"]) == CrisisCaja.concepto(String(aviso["tipo"])) and int(ultimo["monto"]) == -int(aviso["importe"]), "y se apunta en el libro como «%s»" % String(ultimo["concepto"]))
	_comprobar(CrisisCaja.reciente(m), "queda en enfriamiento: no se avisa otro en seguida")
	## Se esquiva con el consejero que toca: el mismo mundo, con el consejero ya en el directorio, paga menos.
	var key: String = CrisisCaja.REBAJA[String(aviso["tipo"])][0]
	var m2 := Mundo.new()
	m2.generar(["CHI"], 71)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	var c2 := m2.mi_club()
	c2.saldo = antes
	m2.roles.crisis_pendiente = [aviso.duplicate()]
	m2.directiva.consejeros[key] = {"nombre": "x", "edad": 50, "perfil": ""}
	m2.semana = semana_aviso + CrisisCaja.AVISO_SEMANAS
	CrisisCaja.semana(m2)
	var esperado := int(round(float(aviso["importe"]) * (1.0 - float(CrisisCaja.REBAJA[String(aviso["tipo"])][1])) / 1000.0)) * 1000
	_comprobar(antes - c2.saldo == esperado and esperado < int(aviso["importe"]), "con el consejero «%s» el golpe baja de %d a %d" % [key, int(aviso["importe"]), antes - c2.saldo])
	## Contratarlo DENTRO de la ventana de aviso también vale (se mira al cobrar).
	var m3 := Mundo.new()
	m3.generar(["CHI"], 71)
	m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
	m3.mi_club().saldo = antes
	m3.roles.crisis_pendiente = [aviso.duplicate()]
	m3.semana = semana_aviso + 1
	m3.directiva.consejeros[key] = {"nombre": "x", "edad": 50, "perfil": ""}   ## lo contrata con el aviso en marcha
	m3.semana = semana_aviso + CrisisCaja.AVISO_SEMANAS
	CrisisCaja.semana(m3)
	_comprobar(antes - m3.mi_club().saldo == esperado, "y contratarlo con el aviso ya en marcha lo esquiva igual")
