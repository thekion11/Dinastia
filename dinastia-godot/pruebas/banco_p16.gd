extends "res://pruebas/banco_p15.gd"
## [Capa 17/27 de `banco.gd`] _probar_documental, _probar_dinastias, _probar_minijuegos, _probar_rotulo_y_sala, _probar_ciudad_grande, _probar_ciudad_animo … (+3)

## EL DOCUMENTAL DE LA TEMPORADA (fase 5): cuenta datos reales del año.
func _probar_documental() -> void:
	_titulo("DOCUMENTAL DE LA TEMPORADA (FASE 5)")
	var m := Mundo.new()
	m.generar(["CHI"], 303)
	m.tomar_el_mando(m.ligas[0].clubes[1].id)
	var sem := 0
	while m.temporada_en_curso() and sem < 80:
		m.avanzar_semana()
		sem += 1
	var caps := DocumentalTemporada.guion(m)
	_comprobar(caps.size() >= 6, "%d capítulos en el documental" % caps.size())
	var mio := m.mi_club()
	var gol: Jugador = null
	for j: Jugador in mio.plantilla:
		if gol == null or j.goles > gol.goles:
			gol = j
	var dice_goleador := false
	var dice_veredicto := false
	for cap: Dictionary in caps:
		if String(cap["titulo"]).contains("goleador") and String(cap["texto"]).contains(gol.nombre) and String(cap["texto"]).contains(str(gol.goles)):
			dice_goleador = true
		if String(cap["titulo"]).contains("veredicto"):
			dice_veredicto = true
	_comprobar(dice_goleador, "el capítulo del goleador nombra al de verdad (%s, %d)" % [gol.nombre, gol.goles])
	_comprobar(dice_veredicto, "hay veredicto final con el puesto")

## DINASTÍAS FAMILIARES (fase 5): tu hijo llega a la cantera que diriges.
func _probar_dinastias() -> void:
	_titulo("DINASTÍAS FAMILIARES (FASE 5)")
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	var mio := m.mi_club()
	while mio.plantilla.size() > 26:
		mio.plantilla.pop_back()
	## 1) Leyenda propia (de la Carrera de Jugador).
	m.cantera.leyendas.append({"nombre": "Ramiro Valdivia", "club_id": m.ligas[0].clubes[7].id, "pos": "DEL",
		"nivel": 86, "anio_hijo": m.anio, "usado": false, "propio": true})
	var copia := Cantera.new(m)
	copia.desde_dic(m.cantera.a_dic())
	var guardado_propio := false
	for L: Dictionary in copia.leyendas:
		if String(L["nombre"]) == "Ramiro Valdivia" and bool(L.get("propio", false)):
			guardado_propio = true
	_comprobar(guardado_propio, "la dinastía propia sobrevive al guardado")
	m.cantera.call("_hijos_de_leyendas")
	var hijo: Jugador = null
	for j: Jugador in mio.plantilla:
		if j.nombre.ends_with("Valdivia"):
			hijo = j
	_comprobar(hijo != null, "el hijo de tu jugador retirado llega a TU cantera (no a otro club)")
	if hijo != null:
		_comprobar(hijo.edad <= 17 and hijo.pot > hijo.ovr, "llega joven y con techo (%d años, %d → %d)" % [hijo.edad, hijo.ovr, hijo.pot])
	## 2) El hijo del entrenador (familia de VidaDT) al cumplir 16.
	m.vida.perfil = {"pareja": "", "hijos": [{"nombre": "Mateo", "edad": 15}], "mascota": "", "anio0": m.anio - 1}
	m.cantera.call("_hijos_del_dt")
	var del_dt := false
	for j2: Jugador in mio.plantilla:
		if j2.nombre.begins_with("Mateo "):
			del_dt = true
	_comprobar(del_dt, "el hijo del míster entra en la cantera al cumplir 16")

