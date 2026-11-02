extends BaseIdea
## EL PARTIDO SIMULADO TIENE VIDA (01-11-2026, fase 4 «jugabilidad», ideas «verificar jugando» 355, 357, 358, 376 y 801): en 40
## partidos simulados hay momentum que cambia de lado, xG que suma, palos, ocasiones falladas, decisiones arbitrales, y el
## perfil del árbitro se nota (el tarjetero saca más; el casero, contra el que visita).

func _jugar(m: Mundo, i: int, perfil: String) -> Dictionary:
	var a: Club = m.ligas[0].clubes[i % 8]
	var b: Club = m.ligas[0].clubes[8 + (i % 8)]
	var p := Partido.new(a, b)
	var r := {"tarj_l": 0, "tarj_v": 0, "palos": 0, "decisiones": 0, "remates": 0}
	p.tarjeta.connect(func(j: Jugador, _roja: bool, _min: int) -> void: r["tarj_l" if j.club_id == a.id else "tarj_v"] += 1)
	p.remate.connect(func(_c: Club, _au: Jugador, tipo: String, _min: int) -> void:
		r["remates"] += 1
		if tipo == "poste":
			r["palos"] += 1)
	p.decision_arbitral.connect(func(_tx: String, _min: int) -> void: r["decisiones"] += 1)
	p.preparar()
	if perfil != "-":
		p.arbitro = {"nombre": "Árbitro de prueba", "perfil": perfil}
	while not p.terminado_ya:
		p.simular_minuto()
	r["remates"] = p.remates_local + p.remates_visita
	r["xg"] = p.xg_local + p.xg_visita
	r["goles"] = p.goles_local + p.goles_visita
	r["momentum"] = p.momentum_eventos.size()
	var lados := {}
	for v: int in p.momentum_eventos:
		lados[signi(v)] = true
	r["momentum_lados"] = lados.size()
	return r

func _probar() -> void:
	_titulo("EL PARTIDO SIMULADO TIENE VIDA")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var tot := {}
	var por_perfil := {}
	for perfil: String in ["", "tarjetero", "casero"]:
		por_perfil[perfil] = {"tarj_l": 0, "tarj_v": 0}
		for i in 40:
			var r := _jugar(m, i, perfil)
			for k: String in r:
				tot[k] = float(tot.get(k, 0.0)) + float(r[k])
			por_perfil[perfil]["tarj_l"] += int(r["tarj_l"])
			por_perfil[perfil]["tarj_v"] += int(r["tarj_v"])
	var n := 120.0
	_comprobar(float(tot["momentum"]) / n > 3.0 and float(tot["momentum_lados"]) / n > 1.5, "momentum: %.1f empujones por partido y cambia de lado" % (float(tot["momentum"]) / n))
	_comprobar(float(tot["xg"]) / n > 1.0, "xG: %.2f por partido (goles %.2f)" % [float(tot["xg"]) / n, float(tot["goles"]) / n])
	_comprobar(float(tot["palos"]) > 0.0, "hay palos (%d en %d partidos)" % [int(tot["palos"]), int(n)])
	_comprobar(float(tot["remates"]) > float(tot["goles"]) * 3.0, "ocasiones falladas: %.1f remates por gol" % (float(tot["remates"]) / maxf(float(tot["goles"]), 1.0)))
	_comprobar(float(tot["decisiones"]) > 0.0, "decisiones arbitrales anunciadas (%d)" % int(tot["decisiones"]))
	var neutro: Dictionary = por_perfil[""]
	var tarjetero: Dictionary = por_perfil["tarjetero"]
	var casero: Dictionary = por_perfil["casero"]
	_comprobar(int(tarjetero["tarj_l"]) + int(tarjetero["tarj_v"]) > int(neutro["tarj_l"]) + int(neutro["tarj_v"]), "el tarjetero saca más (%d frente a %d)" % [int(tarjetero["tarj_l"]) + int(tarjetero["tarj_v"]), int(neutro["tarj_l"]) + int(neutro["tarj_v"])])
	_comprobar(int(casero["tarj_v"]) - int(casero["tarj_l"]) > int(neutro["tarj_v"]) - int(neutro["tarj_l"]), "el casero castiga al visitante (%d-%d frente a %d-%d)" % [int(casero["tarj_l"]), int(casero["tarj_v"]), int(neutro["tarj_l"]), int(neutro["tarj_v"])])
