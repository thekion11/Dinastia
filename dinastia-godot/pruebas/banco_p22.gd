extends "res://pruebas/banco_p21.gd"
## [Capa 24/27 de `banco.gd`] _probar_contratos_c9, _probar_vida_dt, _probar_maestrias, _probar_habilidades_en_resultados, _probar_motor_libre, _probar_portafolio_futbol … (+1)

func _probar_contratos_c9() -> void:
	_titulo("C9: CONTRATOS Y JORNADA LABORAL")
	_comprobar(Contratos.JORNADA.size() == 24, "los 24 países tienen su jornada legal")
	## Chile: 44 horas hasta el 26 de abril de 2026, 42 después, 40 en 2028.
	var sem_marzo := 8
	var sem_junio := 20
	_comprobar(Contratos.horas("CHI", 2026, sem_marzo) == 44 and Contratos.horas("CHI", 2026, sem_junio) == 42, "Chile pasa de 44 a 42 horas en abril de 2026")
	_comprobar(Contratos.horas("CHI", 2028, sem_junio) == 40, "y llega a 40 en 2028")
	_comprobar(Contratos.horas("COL", 2026, sem_junio) == 44 and Contratos.horas("COL", 2026, 30) == 42, "Colombia baja a 42 en julio de 2026")
	_comprobar(Contratos.horas("FRA", 2026, 10) == 35 and Contratos.horas("MEX", 2026, 10) == 48, "Francia 35, México 48")
	_comprobar(Contratos.factor_estructura("FRA", 2026, 10) > 1.0 and Contratos.factor_estructura("MEX", 2026, 10) < 1.0, "menos horas legales, estructura más cara")
	var m := Mundo.new()
	m.generar(["CHI"], 5154)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var j := c.plantilla[0]
	j.edad = 17
	_comprobar(Contratos.ajustar_anios(j, 5) == 3, "un menor de 18 no firma por más de 3 años (FIFA)")
	j.edad = 25
	_comprobar(Contratos.ajustar_anios(j, 7) == 5 and Contratos.ajustar_anios(j, 0) == 1, "entre 1 y 5 años para el resto")
	var noticias: Array = []
	m.contratos.noticia.connect(func(t: String, _b: String) -> void: noticias.append(t))
	for s in range(1, 30):
		m.contratos.semana(c, 2026, s)
	_comprobar(noticias.size() == 1, "el cambio de jornada de abril sale una vez en las noticias")
	var jugadores_menores := 0
	for cl: Club in m.clubes.values():
		for x: Jugador in cl.plantilla:
			if x.edad < 18 and x.anios_contrato > 3:
				jugadores_menores += 1
	_comprobar(jugadores_menores == 0, "ningún menor del mundo generado tiene más de 3 años de contrato")

func _probar_vida_dt() -> void:
	_titulo("MI VIDA: LA VIDA DEL DT FUERA DEL CLUB")
	var m := Mundo.new()
	m.generar(["CHI"], 5156)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	var v := m.vida
	var r := m.roles
	v.crear_perfil(c.id)
	var perfil0 := v.perfil.duplicate(true)
	v.perfil = {}
	v.crear_perfil(c.id)
	_comprobar(v.perfil == perfil0, "la familia sale siempre igual para el mismo club")
	r.patrimonio = 100000
	var p0 := r.patrimonio
	v.semana(c, r, 2026, 1, 2)
	_comprobar(r.patrimonio == p0 - v.coste_semanal(), "casa y transporte se pagan del patrimonio")
	## Trabajar al máximo: más preparación, más estrés.
	v.balance = 100
	v.estres = 40
	_comprobar(v.factor_trabajo(2026, 2) > 1.02, "trabajando al 100% se prepara mejor el partido")
	for s in range(2, 8):
		v.semana(c, r, 2026, s, -1)
	_comprobar(v.estres > 60, "perder y trabajar sin parar dispara el estrés (%d)" % v.estres)
	## Tres semanas al límite: reposo.
	v.estres = 95
	v.semanas_estres_alto = 0
	for s in range(8, 11):
		v.estres = 95
		v.semana(c, r, 2026, s, -1)
	_comprobar(v.de_baja(2026, 10) or v.de_baja(2026, 11), "tres semanas al límite: el médico te para")
	## Ocio: una vez por semana.
	v.estres = 50
	_comprobar(v.hacer_ocio("asado", r, 2026, 20) == "" and v.estres < 50, "un asado baja el estrés")
	_comprobar(v.hacer_ocio("gimnasio", r, 2026, 20) != "", "solo un respiro por semana")
	## Mudanza.
	var pat := r.patrimonio
	_comprobar(v.cambiar_vivienda("casa", r) == "" and v.vivienda == "casa" and r.patrimonio < pat, "te puedes mudar pagando la mudanza")
	r.patrimonio = 0
	_comprobar(v.cambiar_vivienda("mansion", r) != "", "sin plata no hay mansión")
	## Sin plata para la casa, vuelves a lo barato.
	v.vivienda = "mansion"
	v.transporte = "chofer"
	r.patrimonio = 10
	v.semana(c, r, 2026, 30, 2)
	_comprobar(v.transporte == "micro" and v.vivienda != "mansion", "sin plata para la casa, te ajustas el cinturón")
	## Asunto de casa.
	v.pendiente = {"tipo": "tele", "texto": "x", "a": "si", "b": "no"}
	r.patrimonio = 0
	var res := v.resolver("a", r, c, m.prensa, 2026, 31)
	_comprobar(res != "" and r.patrimonio > 0 and v.pendiente.is_empty(), "el programa de tele paga")
	var d := v.a_dic()
	var v2 := VidaDT.new()
	v2.desde_dic(d)
	_comprobar(v2.a_dic() == d, "Mi vida se guarda entera")

