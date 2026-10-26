extends BaseIdea
## CLÁUSULA DE DESCENSO Y FRENO DEL ENTRENAMIENTO (26-10-2026, decisiones del dueño).
##  1. Al descender (IA y humano) los sueldos bajan 30-50 % según el contrato, los de más caché pueden pedir
##     salir, se ve en el régimen de la ficha y se guarda; al ascender vuelven a su nivel.
##  2. Un juvenil de 17 con techo alto sube +4-6 por temporada con el plan por defecto (antes +10-11) y no más
##     de +8 con buen plan (foco técnico, al límite, prioritario).

func _probar() -> void:
	_titulo("CLÁUSULA DE DESCENSO")
	_clausula()
	_titulo("DIFICULTAD: premios, pretensiones y tope del valor de la IA")
	_dificultad()
	_titulo("FRENO DEL ENTRENAMIENTO DE TU PLANTEL (juveniles de 17, techo 86)")
	var normal := _crecimiento(false)
	var bueno := _crecimiento(true)
	_linea("  plan por defecto: media %+.1f (min %+d, max %+d) · buen plan: media %+.1f (max %+d)" % [
		normal["media"], normal["min"], normal["max"], bueno["media"], bueno["max"]])
	_comprobar(normal["media"] >= 3.5 and normal["media"] <= 6.5, "plan por defecto: +%.1f por temporada (objetivo +4-6)" % normal["media"])
	_comprobar(bueno["media"] > normal["media"], "el buen plan sigue notándose (%+.1f contra %+.1f)" % [bueno["media"], normal["media"]])
	_comprobar(bueno["media"] <= 8.5 and bueno["max"] <= 10, "buen plan: media %+.1f ≤ +8,5 y nadie más de +10 (máx %+d)" % [bueno["media"], bueno["max"]])

func _clausula() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 404)
	var primera: Array = m.ligas[0].clubes.duplicate()
	primera.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	m.tomar_el_mando((primera[0] as Club).id)
	var yo := m.mi_club()
	var antes: Dictionary = {}
	for j in yo.plantilla:
		antes[j.id] = j.sueldo
	var masa0 := yo.masa_salarial()
	var piden := Contratos.aplicar_descenso(yo, m.anio)
	var rmin := 1.0
	var rmax := 0.0
	var top: Jugador = yo.plantilla[0]
	for j in yo.plantilla:
		rmin = minf(rmin, j.rebaja_descenso)
		rmax = maxf(rmax, j.rebaja_descenso)
		if j.sueldo_pleno() > top.sueldo_pleno():
			top = j
	_linea("  rebajas %.2f-%.2f · masa %d → %d (×%.2f) · piden salir %d" % [rmin, rmax, masa0, yo.masa_salarial(), float(yo.masa_salarial()) / masa0, piden])
	_comprobar(rmin >= 0.30 and rmax <= 0.50 and rmax - rmin >= 0.12, "cada contrato rebaja entre el 30 y el 50 %% (%.2f-%.2f)" % [rmin, rmax])
	_comprobar(top.rebaja_descenso >= 0.44, "el que más cobra se lleva la rebaja más dura (%.2f)" % top.rebaja_descenso)
	var ratio := float(yo.masa_salarial()) / float(masa0)
	_comprobar(ratio >= 0.50 and ratio <= 0.70, "la nómina baja un 30-50 %% (×%.2f)" % ratio)
	_comprobar(piden >= 1 and piden <= yo.plantilla.size() / 3, "algunos de los de más caché piden salir (%d)" % piden)
	## Retasar a mitad de temporada (sube de media, parte médico) no le devuelve el sueldo pleno.
	var j0: Jugador = yo.plantilla[1]
	var s_antes := j0.sueldo
	j0.tasar()
	_comprobar(absi(j0.sueldo - s_antes) <= maxi(20, s_antes / 20), "retasarlo mantiene la cláusula (%d → %d)" % [s_antes, j0.sueldo])
	_comprobar(Contratos.tipo(j0, false).contains("%"), "la ficha lo dice: «%s»" % Contratos.tipo(j0, false))
	## Guardado y carga.
	var k := Partida._dic_a_jugador(Partida._jugador_a_dic(j0))
	_comprobar(is_equal_approx(k.rebaja_descenso, j0.rebaja_descenso) and k.descenso_club == yo.id and k.sueldo == j0.sueldo, "la cláusula se guarda y se carga")
	## Si se va a otro club, deja de aplicarse.
	var otro: Jugador = yo.plantilla[2]
	otro.club_id = "otro"
	_comprobar(otro.factor_clausula() == 1.0, "en otro club la cláusula ya no cuenta")
	otro.club_id = yo.id
	## Ascenso: vuelven a su nivel.
	Contratos.levantar_descenso(yo)
	var max_dif := 0.0
	for j in yo.plantilla:
		max_dif = maxf(max_dif, absf(float(j.sueldo) / float(antes[j.id]) - 1.0))
	_comprobar(max_dif <= 0.03 and yo.plantilla.all(func(j: Jugador) -> bool: return j.rebaja_descenso == 0.0),
		"al ascender cada sueldo vuelve a su nivel (desvío máx %.1f %%)" % (max_dif * 100.0))
	## Y en el cierre real: el último de Primera baja con la cláusula puesta (IA o humano).
	var m2 := Mundo.new()
	m2.generar(["CHI"], 505)
	m2.tomar_el_mando(m2.ligas[0].clubes[0].id)
	m2.jugar_temporada()
	var r := m2.nueva_temporada()
	var ok := not (r["bajan"] as Array).is_empty()
	for c: Club in r["bajan"]:
		var con := c.plantilla.filter(func(j: Jugador) -> bool: return j.factor_clausula() < 1.0).size()
		ok = ok and con >= c.plantilla.size() / 2
		_linea("  baja %s: %d de %d con cláusula" % [c.nombre, con, c.plantilla.size()])
	_comprobar(ok, "en el cierre de temporada los descendidos cobran con la cláusula")

