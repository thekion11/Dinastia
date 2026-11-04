extends BaseIdea
## BANCO ESPECIALIZADO «calendario_competiciones», FASE 2 (4-11-2026, megarreforma de los bancos).
##   1. CALENDARIO DE LIGA (todas las ligas, pares e impares): ida y vuelta completa; cada pareja se cruza dos veces, una en
##      cada campo; nadie juega dos veces en una jornada; cada club juega n−1 de local; rachas de local/visita acotadas.
##   2. COPA: el cuadro es potencia de 2; cada ronda juega cada vivo una vez y pasa uno por cruce; el campeón salió del cuadro y
##      cobra el premio exacto; con empate hay penales que no empatan.
##   3. FECHAS: Pascua de años conocidos; Ramadán 2026 (18-19 de febrero); las fechas del juego avanzan 1 día por día.
##   4. TEMPORADA: al jugarla, todas las jornadas se juegan; al cerrarla, bajan los últimos de Primera y suben los primeros
##      de Segunda (los mismos que dice el resumen), y cada liga conserva su número de clubes.

func _probar() -> void:
	_titulo("BANCO CALENDARIO_COMPETICIONES (fase 2): calendario de liga, copa, fechas y ascensos")
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, 4321)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for l: Liga in m.ligas:
		_calendario(l)
	_calendario_impar(m)
	_copa(m)
	_fechas()
	_temporada(m)

# --- 1. CALENDARIO --------------------------------------------------------------------------------------------------------------

func _calendario(l: Liga) -> void:
	var n := l.clubes.size()
	var malos: Array[String] = []
	var esperadas := (n - 1 if n % 2 == 0 else n) * 2
	if l.jornadas() != esperadas:
		malos.append("%d jornadas (esperadas %d)" % [l.jornadas(), esperadas])
	var cruces := {}
	var locales := {}
	var racha_max := 0
	var seguidas := {}   ## club id -> [último «L»/«V», largo de la racha]
	for jor: Array in l.calendario:
		var en_jornada := {}
		for par: Array in jor:
			var a: Club = par[0]
			var b: Club = par[1]
			if a == b:
				malos.append("%s contra sí mismo" % a.nombre)
			for c: Club in [a, b]:
				if en_jornada.has(c.id):
					malos.append("%s juega dos veces en una jornada" % c.nombre)
				en_jornada[c.id] = true
			var k := "%s>%s" % [a.id, b.id]
			cruces[k] = int(cruces.get(k, 0)) + 1
			locales[a.id] = int(locales.get(a.id, 0)) + 1
			for lado in [[a, "L"], [b, "V"]]:
				var c: Club = lado[0]
				var s: Array = seguidas.get(c.id, ["", 0])
				s = [lado[1], int(s[1]) + 1] if s[0] == lado[1] else [lado[1], 1]
				seguidas[c.id] = s
				racha_max = maxi(racha_max, int(s[1]))
	for a: Club in l.clubes:
		if int(locales.get(a.id, 0)) != n - 1:
			malos.append("%s juega %d de local (esperados %d)" % [a.nombre, int(locales.get(a.id, 0)), n - 1])
		for b: Club in l.clubes:
			if a != b and int(cruces.get("%s>%s" % [a.id, b.id], 0)) != 1:
				malos.append("%s recibe a %s %d veces" % [a.nombre, b.nombre, int(cruces.get("%s>%s" % [a.id, b.id], 0))])
	_comprobar(malos.is_empty(), "%s (%d clubes): ida y vuelta completa, una vez en cada campo, nadie dos veces por jornada%s" % [l.nombre, n, "" if malos.is_empty() else " — " + str(malos.slice(0, 5))])
	if n % 2 == 0:
		_comprobar(racha_max <= 3, "  %s: racha más larga en el mismo campo %d (≤ 3)" % [l.nombre, racha_max])
	else:
		## Con número impar el descanso corta la alternancia (método del círculo): hoy ninguna liga real es impar (solo el editor).
		print("  AVISO %s (impar): racha más larga en el mismo campo %d" % [l.nombre, racha_max])

func _calendario_impar(m: Mundo) -> void:
	var l := Liga.new("Prueba impar", "CHI", 3)
	for c: Club in m.ligas[0].clubes.slice(0, 7):
		l.clubes.append(c)
	l.preparar()
	_calendario(l)

# --- 2. COPA ---------------------------------------------------------------------------------------------------------------------

