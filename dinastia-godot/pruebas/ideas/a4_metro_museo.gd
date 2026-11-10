extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D, con pantalla virtual: METRO POR DENTRO y MUSEO AMPLIADO con el explorador a pie real.
##   1. Metro: cada acceso (a pie → andén → calle) y cada trayecto (andén → tren → llegar a otra estación → bajar → salir): el jugador queda en un sitio finito, dentro de la zona del andén al bajar, y al salir a la calle FUERA de edificios y paredes, sobre el suelo y a pocos metros de la boca.
##      Entradas y salidas repetidas (30): sin fugas de nodos.
##   2. Museo ampliado: de la planta 0 a la 3 por el ascensor (varias veces seguidas), cada planta con su altura, el jugador dentro del museo, vitrinas con 0 y 500 trofeos y el visor de la copa de cada planta; ampliar varias veces seguidas no duplica salas.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

func _probar() -> void:
	_titulo("A4 MUNDO_3D: metro por dentro y museo ampliado (explorador real)")
	AjustesCiudad.guardar("tutorial_visto", true)
	var c: Dictionary = await Comun.abrir(self)
	var vc: Node = c["vc"]
	vc.set("_ciclo_activo", false)
	vc.call("explorar", "pie")
	var e: Object = vc.get("_explorador")
	_comprobar(e != null, "el explorador a pie existe")
	if e == null:
		return
	for i in 10:
		await get_tree().process_frame
	## A4_PARTE=1 (metro) | 2 (museo): con pantalla (xvfb, software) la ciudad entera ya cuesta ~190 s, así que cada mitad va por separado para caber en 300 s. Sin variable, las dos.
	var parte := OS.get_environment("A4_PARTE")
	if parte != "2":
		await _metro(e, vc)
	if parte != "1":
		await _museo(e, vc, c["m"])
	(c["vc"] as Node).free()

func _esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

## Avanza el servicio hasta que NO haya tren parado en la estación (E en el andén con un tren parado sube a él: para salir a la calle hay que esperar a que se vaya).
func _sin_tren(metro: Object, linea: String, idx: int) -> void:
	for i in 400:
		if int(metro.tren_parado_en(linea, idx)) < 0:
			return
		metro.call("_process", 0.25)

