extends "res://pruebas/banco/varios_p9.gd"
## [Capa 10b de `varios.gd`, 9-11] _probar_capitulos, _probar_ascensor_viaje, _probar_fila_proximos (secciones nuevas de la reestructuración «solo club»)

## LOS CAPÍTULOS DE CADA TEMPORADA (9-11): el documental de cada año se archiva en la partida y sobrevive a guardar y cargar.
func _probar_capitulos() -> void:
	_titulo("CAPÍTULOS DE CADA TEMPORADA (ARCHIVO EN LA PARTIDA)")
	var m := Mundo.new()
	m.generar(["CHI"], 404)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var rival: Club = m.ligas[0].clubes[2]
	var guion: Array = [
		{"titulo": "Portada", "texto": "Un año entero.", "tipo": "escudo", "ref": m.mi_club()},
		{"titulo": "Capítulo 3 · La noche grande", "texto": "3-0 al rival.", "tipo": "rival", "ref": rival}]
	CapitulosTemporadas.archivar(m, 2026, guion)
	CapitulosTemporadas.archivar(m, 2027, guion)
	CapitulosTemporadas.archivar(m, 2026, guion)   ## el mismo año se reescribe, no se duplica
	_comprobar(CapitulosTemporadas.anios(m) == [2027, 2026], "dos temporadas archivadas, la más reciente primero (%s)" % str(CapitulosTemporadas.anios(m)))
	var m2 := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(Partida.instantanea(m))))
	_comprobar(CapitulosTemporadas.anios(m2) == [2027, 2026], "los capítulos sobreviven a guardar y cargar (%s)" % str(CapitulosTemporadas.anios(m2)))
	var caps := CapitulosTemporadas.reconstruir(m2, 2026)
	_comprobar(caps.size() == 2 and String(caps[1]["texto"]) == "3-0 al rival." and caps[1]["ref"] is Club and (caps[1]["ref"] as Club).id == rival.id,
		"el capítulo vuelve con su texto y su rival (escudo) tras cargar")

## EL ASCENSOR SUBE Y BAJA (9-11, vídeo del dueño): el viaje es gradual (no un teletransporte), dura según las plantas y termina en la planta pedida.
func _probar_ascensor_viaje() -> void:
	_titulo("EL ASCENSOR DEL CLUB: VIAJE GRADUAL")
	var cuerpo := Node3D.new()
	add_child(cuerpo)
	cuerpo.position.y = RecorridoClub.y_de(0)
	var llego := [false]
	var tw := AscensorViaje.viajar(cuerpo, 0, 2, func() -> void: llego[0] = true)
	_comprobar(tw != null and not llego[0], "el viaje arranca sin haber llegado todavía")
	tw.custom_step(AscensorViaje.duracion(0, 2) * 0.5)
	var y_medio := cuerpo.position.y
	_comprobar(y_medio > RecorridoClub.y_de(0) + 0.1 and y_medio < RecorridoClub.y_de(2) - 0.1, "a mitad del viaje está entre las dos plantas (y %.2f)" % y_medio)
	tw.custom_step(AscensorViaje.duracion(0, 2))
	_comprobar(llego[0] and is_equal_approx(cuerpo.position.y, RecorridoClub.y_de(2)), "al terminar está en la altura de la planta 2 y avisa")
	_comprobar(AscensorViaje.duracion(0, 2) > AscensorViaje.duracion(0, 1) and AscensorViaje.duracion(0, 0) >= AscensorViaje.SEG_MINIMO, "más plantas, más tiempo")
	cuerpo.queue_free()
	## (9-11) Las puertas de las salas llevan marco (2 jambas + dintel) y una hoja con bisagra: 4 piezas por hueco.
	var sala := Node3D.new()
	add_child(sala)
	PuertasClub.poner(sala, [Vector2(0.0, 1.6), Vector2(5.0, 6.6)], 0.0, 0.0, Color.RED)
	_comprobar(sala.get_child_count() == 8, "dos huecos: marco (3) y hoja con bisagra (1) cada uno (%d piezas)" % sala.get_child_count())
	sala.queue_free()