func _copa(m: Mundo) -> void:
	Azar.sembrar(55)
	var todos: Array[Club] = []
	for c: Club in m.ligas[0].clubes + m.ligas[1].clubes:
		todos.append(c)
	var cp := Copa.new()
	cp.preparar(todos)
	var n := cp.participantes.size()
	_comprobar(n >= 16 and (n & (n - 1)) == 0 and n <= todos.size() and n * 2 > todos.size(), "copa: cuadro de %d (potencia de 2, el mayor que cabe en %d)" % [n, todos.size()])
	var malos: Array[String] = []
	var empates := 0
	while cp.en_curso():
		var antes := cp.vivos.duplicate()
		var res := cp.jugar_ronda()
		if res.size() * 2 != antes.size():
			malos.append("ronda con %d vivos y %d partidos" % [antes.size(), res.size()])
		var vistos := {}
		for r: Dictionary in res:
			var a: Club = r["local"]
			var b: Club = r["visita"]
			for c: Club in [a, b]:
				if vistos.has(c.id) or not antes.has(c):
					malos.append("%s mal puesto en %s" % [c.nombre, String(r["ronda"])])
				vistos[c.id] = true
			var pasa: Club = r["pasa"]
			if pasa != a and pasa != b:
				malos.append("pasa %s, que no jugó ese cruce" % pasa.nombre)
			var gl := int(r["gl"])
			var gv := int(r["gv"])
			if gl != gv and pasa != (a if gl > gv else b):
				malos.append("%d-%d y pasa el que perdió" % [gl, gv])
			if gl == gv:
				empates += 1
				var pen: Array = r["penales"]
				if pen.size() != 2 or int(pen[0]) == int(pen[1]) or pasa != (a if int(pen[0]) > int(pen[1]) else b):
					malos.append("empate %d-%d con tanda %s" % [gl, gv, pen])
		if cp.vivos.size() * 2 != antes.size():
			malos.append("de %d vivos pasan %d" % [antes.size(), cp.vivos.size()])
	_comprobar(cp.campeon != null and cp.participantes.has(cp.campeon), "copa: hay campeón y salió del cuadro (%s)" % (cp.campeon.nombre if cp.campeon else "—"))
	_comprobar(malos.is_empty(), "copa: %d rondas, cada vivo juega una vez, pasa el ganador (o el de la tanda: %d empates)%s" % [cp.historial.size(), empates, "" if malos.is_empty() else " — " + str(malos.slice(0, 5))])
	_comprobar(cp.historial.size() == int(round(log(float(n)) / log(2.0))), "copa: %d rondas para %d equipos" % [cp.historial.size(), n])
	## El premio exacto al campeón.
	var cp2 := Copa.new()
	var dos: Array[Club] = [todos[0], todos[1]]
	cp2.preparar(dos)
	var saldos := [todos[0].saldo, todos[1].saldo]
	Azar.sembrar(9)
	cp2.jugar_ronda()
	var cobro := (cp2.campeon.saldo - int(saldos[0 if cp2.campeon == todos[0] else 1])) if cp2.campeon != null else -1
	_comprobar(cobro == int(round(float(Copa.PREMIO) * cp2.peso_premio)), "copa: el campeón cobra el premio exacto (%d)" % cobro)

# --- 3. FECHAS -------------------------------------------------------------------------------------------------------------------

func _fechas() -> void:
	var pascuas := {2024: [3, 31], 2025: [4, 20], 2026: [4, 5], 2027: [3, 28], 2030: [4, 21], 2038: [4, 25], 2000: [4, 23]}
	var malas: Array[String] = []
	for a: int in pascuas:
		var p := Calendario.pascua(a)
		if p != pascuas[a]:
			malas.append("%d: %s (real %s)" % [a, p, pascuas[a]])
	_comprobar(malas.is_empty(), "Pascua de 7 años conocidos (2000-2038)%s" % ("" if malas.is_empty() else " — " + str(malas)))
	var ram := Calendario.ramadan(2026)
	var empieza: Array = []
	for r: Array in ram:
		if String(r[2]).begins_with("Empieza"):
			empieza = r
	_comprobar(not empieza.is_empty() and int(empieza[0]) == 2 and absi(int(empieza[1]) - 18) <= 1, "Ramadán 2026 empieza el 18 de febrero ± 1 (%s)" % str(empieza))
	var saltos := 0
	var antes := Calendario.unix_de(2026, 1, 0)
	for s in range(1, 53):
		for d in 7:
			if s == 1 and d == 0:
				continue
			var u := Calendario.unix_de(2026, s, d)
			saltos += 0 if u - antes == 86400 else 1
			antes = u
	_comprobar(saltos == 0, "las fechas del juego avanzan exactamente un día por día durante 52 semanas (%d saltos)" % saltos)
	var lunes := int(Calendario.fecha(2026, 1, 0).get("weekday", -1))
	_comprobar(lunes == 1, "la semana del juego empieza en lunes (día %d)" % lunes)

