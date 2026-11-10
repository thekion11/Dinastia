extends "res://pruebas/banco/varios_p10.gd"
## [Capa 11 de `varios.gd`, 10-11] _probar_final_temporada, _probar_habilidades_y_calor, _probar_puerta_animada, _probar_flecha_forma, _probar_quimica_linea, _probar_objetivo_directiva, _probar_jugador_del_mes, _probar_estrategia_rapida (secciones del 10-11)

## EL FINAL DE TEMPORADA COMPLETO (10-11, orden del dueño): copa y continental a medias se juegan hasta el final antes del cierre, y la pantalla única
## de resumen tiene campeón, tu puesto, copa, continental, ascensos/descensos, premios y veredicto.
func _probar_final_temporada() -> void:
	_titulo("FINAL DE TEMPORADA: TORNEOS PENDIENTES Y PANTALLA ÚNICA DE RESUMEN")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 52)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	var guard := 0
	while m.temporada_en_curso() and guard < 80:
		m.avanzar_semana()
		guard += 1
	_comprobar(not m.temporada_en_curso(), "la liga termina (%d semanas)" % guard)
	m._montar_copa()   ## una copa recién sorteada = a medias al terminar la liga
	_comprobar(m.copa != null and m.copa.en_curso() and CierreTorneos.hay_pendientes(m), "con la liga terminada queda una copa a medias")
	var cerrados := CierreTorneos.cerrar_pendientes(m)
	_comprobar(m.copa.campeon != null and not CierreTorneos.hay_pendientes(m) and not cerrados.is_empty(), "se juega hasta el final y tiene campeón (%s)" % (m.copa.campeon.nombre if m.copa.campeon else "—"))
	_comprobar(CierreTorneos.cerrar_pendientes(m).is_empty(), "cerrar dos veces no juega nada la segunda")
	var foto := CierreTorneos.foto(m)
	_comprobar(int(foto.get("puesto", 0)) >= 1 and foto.get("copa_campeon") == m.copa.campeon, "la foto guarda tu puesto (%d.º) y el campeón de copa" % int(foto.get("puesto", 0)))
	var resumen := m.nueva_temporada()
	var d := ResumenTemporada.datos(foto, resumen)
	_comprobar(d["campeon"] is Club and int(d["puesto"]) >= 1 and int(d["equipos"]) > 2, "el resumen tiene campeón de liga y tu puesto de %d" % int(d["equipos"]))
	_comprobar(d["copa_campeon"] is Club and String(d["copa"]) != "", "y la copa con su campeón (%s)" % String(d["copa"]))
	var pais := m.mi_club().pais
	var solo_mi_pais := true
	for c: Club in (d["suben"] as Array) + (d["bajan"] as Array):
		solo_mi_pais = solo_mi_pais and c.pais == pais
	_comprobar(solo_mi_pais and not (d["suben"] as Array).is_empty(), "ascensos y descensos de tu país (%d suben)" % (d["suben"] as Array).size())
	_comprobar(not (d["directiva"] as Dictionary).is_empty() and d.has("premios"), "con el veredicto de la directiva y los premios de la gala")

