extends BaseIdea
## MERCADO Y CONTRATOS (25-10-2026, paquete mc). Dos fallos medidos con eco_medicion:
##   1. `mercado.ofertas_recibidas` no caducaba: una oferta sin responder seguía viva temporadas después.
##   2. La IA solo renovaba al llegar a cero y por 1-3 años: el % de jugadores del mundo en su último año
##      pasaba del 25% al 60% en tres temporadas.

func _probar() -> void:
	_titulo("MERCADO Y CONTRATOS (mc)")
	_ofertas()
	_renovaciones()

func _ofertas() -> void:
	var m := _mundo(4401)
	var mio := m.mi_club()
	var ahora := m.anio * 60 + m.semana
	var rival: Club = m.ligas[0].clubes[1]
	var vieja := {"jugador": mio.plantilla[0], "club": rival, "monto": 1000, "semana": m.semana,
		"abs": ahora - MercadoAvanzado.CADUCA_SEMANAS, "clausula": false}
	var nueva := {"jugador": mio.plantilla[1], "club": rival, "monto": 2000, "semana": m.semana,
		"abs": ahora - 1, "clausula": false}
	var ajeno: Jugador = rival.plantilla[0]
	var de_otro := {"jugador": ajeno, "club": rival, "monto": 3000, "semana": m.semana, "abs": ahora, "clausula": false}
	m.mercado.ofertas_recibidas.assign([vieja, nueva, de_otro])
	var avisos: Array[String] = []
	m.mercado_av.noticia.connect(func(t: String, _c: String) -> void: avisos.append(t))
	var caidas := m.mercado_av.caducar_ofertas(m)
	_comprobar(caidas == 2, "caen la oferta vieja y la de un jugador que no es tuyo (%d)" % caidas)
	_comprobar(m.mercado.ofertas_recibidas.size() == 1 and m.mercado.ofertas_recibidas[0]["jugador"] == mio.plantilla[1],
		"la oferta reciente sigue en pie")
	_comprobar(avisos.size() == 1 and avisos[0].contains(mio.plantilla[0].nombre), "se avisa de la oferta retirada (y solo de esa)")
	## La edad de la oferta sobrevive al guardado.
	var d := m.mercado.a_dic()
	m.mercado.desde_dic(d)
	_comprobar(int(m.mercado.ofertas_recibidas[0].get("abs", -1)) == ahora - 1, "la fecha de la oferta se guarda y se carga")
	## Y en la simulación real: diez semanas, ninguna oferta más vieja que el plazo.
	var maxima := 0
	for i in 10:
		m.avanzar_semana()
		var a := m.anio * 60 + m.semana
		for o: Dictionary in m.mercado.ofertas_recibidas:
			maxima = maxi(maxima, a - int(o["abs"]))
	_comprobar(maxima <= MercadoAvanzado.CADUCA_SEMANAS, "en 10 semanas ninguna oferta pasa de %d semanas (máx %d)" % [
		MercadoAvanzado.CADUCA_SEMANAS, maxima])

func _renovaciones() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 101)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var inicial := _ultimo_anio(m)
	## Informativo (la nómina del humano, ver informe mc): cuánto de la subida es por tasar() de nuevo el sueldo.
	var firmado := {}
	for j: Jugador in m.mi_club().plantilla:
		firmado[j.id] = j.sueldo
	var masa0 := m.mi_club().masa_salarial()
	for t in 2:
		while m.temporada_en_curso():
			m.avanzar_semana()
		m.nueva_temporada()
		var p := _ultimo_anio(m)
		_linea("  temporada %d: %d%% del mundo en su último año (al empezar %d%%)" % [t + 1, p, inicial])
		var fija := 0
		var sigue := 0
		for j: Jugador in m.mi_club().plantilla:
			fija += int(firmado.get(j.id, j.sueldo))
			sigue += 1 if firmado.has(j.id) else 0
			if not firmado.has(j.id) and OS.get_environment("MC_DET") != "":
				_linea("    nuevo %s edad %d ovr %d sueldo %d anios %d form %s" % [j.nombre, j.edad, j.ovr, j.sueldo, j.anios_contrato, j.club_formacion])
		_linea("  nómina tuya: %d → %d (con los sueldos firmados: %d; %d de %d siguen)" % [masa0, m.mi_club().masa_salarial(),
			fija, sigue, m.mi_club().plantilla.size()])
		_comprobar(p <= 35, "temporada %d: el último año no se dispara (%d%% ≤ 35%%)" % [t + 1, p])

func _ultimo_anio(m: Mundo) -> int:
	var n := 0
	var u := 0
	for c: Club in m.clubes.values():
		if c.id == m.mi_club_id:
			continue
		for j: Jugador in c.plantilla:
			n += 1
			if j.anios_contrato <= 1:
				u += 1
	return int(100.0 * u / maxf(1.0, n))
