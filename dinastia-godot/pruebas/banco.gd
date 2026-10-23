extends "res://pruebas/banco_p24.gd"
## (Parte 25 de 25 de `banco.gd`.)

func _probar_transmision_y_estadisticas() -> void:
	_titulo("PARTIDO 3D: CÁMARA DE TRANSMISIÓN INTELIGENTE Y ESTADÍSTICAS")
	var dt := 1.0 / 60.0
	## 1) En TODOS los estadios y alturas: dentro del cuenco, sin tirones.
	var fuera: Array = []
	var tirones: Array = []
	var techo: Array = []
	for forma: String in ["ingles", "rect", "herradura", "caldera", "oval", "dos", "principal", "cuenco"]:
		var g := StadiumBuilder.geom_de_forma(forma)
		for n in [1, 2, 3, 5]:
			var alto := StadiumBuilder.ALTURA_PIE + float(n) * StadiumBuilder.subida_bandeja() + float(n - 1) * StadiumBuilder.FRENTE_BANDEJA
			var rig := CameraRig.new()
			add_child(rig)
			rig.set_process(false)
			rig.build_for(float(g["dx"]), float(g["dz"]), alto)
			var cam: Camera3D = rig.cameras[0]
			var antes := Vector3.INF
			var fov_antes := -1.0
			var max_v := 0.0
			var max_fov := 0.0
			for i in 1500:
				var tt := float(i) * dt
				## Un balón que va y viene de área a área, con un salto a mitad
				## (saque de centro tras un gol) y una ocasión.
				var b := Vector3(sin(tt * 0.7) * 30.0, 0.1, sin(tt * 0.45) * 50.0)
				if i >= 700 and i < 760:
					b = Vector3(0, 0.1, 0)
				rig.pista_estado = "juego"
				rig.pista_ataca = 1.0 if cos(tt * 0.45) >= 0.0 else -1.0
				if i == 1000:
					rig.pista_ocasion = 1.4
				rig._transmision(cam, b, dt)
				var p := cam.global_position
				if p.x > float(g["dx"]) - 6.9 or absf(p.z) > CameraRig.CARRO_Z_MAX + 0.01 or p.y > 24.01 or p.y < 8.99:
					fuera.append("%s/%d" % [forma, n])
					break
				var losa := alto + 0.4
				if p.y > losa - 1.15 and p.y < losa + 1.6:
					techo.append("%s/%d y=%.1f" % [forma, n, p.y])
					break
				if antes != Vector3.INF:
					max_v = maxf(max_v, p.distance_to(antes) / dt)
					max_fov = maxf(max_fov, absf(cam.fov - fov_antes) / dt)
				antes = p
				fov_antes = cam.fov
			if max_v > CameraRig.CARRO_VMAX * 1.25 or max_fov > CameraRig.ZOOM_VMAX * 1.1:
				tirones.append("%s/%d v=%.1f fov=%.1f" % [forma, n, max_v, max_fov])
			rig.free()
	_comprobar(fuera.is_empty(), "la transmisión no sale de su raíl en ningún estadio (x fija en el cuenco, |z| ≤ 38) %s" % str(fuera))
	_comprobar(techo.is_empty(), "la cámara nunca queda a la altura de la losa del techo %s" % str(techo))
	_comprobar(tirones.is_empty(), "sin tirones: el carro ≤ %.0f m/s y el zoom ≤ %.0f°/s, también tras un salto del balón %s" % [CameraRig.CARRO_VMAX * 1.25, CameraRig.ZOOM_VMAX * 1.1, str(tirones)])
	## 2) Lo que lee de la jugada.
	var rig2 := CameraRig.new()
	add_child(rig2)
	rig2.set_process(false)
	rig2.build_for(49.0, 68.0, 13.0)
	var c2: Camera3D = rig2.cameras[0]
	rig2.pista_estado = "juego"
	rig2.pista_ataca = 1.0
	for i in 60:
		rig2._transmision(c2, Vector3(0, 0.1, -5.0), dt)
	var fov_medio := c2.fov
	_comprobar(rig2.trans_plano == "normal" and absf(fov_medio - CameraRig.FOV_TRANSMISION) < 1.0, "en el medio del campo, plano normal (%s, %.1f°)" % [rig2.trans_plano, fov_medio])
	for i in 240:
		rig2._transmision(c2, Vector3(5.0, 0.1, 40.0), dt)
	_comprobar(rig2.trans_plano == "area" and c2.fov < CameraRig.FOV_TRANSMISION - 4.0, "con la jugada en el área el plano se cierra (%s, %.1f°)" % [rig2.trans_plano, c2.fov])
	rig2.pista_ocasion = 1.4
	rig2._transmision(c2, Vector3(5.0, 0.1, 40.0), dt)
	_comprobar(rig2.trans_plano == "ocasion", "un tiro en el aire es «ocasión» (%s)" % rig2.trans_plano)
	## El foco no tiembla con el balón que se mueve dentro de la zona muerta.
	var r_antes := CameraRig.new()
	add_child(r_antes)
	r_antes.set_process(false)
	r_antes.build_for(49.0, 68.0, 13.0)
	var c3: Camera3D = r_antes.cameras[0]
	r_antes.pista_estado = "juego"
	r_antes.pista_ataca = 1.0
	for i in 200:
		r_antes._transmision(c3, Vector3(0, 0.1, 0), dt)
	var f0 := r_antes._trans_foco
	var mov := 0.0
	for i in 240:
		r_antes._transmision(c3, Vector3(sin(i * 0.3) * 0.8, 0.1, cos(i * 0.21) * 1.2), dt)
		mov = maxf(mov, r_antes._trans_foco.distance_to(f0))
	_comprobar(mov < 0.6, "zona muerta: el balón que se mueve 1 m no mueve el plano (%.2f m)" % mov)
	## Contraataque: el balón cruza el campo rápido hacia la portería rival.
	var r4 := CameraRig.new()
	add_child(r4)
	r4.set_process(false)
	r4.build_for(49.0, 68.0, 13.0)
	var c4: Camera3D = r4.cameras[0]
	r4.pista_estado = "juego"
	r4.pista_ataca = 1.0
	for i in 30:
		r4._transmision(c4, Vector3(0, 0.1, -40.0), dt)
	var abierto := false
	var fov_max := 0.0
	var adelanta := false
	for i in 150:
		var bz := -40.0 + 12.0 * float(i) * dt
		r4._transmision(c4, Vector3(0, 0.1, bz), dt)
		abierto = abierto or r4.trans_plano == "abierto"
		fov_max = maxf(fov_max, c4.fov)
		if i == 120:
			adelanta = r4._trans_foco.z > bz
	_comprobar(abierto and fov_max > CameraRig.FOV_TRANSMISION + 2.5, "en el contraataque el plano se abre (%.1f°)" % fov_max)
	_comprobar(adelanta, "el plano se adelanta hacia donde va el balón")
	_comprobar(CameraRig.lectura_jugada(Vector3(0, 0, 40), Vector3.ZERO, 1.0, false, "puerta", "saque").x == 0.0, "en un saque de puerta no se cierra el plano")
	_comprobar(CameraRig.lectura_jugada(Vector3(30, 0, 52), Vector3.ZERO, 1.0, false, "corner", "saque").x == 1.0, "en un córner se cierra el plano")
	var z0 := CameraRig.amortiguar(0.0, 10.0, 0.0, 0.5, 100.0, 1.0)
	_comprobar(z0.x <= 10.0 and z0.x > 5.0, "el amortiguador no se pasa del objetivo con un fotograma largo (%.2f)" % z0.x)
	rig2.free()
	r_antes.free()
	r4.free()
	## 3) Las estadísticas.
	var penal := EstadisticasVivo.xg_de(Vector2(0, 41.5), true)
	var cerca := EstadisticasVivo.xg_de(Vector2(0, 46.5), true)
	var lejos := EstadisticasVivo.xg_de(Vector2(0, 27.5), true)
	var esquina := EstadisticasVivo.xg_de(Vector2(25, 50.0), true)
	_comprobar(cerca > penal and penal > lejos and lejos < 0.06 and cerca > 0.4, "xG por distancia: 6 m %.2f > 11 m %.2f > 25 m %.2f" % [cerca, penal, lejos])
	_comprobar(esquina < 0.05, "sin ángulo casi no hay xG (%.3f)" % esquina)
	_comprobar(absf(EstadisticasVivo.xg_de(Vector2(0, -41.5), false) - penal) < 0.001, "la visita ataca hacia -Z con la misma vara")
	var ev := EstadisticasVivo.new()
	ev.anotar_tiro(true, Vector2(2, 38), 12)
	ev.anotar_tiro(false, Vector2(-3, -30), 20)
	ev.cerrar_tiro(true, "atajada")
	ev.cerrar_tiro(false, "gol")
	ev.cerrar_tiro(true, "gol", Vector3(0, 0, 50))
	ev.tarjeta(true, false)
	ev.tarjeta(false, true)
	ev.anotar_calor(0, Vector2(0, 40))
	ev.anotar_calor(0, Vector2(0, 41))
	_comprobar(ev.n_tiros(true) == 2 and String(ev.tiros[0]["res"]) == "atajada" and String(ev.tiros[2]["res"]) == "gol",
		"cada remate guarda cómo acabó (y un gol de rebote se apunta aparte)")
	_comprobar(ev.amarillas == [1, 0] and ev.rojas == [0, 1], "tarjetas por equipo")
	## M-137: xA = el xG de los remates que salieron de un pase.
	(ev.tiros[0] as Dictionary)["asist"] = "pasador"
	_comprobar(is_equal_approx(ev.xa(true), float(ev.tiros[0]["xg"])) and ev.xa(false) == 0.0
		and is_equal_approx(float(ev.xa_por_jugador().get("pasador", 0.0)), float(ev.tiros[0]["xg"])), "xA: el pase previo se lleva el xG del remate")
	## M-162: la tabla y los remates, a CSV.
	var ruta_csv := ev.a_csv(null, null)
	var txt_csv := FileAccess.get_file_as_string(ruta_csv) if ruta_csv != "" else ""
	_comprobar(txt_csv.contains("remate;equipo;minuto") and txt_csv.contains(";pasador") and txt_csv.contains("Tarjetas rojas"),
		"CSV: el partido se exporta con la tabla y cada remate")
	if ruta_csv != "":
		DirAccess.remove_absolute(ruta_csv)
	var celda := int((40.0 + 52.5) / 105.0 * EstadisticasVivo.COLS) + int(34.0 / 68.0 * EstadisticasVivo.FILAS) * EstadisticasVivo.COLS
	_comprobar((ev.calor[0] as PackedInt32Array)[celda] == 2, "el mapa de calor cuenta por zonas")
	var ca := Club.new()
	ca.nombre = "Local de prueba"
	var cb := Club.new()
	cb.nombre = "Visita de prueba"
	var pa := Partido.new(ca, cb)
	pa.posesion_local = 58.0
	pa.remates_local = 7
	pa.tiros_puerta_local = 3
	var filas := ev.resumen(pa, null)
	var nombres: Array = filas.map(func(f: Array) -> String: return String(f[0]))
	var faltan: Array = []
	for k: String in ["Posesión", "Tiros", "Tiros a puerta", "Goles esperados (xG)", "Córners", "Faltas", "Tarjetas amarillas", "Tarjetas rojas"]:
		if not k in nombres:
			faltan.append(k)
	_comprobar(faltan.is_empty() and String(filas[0][1]) == "58%", "el resumen tiene todas las filas %s" % str(faltan))
	var hechos := {}
	_comprobar(RotuloEstadisticas.cuando(10, "saque", 1, hechos) == "", "antes del 17' no hay rótulo")
	_comprobar(RotuloEstadisticas.cuando(18, "juego", 1, hechos) == "", "con el balón en juego no hay rótulo")
	_comprobar(RotuloEstadisticas.cuando(18, "saque", 1, hechos) == "primero", "en la primera pelota parada pasado el 17' sale el rótulo")
	hechos["primero"] = true
	_comprobar(RotuloEstadisticas.cuando(25, "saque", 1, hechos) == "" and RotuloEstadisticas.cuando(45, "descanso", 1, hechos) == "descanso"
		and RotuloEstadisticas.cuando(66, "saque", 2, hechos) == "segundo", "uno por momento: 17', descanso y 65'")
	## El panel se arma (tabla + dos campos) sin motor.
	var raiz := Control.new()
	add_child(raiz)
	var panel := PanelEstadisticas.abrir(raiz, pa, null, ev)
	_comprobar(panel != null and panel.get_child_count() > 0, "el panel de estadísticas se arma")
	var rot := RotuloEstadisticas.mostrar(raiz, "descanso", pa, null, ev)
	_comprobar(rot != null and rot.get_child_count() > 0, "el rótulo de la tele se arma")
	raiz.free()
	## El botón: configurable y sin pisar a nadie.
	Mando.registrar()
	_comprobar(InputMap.has_action("jugar_estadisticas"), "«Estadísticas del partido» tiene su acción en el InputMap")
	var pisa: Array = []
	for a: String in Mando.MAPA:
		if a == "jugar_estadisticas":
			continue
		for k: int in Mando.teclas_de("jugar_estadisticas"):
			if k in Mando.teclas_de(a):
				pisa.append(a)
		for b: int in Mando.botones_de("jugar_estadisticas"):
			if b in Mando.botones_de(a):
				pisa.append(a)
	_comprobar(pisa.is_empty(), "su tecla y su botón no son de otra acción %s" % str(pisa))
	var en_grupo := false
	for gr: Array in PanelControles.GRUPOS:
		en_grupo = en_grupo or "jugar_estadisticas" in (gr[1] as Array)
	_comprobar(en_grupo, "se puede reasignar en la pantalla de controles")

