extends "res://pruebas/ideas_base_b.gd"
## Ideas del dueño (lote b, b3): selecciones y competencias.

func ejecutar() -> void:
	var m := _mb(2703)
	var c := m.mi_club()
	var sel: Selecciones = m.selecciones
	## Tres figuras del país en el plantel, una por línea, para que entren en la lista.
	var tres: Array[Jugador] = []
	for pos in ["POR", "DEF", "DEL"]:
		for j in c.plantilla:
			if j.pos == pos and not tres.has(j):
				j.pais = sel.pais_seleccion()
				j.ovr = 99
				tres.append(j)
				break
	## Lista preliminar y lista definitiva (862).
	sel.semana(m.anio, 6)
	_comprobar(sel.prenomina_ids.size() == 30 and sel.prenominados().size() == 30, "la semana 6 publica una prenómina de 30 (862)")
	for j in tres:
		j.fisico = 100
		j.moral = 50
	var ev_comp: Array[int] = [0]
	var f_mov := func(concepto: String, monto: int) -> void:
		if concepto.begins_with("Compensación"):
			ev_comp[0] += monto
	sel.movimiento.connect(f_mov)
	var tocados: Array[Jugador] = []
	var f_toc := func(j: Jugador, _s: int, _so: bool) -> void: tocados.append(j)
	sel.vuelve_tocado.connect(f_toc)
	sel.semana(m.anio, 7)
	_comprobar(sel.nomina_ids.size() == 18 and sel.convocados().size() == 18, "la fecha FIFA reduce a una nómina definitiva de 18 (862)")
	var mios_conv := 0
	var cansados := 0
	for j in sel.convocados():
		if j.club_id == c.id:
			mios_conv += 1
			if j.fisico <= 100 - Selecciones.DESGASTE_FIFA:
				cansados += 1
	_comprobar(mios_conv >= 3 and cansados == mios_conv, "los convocados del club vuelven con 12 puntos menos de físico (844, 872): %d/%d" % [cansados, mios_conv])
	_comprobar(tres[0].moral > 50 and sel.caps_de(tres[0]) == 1, "y con la moral arriba y una internacionalidad más (844)")
	## Con muchas fechas, alguien vuelve lesionado y la FIFA compensa al club (846, 872).
	var saldo0 := c.saldo
	for i in 120:
		Azar.sembrar(500 + i)
		for j in tres:
			j.lesion = 0
			j.fisico = 100
		sel.semana(m.anio, 7)
		if ev_comp[0] > 0:
			break
	_comprobar(not tocados.is_empty() and tocados[0].lesion > 0, "alguno vuelve lesionado de la selección (872)")
	_comprobar(ev_comp[0] > 0, "y la federación internacional compensa al club con %s (846)" % _dinero(ev_comp[0]))
	## Conflicto club-selección: pedir descanso (871).
	var fig := tres[2]
	_comprobar(sel.pedir_descanso(fig) == "" and sel.pidio_descanso(fig), "se pide a la federación que no cite a la figura (871)")
	_comprobar(sel.pedir_descanso(fig) != "" and sel.pedir_descanso(m.ligas[0].clubes[1].plantilla[0]) != "", "no se repite el pedido ni se pide por jugadores ajenos (871)")
	## Nacionalización por años de residencia (863).
	var extr: Jugador = c.plantilla[c.plantilla.size() - 1]
	extr.pais = "BRA"
	_comprobar(not sel.elegible(extr) and sel.nacionalizar(extr) != "", "un extranjero recién llegado no se puede nacionalizar (863)")
	for i in Selecciones.TEMPORADAS_PARA_NACIONALIZAR:
		sel.residencias()
	_comprobar(sel.temporadas_en_el_pais(extr) == 4, "cada temporada en el país suma residencia (863)")
	var s_nac := c.saldo
	_comprobar(sel.nacionalizar(extr) == "" and sel.elegible(extr) and sel.nacionalidad_deportiva(extr) == "CHI" and c.saldo < s_nac, "a los 4 años se nacionaliza pagando el trámite y ya es elegible (863)")
	## Mundial cada cuatro años y vitrina (867, 874).
	_comprobar(sel.toca_copa_del_mundo(2028) and sel.toca_copa_del_mundo(2032) and not sel.toca_copa_del_mundo(2030), "el Mundial toca cada cuatro años (867)")
	var camp := sel.copa_del_mundo(2028)
	_comprobar(String(camp["campeon"]) != "" and String(sel.mundial["campeon"]) == String(camp["campeon"]) and (camp["convocados"] as Array).size() == 6, "se juega la Copa del Mundo con campeón y seis convocados tuyos (867): %s" % camp["campeon"])
	var estrella: Jugador = c.plantilla[4]
	estrella.ovr = 70
	estrella.tasar()
	var valor0 := estrella.valor
	for i in 30:
		sel._vitrina_mundialista(estrella, 2030)
	_comprobar(estrella.ovr > 70 and estrella.valor > valor0, "la vitrina mundialista sube media y valor de mercado (874): %d → %d" % [valor0, estrella.valor])
	## Amistosos que generan ingresos (881) y torneos de pretemporada (895).
	for j in c.plantilla:
		j.forma = 50
	m.amistoso_hecho = false
	_comprobar(m.jugar_amistosos("local") == "" and c.plantilla[0].forma > 50 and m.jugar_amistosos("local") != "", "el triangular sube la forma y solo se juega una vez (895)")
	m.amistoso_hecho = false
	var s_g := c.saldo
	var so_g := c.socios
	var mov_g := 0
	m.jugar_amistosos("gira")
	_comprobar(c.socios >= so_g + 300, "la gira internacional trae socios y taquilla (881): socios +%d, caja %s" % [c.socios - so_g, _dinero(c.saldo - s_g)])
	## Playoff de descenso (850) y supercopa (893).
	var prim: Club = m.ligas[0].clubes[2]
	var asc: Club = m.ligas[0].clubes[3]
	var pr := m.jugar_promocion(prim, asc)
	_comprobar((pr["ganador"] == prim or pr["ganador"] == asc) and "global" in String(pr["texto"]), "la promoción se juega a ida y vuelta: %s (850)" % String(pr["texto"]).left(60))
	m._campeon_liga_pasado = prim
	m._campeon_copa_pasado = asc
	var sc := m.jugar_supercopa()
	_comprobar(sc.has("campeon") and (sc["campeon"] == prim or sc["campeon"] == asc) and String(sc["nombre"]).begins_with("Supercopa"), "la supercopa enfrenta a los dos campeones (893)")
	m._campeon_copa_pasado = prim
	_comprobar(m.jugar_supercopa().is_empty(), "y si ganó el doblete no hay supercopa (893)")
	_ideas_b_copas(m)

