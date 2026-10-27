extends BaseIdea
## PRECONTRATOS (27-10-2026, M-217): firmar en el último semestre con un jugador en su último año; llega gratis al cambio de temporada.

func _probar() -> void:
	_titulo("MERCADO · PRECONTRATOS")
	var m := Mundo.new()
	m.generar(["CHI"], 83)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	var otro: Club = m.ligas[0].clubes[1]
	var j: Jugador = otro.plantilla[0]
	j.anios_contrato = 3
	_comprobar(Precontratos.motivo(m, j) != "", "con más de un año de contrato no hay precontrato")
	j.anios_contrato = 1
	m.semana = 5
	_comprobar(Precontratos.motivo(m, j).contains("19"), "antes de la semana 19 tampoco: %s" % Precontratos.motivo(m, j))
	m.semana = Precontratos.SEMANA_DESDE
	_comprobar(Precontratos.motivo(m, mio.plantilla[0]) != "", "y no con los tuyos")
	_comprobar(Precontratos.motivo(m, j) == "", "en su último año y último semestre se puede")
	## Intentos hasta que firme (depende de sus ganas): con el mundo sembrado acaba firmando.
	var r := "x"
	var intentos := 0
	while r != "" and intentos < 40:
		r = Precontratos.firmar(m, j)
		if r != "":
			m.mercado.precontratos.clear()
			j.pide_salir = true   ## con más ganas de salir
		intentos += 1
	_comprobar(r == "" and not Precontratos.de(m, j.id).is_empty(), "firma (intento %d)" % intentos)
	_comprobar(Precontratos.motivo(m, j).contains("precontrato"), "no se firma dos veces: %s" % Precontratos.motivo(m, j))
	## Se guarda y se carga.
	var m2 := Partida.desde_instantanea(Partida.instantanea(m))
	_comprobar(not Precontratos.de(m2, j.id).is_empty() and int(Precontratos.de(m2, j.id)["sueldo"]) == int(Precontratos.de(m, j.id)["sueldo"]), "el precontrato se guarda con la partida")
	## Cambio de temporada: llega a MI club, sin traspaso y con la ficha pactada, y no va a la bolsa de libres ni se queda en su club.
	var sueldo := int(Precontratos.de(m, j.id)["sueldo"])
	m.nueva_temporada()
	_comprobar(mio.plantilla.has(j) and j.club_id == mio.id, "al vencer su contrato llega a tu club")
	_comprobar(not otro.plantilla.has(j) and not m.libres.has(j), "y no se queda en el suyo ni va a libres")
	_comprobar(j.sueldo == sueldo and j.anios_contrato >= 1, "con la ficha pactada (%d) y contrato nuevo (%d años)" % [j.sueldo, j.anios_contrato])
	_comprobar(m.mercado.precontratos.is_empty(), "y la lista de precontratos se vacía")
	## Sin precontrato, el que vence se renueva o se va a libres como siempre (no llega a mi club).
	var m3 := Mundo.new()
	m3.generar(["CHI"], 83)
	m3.tomar_el_mando(m3.ligas[0].clubes[0].id)
	var o3: Club = m3.ligas[0].clubes[1]
	var k: Jugador = o3.plantilla[0]
	k.anios_contrato = 1
	m3.nueva_temporada()
	_comprobar(not m3.mi_club().plantilla.has(k), "sin precontrato nadie llega solo a tu club")