## PRÓRROGA Y PENALES (17-10-2026). Lo que no necesita el 3D: el acta que se
## alarga al 120' con un cambio más, la tanda del césped que `penales()` ya no
## vuelve a sortear (y la copa respeta), el reloj de la prórroga del motor y
## cuándo está decidida una tanda. La prueba con el partido entero en el
## césped es `pruebas/prueba_prorroga_penales.tscn`.
func _probar_prorroga_y_penales() -> void:
	_titulo("PRÓRROGA Y TANDA DE PENALES DEL MOTOR REAL")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)
	p.preparar()
	p.motor_externo = true
	while p.minuto < 89:
		p.simular_minuto()
	p.prorroga_externa()
	p.simular_minuto()
	_comprobar(not p.terminado_ya and p.minuto == 90 and p.minutos_fin == 120, "con prórroga el acta no termina en el 90'")
	_comprobar(p.MAX_CAMBIOS + p.cambios_extra == 6, "en la prórroga hay un cambio más")
	p.penales_externos(3, 4)
	while not p.terminado_ya:
		p.simular_minuto()
	_comprobar(p.minuto == 120, "el acta termina en el 120'")
	_comprobar(p.penales() == [3, 4] and p.penales() == [3, 4] and p.penales_en_cesped, "`penales()` devuelve la tanda del césped, siempre la misma")
	var copa := Copa.new("Copa de prueba")
	copa.vivos.assign([a, b])
	p.goles_local = 1
	p.goles_visita = 1
	var res := copa.jugar_ronda(p)
	_comprobar(not res.is_empty() and (res[0] as Dictionary)["pasa"] == b and (res[0] as Dictionary)["penales"] == [3, 4], "la copa clasifica al que ganó la tanda del césped")
	var p2 := Partido.new(a, b)
	p2.preparar()
	while not p2.terminado_ya:
		p2.simular_minuto()
	_comprobar(p2.minuto == 90 and not p2.penales_en_cesped, "sin motor ni prórroga: termina en el 90' como siempre")
	## El reloj del motor en la prórroga.
	var mo := MotorJugable.new()
	mo.duracion_mitad = 180.0
	mo.sortear_anadido()
	mo.mitad = 3
	mo.t = 30.0
	var m3 := mo.minuto()
	mo.mitad = 4
	mo.t = 59.0
	var m4 := mo.minuto()
	_comprobar(m3 == 97 and m4 == 119 and is_equal_approx(mo.dur_mitad(), 60.0), "prórroga de 15' (un tercio de la mitad): 97' y 119' (%d', %d')" % [m3, m4])
	_comprobar(mo.anadido.size() == 4 and mo._anadido_de(4) > 0.0, "la prórroga tiene su añadido")
	mo.free()
	_comprobar(MotorJugable.tanda_decidida([[true, true, true], [false, false, false]]), "tanda: 3-0 tras tres cada uno está decidida")
	_comprobar(not MotorJugable.tanda_decidida([[true, true, true, true, true], [true, true, true, true, true]]), "tanda: 5-5 sigue a muerte súbita")
	_comprobar(MotorJugable.tanda_decidida([[true, true, true, true, true, false], [true, true, true, true, true, true]]), "tanda: 5-6 en la muerte súbita está decidida")
	_comprobar(not MotorJugable.tanda_decidida([[true, true, true, true, true, true], [true, true, true, true, true]]), "tanda: en la muerte súbita el segundo aún tira")
	var circ := MarcadorTanda.circulos([true, false], 5)
	_comprobar(circ.count("●") == 2 and circ.count("○") == 3, "el marcador de la tanda pinta ●● y tres huecos")

