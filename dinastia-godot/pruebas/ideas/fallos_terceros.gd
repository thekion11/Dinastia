extends BaseIdea
## LOS 8 FALLOS QUE LEAGUE-SOCCER YA RESOLVIÓ (01-11-2026, orden del dueño: «primero fallos»). Revisados: 1-5 y 7 no existen aquí;
## arreglados: la posesión que podía sumar 101 (6) y el equipo con menos de siete que seguía jugando (8). Y uno que salió de paso:
## los jugadores libres no cumplían años.

func _probar() -> void:
	_titulo("FALLOS RESUELTOS EN LEAGUE-SOCCER, EN EL NUESTRO")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var par: Array = [m.ligas[0].clubes[0], m.ligas[0].clubes[1]]
	## 6) La posesión del motor libre suma siempre 100 (antes, redondeada por separado: 50,5 + 49,5 → 101).
	var ml := MotorLibre.new((par[0] as Club).once(), (par[1] as Club).once(), 1.0, 1.0, 1)
	ml.stats["posesion"] = [50.5, 49.5]
	var r := ml.resultado()
	_comprobar(int(r["posesion"][0]) + int(r["posesion"][1]) == 100, "la posesión suma 100 (%s)" % str(r["posesion"]))
	ml.stats["posesion"] = [0.0, 0.0]
	_comprobar(r is Dictionary and ml.resultado()["posesion"] == [50.0, 50.0], "sin posesión aún, 50-50 (%s)" % str(ml.resultado()["posesion"]))
	## 8) Con menos de siete, el partido se suspende: 3-0 para el rival, o su marcador si ya ganaba por 3 o más.
	var p := Partido.new(par[0], par[1])
	p.preparar()
	var fin := []
	p.terminado.connect(func(gl: int, gv: int) -> void: fin.append([gl, gv]))
	p.goles_local = 1
	var rojas := 0
	while p.once_local.size() >= 7 and rojas < 11:
		p.tarjeta_externa(p.once_local[0].id, true)
		rojas += 1
	_comprobar(p.terminado_ya and fin.size() == 1 and fin[0] == [0, 3], "con %d rojas el local se queda con %d y lo pierde 0-3 (%s)" % [rojas, p.once_local.size(), str(fin)])
	var p2 := Partido.new(par[0], par[1])
	p2.preparar()
	p2.goles_local = 5
	p2.goles_visita = 1
	for _k in 11:
		if p2.once_visita.size() < 7:
			break
		p2.tarjeta_externa(p2.once_visita[0].id, true)
	_comprobar(p2.terminado_ya and p2.goles_local == 5 and p2.goles_visita == 1, "si el rival ya ganaba por más, se queda el marcador (%d-%d)" % [p2.goles_local, p2.goles_visita])
	## 4) Gol en el descuento del 3D: la crónica lo dice «90+3'».
	var p3 := Partido.new(par[0], par[1])
	p3.preparar()
	p3.minuto = 90
	p3.gol_externo(true, p3.once_local[9].id, "", 3)
	p3.gol_externo(false, p3.once_visita[9].id, "")
	_comprobar(Partido.texto_minuto(p3.cronica[-2]) == "90+3'" and Partido.texto_minuto(p3.cronica[-1]) == "90'", "el gol del descuento se lee «%s» y el otro «%s»" % [Partido.texto_minuto(p3.cronica[-2]), Partido.texto_minuto(p3.cronica[-1])])
	## Los libres cumplen años al cambiar de temporada (como los de un club).
	if m.libres.is_empty():
		m.libres.append(m.ligas[0].clubes[2].plantilla.pop_back())
	var j: Jugador = m.libres[0]
	var edad := j.edad
	m.nueva_temporada()
	_comprobar(j.edad == edad + 1, "un jugador libre cumple años con la temporada (%d → %d)" % [edad, j.edad])
