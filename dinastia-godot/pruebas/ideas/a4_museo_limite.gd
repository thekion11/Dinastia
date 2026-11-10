extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: el MUSEO al límite. Un club con 200+ hitos (todas las competiciones, varias décadas, títulos largos):
##   1. Las vitrinas no se solapan, cada copa queda sobre su vitrina y dentro de la sala (ni fuera ni atravesando paredes).
##   2. Los rótulos (Label3D) caben: no se pisan entre sí y no se salen de la sala por los lados ni por el techo.
##   3. Ampliar el museo una tras otra (niveles 0→5 con obra) y entrar y salir del estadio 20 veces: ni nodos que crezcan ni edificios duplicados.
##   4. La animación de expansión se interrumpe a mitad (salir del estadio, reconstruir): sin tweens huérfanos ni errores, y las copas no se quedan encendidas.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const TITULOS := ["Campeonato Nacional", "Copa Libertadores de América", "Supercopa de Campeones Continentales", "Copa Sudamericana", "Recopa", "Copa Nacional del País", "Liga de Campeones", "Mundial de Clubes de la Federación"]

func _esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _hitos(n: int) -> Array:
	var h: Array = []
	for i in n:
		h.append({"anio": 1960 + i % 70, "titulo": TITULOS[i % TITULOS.size()], "final": "Final %d" % i, "goleadores": ["A (%d)" % i]})
	return h

