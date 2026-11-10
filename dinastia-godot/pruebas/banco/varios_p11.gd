extends "res://pruebas/banco/varios_p11_p1.gd"
## (Parte 2 de 2 de `varios_p11.gd`.)

## FORMACIONES PROPIAS (10-11, pedido del dueño, «Editar posición» del PES 2020): el puesto cambia solo según la zona, el portero no
## se mueve, quedan al menos 3 defensas, se guarda con ★ en la tabla y vuelve al cargar la partida.
func _probar_formacion_propia() -> void:
	_titulo("TÁCTICA: FORMACIONES PROPIAS")
	_comprobar(FormacionPropia.puesto_de(50, 80) == "DFC" and FormacionPropia.puesto_de(88, 75) == "LD" and FormacionPropia.puesto_de(50, 62) == "MCD" and FormacionPropia.puesto_de(12, 60) == "CAI" and FormacionPropia.puesto_de(50, 33) == "MCO" and FormacionPropia.puesto_de(82, 22) == "ED" and FormacionPropia.puesto_de(50, 18) == "DC", "el puesto sale de la zona (DFC, LD, MCD, CAI, MCO, ED, DC)")
	var f := FormacionPropia.desde("4-4-2")
	_comprobar(int(f["DEF"]) == 4 and int(f["MED"]) == 4 and int(f["DEL"]) == 2, "parte de la base 4-4-2")
	_comprobar(FormacionPropia.mover(f, 0, 50, 60) == "portero", "el portero no se mueve")
	var mc := -1
	for i in (f["s"] as Array).size():
		if String(f["s"][i][0]) == "MC":
			mc = i
			break
	_comprobar(FormacionPropia.mover(f, mc, 50, 32) == "" and String(f["s"][mc][0]) == "MCO" and int(f["MED"]) == 4, "un mediocentro que sube pasa a mediapunta (4-4-2 con rombo)")
	var g := FormacionPropia.desde("3-5-2")
	var dfc := -1
	for i in (g["s"] as Array).size():
		var pu := String(g["s"][i][0])
		if pu == "CAD" or pu == "CAI":
			FormacionPropia.mover(g, i, float(g["s"][i][1]), 45.0)   ## los carrileros suben a interiores
		elif pu == "DFC" and dfc < 0:
			dfc = i
	_comprobar(int(g["DEF"]) == 3 and FormacionPropia.mover(g, dfc, 50, 45) == "defensas" and String(g["s"][dfc][0]) == "DFC", "con 3 defensas no se puede subir a otro")
	var c := Club.new()
	c.tactica = Tactica.new()
	var n := FormacionPropia.guardar(c.tactica, "Mi rombo", f)
	_comprobar(n == "★ Mi rombo" and Datos.tabla("FORMS").has(n) and Puente3D.formacion(n)["s"].size() == 11, "se guarda con ★ y la usa el partido (Puente3D)")
	var copia := c.tactica.duplicar()
	_comprobar(copia.propias.has(n), "viaja con la táctica (duplicar)")
	FormacionPropia.borrar(c.tactica, n)
	_comprobar(not Datos.tabla("FORMS").has(n) and c.tactica.propias.is_empty(), "borrar la quita de la pizarra")
	FormacionPropia.registrar_todas(copia.tactica if copia.has_method("tactica") else copia)
	_comprobar(Datos.tabla("FORMS").has(n), "al cargar la partida se vuelven a registrar")
	FormacionPropia.borrar(copia, n)
	var ed := EditorFormacion.crear(c)
	add_child(ed)
	_comprobar(ed.forma.has("s") and (ed.forma["s"] as Array).size() == 11, "el editor abre con la formación actual")
	ed.queue_free()

