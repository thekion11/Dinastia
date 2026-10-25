extends "res://pruebas/ideas_base.gd"
## Ideas del dueño (lote a, a3): medicina, selección, vestuario y prensa interna.

const _A3B := preload("res://pruebas/ideas_a3b.gd")

func ejecutar() -> void:
	_ideas_a_lesiones()
	_ideas_a_emergencia_y_rehab()
	_ideas_a_vestuario()
	_ideas_a_extranjeros_y_prensa()
	_A3B.new(b).ejecutar()

func _ideas_a_lesiones() -> void:
	var m := _mundo_ideas(2621)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var md: Medico = m.medico
	var cat := md.catalogo()
	var clases := {}
	for f: Array in cat:
		clases[String(f[1])] = true
	_comprobar(cat.size() == 22 and clases.size() == 5 and clases.has("muscular") and clases.has("articular") and clases.has("osea"), "el catálogo tiene 22 lesiones de 5 clases: %s (516, 517)" % ", ".join(clases.keys()))
	## Cada lesión cae dentro del rango de su fila (516) y deja su clase en la ficha (517).
	var rival: Jugador = (m.ligas[0].clubes[1] as Club).plantilla[3]
	rival.rasgo = ""
	var dentro := true
	var vistas := {}
	var duraciones := {}
	for i in 120:
		rival.lesion = 0
		var sem := md.lesionar(rival, Medico.GRAVE if i % 2 == 0 else Medico.LEVE, "prueba", m.anio, 3)
		var f := md.ficha(rival)
		vistas[String(f["clase"])] = true
		duraciones[sem] = true
		for fila: Array in cat:
			if String(fila[0]) == String(f["tipo"]):
				dentro = dentro and sem >= int(fila[2]) and sem <= int(fila[3])
	_comprobar(dentro and duraciones.size() >= 5, "las semanas de baja salen del rango de la lesión sorteada y son variadas (%d duraciones) (516)" % duraciones.size())
	_comprobar(vistas.size() >= 3, "en 120 lesiones salen varias clases: %s (517)" % ", ".join(vistas.keys()))
	## Propenso a lesionarse (520) y fatiga distinta de forma (535).
	var normal: Jugador = c.plantilla[1]
	var fragil: Jugador = c.plantilla[2]
	normal.rasgo = ""
	fragil.rasgo = "fragil"
	normal.fisico = 80
	fragil.fisico = 80
	_comprobar(md.riesgo_por_fatiga(fragil) > md.riesgo_por_fatiga(normal) * 1.5, "el rasgo frágil sube el riesgo de lesión un 60%% (520): %.4f contra %.4f" % [md.riesgo_por_fatiga(fragil), md.riesgo_por_fatiga(normal)])
	var r0 := md.riesgo_por_fatiga(normal)
	normal.forma = 30
	var r_forma := md.riesgo_por_fatiga(normal)
	normal.forma = 90
	normal.fisico = 40
	var r_fis := md.riesgo_por_fatiga(normal)
	_comprobar(absf(r_forma - r0) < 0.000001 and r_fis > r0, "el riesgo depende del físico (piernas) y no de la forma (momento) (535)")
	## Historial médico y valor de mercado (521).
	var j: Jugador = (m.ligas[0].clubes[2] as Club).plantilla[4]
	j.rasgo = ""
	j.tasar()
	var v0 := j.valor
	var n := 0
	while md.lesiones_graves(j) < 2 and n < 80:
		j.lesion = 0
		md.lesionar(j, Medico.GRAVE, "prueba", m.anio, 5)
		n += 1
	_comprobar(md.lesiones_graves(j) >= 2 and md.factor_valor(j) == 0.85, "dos lesiones largas dejan el factor de valor en 0,85 (521)")
	_comprobar(float(j.valor) < float(v0) * 0.9 and float(j.valor) > float(v0) * 0.78, "y el valor de mercado baja ~15%% (%d → %d) (521)" % [v0, j.valor])
	## Retiro forzado por lesión crónica (532).
	var viejo: Jugador = c.plantilla[3]
	viejo.edad = 31
	var hist: Array = md.historial(viejo)
	hist.clear()
	var ret := 0
	for k in 3:
		hist.append({"n": "Rotura", "sem": 14, "anio": m.anio - k, "semana": 3})
	for i in 200:
		if md.retiro_forzado(viejo):
			ret += 1
	_comprobar(ret >= 40 and ret < 200, "con tres lesiones largas el retiro forzado es probable pero no seguro (%d de 200) (532)" % ret)
	viejo.edad = 22
	var ret2 := 0
	for i in 100:
		if md.retiro_forzado(viejo):
			ret2 += 1
	hist.pop_back()
	viejo.edad = 31
	for i in 100:
		if md.retiro_forzado(viejo):
			ret2 += 1
	_comprobar(ret2 == 0, "pero nunca antes de los 27 ni con menos de tres lesiones largas (532)")
	## Enfermedades no deportivas (539).
	var enfermo: Jugador = c.plantilla[4]
	var hubo := false
	var semanas_enf := 0
	for i in 300:
		enfermo.lesion = 0
		semanas_enf = md.lesionar(enfermo, -1, "prueba", m.anio, 2)
		if String(md.ficha(enfermo)["clase"]) == "enfermedad":
			hubo = true
			break
	_comprobar(hubo and enfermo.lesion == semanas_enf and md.diagnostico(enfermo) != "", "hay enfermedades (%s) que dejan al jugador fuera %d semana(s) (539)" % [md.diagnostico(enfermo), semanas_enf])
	## Médico del club con nivel propio (525).
	var sin: int = m.staff.descuento_lesion(10)
	for i in 3:
		m.staff.subir("medico", c)
	var con: int = m.staff.descuento_lesion(10)
	_comprobar(sin == 10 and con < 10 and m.staff.nivel("medico") == 3, "subir el nivel del médico recorta las semanas de baja (%d → %d) (525)" % [sin, con])
	var propio: Jugador = c.plantilla[5]
	propio.rasgo = ""
	var suma_con := 0
	var suma_sin := 0
	for i in 40:
		Azar.sembrar(3000 + i)
		propio.lesion = 0
		suma_con += md.lesionar(propio, Medico.MEDIA, "prueba", m.anio, 2)
		var staff_viejo: Staff = md.staff
		md.staff = Staff.new()
		Azar.sembrar(3000 + i)
		propio.lesion = 0
		suma_sin += md.lesionar(propio, Medico.MEDIA, "prueba", m.anio, 2)
		md.staff = staff_viejo
	_comprobar(suma_con < suma_sin, "con médico de nivel 3 las mismas lesiones duran menos en tu club (%d contra %d semanas en 40) (525)" % [suma_con, suma_sin])
	## Días perdidos (541) y comparativa con la liga (542).
	var d0 := md.dias_perdidos
	var sem2 := md.lesionar(c.plantilla[6], Medico.MEDIA, "prueba", m.anio, 4)
	_comprobar(md.dias_perdidos == d0 + sem2 * 7 and sem2 >= 1, "las lesiones de tu plantel suman días perdidos (+%d) (541)" % (sem2 * 7))
	var d1 := md.dias_perdidos
	md.lesionar(rival, Medico.MEDIA, "prueba", m.anio, 4)
	_comprobar(md.dias_perdidos == d1, "y las de otros clubes no (541)")
	var rk := md.ranking_liga(c, m.ligas[0])
	_comprobar(int(rk["puesto"]) >= 1 and int(rk["puesto"]) <= int(rk["total"]) and int(rk["total"]) == m.ligas[0].clubes.size() and int(rk["media"]) > 0, "tu departamento médico se compara con la liga: puesto %d de %d (542)" % [rk["puesto"], rk["total"]])
	md.dias_perdidos = 0
	var mejor := int(md.ranking_liga(c, m.ligas[0])["puesto"])
	md.dias_perdidos = 7 * 400
	var peor := int(md.ranking_liga(c, m.ligas[0])["puesto"])
	_comprobar(mejor == 1 and peor == int(rk["total"]), "sin semanas perdidas eres el primero y con 400 semanas el último (puesto %d y %d) (542)" % [mejor, peor])

