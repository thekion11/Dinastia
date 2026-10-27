extends "res://pruebas/banco/varios_p9.gd"
## [Capa 10/10 de `varios.gd`] _probar_jugadores_fijos, _probar_disenos_kit, _probar_region_reales, _probar_sancion_dt, _probar_tanda_top25b, _probar_informe_rival … (+1)

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


func _probar_disenos_kit() -> void:
	_titulo("EQUIPACIÓN: DISEÑOS, COLORES, BOTINES Y ACCESORIOS")
	var claves := DisenosKit.claves()
	_comprobar(claves.size() >= 62, "hay al menos 50 diseños nuevos (%d en total)" % claves.size())
	var unicas := {}
	for k: String in claves:
		unicas[k] = true
	_comprobar(unicas.size() == claves.size(), "sin claves repetidas")
	_comprobar(Jersey.KITS.all(func(k: String) -> bool: return claves.has(k)), "los 12 estilos de siempre siguen")
	_comprobar(DisenosKit.BOTINES.size() == 30, "30 modelos de botín")
	var de_dos := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[2]) >= 43 and int(d[2]) <= 62 and int(d[7]) == 2)
	var de_tres := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[2]) >= 43 and int(d[2]) <= 62 and int(d[7]) == 3)
	_comprobar(de_dos.size() == 20 and de_tres.size() == 20, "20 diseños nuevos de dos colores y 20 de tres")
	var cols3: Array[Color] = [Color.RED, Color.WHITE, Color.BLUE, Color.BLACK, Color.GREEN]
	var usados := {}
	for d: Array in de_dos:
		for i in 60:
			usados[DisenosKit.color_en(d, cols3, float(i % 10) / 5.0 - 1.0, float(i / 10) / 6.0).to_html(false)] = true
	_comprobar(not usados.has(Color.BLUE.to_html(false)) and not usados.has(Color.BLACK.to_html(false)), "los de dos colores no usan un tercero")
	## Patrocinadores.
	var ms := Mundo.new()
	ms.generar(["CHI"], 31)
	ms.tomar_el_mando(ms.ligas[0].clubes[0].id)
	_comprobar(SponsorKit.de_club(ms.mi_club(), ms).is_empty(), "sin contrato, tu camiseta va limpia")
	ms.auspicio.contrato = {"marca": "Cerveza Andin4", "color": "#e8b13a", "monto": 1, "exig_pos": 5, "anio": 2026}
	var spk := DisenosKit.kit_de_club(ms.mi_club())
	_comprobar((spk["sp"] as Dictionary).has("pecho") and String(spk["sp"]["pecho"]["marca"]) == "Cerveza Andina", "el contrato principal va al pecho (sin la cubierta)")
	var ajenos := 0
	for cc: Club in ms.ligas[0].clubes:
		if cc != ms.mi_club() and not SponsorKit.de_club(cc, ms).is_empty():
			ajenos += 1
	_comprobar(ajenos > 0 and SponsorKit.de_club(ms.ligas[0].clubes[3], ms) == SponsorKit.de_club(ms.ligas[0].clubes[3], ms), "los rivales llevan sus sponsors, siempre los mismos")
	var im := SponsorKit.imagen("Seguros Patagonia", "#8fa3b5", Color.WHITE)
	_comprobar(im.get_width() > im.get_height() and SponsorKit.lineas_de("SEGUROS PATAGONIA").size() == 2, "los nombres largos van en dos líneas")
	var un := DisenosKit.uniforms(spk, 9)
	_comprobar(bool(un["hay_sp_pecho"]) and un["sp_pecho"] is Texture2D, "el sponsor llega al shader 3D")
	ms.mi_club().kit_x = {"sp_ocultar": ["pecho"]}
	_comprobar(not (DisenosKit.kit_de_club(ms.mi_club())["sp"] as Dictionary).has("pecho"), "se puede no estampar una zona")
	_comprobar(DisenosKit.ACCESORIOS.size() >= 6, "accesorios para los jugadores")
	var cinco := DisenosKit.DISENOS.filter(func(d: Array) -> bool: return int(d[7]) == 5)
	_comprobar(not cinco.is_empty(), "hay diseños que usan los 5 colores")
	## La fórmula 2D da colores de la paleta.
	var cols: Array[Color] = [Color.RED, Color.WHITE, Color.BLUE, Color.YELLOW, Color.BLACK]
	var vistos := {}
	var d := DisenosKit.diseno("franjas_cinco")
	for i in 40:
		vistos[DisenosKit.color_en(d, cols, -1.0 + float(i) / 20.0, 0.5).to_html()] = true
	_comprobar(vistos.size() >= 4, "«Franjas de cinco colores» usa varios colores (%d)" % vistos.size())
	## El kit de un club, guardado y leído.
	var m := Mundo.new()
	m.generar(["CHI"], 5158)
	var c: Club = m.ligas[0].clubes[0]
	var k := DisenosKit.kit_de_club(c)
	_comprobar((k["cols"] as Array).size() == 5 and k.has("bot") and k.has("acc"), "la equipación completa tiene 5 colores, botines y accesorios")
	c.kit_x = {"dis": "tartan", "bot": {"mod": "fuego"}, "acc": {"guantes": "111111"}}
	var dic := c.identidad_a_dic()
	var c2 := Club.new()
	c2.identidad_desde_dic(dic)
	_comprobar(String(DisenosKit.kit_de_club(c2)["dis"]) == "tartan", "el diseño elegido se guarda con el club")
	var u := DisenosKit.uniforms(DisenosKit.kit_de_club(c2), 10)
	_comprobar(int(u["familia"]) == 26 and (u["acc_guantes"] as Color).a > 0.5 and int(u["dorsal"]) == 10, "el shader recibe diseño, accesorios y dorsal")
	_comprobar(DisenosKit.textura_camiseta("tartan", cols, 1, 64) != null, "la miniatura 2D se dibuja")