## LOS MINIJUEGOS (7-10-2026): tiros libres y trivia del club.
func _probar_minijuegos() -> void:
	_titulo("MINIJUEGOS: TIROS LIBRES Y TRIVIA DEL CLUB")
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.2) == "barrera", "potencia floja: barrera")
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.95) == "alto", "potencia pasada: por encima")
	_comprobar(MinijuegoTiroLibre.resultado_potencia(0.62) == "justo", "en el centro: con rosca")
	var h: Array[int] = [0, 0]
	_comprobar(MinijuegoTiroLibre.prob_atajada(0, h, "bueno") > MinijuegoTiroLibre.prob_atajada(0, [] as Array[int], "bueno"), "repetir zona: el portero se adelanta")
	var m := Mundo.new()
	m.generar(["CHI"], 21)
	m.tomar_el_mando(m.ligas[0].clubes[2].id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ps := TriviaClub.preguntas(m, rng)
	_comprobar(ps.size() >= 6, "%d preguntas de trivia con los datos de la partida" % ps.size())
	var bien := true
	for pr: Dictionary in ps:
		var ops: Array = pr["opciones"]
		if ops.size() < 3 or int(pr["correcta"]) < 0 or int(pr["correcta"]) >= ops.size():
			bien = false
	_comprobar(bien, "cada pregunta tiene opciones y la respuesta correcta está entre ellas")
	var c := m.mi_club()
	var cap := ""
	for j: Jugador in c.plantilla:
		if j.capitan:
			cap = j.nombre
	var ok_cap := true
	for pr2: Dictionary in ps:
		if String(pr2["q"]).contains("brazalete"):
			ok_cap = String(pr2["opciones"][int(pr2["correcta"])]) == cap
	_comprobar(ok_cap, "la respuesta del capitán es el capitán de verdad (%s)" % cap)

## LA CIUDAD GRANDE (7-10-2026): red vial en datos, semáforos, transporte.
func _probar_rotulo_y_sala() -> void:
	## 15-10-2026: el rótulo de la fachada y la sala de dentro se sorteaban por
	## separado («Farmacia» que abría un taller). Ahora manda el rótulo.
	_titulo("CIUDAD: LO QUE DICE EL RÓTULO ES LO QUE HAY DENTRO")
	var sin_sala: Array = []
	for com: Array in CiudadExpansion.COMERCIOS:
		var texto := String(com[0])
		var nombre := texto.substr(texto.find(" ") + 1)
		var k := String(ExploradorCiudad.SALA_DE_ROTULO.get(nombre, ""))
		if k == "" or not InteriorInstalacion.tiene(k):
			sin_sala.append(nombre)
	_comprobar(sin_sala.is_empty(), "los %d comercios tienen una sala que existe %s" % [CiudadExpansion.COMERCIOS.size(), str(sin_sala)])
	var cb := CityBuilder.new()
	cb.expansion = CiudadExpansion.new(cb)
	cb.expansion.rotulos = [
		{"pos": Vector3(100, 0, 50), "ancho": 8.0, "texto": "💊 Farmacia"},
		{"pos": Vector3(110, 0, 50), "ancho": 8.0, "texto": "🥖 Panadería"},
	]
	var ex := ExploradorCiudad.new()
	ex.cb = cb
	_comprobar(String(ex._rotulo_en(Vector3(101, 0, 51)).get("texto", "")) == "💊 Farmacia", "la puerta de la farmacia es la de la farmacia")
	_comprobar(String(ex._rotulo_en(Vector3(109, 0, 51)).get("texto", "")) == "🥖 Panadería", "y la de al lado, la de la panadería")
	_comprobar(ex._rotulo_en(Vector3(140, 0, 50)).is_empty(), "lejos de los rótulos no hay rótulo")
	ex.free()
	cb.free()
	## OCLUSIÓN (21-10-2026): 4 paredes por edificio grande; ni quioscos ni estadio.
	var cbo := CityBuilder.new()
	cbo._frentes = [Rect2(300, 300, 20, 30), Rect2(400, 400, 4, 4)] as Array[Rect2]
	cbo.huellas = [Rect2(300, 300, 20, 30), Rect2(CityBuilder.ESTADIO_EN.x - 10.0, CityBuilder.ESTADIO_EN.z - 10.0, 20, 20), Rect2(-500, 200, 12, 12)] as Array[Rect2]
	var raiz_o := OclusoresCiudad.montar(cbo)
	_comprobar(OclusoresCiudad.cuantas(cbo) == 8, "oclusión: 2 edificios grandes = 8 paredes (sin quiosco, sin estadio, sin repetir) → %d" % OclusoresCiudad.cuantas(cbo))
	OclusoresCiudad.activar(cbo, false)
	_comprobar(not raiz_o.visible, "oclusión: se apaga al entrar en un edificio")
	cbo.free()
	## EL CHOQUE DEL COCHE (21-10-2026, M-172): golpe y multa contra otro coche.
	var exc := ExploradorCiudad.new()
	exc.modo = "coche"
	exc._golpe_coche(12.0, false)
	_comprobar(exc.multas == 1 and exc._sacudida_golpe > 0.0, "chocar a 43 km/h contra otro coche: golpe y multa")
	exc._golpe_coche(12.0, false)
	_comprobar(exc.multas == 1, "rozando no se multa en bucle (un golpe cada medio segundo)")
	var exc2 := ExploradorCiudad.new()
	exc2._golpe_coche(5.0, false)
	var exc3 := ExploradorCiudad.new()
	exc3._golpe_coche(12.0, true)
	_comprobar(exc2.multas == 0 and exc3.multas == 0 and exc3._sacudida_golpe > 0.0, "despacio, o contra una pared, golpe sin multa")
	exc.free()
	exc2.free()
	exc3.free()
	_comprobar(Sonido.NOMBRES.has("choque_coche") and not Sonido._sintetizar("choque_coche", 1.0).data.is_empty(), "el choque de coche suena")

func _probar_ciudad_grande() -> void:
	_titulo("LA CIUDAD GRANDE: RED VIAL, SEMÁFOROS Y TRANSPORTE")
	var cb := CityBuilder.new()
	var e := CiudadExpansion.new(cb)
	e.armar_red()
	e.armar_bloques()
	e.armar_transporte()
	var lado := float(CiudadExpansion.K) * CiudadExpansion.CELDA * 2.0
	_comprobar(lado * lado >= 4.0 * 1200.0 * 1200.0, "la ciudad mide %d m de lado: más de 4 veces la superficie de antes" % int(lado))
	_comprobar(e.tramos.size() >= 900, "%d tramos de calle en la red" % e.tramos.size())
	var puentes := 0
	for t: Dictionary in e.tramos:
		if bool(t["puente"]):
			puentes += 1
	_comprobar(puentes >= 15, "%d tramos cruzan el río por puente" % puentes)
	_comprobar(e.cruces_semaforo.size() >= 40, "%d cruces con semáforo" % e.cruces_semaforo.size())
	## Marcas y aceras coherentes en los cruces (16-10-2026).
	var cruce_ca := Vector3(550, 0, -660)    ## calle (x=550) que cruza una avenida (z=-660)
	_comprobar(is_equal_approx(e.medio_cruce(cruce_ca, Vector3(0, 0, 1)), CiudadExpansion.ANCHO_AV * 0.5), "la calle sabe que la cruza una avenida de 24 m")
	_comprobar(e._fin_acera(cruce_ca, Vector3(0, 0, -1), Vector3(1, 0, 0), CiudadExpansion.ANCHO_CALLE, false) >= CiudadExpansion.ANCHO_AV * 0.5,
		"la acera de la calle no entra en la calzada de la avenida")
	var mal_rayas := 0
	for p: Vector3 in e.cruces_semaforo:
		for d: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			if e.ancho_brazo(p, d) > 0.0 and not e.es_puente(p, d) and e._libre_de_marcas(p, d) < e.linea_detencion(e.medio_cruce(p, d)):
				mal_rayas += 1
	_comprobar(mal_rayas == 0, "las rayas del centro no pisan cruces ni cebras (%d mal)" % mal_rayas)
	var camino := e.camino_entre(Vector2i(-12, -12), Vector2i(12, 12))
	_comprobar(camino.size() >= 25, "la red está conectada: de una esquina a la otra en %d cruces" % camino.size())
	var camino2 := e.camino_entre(Vector2i(-9, 0), Vector2i(9, 0))
	_comprobar(not camino2.is_empty(), "se cruza de la orilla oeste a la este (%d cruces)" % camino2.size())
	var en_rio := 0
	var usos := {}
	for bl: Dictionary in e.bloques:
		var r: Rect2 = bl["rect"]
		usos[bl["uso"]] = true
		if not (String(bl["uso"]) in ["rio", "puerto"]) and r.position.x < CityBuilder.RIO_X + 45.0 and r.end.x > CityBuilder.RIO_X - 45.0:
			en_rio += 1
	_comprobar(en_rio == 0, "ninguna manzana edificada encima del río")
	for u in ["ayuntamiento", "hospital", "comisaria", "bomberos", "escuela", "universidad", "estacion_central", "centro_comercial", "puerto", "casa_grande", "torres", "casas", "industrial"]:
		_comprobar(usos.has(u), "la ciudad tiene %s" % u)
	var est := 0
	for l: Dictionary in e.lineas_metro:
		est += (l["estaciones"] as Array).size()
	_comprobar(e.lineas_metro.size() == 2 and est >= 10, "metro: %d líneas, %d estaciones" % [e.lineas_metro.size(), est])
	## Las calles tienen nombre: en un cruce, las dos; dentro de una manzana, ninguno.
	var cruce := e.nombre_calle_en(Vector3(990.0, 0, -990.0))
	var en_fila := e.nombre_calle_en(Vector3(1045.0, 0, -988.0))
	var en_col := e.nombre_calle_en(Vector3(1100.0, 0, -940.0))
	var en_manzana := e.nombre_calle_en(Vector3(1045.0, 0, -935.0))
	_comprobar(cruce.contains(" con ") and en_fila.begins_with("Avenida") and en_col.begins_with("Calle") and en_manzana == "" and e.nombre_calle_en(Vector3.ZERO) == "",
		"nombres de calle: «%s» · «%s» · «%s»" % [cruce, en_fila, en_col])
	var paradas := 0
	for l: Dictionary in e.lineas_bus:
		paradas += (l["paradas"] as Array).size()
	_comprobar(paradas >= 10, "autobuses: %d paradas" % paradas)
	## El metro: un tren va, para en cada estación y da la vuelta en la cabecera.
	var est_metro := PackedFloat32Array([220.0, 550.0, 880.0, 1210.0, 1540.0, 1870.0, 2200.0])
	var tren := MetroCiudad.Tren.new(2420.0, est_metro, 300.0, 1.0)
	var dentro := true
	var giro := false
	for k in 6000:
		var antes := tren.sentido
		tren.simular(0.1)
		if tren.sentido != antes:
			giro = true
		if tren.s < -1.0 or tren.s > 2421.0:
			dentro = false
	_comprobar(tren.paradas_hechas >= 6, "el tren del metro paró en %d estaciones en 10 minutos" % tren.paradas_hechas)
	_comprobar(giro and dentro, "el tren da la vuelta en la cabecera sin salirse de la vía")
	## El modo a pie / al volante: choques y puentes.
	var obst: Array[Rect2] = [Rect2(100, 100, 50, 50)]
	_comprobar(not ExploradorCiudad.libre(Vector3(120, 0, 120), 1.0, obst), "no se atraviesa una manzana")
	_comprobar(ExploradorCiudad.libre(Vector3(200, 0, 200), 1.0, obst), "por la calle se pasa")
	_comprobar(not ExploradorCiudad.libre(Vector3(CityBuilder.RIO_X, 0, 55.0), 1.0, obst), "no se cae al río fuera de un puente")
	_comprobar(ExploradorCiudad.libre(Vector3(CityBuilder.RIO_X, 0, 0.0), 1.0, obst), "por el puente sí se cruza")
	_comprobar(ExploradorCiudad.altura_suelo(CityBuilder.RIO_X, 0.0) > 4.0 and ExploradorCiudad.altura_suelo(CityBuilder.RIO_X + 100.0, 0.0) < 0.5, "sobre el puente se va arriba y fuera de él, a ras de suelo")
	_comprobar(MinijuegosCiudad.juego_de("ciudad_plaza_mayor") == "autografos" and MinijuegosCiudad.juego_de("ciudad_puerto") == "pesca" and MinijuegosCiudad.juego_de("karting") == "karting", "cada lugar de la ciudad lleva su minijuego")
	## El circuito 3D del karting: el progreso medido sobre la trazada coincide
	## con la distancia recorrida, y la trazada está siempre sobre el asfalto.
	var mk := MinijuegosCiudad.new()
	var err := 0.0
	var fuera := 0.0
	for k in 200:
		var s_k := mk._largo_pista() * float(k) / 200.0
		var c: Dictionary = mk._centro_pista(s_k)
		err = maxf(err, absf(mk._progreso(c["p"]) - s_k))
		fuera = maxf(fuera, mk._fuera_de_eje(c["p"]))
	_comprobar(err < 0.05 and fuera < 0.01, "karting 3D: progreso exacto (error %.3f m) y trazada sobre el eje (%.3f m)" % [err, fuera])
	mk.free()
	var sem := Semaforos.new()
	var vistos := {}
	var cruzados := 0
	for k in 80:
		sem.t = float(k) * 0.5
		vistos["%s%s" % [sem.estado(0), sem.estado(1)]] = true
		if sem.verde(0) and sem.verde(1):
			cruzados += 1
	_comprobar(cruzados == 0, "nunca verde en los dos ejes a la vez")
	_comprobar(vistos.has("vr") and vistos.has("rv") and vistos.has("ar"), "el ciclo pasa por verde, ámbar y rojo en cada eje")
	sem.free()
	cb.free()

## FASE 5: la ciudad responde al club.
func _probar_ciudad_animo() -> void:
	_titulo("LA CIUDAD RESPONDE AL CLUB (FASE 5)")
	_comprobar(CiudadAnimo.evaluar(1, 16, 30, 30, 4, 5, 2, true)["estado"] == "euforia", "campeón → euforia")
	_comprobar(CiudadAnimo.evaluar(16, 16, 30, 30, -3, 5, 2, true)["estado"] == "crisis", "descendido → crisis")
	_comprobar(CiudadAnimo.evaluar(8, 16, 15, 30, 0, 5, 2, false)["estado"] == "normal", "mitad de tabla sin racha → normal")
	_comprobar(CiudadAnimo.evaluar(2, 16, 20, 30, 5, 5, 2, false)["estado"] in ["bien", "euforia"], "segundo con cinco victorias → buen ambiente")
	_comprobar(CiudadAnimo.evaluar(15, 16, 22, 30, -1, 5, 2, false)["valor"] <= -0.6, "en descenso a falta de un tercio: al menos «mal»")
	_comprobar(CiudadAnimo.evaluar(1, 16, 0, 30, 0, 0, 2, false)["estado"] == "normal", "antes de la 1.ª jornada: normal")
	var frentes: Array = []
	for i in 40:
		frentes.append(Rect2(float(i) * 12.0 - 240.0, 300.0, 10.0, 10.0))
	var raiz := Node3D.new()
	var e := CiudadAnimo.montar(raiz, {"estado": "euforia"}, frentes, Vector3(0, 0, -150), Color.RED, Color.WHITE)
	var raiz2 := Node3D.new()
	var c := CiudadAnimo.montar(raiz2, {"estado": "crisis"}, frentes, Vector3(0, 0, -150), Color.RED, Color.WHITE)
	_comprobar(int(e["pancartas"]) >= 35 and int(e["grafitis"]) == 0, "euforia: pancartas en las fachadas (%d), ningún grafiti" % e["pancartas"])
	_comprobar(int(c["persianas"]) >= 20 and int(c["grafitis"]) >= 10 and int(c["pancartas"]) == 0, "crisis: persianas (%d) y grafitis (%d), ninguna pancarta" % [c["persianas"], c["grafitis"]])
	raiz.free()
	raiz2.free()
	var m := Mundo.new()
	m.generar(["CHI"], 55)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for k in 6:
		m.avanzar_semana()
	var a := CiudadAnimo.de(m, m.mi_club())
	_comprobar(String(a["estado"]) in CiudadAnimo.ESTADOS and String(a["motivo"]) != "", "el ánimo sale del mundo real: %s (%s)" % [a["estado"], a["motivo"]])

## FASE 4: el mini-juego de representantes (la mesa de regateo).
func _probar_mesa_agente() -> void:
	_titulo("MINI-JUEGO DE REPRESENTANTES (FASE 4)")
	var ex := {"tipo": "mejora", "agente": "R. Prueba", "perfil": "discreto", "pid": "j1"}
	var m := MesaAgente.new(ex, 0, 0.0, 7)
	m.ceder()
	_comprobar(m.estado == "acuerdo" and is_equal_approx(m.fraccion(), 1.0), "ceder cierra al 100 %")
	m = MesaAgente.new(ex, 0, 0.0, 7)
	m.plantarse()
	_comprobar(m.estado == "plantado" and m.fraccion() < 0.0, "plantarse es un no")
	m = MesaAgente.new(ex, 0, 0.0, 7)
	var rondas := 0
	while m.estado == "abierta" and rondas < 20:
		m.regatear(0)
		rondas += 1
	_comprobar(m.estado == "se_fue" and rondas <= m.paciencia_max, "ofrecer nada lo ofende: se va en %d rondas (paciencia %d)" % [rondas, m.paciencia_max])
	m = MesaAgente.new(ex, 0, 0.0, 7)
	m.farol()
	var pide := m.pide
	var pac := m.paciencia
	m.farol()
	_comprobar(m.farol_usado and m.pide == pide and m.paciencia == pac, "un solo farol por mesa")
	## Una estrategia sensata (la oferta del medio; ceder a la última taza)
	## saca tratos mejores al formador que al tiburón, y casi siempre cierra.
	var medias := {}
	for perfil: String in ["formador", "tiburon"]:
		var suma := 0.0
		var tratos := 0
		for k in 300:
			var mm := MesaAgente.new({"tipo": "comision", "agente": "A%d" % k, "perfil": perfil}, 0, 0.0, 1000 + k)
			while mm.estado == "abierta":
				if mm.paciencia <= 1:
					mm.ceder()
				else:
					var o := mm.ofertas()
					mm.regatear(o[mini(1, o.size() - 1)])
			if mm.estado == "acuerdo":
				tratos += 1
				suma += float(mm.acordado)
		medias[perfil] = suma / maxf(1.0, float(tratos))
		_comprobar(tratos >= 240, "%s: %d de 300 mesas cierran con trato" % [perfil, tratos])
	_comprobar(float(medias["formador"]) + 8.0 < float(medias["tiburon"]), "el formador cede más que el tiburón (%.0f %% / %.0f %%)" % [medias["formador"], medias["tiburon"]])
	_comprobar(float(medias["tiburon"]) < 99.0, "regatear sirve: al tiburón tampoco se le paga siempre todo (%.0f %%)" % medias["tiburon"])
	## El trato se aplica a escala: una mejora al 50 % sube el sueldo un 15 %.
	var w := Mundo.new()
	w.generar(["CHI"], 31)
	w.tomar_el_mando(w.ligas[0].clubes[0].id)
	var j: Jugador = w.mi_club().plantilla[0]
	var antes := j.sueldo
	w.cantera.exigencia = {"tipo": "mejora", "agente": "R. Prueba", "pid": j.id, "ids": [j.id], "perfil": "discreto"}
	var r := w.cantera.resolver_agente("a", 0.5)
	_comprobar(absi(j.sueldo - int(round(float(antes) * 1.15))) <= 1, "mejora pactada al 50 %%: sueldo %d → %d (+15 %%)" % [antes, j.sueldo])
	_comprobar(String(r.get("cuerpo", "")).contains("50 %"), "la noticia cuenta lo pactado en la mesa")

## FASE 4: las plantillas de arranque son las mismas con cualquier semilla y
## con cualquier mezcla de países cargados (sembradas con el nombre del club).
func _probar_plantillas_fijas() -> void:
	_titulo("PLANTILLAS FIJAS DE ARRANQUE (FASE 4)")
	var a := Mundo.new()
	a.generar(["CHI", "GER"], 5)
	var b := Mundo.new()
	b.generar(["CHI", "ARG", "GER", "ESP"], 424242)
	var firma := func(c: Club) -> Array:
		var f: Array = []
		for j: Jugador in c.plantilla:
			f.append("%s|%s|%d|%d|%d" % [j.nombre, j.pos_e, j.edad, j.ovr, j.pot])
		f.sort()
		return f
	var por_nombre := {}
	for c: Club in b.clubes.values():
		por_nombre[c.nombre] = c
	var iguales := 0
	var sin_reales := 0
	var total := 0
	for c: Club in a.clubes.values():
		if not por_nombre.has(c.nombre):
			continue
		total += 1
		var reales := 0
		for j: Jugador in c.plantilla:
			if j.real:
				reales += 1
		if reales == 0:
			sin_reales += 1
		if firma.call(c) == firma.call(por_nombre[c.nombre]):
			iguales += 1
	_comprobar(total >= 40, "%d clubes (Chile y Alemania) en los dos mundos" % total)
	_comprobar(iguales == total, "misma plantilla (nombre, puesto, edad, media, potencial) con otra semilla y otros países: %d de %d" % [iguales, total])
	_comprobar(sin_reales >= 1, "incluye clubes sin tabla REALES (%d)" % sin_reales)
	## Los canteranos que llegan después siguen siendo de cada partida.
	var j1 := a.crear_jugador(a.ligas[0].clubes[0], "DEL", "DC")
	var j2 := b.crear_jugador(a.ligas[0].clubes[0], "DEL", "DC")
	_comprobar(j1.nombre != j2.nombre or j1.ovr != j2.ovr, "lo que nace después varía con la semilla (%s / %s)" % [j1.nombre, j2.nombre])

## FASE 4, E9: el rasgo del estadio real se DIBUJA y le da un apodo genérico.
func _probar_guinos_estadio() -> void:
	_titulo("GUIÑOS DE LOS ESTADIOS REALES (FASE 4, E9)")
	_comprobar(GuinosEstadio.apodo({"rasgo": "Herradura abierta a la cordillera"}) == "El Mirador", "cordillera → «El Mirador»")
	_comprobar(GuinosEstadio.apodo({"rasgo": "La caldera: tres bandejas"}) == "La Caldera", "caldera → «La Caldera»")
	_comprobar(GuinosEstadio.apodo({"rasgo": "", "niveles": 1}) == "", "sin rasgo ni tamaño: sin apodo inventado")
	var tabla: Dictionary = Datos.tabla("ESTADIO_CLUB")
	var con_apodo := 0
	for k: String in tabla:
		if GuinosEstadio.apodo(tabla[k]) != "":
			con_apodo += 1
	_comprobar(con_apodo >= 100, "%d de %d estadios reales con apodo (≥100)" % [con_apodo, tabla.size()])
	for caso: Array in [["Herradura abierta a la cordillera", 6], ["Cuatro torres rojas en las esquinas", 4], ["Junto al río", 1], ["Estadio minero en pleno desierto", 15]]:
		var raiz := Node3D.new()
		GuinosEstadio.montar(raiz, {"rasgo": caso[0]}, 40.0, 58.0, 20.0, 18.0)
		var n := raiz.get_child(0).get_child_count() if raiz.get_child_count() > 0 else 0
		_comprobar(n >= int(caso[1]), "«%s» dibuja %d piezas (≥%d)" % [caso[0], n, caso[1]])
		raiz.free()