func _metro(e: Object, vc: Node) -> void:
	var metro: Object = e.metro
	var accesos: Array = metro.accesos
	_comprobar(accesos.size() >= 4, "el metro tiene accesos (%d)" % accesos.size())
	var calle0: Vector3 = e.cuerpo.position
	var malas: Array[String] = []
	var n_ok := 0
	var nodos0 := 0
	var nodos1 := 0
	var vuelta := 0
	for acc: Dictionary in accesos:
		vuelta += 1
		e.call("_entrar_al_anden", acc)
		await _esperar(2)
		var p: Vector3 = e.cuerpo.position
		if String(e.estado) != "anden" or not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
			malas.append("%s/%d: no entra al andén (%s, %s)" % [acc["linea"], int(acc["idx"]), e.estado, str(p)])
			continue
		## salir a la calle por la boca (no hay tren parado: se fuerza a que no lo haya)
		if true:
			_sin_tren(metro, String(acc["linea"]), int(acc["idx"]))
			e.call("_usar_en_anden")
			await _esperar(2)
			var q: Vector3 = e.cuerpo.position
			var pie: Vector3 = acc.get("pie", Vector3.ZERO)
			if String(e.estado) != "calle":
				malas.append("%s/%d: no sale a la calle (%s)" % [acc["linea"], int(acc["idx"]), e.estado])
			elif Vector2(q.x - pie.x, q.z - pie.z).length() > 12.0:
				malas.append("%s/%d: sale a %s y la boca está en %s" % [acc["linea"], int(acc["idx"]), str(q), str(pie)])
			elif not e.call("libre_total", q, 0.4):
				var quien := ""
				for r: Rect2 in e.obstaculos:
					if r.grow(0.3).has_point(Vector2(q.x, q.z)):
						quien = str(r)
						break
				malas.append("%s/%d (elevada %s): sale DENTRO de un obstáculo/pared en %s (rect %s; boca %s)" % [acc["linea"], int(acc["idx"]), str(acc["elevada"]), str(q), quien, str(pie)])
			elif absf(q.y - float(e.call("altura_suelo", q.x, q.z))) > 1.0:
				malas.append("%s/%d: sale a una altura rara (%.1f)" % [acc["linea"], int(acc["idx"]), q.y])
			else:
				n_ok += 1
		if vuelta == 3:
			nodos0 = vc.find_children("*", "", true, false).size()
		nodos1 = vc.find_children("*", "", true, false).size()
	_comprobar(malas.is_empty(), "%d accesos del metro: entrar al andén y salir a la calle en la boca, fuera de paredes (%d bien; %d fallos%s)" % [accesos.size(), n_ok, malas.size(), "" if malas.is_empty() else ": " + str(malas.slice(0, 3))])
	## trayectos: subir a un tren, avanzar el servicio hasta que pare en una estación y bajar
	var trayectos := 0
	var malos_t: Array[String] = []
	for l: Dictionary in metro.lineas:
		var nombre := String(l["nombre"])
		for k in mini(2, (l["trenes"] as Array).size()):
			e._linea = nombre
			e.call("_subir_al_tren", k)
			var llegado := -1
			for paso in 600:
				metro.call("_process", 0.25)
				llegado = int(metro.estacion_del_tren(nombre, k))
				if llegado >= 0:
					break
			if llegado < 0:
				malos_t.append("%s tren %d: no para en ninguna estación en 150 s" % [nombre, k])
				continue
			e.call("_bajar_del_tren")
			await _esperar(2)
			_sin_tren(metro, nombre, llegado)
			var p2: Vector3 = e.cuerpo.position
			var medio: Vector2 = e._anden_medio
			var rel: Vector3 = p2 - e._anden_c
			if String(e.estado) != "anden" or not is_finite(p2.x) or absf(rel.y) > 4.0 or absf(rel.x) > 60.0 or absf(rel.z) > 60.0:
				malos_t.append("%s tren %d: baja en %s (andén en %s, %s)" % [nombre, k, str(p2), str(e._anden_c), e.estado])
				continue
			e.call("_usar_en_anden")
			await _esperar(2)
			var q2: Vector3 = e.cuerpo.position
			var cerca := false
			for acc2: Dictionary in accesos:
				if String(acc2["linea"]) == nombre and int(acc2["idx"]) == llegado:
					var pie2: Vector3 = acc2.get("pie", Vector3.ZERO)
					if Vector2(q2.x - pie2.x, q2.z - pie2.z).length() < 13.0:
						cerca = true
			if String(e.estado) != "calle" or not e.call("libre_total", q2, 0.4) or not cerca:
				malos_t.append("%s tren %d → estación %d: sale a %s (%s), %s de la boca, %s" % [nombre, k, llegado, str(q2), e.estado, "cerca" if cerca else "LEJOS", "libre" if e.call("libre_total", q2, 0.4) else "EN PARED"])
				continue
			trayectos += 1
	print("  (info) %d trayectos completos; nodos tras 3 accesos %d, al final %d" % [trayectos, nodos0, nodos1])
	_comprobar(malos_t.is_empty(), "trayectos en tren (subir, viajar, bajar, salir): %d bien, %d fallos%s" % [trayectos, malos_t.size(), "" if malos_t.is_empty() else ": " + str(malos_t.slice(0, 4))])
	_comprobar(nodos1 - nodos0 < 300, "el metro no acumula nodos con las entradas y salidas (%d → %d)" % [nodos0, nodos1])
	_comprobar(String(e.estado) == "calle" and e.cuerpo.position.y > -5.0, "al terminar el jugador está en la calle (%s)" % e.estado)

func _hitos(n: int) -> Array:
	var h: Array = []
	for i in n:
		h.append({"anio": 1990 + i % 40, "titulo": "Copa %d" % i, "final": "Final %d" % i, "goleadores": ["A (%d)" % i]})
	return h

func _vitrinas_n() -> int:
	return SalasClub.vitrinas.size() + MuseoAmpliado.vitrinas.size()

