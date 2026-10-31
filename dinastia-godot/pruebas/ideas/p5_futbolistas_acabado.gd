extends BaseIdea
## §2.5 punto 5 (31-10-2026): los futbolistas del partido llevan el pelo del Drive donde coincide con el corte de su retrato (sin foto
## real) y la postura relajada de manos de los peatones, en versión «atleta» (sin encorvarse y sin puño apretado).

func _probar() -> void:
	_titulo("§2.5-5: PELO Y POSTURA DE LOS FUTBOLISTAS")
	var rizados := {}
	for k in 40:
		rizados[PeloDrive.para_futbolista("j%d" % k, "rizado", false)] = true
	_comprobar(rizados.keys().all(func(x: int) -> bool: return x in [80, 59]) and rizados.size() == 2, "el corte rizado lleva los dos rizados del Drive (%s)" % str(rizados.keys()))
	_comprobar(PeloDrive.para_futbolista("j1", "flequillo", false) == 68, "el flequillo, el flequillo despeinado (68)")
	_comprobar(PeloDrive.para_futbolista("j1", "corto", false) == -1, "el corto sigue con el corte del pack")
	_comprobar(PeloDrive.para_futbolista("j1", "rizado", true) == -1, "con foto real no se le cambia el pelo")
	_comprobar(PeloDrive.para_futbolista("j7", "rizado", false) == PeloDrive.para_futbolista("j7", "rizado", false), "y el mismo jugador lleva siempre el mismo")
	for id in [80, 68, 59]:
		_comprobar(PeloDrive.malla(id) != null, "la malla del peinado %d existe" % id)
	## Postura: el atleta tiene las manos igual de relajadas pero los hombros y el cuello mucho más rectos que el peatón.
	var esq := Skeleton3D.new()
	add_child(esq)
	for h in ["spine_03", "neck_01", "Head", "clavicle_l", "clavicle_r", "index_01_l"]:
		esq.add_bone(h)
	var peaton := PosturaQ.new()
	var atleta := PosturaQ.new()
	peaton.configurar(esq, 1234, false)
	atleta.configurar(esq, 1234, true)
	var ang := func(m: PosturaQ, i: int) -> float: return rad_to_deg(m._giros[i].get_angle())
	_comprobar(absf(ang.call(atleta, 3)) <= absf(ang.call(peaton, 3)) * 0.34 + 0.01, "hombro del atleta %.1f° contra %.1f° del peatón" % [ang.call(atleta, 3), ang.call(peaton, 3)])
	_comprobar(absf(ang.call(atleta, 1)) <= absf(ang.call(peaton, 1)) * 0.36 + 0.01, "cuello del atleta %.1f° contra %.1f°" % [ang.call(atleta, 1), ang.call(peaton, 1)])
	_comprobar(absf(ang.call(atleta, 4) - ang.call(peaton, 4) * 0.7) < 0.05, "y los dedos algo menos doblados que el peatón (%.1f° contra %.1f°)" % [ang.call(atleta, 4), ang.call(peaton, 4)])
	var todos_nivelan := true
	for s in 60:
		var m := PosturaQ.new()
		m.configurar(esq, s, true)
		todos_nivelan = todos_nivelan and m._nivelar
	_comprobar(todos_nivelan, "ningún atleta va con la cabeza gacha")
	esq.queue_free()
