extends BaseIdea
## S6 · NPC CON PARAGUAS CUANDO LLUEVE (27-10-2026): abren paraguas, caminan más rápido, alguno se resguarda y al escampar se recoge todo.

func _probar() -> void:
	_titulo("S6 · PARAGUAS, PRISA Y RESGUARDO CON LLUVIA")
	var raiz := Node3D.new()
	add_child(raiz)
	var lista: Array = []
	for k in 12:
		var d := PeatonVida.nuevo(raiz, 300 + k)
		var nodo := d["nodo"] as Node3D
		nodo.position = Vector3(float(k) * 3.0, 0, 0)
		lista.append({"nodo": nodo, "peaton": true, "vel": 1.4, "anim": d["anim"]})
	lista.append({"nodo": Node3D.new(), "peaton": false, "vel": 12.0})   ## un coche: ni caso
	_comprobar(ParaguasVida.llueve("lluvia") and ParaguasVida.llueve("tormenta") and not ParaguasVida.llueve("despejado") and not ParaguasVida.llueve("nublado"), "llueve solo con lluvia y tormenta")
	var a0 := ParaguasVida.tick(lista, false, [], 1)
	_comprobar(a0 == 0 and is_equal_approx(float(lista[0]["vel"]), 1.4), "sin lluvia no hay paraguas ni prisa")
	var a1 := ParaguasVida.tick(lista, true, [], 1)
	_comprobar(a1 == 12, "con lluvia los 12 peatones abren paraguas (%d)" % a1)
	_comprobar(is_equal_approx(float(lista[0]["vel"]), 1.4 * ParaguasVida.FACTOR_PRISA) and not lista[12].has("vel0"), "caminan un 25 %% más rápido y el coche no cambia (%.2f)" % float(lista[0]["vel"]))
	ParaguasVida.tick(lista, true, [], 2)
	_comprobar(is_equal_approx(float(lista[0]["vel"]), 1.4 * ParaguasVida.FACTOR_PRISA), "el repaso siguiente no acelera dos veces")
	var cop := (lista[0]["nodo"] as Node3D).find_child(ParaguasVida.NOMBRE, true, false) as Node3D
	_comprobar(cop is BoneAttachment3D and (cop as BoneAttachment3D).bone_name == "hand_r" and cop.get_child_count() == 1 and cop.get_child(0).get_child_count() == 2, "el paraguas va en la mano derecha (copa y mango)")
	var ap0: AnimationPlayer = lista[0]["anim"]
	_comprobar(ap0.has_animation("caminar_paraguas") and ap0.current_animation == "caminar_paraguas", "con el paraguas el brazo derecho va levantado (caminar_paraguas)")
	## Resguardo: junto a una entrada, con el paso de los repasos alguno se para bajo la marquesina (máx. 5) y cierra el paraguas.
	var puertas := [{"p": Vector3(0, 0, 0), "n": Vector3(0, 0, 1)}, {"p": Vector3(12, 0, 0), "n": Vector3(0, 0, 1)}, {"p": Vector3(24, 0, 0), "n": Vector3(0, 0, 1)}]
	for c in 40:
		ParaguasVida.tick(lista, true, puertas, 10 + c)
	var parados := 0
	for v in lista:
		if bool(v.get("resguardo", false)) and bool(v.get("pausa", false)):
			parados += 1
			_comprobar((v["nodo"] as Node3D).find_child(ParaguasVida.NOMBRE, true, false) == null, "el resguardado lleva el paraguas cerrado")
	_comprobar(parados >= 1 and parados <= ParaguasVida.MAX_RESGUARDADOS, "se resguardan %d (de 1 a %d)" % [parados, ParaguasVida.MAX_RESGUARDADOS])
	## Al escampar se recoge todo.
	ParaguasVida.tick(lista, false, puertas, 99)
	var abiertos := 0
	for v in lista:
		if v["nodo"].find_child(ParaguasVida.NOMBRE, true, false) != null:
			abiertos += 1
	_comprobar(abiertos == 0 and is_equal_approx(float(lista[0]["vel"]), 1.4) and not lista[0].has("vel0"), "al escampar se guardan los paraguas y vuelve la velocidad")