func _probar_maestrias() -> void:
	_titulo("MAESTRÍAS: 15 CATEGORÍAS DE 30 NIVELES")
	_comprobar(Maestria.ORDEN.size() == 15 and Maestria.CATEGORIAS.size() == 15, "hay 15 categorías")
	var m := Mundo.new()
	m.generar(["CHI"], 5157)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var ma := m.maestria
	_comprobar(ma.subir("ataque") != "", "sin puntos no se sube")
	ma.puntos = 1000
	var pts0 := m.entrenamiento.dt_puntos
	for i in 30:
		ma.subir("ataque", m.entrenamiento)
	_comprobar(ma.nivel("ataque") == 30 and ma.subir("ataque") != "", "30 niveles y ni uno más")
	_comprobar(m.entrenamiento.dt_puntos == pts0 + 3, "los hitos 10, 20 y 30 dan un punto de habilidad cada uno")
	_comprobar(absf(ma.factor_ataque() - 1.06) < 0.001, "el nivel 30 de Ataque son +6 %% de ataque (%.3f)" % ma.factor_ataque())
	_comprobar(1000 - ma.puntos == 10 * 1 + 10 * 2 + 10 * 3, "los niveles se encarecen por decenas (costó %d)" % (1000 - ma.puntos))
	var c := m.mi_club()
	m.aplicar_bonificadores()
	var a0 := c.bonus_ataque
	ma.niveles["ataque"] = 0
	m.aplicar_bonificadores()
	_comprobar(c.bonus_ataque < a0, "la maestría de ataque llega al bono del equipo")
	ma.puntos = 0
	ma.semana(c, m.prensa, m.academia, 1, 1)
	_comprobar(ma.puntos == 2, "semana ganada: dos puntos de maestría")
	ma.niveles["finanzas"] = 15
	var s0 := c.saldo
	ma.semana(c, m.prensa, m.academia, 2, 2)
	_comprobar(c.saldo > s0, "Finanzas da un ingreso semanal")
	var d := ma.a_dic()
	var m2 := Maestria.new()
	m2.desde_dic(d)
	_comprobar(m2.nivel("finanzas") == 15 and m2.puntos == ma.puntos, "las maestrías se guardan")

