extends "res://pruebas/banco/varios_p7.gd"
## [Banco · grupo «varios» · capa 8/10] Generado al partir el banco por grupos (26-10).

## C20: la portada guarda lo que necesita el periódico (foto, bajada, medio) y
## cada medio tiene su cabecera; seis cabeceras distintas.
func _probar_portadas_c20() -> void:
	_titulo("C20 PORTADA DE PERIÓDICO: SEIS CABECERAS Y DATOS PARA DIBUJARLA")
	var m := Mundo.new()
	m.generar(["CHI"], 1357)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var pr := m.prensa
	for k in 12:
		pr.portada_tras_resultado(true, false, false, "semilla%d" % k, "A 2-0 B")
	_comprobar(not pr.portadas.is_empty() and String(pr.portadas[0].get("sub", "")) == "A 2-0 B" and String(pr.portadas[0].get("img", "")) == "dt",
		"la portada del partido lleva el marcador y la foto del DT")
	var nombres := {}
	for c: Array in PortadaPeriodico.CABECERAS:
		nombres[String(c[1])] = true
	_comprobar(nombres.size() == 6, "seis cabeceras distintas")
	_comprobar(String(PortadaPeriodico.cabecera_de({"medio": "El Pelotazo"})[0]) == "pelotazo", "cada medio con su cabecera")
	var a := PortadaPeriodico.cabecera_de({"t": "Algo", "semana": 3})
	_comprobar(a == PortadaPeriodico.cabecera_de({"t": "Algo", "semana": 3}), "la misma portada, la misma cabecera")

## C3: la región de origen existe y se guarda; los españoles ya no son todos
## vascos; el Athletic (o su equivalente ficticio) es todo de Euskal Herria, su
## mercado lo respeta -la IA y tú- y sus canteranos llevan apellidos vascos.
func _probar_cantera_c3() -> void:
	_titulo("C3 FILOSOFÍA DE CANTERA: REGIÓN DE ORIGEN, MERCADO Y APELLIDOS")
	var m := Mundo.new()
	m.generar(["ESP"], 8642)
	var bilbao: Club = null
	var otro: Club = null
	for c: Club in m.clubes.values():
		if not Regiones.filosofia(c).is_empty():
			bilbao = c
		elif c.pais == "ESP" and otro == null:
			otro = c
	_comprobar(bilbao != null, "el club de cantera vasca existe (Athletic o su equivalente)")
	if bilbao == null:
		return
	var todos_vascos := true
	for j: Jugador in bilbao.plantilla:
		todos_vascos = todos_vascos and j.region == "EUS"
	## Nacido o formado allí, aunque juegue con otra selección: cuenta la
	## región, no la nacionalidad.
	_comprobar(todos_vascos, "toda la plantilla es de Euskal Herria (por origen, no por pasaporte)")
	var espanoles := 0
	var vascos := 0
	for c: Club in m.clubes.values():
		if c == bilbao:
			continue
		for j: Jugador in c.plantilla:
			if j.pais == "ESP":
				espanoles += 1
				if j.region == "EUS":
					vascos += 1
	var pct := 100.0 * float(vascos) / float(maxi(1, espanoles))
	_comprobar(pct > 3.0 and pct < 18.0, "los vascos son una parte de los españoles, no todos (%.1f %%)" % pct)
	var apellido_vasco := false
	for j: Jugador in bilbao.plantilla:
		for ap: String in Regiones.APELLIDOS_EUS:
			if j.nombre.ends_with(ap):
				apellido_vasco = true
	_comprobar(apellido_vasco, "apellidos vascos en el Athletic")
	## El mercado: un español no vasco no entra; uno vasco sí.
	var no_vasco: Jugador = null
	var vasco: Jugador = null
	for j: Jugador in otro.plantilla:
		if j.region == "" and no_vasco == null:
			no_vasco = j
	for c: Club in m.clubes.values():
		if c != bilbao:
			for j: Jugador in c.plantilla:
				if j.region == "EUS" and vasco == null:
					vasco = j
	_comprobar(not Regiones.admite(bilbao, no_vasco), "el Athletic no puede fichar a un no vasco")
	_comprobar(vasco == null or Regiones.admite(bilbao, vasco), "sí a uno de Euskal Herria")
	m.tomar_el_mando(bilbao.id)
	var motivo := m.mercado.abrir_negociacion(no_vasco)
	_comprobar(String(motivo).to_lower().contains("euskal herria"), "si diriges al Athletic, la regla vale para ti: «%s»" % motivo)
	## Guardado.
	var d := Partida._jugador_a_dic(bilbao.plantilla[0])
	_comprobar(Partida._dic_a_jugador(d).region == "EUS", "la región se guarda con la partida")