## LA FILA DE PRÓXIMOS PARTIDOS (9-11, idea del PES 2020): los siguientes partidos de liga de tu club, en orden y con tu club dentro.
func _probar_fila_proximos() -> void:
	_titulo("FILA DE PRÓXIMOS PARTIDOS")
	var m := Mundo.new()
	m.generar(["CHI"], 55)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var lista := FilaProximos.datos(m)
	_comprobar(lista.size() == FilaProximos.CUANTOS, "salen %d próximos partidos (%d)" % [FilaProximos.CUANTOS, lista.size()])
	var seguidas := true
	var contra_si_mismo := false
	for k in lista.size():
		if int(lista[k]["jornada"]) != m.liga_de(m.mi_club()).jornada_actual + 1 + k:
			seguidas = false
		if lista[k]["rival"] == m.mi_club():
			contra_si_mismo = true
	_comprobar(seguidas and not contra_si_mismo, "van en jornadas consecutivas y ninguno es contra uno mismo")
	var caja := HBoxContainer.new()
	add_child(caja)
	FilaProximos.pintar(m, caja)
	_comprobar(caja.get_child_count() >= 1 + 2 * FilaProximos.CUANTOS, "la fila pinta rótulo y una celda con separador por partido (%d nodos)" % caja.get_child_count())
	caja.queue_free()

## INTERCAMBIAR EN EL ONCE DESDE LA PLANTILLA (9-11): titular↔titular cambia de puesto, titular↔reserva sustituye, y no vale con lesionados ni con dos reservas.
func _probar_intercambio_once() -> void:
	_titulo("PLANTILLA A LA PES: INTERCAMBIO EN EL ONCE")
	var m := Mundo.new()
	m.generar(["CHI"], 66)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var club := m.mi_club()
	for j: Jugador in club.plantilla:
		j.lesion = 0
		j.suspension = 0
	var once0: Array[Jugador] = club.once()
	var t1: Jugador = once0[1]
	var t2: Jugador = once0[2]
	var reservas: Array = club.plantilla.filter(func(j: Jugador) -> bool: return not once0.has(j))
	var r1: Jugador = reservas[0]
	var r2: Jugador = reservas[1]
	_comprobar(PlantillaPes.intercambiar(club, t1, t2) and club.once()[1] == t2 and club.once()[2] == t1, "dos titulares se cambian de puesto en el once")
	_comprobar(PlantillaPes.intercambiar(club, t1, r1) and club.once().has(r1) and not club.once().has(t1), "un reserva sustituye a un titular")
	_comprobar(not PlantillaPes.intercambiar(club, t1, r2) and not PlantillaPes.intercambiar(club, t2, t2), "dos reservas, o el mismo jugador, no valen")
	r2.lesion = 3
	_comprobar(not PlantillaPes.intercambiar(club, t2, r2), "no se mete a un lesionado")