func _crecimiento(buen_plan: bool) -> Dictionary:
	var deltas: Array[int] = []
	for s in [11, 22, 33]:
		var m := Mundo.new()
		m.generar(["CHI"], s)
		m.tomar_el_mando(m.ligas[0].clubes[3].id)
		var yo := m.mi_club()
		var chicos: Array[Jugador] = []
		for j in yo.plantilla:
			if chicos.size() < 4 and not j.es_portero() and j.ovr >= 60:
				j.edad = 17
				j.ovr = 62
				j.pot = 86
				j.tasar()
				chicos.append(j)
		if buen_plan:
			m.entrenamiento.foco = "tecnico"
			m.entrenamiento.intensidad = "alta"
			for j in chicos:
				m.entrenamiento.alternar_prioritario(j)
		var o0: Dictionary = {}
		for j in chicos:
			o0[j.id] = j.ovr
		m.jugar_temporada()
		var pj := 0
		for j in chicos:
			pj += j.partidos
		m.nueva_temporada()
		for j in chicos:
			deltas.append(j.ovr - int(o0[j.id]))
		_linea("    semilla %d%s: %d partidos de media" % [s, " (buen plan)" if buen_plan else "", pj / chicos.size()])
	var suma := 0
	for d in deltas:
		suma += d
	return {"media": float(suma) / maxf(1.0, deltas.size()), "min": deltas.min(), "max": deltas.max()}

func _dificultad() -> void:
	var m := _mundo(606)
	var j: Jugador = m.mi_club().plantilla[0]
	var r := {}
	for d in ["facil", "normal", "leyenda"]:
		m.dificultad = d
		r[d] = [m.cantera.pide_para_renovar(j), Negociacion._pide_fichaje(m, j, "titular", 3),
			m._premio_para(m.mi_club(), Mundo.PREMIO_LIGA), m.tope_valor_ia()]
		_linea("  %s: renovar %d · fichar %d · premio de liga %d · tope valor IA x%.2f" % [d, r[d][0], r[d][1], r[d][2], r[d][3]])
	_comprobar(r["facil"][0] < r["normal"][0] and r["normal"][0] < r["leyenda"][0], "renovar: en fácil piden menos y en leyenda más")
	_comprobar(r["facil"][1] < r["normal"][1] and r["normal"][1] < r["leyenda"][1], "fichar: en fácil piden menos y en leyenda más")
	_comprobar(r["facil"][2] > r["normal"][2] and r["normal"][2] > r["leyenda"][2], "el premio de liga de tu club sube en fácil y baja en leyenda")
	_comprobar(r["facil"][3] < r["normal"][3] and r["normal"][3] < r["leyenda"][3], "el tope del valor de la IA crece con la dificultad")
	## La taquilla que enseña Finanzas: la misma cuenta que se cobra, con precios dinámicos.
	var yo := m.mi_club()
	var t0 := m.estimar_taquilla(yo)
	var f := m._finanzas_de_la_semana(yo)
	var a_mano := int(round(float(f.asistencia()) * m.factor_publico() * Calendario.factor_publico(yo.pais, m.anio, m.semana)
		* (m.comercial.factor_techo() if m.comercial != null else 1.0) * (m.ciudad.factor_aforo() if m.ciudad != null else 1.0)
		* (m.maestria.factor_publico() if m.maestria != null else 1.0)))
	_comprobar(int(t0["gente"]) == a_mano and int(t0["gente"]) <= yo.estadio_aforo, "taquilla estimada: %d personas, %d por partido" % [t0["gente"], t0["monto"]])
	m.hinchada.precio_dinamico = true
	var t1 := m.estimar_taquilla(yo)
	var pp := m.proximo_partido()
	var rr: int = ((pp[1] if pp[0] == yo else pp[0]) as Club).rep if pp.size() == 2 else 70
	_comprobar(int(t1["precio"]) == m.hinchada.precio_efectivo(int(round(yo.precio_entrada)), rr), "con precios dinámicos usa el precio contra el rival (%d → %d)" % [int(yo.precio_entrada), int(t1["precio"])])
	var otro: Club = m.ligas[0].clubes[1]
	_comprobar(m._premio_para(otro, Mundo.PREMIO_LIGA) == Mundo.PREMIO_LIGA, "a la IA no le cambia el premio")