func _ideas_a_emergencia_y_rehab() -> void:
	var m := _mundo_ideas(2622)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var md: Medico = m.medico
	## Rehabilitación visible semana a semana (543).
	var j: Jugador = c.plantilla[1]
	j.lesion = 0
	md.lesionar(j, Medico.GRAVE, "prueba", m.anio, 3)
	j.lesion = 10
	md.ficha(j)["total"] = 10
	var p0 := md.pct_recuperado(j)
	_comprobar(md.terapia(j, c) == "" and int(md.ficha(j)["terapia"]) >= 3, "se contrata terapia intensiva (543)")
	var l0 := j.lesion
	_comprobar(md.rehabilitacion(j) and j.lesion == l0 - 1 and md.pct_recuperado(j) > p0, "cada semana de rehabilitación descuenta una de baja y sube el porcentaje (%d%% → %d%%) (543)" % [p0, md.pct_recuperado(j)])
	## Ventana de emergencia por lesión grave (530, 531).
	var r: Roles = m.roles
	m.semana = 10
	_comprobar(not r.ventana_abierta() and not r.puede_fichar(), "con el mercado cerrado no se puede fichar (530)")
	_comprobar(r.abrir_emergencia(j.id) and r.emergencia_activa() and r.puede_fichar(), "una lesión grave abre la ventana de emergencia y se puede fichar un libre (530)")
	_comprobar(not r.abrir_emergencia(j.id), "pero solo una vez por temporada (531)")
	m.semana = 15
	_comprobar(not r.emergencia_activa() and not r.puede_fichar(), "dura tres semanas y se cierra sola (531)")
	r.emergencia = {}
	m.semana = 12
	r.abrir_emergencia(j.id)
	r.usar_emergencia()
	_comprobar(not r.emergencia_activa(), "y se gasta al usarla: es una sola bala (531)")
	## Descanso programado como herramienta preventiva (537).
	var en: Entrenamiento = m.entrenamiento
	for i in 6:
		en.fijar_dia(i, "fisico")
	var duro := en.carga_riesgo()
	for i in 6:
		en.fijar_dia(i, "descanso")
	_comprobar(en.carga_riesgo() < duro and en.carga_riesgo() <= 0.5, "una semana de descanso programado baja la carga de riesgo (%.1f → %.1f) (537)" % [duro, en.carga_riesgo()])
	## Lesión en la gira de selección (529): recorre fechas FIFA hasta que alguien vuelve tocado.
	var tocados := []
	m.selecciones.vuelve_tocado.connect(func(x: Jugador, s: int, _sobre: bool) -> void: tocados.append([x, s]))
	for i in 150:
		m.selecciones._fecha_fifa(m.anio, 7 + (i % 3) * 9)
	var ok_tocado := not tocados.is_empty()
	if ok_tocado:
		var par: Array = tocados[0]
		ok_tocado = (par[0] as Jugador).lesion >= 1 and int(par[1]) >= 1
	_comprobar(ok_tocado, "en las fechas FIFA algún convocado vuelve lesionado (%d casos) (529)" % tocados.size())