func _probar_region_reales() -> void:
	_titulo("REGIÓN REAL: VASCOS FUERA DEL ATHLETIC")
	var antes := Datos.usar_base_real(true)
	Reales.invalidar()
	var m := Mundo.new()
	m.generar(["ESP"], 4242)
	var ath: Club = null
	var vascos := 0
	var falsos := 0
	for c: Club in m.clubes.values():
		if Nombres.limpiar(c.nombre) == "Ath. Bilbao":
			ath = c
		for j: Jugador in c.plantilla:
			if not j.real:
				continue
			## Con la cubierta de nombres, algún apellido sale en minúscula.
			var n := Nombres.limpiar(j.nombre).to_lower()
			if n in ["mikel oyarzabal", "martín zubimendi", "aimar oroz"]:
				if j.region == "EUS":
					vascos += 1
			elif n in ["pedri", "koke", "iago aspas", "isco"] and j.region != "":
				falsos += 1
	_comprobar(vascos >= 3, "Oyarzabal, Zubimendi y Oroz son de Euskal Herria (%d)" % vascos)
	_comprobar(falsos == 0, "los reales de otras regiones no heredan una región sorteada")
	if ath != null:
		var oya: Jugador = null
		for c: Club in m.clubes.values():
			for j: Jugador in c.plantilla:
				if Nombres.limpiar(j.nombre).to_lower() == "mikel oyarzabal":
					oya = j
		_comprobar(oya != null and Regiones.admite(ath, oya), "el Athletic puede fichar a Oyarzabal")
	Datos.usar_base_real(antes)
	Reales.invalidar()

