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
