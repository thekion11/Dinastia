extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5: DERIVAS DEL MUNDO A MUY LARGO PLAZO. Una corrida larga sin tocar nada (el humano solo se salva del despido) y una foto del mundo por temporada:
## edad y valoración medias, valor y sueldo medios de la IA, caja mediana de la IA y clubes en rojo, tamaños de plantel, libres, campeones distintos por liga, 85+, goles por partido,
## tamaño del guardado y tiempo de la temporada. Imprime la tabla cada 5 temporadas y comprueba las DERIVAS contra rangos anchos (lo que de verdad rompería el juego).
## DERIVA_TEMP (30), DERIVA_PAISES (CHI,ARG), DERIVA_SEMILLA (2026). Es una ESPECIAL larga (30 temporadas × 2 países ≈ varios minutos): `especiales.sh todo`.
var _fotos: Array[Dictionary] = []

func _probar() -> void:
	var temp := int(OS.get_environment("DERIVA_TEMP")) if OS.get_environment("DERIVA_TEMP") != "" else 30
	var paises: Array[String] = []
	for p in (OS.get_environment("DERIVA_PAISES") if OS.get_environment("DERIVA_PAISES") != "" else "CHI,ARG").split(","):
		paises.append(p)
	var semilla := int(OS.get_environment("DERIVA_SEMILLA")) if OS.get_environment("DERIVA_SEMILLA") != "" else 2026
	_titulo("A4 DERIVAS: %d temporadas, %s, semilla %d" % [temp, ",".join(paises), semilla])
	Partido.limpiar_contexto()
	var m := Mundo.new()
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var campeones: Array[Dictionary] = []   ## por temporada: id de liga → id del campeón
	_fotos.append(_foto(m, 0.0, 0))
	for t in temp:
		var t0 := Time.get_ticks_msec()
		m.jugar_temporada()
		var gpp := _goles(m)
		var camp := {}
		for l: Liga in m.ligas:
			var tb := l.tabla()
			if not tb.is_empty():
				var fila: Dictionary = tb[0]
				var cl: Variant = fila.get("club", fila.get("id", ""))
				camp[l.nombre] = (cl as Club).id if cl is Club else str(cl)
		campeones.append(camp)
		if m.directiva != null and m.directiva.despedido_ya:
			m.directiva.despedido_ya = false
			m.directiva.confianza = 60
		m.nueva_temporada()
		_fotos.append(_foto(m, gpp, Time.get_ticks_msec() - t0))
		if (t + 1) % 5 == 0:
			_linea(_texto(_fotos[t + 1], t + 1))
			await get_tree().process_frame
	_linea(_texto(_fotos[0], 0))
	_analizar(campeones, temp)

func _goles(m: Mundo) -> float:
	var gf := 0
	var pj := 0
	for l in m.ligas:
		for fila: Dictionary in l.tabla_puntos.values():
			gf += int(fila["gf"])
			pj += int(fila["pj"])
	return float(gf) / maxf(1.0, float(pj) / 2.0)

func _foto(m: Mundo, gpp: float, ms: int) -> Dictionary:
	var n := 0
	var edad := 0.0
	var ovr := 0.0
	var top := 0
	var val_ia := 0.0
	var sal_ia := 0.0
	var n_ia := 0
	var cajas: Array[int] = []
	var rojos := 0
	var pmin := 999
	var pmax := 0
	var cortos := 0
	for c: Club in m.clubes.values():
		pmin = mini(pmin, c.plantilla.size())
		pmax = maxi(pmax, c.plantilla.size())
		if c.plantilla.size() < 16:
			cortos += 1
		if c.id != m.mi_club_id:
			cajas.append(c.saldo)
			if c.saldo < 0:
				rojos += 1
		for j: Jugador in c.plantilla:
			n += 1
			edad += j.edad
			ovr += j.ovr
			if j.ovr >= 85:
				top += 1
			if c.id != m.mi_club_id:
				val_ia += j.valor
				sal_ia += j.sueldo
				n_ia += 1
	cajas.sort()
	var kb := 0
	if ms > 0 and (m.anio % 5 == 0 or true):
		kb = JSON.stringify(Partida.instantanea(m)).length() / 1024
	return {"n": n, "libres": m.libres.size(), "edad": edad / maxf(1.0, n), "ovr": ovr / maxf(1.0, n), "top": top, "val": val_ia / maxf(1.0, n_ia), "sal": sal_ia / maxf(1.0, n_ia),
		"caja_med": cajas[cajas.size() / 2] if not cajas.is_empty() else 0, "rojos": rojos, "clubes": m.clubes.size(), "pmin": pmin, "pmax": pmax, "cortos": cortos,
		"gpp": gpp, "kb": kb, "ms": ms}