## EL PARTIDO DE DESPEDIDA (9-11): al final de la temporada, tu equipo contra los que se retiran esa temporada; el cierre respeta quién se retira.
func _probar_partido_despedida() -> void:
	_titulo("PARTIDO DE DESPEDIDA (FINAL DE TEMPORADA, CONTRA LOS RETIRADOS)")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 88)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var mio := m.mi_club()
	var vistos := {}
	for k in 5:
		var d := PartidoDespedida.escudo_del_anio(2030 + k)
		vistos["%s/%s/%s" % [d["forma"], d["patron"], d["c2"]]] = true
	_comprobar(vistos.size() == 5 and PartidoDespedida.escudo_del_anio(2030) == PartidoDespedida.escudo_del_anio(2035),
		"el escudo de las Leyendas tiene 5 diseños distintos que rotan por temporada (%d)" % vistos.size())
	var leyendas := PartidoDespedida.preparar(m)
	_comprobar(leyendas != null and leyendas.plantilla.size() >= PartidoDespedida.MINIMO_JUGADORES, "hay equipo de leyendas con once o más retirados (%d)" % (leyendas.plantilla.size() if leyendas != null else 0))
	if leyendas == null:
		return
	var ids_leyendas: Array[String] = []
	var todos_retiran := true
	var hay_portero := false
	for j: Jugador in leyendas.plantilla:
		ids_leyendas.append(j.id)
		todos_retiran = todos_retiran and bool(m.prensa.retiros_previstos.get(j.id, false))
		hay_portero = hay_portero or j.pos == "POR"
	_comprobar(todos_retiran and hay_portero, "todos los de las Leyendas son de los que se retiran, y hay portero")
	## El partido de gala (simulado): no cambia lo que pasa a tus jugadores y deja taquilla.
	var foto := PartidoDespedida.foto(mio)
	var saldo0 := mio.saldo
	var p := Partido.new(mio, leyendas)
	p.simular()
	for j: Jugador in mio.plantilla:
		j.lesion = 4   ## una lesión en el partido de gala…
	var res := PartidoDespedida.cerrar(m, p, leyendas, foto)
	var intacto := true
	for j: Jugador in mio.plantilla:
		intacto = intacto and j.lesion == int(foto[j.id]["lesion"])
	_comprobar(intacto, "…no cuenta: tus jugadores quedan como estaban antes del partido")
	_comprobar(int(res["ingreso"]) > 0 and mio.saldo == saldo0 + int(res["ingreso"]), "la taquilla entra en la caja (%d)" % int(res["ingreso"]))
	## El cierre de temporada respeta quién se retira: ninguno de los retirados sigue en ningún club.
	m.nueva_temporada()
	PartidoDespedida.limpiar(m)
	var siguen := 0
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if ids_leyendas.has(j.id):
				siguen += 1
	_comprobar(siguen == 0, "tras el cierre ninguno de los %d retirados sigue en un club" % ids_leyendas.size())

## HOMENAJE Y GUARDADO DEL PARTIDO DE DESPEDIDA (9-11): lo decidido sobrevive a guardar y cargar; el homenajeado de tu club deja la camiseta retirada, que no se reparte.
func _probar_homenaje_despedida() -> void:
	_titulo("PARTIDO DE DESPEDIDA: HOMENAJE, CAMISETA RETIRADA Y GUARDADO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 99)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var mio := m.mi_club()
	PartidoDespedida.preparar(m)
	var estrella: Jugador = mio.plantilla[3]
	estrella.edad = 36
	estrella.capitan = true
	estrella.ovr = 95
	estrella.dorsal = 7
	m.prensa.retiros_previstos[estrella.id] = true
	var leyendas := PartidoDespedida.preparar(m)   ## ya decidido: se reutiliza (no se vuelve a sortear)
	_comprobar(leyendas != null and leyendas.plantilla.has(estrella), "lo ya decidido se reutiliza y el homenajeado juega con las Leyendas")
	## Guardar y cargar antes del cierre: la decisión sigue ahí.
	var m2 := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(Partida.instantanea(m))))
	_comprobar(m2.prensa.retiros_previstos.size() == m.prensa.retiros_previstos.size() and bool(m2.prensa.retiros_previstos.get(estrella.id, false)),
		"lo decidido sobrevive a guardar y cargar (%d decisiones)" % m2.prensa.retiros_previstos.size())
	var f := PartidoDespedida.foto(mio)
	var p := Partido.new(mio, leyendas)
	p.simular()
	var res := PartidoDespedida.cerrar(m, p, leyendas, f)
	_comprobar(res["homenajeados"].size() >= 1 and PartidoDespedida.dorsal_retirado(m, mio, 7), "el homenajeado de tu club deja el #7 como camiseta retirada")
	var m3 := Partida.desde_instantanea(JSON.parse_string(JSON.stringify(Partida.instantanea(m))))
	_comprobar(PartidoDespedida.dorsal_retirado(m3, m3.mi_club(), 7) and m3.prensa.despedida_anio == m.anio, "la camiseta retirada y el año del partido sobreviven a guardar y cargar")
	m.nueva_temporada()
	PartidoDespedida.limpiar(m)
	var dorsales_ok := true
	for j: Jugador in m.mi_club().plantilla:
		dorsales_ok = dorsales_ok and j.dorsal != 7
	_comprobar(dorsales_ok, "el #7 no se reparte a nadie de tu club tras el cierre")

