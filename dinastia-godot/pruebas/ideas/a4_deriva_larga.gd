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
	var quien := OS.get_environment("DERIVA_CLUB")   ## "ultimo" = el más chico de la primera liga; por defecto, el primero de la lista
	var lista: Array = m.ligas[0].clubes
	m.tomar_el_mando((lista[lista.size() - 1] if quien == "ultimo" else lista[0]).id)
	_linea("  al mando: %s (rep %d)" % [m.mi_club().nombre, m.mi_club().rep])
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
				camp[l.nombre] = ("%s(%d)" % [(cl as Club).nombre, (cl as Club).rep]) if cl is Club else str(cl)
		campeones.append(camp)
		if m.directiva != null and m.directiva.despedido_ya:
			m.directiva.despedido_ya = false
			m.directiva.confianza = 60
		m.nueva_temporada()
		_fotos.append(_foto(m, gpp, Time.get_ticks_msec() - t0))
		if OS.get_environment("DERIVA_DETALLE") != "" and (t + 1) % 3 == 0:
			_detalle(m, t + 1)
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
	var por_div := {}   ## división → [suma de valoraciones, jugadores]
	for l: Liga in m.ligas:
		var d := l.division()
		for c: Club in l.clubes:
			for j: Jugador in c.plantilla:
				var a: Array = por_div.get(d, [0, 0])
				a[0] += j.ovr
				a[1] += 1
				por_div[d] = a
	var ovr_div := {}
	for d in por_div:
		ovr_div[d] = float((por_div[d] as Array)[0]) / maxf(1.0, float((por_div[d] as Array)[1]))
	cajas.sort()
	var kb := 0
	if ms > 0 and (m.anio % 5 == 0 or true):
		kb = JSON.stringify(Partida.instantanea(m)).length() / 1024
	return {"n": n, "libres": m.libres.size(), "edad": edad / maxf(1.0, n), "ovr": ovr / maxf(1.0, n), "top": top, "val": val_ia / maxf(1.0, n_ia), "sal": sal_ia / maxf(1.0, n_ia),
		"caja_med": cajas[cajas.size() / 2] if not cajas.is_empty() else 0, "rojos": rojos, "clubes": m.clubes.size(), "pmin": pmin, "pmax": pmax, "cortos": cortos,
		"gpp": gpp, "kb": kb, "ms": ms, "ovr_div": ovr_div}

func _texto(f: Dictionary, t: int) -> String:
	return "  t%-2d jug %d libres %d edad %.1f ovr %.1f 85+ %d | valor IA %.0f sueldo IA %.0f | caja mediana IA %.1f M, en rojo %d/%d | plantel %d-%d (cortos %d) | ovr por división %s | goles %.2f | guardado %d KB | %d ms" % [
		t, f["n"], f["libres"], f["edad"], f["ovr"], f["top"], f["val"], f["sal"], float(f["caja_med"]) / 1e6, f["rojos"], f["clubes"], f["pmin"], f["pmax"], f["cortos"], _div_txt(f["ovr_div"]), f["gpp"], f["kb"], f["ms"]]

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
		var secuencia: Array[String] = []
		for c in campeones:
			secuencia.append(String(c.get(liga, "-")))
		_linea("  campeones de %s por temporada: %s" % [liga, ", ".join(secuencia)])
		for i in range(desde, campeones.size()):
			vistos[String(campeones[i].get(liga, ""))] = true
		_linea("  campeones distintos en %s (últimas %d): %d" % [liga, campeones.size() - desde, vistos.size()])
		## DOMINIO (A4-GESTION-010): se imprime, no se exige: el campeón repite hasta 26 años seguidos con la reputación en el tope (96) y está documentado como deuda de balance con su propuesta.

## Los 4 clubes de mayor reputación de la primera liga: reputación, caja, media de sus 14 mejores, sueldos y valor del plantel (para ver POR DÓNDE se hace la bola de nieve).
func _detalle(m: Mundo, t: int) -> void:
	var l: Liga = m.ligas[0]
	var cs: Array = l.clubes.duplicate()
	cs.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	var partes: Array[String] = []
	for c: Club in cs.slice(0, 4):
		var ovrs: Array[int] = []
		var nomina := 0
		for j: Jugador in c.plantilla:
			ovrs.append(j.ovr)
			nomina += j.sueldo
		ovrs.sort()
		ovrs.reverse()
		var top14 := 0.0
		for i in mini(14, ovrs.size()):
			top14 += ovrs[i]
		partes.append("%s rep %d caja %.1fM top14 %.1f nómina %.2fM" % [c.nombre.left(9), c.rep, float(c.saldo) / 1e6, top14 / 14.0, float(nomina) / 1e6])
	_linea("    t%d: %s" % [t, " | ".join(partes)])

func _div_txt(d: Dictionary) -> String:
	var ks := d.keys()
	ks.sort()
	var partes: Array[String] = []
	for k in ks:
		partes.append("D%d %.1f" % [int(k), float(d[k])])
	return " ".join(partes)
