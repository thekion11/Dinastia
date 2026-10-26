extends BaseIdea
## ESTABILIDAD DE LA PIRÁMIDE DE EDADES (paquete cant, 25-10-2026). Cinco temporadas sin tocar nada y se mira
## que el mundo no se rejuvenezca ni se llene de cracks precoces: en el fútbol real los 85+ con menos de 22
## años se cuentan con los dedos. Antes del ajuste, en tres temporadas salían una docena de 84-87 con 19-23
## años, la edad media bajaba de 26,9 a 25,8 y el valor medio se multiplicaba por 1,8 con la media plana.
## CANT_TEMP / CANT_SEMILLA para cambiarla.

func _probar() -> void:
	var temporadas := int(OS.get_environment("CANT_TEMP")) if OS.get_environment("CANT_TEMP") != "" else 5
	var semilla := int(OS.get_environment("CANT_SEMILLA")) if OS.get_environment("CANT_SEMILLA") != "" else 101
	_titulo("CANTERA: estabilidad de OVR por edad en %d temporadas (semilla %d)" % [temporadas, semilla])
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	var primera: Array = m.ligas[0].clubes.duplicate()
	primera.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	m.tomar_el_mando(primera[0].id)
	var f0 := _foto(m)
	_linea("  t0  " + _texto(f0))
	var fotos: Array[Dictionary] = [f0]
	for t in temporadas:
		m.jugar_temporada()
		m.nueva_temporada()
		fotos.append(_foto(m))
		_linea("  t%d  " % (t + 1) + _texto(fotos[-1]))
	var fin: Dictionary = fotos[-1]
	_comprobar(absf(fin["edad"] - f0["edad"]) <= 0.6, "la edad media se sostiene (%.1f → %.1f)" % [f0["edad"], fin["edad"]])
	_comprobar(absf(fin["ovr"] - f0["ovr"]) <= 1.5, "la media OVR se sostiene (%.1f → %.1f)" % [f0["ovr"], fin["ovr"]])
	var tope_precoces := maxi(2, int(f0["precoces"]) + 1)
	for i in fotos.size():
		_comprobar(int(fotos[i]["precoces"]) <= tope_precoces, "t%d: 85+ con menos de 22 años: %d (tope %d)" % [i, fotos[i]["precoces"], tope_precoces])
	_comprobar(int(fin["jovenes_80"]) <= maxi(4, int(f0["jovenes_80"]) * 2), "80+ con menos de 23 en la IA no se disparan (%d → %d)" % [f0["jovenes_80"], fin["jovenes_80"]])
	## La forma de la curva: los de 19-21 por debajo de los de 25-29 (es la edad en que se llega al techo).
	_comprobar(fin["m_jov"] < fin["m_pico"], "los jóvenes siguen por debajo del pico (%.1f < %.1f)" % [fin["m_jov"], fin["m_pico"]])
	_comprobar(absf(fin["m_pico"] - f0["m_pico"]) <= 2.5, "la media del pico (25-29) estable (%.1f → %.1f)" % [f0["m_pico"], fin["m_pico"]])
	## El valor se mide en el mundo de la IA: tu club sin gestionar no renueva a nadie y en cinco años es una
	## plantilla entera de canteranos (es lo que pasa si no tocas nada, no un fallo de la curva).
	var v := float(fin["sin_mio"]) / maxf(1.0, float(f0["sin_mio"]))
	_comprobar(v < 1.4, "el valor medio de la IA no se infla con la media plana (x%.2f; con tu club x%.2f)" % [v, float(fin["valor"]) / maxf(1.0, float(f0["valor"]))])
	_comprobar(float(fin["sd"]) - float(f0["sd"]) <= 1.5, "la dispersión de medias no se abre (sd %.1f → %.1f)" % [f0["sd"], fin["sd"]])

func _foto(m: Mundo) -> Dictionary:
	var n := 0
	var ovr := 0.0
	var edad := 0.0
	var valor := 0.0
	var tasado := 0.0
	var mio := 0.0
	var nmio := 0
	var precoces := 0
	var jov80 := 0
	var sj := 0.0
	var nj := 0
	var sp := 0.0
	var np := 0
	var ovrs: Array[int] = []
	for j: Jugador in m.jugadores():
		ovrs.append(j.ovr)
		n += 1
		ovr += j.ovr
		edad += j.edad
		valor += j.valor
		if j.club_id == m.mi_club_id:
			mio += j.valor
			nmio += 1
		tasado += Eco.VALOR_PIVOTE * pow(Eco.CURVA_JUG, float(j.ovr) - Eco.OVR_PIVOTE) * Eco.factor_edad(j.edad, j.ovr, j.pot)
		if j.edad < 22 and j.ovr >= 85:
			precoces += 1
		if j.edad < 23 and j.ovr >= 80 and j.club_id != m.mi_club_id:
			jov80 += 1
		if j.edad >= 19 and j.edad <= 21:
			sj += j.ovr
			nj += 1
		elif j.edad >= 25 and j.edad <= 29:
			sp += j.ovr
			np += 1
	var k := maxf(1.0, float(n))
	ovrs.sort()
	var var_ := 0.0
	for o in ovrs:
		var_ += pow(float(o) - ovr / k, 2.0)
	return {"n": n, "p95": ovrs[int(ovrs.size() * 0.95)], "p10": ovrs[int(ovrs.size() * 0.10)], "sd": sqrt(var_ / k), "ovr": ovr / k, "edad": edad / k, "valor": valor / k, "sin_mio": (valor - mio) / maxf(1.0, k - nmio), "nmio": nmio, "tasado": tasado / k, "precoces": precoces, "jovenes_80": jov80,
		"m_jov": sj / maxf(1.0, float(nj)), "m_pico": sp / maxf(1.0, float(np))}

func _texto(f: Dictionary) -> String:
	return "n %d · ovr %.1f (p10 %d, p95 %d, sd %.1f) · edad %.1f · valor medio %.0f (tasación %.0f; sin tu club %.0f, tu plantel %d) · 85+ <22: %d · 80+ <23 (IA): %d · media 19-21 %.1f · 25-29 %.1f" % [
		f["n"], f["ovr"], f["p10"], f["p95"], f["sd"], f["edad"], f["valor"], f["tasado"], f["sin_mio"], f["nmio"], f["precoces"], f["jovenes_80"], f["m_jov"], f["m_pico"]]