## LAS CAMISETAS RETIRADAS SE VEN (9-11): la tarjeta de la Historia del club y las del museo del estadio (una por dorsal retirado).
func _probar_camisetas_retiradas_vista() -> void:
	_titulo("CAMISETAS RETIRADAS: HISTORIA Y MUSEO")
	var m := Mundo.new()
	m.generar(["CHI"], 12)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	_comprobar(CamisetasRetiradas.crear(m) == null, "sin camisetas retiradas no se pinta nada en la Historia")
	m.prensa.dorsales_retirados = [{"dorsal": 7, "nombre": "A B", "anio": 2027}, {"dorsal": 10, "nombre": "C D", "anio": 2028}]
	var c := CamisetasRetiradas.crear(m)
	_comprobar(c != null and (c.get_child(1) as Container).get_child_count() == 2, "la Historia pinta una tarjeta por dorsal retirado")
	if c != null:
		c.queue_free()
	var sala := Node3D.new()
	add_child(sala)
	var antes := sala.get_child_count()
	CamisetasMuseo.poner(sala, Rect2(-2.0, -3.0, 4.0, 6.0), 0.0, Color(0.2, 0.5, 0.3), m.prensa.dorsales_retirados)
	_comprobar(sala.get_child_count() - antes == 2 * 6, "el museo cuelga 6 piezas por camiseta (marco, fondo, cuerpo, mangas y 2 rótulos) = %d" % (sala.get_child_count() - antes))
	sala.queue_free()

## EL ESTILO DE JUEGO EN LA PLANTILLA (9-11): las estrellas salen de la aptitud y cambiar de rol lo deja en Táctica y en la pizarra del partido.
func _probar_estilo_plantilla() -> void:
	_titulo("PLANTILLA A LA PES: ESTILO DE JUEGO CON ESTRELLAS")
	_comprobar(PlantillaEstilos.estrellas(0.80) == 0 and PlantillaEstilos.estrellas(0.97) == 1 and PlantillaEstilos.estrellas(1.05) == 2 and PlantillaEstilos.estrellas(1.20) == 3, "0, 1, 2 y 3 estrellas según la aptitud")
	_comprobar(PlantillaEstilos.texto_estrellas(2) == "★★☆", "texto de estrellas")
	var m := Mundo.new()
	m.generar(["CHI"], 31)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var club := m.mi_club()
	var j: Jugador = club.once().filter(func(x: Jugador) -> bool: return x.pos == "MED")[0]
	var caja := VBoxContainer.new()
	add_child(caja)
	var cambios := [0]
	PlantillaEstilos.pintar(m, club, j, caja, func() -> void: cambios[0] += 1)
	var claves: Array = m.vestuario.roles_de_grupo(Datos.grupo(j.pos_e))
	claves.sort()
	_comprobar(caja.get_child_count() == 1 + claves.size() and claves.size() >= 2, "un título y un botón por rol de su línea (%d roles)" % claves.size())
	var otro := String(claves[1] if m.vestuario.rol_tactico(j) == String(claves[0]) else claves[0])
	(caja.get_child(1 + claves.find(otro)) as Button).pressed.emit()
	_comprobar(m.vestuario.rol_tactico(j) == otro and cambios[0] == 1, "elegir un rol lo fija en el vestuario y avisa para repintar")
	var clave_rol := String(RolTactico.DE_VESTUARIO.get(otro, ""))
	_comprobar(clave_rol == "" or String(club.tactica.roles.get(j.id, "")) == clave_rol, "y lo deja en la táctica del partido (%s)" % clave_rol)
	caja.queue_free()

