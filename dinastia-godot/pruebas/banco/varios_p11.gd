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