## EL INFORME DEL RIVAL (17-10-2026): sale de los datos reales del mundo.
func _probar_informe_rival() -> void:
	_titulo("INFORME DEL RIVAL ANTES DEL PARTIDO")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	for i in 6:
		m.ligas[0].jugar_jornada()
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	var rival: Club = p.visita if p.local == m.mi_club() else p.local
	var d := InformeRival.datos(rival, m.mi_club(), m.liga_de(rival))
	_comprobar(int(d["puesto"]) >= 1 and int(d["puesto"]) <= m.ligas[0].clubes.size(), "el informe dice el puesto del rival en la tabla (%d.º)" % int(d["puesto"]))
	_comprobar((d["racha"] as Array).size() == 5, "la racha tiene los últimos 5 partidos del rival")
	var mejor := 0
	for j: Jugador in rival.once():
		mejor = maxi(mejor, j.ovr)
	_comprobar((d["mejores"] as Array).size() == 3 and (d["mejores"][0] as Jugador).ovr == mejor, "los más peligrosos empiezan por el mejor del once")
	_comprobar(not (d["consejos"] as Array).is_empty(), "hay al menos un consejo del cuerpo técnico")
	rival.tactica.presion = Tactica.Nivel.ALTO
	var d2 := InformeRival.datos(rival, m.mi_club(), m.liga_de(rival))
	_comprobar(str(d2["consejos"]).contains("Presionan arriba"), "si el rival presiona alto, el consejo lo dice")

