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
