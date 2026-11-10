extends "res://pruebas/banco/estadio_p3.gd"
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
	_comprobar(ra.escalon == RendimientoAdaptativo.ESCALONES.size() and avisos == [3, 4, 5, 6],
		"con FPS malos sostenidos llega al último escalón (%d) y avisa de cada uno, sin pasarse" % ra.escalon)
	ra.free()
	raiz.free()
	_comprobar(is_equal_approx(get_viewport().scaling_3d_scale, Calidad.escala_3d()), "al quitarlo, el 3D del juego vuelve a la escala de su nivel (%.0f %%)" % (100.0 * Calidad.escala_3d()))

func _ra_nuevo(raiz: Node3D, calentado := false) -> RendimientoAdaptativo:
	var ra := RendimientoAdaptativo.new()
	ra.raiz3d = raiz
	add_child(ra)
	if calentado:
		ra.avanzar(RendimientoAdaptativo.SEG_CALENTAR, 100.0)   ## pasa el calentamiento con una muestra buena de relleno... que se descarta abajo
		ra._muestras.clear()
		ra._t_muestra = 0.0
	return ra

## (01-11) `PeatonQ.terminar` con el nodo aún fuera del árbol no vestía a nadie (salían en ropa
## interior en el teleférico): ahora se viste al entrar, igual que si ya estuviera, y una sola vez.
func _probar_peaton_fuera_del_arbol() -> void:
	_titulo("PEATÓN VESTIDO AUNQUE SE TERMINE FUERA DEL ÁRBOL")
	var r1 := RandomNumberGenerator.new()
	r1.seed = 7
	var d := PeatonQ.crear(r1)
	var r2 := RandomNumberGenerator.new()
	r2.seed = 7
	var ref := PeatonQ.crear(r2)
	if d.is_empty() or ref.is_empty():
		_comprobar(false, "PeatonQ.crear da un peatón")
		return
	var nodo: Node3D = d["nodo"]
	PeatonQ.terminar(d)
	PeatonQ.terminar(d)
	add_child(nodo)
	add_child(ref["nodo"])
	PeatonQ.terminar(ref)
	var n := nodo.find_children("*", "MeshInstance3D", true, false).size()
	var n_ref := (ref["nodo"] as Node).find_children("*", "MeshInstance3D", true, false).size()
	_comprobar(n == n_ref and n > 3, "terminado fuera y metido después lleva las mismas piezas que dentro (%d / %d), sin doblar la ropa" % [n, n_ref])
	nodo.queue_free()
	(ref["nodo"] as Node).queue_free()

## 2-11-2026: el perfil «ligero» automático según el hardware (visor/calidad_auto.gd).
func _probar_calidad_auto() -> void:
	_titulo("CALIDAD AUTOMÁTICA SEGÚN HARDWARE")
	var d := CalidadAuto.detectar("Intel(R) UHD Graphics 620", 8192, 8)
	_comprobar(d["debil"] and "UHD" in String(d["motivos"][0]), "una Intel UHD se considera modesta aunque tenga 8 GB y 8 hilos")
	d = CalidadAuto.detectar("NVIDIA GeForce GTX 1060", 16384, 12)
	_comprobar(not d["debil"] and d["motivos"].is_empty(), "una gráfica dedicada con 16 GB y 12 hilos NO es modesta")
	d = CalidadAuto.detectar("NVIDIA GeForce GTX 1060", 4096, 8)
	_comprobar(d["debil"] and d["motivos"].size() == 1, "con 4 GB de RAM es modesta por la RAM (un solo motivo)")
	d = CalidadAuto.detectar("Intel Pentium", 4096, 2)
	_comprobar(d["motivos"].size() == 2, "RAM 4 GB + 2 hilos = dos motivos")
	d = CalidadAuto.detectar("llvmpipe (LLVM 20.1.2, 256 bits)", 16000, 4)
	_comprobar(d["debil"], "el render por software (llvmpipe) cuenta como modesto")
	## Con archivo guardado, la elección del jugador manda: no se toca nada.
	var antes := Calidad.elegida
	_comprobar(FileAccess.file_exists(Calidad.ARCHIVO) == false or CalidadAuto.aplicar_si_primera_vez({"debil": true, "motivos": ["x"]}).is_empty(),
		"si ya hay grafica.cfg el perfil automático no hace nada")
	_comprobar(Calidad.elegida == antes or not FileAccess.file_exists(Calidad.ARCHIVO), "y la calidad elegida no cambia")

