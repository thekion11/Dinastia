extends "res://pruebas/banco_p23.gd"
## (Parte 24 de 25 de `banco.gd`.)

func _probar_galeria_club() -> void:
	_titulo("GALERÍA SUBTERRÁNEA AL COMPLEJO (2.0, fase 6)")
	## En todas las formas y túneles: del pasillo del sótano se llega andando,
	## por zonas pisables, hasta arriba de la escalera mecánica.
	var fallos := []
	var largos := []
	for forma: String in ["cuenco", "oval", "rect", "caldera", "herradura", "ingles", "dos", "principal"]:
		for tunel: String in ["central", "esquina"]:
			var est := TunelVestuario.datos({"forma": forma, "tunel": tunel}, 2)
			var zonas: Array = GaleriaClub.zonas(est) + (est["zonas"] as Array)
			var t := GaleriaClub.trazado(est)
			var pasos: Array = [Vector3(float(t["xa"]), 0, float(est["z_fin"]) - 1.5), Vector3(float(t["xa"]), 0, float(t["zc"])),
				Vector3(float(t["xb"]), 0, float(t["zc"])), Vector3(float(t["xb"]), 0, float(t["z_esc"]) + 3.0)]
			var ok := true
			for i in pasos.size() - 1:
				var a: Vector3 = pasos[i]
				var b: Vector3 = pasos[i + 1]
				var n := int(a.distance_to(b) / 0.25) + 1
				for k in n + 1:
					var q := a.lerp(b, float(k) / float(n))
					if TunelVestuario.zona_en(zonas, q, GaleriaClub.PLANTA).is_empty():
						ok = false
			var fin := Vector3(float(t["xb"]), 0, float(t["z_esc"]) + 3.6)
			if not ok or not GaleriaClub.arriba(est, fin):
				fallos.append("%s/%s" % [forma, tunel])
			largos.append(GaleriaClub.metros_hasta(est, pasos[0]))
	_comprobar(fallos.is_empty(), "del sótano a la calle por la galería en las 8 formas %s" % str(fallos))
	_comprobar(largos.min() > 100 and largos.max() < 260, "la galería mide lo que separa estadio y complejo (%d-%d m)" % [largos.min(), largos.max()])
	## Sale delante del complejo, fuera de la avenida y antes de los edificios.
	var b := GaleriaClub.boca_mundo(TunelVestuario.datos({"forma": "cuenco"}, 2))
	_comprobar(absf(b.x) > 10.0 and b.z > 70.0 and b.z < CityBuilder.FILA_0_Z - 16.0, "la caseta queda junto al complejo, sin pisar la avenida (%s)" % str(b))
	## No se pisa fuera: ni la tierra junto a la galería ni otras plantas.
	var est2 := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var z2: Array = GaleriaClub.zonas(est2)
	var t2 := GaleriaClub.trazado(est2)
	_comprobar(TunelVestuario.zona_en(z2, Vector3(float(t2["xa"]) + 4.0, 0, 150.0), GaleriaClub.PLANTA).is_empty(), "la tierra de al lado no se pisa")
	_comprobar(TunelVestuario.zona_en(z2, Vector3(float(t2["xa"]), 0, 150.0), 0).is_empty(), "la galería solo está en la planta −2")
	## En el estadio suelto la puerta tiene persiana y se avisa al llegar.
	var ex := ExploradorEstadio.new()
	ex._datos = est2
	ex.cuerpo = Node3D.new()
	ex.cuerpo.position = Vector3(float(t2["xa"]), RecorridoClub.y_de(-2), float(est2["z_fin"]) - 1.0)
	_comprobar(ex._junto_a_la_persiana(), "junto a la persiana del sótano se avisa de la galería")
	ex.cuerpo.position.x -= 6.0
	_comprobar(not ex._junto_a_la_persiana(), "lejos de la persiana, no")
	ex.cuerpo.free()
	ex.free()

