extends BaseIdea
## MEDICIÓN DE LA ECONOMÍA (paquete eco, 25-10-2026). Simula varias temporadas con varias semillas, una vez
## al mando del club más GRANDE de la Primera chilena y otra del más CHICO, sin que el humano toque nada
## (el peor caso para M-208: si la caja crece sola sin gestionar, crece siempre). Saca curvas por temporada:
## caja propia, reputación, división; valor medio del mercado (burbujas, M-210); y del resto del mundo cuántos
## clubes de la IA están en rojo o rescatados. ECO_TEMP / ECO_SEMILLAS para cambiarla.

func _probar() -> void:
	var temporadas := int(OS.get_environment("ECO_TEMP")) if OS.get_environment("ECO_TEMP") != "" else 3
	var semillas: Array = [101]
	if OS.get_environment("ECO_SEMILLAS") != "":
		semillas = Array(OS.get_environment("ECO_SEMILLAS").split(",")).map(func(x: String) -> int: return int(x))
	_titulo("ECONOMÍA: %d temporadas x %d semillas x (grande, chico)" % [temporadas, semillas.size()])
	for s: int in semillas:
		for grande: bool in ([true] if OS.get_environment("ECO_SOLO") == "grande" else [true, false]):
			_una(int(s), temporadas, grande)

func _una(semilla: int, temporadas: int, grande: bool) -> void:
	var m := Mundo.new()
	m.generar(["CHI"], semilla)
	var primera: Array = m.ligas[0].clubes.duplicate()
	primera.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
	var yo: Club = primera[0] if grande else primera[primera.size() - 1]
	m.tomar_el_mando(yo.id)
	var et := "semilla %d, %s (%s, rep %d)" % [semilla, "GRANDE" if grande else "CHICO", yo.nombre, yo.rep]
	_linea("")
	_linea("--- %s ---" % et)
	var cajas: Array[int] = [yo.saldo]
	var valores: Array[float] = [_valor_medio(m)]
	var max_rojo := 0
	var sube := 0
	_linea("  t0  caja %8.2f M  ref %6.2f M  valor medio %7.0f" % [yo.saldo / 1e6, Eco.ref_caja(yo.rep) / 1e6, valores[0]])
	_linea("      " + _foto(m))
	for t in temporadas:
		var rojo_min := yo.saldo
		## Se avanza semana a semana para ver el banco en la temporada (no solo la foto final).
		while m.temporada_en_curso():
			m.avanzar_semana()
			if m.banco != null:
				max_rojo = maxi(max_rojo, m.banco.semanas_en_rojo)
			rojo_min = mini(rojo_min, yo.saldo)
		m.jugar_temporada()
		m.nueva_temporada()
		var ia_rojo := 0
		for c: Club in m.clubes.values():
			if c.id != yo.id and c.saldo < 0:
				ia_rojo += 1
		cajas.append(yo.saldo)
		valores.append(_valor_medio(m))
		_linea("      " + _foto(m))
		if cajas[-1] > cajas[-2]:
			sube += 1
		_linea("  t%d  caja %8.2f M  (mín %7.2f)  ref %6.2f M  rep %d  div %d  valor medio %7.0f  IA en rojo %d  masa %d" % [
			t + 1, yo.saldo / 1e6, rojo_min / 1e6, Eco.ref_caja(yo.rep) / 1e6, yo.rep, yo.division, valores[-1], ia_rojo, yo.masa_salarial()])
	## Los más caros del mundo al final: dice de dónde sale la subida del valor medio.
	var todos: Array = m.jugadores()
	todos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.valor > b.valor)
	for j: Jugador in todos.slice(0, 5):
		var esperado := Eco.VALOR_PIVOTE * pow(Eco.CURVA_JUG, float(j.ovr) - Eco.OVR_PIVOTE) * Eco.factor_edad(j.edad, j.ovr, j.pot)
		_linea("      top: %s ovr %d pot %d edad %d valor %d (x%.2f de su tasación) sueldo %d" % [j.nombre, j.ovr, j.pot, j.edad, j.valor, float(j.valor) / maxf(1.0, esperado), j.sueldo])
	_linea("  temporadas con la caja al alza: %d/%d · peor racha en rojo: %d semanas" % [sube, temporadas, max_rojo])
	## M-208: sin gestionar, la caja del grande no puede crecer más de 3/4 de su referencia por temporada
	## (con el 42% plano crecía 1,15 referencias por año: 6,6 M → 18,9 M en dos temporadas).
	var crece := float(cajas[-1] - cajas[0]) / float(temporadas)
	if grande:
		_comprobar(crece < Eco.ref_caja(yo.rep) * 0.75, "%s: la caja no se dispara sola (%.2f M/temporada)" % [et, crece / 1e6])
	## M-210, precios coherentes: lo que cuesta un jugador es lo que dice su tasación (media, edad, techo). El
	## valor MEDIO sí sube: lo arrastra la cola de estrellas jóvenes de la cantera, no el precio.
	var ratios: Array[float] = []
	for j in m.jugadores():
		ratios.append(float(j.valor) / maxf(1.0, Eco.VALOR_PIVOTE * pow(Eco.CURVA_JUG, float(j.ovr) - Eco.OVR_PIVOTE) * Eco.factor_edad(j.edad, j.ovr, j.pot)))
	ratios.sort()
	var med := ratios[ratios.size() / 2]
	_comprobar(med > 0.8 and med < 1.2, "%s: precios pegados a la tasación (mediana x%.2f; valor medio x%.2f)" % [et, med, valores[-1] / maxf(valores[0], 1.0)])

func _valor_medio(m: Mundo) -> float:
	var tot := 0.0
	var n := 0
	for j in m.jugadores():
		tot += float(j.valor)
		n += 1
	return tot / maxf(1.0, float(n))

## Media de OVR, mediana del valor, edad media y cuántos están en su último año: para separar si el valor sube
## porque suben las medias (desarrollo, fuera de esta zona) o porque cambia la tasación.
func _foto(m: Mundo) -> String:
	var ovr := 0.0
	var edad := 0.0
	var ultimo := 0
	var caros := 0
	var sueldo := 0.0
	var baratos := 0
	var vals: Array[int] = []
	for j in m.jugadores():
		ovr += j.ovr
		sueldo += j.sueldo
		edad += j.edad
		vals.append(j.valor)
		var esperado := Eco.VALOR_PIVOTE * pow(Eco.CURVA_JUG, float(j.ovr) - Eco.OVR_PIVOTE) * Eco.factor_edad(j.edad, j.ovr, j.pot)
		var r := float(j.valor) / maxf(esperado, 1.0)
		if r > 1.5:
			caros += 1
		elif r < 0.6:
			baratos += 1
		if j.anios_contrato <= 1:
			ultimo += 1
	vals.sort()
	var n := maxf(1.0, float(vals.size()))
	return "sueldo medio %.0f · " % (sueldo / maxf(1.0, float(vals.size()))) + "ovr %.1f edad %.1f mediana %d último año %d%% n %d · tasación vieja: %d%% por encima x1.5, %d%% por debajo x0.6" % [ovr / n, edad / n, vals[vals.size() / 2], int(100.0 * ultimo / n), vals.size(), int(100.0 * caros / n), int(100.0 * baratos / n)]