func _ideas_a_vestuario() -> void:
	var m := _mundo_ideas(2623)
	var c := m.mi_club()
	c.mover_saldo(900000000)
	var v: Vestuario = m.vestuario
	## Jerarquía interna (546).
	v.armar()
	var con_lider := 0
	var lider_ok := true
	for cl: Dictionary in v.camarillas:
		con_lider += 1
		lider_ok = lider_ok and (cl["miembros"] as Array).has(cl["lider"]) and v.clan_por_id(String(cl["id"])).has("humor")
	_comprobar(con_lider >= 1 and lider_ok, "cada grupo del vestuario tiene un líder que es miembro suyo (%d grupos) (546)" % con_lider)
	var j0: Jugador = c.plantilla[0]
	var clan := v.clan_de(j0)
	_comprobar(clan.is_empty() or (clan["miembros"] as Array).has(j0.id), "y el jugador conoce a su grupo (546)")
	## Quejas por minutos (550): el rol prometido no se cumple.
	var j: Jugador = c.plantilla[3]
	v.fijar_rol(j, "titular")
	var avisos := []
	v.rol_incumplido.connect(func(x: Jugador, ratio: float) -> void: avisos.append([x, ratio]))
	var moral0 := j.moral
	for i in 10:
		v._chequeo_roles([])
	_comprobar(avisos.size() >= 1 and (avisos[0][0] as Jugador) == j and j.moral < moral0, "un titular prometido que no juega protesta y pierde moral (%d → %d) (550)" % [moral0, j.moral])
	## Pide salir (551).
	v.solicitud = {"pid": j.id, "k": "salida"}
	var rs := v.resolver_solicitud(true)
	_comprobar(j.transferible and String(rs.get("clave", "")) == "salida", "concederle la salida lo deja transferible (551)")
	v.solicitud = {"pid": j.id, "k": "salida"}
	var m1 := j.moral
	v.resolver_solicitud(false)
	_comprobar(j.moral == m1 - 10, "y negársela le cuesta 10 de moral (551)")
	## Capitán (556).
	var voto := v.votar_capitan(c)
	var g: Jugador = voto["ganador"]
	_comprobar(g != null and g.edad >= 21 and int(voto["total"]) == c.plantilla.size(), "el vestuario vota capitán entre los mayores de 21 (556)")
	var aspirante: Jugador = c.plantilla[7]
	for x: Jugador in c.plantilla:
		x.capitan = false
	c.plantilla[8].capitan = true
	v.solicitud = {"pid": aspirante.id, "k": "capitan"}
	v.resolver_solicitud(true)
	var caps := 0
	for x: Jugador in c.plantilla:
		if x.capitan:
			caps += 1
	_comprobar(aspirante.capitan and caps == 1 and not c.plantilla[8].capitan, "dar la cinta a quien la pide deja un solo capitán (556)")
	## Tonos de charla (560, 561).
	var tonos := {}
	for t: String in Vestuario.TONOS:
		var lote: Array = c.plantilla.slice(0, 11)
		for x: Jugador in lote:
			x.rasgo = ""
			x.moral = 70
		var r := v.charla(lote, t)
		tonos[t] = r["nombre"]
		var moral_t := 0
		var en_rango := true
		var fila: Array = Vestuario.TONOS[t]
		for x: Jugador in lote:
			moral_t += x.moral - 70
			en_rango = en_rango and x.moral - 70 >= int(fila[2]) and x.moral - 70 <= int(fila[3])
		_comprobar(String(r["tono"]) == t and en_rango, "el tono «%s» mueve la moral de cada jugador dentro de su margen [%d, %d] (%+d en total) (560)" % [t, int(fila[2]), int(fila[3]), moral_t])
	_comprobar(tonos.size() == 6, "hay seis tonos de charla distintos (560)")
	var lideres: Array[Jugador] = []
	for i in 11:
		var x := Jugador.new()
		x.id = "lid%d" % i
		x.rasgo = "lider"
		lideres.append(x)
	var frag: Array[Jugador] = []
	for i in 11:
		var x2 := Jugador.new()
		x2.id = "fra%d" % i
		x2.rasgo = "fragil"
		frag.append(x2)
	var suma := {"lid_exig": 0, "lid_elog": 0, "fra_exig": 0, "fra_elog": 0}
	for rep in 25:
		for g2: Array in [[lideres, "lid"], [frag, "fra"]]:
			for tono: String in ["exigir", "calma"]:
				for x: Jugador in g2[0]:
					x.moral = 60
				v.charla(g2[0], tono)
				var t_m := 0
				for x: Jugador in g2[0]:
					t_m += x.moral - 60
				suma["%s_%s" % [g2[1], "exig" if tono == "exigir" else "elog"]] += t_m
	_comprobar(suma["lid_exig"] > suma["lid_elog"] and suma["fra_elog"] > suma["fra_exig"], "los líderes responden mejor a la exigencia (%d contra %d) y los frágiles al elogio (%d contra %d) (561)" % [suma["lid_exig"], suma["lid_elog"], suma["fra_elog"], suma["fra_exig"]])
	## Conflictivo determinante, multas, reglamento y escándalos (563, 564, 565, 566).
	var pol: Jugador = c.plantilla[9]
	pol.rasgo = "polemico"
	var tipos := {}
	for i in 300:
		var s := v.suceso_semanal()
		tipos[String(s.get("tipo", ""))] = true
		if tipos.size() >= 3 and tipos.has("lio"):
			break
	_comprobar(tipos.has("lio") and tipos.size() >= 3, "con un polémico en el plantel hay líos nocturnos entre los sucesos semanales: %s (563, 566)" % ", ".join(tipos.keys()))
	var saldo := c.saldo
	m.normas["multas"] = false
	var lio0 := v._suceso_lio(m, c)
	_comprobar(int(lio0["multa"]) == 0 and c.saldo == saldo, "con el reglamento sin multas el lío no se cobra (565)")
	m.normas["multas"] = true
	var s1 := c.saldo
	var lio1 := v._suceso_lio(m, c)
	var esperada := maxi(1, (lio1["jugador"] as Jugador).sueldo * Vestuario.MULTA_SEMANAS)
	_comprobar(int(lio1["multa"]) == esperada and c.saldo == s1 + esperada, "con la norma «multas» se cobran dos semanas de sueldo (%s) (564, 565)" % str(esperada))
	_comprobar(Mundo.NORMAS_DEF.size() == 4 and String(Mundo.NORMAS_DEF[0][0]) == "multas", "el reglamento interno tiene cuatro normas configurables (565)")