func _ideas_b_copas(m: Mundo) -> void:
	var todos: Array[Club] = []
	for cl: Club in m.clubes.values():
		todos.append(cl)
	## Copa de eliminación directa (890), sorteo anunciado (901), sede fija (905).
	var cp := Copa.new("Copa de prueba")
	var l16: Array[Club] = todos.slice(0, 16)
	cp.preparar(l16)
	var sorteos: Array[int] = [0]
	cp.sorteo_eliminatoria.connect(func(_r: String, parejas: Array) -> void: sorteos[0] += parejas.size())
	cp.anunciar_sorteo()
	_comprobar(cp.vivos.size() == 16 and sorteos[0] == 8 and cp.nombre_de_ronda() == "Octavos de final", "el sorteo anuncia los 8 cruces de octavos (901)")
	var camp := cp.jugar_hasta_el_final()
	_comprobar(camp != null and cp.historial.size() == 4 and cp.vivos.size() == 1 and cp.historial[3]["ronda"] == "Final", "la copa se juega a eliminación directa en 4 rondas hasta la final (890)")
	var cp2 := Copa.new("Final con sede")
	var dos: Array[Club] = [todos[0], todos[1]]
	cp2.preparar(dos)
	cp2.sede_final_id = cp2.vivos[1].id
	var sede: Club = cp2.vivos[1]
	var res := cp2.jugar_ronda()
	_comprobar(res[0]["local"] == sede, "la final se juega en la sede fijada de antemano (905)")
	var ed := Editor.new(m)
	cp2.sede_final_id = ""
	m.copa = Copa.new("X")
	ed.fijar_sede_final(todos[5])
	_comprobar(m.copa.sede_final_id == todos[5].id and m.ajustes_competicion["copa_sede"] == todos[5].id, "el editor fija la sede de la final para esta y las próximas temporadas (905)")
	_comprobar(Copa.copas_de("ENG", "Inglaterra").size() == 2 and Copa.copas_de("ENG", "Inglaterra")[1][0] == "Copa de la Liga" and Copa.copas_de("ESP", "España")[0][0] == "Copa del Rey", "hay copa de la liga secundaria y copas propias de cada país (894)")
	## Copa continental con grupos (896, 903, 904, 907, 908).
	var lib := Continental.crear("lib")
	lib.preparar(l16)
	_comprobar(lib.por_grupos and lib.grupos.size() == 4 and lib.grupos[0].size() == 4, "la copa internacional arranca con 4 grupos de 4 (896, 903)")
	for i in 3:
		lib.jugar_ronda()
	var t0 := lib.tabla_de_grupo(0)
	var ordenada := true
	for i in t0.size() - 1:
		ordenada = ordenada and (int(t0[i]["pts"]) > int(t0[i + 1]["pts"]) or (int(t0[i]["pts"]) == int(t0[i + 1]["pts"]) and int(t0[i]["dif"]) >= int(t0[i + 1]["dif"])))
	_comprobar(ordenada and int(t0[0]["pj"]) == 3, "la tabla de grupo ordena por puntos y diferencia de gol (903)")
	_comprobar(lib.clasificados().size() == 8 and lib.vivos.size() == 8 and lib.nombre_de_ronda() == "Cuartos de final", "pasan 8 a cuartos (903)")
	_comprobar(lib.premio_de_ronda(4) > lib.premio_de_ronda(8) and lib.premio_de_ronda(8) > 0 and lib.premio_de_cuartos() > 0, "los premios crecen con la fase alcanzada (907)")
	var uc := Continental.crear("ucl")
	_comprobar(lib.premio_de_ronda(8) != uc.premio_de_ronda(8), "y cada copa paga distinto (907)")
	var camp2 := lib.jugar_hasta_el_final()
	_comprobar(camp2 != null and lib.historial.size() == 6, "la copa internacional llega a su final (896)")
	## Cupos según la posición en la liga (908).
	var liga1: Liga = m.ligas[0]
	var lider: Club = liga1.clubes[7]
	liga1.tabla_puntos[lider.id]["pts"] = 99
	liga1.tabla_puntos[lider.id]["pj"] = 1
	var plazas := Continental.plazas(m.clubes.values(), m.ligas, null)
	var pl: Array = plazas["lib"]
	_comprobar(pl.size() == 16 and pl[0] == lider, "el líder de la liga ocupa la primera plaza continental de su país (908)")
	var campcopa: Club = null
	for cl in todos:
		if cl.pais == "ARG" and not pl.has(cl):
			campcopa = cl
			break
	var pl2: Array = Continental.plazas(m.clubes.values(), m.ligas, campcopa)["lib"]
	_comprobar(campcopa != null and pl2.has(campcopa) and pl2.size() == 16, "el campeón de copa se lleva una plaza directa (908)")

