extends BaseIdea
## s7m · EL TUTORIAL DE GESTIÓN DEL PRIMER MES (M-297, 27-10-2026; `MentorPrimerMes`). Las cuatro primeras
## semanas al mando, el mentor deja un consejo por semana sacado del club real (partido, cansados, contratos,
## caja y confianza), por `Prensa.mentor_dice`; no se repite, no vuelve al cambiar de club, se guarda, una
## partida vieja no lo recibe y no toca el azar de la partida.

func _probar() -> void:
	_titulo("S7M: el mentor del primer mes")
	var m := _mundo(5151, 0)
	var dichos: Array = []
	m.prensa.mentor_dice.connect(func(t: String, b: String) -> void: dichos.append([t, b]))
	var mm := m.mentor_mes
	_comprobar(mm.activo and mm.semana_al_mando == 0, "al tomar el mando empieza el mes")
	for i in 4:
		m.avanzar_semana()
	_comprobar(mm.dados == ["partido", "carga", "contratos", "caja"], "cuatro semanas, cuatro consejos en orden (%s)" % str(mm.dados))
	_comprobar(dichos.size() == 4, "los cuatro salen por la voz del mentor (%d)" % dichos.size())
	var largos := dichos.all(func(d: Array) -> bool: return String(d[1]).length() > 60)
	_comprobar(largos, "y cada uno dice algo (más de 60 letras)")
	for d: Array in dichos:
		_linea("  «%s» %s" % [d[0], String(d[1]).replace("\n\n", " / ")])
	m.avanzar_semana()
	_comprobar(dichos.size() == 4 and not mm.activo, "la quinta semana ya no habla: el mes acabó")
	## Cambiar de club a mitad de carrera no lo repite.
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	m.avanzar_semana()
	_comprobar(dichos.size() == 4, "fichar por otro club no repite el mes")
	## El texto sale del club real.
	var c := m.mi_club()
	var j: Jugador = c.plantilla[0]
	j.fisico = 40
	j.lesion = 0
	var carga := String(MentorPrimerMes.consejo_de(2, c, -1, -1, null)[2])
	_comprobar(carga.contains(j.nombre), "la carga nombra al más cansado (%s, físico 40)" % j.nombre)
	for k: Jugador in c.plantilla:
		k.anios_contrato = 3
	j.anios_contrato = 1
	var contratos := String(MentorPrimerMes.consejo_de(3, c, -1, -1, null)[2])
	_comprobar(contratos.contains(j.nombre) and contratos.contains("1 "), "los contratos nombran al que acaba (%s)" % j.nombre)
	var antes := c.saldo
	c.mover_saldo(-antes - 1000)
	var caja := String(MentorPrimerMes.consejo_de(4, c, -1, -1, m.directiva)[2])
	_comprobar(caja.contains("rojo") or caja.contains(Idiomas.t("rojo")), "con la caja en negativo, avisa de que está en rojo")
	_comprobar(caja.contains(str(m.directiva.confianza)), "y cita la confianza de la directiva (%d)" % m.directiva.confianza)
	c.mover_saldo(antes + 1000)
	var gano := String(MentorPrimerMes.consejo_de(1, c, 3, 1, null)[2])
	var perdio := String(MentorPrimerMes.consejo_de(1, c, 0, 2, null)[2])
	_comprobar(gano.contains("3-1") and perdio.contains("0-2") and gano != perdio, "el primer consejo cambia con el marcador")
	## Guardar y cargar; y una partida vieja (sin la clave) no lo recibe.
	var mm2 := MentorPrimerMes.new()
	mm2.desde_dic(mm.a_dic())
	_comprobar(mm2.dados == mm.dados and mm2.activo == mm.activo, "se guarda y se carga")
	var viejo := MentorPrimerMes.new()
	viejo.desde_dic({})
	_comprobar(not viejo.activo, "una partida guardada antes no lo recibe a media carrera")
	## No toca el azar.
	var m3 := _mundo(5252, 0)
	var st: int = Azar._rng.state
	m3.mentor_mes.tras_semana(m3, 2, 0)
	m3.mentor_mes.tras_semana(m3, 2, 0)
	_comprobar(Azar._rng.state == st, "no toca el azar de la partida")
	_comprobar(m3.mentor_mes.dados.size() == 2, "y fuera de la semana también se puede llamar (%d)" % m3.mentor_mes.dados.size())