func _probar_reforma_con_obra() -> void:
	_titulo("EL MISMO ESTADIO EN TODAS PARTES: LAS REFORMAS TARDAN")
	var m := Mundo.new()
	m.generar(["CHI"], 424242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	if mio == null or m.estadio == null:
		_comprobar(false, "hay partida para probar la reforma")
		return
	mio.saldo = 999999999
	var antes := String(m.perfil_estadio_de(mio)["forma"])
	var nueva := "rect" if antes != "rect" else "oval"
	_comprobar(m.estadio.reformar(mio, {"forma": nueva}, m.obras) == "", "se encarga la reforma de la forma")
	_comprobar(m.estadio.en_obras() and String(m.perfil_estadio_de(mio)["forma"]) == antes,
		"mientras dura la obra se juega en el estadio de siempre")
	_comprobar("reforma" in (m.perfil_estadio_de(mio).get("en_obra", []) as Array), "y se ven los andamios")
	_comprobar(String(m.estadio.ajustes["forma"]) == nueva, "el diseñador enseña el proyecto")
	## La pintura no espera.
	var cal := String(m.perfil_estadio_de(mio)["lineaCol"])
	var nueva_cal := cal
	for o: Variant in m.estadio.opciones("lineaCol"):
		var v := String((o as Dictionary).get("clave", o)) if o is Dictionary else String(o)
		if v != cal:
			nueva_cal = v
			break
	var err_cal := m.estadio.reformar(mio, {"lineaCol": nueva_cal}, m.obras)
	_comprobar(err_cal == "" and nueva_cal != cal and String(m.perfil_estadio_de(mio)["lineaCol"]) == nueva_cal,
		"la pintura se ve al momento, aun en obras (%s)" % err_cal)
	var semanas := int(m.estadio.obra["semanas"])
	_comprobar(semanas == int(EstadioPropio.SEMANAS_OBRA["obra"]), "mover el graderío lleva %d semanas" % semanas)
	## Se guarda y se carga con la obra a medias.
	var otro := EstadioPropio.new()
	otro.desde_dic(m.estadio.a_dic())
	_comprobar(otro.en_obras() and String(otro.hecho()["forma"]) == antes, "la obra a medias sobrevive al guardado")
	var termino := false
	for i in semanas:
		termino = m.estadio.avanzar_semana() or termino
	_comprobar(termino and not m.estadio.en_obras() and String(m.perfil_estadio_de(mio)["forma"]) == nueva,
		"al terminar, el estadio nuevo es el de todas partes")
	_comprobar(not ("reforma" in (m.perfil_estadio_de(mio).get("en_obra", []) as Array)), "y se van los andamios")

## ETAPA 3: la optimización por código no cambia lo que se ve y lo elegido en
## gráficos se guarda.
func _probar_optimizacion() -> void:
	_titulo("ETAPA 3: OPTIMIZACIÓN (AGRUPAR, PRIMITIVAS, CALIDAD GUARDADA)")
	var raiz := Node3D.new()
	add_child(raiz)
	for i in 6:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(1.0 + i, 2.0, 0.5)
		mi.mesh = b
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.3, 0.6, 0.2)
		mi.material_override = m
		mi.position = Vector3(i * 4.0, 0, 0)
		raiz.add_child(mi)
	## Uno que se mueve (cuelga de un nodo con script): no se toca.
	var movil := Node3D.new()
	movil.set_script(GDScript.new())
	raiz.add_child(movil)
	var mi2 := MeshInstance3D.new()
	mi2.mesh = BoxMesh.new()
	movil.add_child(mi2)
	var cil := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.1
	cil.mesh = cm
	raiz.add_child(cil)
	Optimizar.primitivas(raiz)
	_comprobar(cm.radial_segments <= 8 and cm.rings == 0, "un poste fino baja de 64 lados a %d" % cm.radial_segments)
	var r := Optimizar.agrupar(raiz)
	var mms := raiz.find_children("Agrupado*", "MultiMeshInstance3D", true, false)
	_comprobar(int(r["piezas"]) >= 6 and mms.size() >= 1, "las 6 cajas iguales (distinto tamaño) quedan en un MultiMesh")
	## (Sin gráfica, el servidor de render no guarda las transformaciones del
	## MultiMesh: se comprueba el plegado de tamaño y el número de instancias.)
	var n6 := 0
	for n in mms:
		if (n as MultiMeshInstance3D).multimesh.instance_count == 6:
			n6 += 1
	var cj := MeshInstance3D.new()
	var bj := BoxMesh.new()
	bj.size = Vector3(6.0, 2.0, 0.5)
	cj.mesh = bj
	var pl := Optimizar._plegar(cj, bj)
	cj.free()
	var ok_tam: bool = n6 == 1 and pl.size() == 2 and (pl[0] as BoxMesh).size == Vector3.ONE \
		and (pl[1] as Vector3).is_equal_approx(Vector3(6.0, 2.0, 0.5))
	_comprobar(ok_tam, "cada caja agrupada conserva su tamaño y su sitio")
	_comprobar(is_instance_valid(mi2) and mi2.get_parent() == movil, "lo que cuelga de un nodo con script no se agrupa")
	raiz.queue_free()
	## Lo elegido en gráficos sobrevive a reabrir el juego.
	var previo := [Calidad.elegida, Calidad.adaptativa, Calidad.motor_ligero]
	var existia := FileAccess.file_exists(Calidad.ARCHIVO)
	Calidad.elegida = Calidad.MEDIO
	Calidad.adaptativa = false
	Calidad.motor_ligero = true
	Calidad.guardar()
	Calidad.elegida = Calidad.ULTRA
	Calidad.adaptativa = true
	Calidad.motor_ligero = false
	Calidad.cargar()
	_comprobar(Calidad.elegida == Calidad.MEDIO and not Calidad.adaptativa and Calidad.motor_ligero,
		"calidad, ajuste automático y motor se guardan y se leen")
	Calidad.elegida = previo[0]
	Calidad.adaptativa = previo[1]
	Calidad.motor_ligero = previo[2]
	if existia:
		Calidad.guardar()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Calidad.ARCHIVO))

