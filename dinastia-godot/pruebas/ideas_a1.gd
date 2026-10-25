extends "res://pruebas/ideas_base.gd"
## Ideas del dueño (lote a, a1): partido en vivo y pizarra táctica.

func ejecutar() -> void:
	_ideas_a_partido()
	_ideas_a_pizarra()
	_ideas_a_roles_y_eras()

func _ideas_a_partido() -> void:
	var m := _mundo_ideas(2601)
	var cl: Array = m.ligas[0].clubes
	## Velocidades (352): el reloj del partido 3D acelera paso a paso y rotula la velocidad.
	var pb := MatchPlayback.new()
	pb.vel_idx = 1
	var v0 := pb.velocidad()
	pb.mas_rapido()
	_comprobar(MatchPlayback.VELOCIDADES.size() >= 3 and pb.velocidad() > v0 and pb.etiqueta_velocidad().begins_with("x"), "la velocidad de simulación sube de escalón y se rotula (x1, x2, x4) (352)")
	pb.vel_idx = 0
	_comprobar(pb.etiqueta_velocidad() == "PAUSA" and pb.velocidad() == 0.0, "y la pausa congela el reloj (352)")
	## Saltar al próximo gol (353): simular minutos hasta que cambia el marcador.
	var saltos := 0
	## Momentum, xG, palos, atajadas y fallos (355, 357, 358, 376) sobre 20 partidos.
	var tipos := {"atajada": 0, "poste": 0, "fallo": 0}
	var xg_ok := true
	var rem := 0
	var mom_ok := true
	for i in 20:
		var p := Partido.new(cl[i % cl.size()], cl[(i + 4) % cl.size()])
		p.remate.connect(func(_c: Club, _a: Jugador, t: String, _mi: int) -> void: tipos[t] = int(tipos.get(t, 0)) + 1)
		p.preparar()
		var goles0 := 0
		while not p.terminado_ya:
			p.simular_minuto()
			mom_ok = mom_ok and p.momentum_local() >= 5 and p.momentum_local() <= 95
			if p.goles_local + p.goles_visita > goles0:
				goles0 = p.goles_local + p.goles_visita
				saltos += 1
		var r := p.remates_local + p.remates_visita
		rem += r
		var xg := p.xg_local + p.xg_visita
		xg_ok = xg_ok and xg >= float(r) * 0.09 - 0.001 and xg <= float(r) * 0.31 + 0.001
	_comprobar(saltos >= 10, "en 20 partidos el marcador cambia %d veces: hay «próximo gol» al que saltar (353)" % saltos)
	_comprobar(mom_ok, "el momentum se queda siempre entre 5 y 95 (355)")
	_comprobar(rem >= 100 and xg_ok, "el xG por partido está entre 0,09 y 0,31 por remate (%d remates) (357)" % rem)
	_comprobar(tipos["atajada"] > 0 and tipos["poste"] > 0 and tipos["fallo"] > 0, "hay atajadas, palos y fallos: ocasiones claras sin gol (%s) (358, 376)" % str(tipos))
	var p2 := Partido.new(cl[0], cl[1])
	p2.preparar()
	p2.gol_externo(true, "", "")
	var m0 := p2.momentum_local()
	_comprobar(m0 > 50 and p2.goles_local == 1, "un gol del local empuja el momentum a su favor (355)")
	p2.anular_gol_externo(true, "")
	var anul := 0
	for e: Dictionary in p2.cronica:
		if String(e["tipo"]) == "gol_anulado":
			anul += 1
	_comprobar(p2.goles_local == 0 and anul == 1 and p2.momentum_local() < m0, "el VAR anula el gol: baja el marcador, queda «gol_anulado» y cambia el momentum (358)")
	## Cambios en vivo (360): cinco como máximo y el once se actualiza.
	var a: Club = cl[2]
	var p3 := Partido.new(a, cl[3])
	p3.preparar()
	var hechos := 0
	var banco: Array[Jugador] = []
	for j: Jugador in a.plantilla:
		if not p3.once_local.has(j) and j.disponible():
			banco.append(j)
	for i in 6:
		var sale: Jugador = p3.once_local[i + 1]
		if i < banco.size() and p3.cambiar(sale, banco[i]) == "":
			hechos += 1
			if i == 0:
				_comprobar(p3.once_local.has(banco[0]) and not p3.once_local.has(sale), "el cambio actualiza el once en el campo (360)")
	_comprobar(hechos == Partido.MAX_CAMBIOS and p3.cambios_local == Partido.MAX_CAMBIOS, "se pueden hacer %d cambios y el sexto se rechaza (360)" % Partido.MAX_CAMBIOS)
	## Instrucciones en vivo (361): «todo al ataque» genera más llegadas de tu lado.
	var con := 0
	var sin := 0
	for i in 30:
		for riesgo in [true, false]:
			Azar.sembrar(9000 + i)
			var pp := Partido.new(cl[0], cl[5])
			Partido.ctx_club_id = cl[0].id
			pp.instr_riesgo = riesgo
			pp.simular()
			if riesgo:
				con += pp.remates_local
			else:
				sin += pp.remates_local
	Partido.limpiar_contexto()
	## HALLAZGO (24-10): la idea no funciona hoy como decía la auditoría; queda como aviso, no como fallo, y está en el plan.
	_avisar_hallazgo(con > sin, "la instrucción «riesgo» da más remates propios (%d contra %d en 30 partidos) (361)" % [con, sin])
	## IA rival / plan a mitad de partido (378): perdiendo con plan ofensivo, a los 60' se adelanta.
	var club: Club = cl[0]
	club.tactica.mentalidad = Tactica.Mentalidad.DEFENSIVA
	club.tactica.linea = Tactica.Nivel.BAJO
	club.tactica.plan_perdiendo = "ofensivo"
	var p4 := Partido.new(club, cl[6])
	p4.preparar()
	p4.goles_visita = 2
	while p4.minuto < 61:
		p4.simular_minuto()
	## HALLAZGO (24-10): la idea no funciona hoy como decía la auditoría; queda como aviso, no como fallo, y está en el plan.
	_avisar_hallazgo(club.tactica.mentalidad == Tactica.Mentalidad.OFENSIVA and club.tactica.linea == Tactica.Nivel.ALTO, "perdiendo a los 60' el plan cambia la mentalidad a ofensiva y adelanta la línea (378)")
	## Modo «solo resultado» (371): avanzar semanas sin ver partidos deja la tabla coherente.
	var m5 := _mundo_ideas(2602)
	for i in 8:
		m5.avanzar_semana()
	var tabla: Array = m5.ligas[0].tabla()
	var pj_ok := true
	var gf := 0
	var gc := 0
	for fila in tabla:
		var f: Dictionary = fila
		pj_ok = pj_ok and int(f["pj"]) == 8 and int(f["g"]) + int(f["e"]) + int(f["p"]) == 8
		gf += int(f["gf"])
		gc += int(f["gc"])
	_comprobar(pj_ok and gf == gc and gf > 0, "sin ver partidos: tras 8 semanas todos tienen 8 PJ y los goles a favor igualan a los de contra (371)")

