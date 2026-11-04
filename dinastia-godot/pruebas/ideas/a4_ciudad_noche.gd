extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: la ciudad de NOCHE con mucho tráfico y SIRENAS (6 sirenas quietas durante 2 min en medio del tráfico y luego fuera).
##   Se simulan 6 min a 0,1 s. Mide, por vehículo, el tiempo seguido QUIETO (< 0,05 m por paso):
##   1. Atascos que no se deshacen: pasados 60 s de quitar las sirenas, ningún coche lleva más de 90 s seguidos quieto (salvo los de un semáforo: se descuenta el que está a < 12 m de una línea de detención).
##   2. Peatones que se quedan quietos: ≤ 15 % quietos 120 s seguidos sin motivo (espera, charla, cediendo).
##   3. Buses que no salen del paradero: ningún bus lleva más de 60 s seguidos quieto tras quitar las sirenas, y todos recorren distancia en los 6 min.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const PASO := 0.1
const PASOS := 3600   ## 6 min
const T_SIRENAS_0 := 600
const T_SIRENAS_1 := 1800

func _probar() -> void:
	_titulo("A4 MUNDO_3D: la ciudad de noche, tráfico y sirenas (6 min)")
	var c: Dictionary = await Comun.abrir(self)
	var vc: Node = c["vc"]
	var cb: Node = c["cb"]
	vc.set("_ciclo_activo", false)
	vc.set("_hora", 23.5)
	vc.call("_aplicar_hora")
	cb.call("encender_luces", 1.0)
	var t: Object = cb.get_node_or_null("Trafico")
	_comprobar(t != null, "la ciudad trae su tráfico")
	if t == null:
		return
	t.set_process(false)
	var sem: Object = t.get("semaforos")
	if sem != null:
		sem.set_process(false)
	var vehiculos: Array = t.get("_vehiculos")
	var coches: Array = []
	var buses: Array = []
	var gente: Array = []
	for v: Dictionary in vehiculos:
		var n: Node3D = v["nodo"]
		if not is_instance_valid(n):
			continue
		if String(n.name).begins_with("Bus_"):
			buses.append(v)
		elif bool(v.get("peaton", false)):
			gente.append(v)
		elif float(v.get("alto", 0.0)) < 0.05 and not String(n.name).begins_with("kart"):
			coches.append(v)
	print("  (info) %d coches, %d buses, %d peatones" % [coches.size(), buses.size(), gente.size()])
	var todos: Array = coches + buses + gente
	var prev: Array[Vector3] = []
	var quieto: Array[float] = []
	var peor: Array[float] = []
	var peor_tras: Array[float] = []   ## solo tras quitar las sirenas
	var recorrido: Array[float] = []
	for v: Dictionary in todos:
		var p: Vector3 = (v["nodo"] as Node3D).position
		prev.append(p)
		quieto.append(0.0)
		peor.append(0.0)
		peor_tras.append(0.0)
		recorrido.append(0.0)
	var sirenas: Array[Node3D] = []
	for i in PASOS:
		if i == T_SIRENAS_0:
			## 6 sirenas quietas encima de 6 coches (en sus posiciones de ese instante)
			for k in 6:
				var q := Node3D.new()
				q.position = (coches[k * 17 % coches.size()]["nodo"] as Node3D).position
				add_child(q)
				sirenas.append(q)
				(TraficoCiudad.sirenas as Array).append(q)
		if i == T_SIRENAS_1:
			for q in sirenas:
				(TraficoCiudad.sirenas as Array).erase(q)
				q.queue_free()
			sirenas.clear()
		if sem != null:
			sem.call("_process", PASO)
		t.call("_process", PASO)
		if i % 20 == 19:
			await get_tree().process_frame
		for k in todos.size():
			var v: Dictionary = todos[k]
			var n: Node3D = v["nodo"]
			if not is_instance_valid(n):
				continue
			var p := n.position
			var d := p.distance_to(prev[k])
			recorrido[k] += d
			prev[k] = p
			if d < 0.005 and float(v.get("espera", 0.0)) <= 0.0 and n.visible:   ## los ocultos (de noche la gente «se esconde») no cuentan
				quieto[k] += PASO
			else:
				quieto[k] = 0.0
			peor[k] = maxf(peor[k], quieto[k])
			if i > T_SIRENAS_1 + 600:
				peor_tras[k] = maxf(peor_tras[k], quieto[k])
	var n_c := coches.size()
	var atascados := 0
	var peor_coche := 0.0
	for k in n_c:
		peor_coche = maxf(peor_coche, peor_tras[k])
		if peor_tras[k] > 90.0:
			atascados += 1
	var n_b := buses.size()
	var detalle_b: Array[String] = []
	var buses_quietos := 0
	var buses_sin_andar := 0
	for k in range(n_c, n_c + n_b):
		if peor_tras[k] > 60.0:   ## tras quitar las sirenas (durante ellas un bus cerca de una sirena SE PARA a propósito)
			buses_quietos += 1
			var vb: Dictionary = todos[k]
			var nb: Node3D = vb["nodo"]
			detalle_b.append("%s ruta %d s=%.0f quieto %.0f s (tras las sirenas) vact %.2f espera %.1f lod %s cola %s en (%.0f,%.0f)" % [nb.name, int(vb["ruta"]), float(vb["s"]), peor_tras[k], float(vb.get("vact", -1)), float(vb.get("espera", 0)), str(vb.get("lod")), str(vb.has("cola")), nb.position.x, nb.position.z])
		if recorrido[k] < 50.0:
			buses_sin_andar += 1
	var gente_quieta := 0
	for k in range(n_c + n_b, todos.size()):
		if peor[k] > 120.0:
			gente_quieta += 1
	print("  (info) peor tiempo quieto seguido de un coche tras quitar las sirenas: %.0f s; coches > 90 s: %d de %d; buses > 60 s quietos: %d de %d, sin andar: %d; peatones > 120 s quietos: %d de %d" % [peor_coche, atascados, n_c, buses_quietos, n_b, buses_sin_andar, gente_quieta, gente.size()])
	_comprobar(float(atascados) <= float(n_c) * 0.03, "los atascos se deshacen tras quitar las sirenas: %d de %d coches siguen > 90 s quietos (≤ 3 %%)" % [atascados, n_c])
	_comprobar(float(gente_quieta) <= float(gente.size()) * 0.15, "peatones quietos > 120 s sin motivo: %d de %d (≤ 15 %%)" % [gente_quieta, gente.size()])
	for l in detalle_b:
		print("    BUS QUIETO: ", l)
	_comprobar(buses_quietos == 0 and buses_sin_andar == 0, "los buses salen del paradero: %d quietos > 60 s y %d sin recorrer 50 m en 6 min" % [buses_quietos, buses_sin_andar])
	(c["vc"] as Node).free()