## C5 y C8: el presidente de la federación con agenda y mandato, la junta de
## accionistas del club, y las lesiones absurdas (raras, sin Azar, el toque de
## queda evita las de noche).
func _probar_instituciones_c5_c8() -> void:
	_titulo("C5/C8 INSTITUCIONES: PRESIDENTE DE LA FEDERACIÓN, JUNTA DE ACCIONISTAS, LESIONES ABSURDAS")
	var m := Mundo.new()
	m.generar(["CHI"], 2024)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var f := m.federacion
	_comprobar(f.revisar_presidencia(2026) and not f.presidente.is_empty(), "la federación elige presidente")
	_comprobar(not f.revisar_presidencia(2027), "no hay elecciones a mitad de mandato")
	_comprobar(f.revisar_presidencia(2026 + Federacion.MANDATO_ANIOS), "a los cuatro años, elecciones")
	var ag: Array = Federacion.AGENDAS[String(f.presidente["agenda"])][1]
	_comprobar(f.agenda_empuja(String(ag[0])), "el presidente empuja lo de su agenda")
	var d := f.a_dic()
	var f2 := Federacion.new()
	f2.desde_dic(d)
	_comprobar(f2.presidente == f.presidente, "el presidente se guarda")
	## Junta.
	var jt := m.junta
	_comprobar(jt != null and jt.accionistas.size() == 3 and not jt.presidente.is_empty(), "el club tiene presidente y tres accionistas")
	jt.semana(m.mi_club(), 2026, Junta.CADA)
	_comprobar(not jt.pendiente.is_empty(), "cada trimestre hay junta")
	var conf0 := m.directiva.confianza
	var r := jt.resolver("a", m.mi_club(), m.directiva, m.prensa)
	_comprobar(not r.is_empty() and jt.pendiente.is_empty(), "la junta se resuelve")
	## Forzar la censura: todos hartos.
	for a: Dictionary in jt.accionistas:
		a["humor"] = 20
	jt.pendiente = {"quien": String(jt.accionistas[0]["nombre"]), "exige": "cantera", "tema": "x", "a": "si", "b": "no", "monto": 0}
	conf0 = m.directiva.confianza
	r = jt.resolver("b", m.mi_club(), m.directiva, m.prensa)
	_comprobar(bool(r["censura"]) and m.directiva.confianza < conf0, "un accionista harto presenta moción de censura")
	## Lesiones absurdas.
	var n := 0
	var noche_con_queda := false
	for sem in 400:
		var la := LesionesAbsurdas.sortear(m.mi_club(), 2026, sem, true)
		if not la.is_empty():
			n += 1
			if bool(la["noche"]):
				noche_con_queda = true
	_comprobar(n > 10 and n < 60, "son raras: %d en 400 semanas" % n)
	_comprobar(not noche_con_queda, "con toque de queda no hay lesiones de noche")
	_comprobar(LesionesAbsurdas.sortear(m.mi_club(), 2026, 7, false) == LesionesAbsurdas.sortear(m.mi_club(), 2026, 7, false), "no consume Azar: la misma semana, lo mismo")