## MAPA DE CALOR Y HABILIDADES CON ESTRELLAS DE LA PLANTILLA (10-11, como la «Información del jugador» del PES).
func _probar_habilidades_y_calor() -> void:
	_titulo("PLANTILLA: HABILIDADES CON ESTRELLAS Y MAPA DE CALOR")
	var j := Jugador.new()
	j.id = "prueba_ext"; j.pos = "DEL"; j.pos_e = "ED"; j.ovr = 84; j.edad = 26
	j.atributos = {"rit": 95, "tir": 80, "pas": 78, "reg": 94, "def": 35, "fis": 66}
	var h := HabilidadesJugador.de(j)
	var ids: Array = h.map(func(x: Dictionary) -> String: return String(x["id"]))
	_comprobar(not h.is_empty() and h.size() <= HabilidadesJugador.MAXIMO and ids.has("regate_prof"), "un extremo regateador tiene «Regate en profundidad» (%s)" % ", ".join(ids))
	_comprobar(int(h[0]["estrellas"]) == 3 and not ids.has("marcaje") and not ids.has("reflejos"), "con 3 estrellas en lo mejor, y sin habilidades de defensa ni de portero")
	_comprobar(HabilidadesJugador.de(j) == h, "es determinista: el mismo jugador da las mismas estrellas")
	var por := Jugador.new()
	por.id = "prueba_por"; por.pos = "POR"; por.pos_e = "POR"; por.ovr = 82; por.edad = 33; por.capitan = true
	por.atributos = {"div": 85, "par": 84, "saq": 70, "ref": 88, "vel": 60, "pos": 80}
	var hp: Array = HabilidadesJugador.de(por).map(func(x: Dictionary) -> String: return String(x["id"]))
	var solo_por := true
	for id: String in hp:
		solo_por = solo_por and id in ["saque_largo", "parada_penal", "salida", "reflejos", "liderazgo"]
	_comprobar(solo_por and hp.has("reflejos") and hp.has("liderazgo"), "el portero solo tiene las suyas, y el capitán veterano «Liderazgo» (%s)" % ", ".join(hp))
	var flojo := Jugador.new()
	flojo.id = "prueba_flojo"; flojo.pos = "MED"; flojo.pos_e = "MC"; flojo.ovr = 48
	flojo.atributos = {"rit": 50, "tir": 45, "pas": 50, "reg": 48, "def": 47, "fis": 50}
	_comprobar(HabilidadesJugador.de(flojo).is_empty(), "un jugador flojo no tiene habilidades destacadas")
	## El mapa de calor: lo más caliente cae en su zona (extremo derecho arriba a la derecha; portero abajo al centro).
	for par: Array in [[j, "ED"], [por, "POR"]]:
		var a := MapaCalorJugador.intensidades(par[0])
		var mejor := 0
		for i in a.size():
			if a[i] > a[mejor]:
				mejor = i
		var x := (float(mejor % MapaCalorJugador.COLS) + 0.5) / MapaCalorJugador.COLS
		var y := (float(mejor / MapaCalorJugador.COLS) + 0.5) / MapaCalorJugador.FILAS
		var z: Array = MapaCalorJugador.ZONAS[par[1]]
		_comprobar(absf(x - float(z[0])) < 0.15 and absf(y - float(z[1])) < 0.12 and is_equal_approx(a[mejor], 1.0), "el mapa de calor del %s se concentra en su zona (%.2f, %.2f)" % [par[1], x, y])
	j.pos_sec = ["MD"]
	var a2 := MapaCalorJugador.intensidades(j)
	var celda_md := int(0.46 * MapaCalorJugador.FILAS) * MapaCalorJugador.COLS + int(0.85 * MapaCalorJugador.COLS)
	_comprobar(a2[celda_md] > MapaCalorJugador.intensidades(Jugador.new())[celda_md] and a2[celda_md] >= 0.4, "la posición secundaria también se calienta (%.2f)" % a2[celda_md])

## LA PUERTA QUE SE ABRE AL ACERCARSE (10-11): la hoja de cada puerta del club gira abierta con el observador cerca (misma planta) y cerrada lejos.
func _probar_puerta_animada() -> void:
	_titulo("CLUB: PUERTAS QUE SE ABREN AL ACERCARSE")
	var p := PuertaAnimada.new()
	p.centro_local = Vector3(2.0, 1.2, 0.0)
	_comprobar(is_equal_approx(p.abrir_ahora_segun(Vector3(2.5, 1.7, 1.0)), PuertaAnimada.ABIERTA), "cerca y en la misma planta: abierta")
	_comprobar(is_zero_approx(p.abrir_ahora_segun(Vector3(9.0, 1.7, 4.0))), "lejos: cerrada")
	_comprobar(is_zero_approx(p.abrir_ahora_segun(Vector3(2.0, 6.0, 0.5))), "justo encima, en otra planta: cerrada")
	var sala := Node3D.new()
	PuertasClub.poner(sala, [Vector2(0.0, 1.6)], 0.0, 0.0, Color.RED)
	var hay := sala.get_children().filter(func(n: Node) -> bool: return n is PuertaAnimada)
	_comprobar(hay.size() == 1 and is_equal_approx((hay[0] as PuertaAnimada).rotation.y, PI), "cada hueco lleva su hoja animada, abierta de salida (sin cámara no se mueve)")
	sala.free()
	p.free()

## LA FLECHA DE FORMA (10-11): 5 estados según `Jugador.forma`, de ↓ a ↑.
func _probar_flecha_forma() -> void:
	_titulo("PLANTILLA: FLECHA DE FORMA")
	var j := Jugador.new()
	var vistos: Array = []
	for f: int in [10, 35, 50, 70, 95]:
		j.forma = f
		vistos.append(FlechaForma.FLECHAS[FlechaForma.nivel(j)])
	_comprobar(vistos == ["↓", "↘", "→", "↗", "↑"], "de muy baja a en racha: %s" % "".join(vistos))