## LOCOMOCIÓN DE LEAGUE-SOCCER (10-11, fase 4c): la elección de arranques, frenadas y giros copia la del original
## (`HumanoidBase::SelectAnim` + `GetMovementSimilarity`) sobre los datos de `datos/league_movimiento.json`.
func _probar_league_movimiento() -> void:
	_titulo("MOTOR LEAGUE: ARRANQUES, FRENADAS Y GIROS DEL ORIGINAL")
	_comprobar(LeagueMovimiento.clips().size() == 38, "19 clips de movimiento del original con su espejo (%d)" % LeagueMovimiento.clips().size())
	_comprobar(LeagueMovimiento.rango(1.0) == 0.0 and LeagueMovimiento.rango(3.0) == 3.5 and LeagueMovimiento.rango(5.0) == 5.0 and LeagueMovimiento.rango(7.0) == 8.0, "velocidades escalonadas del original (RangeVelocity)")
	_comprobar(String(LeagueMovimiento.elegir(0.0, 0.0, 5.0).get("nombre", "")) == "ls_movement__idle__000_accel", "parado y quiere ir de frente: arranque recto")
	_comprobar(String(LeagueMovimiento.elegir(0.0, -PI / 2.0, 5.0).get("nombre", "")) == "ls_movement__idle__090_accel", "parado y quiere ir a la derecha: arranque girando 90° a la derecha")
	_comprobar(String(LeagueMovimiento.elegir(0.0, PI / 2.0, 5.0).get("nombre", "")) == "ls_movement__idle__090_accel_espejo", "a la izquierda: el mismo clip espejado")
	var frena := LeagueMovimiento.elegir(7.5, 0.0, 0.0)
	_comprobar(float(frena.get("entra", -1)) == 8.0 and float(frena.get("sale", -1)) == 0.0, "a toda carrera y quiere pararse: una frenada desde el sprint (%s)" % frena.get("nombre", ""))
	var vuelta := LeagueMovimiento.elegir(3.0, PI * 0.95, 3.0)
	_comprobar(absf(float(vuelta.get("ang", 0.0))) > 2.0, "al trote y quiere volver atrás: un giro de 135-180° (%s)" % vuelta.get("nombre", ""))
	_comprobar(LeagueMovimiento.estable(LeagueMovimiento.elegir(7.5, 0.0, 8.0)), "a toda carrera y de frente: el paso estable (no hay transición)")
	_comprobar(absf(LeagueMovimiento.sesgo_giro(Vector2(0, -7.5), Vector2(0, 7.5)) - 0.9) < 0.001 and LeagueMovimiento.sesgo_giro(Vector2(0, -7.5), Vector2(0, -7.5)) < 0.001, "sesgo de giro rápido: máximo al dar la vuelta, nulo de frente")

func _probar_visita_generada() -> void:
	_titulo("SEGUNDO UNIFORME PROPIO GENERADO (sin visita archivada)")
	var m := Mundo.new()
	m.generar(["ESP", "ARG", "JPN", "GER", "BRA", "MEX"], 5821)
	var n := 0
	var iguales := 0
	var distintos_disenos := {}
	var mala := ""
	for c: Club in m.clubes.values():
		if not VisitaGenerada.es_basica(AspectoClub.visita(c)):
			continue
		n += 1
		var v := VisitaGenerada.para(c)
		if str(v) != str(VisitaGenerada.para(c)):
			mala = "no es determinista: " + c.nombre
		if str(v["c1"]) == c.color_kit1() and str(v["c2"]) == c.color_kit2() and v["camiseta"] == DisenosKit._diseno_de(c):
			iguales += 1
		distintos_disenos[v["camiseta"]] = true
		if not (String(v["c1"]).begins_with("#") and String(v["pant"]).begins_with("#") and String(v["med"]).begins_with("#")):
			mala = "colores sin # en " + c.nombre
	_comprobar(n > 50, "hay clubes sin visita archivada que medir (%d)" % n)
	_comprobar(mala == "", "la visita generada es determinista y bien formada (%s)" % mala)
	_comprobar(iguales == 0, "ninguna visita es idéntica a la primera camiseta (%d de %d)" % [iguales, n])
	_comprobar(distintos_disenos.size() >= 4, "salen varios diseños distintos (%d)" % distintos_disenos.size())
	## La lógica de choque sigue mandando: con rival de su mismo color, la visita no se le parece.
	var cs: Array = m.clubes.values()
	var choques := 0
	for i in mini(cs.size(), 60):
		var a: Club = cs[i]
		var b: Club = cs[(i * 7 + 3) % cs.size()]
		if a == b:
			continue
		if Puente3D.chocan(Puente3D.kit(a), Puente3D.kit_visita(a, b)):
			choques += 1
	_comprobar(choques == 0, "la visita nunca choca con el local (%d choques)" % choques)
	## Legibilidad a la cámara real: cada diseño fino pasa a uno que existe, y no se toca el original.
	var validos: Array = DisenosKit.claves()
	var rotos := []
	for k: String in KitLegible.ANCHOS:
		if not validos.has(KitLegible.ANCHOS[k]) or not validos.has(k):
			rotos.append(k)
	_comprobar(rotos.is_empty(), "los diseños anchos existen (%s)" % str(rotos))
	var orig := {"dis": "diagonal", "cols": ["#ff0000", "#ffffff"]}
	_comprobar(KitLegible.para_partido(orig)["dis"] == "sash" and orig["dis"] == "diagonal" and KitLegible.para_partido({"dis": "liso"})["dis"] == "liso", "el diseño fino se ensancha sin tocar el original")