## «DESHACER» Y «ONCE AUTOMÁTICO» DE LA PLANTILLA (9-11): la foto del once se restaura tal cual, y el automático vuelve a armar el once solo.
func _probar_gestion_once() -> void:
	_titulo("GESTIÓN DEL ONCE: DESHACER Y AUTOMÁTICO")
	var m := Mundo.new()
	m.generar(["CHI"], 41)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var club := m.mi_club()
	for j: Jugador in club.plantilla:
		j.lesion = 0
		j.suspension = 0
	var once0: Array[Jugador] = club.once()
	var antes := GestionOnce.foto(club)
	_comprobar(antes.is_empty(), "el once automático se fotografía como vacío (no hay once elegido)")
	var reserva: Jugador = club.plantilla.filter(func(j: Jugador) -> bool: return not once0.has(j))[0]
	_comprobar(GestionOnce.intercambiar(club, once0[2], reserva) and club.once_elegido.size() == 11, "el cambio fija el once elegido")
	var medio := GestionOnce.foto(club)
	GestionOnce.restaurar(club, antes)
	_comprobar(club.once_elegido.is_empty() and club.once() == once0, "deshacer vuelve al once automático de antes")
	GestionOnce.restaurar(club, medio)
	_comprobar(club.once().has(reserva), "y se puede rehacer el cambio")
	GestionOnce.automatico(club)
	_comprobar(club.once_elegido.is_empty() and club.once() == once0, "«once automático» vuelve a armarlo solo")