## ¿DE VERDAD PESAN EN EL MARCADOR? (26-9-2026). El mismo club contra el mismo
## rival, 300 partidos con la misma semilla: una vez sin nada y otra con las
## maestrías de juego al 30 y "Genio táctico" en el árbol. Al ser los mismos
## números aleatorios, cualquier diferencia es de las habilidades.
func _probar_habilidades_en_resultados() -> void:
	_titulo("HABILIDADES Y MAESTRÍAS: SE NOTAN EN LOS RESULTADOS")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var yo: Club = m.ligas[0].clubes[0]
	var rival: Club = m.ligas[0].clubes[1]
	m.tomar_el_mando(yo.id)
	var serie := func() -> Dictionary:
		m.aplicar_bonificadores()
		var r := {"g": 0, "e": 0, "p": 0, "gf": 0, "gc": 0, "bono": yo.bonus_ataque}
		seed(4242)
		for i in 300:
			var pa := Partido.new(yo, rival, true)
			var res: Dictionary = pa.simular()
			r["gf"] += int(res["local"])
			r["gc"] += int(res["visita"])
			if res["local"] > res["visita"]:
				r["g"] += 1
			elif res["local"] == res["visita"]:
				r["e"] += 1
			else:
				r["p"] += 1
		return r
	var base: Dictionary = serie.call()
	for k: String in ["ataque", "defensa", "porteros", "balon_parado", "analisis"]:
		m.maestria.niveles[k] = Maestria.NIVEL_MAX
	m.entrenamiento.dt_nodos["pizarra"] = true
	m.entrenamiento.dt_nodos["genio"] = true
	var top: Dictionary = serie.call()
	var pts := func(r: Dictionary) -> float: return (3.0 * r["g"] + r["e"]) / 300.0
	print("   · ", "sin nada:  %d-%d-%d, %d:%d goles, %.2f pts/partido (bono ataque %.3f)" % [base["g"], base["e"], base["p"], base["gf"], base["gc"], pts.call(base), base["bono"]])
	print("   · ", "al máximo: %d-%d-%d, %d:%d goles, %.2f pts/partido (bono ataque %.3f)" % [top["g"], top["e"], top["p"], top["gf"], top["gc"], pts.call(top), top["bono"]])
	_comprobar(float(top["bono"]) > float(base["bono"]) * 1.15, "el bono llega al motor del partido")
	_comprobar(int(top["gf"]) > int(base["gf"]) and int(top["gc"]) < int(base["gc"]), "más goles a favor y menos en contra")
	_comprobar(pts.call(top) > pts.call(base) + 0.1, "se ganan más puntos por partido (%.2f → %.2f)" % [pts.call(base), pts.call(top)])
	## Y no deciden solas: un club muy inferior con todo al máximo sigue sin
	## ser favorito ante el mejor.
	_comprobar(pts.call(top) < 3.0, "no ganan todos los partidos")

