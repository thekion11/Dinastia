extends BaseIdea
## El cierre de temporada avanza el año en el núcleo, el guardado lo conserva y
## el club intervenido por deudas baja por despacho (M-219), humano o IA.

func _probar() -> void:
	_titulo("CIERRE: año que avanza y descenso administrativo (M-219)")
	var m := _mundo(2601)
	var a0 := m.anio
	for _i in 3:
		m.cerrar_temporada()
	_comprobar(m.anio == a0 + 3, "tres cierres avanzan tres años: %d -> %d" % [a0, m.anio])
	var d := Partida.instantanea(m)
	_comprobar(int(d["anio"]) == m.anio, "el retrato de la partida guarda el año nuevo (%d)" % int(d["anio"]))
	m.nueva_temporada()
	_comprobar(m.anio == a0 + 4, "nueva_temporada() suma uno, sin duplicar")
	_probar_descenso_ia()
	_probar_descenso_humano()

func _primera_y_segunda(m: Mundo) -> Array:
	for l in m.ligas:
		if l.division() == 1 and m._segunda_de(l.pais) != null:
			return [l, m._segunda_de(l.pais)]
	return []

func _probar_descenso_ia() -> void:
	var m := _mundo(2602)
	var ls := _primera_y_segunda(m)
	_comprobar(not ls.is_empty(), "hay Primera y Segunda")
	if ls.is_empty():
		return
	m.jugar_temporada()
	var t: Array = (ls[0] as Liga).tabla()
	var lider: Club = t[0]["club"]
	if lider == m.mi_club():
		lider = t[1]["club"]
	lider.saldo = -5000000
	for _s in Banco.SEM_VEEDOR:
		m.insolvencia.semana(m)
	_comprobar(m.insolvencia.intervenido(m, lider), "un club de la IA 8 semanas en rojo queda intervenido")
	var n1 := (ls[0] as Liga).clubes.size()
	var r := m.cerrar_temporada()
	_comprobar(lider.division == 2, "el intervenido baja aunque acabó arriba (división %d)" % lider.division)
	_comprobar((ls[0] as Liga).clubes.size() == n1, "Primera conserva su tamaño (%d)" % (ls[0] as Liga).clubes.size())
	_comprobar((r.get("administrativo", []) as Array).has(lider), "el resumen apunta el descenso administrativo")

func _probar_descenso_humano() -> void:
	var m := _mundo(2603)
	var ls := _primera_y_segunda(m)
	if ls.is_empty() or not (ls[0] as Liga).clubes.has(m.mi_club()):
		_comprobar(false, "tu club empieza en una Primera con Segunda")
		return
	m.jugar_temporada()
	m.banco.semanas_en_rojo = Banco.SEM_VEEDOR
	m.mi_club().saldo = -1000000
	var avisos: Array[String] = []
	m.insolvencia.noticia.connect(func(ti: String, _c: String) -> void: avisos.append(ti))
	m.cerrar_temporada()
	_comprobar(m.mi_club().division == 2, "tu club intervenido baja por deudas")
	_comprobar(avisos.has(Idiomas.t("⚖️ Descenso administrativo")), "y sale la noticia del descenso administrativo")