func _probar_sancion_dt() -> void:
	_titulo("ESTADIO 2.0: SANCIÓN AL DT Y LA GRADA")
	var m := Mundo.new()
	m.generar(["CHI"], 515)
	var f := m.federacion
	f.sancionar_dt(2)
	_comprobar(not f.dt_sancionado(), "el partido de la expulsión no cuenta como sanción")
	f.cumplir_sancion_dt()
	_comprobar(f.dt_sancionado() and f.dt_suspension == 2, "los dos siguientes, desde la grada (%d)" % f.dt_suspension)
	f.cumplir_sancion_dt()
	f.cumplir_sancion_dt()
	_comprobar(not f.dt_sancionado() and f.dt_suspension == 0, "cumplida, vuelve a la banda")
	f.sancionar_dt(1)
	var f2 := Federacion.new()
	f2.desde_dic(f.a_dic())
	_comprobar(f2.dt_suspension == 1 and f2.dt_susp_nueva, "la sanción se guarda con la partida")
	var b := RecorridoClub.butaca({"forma": "cuenco"}, 1.0, 10.0)
	_comprobar((b["pos"] as Vector3).x > 43.5 and (b["pos"] as Vector3).y > 2.0, "la butaca está en la primera bandeja de la grada")
	_comprobar(RecorridoClub.junto_a_la_grada(Vector3(35, 0, 0), 0) and not RecorridoClub.junto_a_la_grada(Vector3(0, 0, 0), 0), "solo se sienta uno desde la banda")
	## 21-10: los pasillos de la grada y la cinta LED existen. (La butaca real y
	## el hincha que se aparta se comprueban con pantalla: sin ella, Godot no
	## guarda las posiciones de los MultiMesh — `captura_sentarse`.)
	var raiz_b := Node3D.new()
	add_child(raiz_b)
	StadiumBuilder.build(raiz_b, {"forma": "cuenco", "niveles": 2}, 30000, 0.9, 7)
	_comprobar(raiz_b.find_children("Pasillos", "MultiMeshInstance3D", true, false).size() >= 4
		and raiz_b.find_children("Barandillas", "MultiMeshInstance3D", true, false).size() >= 4, "la grada tiene pasillos con escalera y barandilla")
	_comprobar(raiz_b.find_children("CintaLED", "MeshInstance3D", true, false).size() >= 1, "el peto de la bandeja de arriba lleva cinta LED")
	raiz_b.free()