func _dinero_a(n: int) -> String:
	return str(n)

func _ideas_a_extranjeros_y_prensa() -> void:
	var m := _mundo_ideas(2624)
	var c := m.mi_club()
	var cn: Cantera = m.cantera
	## Extranjero solo (569) y compatriota (572).
	var ext: Jugador = c.plantilla[2]
	ext.pais = "JPN"
	for x: Jugador in c.plantilla:
		if x != ext and x.pais == "JPN":
			x.pais = "CHI"
	ext.moral = 70
	cn.prometer_compatriota(ext)
	_comprobar(cn.tiene_promesa(ext), "se le promete traer a un compatriota (572)")
	var res := cn.chequeo_promesas()
	_comprobar(res.size() == 1 and not bool(res[0]["cumplida"]) and ext.moral < 70 and ext.pide_salir, "sin compatriota al cerrar la temporada se hunde su moral (%d) y pide volver (569)" % ext.moral)
	var ext2: Jugador = c.plantilla[3]
	ext2.pais = "JPN"
	ext2.moral = 60
	ext2.pide_salir = false
	cn.prometer_compatriota(ext2)
	c.plantilla[4].pais = "JPN"
	var res2 := cn.chequeo_promesas()
	_comprobar(res2.size() == 1 and bool(res2[0]["cumplida"]) and ext2.moral == 68 and not ext2.pide_salir, "con un compatriota en el plantel la promesa se cumple y suma 8 de moral (572)")
	## Declaraciones públicas que mueven el ánimo interno (574).
	var pr: Prensa = m.prensa
	var rueda := pr.abrir_rueda(true, false)
	_comprobar(not rueda.is_empty() and pr.hay_rueda(), "tras un partido hay rueda de prensa (574)")
	var opciones: Array = pr.entrevista["opciones"]
	var mejor := 0
	for i in opciones.size():
		if int(opciones[i]["moral"]) > int(opciones[mejor]["moral"]):
			mejor = i
	var antes := 0
	for x: Jugador in c.plantilla:
		antes += x.moral
	var conf0 := m.directiva.confianza
	var r := pr.responder(mejor)
	var despues := 0
	for x: Jugador in c.plantilla:
		despues += x.moral
	_comprobar(r.has("titular") and int(r["moral"]) != 0 and despues != antes, "lo que dices en la rueda mueve la moral de todo el plantel (%d en total) (574)" % (despues - antes))
	_comprobar((int(r["confianza"]) == 0) == (m.directiva.confianza == conf0), "y la confianza de la directiva (574)")