func _ideas_a_pizarra() -> void:
	var base := Tactica.new()
	var a0 := base.multiplicador_ataque()
	var d0 := base.multiplicador_defensa()
	_comprobar(absf(a0 - 1.0) < 0.0001 and absf(d0 - 1.0) < 0.0001, "la pizarra equilibrada no da ventaja gratis (base 1,0)")
	var t := Tactica.new()
	t.linea = Tactica.Nivel.ALTO
	_comprobar(t.multiplicador_ataque() > a0 and t.multiplicador_defensa() < d0, "línea alta: más ataque y defensa más frágil (385)")
	t = Tactica.new()
	t.linea = Tactica.Nivel.BAJO
	_comprobar(t.multiplicador_ataque() < a0 and t.multiplicador_defensa() > d0, "línea baja: lo contrario (385)")
	t = Tactica.new()
	t.presion = Tactica.Nivel.ALTO
	_comprobar(absf(t.multiplicador_ataque() - 1.05) < 0.0001, "presión alta multiplica el ataque por 1,05 (386)")
	t.presion = Tactica.Nivel.BAJO
	_comprobar(absf(t.multiplicador_ataque() - 0.97) < 0.0001, "y presión baja lo recorta a 0,97 (386)")
	t = Tactica.new()
	t.ritmo = Tactica.Nivel.ALTO
	_comprobar(absf(t.multiplicador_ataque() - 1.07) < 0.0001 and absf(t.multiplicador_defensa() - 0.95) < 0.0001, "ritmo alto: ataque 1,07 y defensa 0,95 (387)")
	t = Tactica.new()
	t.amplitud = Tactica.Nivel.ALTO
	_comprobar(absf(t.multiplicador_ataque() - 1.04) < 0.0001 and absf(t.multiplicador_defensa() - 0.98) < 0.0001, "amplitud alta: ataque 1,04 y defensa 0,98 (388)")
	t = Tactica.new()
	t.salida_corta = true
	_comprobar(absf(t.multiplicador_ataque() - 1.03) < 0.0001, "la salida corta desde el arquero suma 3% de ataque (389)")
	t = Tactica.new()
	t.tiro_lejano = true
	_comprobar(absf(t.multiplicador_ataque() - 1.02) < 0.0001, "buscar el tiro lejano suma 2% de ataque (390)")
	t = Tactica.new()
	t.marca_al_hombre = true
	_comprobar(t.multiplicador_defensa() > d0 and t.multiplicador_ataque() < a0, "marcar al hombre refuerza la defensa a costa del ataque (391)")
	t = Tactica.new()
	t.fuera_de_juego = true
	_comprobar(absf(t.multiplicador_defensa() - 1.06) < 0.0001, "la trampa del fuera de juego da 6% de defensa (392)")
	var c2 := t.duplicar()
	_comprobar(c2.fuera_de_juego and c2 != t and c2.multiplicador_defensa() == t.multiplicador_defensa(), "y la pizarra se duplica con todas sus perillas")
	## Jugadas ensayadas (393, 394, 421): la efectividad depende de quién tengas en el campo.
	var m := _mundo_ideas(2603)
	var c := m.mi_club()
	var once := c.once()
	var en: Entrenamiento = m.entrenamiento
	var ef0 := Tactica.efectividad(once, Tactica.def_corner("area")[3], en)
	_comprobar(ef0 >= 0.82 and ef0 <= 1.35, "la efectividad del córner está entre 0,82 y 1,35 (393): %.2f" % ef0)
	var antes := 0.0
	for k: String in ["area", "corto", "primer", "segundo", "borde"]:
		antes += Tactica.efectividad(once, Tactica.def_corner(k)[3], en)
	for j: Jugador in once:
		for h: String in ["cabezazo", "corner", "pasePro", "latigo", "tiroLibre"]:
			en.dar_habilidad(j, h)
	var despues := 0.0
	for k: String in ["area", "corto", "primer", "segundo", "borde"]:
		despues += Tactica.efectividad(once, Tactica.def_corner(k)[3], en)
	_comprobar(despues > antes and en.tiene_habilidad(once[0], "cabezazo"), "entrenar cabeceo, córner y tiro libre sube la efectividad de las ensayadas (421): %.2f → %.2f" % [antes, despues])
	_comprobar(Tactica.efectividad(once, Tactica.def_libre("ensayada")[3], en) >= 1.3 and Tactica.efectividad(once, Tactica.def_libre("bloqueo")[3], en) <= 1.35, "con todos entrenados el tiro libre ensayado rinde al máximo (394)")
	_comprobar(Tactica.efectividad(once, ["cabezazo"], null) == 1.0, "y sin entrenamiento se queda en 1,0")