## C6/C7: hablar con un jugador (según quién es, con memoria y promesas que se
## cobran), la entrevista al paso de un medio nuevo (mueve seguidores) y la
## presentación de un fichaje.
func _probar_charlas_c6_c7() -> void:
	_titulo("C6/C7 CHARLAS UNO A UNO, ENTREVISTA AL PASO Y PRESENTACIÓN DE FICHAJES")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var j: Jugador = c.plantilla[5]
	j.moral = 50
	j.rasgo = "polemico"
	var r := m.charlas.hablar(j, "exigir", 2026, 3)
	_comprobar(int(r["moral"]) < 0, "al polémico, exigirle le sienta mal (%s)" % String(r["efecto"]))
	j.rasgo = "lider"
	j.moral = 50
	r = m.charlas.hablar(j, "exigir", 2026, 10)
	_comprobar(int(r["moral"]) > 0, "al líder, exigirle le motiva")
	r = m.charlas.hablar(j, "exigir", 2026, 11)
	_comprobar(bool(r["repetido"]) and String(r["respuesta"]).contains("Otra vez"), "repetir el tema enseguida vale menos")
	## Promesa incumplida.
	var k: Jugador = c.plantilla[20]
	var moral_k := k.moral
	m.charlas.hablar(k, "minutos", 2026, 20)
	m.charlas.semana(c, 2026, 20 + Charlas.PLAZO_PROMESA)
	_comprobar(k.moral < moral_k + 5 and not m.charlas.promesas.has(k.id), "la promesa de minutos incumplida se cobra")
	## Al paso.
	var hubo := false
	for sem in 40:
		m.prensa.al_paso = {}
		if not m.prensa.revisar_al_paso(2026, sem).is_empty():
			hubo = true
			break
	_comprobar(hubo, "cada tanto te para un medio nuevo")
	var seg0 := m.prensa.seguidores
	m.prensa.abrir_al_paso()
	var rp := m.prensa.responder_pie(0)
	_comprobar(m.prensa.seguidores != seg0 and not rp.is_empty(), "lo que dices al paso mueve seguidores")
	## Presentación.
	var nuevo: Jugador = m.ligas[0].clubes[3].plantilla[0]
	nuevo.ovr = 95
	var saldo0 := c.saldo
	var pr := PresentacionFichaje.aplicar(m, nuevo, true)
	_comprobar(c.saldo < saldo0 and int(pr["seguidores"]) > 1000, "presentar a una estrella en el estadio cuesta y trae seguidores")
	nuevo.ovr = 40
	pr = PresentacionFichaje.aplicar(m, nuevo, true)
	_comprobar(int(pr["animo"]) <= 1, "presentar a lo grande a un suplente se lee como propaganda")
	## Guardado de charlas.
	var ch2 := Charlas.new()
	ch2.desde_dic(m.charlas.a_dic())
	_comprobar(ch2.ultima.has(j.id), "la memoria de las charlas se guarda")

## C7: la licencia de entrenador (niveles, examen de 8, aprobar con 6, espera al
## suspender, premio de prestigio) y el portero del minijuego que aprende.
func _probar_licencia_c7() -> void:
	_titulo("C7 LICENCIA DE ENTRENADOR Y MINIJUEGO DE PENALES")
	var m := Mundo.new()
	m.generar(["CHI"], 99)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var lic := m.licencia
	var qs := lic.examen()
	_comprobar(qs.size() == Licencia.PREGUNTAS_POR_EXAMEN, "el examen tiene %d preguntas" % qs.size())
	var todas_ok := true
	for q: Array in Licencia.BANCO:
		todas_ok = todas_ok and int(q[2]) >= 0 and int(q[2]) < (q[1] as Array).size()
	_comprobar(todas_ok, "toda pregunta del banco tiene una respuesta válida")
	for n in range(1, 5):
		var cuantas := 0
		for q: Array in Licencia.BANCO:
			if int(q[3]) <= n and int(q[3]) >= maxi(1, n - 1):
				cuantas += 1
		_comprobar(cuantas >= Licencia.PREGUNTAS_POR_EXAMEN, "hay preguntas de sobra para el nivel %d (%d)" % [n, cuantas])
	## Suspender: todas mal.
	var malas: Array = []
	for q: Array in qs:
		malas.append((int(q[2]) + 1) % (q[1] as Array).size())
	var r := lic.corregir(qs, malas, 2026, 5, m.roles, m.prensa)
	_comprobar(not bool(r["aprobado"]) and lic.puede_presentarse(2026, 6) != "", "suspender obliga a esperar")
	_comprobar(lic.puede_presentarse(2026, 5 + Licencia.ESPERA_SEMANAS) == "", "pasada la espera, se puede repetir")
	## Aprobar: todas bien.
	qs = lic.examen()
	var buenas: Array = []
	for q: Array in qs:
		buenas.append(int(q[2]))
	var prest0 := m.roles.prestigio
	r = lic.corregir(qs, buenas, 2026, 20, m.roles, m.prensa)
	_comprobar(bool(r["aprobado"]) and lic.nivel == 1 and m.roles.prestigio >= prest0, "aprobar sube de nivel y de prestigio")
	var l2 := Licencia.new()
	l2.desde_dic(lic.a_dic())
	_comprobar(l2.nivel == 1, "la licencia se guarda")
	## El portero aprende.
	var mj := MinijuegoPenales.new()
	mj._rng.seed = 5
	mj._historial = [2, 2]
	var a_la_2 := 0
	for k in 100:
		if mj.eleccion_portero() == 2:
			a_la_2 += 1
	_comprobar(a_la_2 > 60, "si repites esquina, el portero se tira ahí (%d de 100)" % a_la_2)
	mj.free()