## M-476 / M-404: `FundirPiezas` junta los hijos directos con material en una malla por (material, sombra), respeta
## `excluir` y deja los mismos materiales y la misma geometría.
func _probar_fundir_piezas() -> void:
	_titulo("FUNDIR PIEZAS (una malla por material)")
	var raiz := Node3D.new()
	add_child(raiz)
	var rojo := StandardMaterial3D.new()
	var azul := StandardMaterial3D.new()
	var piezas: Array = []
	for i in 6:
		var mi := MeshInstance3D.new()
		mi.mesh = BoxMesh.new()
		mi.material_override = rojo if i < 4 else azul
		mi.position = Vector3(i * 2.0, 0, 0)
		raiz.add_child(mi)
		piezas.append(mi)
	var puerta := MeshInstance3D.new()
	puerta.mesh = BoxMesh.new()
	puerta.material_override = rojo
	raiz.add_child(puerta)
	var rotulo := Label3D.new()
	raiz.add_child(rotulo)
	var n := FundirPiezas.fundir(raiz, 300.0, "Fundido", [puerta])
	_comprobar(n == 6, "funde las 6 piezas y deja la excluida (%d)" % n)
	var mallas: Array = raiz.get_children().filter(func(h): return h.name == "Fundido")
	_comprobar(mallas.size() == 1 and (mallas[0] as MeshInstance3D).mesh.get_surface_count() == 2, "una malla con una superficie por material")
	var m: MeshInstance3D = mallas[0]
	_comprobar(m.mesh.surface_get_material(0) == rojo and m.mesh.surface_get_material(1) == azul, "las superficies llevan los MISMOS materiales")
	_comprobar(m.visibility_range_end == 300.0, "lleva la distancia de corte pedida")
	_comprobar(is_instance_valid(puerta) and puerta.get_parent() == raiz and is_instance_valid(rotulo), "la excluida y el rótulo se quedan")
	var vert := 0
	for k in m.mesh.get_surface_count():
		vert += (m.mesh.surface_get_arrays(k)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_comprobar(vert == 6 * 24, "la geometría no cambia (%d vértices: 6 cajas de 24)" % vert)
	var aabb := m.get_aabb()
	_comprobar(absf(aabb.size.x - 11.0) < 0.01, "las posiciones se conservan (ancho %.2f)" % aabb.size.x)
	raiz.queue_free()

## M-404: cada relleno de la ciudad deja piezas (se ejercitaban solo al construir la ciudad entera).
func _probar_rellenos_ciudad() -> void:
	_titulo("RELLENOS DE LA CIUDAD (cada uno deja piezas)")
	var casos := {
		"CiudadMercado": func(ex): CiudadMercado.montar(ex, Vector3.ZERO, 40.0, 0.0),
		"CiudadSolar": func(ex): CiudadSolar.montar(ex, Rect2(-20, -20, 40, 40)),
		"CiudadVilla": func(ex): CiudadVilla.montar(ex, Vector3.ZERO, 40.0, 0.0),
		"CiudadIndustrial": func(ex): CiudadIndustrial.rellenar(ex, Rect2(-30, -30, 60, 60)),
		"CiudadGasolinera": func(ex): CiudadGasolinera.montar(ex, Vector3.ZERO, 40.0, 0.0),
		"CiudadPlaza": func(ex): CiudadPlaza.montar(ex, Vector3.ZERO, 40.0, 0.0),
		"CiudadOeste": func(ex): CiudadOeste.rellenar(ex, Rect2(-30, -30, 60, 60)),
		"FachadaModular": func(ex): FachadaModular.montar(ex, 0.0, 0.0, 0.0, 12.0, 3),
		"CiudadServicios.bomberos": func(ex): CiudadServicios.bomberos(ex, Vector3.ZERO, 40.0, 40.0),
		"CiudadServicios.cocheras": func(ex): CiudadServicios.cocheras(ex, Vector3.ZERO, 40.0, 40.0),
		"CiudadServicios.desguace": func(ex): CiudadServicios.desguace(ex, Vector3.ZERO, 40.0, 40.0),
	}
	for nombre: String in casos:
		var cb := CityBuilder.new()
		add_child(cb)
		var ex := CiudadExpansion.new(cb)
		cb._rotulos = Node3D.new()   ## los rótulos del mapa cuelgan de aquí al construir la ciudad
		cb.add_child(cb._rotulos)
		if nombre == "CiudadOeste" and ex._mallas_mod().is_empty():
			_linea("  CiudadOeste: sin mallas modulares cargadas, no aplica")
			cb.queue_free()
			continue
		var antes := cb.get_child_count() + cb.puntos_clic.size()
		(casos[nombre] as Callable).call(ex)
		var nuevos := cb.get_child_count() + cb.puntos_clic.size() - antes   ## piezas o puntos de clic
		_comprobar(nuevos >= 1, "%s deja piezas (%d)" % [nombre, nuevos])
		cb.queue_free()

## M-404: módulos de `visor/` sin prueba directa (foto de equipo, sillón, banco, obra, tienda de la gasolinera).
func _probar_visor_pequenos() -> void:
	_titulo("MÓDULOS PEQUEÑOS DEL VISOR (foto de equipo, sillón, banco, obra, tienda)")
	## CeremoniaFoto: once locales en dos filas y vuelta exacta al sitio.
	var jugadores: Array = []
	var nodos: Array = []
	for i in 12:
		var nd := Node3D.new()
		nd.position = Vector3(float(i), 0, 3.0)
		nd.rotation.y = 0.3
		add_child(nd)
		nodos.append(nd)
		jugadores.append({"es_local": i < 11, "node": nd, "anim": null})
	var anims: Array = []
	var guardado := CeremoniaFoto.colocar(jugadores, func(_a, nombre): anims.append(nombre))
	_comprobar(guardado.size() == 11, "la foto coloca solo a los 11 locales (%d)" % guardado.size())
	_comprobar(anims.count("parado") == 6 and anims.count("agachado") == 5, "seis de pie detrás y cinco agachados delante")
	_comprobar(is_equal_approx((nodos[0] as Node3D).position.x, CeremoniaFoto.X_ATRAS) and is_equal_approx((nodos[10] as Node3D).position.x, CeremoniaFoto.X_DELANTE), "dos filas en X_ATRAS y X_DELANTE")
	_comprobar((nodos[11] as Node3D).position == Vector3(11, 0, 3.0), "el visitante no se mueve")
	CeremoniaFoto.devolver(guardado, jugadores, func(_a, _n): pass)
	_comprobar((nodos[4] as Node3D).position == Vector3(4, 0, 3.0) and is_equal_approx((nodos[4] as Node3D).rotation.y, 0.3), "al terminar cada uno vuelve a su sitio y giro")
	var raiz_luz := Node3D.new()
	add_child(raiz_luz)
	var l := CeremoniaFoto.luz(raiz_luz)
	CeremoniaFoto.destellar(l, 0.75)   ## (0,75 + 0,2) mod 0,45 = 0,05 s: en pleno destello
	var encendido := l.light_energy
	CeremoniaFoto.destellar(l, 0.88)   ## fase 0,18 s: apagado
	_comprobar(encendido > 0.0 and l.light_energy == 0.0, "el flash destella a ratos y se apaga entre medias")
	for nd2: Node3D in nodos:
		nd2.queue_free()
	raiz_luz.queue_free()
	## SillonOficina: con el recurso del Drive lo pone con su cuerpo; sin él devuelve null (quien llama usa lo de antes).
	var raiz := Node3D.new()
	add_child(raiz)
	var sillon := SillonOficina.poner(raiz, Vector3(1, 0, 2), 0.5)
	if ResourceLoader.exists(SillonOficina.RUTA):
		_comprobar(sillon != null and sillon.find_children("*", "CollisionShape3D", true, false).size() == 1, "el sillón del Drive se coloca con su cuerpo")
		var sin_cuerpo := SillonOficina.poner(raiz, Vector3.ZERO, 0.0, false)
		_comprobar(sin_cuerpo != null and sin_cuerpo.find_children("*", "CollisionShape3D", true, false).is_empty(), "sin cuerpo no lleva colisión")
	else:
		_comprobar(sillon == null, "sin el recurso devuelve null")
	raiz.queue_free()
	## Banco y obra de la ciudad.
	var cb := CityBuilder.new()
	add_child(cb)
	cb._rotulos = Node3D.new()
	cb.add_child(cb._rotulos)
	var ex := CiudadExpansion.new(cb)
	var clics := cb.puntos_clic.size()
	CiudadBanco.montar(ex, 0.0, 0.0, 0.0)
	_comprobar(cb.puntos_clic.size() == clics + 1 and String(cb.puntos_clic[-1]["k"]).begins_with("banco_"), "la ventanilla del banco deja su punto de clic")
	var hijos := cb.get_child_count()
	ex._materiales()   ## la obra usa el hormigón de la ciudad
	CiudadObra.montar(ex, Rect2(-30, -30, 60, 60))
	_comprobar(cb.get_child_count() > hijos, "la obra deja piezas (%d)" % (cb.get_child_count() - hijos))
	cb.queue_free()
	## Tienda de la gasolinera: solo responde a «tienda_<n>» y necesita vida.
	_comprobar(not GasolineraTienda.servicio({"vida": null}, "otra_cosa") and not GasolineraTienda.servicio({"vida": null}, "tienda_1"), "sin vida o con otra clave, la tienda no responde")

## M-404: efectos de la ciudad y el teleférico sin prueba directa (fuego, accidente, cinta, banderas del gol, andén).
func _probar_visor_efectos() -> void:
	_titulo("EFECTOS DEL VISOR (incendio, accidente, cinta, banderas, andén del teleférico)")
	var raiz := Node3D.new()
	add_child(raiz)
	var fuego := IncendioVisual.fuego(raiz, Vector3(5, 0, 5))
	_comprobar(fuego.get_node_or_null("Llama2") != null and fuego.get_node_or_null("Humo3") != null and fuego.get_node_or_null("LuzFuego") != null, "el fuego tiene 3 llamas, 4 bolas de humo y su luz")
	IncendioVisual.animar(fuego, 1.0, 1.0)
	var llama := fuego.get_node("Llama0") as MeshInstance3D
	var luz_viva := (fuego.get_node("LuzFuego") as OmniLight3D).light_energy
	IncendioVisual.animar(fuego, 1.0, 0.0)
	_comprobar(llama.scale.x < 0.1 and (fuego.get_node("LuzFuego") as OmniLight3D).light_energy < luz_viva * 0.1, "al apagarse las llamas encogen y la luz se va")
	IncendioVisual.animar(null, 0.0, 1.0)   ## no revienta con nulo
	var humo_y := (fuego.get_node("Humo0") as MeshInstance3D).position.y
	_comprobar(humo_y >= 7.0, "el humo sube sobre las llamas (y = %.1f)" % humo_y)
	var acc := IncendioVisual.accidente(raiz, Vector3(-20, 0, 0))
	_comprobar(acc.get_node_or_null("Intermitente3") != null, "el accidente lleva sus cuatro intermitentes")
	IncendioVisual.parpadeo(acc, 0.1)
	var visible_a := (acc.get_node("Intermitente0") as MeshInstance3D).visible
	IncendioVisual.parpadeo(acc, 0.5)
	_comprobar(visible_a and not (acc.get_node("Intermitente0") as MeshInstance3D).visible, "los intermitentes parpadean")
	var cinta := IncendioVisual.cinta(raiz, Vector3(0, 0, 20))
	_comprobar(cinta.get_child_count() == 8, "la cinta: 4 postes y 4 cordones (%d)" % cinta.get_child_count())
	## Banderas del gol: tres planos con shader (o nada con el motor ligero).
	var sitios := [Vector3(30, 5, 0), Vector3(-30, 5, 0), Vector3(0, 5, 40), Vector3(0, 5, -40)]
	var ban := BanderasGrada.lanzar(raiz, Color.RED, Color.WHITE, sitios)
	if Calidad.motor_ligero:
		_comprobar(ban == null, "con el motor ligero no hay banderas")
	else:
		_comprobar(ban != null and ban.get_child_count() == 3, "tres banderas con los colores del club")
		_comprobar(BanderasGrada.lanzar(raiz, Color.RED, Color.WHITE, []) == null, "sin sitios en la grada no lanza nada")
	## Andén del teleférico: deja piezas y no revienta.
	var anden := Node3D.new()
	raiz.add_child(anden)
	var n_det := TelefericoEstacion.detalles(anden)
	_comprobar(n_det > 0 and anden.get_child_count() > 0, "el andén del teleférico recibe sus detalles (%d)" % n_det)
	raiz.queue_free()

## M-404: vomitorios de la grada (tres MultiMesh por tribuna) y la obra del estadio (solo datos).
func _probar_vomitorios() -> void:
	_titulo("VOMITORIOS DE LA GRADA")
	var contados: Array[int] = []
	for largo: float in [30.0, 80.0, 140.0]:
		var deck := MeshInstance3D.new()
		deck.mesh = BoxMesh.new()
		add_child(deck)
		VomitoriosGrada.montar(deck, largo, 12.0, false)
		var multis: Array = deck.get_children().filter(func(h): return h is MultiMeshInstance3D)
		_comprobar(multis.size() == 3, "largo %.0f: hormigón, hueco y rótulo (3 multimallas, %d)" % [largo, multis.size()])
		if multis.size() == 3:
			var n: int = (multis[0] as MultiMeshInstance3D).multimesh.instance_count
			_comprobar(n >= 2 and n <= 6 and (multis[1] as MultiMeshInstance3D).multimesh.instance_count == n, "largo %.0f: entre 2 y 6 accesos, uno por hueco (%d)" % [largo, n])
			contados.append(n)
		deck.queue_free()
	_comprobar(contados.size() == 3 and contados[2] >= contados[0], "una grada más larga no tiene menos accesos %s" % str(contados))
	_comprobar(EstadioObra.new() != null, "EstadioObra se crea (solo datos)")