## EVENTOS DEL CALENDARIO Y VISTA DE VARIAS SEMANAS (10-11, estilo PES 2020): liga, copa, continental, mercado y fin de temporada; el «Hito» se detiene en cada uno.
func _probar_eventos_fecha() -> void:
	_titulo("CALENDARIO: EVENTOS, VARIAS SEMANAS Y «HITO»")
	var m := Mundo.new()
	m.generar(["CHI"], 55)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var mio := m.mi_club()
	var liga := m.liga_de(mio)
	var sem := EventosFecha.semanas(m)
	_comprobar(sem.size() == EventosFecha.VISTA, "la vista trae %d semanas (%d)" % [EventosFecha.VISTA, sem.size()])
	var seguidas := true
	var cuenta := {"liga": 0, "copa": 0, "conti": 0, "mercado_cierra": 0}
	for i in sem.size():
		if int(sem[i]["k"]) != i or int(sem[i]["semana"]) != m.semana + i:
			seguidas = false
		for e: Dictionary in sem[i]["eventos"]:
			if cuenta.has(e["tipo"]):
				cuenta[e["tipo"]] += 1
			if e["tipo"] == "liga" and (not (e["rival"] is Club) or e["rival"] == mio or e["etiqueta"] != "J%d" % (i + 1)):
				seguidas = false
	_comprobar(seguidas and cuenta["liga"] == EventosFecha.VISTA, "una semana tras otra, cada una con su partido de liga y el rival (%d)" % cuenta["liga"])
	var copa_viva := m.copa != null and m.copa.en_curso() and m.copa.vivos.has(m.club_de_la_copa())
	_comprobar((cuenta["copa"] == 1) == copa_viva, "la copa sale en la semana 4 si sigues vivo (%d, vivo %s)" % [cuenta["copa"], str(copa_viva)])
	var conti := m.mi_continental()
	_comprobar((cuenta["conti"] == 1) == (conti != null and conti.en_curso()), "el continental sale en la semana 3 si tu club juega uno (%d)" % cuenta["conti"])
	_comprobar(cuenta["mercado_cierra"] == 1, "el cierre del mercado (semana %d) sale en las 6 semanas" % Mundo.VENTANA_VERANO)
	## La copa y el continental llevan nombre de competición y, la primera ronda, rival.
	for s: Dictionary in sem:
		for e: Dictionary in s["eventos"]:
			if e["tipo"] == "copa":
				_comprobar(String(e["texto"]).begins_with(m.copa.nombre) and e["rival"] is Club, "copa: «%s» con rival" % e["texto"])
			if e["tipo"] == "conti":
				_comprobar(String(e["texto"]).begins_with(conti.nombre), "continental: «%s»" % e["texto"])
	## Apertura del mercado de invierno.
	m.semana = Mundo.VENTANA_INVIERNO_INI - 2
	var ab := false
	for s: Dictionary in EventosFecha.semanas(m):
		for e: Dictionary in s["eventos"]:
			if e["tipo"] == "mercado_abre":
				ab = int(s["semana"]) == Mundo.VENTANA_INVIERNO_INI and int(e["dia"]) == 0
	_comprobar(ab, "el mercado abre el lunes de la semana %d" % Mundo.VENTANA_INVIERNO_INI)
	## Fin de temporada: la última jornada lleva el evento y la vista no pasa de ahí.
	m.semana = 30
	liga.jornada_actual = liga.jornadas() - 3
	var fin := EventosFecha.semanas(m)
	var tipos_fin := (fin[fin.size() - 1]["eventos"] as Array).map(func(e: Dictionary) -> String: return String(e["tipo"]))
	_comprobar(fin.size() == 3 and tipos_fin.has("fin"), "la vista acaba en la última jornada, con «Fin de temporada» (%d semanas)" % fin.size())
	## «Hito»: hasta qué día y por qué evento.
	m.semana = 1
	liga.jornada_actual = 0
	var h0 := EventosFecha.hito(m, 0)
	_comprobar(h0["tipo"] == "liga" and int(h0["dia"]) == 5, "el hito de un lunes de liga es el partido del sábado (%s)" % h0["texto"])
	m.semana = Mundo.VENTANA_VERANO
	var h6 := EventosFecha.hito(m, 6)
	_comprobar(h6["tipo"] != "mercado_cierra" and int(h6["dia"]) == 6, "el domingo del cierre del mercado ya pasó: el hito sigue en la semana que viene")
	m.semana = Mundo.VENTANA_INVIERNO_INI - 1
	var hab := EventosFecha.hito(m, 6)
	_comprobar(hab["tipo"] == "mercado_abre", "el domingo antes de abrir el mercado, el hito es su apertura (%s)" % hab["texto"])
	var ordenados := true
	var previo := -1
	m.semana = 1
	for e: Dictionary in EventosFecha.proximos(m, 0, 12):
		var clave := int(e["k"]) * 10 + int(e["dia"])
		if clave < previo:
			ordenados = false
		previo = clave
	_comprobar(ordenados, "los próximos eventos salen en orden de fecha")
	## La fila de próximos y la vista de varias semanas se pintan.
	var caja := HBoxContainer.new()
	add_child(caja)
	FilaProximos.pintar(m, caja)
	_comprobar(caja.get_child_count() == 2 + 2 * FilaProximos.CUANTOS, "la fila pinta rótulo, botón 📅 y %d eventos (%d nodos)" % [FilaProximos.CUANTOS, caja.get_child_count()])
	caja.queue_free()
	var vista := CalendarioSemanas.mostrar(self, m, 0)
	var tira: Node = vista._centro.get_child(2)
	_comprobar(tira.get_child_count() == EventosFecha.VISTA, "la vista de varias semanas pinta una columna por semana (%d)" % tira.get_child_count())
	vista.queue_free()