func _probar_calendario_c13() -> void:
	_titulo("C13/C16: CALENDARIO, DÍAS NACIONALES, MEMORIA Y FESTIVIDADES")
	## Las fechas: el lunes de la semana 1 de 2026 es el 26 de enero.
	var d := Calendario.fecha(2026, 1, 0)
	_comprobar(int(d["month"]) == 1 and int(d["day"]) == 26, "la semana 1 de 2026 empieza el lunes 26 de enero")
	var p := Calendario.pascua(2026)
	_comprobar(int(p[0]) == 4 and int(p[1]) == 5, "Pascua 2026 cae el 5 de abril")
	var p2 := Calendario.pascua(2027)
	_comprobar(int(p2[0]) == 3 and int(p2[1]) == 28, "Pascua 2027 cae el 28 de marzo")
	var ram := Calendario.ramadan(2026)
	_comprobar(ram.size() == 2 and int(ram[0][0]) == 2 and absi(int(ram[0][1]) - 18) <= 1, "el Ramadán 2026 empieza hacia el 18 de febrero")
	## El 11 de septiembre, en Chile y en EE. UU., es de memoria.
	var chi := Calendario.del_anio("CHI", 2026)
	var once_chi := chi.filter(func(f: Dictionary) -> bool: return int(f["mes"]) == 9 and int(f["dia"]) == 11)
	var once_usa := Calendario.del_anio("USA", 2026).filter(func(f: Dictionary) -> bool: return int(f["mes"]) == 9 and int(f["dia"]) == 11)
	_comprobar(once_chi.size() == 1 and String(once_chi[0]["tipo"]) == "memoria" and once_usa.size() == 1 and String(once_usa[0]["tipo"]) == "memoria",
		"el 11 de septiembre es fecha de memoria en Chile y en EE. UU.")
	_comprobar(chi.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1), "el 1 de mayo está en Chile")
	var usa := Calendario.del_anio("USA", 2026)
	_comprobar(not usa.any(func(f: Dictionary) -> bool: return int(f["mes"]) == 5 and int(f["dia"]) == 1)
		and usa.any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Labor Day" and int(f["dia"]) == 7),
		"en EE. UU. no es el 1 de mayo sino el Labor Day (7 de septiembre de 2026)")
	_comprobar(Calendario.del_anio("URU", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]) == "Semana de Turismo"), "en Uruguay es la Semana de Turismo")
	_comprobar(Calendario.del_anio("KSA", 2026).any(func(f: Dictionary) -> bool: return String(f["nombre"]).begins_with("Empieza el Ramadán")), "Arabia Saudí tiene el Ramadán en su calendario")
	## Buscar la semana del 18 de septiembre en Chile (fiesta) y la del 11 (memoria).
	var sem_fiesta := -1
	var sem_memoria := -1
	for s in range(1, 50):
		for f: Dictionary in Calendario.de_la_semana("CHI", 2026, s):
			if String(f["nombre"]) == "Fiestas Patrias":
				sem_fiesta = s
			if String(f["nombre"]) == "11 de septiembre":
				sem_memoria = s
	_comprobar(sem_fiesta > 0 and sem_memoria > 0 and sem_fiesta != sem_memoria, "Fiestas Patrias y el 11 caen en semanas distintas (%d y %d)" % [sem_fiesta, sem_memoria])
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_fiesta) > 1.0, "la semana de Fiestas Patrias llena más el estadio")
	_comprobar(Calendario.factor_publico("CHI", 2026, sem_memoria) == 1.0 and Calendario.hay_memoria("CHI", 2026, sem_memoria), "la del 11 de septiembre no tiene bonus de fiesta")
	## Los torneos.
	_comprobar(Calendario.torneos(2026).any(func(t: Dictionary) -> bool: return String(t["nombre"]) == "Copa del Mundo"), "2026 es año de Mundial")
	_comprobar(not Calendario.torneos(2027).any(func(t: Dictionary) -> bool: return String(t["nombre"]) == "Copa del Mundo"), "2027 no")
	## En el mundo: la semana de memoria da noticia y el mentor la explica una vez.
	var m := Mundo.new()
	m.generar(["CHI"], 5151)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var noticias: Array = []
	var mentor: Array = []
	m.calendario.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	m.calendario.mentor.connect(func(t: String, _b: String) -> void: mentor.append(t))
	var moral0 := c.plantilla[0].moral
	m.calendario.semana(c, 2026, sem_memoria)
	_comprobar(noticias.any(func(t: String) -> bool: return t.contains("11 de septiembre")) and mentor.has("11 de septiembre"), "el 11 sale en las noticias y el mentor lo explica")
	_comprobar(c.plantilla[0].moral == moral0, "la memoria no sube la moral como una fiesta")
	m.calendario.semana(c, 2026, sem_fiesta)
	_comprobar(c.plantilla[0].moral == mini(moral0 + 1, 99), "la semana de fiesta sube la moral")
	var m2 := mentor.size()
	m.calendario.ultima_semana = -1
	m.calendario.semana(c, 2027, sem_fiesta + 1 if Calendario.de_la_semana("CHI", 2027, sem_fiesta).is_empty() else sem_fiesta)
	_comprobar(not mentor.slice(m2).has("Fiestas Patrias"), "el mentor no repite la explicación al año siguiente")
	var dic := m.calendario.a_dic()
	var cal2 := Calendario.new()
	cal2.desde_dic(dic)
	_comprobar(cal2.explicadas.has("11 de septiembre"), "se guarda lo que el mentor ya explicó")
	_comprobar(Calendario.proximas("CHI", 2026, 1, 5).size() == 5, "hay próximas fechas para el calendario")