func _museo(e: Object, vc: Node, _m: Mundo) -> void:
	e.call("_entrar_al_estadio")
	await _esperar(4)
	var edificio := get_tree().get_first_node_in_group("edificio_club") as Node3D
	_comprobar(edificio != null, "el edificio del club existe (estadio abierto)")
	if edificio == null:
		return
	var ctx: Dictionary = EdificioClub.ctx
	var malas: Array[String] = []
	var inst: Dictionary = (ctx.get("inst", {}) as Dictionary).duplicate()
	var casos := [[0, 0, false], [4, 3, true], [5, 0, true], [5, 5, true], [5, 500, true]]
	for caso in casos:
		var nivel: int = caso[0]
		var n_hitos: int = caso[1]
		var en_obra: bool = nivel == 4
		ctx["inst"] = inst.duplicate()
		(ctx["inst"] as Dictionary)["museo"] = nivel
		ctx["obras"] = {"museo": 3} if en_obra else {}
		ctx["hitos"] = _hitos(n_hitos)
		ctx["titulos"] = n_hitos   ## como lo deja `contexto_de`
		var nodos_antes := vc.find_children("*", "", true, false).size()
		var t0 := Time.get_ticks_msec()
		for r in 3:   ## ampliar / rehacer varias veces seguidas
			EdificioClub.reconstruir(get_tree().get_first_node_in_group("edificio_club") as Node3D)
			await _esperar(2)
		var ms := Time.get_ticks_msec() - t0
		var nodos_despues := vc.find_children("*", "", true, false).size()
		var edificios := get_tree().get_nodes_in_group("edificio_club").size()
		var plantas: Array = EdificioClub.plantas()
		var con_3 := plantas.has(3)
		if con_3 != (nivel >= 5 or en_obra):
			malas.append("museo %d (obra %s): plantas %s" % [nivel, str(en_obra), str(plantas)])
		if edificios != 1:
			malas.append("museo %d: %d edificios del club tras rehacer (duplicado)" % [nivel, edificios])
		if nodos_despues - nodos_antes > 3000:
			malas.append("museo %d, %d hitos: los nodos crecen %d → %d" % [nivel, n_hitos, nodos_antes, nodos_despues])
		print("  (info) museo nivel %d, %d hitos: plantas %s, %d vitrinas, 3 reconstrucciones en %d ms, nodos %d → %d" % [nivel, n_hitos, str(plantas), _vitrinas_n(), ms, nodos_antes, nodos_despues])
		if _vitrinas_n() > 40:
			malas.append("museo %d, %d hitos: %d vitrinas (desbordado)" % [nivel, n_hitos, _vitrinas_n()])
		if n_hitos >= 5 and nivel >= 5:
			## los hitos MÁS RECIENTES tienen vitrina (antes salían los más antiguos y los títulos nuevos no se veían nunca) y ninguna ficha se repite
			var ks: Array[int] = []
			for v: Dictionary in SalasClub.vitrinas + MuseoAmpliado.vitrinas:
				ks.append(int(v["k"]))
			var unicos := {}
			for k in ks:
				unicos[k] = true
			if unicos.size() != ks.size():
				malas.append("hitos %d: vitrinas con la misma ficha (%s)" % [n_hitos, str(ks)])
			if ks.max() != n_hitos - 1 and n_hitos > 6:
				malas.append("hitos %d: la ficha más reciente no tiene vitrina (máx %d; %s)" % [n_hitos, ks.max(), str(ks)])
		if n_hitos == 500 and nivel >= 5:
			## cada planta: subir por el ascensor, en cada vitrina interactuar con su trofeo
			for p: int in plantas:
				e.call("_ir_a_planta", p)
				## (10-11) el ascensor sube y baja GRADUAL (`AscensorViaje`, 1 s por planta): se espera a que llegue (hasta 15 s de reloj) en vez de 2 fotogramas.
				var t_ini := Time.get_ticks_msec()
				while Time.get_ticks_msec() - t_ini < 15000:   ## (10-11) por TIEMPO real, no por fotogramas: sin pantalla los fotogramas van a miles por segundo y 900 no llegaban a 1 s de viaje
					await get_tree().process_frame
					if absf(e.cuerpo.position.y - RecorridoClub.y_de(p)) <= 0.05 and not bool(e.get("_en_viaje")):   ## llegó Y el viaje terminó (el último centímetro del tween cae dentro de 5 cm antes de su callback, que fija la planta)
						break
				await _esperar(2)
				if absf(e.cuerpo.position.y - RecorridoClub.y_de(p)) > 0.05:
					malas.append("planta %d: el jugador queda a y=%.2f (esperado %.2f)" % [p, e.cuerpo.position.y, RecorridoClub.y_de(p)])
				var vistas := 0
				for v: Dictionary in SalasClub.vitrinas + MuseoAmpliado.vitrinas:
					var pv: Vector3 = v["p"]
					if absf(pv.y - RecorridoClub.y_de(p)) > 1.5:
						continue
					e.cuerpo.position = CityBuilder.ESTADIO_EN + pv + Vector3(0.0, 0.0, 0.5)
					e.cuerpo.position.y = RecorridoClub.y_de(p)
					e.set("_menu_asc", null)
					var abierto := bool(MuseoVitrinas.usar(e, e.cuerpo.position - CityBuilder.ESTADIO_EN))
					await _esperar(1)
					if abierto and is_instance_valid(e._menu_asc):
						vistas += 1
						(e._menu_asc as Node).queue_free()
					else:
						malas.append("planta %d, vitrina %d: E no abre el visor del trofeo" % [p, int(v["k"])])
				print("  (info) planta %d: %d vitrinas con trofeo visto" % [p, vistas])
	_comprobar(malas.is_empty(), "museo ampliado: plantas, rehacer varias veces, 0/500 trofeos e interactuar en cada planta (%d fallos%s)" % [malas.size(), "" if malas.is_empty() else ": " + str(malas.slice(0, 4))])
	ctx["inst"] = inst
	e.call("_ir_a_planta", 0)
	e.call("_salir_del_estadio")
	await _esperar(3)
	_comprobar(String(e.estado) == "calle" and e.cuerpo.position.y > -5.0, "tras recorrer el museo se sale a la calle (%s, y=%.1f)" % [e.estado, e.cuerpo.position.y])