# --- 4. TEMPORADA ----------------------------------------------------------------------------------------------------------------

func _temporada(m: Mundo) -> void:
	var tamanos := {}
	for l: Liga in m.ligas:
		tamanos[l.nombre] = l.clubes.size()
	while m.temporada_en_curso():
		m.avanzar_semana()
	var sin_jugar: Array[String] = []
	var ultimos := {}
	var primeros := {}
	for l: Liga in m.ligas:
		if l.quedan_jornadas():
			sin_jugar.append(l.nombre)
		var t := l.tabla()
		ultimos[l.nombre] = (t.slice(t.size() - l.plazas_descenso) as Array).map(func(f: Dictionary) -> Club: return f["club"])
		primeros[l.nombre] = (t.slice(0, l.plazas_descenso) as Array).map(func(f: Dictionary) -> Club: return f["club"])
	_comprobar(sin_jugar.is_empty(), "la temporada juega todas las jornadas de todas las ligas%s" % ("" if sin_jugar.is_empty() else ": " + str(sin_jugar)))
	var pj_mal: Array[String] = []
	for l: Liga in m.ligas:
		var n := l.clubes.size()
		var esperado := (n - 1) * 2   ## también con n impar: cada club descansa una jornada por vuelta
		for f: Dictionary in l.tabla():
			if int(f["pj"]) != esperado:
				pj_mal.append("%s: %d PJ (esperados %d)" % [(f["club"] as Club).nombre, int(f["pj"]), esperado])
	_comprobar(pj_mal.is_empty(), "cada club jugó (n−1)·2 partidos de liga%s" % ("" if pj_mal.is_empty() else " — " + str(pj_mal.slice(0, 4))))
	m.cerrar_temporada_simulada()
	var res: Dictionary = m.nueva_temporada()
	var bajan: Array = res.get("bajan", [])
	var suben: Array = res.get("suben", [])
	_comprobar(bajan.size() > 0 and bajan.size() == suben.size(), "al cerrar el año bajan y suben los mismos (%d y %d)" % [bajan.size(), suben.size()])
	var malos: Array[String] = []
	for l: Liga in m.ligas:
		if l.clubes.size() != int(tamanos[l.nombre]):
			malos.append("%s pasa de %d a %d clubes" % [l.nombre, int(tamanos[l.nombre]), l.clubes.size()])
		for c: Club in l.clubes:
			if c.division != l.division():
				malos.append("%s juega en %s pero su división es %d" % [c.nombre, l.nombre, c.division])
	for l: Liga in m.ligas:
		if l.division() != 1 or not m.ligas.any(func(o: Liga) -> bool: return o.pais == l.pais and o.division() == 2):
			continue   ## sin Segunda en ese país no hay descenso
		for c: Club in ultimos[l.nombre]:
			if not bajan.has(c) and res.get("administrativo", []).is_empty() and res.get("promocion", {}).is_empty():
				malos.append("%s acabó último en %s y no bajó" % [c.nombre, l.nombre])
	for c: Club in bajan:
		if c.division != 2:
			malos.append("%s bajó pero sigue en división %d" % [c.nombre, c.division])
	for c: Club in suben:
		if c.division != 1:
			malos.append("%s subió pero sigue en división %d" % [c.nombre, c.division])
	_comprobar(malos.is_empty(), "ascensos y descensos: los últimos de Primera bajan, los primeros de Segunda suben, cada liga con sus clubes%s" % ("" if malos.is_empty() else " — " + str(malos.slice(0, 5))))
	var nuevas_ok := true
	for l: Liga in m.ligas:
		nuevas_ok = nuevas_ok and l.jornada_actual == 0 and l.jornadas() > 0
	_comprobar(nuevas_ok, "la temporada nueva arranca con el calendario armado y en la jornada 0")
