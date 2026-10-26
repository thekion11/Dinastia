extends BaseIdea
## pmov (26-10-2026): EL METRO DICE LA VERDAD. Lo que se lee en el andén
## («próximo tren: N s») y en el vagón («próxima: X») tiene que cumplirse: se
## simula la línea de verdad (`MetroCiudad.Tren`, 7 estaciones, 3 trenes como en
## `MetroCiudad.montar`) y se compara con lo anunciado. Antes: error medio 24 %, peor 20 s; la próxima en la cabecera era la otra punta.

const DT := 0.1

func _probar() -> void:
	_titulo("PMOV: METRO — ESPERAS Y PRÓXIMA ESTACIÓN CREÍBLES")
	_eta_contra_reloj()
	_proxima_en_cabecera()
	_viaje_lleva_donde_dice()

## Una línea como las del juego: 22 celdas, estaciones en -9..9 de 3 en 3.
func _linea_metro() -> Dictionary:
	var cel := CiudadExpansion.CELDA
	var largo := 22.0 * cel
	var est := PackedFloat32Array()
	for k in [-9, -6, -3, 0, 3, 6, 9]:
		est.append((float(k) + 11.0) * cel)
	var trenes: Array = []
	for k in 3:
		trenes.append(MetroCiudad.Tren.new(largo, est, largo * (float(k) + 0.5) / 3.0, 1.0 if k % 2 == 0 else -1.0))
	return {"nombre": "Línea 1", "est_s": est, "trenes": trenes, "largo": largo}

## Segundos hasta que un tren para (puertas abiertas) en la estación `i`.
func _llegada_real(l: Dictionary, i: int) -> float:
	var s := float(l["est_s"][i])
	var t := 0.0
	while t < 1500.0:
		for tr: MetroCiudad.Tren in l["trenes"]:
			if tr.espera > 0.0 and absf(tr.s - s) < 1.0:
				return t
		for tr: MetroCiudad.Tren in l["trenes"]:
			tr.simular(DT)
		t += DT
	return INF

## En varios momentos del servicio y en todas las estaciones, la espera anunciada
## se parece a la real: error medio < 20 % y ninguno > 10 s.
func _eta_contra_reloj() -> void:
	var peor := 0.0
	var suma_rel := 0.0
	var n := 0
	var l := _linea_metro()
	for momento in 8:
		for i in 7:
			var m := MetroCiudad.new()
			m.lineas = [_copia(l)]
			var anunciada := m.eta_minima("Línea 1", i)
			var real := _llegada_real(m.lineas[0], i)
			m.free()
			if real < 1.0:
				continue   ## ya hay un tren parado: «llegando»
			peor = maxf(peor, absf(anunciada - real))
			suma_rel += absf(anunciada - real) / real
			n += 1
		## Avanza el servicio 45 s para el siguiente momento.
		for k in 450:
			for tr: MetroCiudad.Tren in l["trenes"]:
				tr.simular(DT)
	var medio := suma_rel / maxf(1.0, float(n))
	_comprobar(medio < 0.2, "la espera anunciada en el andén se cumple (error medio %.0f %% en %d casos)" % [medio * 100.0, n])
	_comprobar(peor < 10.0, "y nunca se equivoca en más de 10 s (peor %.0f s; antes, 20 s)" % peor)

func _copia(l: Dictionary) -> Dictionary:
	var c := l.duplicate()
	var tr: Array = []
	for t: MetroCiudad.Tren in l["trenes"]:
		var u := MetroCiudad.Tren.new(t.largo, t.estaciones, t.s, t.sentido)
		u.v = t.v
		u.espera = t.espera
		u.ultima_parada = t.ultima_parada
		tr.append(u)
	c["trenes"] = tr
	return c

## En la cabecera (última estación), la próxima es la de al lado, no la otra punta.
func _proxima_en_cabecera() -> void:
	var l := _linea_metro()
	var est: PackedFloat32Array = l["est_s"]
	var t := MetroCiudad.Tren.new(float(l["largo"]), est, est[6], 1.0)
	t.espera = 5.0
	t.ultima_parada = est[6]
	l["trenes"] = [t]
	var m := MetroCiudad.new()
	m.lineas = [l]
	var nombres: Array = MetroCiudad.NOMBRES["Línea 1"]
	_comprobar(m.proxima_de("Línea 1", 0) == String(nombres[5]),
		"parado en la cabecera «%s», la próxima es «%s» (dice «%s»)" % [nombres[6], nombres[5], m.proxima_de("Línea 1", 0)])
	t.s = est[0]
	t.sentido = -1.0
	t.ultima_parada = est[0]
	_comprobar(m.proxima_de("Línea 1", 0) == String(nombres[1]),
		"y en la otra cabecera, «%s» (dice «%s»)" % [nombres[1], m.proxima_de("Línea 1", 0)])
	m.free()

## Lo que anuncia el vagón en marcha es donde para de verdad, en toda la línea (ida y vuelta).
func _viaje_lleva_donde_dice() -> void:
	var l := _linea_metro()
	var t: MetroCiudad.Tren = l["trenes"][0]
	l["trenes"] = [t]
	var m := MetroCiudad.new()
	m.lineas = [l]
	var mal := 0
	var paradas := 0
	var anunciada := ""
	var en_marcha := false
	for i in 12000:
		t.simular(DT)
		var parada := m.estacion_del_tren("Línea 1", 0)
		if parada < 0:
			anunciada = m.proxima_de("Línea 1", 0)
			en_marcha = true
		elif en_marcha:
			en_marcha = false
			paradas += 1
			if String(MetroCiudad.NOMBRES["Línea 1"][parada]) != anunciada:
				mal += 1
	_comprobar(paradas >= 12 and mal == 0, "el tren para donde anunciaba en %d de %d paradas" % [paradas - mal, paradas])
	m.free()