func _texto(f: Dictionary, t: int) -> String:
	return "  t%-2d jug %d libres %d edad %.1f ovr %.1f 85+ %d | valor IA %.0f sueldo IA %.0f | caja mediana IA %.1f M, en rojo %d/%d | plantel %d-%d (cortos %d) | goles %.2f | guardado %d KB | %d ms" % [
		t, f["n"], f["libres"], f["edad"], f["ovr"], f["top"], f["val"], f["sal"], float(f["caja_med"]) / 1e6, f["rojos"], f["clubes"], f["pmin"], f["pmax"], f["cortos"], f["gpp"], f["kb"], f["ms"]]

func _analizar(campeones: Array[Dictionary], temp: int) -> void:
	var f0: Dictionary = _fotos[0]
	var fn: Dictionary = _fotos[_fotos.size() - 1]
	var v := float(fn["val"]) / float(f0["val"])
	var s := float(fn["sal"]) / float(f0["sal"])
	_linea("  DERIVA t%d/t0: valor IA ×%.2f, sueldo IA ×%.2f, ovr %+.1f, edad %+.1f, libres %d → %d, guardado %d → %d KB" % [temp, v, s, float(fn["ovr"]) - float(f0["ovr"]), float(fn["edad"]) - float(f0["edad"]), f0["libres"], fn["libres"], _fotos[1]["kb"], fn["kb"]])
	_comprobar(absf(float(fn["ovr"]) - float(f0["ovr"])) <= 3.0, "la valoración media no deriva más de 3 puntos en %d temporadas (%+.1f)" % [temp, float(fn["ovr"]) - float(f0["ovr"])])
	_comprobar(float(fn["edad"]) >= 25.0 and float(fn["edad"]) <= 28.5, "la edad media sigue entre 25,0 y 28,5 (%.1f)" % float(fn["edad"]))
	_comprobar(v >= 0.6 and v <= 2.5, "el valor medio de la IA no se dispara ni se hunde (×%.2f, rango 0,6-2,5)" % v)
	_comprobar(s >= 0.6 and s <= 3.0, "el sueldo medio de la IA no se dispara (×%.2f, rango 0,6-3,0)" % s)
	_comprobar(int(fn["rojos"]) <= int(float(fn["clubes"]) * 0.25), "pocos clubes de la IA en rojo (%d de %d)" % [fn["rojos"], fn["clubes"]])
	_comprobar(float(fn["caja_med"]) > -2000000.0, "la caja mediana de la IA no se hunde (%.1f M)" % (float(fn["caja_med"]) / 1e6))
	_comprobar(int(fn["cortos"]) == 0 and int(fn["pmin"]) >= 14, "ningún club con plantel corto al final (mínimo %d)" % fn["pmin"])
	_comprobar(int(fn["pmax"]) <= 45, "ningún plantel desbordado (máximo %d)" % fn["pmax"])
	_comprobar(int(fn["libres"]) <= int(f0["libres"]) * 3 + 200, "los libres no se acumulan sin fin (%d → %d)" % [f0["libres"], fn["libres"]])
	_comprobar(int(fn["top"]) <= maxi(40, int(f0["top"]) * 3), "los 85+ no se disparan (%d → %d)" % [f0["top"], fn["top"]])
	_comprobar(float(fn["kb"]) <= float(_fotos[1]["kb"]) * 4.0, "el guardado no crece sin control (%d → %d KB, ≤ ×4)" % [_fotos[1]["kb"], fn["kb"]])
	var gmal := 0
	for i in range(1, _fotos.size()):
		if float(_fotos[i]["gpp"]) < 2.0 or float(_fotos[i]["gpp"]) > 3.4:
			gmal += 1
	_comprobar(gmal <= maxi(1, temp / 15), "goles por partido en 2,0-3,4 casi siempre (%d temporadas fuera)" % gmal)
	## campeones distintos por liga en las últimas 15 temporadas
	var nombres := {}
	for c in campeones:
		for k in c:
			nombres[k] = true
	for liga: String in nombres:
		var vistos := {}
		var desde := maxi(0, campeones.size() - 15)
		for i in range(desde, campeones.size()):
			vistos[String(campeones[i].get(liga, ""))] = true
		_linea("  campeones distintos en %s (últimas %d): %d" % [liga, campeones.size() - desde, vistos.size()])
		_comprobar(vistos.size() >= 2 or campeones.size() < 8, "la liga «%s» no la gana siempre el mismo (%d campeones distintos en las últimas %d)" % [liga, vistos.size(), campeones.size() - desde])
