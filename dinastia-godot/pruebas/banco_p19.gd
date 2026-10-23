extends "res://pruebas/banco_p18.gd"
## (Parte 19 de 25 de `banco.gd`.)

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