## LA CASA DEL PERSONAJE A PIE, SIN CIUDAD (10-11): el plano tiene todas sus habitaciones alcanzables caminando, paredes y muebles chocan, los muebles no tapan las puertas.
func _probar_casa_plano() -> void:
	_titulo("CASA DEL PERSONAJE: PLANO, COLISIÓN Y HABITACIONES ALCANZABLES")
	CasaPlano.vaciar_cache()
	var obst := CasaPlano.obstaculos()
	_comprobar(obst.size() > CasaPlano.paredes().size() + 20, "hay paredes y muebles sólidos (%d cajas)" % obst.size())
	_comprobar(CasaPlano.libre(CasaPlano.INICIO, obst), "el punto de inicio está libre")
	_comprobar(CasaPlano.sala_en(CasaPlano.INICIO) == "Sala" and CasaPlano.sala_en(Vector2(-1, -1)) == "", "el inicio es la sala y fuera de la casa no hay habitación")
	## Pared: caminar contra la pared del pasillo (z = 4,8; sin hueco en x = 2) se frena delante de ella.
	var p := CasaPlano.mover(Vector2(2.0, 4.0), Vector2(2.0, 6.0), obst)
	_comprobar(p.y < 4.8 - CasaPlano.RADIO + 0.01 and p.y > 3.9, "la pared frena al cuerpo (z %.2f)" % p.y)
	## Hueco de puerta (x 2,5..3,5): se cruza.
	var q := CasaPlano.mover(Vector2(3.0, 4.0), Vector2(3.0, 5.6), obst)
	_comprobar(q.y > 5.5, "por el hueco de la puerta se pasa (z %.2f)" % q.y)
	## Un paso enorme (tirón de fotogramas) no atraviesa la pared.
	var t := CasaPlano.mover(Vector2(2.0, 4.0), Vector2(2.0, 8.0), obst)
	_comprobar(t.y < 4.8, "un paso largo no atraviesa la pared (z %.2f)" % t.y)
	## Deslizar: contra la pared de lado se avanza por el eje libre.
	var d := CasaPlano.mover(Vector2(2.0, 4.0), Vector2(3.0, 5.0), obst)
	_comprobar(d.x > 2.4, "contra la pared se desliza de lado (x %.2f)" % d.x)
	## Los muebles sólidos chocan: el sofá (x 4,6, z 3,7).
	var s := CasaPlano.mover(Vector2(4.6, 2.9), Vector2(4.6, 3.9), obst)
	_comprobar(s.y < 3.3, "el sofá frena al cuerpo (z %.2f)" % s.y)
	## Ninguna habitación queda aislada: su centro (o un punto libre cercano) se alcanza desde la entrada.
	var alc := CasaPlano.alcanzables(CasaPlano.INICIO)
	for s2: Array in CasaPlano.SALAS:
		var c := CasaPlano.centro_de(String(s2[0]))
		var hallado := false
		for dx in range(-8, 9):
			for dz in range(-8, 9):
				var pt := c + Vector2(dx, dz) * 0.1
				if CasaPlano.libre(pt, obst) and alc.has(CasaPlano.celda_de(pt)):
					hallado = true
		_comprobar(hallado, "se llega caminando a la habitación «%s»" % String(s2[0]))
	## Las puertas de la casa no las tapa ningún mueble: cada hueco se atraviesa de lado a lado.
	for h: Array in CasaPlano.huecos():
		var medio := (float(h[2]) + float(h[3])) / 2.0
		var a := Vector2(medio, float(h[1]) - 0.6) if String(h[0]) == "h" else Vector2(float(h[1]) - 0.6, medio)
		var b := Vector2(medio, float(h[1]) + 0.6) if String(h[0]) == "h" else Vector2(float(h[1]) + 0.6, medio)
		_comprobar(CasaPlano.libre(a, obst) and CasaPlano.libre(b, obst) and CasaPlano.mover(a, b, obst).distance_to(b) < 0.05,
			"el hueco %s %.1f (%.1f-%.1f) se cruza" % [String(h[0]), float(h[1]), float(h[2]), float(h[3])])
	## Cámara: nunca dentro de una pared.
	var dist := CasaPlano.distancia_camara(Vector2(2.0, 4.5), Vector2(0, 1), 3.0, obst)
	_comprobar(dist < 0.5, "la cámara se acerca si hay una pared detrás (%.1f m)" % dist)
	_comprobar(CasaPlano.distancia_camara(Vector2(3.0, 1.0), Vector2(1, 0), 1.0, obst) >= 0.9, "con sitio detrás, la cámara llega a su distancia")
	## El acceso no nombra la ciudad: con ella apagada (lo normal) lleva a la casa a pie.
	_comprobar(not InterruptorCiudad.activa, "la ciudad está apagada")