## LA TRANSMISIÓN INTELIGENTE Y LAS ESTADÍSTICAS A PEDIDO (16-10-2026).
## La cámara se prueba sin pintar nada: se le dan balones sintéticos a 60 Hz y
## se mide lo que hace (dónde está, cuánto corre, cuánto cierra o abre).
## LOS ARREGLOS RÁPIDOS DEL PARTIDO CON MOTOR (17-10-2026): árbitro que
## contrasta (M-072), gestos y tarjeta en la mano (M-106), cartel del cuarto
## árbitro (M-139), red que se ondula (M-149), festejo de la grada (M-050) y
## líneas del fuera de juego en la sala VAR (M-118).
func _probar_arreglos_partido_motor() -> void:
	_titulo("PARTIDO 3D: ÁRBITRO, CARTEL, RED, FESTEJO Y LÍNEA VAR")
	## M-072: contra un equipo de negro el árbitro no va de negro; estable.
	var kn := {"c1": "#101010"}
	var kr := {"c1": "#d01818"}
	var a1 := Puente3D.kit_arbitro(kn, kr, 77)
	_comprobar(String(a1["nombre"]) != "negro", "árbitro: contra negro y rojo no va de negro (%s)" % a1["nombre"])
	_comprobar(Puente3D.kit_arbitro(kn, kr, 77)["nombre"] == a1["nombre"], "árbitro: la misma camiseta para el mismo partido")
	var cl := Color(String(a1["c1"]))
	var peor := minf(Puente3D.contraste_camiseta(cl, Color("#101010")), Puente3D.contraste_camiseta(cl, Color("#d01818")))
	_comprobar(peor > Puente3D.contraste_camiseta(Color("#111216"), Color("#101010")) + 0.3, "árbitro: contrasta más que el negro de siempre (%.2f)" % peor)
	var a2 := Puente3D.kit_arbitro({"c1": "#f4f4f4"}, {"c1": "#2a9a3a"}, 5)
	_comprobar(String(a2["nombre"]) in ["negro", "rojo", "rosa", "naranja"], "árbitro: contra blanco y verde, uno oscuro o vivo (%s)" % a2["nombre"])
	## M-106: los gestos del árbitro en el motor real (cola con reloj propio).
	var motor := MotorJugable.new()
	add_child(motor)
	motor.set_physics_process(false)
	var arb_nodo := Node3D.new()
	add_child(arb_nodo)
	var ap := AnimationPlayer.new()
	arb_nodo.add_child(ap)
	var lib := AnimationLibrary.new()
	for clip in ["parado", "trotar", "correr", "arbitro_silbato", "senalar_falta", "mostrar_tarjeta", "arbitro_amonestar_hablar", "arbitro_tiempo_anadido"]:
		var an := Animation.new()
		an.length = 1.0
		lib.add_animation(clip, an)
	ap.add_animation_library("", lib)
	motor.arbitros = [{"id": "arbitro", "node": arb_nodo, "anim": ap, "arbitro": true}]
	var bal := Node3D.new()
	add_child(bal)
	motor.balon = bal
	var gestos: Array = []
	motor.gesto_arbitro.connect(func(g: String) -> void: gestos.append(g))
	motor.call("_gesto_arbitro", "arbitro_silbato", 0.0, 0.9)
	motor.call("_gesto_arbitro", "mostrar_tarjeta", 1.0, 1.5, {"tarjeta": "amarilla"})
	for i in 40:
		motor.call("_mover_arbitros", 0.05)
	_comprobar(gestos.has("silbato") and gestos.has("mostrar_tarjeta"), "árbitro: pita y enseña la tarjeta (%s)" % str(gestos))
	_comprobar(String(motor.arbitros[0].get("anim_actual", "")) == "mostrar_tarjeta", "árbitro: está con el gesto de la tarjeta")
	motor.queue_free()
	arb_nodo.queue_free()
	bal.queue_free()
	## M-139: el cartel lleva los minutos por las dos caras.
	var cartel := CuartoArbitro.cartel(4)
	var textos := 0
	for l in cartel.find_children("*", "Label3D", true, false):
		if (l as Label3D).text == "+4":
			textos += 1
	_comprobar(textos == 2, "cuarto árbitro: «+4» por las dos caras (%d)" % textos)
	cartel.free()
	## M-149: la red se abomba hacia fuera desde donde entra el balón.
	var raiz := Node3D.new()
	add_child(raiz)
	var poste := StandardMaterial3D.new()
	StadiumBuilder._add_goal(raiz, 52.5, poste, Color.WHITE)
	StadiumBuilder._add_goal(raiz, -52.5, poste, Color.WHITE)
	_comprobar(RedArco.golpe(raiz, Vector3(1.0, 1.2, 53.3)), "red: el gol encuentra su arco")
	var fondo: MeshInstance3D = null
	for m in raiz.find_children("RedFondo", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).global_position.z > 0.0:
			fondo = m
	var fz := float((fondo.material_override as ShaderMaterial).get_shader_parameter("fuerza")) if fondo != null else 0.0
	_comprobar(fz > 0.3, "red: el paño de fondo recibe la onda (fuerza %.2f)" % fz)
	_comprobar((fondo.mesh as QuadMesh).subdivide_width >= 16 if fondo != null else false, "red: el paño está subdividido para ondularse")
	raiz.queue_free()
	## M-118: el tramo de la línea se recorta al monitor.
	var sala := SalaVAR.new()
	var rec: Array = sala.call("_recortar", Vector2(-3, 0), Vector2(3, 0.2), Vector2(1, 0.5))
	_comprobar(rec.size() == 2 and absf((rec[0] as Vector2).x + 1.0) < 0.01 and absf((rec[1] as Vector2).x - 1.0) < 0.01, "VAR: la línea se recorta al borde del monitor")
	_comprobar((sala.call("_recortar", Vector2(-3, 2), Vector2(3, 2), Vector2(1, 0.5)) as Array).is_empty(), "VAR: una línea fuera del monitor no se dibuja")
	sala.free()
	## M-050: con el motor ligero no hay festejo.
	var ligero := Calidad.motor_ligero
	Calidad.motor_ligero = true
	_comprobar(not FestejoGrada.activo(), "festejo: apagado con el motor ligero")
	Calidad.motor_ligero = ligero

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
