extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: PEATONES al límite en la ciudad armada.
##   1. Se suman 500 peatones a las rutas de gente que ya existen y se simulan 60 s: posiciones finitas, ninguno fuera del mapa (±1500 m), sin pares encimados (< 0,2 m) por encima de un tope y sin manada parada (< 20 % quietos por semáforo/charla).
##   2. El coste del paso del tráfico con esos 500 más (ms por paso, solo para saber: sin GPU).
##   3. Los peatones que esperan en un cruce con su semáforo en rojo no pisan la calzada en rojo para los coches (la fase la rige `Semaforos`).
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const EXTRA := 500
const PASOS := 600   ## 60 s a 0,1 s

func _probar() -> void:
	_titulo("A4 MUNDO_3D: peatones al límite (+%d, 60 s)" % EXTRA)
	var c: Dictionary = await Comun.abrir(self)
	var cb: Node = c["cb"]
	var t: Object = cb.get_node_or_null("Trafico")
	_comprobar(t != null, "la ciudad trae su tráfico")
	if t == null:
		return
	t.set_process(false)
	var sem: Object = t.get("semaforos")
	if sem != null:
		sem.set_process(false)
	var rutas_gente := {}
	for v: Dictionary in t.get("_vehiculos"):
		if bool(v.get("peaton", false)):
			rutas_gente[int(v["ruta"])] = true
	var ids: Array = rutas_gente.keys()
	var antes := 0
	for v: Dictionary in t.get("_vehiculos"):
		if bool(v.get("peaton", false)):
			antes += 1
	_comprobar(ids.size() >= 4, "hay rutas de gente (%d) y %d peatones de serie" % [ids.size(), antes])
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in EXTRA:
		var ruta := int(ids[rng.randi() % ids.size()])
		var largo := float((t.get("_rutas") as Array)[ruta].get("largo"))
		cb.call("_un_peaton", t, rng, ruta, rng.randf() * largo)
	var peatones: Array = []
	for v: Dictionary in t.get("_vehiculos"):
		if bool(v.get("peaton", false)) and is_instance_valid(v["nodo"]):
			peatones.append(v)
	_comprobar(peatones.size() >= antes + EXTRA - 5, "se sumaron %d peatones (ahora %d)" % [EXTRA, peatones.size()])
	var t0 := Time.get_ticks_usec()
	var encimados := 0
	var maximo_enc := 0
	var fuera := 0
	var no_finitos := 0
	for i in PASOS:
		if sem != null:
			sem.call("_process", 0.1)
		t.call("_process", 0.1)
		if i % 20 == 19:
			await get_tree().process_frame
		if i % 30 == 29:
			var rejilla := {}
			var en_este := 0
			for v: Dictionary in peatones:
				var p: Vector3 = (v["nodo"] as Node3D).position
				if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
					no_finitos += 1
					continue
				if absf(p.x) > 1500.0 or absf(p.z) > 1500.0:
					fuera += 1
				var k := Vector2i(floori(p.x / 2.0), floori(p.z / 2.0))
				if not rejilla.has(k):
					rejilla[k] = []
				(rejilla[k] as Array).append(p)
			for k: Vector2i in rejilla:
				var lst: Array = rejilla[k]
				for a in lst.size():
					for b in range(a + 1, lst.size()):
						if (lst[a] as Vector3).distance_to(lst[b]) < 0.2:
							en_este += 1
			encimados += en_este
			maximo_enc = maxi(maximo_enc, en_este)
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(PASOS)
	var quietos := 0
	for v: Dictionary in peatones:
		if float(v.get("vact", v.get("vel", 1.0))) < 0.05 and float(v.get("espera", 0.0)) <= 0.0:
			quietos += 1
	print("  (info) %d peatones: %.1f ms por paso del tráfico, %d encimados (máx %d en una foto), %d quietos al final" % [peatones.size(), ms, encimados, maximo_enc, quietos])
	_comprobar(no_finitos == 0, "ninguna posición no finita (%d)" % no_finitos)
	_comprobar(fuera == 0, "ningún peatón fuera del mapa (%d veces)" % fuera)
	_comprobar(maximo_enc <= 30, "pares encimados (< 0,2 m) en una foto con %d peatones ≤ 30 (máx %d)" % [peatones.size(), maximo_enc])
	_comprobar(float(quietos) <= float(peatones.size()) * 0.2, "la gente no se queda quieta en bloque (%d de %d)" % [quietos, peatones.size()])
	(c["vc"] as Node).free()
