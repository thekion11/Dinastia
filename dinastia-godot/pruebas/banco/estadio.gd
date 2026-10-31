extends "res://pruebas/banco/estadio_p1.gd"
## [Capa 2/2 de `estadio.gd`] _probar_interiores_club, _probar_galeria_club, _probar_reforma_con_obra

func _probar_interiores_club() -> void:
	_titulo("ESTADIO 2.0: DECORAR LAS SALAS")
	var it := InterioresClub.new()
	it.pintar("Oficina del DT", "pared", "1f3f6b")
	_comprobar(it.poner("Oficina del DT", "bufanda"), "en tu oficina caben tus objetos propios")
	_comprobar(not it.poner("Sala de prensa", "bufanda"), "tu bufanda no va a la sala de prensa")
	for k in 6:
		it.poner("Museo del club", "planta")
	_comprobar(not it.poner("Museo del club", "sofa"), "seis huecos por sala, ni uno más")
	it.quitar_ultima("Museo del club")
	_comprobar((it.sala("Museo del club")["deco"] as Array).count("planta") == 5, "se quita el último objeto")
	it.colgar("Oficina del DT", "user://fotos/foto_x.png")
	var m := Mundo.new()
	m.generar(["CHI"], 616)
	m.interiores = it
	var m2 := Mundo.new()
	m2.generar(["CHI"], 616)
	m2.interiores.desde_dic(m.interiores.a_dic())
	_comprobar(String(m2.interiores.sala("Oficina del DT")["pared"]) == "1f3f6b" and (m2.interiores.sala("Oficina del DT")["fotos"] as Array).has("user://fotos/foto_x.png"),
		"la decoración y las fotos se guardan con la partida")
	## El edificio la pinta: con decoración hay más piezas que sin ella.
	EdificioClub.ctx = {"interiores": InterioresClub.new()}
	var r1 := Node3D.new()
	EdificioClub.montar(r1, 0.0, 70.0, 83.0, Color.RED, Color.WHITE, StandardMaterial3D.new(), StandardMaterial3D.new(), "X")
	var antes := r1.find_children("*", "MeshInstance3D", true, false).size()
	EdificioClub.ctx = {"interiores": it}
	var r2 := Node3D.new()
	EdificioClub.montar(r2, 0.0, 70.0, 83.0, Color.RED, Color.WHITE, StandardMaterial3D.new(), StandardMaterial3D.new(), "X")
	var despues := r2.find_children("*", "MeshInstance3D", true, false).size()
	_comprobar(despues > antes, "el edificio pinta la decoración (%d → %d piezas)" % [antes, despues])
	r1.free()
	r2.free()
	EdificioClub.ctx = {}


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

## CALIDAD ADAPTATIVA (M-354, 28-10-2026): los umbrales de `RendimientoAdaptativo` con FPS inventados (`avanzar`), sin depender de la máquina. La prueba de
## lo que toca cada escalón está en `pruebas/probar_rendimiento_adaptativo.gd` (necesita abrir el estadio).
func _probar_rendimiento_adaptativo() -> void:
	_titulo("CALIDAD ADAPTATIVA: UMBRALES")
	var raiz := Node3D.new()
	add_child(raiz)
	var m := RendimientoAdaptativo.MUESTRAS
	## A: el calentamiento y el mínimo de muestras.
	var ra := _ra_nuevo(raiz)
	for i in int(RendimientoAdaptativo.SEG_CALENTAR) - 1:
		ra.avanzar(1.0, 5.0)
	_comprobar(ra.escalon == 0, "durante el calentamiento (%d s) no baja nada, ni a 5 FPS" % int(RendimientoAdaptativo.SEG_CALENTAR))
	for i in m - 1:   ## la primera muestra cae al cumplirse el calentamiento
		ra.avanzar(1.0, 5.0)
	_comprobar(ra.escalon == 0, "con menos de %d muestras no decide, aunque sean malas" % m)
	ra.free()
	## B: lo que no debe bajar.
	ra = _ra_nuevo(raiz, true)
	for i in m:
		ra.avanzar(1.0, RendimientoAdaptativo.OBJETIVO_FPS)
	_comprobar(ra.escalon == 0, "la media justo en %d FPS no baja: el umbral es estricto" % int(RendimientoAdaptativo.OBJETIVO_FPS))
	for i in 3 * m:
		ra.avanzar(1.0, 60.0)
	_comprobar(ra.escalon == 0, "a 60 FPS nunca baja")
	ra.free()
	## C: bajar de uno en uno, sin volver a subir.
	ra = _ra_nuevo(raiz, true)
	var llamadas := 0
	while ra.escalon == 0 and llamadas < 20:
		ra.avanzar(1.0, 30.0)
		llamadas += 1
	_comprobar(ra.escalon == 1 and llamadas == m, "a 30 FPS sostenidos baja UN escalón (a los %d segundos)" % llamadas)
	for i in m - 1:
		ra.avanzar(1.0, 20.0)
	_comprobar(ra.escalon == 1, "tras bajar vuelve a medir desde cero: otros %d segundos antes del siguiente" % m)
	ra.avanzar(1.0, 20.0)
	_comprobar(ra.escalon == 2, "al cumplirse las %d muestras malas nuevas baja el segundo" % m)
	for i in 4 * m:
		ra.avanzar(1.0, 120.0)
	_comprobar(ra.escalon == 2, "nunca vuelve a subir aunque los FPS mejoren")
	ra.activo = false
	for i in 4 * m:
		ra.avanzar(1.0, 5.0)
	_comprobar(ra.escalon == 2, "apagado no hace nada")
	ra.activo = true
	var avisos: Array[int] = []
	ra.escalon_aplicado.connect(func(e: int, _q: String) -> void: avisos.append(e))
	for i in 10 * m:
		ra.avanzar(1.0, 5.0)
	_comprobar(ra.escalon == RendimientoAdaptativo.ESCALONES.size() and avisos == [3, 4, 5],
		"con FPS malos sostenidos llega al último escalón (%d) y avisa de cada uno, sin pasarse" % ra.escalon)
	ra.free()
	raiz.free()
	_comprobar(is_equal_approx(get_viewport().scaling_3d_scale, 1.0), "al quitarlo, el 3D del juego vuelve al 100 %")

func _ra_nuevo(raiz: Node3D, calentado := false) -> RendimientoAdaptativo:
	var ra := RendimientoAdaptativo.new()
	ra.raiz3d = raiz
	add_child(ra)
	if calentado:
		ra.avanzar(RendimientoAdaptativo.SEG_CALENTAR, 100.0)   ## pasa el calentamiento con una muestra buena de relleno... que se descarta abajo
		ra._muestras.clear()
		ra._t_muestra = 0.0
	return ra