func _probar_tanda_top25b() -> void:
	_titulo("TOP 25 (2.ª TANDA): CAMBIO, SORTEO, VALORACIONES, ESCUDO, DESPIDO")
	## M-104: el cartel del cambio, con los dos dorsales por las dos caras.
	var cartel := CuartoArbitro.cartel_lineas([["9", CuartoArbitro.VERDE], ["17", CuartoArbitro.ROJO]])
	var nueves := 0
	var diecisiete := 0
	for l in cartel.find_children("*", "Label3D", true, false):
		nueves += 1 if (l as Label3D).text == "9" else 0
		diecisiete += 1 if (l as Label3D).text == "17" and (l as Label3D).modulate == CuartoArbitro.ROJO else 0
	_comprobar(nueves == 2 and diecisiete == 2, "cambio: cartel con el que entra (verde) y el que sale (rojo) por las dos caras")
	cartel.free()
	## M-104: la escena (el que entra espera sujeto, palmada, se suelta, se va).
	var motor := MotorJugable.new()
	add_child(motor)
	motor.set_physics_process(false)
	var raiz := Node3D.new()
	add_child(raiz)
	var sale := Node3D.new()
	raiz.add_child(sale)
	sale.position = Vector3(30.0, 0, 2.0)
	var en_nodo := Node3D.new()
	raiz.add_child(en_nodo)
	en_nodo.position = Vector3(10.0, 0, 0)
	var entra := {"node": en_nodo, "vel": Vector3.ONE}
	var esc := EscenaCambio.iniciar(raiz, null, motor, sale, null, entra, 17, 9)
	_comprobar(esc != null and raiz.get_node_or_null("CuartoArbitro") != null, "cambio: sale el cuarto árbitro con el cartel")
	var fases: Array = []
	var quieto := true
	for i in 120:
		motor.t += 0.1
		en_nodo.position += Vector3(-0.3, 0, 0)   ## como si el motor lo moviera
		if is_instance_valid(esc):
			esc._process(0.1)
			if not fases.has(esc.fase):
				fases.append(esc.fase)
			if esc.fase == "acude" and en_nodo.position.distance_to(Vector3(EscenaCambio.X_LINEA, 0, EscenaCambio.Z_ESPERA)) > 0.01:
				quieto = false
	_comprobar(quieto, "cambio: el que entra espera en la banda hasta la palmada")
	_comprobar(fases.has("palmada") and fases.has("se_va"), "cambio: se chocan la mano y el que sale se va (%s)" % str(fases))
	_comprobar(float(entra.get("freno_duelo", 0.0)) == 1.0, "cambio: el que entra queda suelto después")
	_comprobar(not is_instance_valid(esc) or esc.is_queued_for_deletion(), "cambio: la escena se borra sola")
	motor.queue_free()
	raiz.queue_free()
	## M-160 y clips: el sorteo cabe en la ceremonia; los gestos existen.
	_comprobar(CeremoniaPartido.T_FIN >= CeremoniaPartido.T_VUELO + CeremoniaPartido.T_SALIDA + CeremoniaPartido.T_FILA * 2.0 + 3.5
		and CeremoniaPartido.T_SORTEO <= 5.0, "sorteo: ≈4 s al final de la ceremonia")
	var expr: Array = AnimFutbol.familias()["expresivo"]
	_comprobar(expr.has("chocar_mano") and expr.has("dar_mano"), "clips nuevos: chocar_mano y dar_mano")
	## M-141: valoraciones deterministas, ordenadas y sin tocar el resultado.
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	p.simular()
	var v1 := p.valoraciones()
	var v2 := p.valoraciones()
	var orden := true
	for i in range(1, v1.size()):
		if float(v1[i]["nota"]) > float(v1[i - 1]["nota"]):
			orden = false
	_comprobar(v1.size() >= 22 and orden, "valoraciones: los 22, de mejor a peor (%d)" % v1.size())
	var iguales := v1.size() == v2.size()
	for i in mini(v1.size(), v2.size()):
		iguales = iguales and float(v1[i]["nota"]) == float(v2[i]["nota"])
	_comprobar(iguales, "valoraciones: pedirlas dos veces da lo mismo")
	var rango := true
	for x: Dictionary in v1:
		rango = rango and float(x["nota"]) >= 3.0 and float(x["nota"]) <= 10.0
	_comprobar(rango, "valoraciones: entre 3 y 10")
	_comprobar(p.mejor_del_partido() == v1[0], "valoraciones: el mejor del partido es el primero")
	## 19-10: un partido MIRADO (minuto a minuto, sin `simular()`) también
	## cierra notas y forma, una sola vez y sin tocar el azar.
	var par2 := m.proximo_partido()
	var pm := Partido.new(par2[1], par2[0])
	pm.preparar()
	while not pm.terminado_ya:
		pm.simular_minuto()
	var j0: Jugador = pm.once_local[0]
	var antes_n := j0.notas.size()
	var antes_p := j0.partidos
	pm.cerrar_notas_mirado()
	pm.cerrar_notas_mirado()
	_comprobar(j0.partidos == antes_p + 1 and (j0.notas.size() == antes_n + 1 or antes_n >= 8),
		"partido mirado: cuenta en notas y partidos una sola vez")
	## M-238: el resumen de la etapa del despido.
	var filas := EscenaDespido.datos_etapa(m)
	var claves: Array = []
	for f: Array in filas:
		claves.append(f[0])
	_comprobar(claves.has("Temporadas") and claves.has("Títulos") and claves.has("Balance (G-E-P)"), "despido: resumen con temporadas, balance y títulos")
	## M-051: el escudo, más grande y con relieve.
	var sh := load("res://visor/equipacion_q.gdshader") as Shader
	_comprobar(sh.code.contains("h_escudo") and sh.code.contains("/ 0.104 + 0.5"), "escudo: 10,4 cm de ancho y relieve en el shader")

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