func _probar_marcas_y_escudos() -> void:
	_titulo("M-059/M-062: MARCAS Y ESCUDOS EN TODO EL MUNDO")
	var m := Mundo.new()
	var paises: Array[String] = []
	for pais: String in (Datos.tabla("PAISES_LIGAS") as Dictionary):
		paises.append(pais)
	m.generar(paises, 5962)
	var cuenta := {}
	var zonas := 0
	var firmas := {}
	var repetidos: Array = []
	for c: Club in m.clubes.values():
		var sp := SponsorKit.de_club(c)
		for z: String in sp:
			var marca := String((sp[z] as Dictionary).get("marca", ""))
			cuenta[marca] = int(cuenta.get(marca, 0)) + 1
			zonas += 1
		var firma := "%s|%s|%s|%s|%s|%s" % [Escudo.forma_de(c), Escudo.patron_de(c), c.color1.to_lower(), c.color2.to_lower(),
			Escudo.simbolo_de(c), Escudo.iniciales(c) if Escudo.simbolo_de(c) == "" else ""]
		if firmas.has(firma):
			repetidos.append("%s = %s" % [c.nombre, firmas[firma]])
		firmas[firma] = c.nombre
	var media := float(zonas) / float(maxi(1, Auspicio.marcas().size()))
	var peor := ""
	for k: String in cuenta:
		if peor == "" or int(cuenta[k]) > int(cuenta[peor]):
			peor = k
	_linea("  %d clubes, %d zonas patrocinadas, %d marcas; media %.1f, la que más: %s ×%d" % [m.clubes.size(), zonas, cuenta.size(), media, peor, int(cuenta.get(peor, 0))])
	_comprobar(m.clubes.size() > 300, "un mundo grande (%d clubes)" % m.clubes.size())
	_comprobar(float(cuenta.get(peor, 0)) <= 2.0 * media, "M-059: ninguna marca pasa del doble de la media (%s ×%d, media %.1f)" % [peor, int(cuenta.get(peor, 0)), media])
	## M-085: canas con la edad en los inventados.
	var jv: Jugador = null
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if not j.real and jv == null:
				jv = j
	var edad0 := jv.edad
	jv.edad = 24
	var joven := Color(String(Cara.look_de(jv).get("peloC", "#000000")))
	jv.edad = 39
	var viejo := Color(String(Cara.look_de(jv).get("peloC", "#000000")))
	jv.edad = edad0
	_comprobar(viejo.s < joven.s, "M-085: a los 39 el pelo tiene canas (%s → %s)" % [joven.to_html(false), viejo.to_html(false)])
	_comprobar(repetidos.is_empty(), "M-062: ningún escudo repetido entre clubes (%d: %s)" % [repetidos.size(), str(repetidos.slice(0, 5))])
	## M-066 (25-10): el escudo monocromo solo tiene la tinta, blanco y transparencia.
	var tm := Escudo.textura_mono(m.clubes.values()[0] as Club, 26)
	var im: Image = tm.get_image() if tm != null else null
	var extras := 0
	for yy in range(0, im.get_height() if im != null else 0, 3):
		for xx in range(0, im.get_width(), 3):
			var pm := im.get_pixel(xx, yy)
			extras += 1 if pm.a > 0.0 and pm.r != pm.g and not (pm.r == pm.b) else 0
			extras += 1 if pm.a > 0.0 and pm.r > 0.01 and pm.r < 0.99 else 0
	_comprobar(im != null and extras == 0, "M-066: Escudo.textura_mono solo usa tinta y blanco (%d píxeles de otro color)" % extras)
	## M-063/M-068 (25-10): más clubes con escudo y camiseta de rasgo propio en la tabla.
	var con_esc := 0
	var con_cam := 0
	for fila: Variant in (Datos.tabla("ESTADIO_CLUB") as Dictionary).values():
		con_esc += 1 if (fila as Dictionary).has("escudo") else 0
		con_cam += 1 if (fila as Dictionary).has("camiseta") else 0
	_comprobar(con_esc >= 46 and con_cam >= 99, "M-063/M-068: %d escudos y %d camisetas con rasgo del club real" % [con_esc, con_cam])
	## Los fabricantes en la camiseta 3D (21-10-2026, M-057).
	var mf := Mundo.new()
	mf.generar(["CHI"], 4711)
	var vistos := {}
	for c: Club in mf.ligas[0].clubes:
		var marca := DisenosKit.marca_de(c)
		if not vistos.has(marca):
			_comprobar(DisenosKit.MARCA_FORMA.has(marca) and marca != "propia", "fabricante de %s: %s (conocido, no la marca propia)" % [c.nombre, marca])
		vistos[marca] = true
	_comprobar(vistos.size() >= 4, "los clubes de una liga visten de %d fabricantes distintos" % vistos.size())
	_comprobar(DisenosKit.marca_de(mf.ligas[0].clubes[0]) == DisenosKit.marca_de(mf.ligas[0].clubes[0]), "el fabricante de un club es fijo")
	## Las formas de estadio de los clubes según su tamaño (21-10-2026, M-002).
	var mf2 := Mundo.new()
	mf2.generar(["CHI", "ESP", "ARG", "ENG", "GER", "ITA"], 31)
	var formas := {}
	var chicos_mal := 0
	for c: Club in mf2.clubes.values():
		var fo := String(c.perfil_estadio()["forma"])
		formas[fo] = true
		if c.estadio_aforo < 10000 and fo in ["oval", "caldera"]:
			chicos_mal += 1
	_comprobar(formas.size() >= 8, "los clubes usan %d formas de estadio %s" % [formas.size(), str(formas.keys())])
	_comprobar(chicos_mal == 0, "ningún club de menos de 10.000 butacas tiene un ovalado o una caldera")
	for fo: String in ["estrecho", "asimetrico"]:
		_comprobar(StadiumBuilder.geom_de_forma(fo)["dz"] != StadiumBuilder.geom_de_forma("cuenco")["dz"], "la forma «%s» tiene su geometría" % fo)

func _probar_nombres_repetidos() -> void:
	_titulo("M-331: NOMBRES REPETIDOS EN UN MUNDO")
	var m := Mundo.new()
	m.generar(["CHI", "ESP", "BRA"], 331)
	var vistos := {}
	var total := 0
	for l in m.ligas:
		for c: Club in l.clubes:
			for j: Jugador in c.plantilla:
				total += 1
				vistos[j.nombre] = int(vistos.get(j.nombre, 0)) + 1
	var rep := 0
	var peor := ""
	for k: String in vistos:
		rep += maxi(0, int(vistos[k]) - 1)
		if peor == "" or int(vistos[k]) > int(vistos[peor]):
			peor = k
	var pct := 100.0 * float(rep) / float(maxi(total, 1))
	_linea("  %d jugadores, %d nombres repetidos (%.1f %%); el más repetido: %s ×%d" % [total, rep, pct, peor, int(vistos.get(peor, 0))])
	_comprobar(total > 500, "hay mundo que medir (%d jugadores)" % total)
	_comprobar(pct < 3.0, "menos de un 3 %% de tocayos (%.1f %%)" % pct)
	_comprobar(int(vistos.get(peor, 0)) <= 3, "nadie se llama igual que otros tres")