## LA QUÍMICA ENTRE COMPAÑEROS DE LÍNEA (10-11): solo lectura para la interfaz; mismo país y temporadas juntos suben, y hay una cifra por línea.
func _probar_quimica_linea() -> void:
	_titulo("PLANTILLA: QUÍMICA ENTRE COMPAÑEROS DE LÍNEA")
	var m := Mundo.new()
	m.generar(["CHI"], 61)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	var a: Jugador = club.plantilla[1]
	var b: Jugador = club.plantilla[2]
	a.historial.clear(); b.historial.clear()
	a.moral = 60; b.moral = 60
	b.pais = "ARG" if a.pais != "ARG" else "URU"
	var base := QuimicaLinea.par(m, a, b)
	b.pais = a.pais
	var mismo_pais := QuimicaLinea.par(m, a, b)
	for k in 3:
		a.registrar_temporada(2020 + k, club.nombre)
		b.registrar_temporada(2020 + k, club.nombre)
	var veteranos := QuimicaLinea.par(m, a, b)
	_comprobar(mismo_pais > base and veteranos > mismo_pais and veteranos <= 100, "el mismo país y las temporadas juntos suben la química (%d → %d → %d)" % [base, mismo_pais, veteranos])
	var lin := QuimicaLinea.lineas(m, club.once())
	_comprobar(lin.has("DEF") and lin.has("MED") and lin.has("DEL") and not lin.has("POR"), "una cifra por línea del once, sin el portero (%s)" % str(lin))

## EL OBJETIVO DE LA DIRECTIVA A LA VISTA (10-11): la barra se llena dentro de la meta y se acorta lejos de ella.
func _probar_objetivo_directiva() -> void:
	_titulo("MENÚ CENTRAL: OBJETIVO DE LA DIRECTIVA CON BARRA")
	_comprobar(ObjetivoDirectiva.progreso(3, 4, 16) == 100 and ObjetivoDirectiva.progreso(0, 4, 16) == 50, "dentro de la meta: llena; sin jugar: a la mitad")
	var cerca := ObjetivoDirectiva.progreso(6, 4, 16)
	var lejos := ObjetivoDirectiva.progreso(15, 4, 16)
	_comprobar(cerca > lejos and lejos >= 5 and cerca < 100, "fuera de la meta, cuanto más lejos, más corta (6.º: %d, 15.º: %d)" % [cerca, lejos])
	var m := Mundo.new()
	m.generar(["CHI"], 62)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var f := ObjetivoDirectiva.fila(m, m.mi_club(), m.liga_de(m.mi_club()))
	_comprobar(f != null and f.find_children("*", "ProgressBar", true, false).size() == 1, "con un club en marcha sale la fila con su barra")
	if f != null:
		f.free()

## EL JUGADOR DEL MES (10-11): cada 4 semanas, el mejor de tu liga por sus últimas notas; queda en su ficha.
func _probar_jugador_del_mes() -> void:
	_titulo("JUGADOR DEL MES")
	var m := Mundo.new()
	m.generar(["CHI"], 63)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var antes := 0
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			antes += j.premios.filter(func(p: Dictionary) -> bool: return String(p.get("premio", "")) == "Jugador del mes").size()
	for k in 8:
		m.avanzar_semana()
	var despues := 0
	for c2: Club in m.clubes.values():
		for j2: Jugador in c2.plantilla:
			despues += j2.premios.filter(func(p: Dictionary) -> bool: return String(p.get("premio", "")) == "Jugador del mes").size()
	_comprobar(despues - antes == 2, "en 8 semanas hay 2 jugadores del mes (%d)" % (despues - antes))
	var g := PremioMensual.elegir(m)
	_comprobar(g != null and g.notas.size() >= PremioMensual.MINIMO_NOTAS and m.liga_de(m.mi_club()).clubes.any(func(c3: Club) -> bool: return c3.id == g.club_id), "el elegido es de tu liga y tiene notas suficientes")