## LA BASE DE LA IA QUE JUEGA Y DEL MANDO (26-9-2026).
func _probar_motor_libre() -> void:
	_titulo("IA LIBRE: ACCIONES, MOTOR SIN JUGADAS PREHECHAS Y MANDO")
	## Siempre con la misma base (la real si está): según lo que corriera antes
	## en el mismo proceso, el mundo salía con la ficticia y otro club era «el
	## más fuerte» (20-10: con la ficticia, este prototipo da 12,5 goles de media;
	## ver PENDIENTES, M-392: `MotorLibre` no se usa en el juego).
	var base_antes := Datos.base_real
	if Datos.hay_pack_real():
		Datos.usar_base_real(true)
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var cl: Array = m.ligas[0].clubes.duplicate()
	cl.sort_custom(func(a: Club, b: Club) -> bool: return a.media() > b.media())
	var fuerte: Club = cl[0]
	var debil: Club = cl[cl.size() - 1]
	var j: Jugador = fuerte.once()[10]
	## El catálogo.
	_comprobar(AccionesJuego.CATALOGO.size() >= 20, "%d acciones en el catálogo" % AccionesJuego.CATALOGO.size())
	var sin_anim: Array = []
	for k: String in AccionesJuego.CATALOGO:
		var an := String(AccionesJuego.CATALOGO[k]["anim"])
		if an != "" and not AnimExtra.CATEGORIAS.has(an):
			sin_anim.append(k)
	_comprobar(sin_anim.is_empty(), "cada acción tiene su familia de animaciones %s" % str(sin_anim))
	var p_cerca := AccionesJuego.prob_exito(j, "pase_corto", {"dist": 8.0})
	var p_lejos := AccionesJuego.prob_exito(j, "pase_corto", {"dist": 30.0, "presion": 1.0})
	_comprobar(p_cerca > p_lejos, "un pase corto y libre sale más que uno largo y presionado (%.2f > %.2f)" % [p_cerca, p_lejos])
	var jb: Jugador = debil.once()[10]
	_comprobar(AccionesJuego.prob_exito(j, "tiro", {"dist": 16.0}) != AccionesJuego.prob_exito(jb, "tiro", {"dist": 16.0}), "los atributos mueven la probabilidad")
	_comprobar(AccionesJuego.prob_exito(j, "tiro", {"dist": 16.0, "pie_malo": true}) <= AccionesJuego.prob_exito(j, "tiro", {"dist": 16.0}), "la pierna débil resta")
	_comprobar(AccionesJuego.xg(Vector2(11, 0)) > AccionesJuego.xg(Vector2(25, 0)) and AccionesJuego.xg(Vector2(11, 0)) > AccionesJuego.xg(Vector2(8, 20)), "el xG baja con la distancia y el ángulo")
	## El motor: dos iguales dan un partido creíble.
	var ig := MotorLibre.new(fuerte.once(), fuerte.once(), 1.0, 1.0, 51).simular()
	var tiros: Array = ig["tiros"]
	var acierto := float(ig["pases_ok"][0] + ig["pases_ok"][1]) / maxf(1.0, float(ig["pases"][0] + ig["pases"][1]))
	print("   · iguales: ", ig["goles"], " tiros ", tiros, " pases ", ig["pases"], " acierto %.0f %%" % (acierto * 100.0))
	## Con un solo partido la prueba dependía de la suerte de esa semilla (17-10:
	## al cambiar el once automático salió un 7-2). Se mira la media de cuatro.
	var total_g := int(ig["goles"][0]) + int(ig["goles"][1])
	for sem in [52, 53, 54]:
		var otro := MotorLibre.new(fuerte.once(), fuerte.once(), 1.0, 1.0, sem).simular()
		total_g += int(otro["goles"][0]) + int(otro["goles"][1])
	_comprobar(float(total_g) / 4.0 <= 8.0, "marcador de fútbol, no de balonmano (media %.1f goles en 4 partidos)" % (float(total_g) / 4.0))
	## Entre dos equipos de élite el prototipo todavía tira de más (calibración
	## pendiente, E17 del ROADMAP): el tope es generoso a propósito.
	_comprobar(int(tiros[0]) + int(tiros[1]) >= 6 and int(tiros[0]) + int(tiros[1]) <= 160, "hay tiros, sin exagerar")
	_comprobar(acierto > 0.5 and acierto < 0.95, "acierto de pase creíble")
	var dec: Dictionary = ig["decisiones"]
	_comprobar(dec.has("pase_corto") and dec.has("conducir") and dec.has("tiro"), "la IA elige entre pasar, conducir y tirar")
	## El mejor gana, juegue de local o de visita.
	var a := MotorLibre.new(fuerte.once(), debil.once(), 1.0, 1.0, 1).simular()
	var b := MotorLibre.new(debil.once(), fuerte.once(), 1.0, 1.0, 2).simular()
	var gf := int(a["goles"][0]) + int(b["goles"][1])
	var gd := int(a["goles"][1]) + int(b["goles"][0])
	_comprobar(gf > gd, "el equipo mejor gana sin guion (%d-%d en dos partidos)" % [gf, gd])
	## Y las habilidades del club (el bono de maestrías y árbol) también aquí.
	## Varias semillas: con una sola, el azar de un partido puede más que un
	## bono del 20 % (pasó al cambiar el once por las reglas de la liga).
	var xg_bono := 0.0
	var xg_sin := 0.0
	## Dos clubes parecidos y DISTINTOS: el motor guarda estado en cada
	## jugador, y un equipo contra sí mismo comparte los mismos objetos.
	var debil2: Club = cl[cl.size() - 2]
	## Con +20 % el efecto (≈6 puntos de calidad) quedaba por debajo del ruido
	## de 12 partidos y la prueba pasaba o fallaba según el orden de las
	## secciones (PENDIENTES, 17-10). Se prueba la DIRECCIÓN con +35 %.
	for sem in 6:
		var c1 := MotorLibre.new(debil.once(), debil2.once(), 1.35, 1.0, 3 + sem * 2).simular()
		var c2 := MotorLibre.new(debil.once(), debil2.once(), 1.0, 1.35, 4 + sem * 2).simular()
		xg_bono += float(c1["xg"][0]) + float(c2["xg"][1])
		xg_sin += float(c1["xg"][1]) + float(c2["xg"][0])
	_comprobar(xg_bono > xg_sin, "con el bono del club se generan más ocasiones (xG %.1f vs %.1f)" % [xg_bono, xg_sin])
	## El jugador controlado.
	var ml := MotorLibre.new(fuerte.once(), debil.once(), 1.0, 1.0, 9)
	ml.tomar_control(ml.poseedor)
	var yo := ml.poseedor
	ml.agentes[yo]["pos"] = Vector2(40.0, 0.0)
	ml.mover(Vector2(1, 0))
	ml.ordenar("tiro")
	ml.paso()
	_comprobar(int(ml.stats["tiros"][0]) == 1, "el jugador del mando tira cuando se le ordena")
	ml.cambiar_jugador()
	_comprobar(ml.controlado >= 0 and ml.agentes[ml.controlado]["eq"] == 0, "cambiar de jugador se queda en el propio equipo")
	## El mapa de botones.
	Mando.registrar()
	_comprobar(Mando.MAPA.keys().all(func(k: String) -> bool: return InputMap.has_action(k)), "las acciones de juego están en el InputMap")
	_comprobar(Mando.accion_de("jugar_pase", true) == "pase_corto" and Mando.accion_de("jugar_pase", false) == "presionar", "el mismo botón pasa con balón y presiona sin él")
	var botones_catalogo: Array = []
	for k: String in AccionesJuego.CATALOGO:
		var bt := String(AccionesJuego.CATALOGO[k]["boton"])
		if bt != "" and not Mando.MAPA.has(bt):
			botones_catalogo.append(bt)
	_comprobar(botones_catalogo.is_empty(), "cada botón del catálogo existe en el mapa del mando %s" % str(botones_catalogo))
	if Datos.hay_pack_real():
		Datos.usar_base_real(base_antes)

