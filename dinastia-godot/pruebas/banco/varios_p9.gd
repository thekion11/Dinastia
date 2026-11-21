extends "res://pruebas/banco/varios_p9_h.gd"
## [Capa 9/10 de `varios.gd`] _probar_politica_c15, _probar_historia_c4, _probar_vida_dt, _probar_maestrias, _probar_habilidades_en_resultados, _probar_motor_libre … (+1)

func _probar_politica_c15() -> void:
	_titulo("C15: POLÍTICA Y ESTADO (FICTICIA Y NEUTRAL)")
	_pc_estructura()
	var m := Mundo.new()
	m.generar(["CHI"], 5152)
	var st := _pc_gobierno(m)
	_pc_apoyo(m, st["c"])
	_pc_saudi(m, st)

func _probar_historia_c4() -> void:
	_titulo("C4: HISTORIA DE LOS CLUBES, CON GUIÑO AL REAL")
	Datos.usar_base_real(false)
	var m := Mundo.new()
	m.generar(["CHI"], 5153)
	var clubes: Array = m.ligas[0].clubes
	var por_nombre := {}
	for c: Club in m.clubes.values():
		por_nombre[c.nombre] = c
	var lautaro: Club = por_nombre.get("Lautaro FC")
	var andina: Club = por_nombre.get("U. Andina")
	var precord: Club = por_nombre.get("Precordillera")
	_comprobar(lautaro != null and andina != null and precord != null, "están los tres grandes de la base ficticia")
	var hl := HistoriaClub.de(lautaro, clubes)
	_comprobar(bool(hl["con_guino"]) and String(hl["estadio"]) == "la Ruca" and int(hl["fundado"]) == 1925, "Lautaro FC guiña a su original: fundado en 1925, juega en la Ruca")
	_comprobar(HistoriaClub.nombre_clasico("Lautaro FC", "U. Andina") == "Superclásico", "Lautaro-Andina es el Superclásico")
	_comprobar(HistoriaClub.nombre_clasico("U. Andina", "Precordillera") == "Clásico Universitario", "Andina-Precordillera es el Clásico Universitario")
	_comprobar(HistoriaClub.nombre_clasico("Precordillera", "Lautaro FC") == "el Clásico", "Precordillera-Lautaro es el Clásico")
	_comprobar(m.es_clasico(lautaro, andina), "y el juego lo trata como clásico")
	## Todos los clubes del mundo tienen historia con guiño.
	var m2 := Mundo.new()
	m2.generar([], 5155)
	var sin := 0
	var faltan: Array = []
	for c: Club in m2.clubes.values():
		if HistoriaClub.dato(c.nombre).is_empty():
			sin += 1
			faltan.append(c.nombre)
	if sin > 0:
		print("    sin historia: ", faltan)
	_comprobar(sin == 0, "los %d clubes tienen su fila de historia (%d sin ella)" % [m2.clubes.size(), sin])
	var grande: Club = clubes[0]
	var chico: Club = clubes[clubes.size() - 1]
	_comprobar(int(HistoriaClub.de(grande, clubes)["titulos"]) > int(HistoriaClub.de(chico, clubes)["titulos"]), "el grande tiene más títulos que el chico")
	var rep1_a = HistoriaClub.de(grande, clubes)
	var rep1_b = HistoriaClub.de(grande, clubes)
	_comprobar(rep1_a == rep1_b, "el mismo club tiene siempre la misma historia")
	## (12-11) Coherencia con el año de fundación en TODOS los clubes: ni más títulos que años de vida dan, ni época dorada anterior al club.
	var raros: Array = []
	for c9: Club in m2.clubes.values():
		var h9 := HistoriaClub.de(c9, [])
		var anio9 := int(h9["fundado"])
		var ep9 := String(h9["epoca"])
		var antes := false
		for i9 in HistoriaClub.EPOCA.size():
			antes = antes or (ep9.contains(String(HistoriaClub.EPOCA[i9])) and 1950 + i9 * 10 < anio9 + 5)
		if int(h9["titulos"]) > maxi(0, (2025 - anio9) / 3) or antes:
			raros.append(c9.nombre)
	_comprobar(raros.is_empty(), "ningún club tiene una historia imposible para su año de fundación (%d: %s)" % [raros.size(), str(raros.slice(0, 5))])
	_comprobar(HistoriaClub.color_de("#ffffff") == "blanco" and HistoriaClub.color_de("#d50032") == "rojo" and HistoriaClub.color_de("#003da5") == "azul", "el apodo generado sale del color")
	m.tomar_el_mando(clubes[0].id)
	var t := m.prensa.titular_prensa(true, false, true, "x", "Superclásico")
	_comprobar(String(t["tit"]).begins_with("SUPERCLÁSICO: "), "la portada dice SUPERCLÁSICO")
	## Con el pack real, los mismos datos con los nombres reales.
	if Datos.hay_pack_real():
		Datos.usar_base_real(true)
		_comprobar(int(HistoriaClub.dato("C0lo-C0lo").get("fundado", 0)) == 1925 and HistoriaClub.nombre_clasico("C0lo-C0lo", "U. de Ch1le") == "Superclásico", "con el pack real: Colo-Colo 1925 y el Superclásico con la U")
		Datos.usar_base_real(false)

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
			## (19-11) Sin pasar semanas, sanciones y lesiones se acumulan: con «menos de siete» también en el saque, el rival acababa
			## perdiendo 3-0 de mesa todos los partidos. Como en `_probar_partidos` (4-11), cada uno sale sano: se mide la habilidad, no el desgaste.
			for c: Club in [yo, rival]:
				for j: Jugador in c.plantilla:
					j.suspension = 0
					j.lesion = 0
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
	_ml_preparar()
	_ml_catalogo()
	_ml_motor_iguales()
	_ml_el_mejor()
	_ml_bono()
	_ml_mando()
	_ml_restaurar()

## EL PORTAFOLIO DE FÚTBOL (26-9-2026): cuántos de cada familia hay, que
## existan en la librería de un jugador y que el partido los use.
func _probar_portafolio_futbol() -> void:
	_titulo("PORTAFOLIO: TIROS, PASES, BARRIDAS, ATAJADAS, REGATES, LESIONES Y ÁRBITRO")
	_pf_familias()
	_pf_libreria()
	_pf_celebraciones()
	_pf_golpeo()
	_pf_variantes()
	_pf_raiz.queue_free()