## POR QUÉ SUBE O BAJA LA MORAL (17-10-2026): cada cambio deja su motivo y se guarda.
func _probar_porque_moral() -> void:
	_titulo("CAMARÍN: POR QUÉ SUBE O BAJA LA MORAL")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in 6:
		m.avanzar_semana()
	var c := m.mi_club()
	var con := 0
	var motivos := {}
	for j in c.plantilla:
		if not j.historial_moral.is_empty():
			con += 1
		for e: Dictionary in j.historial_moral:
			motivos[String(e["m"])] = true
	_comprobar(con >= c.plantilla.size() / 2, "tras 6 semanas la mayoría del plantel tiene motivos de moral anotados (%d de %d)" % [con, c.plantilla.size()])
	_comprobar(not motivos.is_empty() and not motivos.has(""), "cada cambio tiene un motivo con nombre (%s)" % ", ".join(motivos.keys()))
	var j0: Jugador = c.plantilla[0]
	var antes := j0.moral
	j0.cambiar_moral(5, "Prueba")
	_comprobar(j0.moral == mini(antes + 5, 99) and String(j0.historial_moral[-1]["m"]) == "Prueba", "cambiar_moral sube la moral y anota el motivo")
	var copia := Partida.desde_instantanea(Partida.instantanea(m))
	var j1 := copia.jugador_por_id(j0.id)
	_comprobar(j1 != null and j1.historial_moral.size() == j0.historial_moral.size(), "el historial de moral se guarda y se carga")
	var sat: Dictionary = m.vestuario.satisfaccion_de(j0)
	_comprobar(sat.has("min") and sat.has("rend") and sat.has("tact") and sat.has("inst"), "el Camarín puede leer lo que pesa en la satisfacción")

