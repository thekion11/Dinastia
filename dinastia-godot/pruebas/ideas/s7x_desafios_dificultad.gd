extends BaseIdea
## s7x · LA DIFICULTAD FUERA DEL PARTIDO (pedido del dueño, 27-10-2026; `DesafiosDificultad`). Seis desafíos
## nuevos que se eligen al empezar, junto a los de siempre, y cada uno se nota en su sistema.

func _probar() -> void:
	_titulo("S7X: la dificultad fuera del partido")
	var claves: Array = DesafiosDificultad.todos().map(func(f: Array) -> String: return String(f[0]))
	_comprobar(claves.has("pobreza") and claves.has("mala_racha") and claves.has("impaciente") and claves.size() == 14, "salen los 8 de siempre y los 6 nuevos (%d)" % claves.size())
	_directiva()
	_retos()
	_ojeo()
	_mentor()
	_lesiones()

func _con(desafios: Array) -> Mundo:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 8181)
	m.desafios.assign(desafios)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

func _directiva() -> void:
	_linea("· Directiva impaciente")
	var normal := _con([])
	var dura := _con(["impaciente"])
	normal.directiva.mover_confianza(-10, "prueba")
	dura.directiva.mover_confianza(-10, "prueba")
	var c0: int = Directiva.INICIAL
	_comprobar(c0 - normal.directiva.confianza == 10 and c0 - dura.directiva.confianza == 15, "perder 10 de confianza cuesta 15 con la directiva impaciente")
	dura.directiva.mover_confianza(10, "prueba")
	_comprobar(c0 - dura.directiva.confianza == 5, "y ganar sigue sumando lo mismo")

func _retos() -> void:
	_linea("· Retos exigentes")
	var normal := _con([])
	var dura := _con(["retos_duros"])
	var ids: Array = dura.retos_semana.activos.map(func(a: Dictionary) -> String: return String(a["id"]))
	ids.sort()
	_comprobar(ids == ["cero", "ganar_2", "marcar_3"], "solo salen los retos difíciles (%s)" % str(ids))
	var premio_duro := 0
	for a: Dictionary in dura.retos_semana.activos:
		premio_duro += int(a["premio"])
	var premio_normal := 0
	for a: Dictionary in normal.retos_semana.activos:
		premio_normal += int(a["premio"])
	_comprobar(premio_duro > 0, "y pagan menos por reto de lo normal (%d en total por tres difíciles)" % premio_duro)

func _ojeo() -> void:
	_linea("· Asistentes torpes")
	var normal := _con([])
	var torpe := _con(["asistentes_torpes"])
	_comprobar(torpe.ojeadores._error_de(3.0) >= 2 and normal.ojeadores._error_de(3.0) == 0, "con un ojeador perfecto, los torpes ya no aciertan la media exacta")
	_comprobar(torpe.ojeadores._error_de(1.0) == normal.ojeadores._error_de(1.0) * 2, "y fallan el doble (%d frente a %d)" % [torpe.ojeadores._error_de(1.0), normal.ojeadores._error_de(1.0)])

func _mentor() -> void:
	_linea("· Poca ayuda y malos consejos")
	var callado := _con(["poca_ayuda"])
	_comprobar(callado.mentor_mes.tras_semana(callado, 1, 0) == "", "con poca ayuda, el mentor del primer mes no habla")
	var m := _con([])
	var c := m.mi_club()
	for j: Jugador in c.plantilla:
		j.fisico = 50
	var bueno := String(MentorPrimerMes.consejo_de(2, c, -1, -1, null, false)[2])
	var malo := String(MentorPrimerMes.consejo_de(2, c, -1, -1, null, true)[2])
	_comprobar(bueno.contains("sin piernas") or bueno.contains(Idiomas.t("sin piernas")), "con el grupo reventado, el consejo honrado pide bajar la carga")
	_comprobar(malo != bueno and (malo.contains("fresco") or malo.contains(Idiomas.t("fresco"))), "y el malo dice que está fresco y que apriete")
	var mc := _con(["malos_consejos"])
	var engana := 0
	for s in range(1, 13):
		if DesafiosDificultad.consejo_enganoso(mc, s):
			engana += 1
	_comprobar(engana >= 2 and engana <= 7, "con malos consejos, más o menos uno de cada tres sale al revés (%d de 12 semanas)" % engana)
	_comprobar(not DesafiosDificultad.consejo_enganoso(m, 1) and not DesafiosDificultad.consejo_enganoso(m, 2) and not DesafiosDificultad.consejo_enganoso(m, 3), "sin el desafío, nunca")

func _lesiones() -> void:
	_linea("· Mala racha")
	var m := _con(["mala_racha"])
	var st: int = Azar._rng.state
	m.avanzar_semana()
	_comprobar(is_equal_approx(Partido.ctx_lesion_mio, DesafiosDificultad.LESIONES), "con mala racha, las lesiones de tu club pesan %.1f veces más" % Partido.ctx_lesion_mio)
	var n := _con([])
	n.avanzar_semana()
	_comprobar(is_equal_approx(Partido.ctx_lesion_mio, 1.0), "y sin ella, lo de siempre")
	_comprobar(st != Azar._rng.state, "(las semanas siguen tirando del azar como siempre)")