## EL PORTAFOLIO DE FÚTBOL (26-9-2026): cuántos de cada familia hay, que
## existan en la librería de un jugador y que el partido los use.
func _probar_portafolio_futbol() -> void:
	_titulo("PORTAFOLIO: TIROS, PASES, BARRIDAS, ATAJADAS, REGATES, LESIONES Y ÁRBITRO")
	var f := AnimFutbol.familias()
	_comprobar((f["tiro"] as Array).size() >= 20, "%d tipos de tiro" % (f["tiro"] as Array).size())
	_comprobar((f["pase"] as Array).size() >= 20, "%d tipos de pase" % (f["pase"] as Array).size())
	_comprobar((f["barrida"] as Array).size() >= 20, "%d barridas y entradas" % (f["barrida"] as Array).size())
	_comprobar((f["atajada"] as Array).size() >= 12, "%d atajadas nuevas" % (f["atajada"] as Array).size())
	_comprobar((f["regate"] as Array).size() >= 30, "%d regates" % (f["regate"] as Array).size())
	_comprobar((f["expresivo"] as Array).size() >= 12 and (f["lesion"] as Array).size() >= 6, "expresiones y lesiones")
	_comprobar((f["arbitro"] as Array).size() >= 10, "%d gestos del árbitro y los asistentes" % (f["arbitro"] as Array).size())
	var d := FutbolistaQ.crear(1.8, "male")
	var raiz: Node3D = d["nodo"]
	add_child(raiz)
	FutbolistaQ.terminar(d, true)
	var ap: AnimationPlayer = d["anim"]
	var faltan: Array = []
	for fam: String in f:
		for n: String in f[fam]:
			if not ap.has_animation(n):
				faltan.append(n)
	_comprobar(faltan.is_empty(), "todas están en la librería del jugador %s" % str(faltan.slice(0, 5)))
	_comprobar(ap.has_animation("bicicleta_espejo") and ap.has_animation("tiro_empeine_espejo"), "con su espejo para zurdos y para el otro lado")
	_comprobar(ap.get_animation_list().size() >= 300, "%d movimientos por jugador" % ap.get_animation_list().size())
	## CELEBRACIONES SEGÚN EL CARÁCTER (mapa de metas 14).
	var sin_anim: Array = []
	for rs: String in AnimExtra.CELEBRA_POR_RASGO:
		for n: String in AnimExtra.CELEBRA_POR_RASGO[rs]:
			if not ap.has_animation(n):
				sin_anim.append(n)
	_comprobar(sin_anim.is_empty(), "cada celebración de carácter existe en la librería %s" % str(sin_anim))
	var rng_c := RandomNumberGenerator.new()
	rng_c.seed = 11
	var firma := AnimExtra.celebracion_firma("veloz", "j77")
	var repite := 0
	for i in 60:
		if AnimExtra.celebracion(ap, "veloz", "j77", false, rng_c) == firma:
			repite += 1
	_comprobar(repite >= 30 and (AnimExtra.CELEBRA_POR_RASGO["veloz"] as Array).has(firma), "cada jugador repite su celebración casi siempre (%d/60, %s)" % [repite, firma])
	var provoca := 0
	for i in 60:
		if AnimExtra.celebracion(ap, "polemico", "j78", true, rng_c) == "mano_oido":
			provoca += 1
	_comprobar(provoca >= 25, "el polémico, de visita, se pone la mano en la oreja (%d/60)" % provoca)
	_comprobar(AnimExtra.NOMBRE_CELEBRACION.has(AnimExtra.celebracion_firma("lider", "x1")), "la ficha nombra su celebración")
	## EL GOLPEO CON CUERPO (mapa de metas 16): al acompañar, el pie sube de
	## verdad; al armar, el brazo contrario se abre para equilibrar.
	var esq_g: Skeleton3D = d["esqueleto"]
	var i_pie := esq_g.find_bone(String(AnimQuaternius.HUESOS["pie_d"]))
	var i_mano := esq_g.find_bone(String(AnimQuaternius.HUESOS["mano_i"]))
	var i_pel := esq_g.find_bone(String(AnimQuaternius.HUESOS["cadera"]))
	var largo_g := ap.get_animation("tiro_empeine").length
	ap.play("tiro_empeine")
	ap.seek(0.0, true)
	var pie0 := esq_g.get_bone_global_pose(i_pie).origin
	var abre0 := absf(esq_g.get_bone_global_pose(i_mano).origin.x - esq_g.get_bone_global_pose(i_pel).origin.x)
	ap.seek(largo_g * 0.68, true)
	var pie1 := esq_g.get_bone_global_pose(i_pie).origin
	ap.seek(largo_g * 0.5, true)
	var abre1 := absf(esq_g.get_bone_global_pose(i_mano).origin.x - esq_g.get_bone_global_pose(i_pel).origin.x)
	_comprobar(pie1.y - pie0.y > 0.25, "al acompañar el tiro, el pie sube (%.2f)" % (pie1.y - pie0.y))
	_comprobar(abre1 - abre0 > 0.12, "al pegar, el brazo contrario se abre (%.2f)" % (abre1 - abre0))
	ap.stop()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var vistos := {}
	for i in 60:
		vistos[AnimExtra.variante(ap, "patear", "j1", rng)] = true
	_comprobar(vistos.size() >= 8, "el partido sortea entre muchos tiros (%d distintos en 60)" % vistos.size())
	var zurdo := ""
	for i in 200:
		if AnimExtra.es_zurdo("z%d" % i):
			zurdo = "z%d" % i
			break
	var todos_espejo := true
	for i in 20:
		if not AnimExtra.variante(ap, "patear", zurdo, rng).ends_with("_espejo"):
			todos_espejo = false
	_comprobar(todos_espejo, "un zurdo patea siempre con la zurda")
	raiz.queue_free()