## EL PARTIDO ABANDONADO A MEDIAS (17-10-2026): cerrar el juego perdiendo y
## volver a cargar NO repite el partido desde el 0-0, y recargar no cambia nada.
func _probar_partido_abandonado() -> void:
	_titulo("PARTIDO ABANDONADO A MEDIAS: NO SE PUEDE REPETIR HASTA GANAR")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	p.preparar()
	PartidoPendiente.abrir(m, p)
	p.goles_local = 0
	p.goles_visita = 2
	p.minuto = 60
	PartidoPendiente.actualizar(m, p)
	## La partida tal como quedó guardada (recargarla es partir siempre de aquí).
	var foto := Partida.instantanea(m)
	var d := PartidoPendiente.pendiente(m)
	_comprobar(not d.is_empty() and int(d["gv"]) == 2 and int(d["minuto"]) == 60, "el partido en curso queda apuntado con su marcador y su minuto")
	var r1 := PartidoPendiente.resolver(m, d)
	_comprobar(r1 != null and r1.terminado_ya and r1.goles_visita >= 2, "al cargar se completa desde el 0-2 del 60' (no desde 0-0): %d-%d" % [r1.goles_local, r1.goles_visita])
	_comprobar(PartidoPendiente.pendiente(m).is_empty(), "una vez resuelto, deja de estar pendiente")
	## Recargar = otra vez el mismo resultado (azar fijo para ese partido).
	var m2 := Partida.desde_instantanea(foto)
	var r2 := PartidoPendiente.resolver(m2, d)
	_comprobar(r2 != null and r2.goles_local == r1.goles_local and r2.goles_visita == r1.goles_visita, "recargar da el mismo resultado (%d-%d)" % [r2.goles_local, r2.goles_visita])
	d["minuto"] = 90
	var r3 := PartidoPendiente.resolver(m, d)
	_comprobar(r3 != null and r3.goles_local == 0 and r3.goles_visita == 2, "si ya se había pitado el final, queda el resultado tal cual")