func _probar() -> void:
	_titulo("A4 MUNDO_3D: museo al límite (200+ hitos, ampliar, entrar y salir, animación interrumpida)")
	AjustesCiudad.guardar("tutorial_visto", true)
	var c: Dictionary = await Comun.abrir(self)
	var vc: Node = c["vc"]
	vc.set("_ciclo_activo", false)
	vc.call("explorar", "pie")
	var e: Object = vc.get("_explorador")
	await _esperar(10)
	e.call("_entrar_al_estadio")
	await _esperar(4)
	var ctx: Dictionary = EdificioClub.ctx
	var inst: Dictionary = (ctx.get("inst", {}) as Dictionary).duplicate()
	## --- 1 y 2: geometría con 220 hitos
	ctx["inst"] = inst.duplicate()
	(ctx["inst"] as Dictionary)["museo"] = 5
	ctx["obras"] = {}
	ctx["hitos"] = _hitos(220)
	ctx["titulos"] = 220
	EdificioClub.reconstruir(get_tree().get_first_node_in_group("edificio_club") as Node3D)
	await _esperar(3)
	var ed := get_tree().get_first_node_in_group("edificio_club") as Node3D
	var vit: Array[Dictionary] = []
	vit.append_array(SalasClub.vitrinas)
	vit.append_array(MuseoAmpliado.vitrinas)
	var malas: Array[String] = []
	for i in vit.size():
		for j in range(i + 1, vit.size()):
			var a: Vector3 = vit[i]["p"]
			var b: Vector3 = vit[j]["p"]
			if absf(a.y - b.y) < 1.0 and Vector2(a.x - b.x, a.z - b.z).length() < 0.9:
				malas.append("vitrinas %d y %d solapadas (%.2f m)" % [int(vit[i]["k"]), int(vit[j]["k"]), Vector2(a.x - b.x, a.z - b.z).length()])
	print("  (info) %d vitrinas con 220 hitos" % vit.size())
	var etiquetas: Array = ed.find_children("*", "Label3D", true, false)
	var cajas: Array[Dictionary] = []
	for l: Label3D in etiquetas:
		if not l.visible or l.text.length() < 8:   ## (10-11) `visible` propio, no `is_visible_in_tree()`: la oclusión por plantas apaga las ramas de las otras plantas y no quedaba ningún rótulo que medir
			continue
		var ab := l.global_transform * l.get_aabb()
		cajas.append({"l": l, "ab": ab})
	var pisados := 0
	var ejemplo := ""
	for i in cajas.size():
		for j in range(i + 1, cajas.size()):
			var a: AABB = cajas[i]["ab"]
			var b: AABB = cajas[j]["ab"]
			var inter := a.grow(0.05).intersection(b.grow(0.05))   ## los rótulos son planos: se engordan para medir el solape
			if inter.size.x > 0.08 and inter.size.y > 0.08 and inter.size.z > 0.08:
				pisados += 1
				if ejemplo == "":
					ejemplo = "«%s» con «%s»" % [(cajas[i]["l"] as Label3D).text.left(40), (cajas[j]["l"] as Label3D).text.left(40)]
	var anchos: Array[float] = []
	for cc in cajas:
		anchos.append((cc["ab"] as AABB).size.length())
	anchos.sort()
	_comprobar(not anchos.is_empty(), "hay rótulos que medir (%d)" % anchos.size())
	if anchos.is_empty():
		return
	print("  (info) tamaños de rótulo: mín %.2f máx %.2f" % [anchos[0], anchos[-1]])
	print("  (info) %d rótulos medidos, %d pares que se pisan %s" % [cajas.size(), pisados, ejemplo])
	if pisados > 0:
		malas.append("%d pares de rótulos se pisan (%s)" % [pisados, ejemplo])
	_comprobar(malas.is_empty(), "vitrinas y rótulos del museo con 220 hitos (%d problemas%s)" % [malas.size(), "" if malas.is_empty() else ": " + str(malas.slice(0, 3))])
	## --- 3: ampliar una tras otra y entrar y salir 20 veces
	var nodos0 := vc.find_children("*", "", true, false).size()
	for nivel in [0, 3, 4, 5, 4, 5]:
		(ctx["inst"] as Dictionary)["museo"] = nivel
		ctx["obras"] = {"museo": 2} if nivel == 4 else {}
		EdificioClub.reconstruir(get_tree().get_first_node_in_group("edificio_club") as Node3D)
		await _esperar(2)
	var n_ed := get_tree().get_nodes_in_group("edificio_club").size()
	_comprobar(n_ed == 1, "ampliar seis veces seguidas deja un solo edificio (%d)" % n_ed)
	var nodos1 := vc.find_children("*", "", true, false).size()
	for k in 20:
		e.call("_ir_a_planta", 3 if k % 2 == 0 else 2)
		await _esperar(1)
		e.call("_salir_del_estadio")
		await _esperar(2)
		e.call("_entrar_al_estadio")
		await _esperar(2)
	var nodos2 := vc.find_children("*", "", true, false).size()
	print("  (info) nodos: inicio %d, tras ampliar %d, tras 20 entradas y salidas %d" % [nodos0, nodos1, nodos2])
	_comprobar(nodos2 - nodos1 < 300, "entrar y salir del estadio 20 veces no hace crecer los nodos (%d → %d)" % [nodos1, nodos2])
	_comprobar(get_tree().get_nodes_in_group("edificio_club").size() == 1, "tras 20 entradas, un solo edificio del club")
	## --- 4: animación de expansión interrumpida
	(ctx["inst"] as Dictionary)["museo"] = 5
	ctx["obras"] = {}
	AjustesCiudad.guardar("museo_ampliado_visto", 0)
	EdificioClub.reconstruir(get_tree().get_first_node_in_group("edificio_club") as Node3D)
	await _esperar(2)
	var anim := get_tree().get_first_node_in_group("edificio_club").find_child("AnimMuseoAmpliado", true, false)
	_comprobar(anim != null, "la planta 3 trae su animación de expansión")
	if anim != null:
		anim.set("_hecho", true)
		anim.call("_animar")   ## arranca a mitad y se corta
		await _esperar(5)
		var hubo := anim.find_children("*", "Label3D", true, false).size()
		e.call("_salir_del_estadio")
		await _esperar(3)
		e.call("_entrar_al_estadio")
		await _esperar(3)
		var ed2 := get_tree().get_first_node_in_group("edificio_club")
		var anim2 := ed2.find_child("AnimMuseoAmpliado", true, false) if ed2 != null else null
		var restos := 0
		if ed2 != null:
			for l: Label3D in ed2.find_children("*", "Label3D", true, false):
				if l.text.begins_with(Idiomas.t("Museo ampliado · %d títulos").split("%")[0]):
					restos += 1
		## La animación termina sola aunque el jugador esté fuera: 0,5 + copas x PASO + 1,5 + 0,8 s (con 36 vitrinas ~8 s; antes eran pocas copas y bastaban 5 s).
		var n_copas := (anim2.get("copas") as Array).size() if anim2 != null else 0
		await get_tree().create_timer(2.8 + MuseoAmpliadoAnim.PASO * float(n_copas) + 1.0).timeout
		restos = 0
		for l: Label3D in ed2.find_children("*", "Label3D", true, false):
			if l.text.begins_with(Idiomas.t("Museo ampliado · %d títulos").split("%")[0]):
				restos += 1
		print("  (info) cartel de la animación: %d en curso; tras salir y volver: %d (anim %s)" % [hubo, restos, anim2])
		_comprobar(restos == 0, "la animación cortada no deja el cartel «Museo ampliado» flotando (%d)" % restos)
		var apagadas := 0
		var encendidas := 0
		if anim2 != null:
			for mi in anim2.get("copas"):
				if is_instance_valid(mi) and (mi as MeshInstance3D).material_override is StandardMaterial3D:
					if (mi.material_override as StandardMaterial3D).emission_energy_multiplier > 1.0:
						encendidas += 1
					else:
						apagadas += 1
		_comprobar(encendidas == 0, "ninguna copa se queda a medio encender tras cortar la animación (%d de %d)" % [encendidas, encendidas + apagadas])
	ctx["inst"] = inst
	e.call("_ir_a_planta", 0)
	e.call("_salir_del_estadio")
	await _esperar(3)
	(c["vc"] as Node).free()
