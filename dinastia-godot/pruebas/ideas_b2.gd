extends "res://pruebas/ideas_base_b.gd"
## Ideas del dueño (lote b, b2): árbitros, disciplina y federación.

func ejecutar() -> void:
	var m := _mb(2702)
	var c := m.mi_club()
	var rival: Club = m.ligas[0].clubes[1]
	var fe: Federacion = m.federacion
	## Perfiles arbitrales (801): el casero solo castiga al visitante.
	var perfiles := {}
	for f: Array in Datos.tabla("ARBITROS"):
		perfiles[String(f[1])] = true
	_comprobar(perfiles.size() >= 4 and perfiles.has("casero") and perfiles.has("tarjetero"), "hay árbitros con perfiles distintos: %s (801)" % ", ".join(perfiles.keys()))
	Azar.sembrar(21)
	var p := Partido.new(c, rival)
	p.once_local = c.once()
	p.once_visita = rival.once()
	p.arbitro = {"nombre": "Árbitro X", "perfil": "casero"}
	var am_l := 0
	var am_v := 0
	for j in c.plantilla:
		j.amarillas = 0
	for j in rival.plantilla:
		j.amarillas = 0
	for i in 3000:
		p._chequeo_arbitral()
	for j in c.plantilla:
		am_l += j.amarillas
	for j in rival.plantilla:
		am_v += j.amarillas
	_comprobar(am_v > 5 and am_l == 0, "el árbitro casero solo amonesta al visitante: %d vs %d (801)" % [am_v, am_l])
	## Árbitro estricto: penales que generan decisión polémica (806); el VAR los recorta (805).
	p.arbitro = {"nombre": "Árbitro Y", "perfil": "estricto"}
	var decisiones: Array[int] = [0]
	var cuenta := func(_t: String, _mi: int) -> void: decisiones[0] += 1
	p.decision_arbitral.connect(cuenta)
	Partido.ctx_factor_tarjetas = 1.0
	for i in 6000:
		p._chequeo_arbitral()
	var sin_var := decisiones[0]
	decisiones[0] = 0
	Partido.ctx_factor_tarjetas = 0.5
	for i in 6000:
		p._chequeo_arbitral()
	var con_var := decisiones[0]
	Partido.ctx_factor_tarjetas = 1.0
	_comprobar(sin_var > 5, "un árbitro estricto cobra penales polémicos (806): %d" % sin_var)
	_comprobar(con_var < sin_var and not fe.var_activo and fe.factor_tarjetas() == 1.0, "con VAR hay menos decisiones polémicas: %d < %d (805)" % [con_var, sin_var])
	fe.var_activo = true
	_comprobar(fe.factor_tarjetas() == 0.5, "el VAR votado recorta tarjetas a la mitad (805)")
	_comprobar("VAR en toda la categoría" in fe.reglas_vigentes("CHI"), "y el reglamento consultable lo muestra (805, 819)")
	fe.var_activo = false
	## Designación conocida de antemano (802) e historial con cada árbitro (803).
	var a1 := Previa.arbitro_de("c7", 5)
	_comprobar(a1 == Previa.arbitro_de("c7", 5) and String(a1["nombre"]) != "" and String(a1["descripcion"]) != "", "el árbitro de la previa es siempre el mismo y trae descripción (802)")
	var dist := {}
	for w in 38:
		dist[String(Previa.arbitro_de("c7", w)["nombre"])] = true
	_comprobar(dist.size() >= 4, "y cambia de jornada en jornada: %d árbitros distintos (802)" % dist.size())
	fe.anotar_arbitro("Árbitro Z", "casero", 2, 0)
	fe.anotar_arbitro("Árbitro Z", "casero", 1, 1)
	fe.anotar_arbitro("Árbitro Z", "casero", 0, 3)
	_comprobar(fe.texto_arbitro("Árbitro Z") == "Con él: 3 PJ · 1G 1E 1P" and fe.texto_arbitro("Nadie") == "", "el historial con cada árbitro cuenta G/E/P (803)")
	## Reclamo formal por una designación (804) y su multa (807).
	var multas := 0
	var acogidos := 0
	for sem in 40:
		Azar.sembrar(100 + sem)
		m.prensa.arbitro_dudoso("Árbitro Q")
		m.prensa.pendiente = {"id": "reclamo", "pid": c.plantilla[0].id, "txt": "", "opcion_a": "", "opcion_b": ""}
		var antes := c.saldo
		var r := m.prensa.resolver("a")
		if String(r["titulo"]) == "Reclamo rechazado":
			multas += 1
			_comprobar(c.saldo < antes, "el reclamo rechazado trae multa (807)") if multas == 1 else null
		elif String(r["titulo"]) == "Reclamo acogido":
			acogidos += 1
	_comprobar(multas >= 3 and acogidos >= 3 and m.prensa.arbitro_polemico == "", "reclamar es una apuesta: %d multas / %d acogidos (804, 807)" % [multas, acogidos])
	## Expulsión del DT: no dirige el partido siguiente (808).
	fe.sancionar_dt(2)
	_comprobar(not fe.dt_sancionado(), "en el partido de la expulsión aún no cuenta (808)")
	fe.cumplir_sancion_dt()
	_comprobar(fe.dt_sancionado(), "el siguiente partido lo ves desde la grada (808)")
	fe.cumplir_sancion_dt()
	fe.cumplir_sancion_dt()
	_comprobar(not fe.dt_sancionado(), "y cumplida la sanción vuelves a la banda (808)")
	## Agresión, apelación (813, 818) y dopaje (817).
	var jug: Jugador = c.plantilla[3]
	jug.suspension = 0
	var caso := fe.abrir_caso("agresion", jug, 6, "agresión a un rival", m.anio, m.semana)
	_comprobar(jug.suspension == 6 and int(caso["fechas"]) == 6, "una agresión castiga largo: 6 fechas (813)")
	var saldo0 := c.saldo
	_comprobar(fe.apelar(String(caso["id"]), c, 50) == "" and c.saldo < saldo0 and String(caso["estado"]) in ["rebajada", "confirmada"], "apelar cuesta honorarios y el tribunal resuelve (818)")
	_comprobar(fe.apelar(String(caso["id"]), c, 50) != "", "no se apela dos veces (818)")
	var positivo := {}
	var escandalos: Array[int] = [0]
	var f_esc := func(fu: int, _mo: String) -> void: escandalos[0] = fu
	fe.escandalo.connect(f_esc)
	for i in 4000:
		Azar.sembrar(300 + i)
		var r2 := fe.control_antidopaje(c, m.anio, m.semana)
		if bool(r2.get("positivo", false)):
			positivo = r2
			break
	_comprobar(not positivo.is_empty(), "el control antidopaje acaba dando algún positivo (817)")
	if not positivo.is_empty():
		var sancionados := 0
		for j in c.plantilla:
			if j.suspension >= 8 and Nombres.visible(j.nombre) == String(positivo["nombre"]):
				sancionados += 1
		_comprobar(sancionados >= 1 and escandalos[0] >= 15 and int(positivo["fechas"]) >= 8 and String(fe.casos[0]["tipo"]) == "dopaje",
			"el positivo suspende 8+ fechas, abre caso y dispara escándalo %d (817)" % escandalos[0])
	## Reglamento por país (819) y alineación indebida (826, 827).
	_comprobar(not fe.reglas_vigentes("CHI").is_empty() and fe.reglas_vigentes("CHI")[0] is String, "el reglamento del país se consulta en frases (819)")
	var viejos: Array[Jugador] = []
	for j in c.plantilla:
		if j.edad > 21 and viejos.size() < 11:
			viejos.append(j)
	var faltas := LeyesPais.infracciones_once(c, viejos)
	_comprobar(not faltas.is_empty() and String(faltas[0]["tipo"]) == "juvenil", "un once sin sub-21 en Chile es alineación indebida (826)")
	var lg := m.ligas[0]
	lg.tabla_puntos[c.id]["pts"] = 10
	lg.sancionar(c.id, 3)
	_comprobar(int(lg.tabla_puntos[c.id]["pts"]) == 7 and int(lg.tabla_puntos[c.id]["sancion"]) == 3, "la sanción quita puntos y queda anotada (827)")
	## Licencia de club (831-834).
	var ob: Instalaciones = m.obras
	c.estadio_aforo = 30000
	c.saldo = 1000000
	fe.semanas_en_rojo = 0
	var req := fe.requisitos_licencia(c, ob)
	_comprobar(req.size() == 6, "la licencia exige seis requisitos (831)")
	c.estadio_aforo = 2000
	var req2 := fe.requisitos_licencia(c, ob)
	_comprobar(not bool(req2[0]["ok"]) and req2[0]["k"] == "aforo", "un estadio chico no cumple el aforo mínimo (832)")
	c.saldo = -5
	fe.semanas_en_rojo = 6
	var req3 := fe.requisitos_licencia(c, ob)
	_comprobar(not bool(req3[3]["ok"]) and not bool(req3[4]["ok"]), "caja en rojo y patrimonio negativo incumplen lo financiero (833)")
	var aud := fe.auditoria_anual(c, ob, 2030)
	_comprobar(aud["estado"] == "denegada" and fe.sin_cupo_internacional and (aud["fallos"] as Array).size() >= 3 and c.saldo < -5,
		"con tres o más fallos la licencia se deniega, con multa y sin cupo internacional (834)")
	c.saldo = 50000000
	c.estadio_aforo = 30000
	fe.semanas_en_rojo = 0
	var fallos_ok := (fe.auditoria_anual(c, ob, 2031)["fallos"] as Array).size()
	_comprobar((fe.licencia == "vigente") == (fallos_ok == 0) and (fe.licencia == "condicional") == (fallos_ok in [1, 2]), "y arreglando papeles la licencia mejora (834): %s con %d fallos" % [fe.licencia, fallos_ok])
	## Presidente con agenda (837).
	fe.presidente = {}
	_comprobar(fe.revisar_presidencia(2030) and fe.presidente.has("agenda") and fe.presidente.has("nombre"), "la liga elige presidente con agenda (837)")
	var empuja := 0
	for k: String in ["var", "fpf", "playoffs", "superliga", "extranjeros", "juveniles"]:
		if fe.agenda_empuja(k):
			empuja += 1
	_comprobar(empuja >= 2 and not fe.revisar_presidencia(2031), "su agenda empuja mociones concretas y el mandato dura (837): %d" % empuja)