func _probar_no_atravesar_paredes() -> void:
	_titulo("CIUDAD: NO SE ATRAVIESAN PAREDES")
	var ex := _ExpPared.new()
	ex.cuerpo = Node3D.new()
	ex.modo = "pie"
	ex.cuerpo.position = Vector3(4.0, 0, 0)
	ex.movil_encima = true
	for i in 40:
		ex._mover_un_trozo(Vector3(0.3, 0, 0), 0.4)
	_comprobar(ex.cuerpo.position.x + 0.4 <= ex.pared_x + 0.001, "con un coche encima no se entra en el edificio (x=%.2f, pared en %.1f)" % [ex.cuerpo.position.x, ex.pared_x])
	ex._mover_un_trozo(Vector3(-0.3, 0, 0), 0.4)
	_comprobar(ex.cuerpo.position.x < 4.3, "pero sí se puede salir de debajo del coche hacia la calle")
	ex.movil_encima = false
	ex.cuerpo.position = Vector3(5.5, 0, 0)
	ex._mover_un_trozo(Vector3(-0.3, 0, 0), 0.4)
	_comprobar(ex.cuerpo.position.x < 5.5, "si ya estás dentro de algo fijo (al salir del metro) se te deja salir")
	ex.cuerpo.free()
	ex.free()