## LAS ESTRATEGIAS RÁPIDAS DEL PARTIDO (10-11): preajustes de las 4 palancas de la pizarra; volver a pulsar recupera el plan; hay espera entre cambios.
func _probar_estrategia_rapida() -> void:
	_titulo("PARTIDO: ESTRATEGIAS RÁPIDAS")
	var club := Club.new()
	club.tactica = Tactica.new()
	EstrategiaRapida.poner(club.tactica, [1, 1, 1, 1])
	var e := EstrategiaRapida.new()
	_comprobar(e.aplicar(club, "ataque", 10) == "" and EstrategiaRapida.foto(club.tactica) == [2, 2, 2, 2] and e.activa == "ataque", "«Ataque total» sube las cuatro palancas")
	_comprobar(e.aplicar(club, "cerrojo", 11) == "espera" and e.activa == "ataque", "hay que esperar %d minutos para otro cambio" % EstrategiaRapida.ESPERA)
	_comprobar(e.aplicar(club, "cerrojo", 13) == "" and EstrategiaRapida.foto(club.tactica) == [0, 0, 0, 0], "«Cerrojo» las baja todas")
	_comprobar(e.aplicar(club, "cerrojo", 16) == "" and EstrategiaRapida.foto(club.tactica) == [1, 1, 1, 1] and e.activa == "", "pulsar la activa devuelve el plan de antes")

