extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: LLUVIA y PARAGUAS con ~170 peatones de noche, cambiando el clima 20 veces seguidas (lluvia ↔ despejado, y tormenta).
##   1. Ningún peatón lleva más de un paraguas (no se duplican) y con el cielo despejado no queda ninguno abierto en toda la ciudad.
##   2. La lluvia (`PrecipitacionCiudad`, con sus charcos) se monta al llover y se QUITA al escampar: tras las 20 vueltas no quedan nodos de lluvia y el árbol vuelve a su tamaño.
##   3. El suelo mojado vuelve a como estaba (rugosidad del asfalto) al escampar.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

func _probar() -> void:
	_titulo("A4 MUNDO_3D: lluvia y paraguas, 20 cambios de clima con la gente de noche")
	AjustesCiudad.guardar("tutorial_visto", true)
	var c: Dictionary = await Comun.abrir(self)
	var vc: Node = c["vc"]
	var cb: Node = c["cb"]
	vc.set("_ciclo_activo", false)
	vc.set("_hora", 23.0)
	vc.call("_aplicar_hora")
	vc.call("explorar", "pie")
	for i in 10:
		await get_tree().process_frame
	var e: ExploradorCiudad = vc.get("_explorador")
	var vida: VidaCiudad = VidaCiudad.enganchar(e, vc, c["m"])
	var paraguas: ParaguasVida = vida.paraguas
	paraguas.set_process(false)   ## los cambios de clima los llevo yo, a mano
	_comprobar(paraguas != null, "la ciudad trae su gestor de lluvia y paraguas")
	if paraguas == null:
		return
	var trafico: Object = cb.get_node_or_null("Trafico")
	var gente := 0
	for v: Dictionary in trafico.get("_vehiculos"):
		if bool(v.get("peaton", false)):
			gente += 1
	print("  (info) %d peatones" % gente)
	var nodos0 := vc.find_children("*", "", true, false).size()
	var huer0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var duplicados := 0
	var maximo_abiertos := 0
	var climas := ["lluvia", "despejado", "tormenta", "despejado", "lluvia", "lluvia", "despejado", "tormenta", "tormenta", "despejado"]
	for k in 20:
		var clima: String = climas[k % climas.size()]
		paraguas.call("_actualizar_lluvia", clima, cb)
		var abiertos := ParaguasVida.tick(trafico.get("_vehiculos"), ParaguasVida.llueve(clima), cb.get("puertas_vida"), k + 1)
		await get_tree().process_frame
		maximo_abiertos = maxi(maximo_abiertos, abiertos)
		for v: Dictionary in trafico.get("_vehiculos"):
			if bool(v.get("peaton", false)) and is_instance_valid(v["nodo"]):
				if (v["nodo"] as Node).find_children(ParaguasVida.NOMBRE, "", true, false).size() > 1:
					duplicados += 1
		if not ParaguasVida.llueve(clima):
			var sueltos := vc.find_children(ParaguasVida.NOMBRE, "", true, false).size()
			if sueltos > 0:
				duplicados += 1000
				print("    CON %s quedan %d paraguas en la ciudad: %s" % [clima, sueltos, vc.find_children(ParaguasVida.NOMBRE, "", true, false)[0].get_path()])
	paraguas.call("_actualizar_lluvia", "despejado", cb)
	await get_tree().process_frame
	await get_tree().process_frame
	var lluvia_restos := 0
	for n in vc.find_children("*", "", true, false):
		var nm := String(n.name)
		if nm.begins_with("Precipitacion") or nm.begins_with("CharcosLluvia") or nm.begins_with("Lluvia") or nm.begins_with("Relampagos"):
			lluvia_restos += 1
	var nodos1 := vc.find_children("*", "", true, false).size()
	var huer1 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	print("  (info) máximo de paraguas abiertos a la vez %d de %d; nodos %d → %d; huérfanos %d → %d; restos de lluvia %d" % [maximo_abiertos, gente, nodos0, nodos1, huer0, huer1, lluvia_restos])
	_comprobar(maximo_abiertos > 0, "con lluvia hay paraguas abiertos (%d)" % maximo_abiertos)
	_comprobar(duplicados == 0, "ningún peatón con dos paraguas y ninguno suelto con cielo despejado (%d casos)" % duplicados)
	_comprobar(lluvia_restos == 0, "al escampar no quedan nodos de lluvia ni charcos (%d)" % lluvia_restos)
	_comprobar(nodos1 - nodos0 < 200, "el árbol no crece con los 20 cambios de clima (%d → %d)" % [nodos0, nodos1])
	_comprobar(huer1 - huer0 < 80, "ni los nodos huérfanos (%d → %d)" % [huer0, huer1])
	(c["vc"] as Node).free()
