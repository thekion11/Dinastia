extends BaseIdea
## PRIMER CONTRATO DEL CANTERANO Y TOPE DE TECHOS (26-10-2026, plan del lunes §8). Comprueba que el chico de 19
## o menos que sube de la cantera cobra el 45% hasta su primera firma nueva, que el guardado lo conserva (y que
## un guardado viejo sin el campo carga sin él), y mide la nómina del humano y lo raras que son las joyas (90+).

func _probar() -> void:
	_titulo("PRIMER CONTRATO DEL CANTERANO Y TECHOS")
	var m := _mundo(2600)
	var c := m.mi_club()
	## 1) La rebaja y su fin.
	var j := m.crear_jugador(c, "MED", "MC", 18, 60)
	j.pot = 80
	j.tasar()
	var pleno := j.sueldo
	j.primer_contrato = true
	j.tasar()
	_comprobar(absf(float(j.sueldo) / float(pleno) - Jugador.FACTOR_PRIMER_CONTRATO) < 0.06,
		"el primer contrato cobra ~45%% (%d de %d)" % [j.sueldo, pleno])
	_comprobar(absi(j.sueldo_pleno() - pleno) <= 20, "sueldo_pleno() recupera el de mercado (%d ≈ %d)" % [j.sueldo_pleno(), pleno])
	## 2) Guardado: ida y vuelta, y guardado viejo sin "pc".
	var d := Partida._jugador_a_dic(j)
	_comprobar(bool(d.get("pc", false)), "el guardado escribe el primer contrato")
	_comprobar(Partida._dic_a_jugador(d).primer_contrato, "y lo vuelve a leer")
	d.erase("pc")
	_comprobar(not Partida._dic_a_jugador(d).primer_contrato, "un guardado viejo carga sin primer contrato")
	## 3) La primera firma nueva lo cierra.
	Contratos.ajustar_anios(j, 3)
	j.tasar()
	_comprobar(not j.primer_contrato and absi(j.sueldo - pleno) <= 20, "la renovación lo cierra y cobra el pleno (%d)" % j.sueldo)
	## 4) La camada: los de 19 o menos entran con primer contrato.
	var camada: Array[Jugador] = m.cantera._camada_de(c)
	var con := 0
	for k in camada:
		if k.edad <= 19 and k.primer_contrato:
			con += 1
	_comprobar(not camada.is_empty() and con == camada.size(), "la camada sube con primer contrato (%d de %d)" % [con, camada.size()])
	## 5) Lo raras que son las joyas: 400 camadas de un club rep 85.
	var techos: Array[int] = []
	var grande := c
	for i in 200:
		var cam: Array[Jugador] = m.cantera._camada_de(grande)
		for k in cam:
			techos.append(k.pot)
			grande.plantilla.erase(k)
	var n90 := techos.filter(func(t: int) -> bool: return t >= 90).size()
	var n95 := techos.filter(func(t: int) -> bool: return t >= 95).size()
	_linea("  camada (rep %d): %d chicos · techo ≥90: %.1f%% · ≥95: %.1f%% · máx %d" % [grande.rep, techos.size(),
		100.0 * n90 / maxf(1.0, techos.size()), 100.0 * n95 / maxf(1.0, techos.size()), techos.max()])
	_comprobar(techos.max() <= 97, "ningún techo pasa de 97")
	_comprobar(float(n95) / maxf(1.0, techos.size()) < 0.02, "los techos de 95+ son raros (< 2%)")
	## 6) Nómina del humano en tres temporadas sin tocar nada.
	var m2 := _mundo(101)
	var yo := m2.mi_club()
	for t in 3:
		m2.jugar_temporada()
		m2.nueva_temporada()
		var nom := 0
		var pc := 0
		for k in yo.plantilla:
			nom += k.sueldo
			if k.primer_contrato:
				pc += 1
		_linea("  t%d  nómina humano %d/sem · %d con primer contrato · plantel %d" % [t + 1, nom, pc, yo.plantilla.size()])