## OBJETIVOS POR CLUB (10-11, encargo del dueño): cada club recibe un paquete propio (liga ajustada a su tamaño y plazas, varios secundarios con peso, proyecto a
## 3 temporadas). Se prueba con VARIOS países y clubes (regla 34), el cierre que mueve la confianza y el guardado (también el viejo sin los campos nuevos).
func _probar_objetivos_por_club() -> void:
	_titulo("OBJETIVOS POR CLUB: PAQUETE PROPIO, CIERRE Y GUARDADO")
	var distintos := {}
	var mal: Array[String] = []
	var clubes := 0
	var metas_desc := {}
	for grupo: Array in [["CHI", "ESP", "ENG"], ["BRA", "JPN", "USA"], ["ARG", "GER", "MEX"]]:
		Partido.limpiar_contexto()
		var m := Mundo.new()
		var g: Array[String] = []
		g.assign(grupo)
		m.generar(g, 91 + clubes)
		for l: Liga in m.ligas:
			var n := l.clubes.size()
			var pl := ObjetivosClub.plazas_continentales(l.pais, n)
			for c: Club in l.clubes:
				var p := ObjetivosClub.generar(m, c)
				clubes += 1
				if p.is_empty():
					mal.append("%s sin paquete" % c.nombre)
					continue
				var pr: Dictionary = p["principal"]
				var meta := int(pr["meta"])
				if meta < 1 or meta > n:
					mal.append("%s (%d clubes): meta %d" % [c.nombre, n, meta])
				if String(pr["texto"]) == "Evitar el descenso":
					metas_desc[n] = meta
					if meta != n - l.plazas_descenso:
						mal.append("%s: salvarse es el %d.º y la meta es %d" % [c.nombre, n - l.plazas_descenso, meta])
				if String(pr["texto"]).begins_with("Clasificar") and c.division == 1 and meta > int(pl["elite"]) + int(pl["segunda"]):
					mal.append("%s: pide %d plazas continentales y la liga da %d" % [c.nombre, meta, int(pl["elite"]) + int(pl["segunda"])])
				var sec: Array = p["secundarios"]
				if sec.size() < 3 or sec.size() > 6 or (p["proyecto"] as Dictionary).is_empty():
					mal.append("%s: %d secundarios o sin proyecto" % [c.nombre, sec.size()])
				var ids: Array = []
				for o: Dictionary in sec:
					ids.append(String(o["id"]))
					if int(o["peso"]) < 1 or int(o["peso"]) > 10:
						mal.append("%s: peso %d" % [c.nombre, int(o["peso"])])
				distintos["%s|%s|%s" % [pr["texto"], str(ids), (p["proyecto"] as Dictionary)["id"]]] = true
	_comprobar(mal.is_empty(), "%d clubes de 9 países: meta dentro de su liga, salvarse = puesto seguro real, plazas continentales reales, 3-6 secundarios con peso y proyecto (%d fallos%s)" % [clubes, mal.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 3))])
	_comprobar(distintos.size() >= 8, "los paquetes se parecen poco entre clubes (%d combinaciones distintas)" % distintos.size())
	_comprobar(metas_desc.keys().size() < 2 or metas_desc.values().min() != metas_desc.values().max(), "«Evitar el descenso» cambia con el tamaño de la liga (%s)" % str(metas_desc))
	var esp := ObjetivosClub.plazas_continentales("ESP", 20)
	var chi := ObjetivosClub.plazas_continentales("CHI", 16)
	_comprobar(int(esp["elite"]) == 4 and int(chi["elite"]) == 3, "ESP da 4 plazas de Champions y CHI 3 de Libertadores (%d y %d)" % [int(esp["elite"]), int(chi["elite"])])
	## El tamaño de la liga manda: el colista de una liga de 12, 20 o 24 con 2, 3 y 4 descensos (las ligas generadas hoy son de 16).
	var chico := Club.new()
	chico.pais = "ESP"
	chico.division = 1
	var salv: Array[int] = []
	for caso: Array in [[12, 2], [20, 3], [24, 4]]:
		var pe := ObjetivosClub.principal(chico, int(caso[0]), int(caso[0]), int(caso[1]), ObjetivosClub.plazas_continentales("ESP", int(caso[0])))
		salv.append(int(pe["meta"]))
	_comprobar(salv == [10, 17, 20] and String(ObjetivosClub.principal(chico, 1, 20, 3, {"elite": 4, "segunda": 3})["texto"]) == "Salir campeón", "el colista debe salvarse según su liga: 12→10.º, 20 (3 descensos)→17.º, 24 (4 descensos)→20.º (%s) y el favorito, el título" % str(salv))
	## EL CIERRE
	var m2 := Mundo.new()
	m2.generar(["CHI", "ESP"], 77)
	m2.tomar_el_mando(m2.ligas[1].clubes[4].id)
	var d := m2.directiva
	_comprobar(d.objetivos.size() >= 3 and not d.proyecto.is_empty() and d.meta_puesto >= 1, "el club del jugador trae su paquete (%d secundarios, proyecto «%s»)" % [d.objetivos.size(), String(d.proyecto.get("texto", ""))])
	var c2 := m2.mi_club()
	d.objetivos.clear()
	d.proyecto = {}
	d.bases = {"saldo": 0, "socios": 100}
	d.objetivos.append({"id": "eco", "tipo": "economia", "texto": "Salir de los números rojos", "meta": 0, "peso": 8})
	d.objetivos.append({"id": "cantera", "tipo": "cantera", "texto": "x", "meta": 99, "peso": 5})
	d.confianza = 50
	c2.saldo = 5000000
	var r := ObjetivosCierre.cerrar(m2, d, 5, false)
	_comprobar(int(r["delta"]) == 8 - 5 and d.confianza == 53, "cumplir la economía (+8) y fallar la cantera (−5) mueve la confianza +3 (%d)" % d.confianza)
	d.proyecto = {"id": "sanear", "texto": "Sanear", "meta": 0, "temporadas": 3, "cierres": 2, "mejor_puesto": 0, "titulos": 0, "puesto_base": 5, "saldo_base": -1}
	d.objetivos.clear()
	var r2 := ObjetivosCierre.cerrar(m2, d, 5, false)
	_comprobar(bool((r2["proyecto"] as Dictionary).get("cumplido", false)) and int(r2["delta"]) == ObjetivosClub.PESO_PROYECTO_OK, "al cerrar la 3.ª temporada el proyecto saneado suma +%d" % ObjetivosClub.PESO_PROYECTO_OK)
	## GUARDADO: el paquete sobrevive y una partida vieja (sin los campos) abre con el suyo.
	d.generar_objetivos(m2)
	var textos: Array = d.objetivos.map(func(o: Dictionary) -> String: return String(o["texto"]))
	var inst: Dictionary = JSON.parse_string(JSON.stringify(Partida.instantanea(m2)))
	var m3 := Partida.desde_instantanea(inst)
	_comprobar(m3.directiva.objetivos.map(func(o: Dictionary) -> String: return String(o["texto"])) == textos and String(m3.directiva.proyecto.get("id", "")) == String(d.proyecto.get("id", "")), "los objetivos y el proyecto sobreviven a guardar y cargar")
	for k: String in ["objetivos", "proyecto", "bases"]:
		(inst["directiva"] as Dictionary).erase(k)
	var m4 := Partida.desde_instantanea(inst)
	_comprobar(m4.directiva.objetivos.size() >= 3 and m4.directiva.meta_puesto == d.meta_puesto, "una partida vieja sin los campos nuevos abre y estrena los objetivos de su club")