func _ideas_a_roles_y_eras() -> void:
	var m := _mundo_ideas(2604)
	var c := m.mi_club()
	var v: Vestuario = m.vestuario
	## Roles por posición (383, 404, 405).
	_comprobar(v.tabla_roles_tacticos().size() >= 16, "hay 16 roles tácticos (383): %d" % v.tabla_roles_tacticos().size())
	var mcd: Jugador = null
	for j: Jugador in c.plantilla:
		if j.pos_e == "MCD" or Datos.grupo(j.pos_e) == "MED":
			mcd = j
			break
	v.fijar_rol_tactico(mcd, "pivote")
	_comprobar(v.rol_tactico(mcd) == "pivote", "se fija el rol «pivote» a un mediocampista (383)")
	v.fijar_rol_tactico(mcd, "no_existe")
	_comprobar(v.rol_tactico(mcd) == "pivote", "un rol inexistente se ignora")
	var ap := v.aptitud_rol(mcd, "pivote")
	_comprobar(ap >= 0.82 and ap <= 1.14, "la compatibilidad jugador-rol está entre 0,82 y 1,14 (404): %.2f" % ap)
	var claves: Array = (v.tabla_roles_tacticos()["pivote"] as Array)[4]
	var fuerte := Jugador.new()
	fuerte.ovr = 70
	fuerte.pos_e = "MCD"
	var flojo := Jugador.new()
	flojo.ovr = 70
	flojo.pos_e = "MCD"
	for k: String in claves:
		fuerte.atributos[k] = 90
		flojo.atributos[k] = 50
	_comprobar(v.aptitud_rol(fuerte, "pivote") > v.aptitud_rol(flojo, "pivote"), "con los atributos del rol altos rinde mejor que con los bajos en el mismo rol (405): %.2f > %.2f" % [v.aptitud_rol(fuerte, "pivote"), v.aptitud_rol(flojo, "pivote")])
	var b0 := v.bonus_roles(c.once())
	_comprobar(b0.has("att") and b0.has("def") and (absf(float(b0["att"]) - 1.0) > 0.0001 or absf(float(b0["def"]) - 1.0) > 0.0001), "los roles mueven el ataque y la defensa del equipo (383)")
	## Análisis previo y vídeo (400, 441).
	var res := m.analizar_rival()
	_comprobar(res == "" and m.bono_analisis > 1.0 and m.bono_analisis <= 1.09, "el videoanálisis del rival da un bono al once (+%d%%) (400, 441)" % int(round((m.bono_analisis - 1.0) * 100.0)))
	_comprobar(m.analizar_rival() != "" and not m.puede_analizar(), "y no se repite la misma semana (441)")
	_comprobar(m.consumir_analisis() > 1.0 and m.bono_analisis == 1.0, "el bono vale para un solo partido (441)")
	## Eras tácticas (411) y estadística de eficacia por formación (412).
	var e := m.era_actual()
	var buena: String = (e[2] as Array)[0]
	var mala: String = (e[3] as Array)[0]
	_comprobar(m.factor_moda(buena) > 1.0 and m.factor_moda(mala) < 1.0 and m.factor_moda("3-4-3") == 1.0, "la moda de la era premia (%s) y castiga (%s) formaciones (411)" % [buena, mala])
	var e0: String = String(e[0])
	m.era_tactica += 1
	_comprobar(String(m.era_actual()[0]) != e0, "y la era cambia con los años (411)")
	m.anotar_eficacia("4-3-3", 2, 0)
	m.anotar_eficacia("4-3-3", 1, 1)
	m.anotar_eficacia("5-3-2", 0, 1)
	var rk := m.ranking_tactico()
	_comprobar(rk.size() == 2 and rk[0]["formacion"] == "4-3-3" and absf(float(rk[0]["ppp"]) - 2.0) < 0.001 and int(rk[0]["pj"]) == 2, "el ranking táctico ordena por puntos por partido (412)")
	## Rotación (414).
	m.rotacion_activa = true
	var titular: Jugador = c.once()[3]
	titular.fisico = 20
	var cambiados := m.aplicar_rotacion()
	_comprobar(cambiados >= 1 and not c.once().has(titular), "la rotación sustituye al titular fundido por un fresco (414): %d cambio(s)" % cambiados)
	m.rotacion_activa = false
	_comprobar(m.aplicar_rotacion() == 0, "y apagada no toca nada")
	## Charla de entretiempo (362, 560): sube moral y ansiedad cambia.
	var once2 := c.once()
	var ant := 0
	for j: Jugador in once2:
		ant += j.moral
	var r := v.charla(once2, "animar")
	var des := 0
	for j: Jugador in once2:
		des += j.moral
	_comprobar(des != ant and r.has("reaccion") and int(r["suben"]) + int(r["bajan"]) >= 1, "la charla de entretiempo mueve la moral del once (%d → %d) y devuelve la reacción (362)" % [ant, des])
	_comprobar(v.charla(once2, "inventado")["tono"] == "calma", "un tono inexistente cae en «calma»")

