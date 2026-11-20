extends Node
## El núcleo del avance por días (paso 3): se detiene en el primer día con eventos, recorre una temporada entera sin saltarse ningún partido ni repetir
## un aviso, y termina. Cuatro mundos distintos (no siempre el mismo club ni país).

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func correr(padre: Node = null) -> int:
	var p := padre
	for cfg: Array in [[["CHI"], 11], [["ARG", "BRA"], 22], [["ESP", "ENG"], 33], [["GER", "ITA", "FRA"], 44]]:
		var m := Mundo.new()
		var ps: Array[String] = []
		for c in cfg[0]:
			ps.append(String(c))
		m.generar(ps, int(cfg[1]))
		m.tomar_el_mando(m.ligas[0].clubes[1 + int(cfg[1]) % 3].id)
		_temporada(m, "%s/%d" % [",".join(cfg[0]), cfg[1]])
	return fallos

func _ready() -> void:
	correr(self)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

func _temporada(m: Mundo, e: String) -> void:
	var est := DisparadoresDia.nuevo_estado()
	var rodar := func() -> void: m.avanzar_semana()
	var dia := 0
	var uno := AvanceDias.avanzar(m, est, 0, rodar, true)   ## «Avanzar 1 día» del desplegable: se detiene tras UN día, haya o no eventos
	_ok((uno["pasados"] as Array).size() == 1 and int(uno["dia"]) == 1 and not bool(uno["fin"]), "%s: «Avanzar 1 día» avanza exactamente un día" % e)
	dia = int(uno["dia"])
	var paradas := 0
	var partidos := 0
	var jornada0 := m.liga_de(m.mi_club()).jornada_actual
	var ids := {}
	var fin := false
	var guardia := 0
	while not fin and guardia < 400:
		guardia += 1
		var semana_antes := m.semana
		var r := AvanceDias.avanzar(m, est, dia, rodar)
		var pasados: Array = r["pasados"]
		_ok(not pasados.is_empty(), "%s: siempre se recorre al menos un día" % e)
		for p: Dictionary in pasados:
			_ok(int(p["mes"]) >= 1 and int(p["mes"]) <= 12 and int(p["dia_mes"]) >= 1 and int(p["dia_mes"]) <= 31, "%s: fecha válida" % e)
		if bool(r["fin"]):
			fin = true
			break
		_ok(not (r["eventos"] as Array).is_empty(), "%s: la parada tiene eventos" % e)
		_ok(int(r["dia"]) >= 0 and int(r["dia"]) <= 6, "%s: el día de la parada es de la semana" % e)
		_ok(m.semana >= semana_antes, "%s: el tiempo no retrocede" % e)
		paradas += 1
		for ev: Dictionary in r["eventos"]:
			if String(ev.get("origen", "")) == EventosDia.ORIGEN_DISPARADOR:
				_ok(not ids.has(String(ev["id"])), "%s: el disparador %s sale una sola vez" % [e, ev["id"]])
				ids[String(ev["id"])] = true
		if not (r["plan"] as Dictionary)["partido"].is_empty():
			partidos += 1
			var j0 := m.liga_de(m.mi_club()).jornada_actual
			rodar.call()   ## el partido del día se juega con la semana
			_ok(m.liga_de(m.mi_club()).jornada_actual > j0 or not m.temporada_en_curso(), "%s: tras la parada de partido la jornada corre" % e)
			dia = -1   ## la semana ya corrió con el partido: el siguiente avance empieza mirando el lunes
		else:
			dia = int(r["dia"])
	_ok(fin, "%s: la temporada termina" % e)
	var jugadas := m.liga_de(m.mi_club()).jornada_actual - jornada0
	_ok(partidos >= jugadas * 3 / 4 and partidos > 0, "%s: no se saltó partidos (paradas de partido %d, jornadas %d)" % [e, partidos, jugadas])
	_ok(paradas > partidos, "%s: hubo paradas que no son partido (%d de %d)" % [e, partidos, paradas])
