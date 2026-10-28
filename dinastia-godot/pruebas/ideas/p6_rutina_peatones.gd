extends BaseIdea
## M-183: rutinas de peatones por hora y barrio (curvas por sector, prisa y paradas).

const POS := {100: Vector3(0, 0, 0), 200: Vector3(0, 0, -600), 300: Vector3(700, 0, 0), 400: Vector3(0, 0, 800), 500: Vector3(-700, 0, 0), 600: Vector3(1500, 0, 0)}

func _probar() -> void:
	_titulo("P6: RUTINAS DE PEATONES POR HORA Y BARRIO")
	for s: int in POS:
		_comprobar(RecorridosRed.sector_de(POS[s]) == s, "el punto de prueba cae en el sector %d" % s)
	_comprobar(RutinaPeatones.densidad(8.0, 200) > RutinaPeatones.densidad(11.0, 200) + 0.1, "centro: la hora punta de las 8 supera a media mañana")
	_comprobar(RutinaPeatones.densidad(13.0, 200) > RutinaPeatones.densidad(11.0, 200), "centro: la comida de las 13 sube")
	_comprobar(RutinaPeatones.densidad(7.5, 400) > 0.8 and RutinaPeatones.densidad(13.0, 400) < 0.55, "sur residencial: sale por la mañana y a mediodía queda poca gente")
	_comprobar(RutinaPeatones.densidad(22.5, 500) > RutinaPeatones.densidad(18.0, 500) + 0.2, "puerto: el turno de las 22:30 llena la calle")
	_comprobar(RutinaPeatones.densidad(18.0, 300) > RutinaPeatones.densidad(8.0, 300) + 0.2, "este (compras): por la tarde más que por la mañana")
	_comprobar(RutinaPeatones.densidad(3.0, 200) < 0.2 and RutinaPeatones.densidad(3.0, 100) < 0.2, "de madrugada, poca gente")
	_comprobar(RutinaPeatones.densidad(12.0, 600) < 0.5, "periferia: poca gente a cualquier hora")
	_comprobar(RutinaPeatones.prisa(8.0, 200) > 1.2 and RutinaPeatones.prisa(13.2, 200) < 0.95, "con prisa en hora punta y paseando a la hora de comer")
	_comprobar(RutinaPeatones.pausa(13.2, 300) > 2.5 and RutinaPeatones.pausa(8.0, 200) < 1.0, "más paradas a la hora de comer, casi ninguna en hora punta")
	## Sobre una lista de peatones de verdad.
	var lista: Array = []
	for s: int in [100, 200, 300, 400, 500]:
		for k in 60:
			var n := Node3D.new()
			add_child(n)
			n.position = POS[s] + Vector3(float(k), 0, 0)
			n.rotation.y = 0.0 if k % 2 == 0 else PI   ## mitad hacia +Z, mitad hacia −Z
			lista.append({"peaton": true, "nodo": n, "vel": 1.4, "sector": s})
	var r3 := RutinaPeatones.tick(lista, 3.0)
	var r8 := RutinaPeatones.tick(lista, 8.0)
	_comprobar(int(r8["visibles"]) > int(r3["visibles"]) * 2, "a las 8 hay mucha más gente que a las 3 (%d frente a %d de %d)" % [r8["visibles"], r3["visibles"], r8["total"]])
	_comprobar(float(r8["prisa"]) > 1.12, "a las 8 la gente anda con prisa (%.2f)" % float(r8["prisa"]))
	var centro8 := 0
	var sur8 := 0
	var sur13 := 0
	for v: Dictionary in lista:
		if int(v["sector"]) == 200 and (v["nodo"] as Node3D).visible:
			centro8 += 1
	RutinaPeatones.tick(lista, 7.5)
	for v: Dictionary in lista:
		if int(v["sector"]) == 400 and (v["nodo"] as Node3D).visible:
			sur8 += 1
	RutinaPeatones.tick(lista, 13.0)
	for v: Dictionary in lista:
		if int(v["sector"]) == 400 and (v["nodo"] as Node3D).visible:
			sur13 += 1
	_comprobar(centro8 >= 40 and sur8 > sur13 + 10, "centro a las 8: %d de 60; sur 7:30 = %d y a las 13:00 = %d" % [centro8, sur8, sur13])
	RutinaPeatones.tick(lista, 13.2)
	var vel_comer := float((lista[0] as Dictionary)["vel"])
	RutinaPeatones.tick(lista, 8.0)
	var vel_punta := float((lista[0] as Dictionary)["vel"])
	_comprobar(vel_punta > vel_comer * 1.2, "la velocidad se reescala sin acumularse (%.2f → %.2f)" % [vel_comer, vel_punta])
	RutinaPeatones.tick(lista, 8.0)
	_comprobar(is_equal_approx(float((lista[0] as Dictionary)["vel"]), vel_punta), "repasar dos veces a la misma hora no cambia nada")
	## Un oculto por la noche (faros) sigue oculto aunque la hora lo deje salir.
	(lista[5] as Dictionary)["oculto"] = true
	RutinaPeatones.tick(lista, 8.0)
	_comprobar(not ((lista[5] as Dictionary)["nodo"] as Node3D).visible, "el que oculta la noche sigue oculto")
	## Sentido del flujo: por la mañana, más peatones hacia el trabajo; por la tarde, más de vuelta.
	var gente: Array = []
	for k in 200:
		var n := Node3D.new()
		add_child(n)
		n.position = Vector3(0, 0, 100) + Vector3(float(k), 0, 0)   ## sector 100, al sur del trabajo
		n.rotation.y = PI if k % 2 == 0 else 0.0   ## PI: mira a −Z (hacia el trabajo); 0: mira a +Z (se aleja)
		gente.append({"peaton": true, "nodo": n, "vel": 1.4})
	RutinaPeatones.tick(gente, 8.0)
	var hacia8 := 0
	var lejos8 := 0
	for k in gente.size():
		if ((gente[k] as Dictionary)["nodo"] as Node3D).visible:
			if k % 2 == 0:
				hacia8 += 1
			else:
				lejos8 += 1
	RutinaPeatones.tick(gente, 18.0)
	var hacia18 := 0
	var lejos18 := 0
	for k in gente.size():
		if ((gente[k] as Dictionary)["nodo"] as Node3D).visible:
			if k % 2 == 0:
				hacia18 += 1
			else:
				lejos18 += 1
	_comprobar(hacia8 > lejos8 + 10, "a las 8 van más hacia el trabajo (%d) que de vuelta (%d)" % [hacia8, lejos8])
	_comprobar(lejos18 > hacia18 + 10, "a las 18 vuelven más (%d) que van (%d)" % [lejos18, hacia18])
	## Maletines: solo en hora punta y rumbo al trabajo (mañana) o de vuelta (tarde).
	_comprobar(RutinaPeatones.lleva_maletin(8.0, 0.9, 0) and not RutinaPeatones.lleva_maletin(8.0, -0.9, 0), "a las 8 lleva maletín quien va al trabajo, no quien vuelve")
	_comprobar(RutinaPeatones.lleva_maletin(18.0, -0.9, 0) and not RutinaPeatones.lleva_maletin(13.0, 0.9, 0), "a las 18 lo lleva quien vuelve, y a las 13 nadie")
	var con := 0
	for k in 300:
		if RutinaPeatones.lleva_maletin(8.0, 0.9, k):
			con += 1
	_comprobar(con > 70 and con < 130, "más o menos uno de cada tres lo lleva (%d de 300)" % con)
