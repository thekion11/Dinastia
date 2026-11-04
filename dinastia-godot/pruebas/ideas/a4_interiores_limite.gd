extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: INTERIORES y el paso entre escenas con el explorador real (a pie).
##   1. Entrar y salir 50 veces seguidas (varias salas): dentro, el jugador está dentro de la sala y con la cámara finita; fuera, vuelve a su sitio de la calle (no bajo tierra ni fuera del mapa);
##      los nodos del interior se liberan y el árbol no crece con las vueltas (nodos y huérfanos tras la 10.ª y la 50.ª).
##   2. Puertas pulsadas dos veces (entrar con el interior ya abierto, salir ya en la calle): sin interiores huérfanos y el jugador sale al sitio de la calle, no al interior.
##   3. Cambiar la calidad con el interior abierto y salir: sin error.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const SALAS := ["edificio_bar|Bar El Rincón", "edificio_vivienda|Casa de la familia Ortega", "ciudad_hospital", "edificio_tienda|Farmacia"]
const VUELTAS := 50

func _probar() -> void:
	_titulo("A4 MUNDO_3D: interiores, %d entradas y salidas seguidas" % VUELTAS)
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
	var calle: Vector3 = e.cuerpo.position
	var malas: Array[String] = []
	var abiertas := 0
	var nodos10 := 0
	var huer10 := 0
	var nodos_ahora := 0
	var huer_ahora := 0
	for v in VUELTAS:
		var k: String = SALAS[v % SALAS.size()]
		e.call("_entrar_en_edificio", k)
		for i in 3:
			await get_tree().process_frame
		if String(e.estado) != "interior":
			malas.append("vuelta %d (%s): no se entra (estado %s)" % [v, k, e.estado])
			continue
		abiertas += 1
		var rel: Vector3 = e.cuerpo.position - e._INT_ORIGEN
		var t: Vector3 = e._int.tam_sala()
		if absf(rel.x) > t.x * 0.5 + 0.5 or absf(rel.z) > t.z * 0.5 + 0.5 or absf(rel.y) > 3.0:
			malas.append("vuelta %d (%s): el jugador entra FUERA de la sala %s (rel %s)" % [v, k, str(t), str(rel)])
		var cam: Vector3 = e.camara.position
		if not (is_finite(cam.x) and is_finite(cam.y) and is_finite(cam.z)):
			malas.append("vuelta %d: cámara no finita" % v)
		e.call("_salir_del_edificio")
		for i in 3:
			await get_tree().process_frame
		if String(e.estado) != "calle" or e.cuerpo.position.distance_to(calle) > 0.5:
			malas.append("vuelta %d (%s): sale a %s (estado %s), la calle era %s" % [v, k, str(e.cuerpo.position), e.estado, str(calle)])
		if is_instance_valid(e._int) or is_instance_valid(e._int_raiz):
			malas.append("vuelta %d: el interior sigue vivo tras salir" % v)
		if v == 9 or v == VUELTAS - 1:
			for i in 5:
				await get_tree().process_frame
			nodos_ahora = vc.find_children("*", "", true, false).size()
			huer_ahora = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			if v == 9:
				nodos10 = nodos_ahora
				huer10 = huer_ahora
	print("  (info) nodos tras 10 vueltas: %d, tras %d: %d · huérfanos %d → %d" % [nodos10, VUELTAS, nodos_ahora, huer10, huer_ahora])
	_comprobar(abiertas == VUELTAS, "las %d entradas abren (%d)" % [VUELTAS, abiertas])
	_comprobar(malas.is_empty(), "entrar/salir %d veces: dentro de la sala, la calle intacta, sin interior vivo (%d fallos%s)" % [VUELTAS, malas.size(), "" if malas.is_empty() else ": " + str(malas.slice(0, 3))])
	_comprobar(nodos_ahora - nodos10 < 300, "los nodos no crecen con las vueltas (%d → %d)" % [nodos10, nodos_ahora])
	_comprobar(huer_ahora - huer10 < 60, "ni los nodos huérfanos (%d → %d)" % [huer10, huer_ahora])
	## puertas pulsadas dos veces
	e.call("_entrar_en_edificio", SALAS[0])
	for i in 3:
		await get_tree().process_frame
	var interior_pos: Vector3 = e.cuerpo.position
	e.call("_entrar_en_edificio", SALAS[1])   ## la segunda pulsación con el interior ya abierto
	for i in 3:
		await get_tree().process_frame
	e.call("_salir_del_edificio")
	for i in 3:
		await get_tree().process_frame
	e.call("_salir_del_edificio")   ## y la segunda al salir
	for i in 3:
		await get_tree().process_frame
	var d_calle: float = e.cuerpo.position.distance_to(calle)
	_comprobar(String(e.estado) == "calle" and d_calle < 0.5 and e.cuerpo.position.y > -5.0, "doble pulsación: el jugador vuelve a la calle (a %.1f m de donde estaba, y %.1f)" % [d_calle, e.cuerpo.position.y])
	var raices := 0
	for h in vc.find_children("InteriorPaseo*", "Node3D", true, false):
		raices += 1
	_comprobar(raices == 0, "ningún interior huérfano en el mundo tras la doble pulsación (%d)" % raices)
	## calidad con el interior abierto
	e.call("_entrar_en_edificio", SALAS[1])
	for i in 3:
		await get_tree().process_frame
	for nivel in [Calidad.MINIMO, Calidad.ULTRA, Calidad.MEDIO]:
		Calidad.elegida = nivel
		Calidad.aplicar_viewport(get_viewport(), nivel)
		await get_tree().process_frame
	e.call("_salir_del_edificio")
	for i in 3:
		await get_tree().process_frame
	_comprobar(String(e.estado) == "calle" and e.cuerpo.position.distance_to(calle) < 0.5, "cambiar la calidad dentro y salir: vuelve a la calle (%s)" % e.estado)
	Calidad.elegida = Calidad.MEDIO
	## el estadio: 20 entradas y salidas, y la puerta pulsada dos veces
	var salida_est: Vector3 = Vector3.ZERO
	var malas_e: Array[String] = []
	var nodos_e0 := 0
	var nodos_e1 := 0
	for v in 20:
		e.call("_entrar_al_estadio")
		if v % 3 == 0:
			e.call("_entrar_al_estadio")   ## doble pulsación
		for i in 3:
			await get_tree().process_frame
		if String(e.estado) != "estadio":
			malas_e.append("vuelta %d: no entra (%s)" % [v, e.estado])
		var loc: Vector3 = e.cuerpo.position - CityBuilder.ESTADIO_EN
		if not (is_finite(loc.x) and absf(loc.x) < 300.0 and absf(loc.z) < 300.0 and loc.y > -5.0):
			malas_e.append("vuelta %d: dentro del estadio en %s" % [v, str(loc)])
		e.call("_salir_del_estadio")
		for i in 3:
			await get_tree().process_frame
		var fuera: Vector3 = e.cuerpo.position
		if String(e.estado) != "calle" or fuera.y < -5.0 or absf(fuera.x) > 1500.0 or absf(fuera.z) > 1500.0:
			malas_e.append("vuelta %d: sale a %s (%s)" % [v, str(fuera), e.estado])
		if v == 1:
			salida_est = fuera
			nodos_e0 = vc.find_children("*", "", true, false).size()
		elif v > 1 and fuera.distance_to(salida_est) > 0.5:
			malas_e.append("vuelta %d: la salida cambia (%s contra %s)" % [v, str(fuera), str(salida_est)])
		nodos_e1 = vc.find_children("*", "", true, false).size()
	_comprobar(malas_e.is_empty(), "estadio: 20 entradas y salidas (con doble pulsación) coherentes (%d fallos%s)" % [malas_e.size(), "" if malas_e.is_empty() else ": " + str(malas_e.slice(0, 3))])
	_comprobar(nodos_e1 - nodos_e0 < 200, "el estadio no acumula nodos con las vueltas (%d → %d)" % [nodos_e0, nodos_e1])
	(c["vc"] as Node).free()