## ESCUDOS MÁS REALISTAS (10-11, encargo del dueño): los clubes de las 10 ligas grandes llevan su contorno, figura, letras y colores parecidos al real (datos en
## `_escudos.txt`, el real en el pack y el ficticio en lo público); hay un patrón nuevo, los rombos bávaros. Se prueba con varios países y sin repetir escudos.
func _probar_escudos_realistas() -> void:
	_titulo("ESCUDOS PARECIDOS AL REAL: LIGAS GRANDES")
	_comprobar(Escudo.PATRONES.has("rombos_bav"), "el patrón de rombos bávaros existe")
	var tabla: Dictionary = Datos.tabla("ASPECTO_CLUB")
	var con_rombos := 0
	for k: String in tabla:
		var e: Variant = (tabla[k] as Dictionary).get("escudo", [])
		if e is Array and (e as Array).size() > 1 and String(e[1]) == "rombos_bav":
			con_rombos += 1
	_comprobar(con_rombos >= 1, "hay al menos un club con ese patrón en la tabla (%d)" % con_rombos)
	var m := Mundo.new()
	m.generar(["ESP", "ENG", "ITA", "GER", "FRA", "ARG", "BRA", "MEX", "USA", "JPN"], 62)
	var clubes := 0
	var con_figura := 0
	var firmas := {}
	var svg_ok := true
	for l: Liga in m.ligas:
		for c: Club in l.clubes:
			clubes += 1
			var f := AspectoClub.fila(c)
			if AspectoClub.emblema(c) != "" or AspectoClub.letras(c) != "" or not (f.get("escudo", []) as Array).is_empty():
				con_figura += 1
			firmas["%s|%s|%s|%s|%s|%s" % [Escudo.forma_de(c), Escudo.patron_de(c), AspectoClub.emblema(c), AspectoClub.letras(c), c.color_escudo1(), c.color_escudo2()]] = true
			if clubes % 9 == 0 and Escudo.svg_de(c).length() < 200:
				svg_ok = false
	_comprobar(clubes >= 100 and con_figura >= clubes - clubes / 20, "%d de %d clubes de 10 países tienen escudo con forma, figura o letras propias" % [con_figura, clubes])
	_comprobar(firmas.size() >= clubes * 9 / 10, "los escudos casi no se repiten (%d distintos de %d)" % [firmas.size(), clubes])
	_comprobar(svg_ok, "los escudos se dibujan (SVG con contenido)")
	## Las figuras nuevas (torre de París, murciélago, gallo, carabela, toro, dragón, castillo, delfín) existen y se dibujan.
	var nuevas := ["eiffel", "murcielago", "gallo", "carabela", "toro", "dragon", "castillo", "delfin"]
	var dibujan := true
	for k: String in nuevas:
		var im := Image.new()
		var svg := '<svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">%s</svg>' % String(EscudoEmblemas.FIGURAS.get(k, "")).replace("{F}", "#ffffff").replace("{D}", "#000000")
		if not EscudoEmblemas.FIGURAS.has(k) or im.load_svg_from_string(svg) != OK:
			dibujan = false
	_comprobar(dibujan, "las 8 figuras nuevas están en el vocabulario y su SVG se carga")