## 27-10 (pieza D): los peluches coleccionables, la máquina funcional y sus logros.
func _probar_peluches() -> void:
	_titulo("PELUCHES: TABLA, PARTIDA, ÁLBUM Y LOGROS")
	var ids := {}
	var series := {}
	for p: Dictionary in Peluches.PELUCHES:
		ids[String(p["id"])] = true
		series[String(p["serie"])] = true
	_comprobar(Peluches.PELUCHES.size() == 14 and ids.size() == 14 and series.size() == Peluches.SERIES.size(), "tabla: 14 peluches con ids distintos en %d series" % series.size())
	_comprobar(Peluches.de_maquina(0).size() >= 3 and Peluches.de_maquina(1).size() >= 3 and Peluches.de_maquina(2).size() >= 3, "cada una de las tres máquinas trae al menos tres peluches")
	var c1 := Peluches.campo(1, 77)
	var c2 := Peluches.campo(1, 77)
	var solape := false
	var ajeno := false
	for i in c1.size():
		ajeno = ajeno or int(Peluches.def(String(c1[i]["id"]))["maquina"]) != 1
		for j in range(i + 1, c1.size()):
			solape = solape or Vector2(float(c1[i]["x"]) - float(c1[j]["x"]), float(c1[i]["y"]) - float(c1[j]["y"])).length() < 0.2
	_comprobar(c1.size() >= 5 and str(c1) == str(c2) and not solape and not ajeno, "el campo (%d peluches) sale de la semilla, sin solapes y solo con los de su máquina" % c1.size())
	var pe := Peluches.new()
	var ligero := Peluches.def("pollito")
	var pesado := Peluches.def("ballena")
	_comprobar(pe.probabilidad(ligero, 0.0) > pe.probabilidad(pesado, 0.0) and pe.probabilidad(ligero, 0.0) > pe.probabilidad(ligero, 0.1), "agarra mejor lo ligero y lo que tiene la garra encima")
	_comprobar(pe.probabilidad(ligero, Peluches.RADIO_AGARRE + 0.01) == 0.0, "fuera del radio no hay agarre")
	var p0 := pe.probabilidad(pesado, 0.05)
	pe.fallos_seguidos = 3
	_comprobar(pe.probabilidad(pesado, 0.05) > p0 and pe.probabilidad(pesado, 0.05) <= 0.95, "cada fallo seguido sube la probabilidad (nunca es imposible ni segura)")
	pe.fallos_seguidos = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var campo_a: Array = [{"id": "oso", "x": 0.5, "y": 0.5}]
	var aire := pe.intento(campo_a, 0.05, 0.05, rng)
	_comprobar(int(aire["indice"]) == -1 and not bool(aire["exito"]) and pe.fallos_seguidos == 1, "cerrar la garra en el aire falla y cuenta como intento fallido")
	pe.fallos_seguidos = 0
	var aciertos := 0
	for i in 400:
		pe.fallos_seguidos = 0
		if bool(pe.intento(campo_a, 0.5, 0.5, rng)["exito"]):
			aciertos += 1
	_comprobar(aciertos > 160 and aciertos < 320, "un oso (peso 3) justo debajo de la garra se agarra en torno al 50-60 %% (%d de 400)" % aciertos)
	var album := Peluches.new()
	var nuevos: Array = []
	for p: Dictionary in Peluches.de_serie("bosque"):
		nuevos = album.conseguir(String(p["id"]))
	_comprobar(nuevos == ["serie_bosque"] and album.serie_completa("bosque") and not album.completa(), "completar una serie da su logro (y solo ese)")
	_comprobar(album.conseguir("oso").is_empty() and int(album.conseguidos["oso"]) == 2, "repetir un peluche no repite el logro (y cuenta las veces)")
	var todos: Array = []
	for p: Dictionary in Peluches.PELUCHES:
		todos.append_array(album.conseguir(String(p["id"])))
	_comprobar(album.completa() and album.logros.size() == Peluches.SERIES.size() + 1 and album.logros.has(Peluches.LOGRO_TODO) and todos.has(Peluches.LOGRO_TODO), "con los 14: un logro por serie y otro por la colección entera (%d logros)" % album.logros.size())
	var mundo_p := Mundo.new()
	var roles := Roles.new(mundo_p)
	roles.peluches.conseguir("dragon")
	roles.peluches.fallos_seguidos = 2
	var copia := Roles.new(mundo_p)
	copia.desde_dic(roles.a_dic())
	_comprobar(copia.peluches.tiene("dragon") and copia.peluches.fallos_seguidos == 2, "el álbum se guarda y se carga con la partida")
	var vieja := Roles.new(mundo_p)
	var d: Dictionary = roles.a_dic()
	d.erase("peluches")
	vieja.desde_dic(d)
	_comprobar(vieja.peluches.distintos() == 0, "una partida vieja (sin álbum) empieza con el álbum vacío")
	## La máquina: monedas del efectivo y partidas hasta ganar.
	var panel := PanelPeluches.new()
	panel.roles = Roles.new(mundo_p)
	panel.dia = 3
	panel.maquina = 0
	panel._montar()
	panel.roles.cartera.efectivo = 0
	panel._insertar()
	_comprobar(panel.fase == PanelPeluches.ESPERA and panel.roles.cartera.efectivo == 0, "sin monedas en el bolsillo la máquina no arranca")
	panel.roles.cartera.efectivo = 60
	var gano := 0
	var jugadas := 0
	for k in 50:
		panel._insertar()
		if panel.fase != PanelPeluches.MOVER:
			break
		jugadas += 1
		var objetivo: Dictionary = panel.campo[k % panel.campo.size()]
		panel.garra = Vector2(float(objetivo["x"]), float(objetivo["y"]))
		panel.soltar()
		var pasos := 0
		while panel.fase != PanelPeluches.FIN and pasos < 200:
			panel._process(0.1)
			pasos += 1
		if panel._gana != "":
			gano += 1
	_comprobar(jugadas == 50 and panel.roles.cartera.efectivo == 60 - jugadas * Peluches.MONEDA, "cada partida cuesta una moneda del efectivo (%d partidas, quedan %d €)" % [jugadas, panel.roles.cartera.efectivo])
	_comprobar(gano >= 10 and panel.roles.peluches.distintos() >= 3, "apuntando bien se gana a menudo (%d de %d) y el álbum crece (%d distintos)" % [gano, jugadas, panel.roles.peluches.distintos()])
	panel.free()
	var cb := CityBuilder.new()
	add_child(cb)
	var puestas := CiudadArcade.montar(cb, Vector3(0, 0.12, 0), 80.0, 60.0)
	var puntos := 0
	for pc: Dictionary in cb.puntos_clic:
		if String(pc.get("k", "")).begins_with("peluches_"):
			puntos += 1
	_comprobar(puestas == 3 and puntos == 3, "la sala del centro comercial tiene 3 máquinas y las tres son puntos de la E (%d)" % puntos)
	_comprobar(not PeluchesCiudad.servicio(null, "cajero_1"), "el gancho de la E ignora lo que no es una máquina de peluches")
	for p: Dictionary in Peluches.PELUCHES:
		var n := PelucheModelo.montar(p)
		if String(p["id"]) in ["oso", "ballena", "dragon"]:
			_comprobar(n.get_child_count() >= 7, "el peluche «%s» se dibuja (%d piezas)" % [String(p["id"]), n.get_child_count()])
		n.free()
	## La estantería del álbum en la vivienda: más peluches ganados, más peluches en la balda.
	PeluchesCiudad.album = Peluches.new()
	var r0 := Node3D.new()
	var sala0 := InteriorInstalacion.en_mundo(r0, "edificio_vivienda")
	var sin_nada := r0.get_child_count()
	PeluchesCiudad.album.conseguir("oso")
	PeluchesCiudad.album.conseguir("pollito")
	PeluchesCiudad.album.conseguir("dragon")
	var r1 := Node3D.new()
	var sala1 := InteriorInstalacion.en_mundo(r1, "edificio_vivienda")
	_comprobar(r1.get_child_count() == sin_nada + 3, "la estantería de la vivienda enseña los peluches ganados (%d → %d nodos)" % [sin_nada, r1.get_child_count()])
	PeluchesCiudad.album = null
	for x: Node in [sala0, sala1, r0, r1]:
		if x != null:
			x.free()
	cb.queue_free()