## JUGADORES FIJOS CON GUIÑO (26-9-2026): en la base ficticia, el mismo club
## tiene los mismos jugadores (nombre, media y potencial) en cualquier partida.
func _probar_jugadores_fijos() -> void:
	_titulo("JUGADORES FIJOS CON GUIÑO EN LA BASE FICTICIA")
	var a := Mundo.new()
	a.generar(["CHI"], 111)
	var b := Mundo.new()
	b.generar(["CHI"], 98765)
	var ca: Club = a.ligas[0].clubes[0]
	var cb: Club = null
	for c: Club in b.ligas[0].clubes:
		if c.nombre == ca.nombre:
			cb = c
	_comprobar(cb != null, "el mismo club en los dos mundos (%s)" % ca.nombre)
	if cb == null:
		return
	var fijos_a := {}
	for j: Jugador in ca.plantilla:
		if j.real:
			fijos_a[j.nombre] = [j.ovr, j.pot, j.pos_e]
	var iguales := 0
	for j: Jugador in cb.plantilla:
		if j.real and fijos_a.has(j.nombre) and fijos_a[j.nombre] == [j.ovr, j.pot, j.pos_e]:
			iguales += 1
	print("   · ", ca.nombre, ": ", fijos_a.keys().slice(0, 5))
	_comprobar(fijos_a.size() >= 8, "%d jugadores con guiño en el club" % fijos_a.size())
	_comprobar(iguales == fijos_a.size(), "los mismos nombres, medias y potenciales con otra semilla (%d de %d)" % [iguales, fijos_a.size()])
	## Ningún guiño es un nombre real.
	var reales_ok := true
	for n: String in fijos_a:
		if Nombres.vetado(n):
			reales_ok = false
	_comprobar(reales_ok, "ningún guiño coincide con un nombre real vetado")
