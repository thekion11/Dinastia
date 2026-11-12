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
	## (11-11) Solo los del original: las extras de `datos/anims_extra` (prefijo «ext_») no cuentan aquí.
	var orig := LeagueMovimiento.clips().filter(func(c): return not String(c["nombre"]).begins_with("ext_"))
	_comprobar(orig.filter(func(c): return not c.has("auto")).size() == 98 and orig.size() - 98 == (874 if LeagueAuto.activas else 0), "49 clips de movimiento del original con su espejo y 437 intermedias legales con el suyo (%d)" % orig.size())
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
	var iguales := true
	for k in 72:
		var a := -PI + k * TAU / 72.0 + 0.013
		var dir := Vector2(0, -1).rotated(a)
		var mejor := 0.0
		var md := -2.0
		for f: float in LeagueMovimiento.CUERPOS:
			if Vector2(0, -1).rotated(f * PI).dot(dir) > md:
				md = Vector2(0, -1).rotated(f * PI).dot(dir)
				mejor = f * PI
		iguales = iguales and absf(LeagueMovimiento.cuerpo_permitido(a) - mejor) < 0.001
	_comprobar(iguales, "el cuerpo permitido por umbrales da lo mismo que el del original (mayor producto escalar)")
	## Las «angled» (cuerpo girado respecto a la marcha).
	_comprobar(LeagueMovimiento.plantilla(LeagueMovimiento.DRIBBLE, -0.25 * PI) == ["ls_templates__dribbleD045", "ls_templates__dribbleD045_left_espejo"], "trote con el cuerpo a -45°: la plantilla y, para el otro pie, el espejo de la girada al otro lado")
	_comprobar(LeagueMovimiento.plantilla(LeagueMovimiento.WALK, 0.75 * PI).is_empty() and LeagueMovimiento.plantilla(LeagueMovimiento.SPRINT, 0.25 * PI).is_empty(), "sin plantilla a 135° al trote rápido ni girado a toda carrera (como el original)")
	_comprobar(LeagueMovimiento.cuerpo_posible(LeagueMovimiento.SPRINT, 0.25 * PI) == 0.0 and LeagueMovimiento.cuerpo_posible(LeagueMovimiento.WALK, -0.75 * PI) == -0.25 * PI and LeagueMovimiento.cuerpo_posible(LeagueMovimiento.IDLE, 0.75 * PI) == 0.0, "el cuerpo que admite cada velocidad (sprint de frente, trote rápido < 90°, parado de frente)")
	_comprobar(absf(LeagueMovimiento.mirada(1.0, 0.0, 0.0) - 1.0) < 0.001 and LeagueMovimiento.mirada(1.0, 8.0, 8.0) < 0.85, "la mirada va al balón entera parado y menos a toda carrera")
	var de_lado := LeagueMovimiento.elegir(3.5, 0.0, 3.5, 0.0, -0.25 * PI)
	_comprobar(absf(float(de_lado.get("cuerpo_sale", 0.0)) + 0.25 * PI) < 0.2, "al trote, de frente y queriendo mirar 45° a la derecha: un clip que deja el cuerpo a -45° (%s)" % de_lado.get("nombre", ""))
	## El pie (L `CompareFootSimilarity`, `GetOutgoingFoot`).
	var der := String(LeagueMovimiento.elegir(5.0, 0.0, 8.0, 0.0, NAN, "D").get("nombre", ""))
	var izq := String(LeagueMovimiento.elegir(5.0, 0.0, 8.0, 0.0, NAN, "I").get("nombre", ""))
	_comprobar(der == "ls_movement__walk__000_accel" and izq == "ls_movement__walk__000_accel_espejo", "acelerando de frente: el clip que empieza con el pie que toca (%s / %s)" % [der, izq])
	var dos_pasos: Dictionary = {}
	for c: Dictionary in LeagueMovimiento.clips():
		if String(c["nombre"]) == "ls_movement__dribble__135":
			dos_pasos = c
	_comprobar(String(dos_pasos.get("pie_sale", "")) == "D", "un clip de 2 pasos que empieza con el derecho deja el derecho para el siguiente")
	_comprobar(String(LeagueMovimiento.elegir(0.0, 0.0, 5.0, 0.0, NAN, "I").get("nombre", "")) == "ls_movement__idle__000_accel", "parado, el pie no cuenta (como el original)")

## CATÁLOGO ETIQUETADO (11-11, fase 4): otras animaciones se suman con `datos/anims_extra/*.json` sin tocar código y la elección las ve.
func _probar_league_catalogo() -> void:
	_titulo("MOTOR LEAGUE: CATÁLOGO ETIQUETADO Y EXTENSIBLE")
	LeagueCatalogo.reiniciar()
	LeagueMovimiento.reiniciar()
	var base := LeagueMovimiento.clips().size()
	## (11-11) Ya hay extras reales en `datos/anims_extra` (la sesión de animaciones): la prueba mide a partir de lo que haya.
	var n0 := LeagueCatalogo.extras().size()
	_comprobar(n0 % 2 == 0 and LeagueCatalogo.extras().all(func(e): return String(e["nombre"]).begins_with("ext_")), "las extras de datos/anims_extra entran en pares (normal y espejo) y con prefijo ext_ (%d; catálogo %d)" % [n0, base])
	var mal := LeagueCatalogo.agregar([{"nombre": "sin_prefijo", "entra": 0, "sale": 5, "ang": 0, "largo": 0.4},
		{"nombre": "ext_largo_absurdo", "entra": 0, "sale": 5, "ang": 0, "largo": 9.0}, {"nombre": "ext_sin_largo", "entra": 0, "sale": 5, "ang": 0},
		{"nombre": "ext_pie_raro", "entra": 0, "sale": 5, "ang": 0, "largo": 0.4, "pie": "X"}, {"nombre": "ext_grados", "entra": 0, "sale": 5, "ang": 90.0 * 5.0, "largo": 0.4}])
	_comprobar(mal.size() == 5 and LeagueCatalogo.extras().size() == n0, "cinco entradas mal etiquetadas se rechazan con su motivo (%d)" % mal.size())
	## Un arranque de prueba con las MISMAS etiquetas que uno del original (reusa su clip): con el empate gana el del original.
	var antes := String(LeagueMovimiento.elegir(0.0, -PI / 2.0, 5.0).get("nombre", ""))
	var ok := LeagueCatalogo.agregar([{"nombre": "ext_prueba_arranque", "clip": "ls_movement__idle__090_accel", "clip_espejo": "ls_movement__idle__090_accel_espejo",
		"entra": 0, "sale": 3.5, "ang": -1.5795, "cuerpo": -1.6004, "largo": 0.26, "reposo": 1, "pie": "D"}])
	_comprobar(ok.is_empty() and LeagueCatalogo.extras().size() == n0 + 2, "una entrada buena trae su versión normal y su espejo")
	LeagueMovimiento.reiniciar()
	_comprobar(LeagueMovimiento.clips().size() == base + 2, "el catálogo de movimiento la incluye (%d)" % LeagueMovimiento.clips().size())
	_comprobar(antes == "ls_movement__idle__090_accel" and String(LeagueMovimiento.elegir(0.0, -PI / 2.0, 5.0).get("nombre", "")) == "ls_movement__idle__090_accel", "con un empate gana el del original")
	var porpie := LeagueCatalogo.buscar({"tipo": "arranque", "ext": true}, {"ang": -PI / 2.0}).filter(func(e): return String(e["nombre"]).begins_with("ext_prueba"))
	_comprobar(porpie.size() == 2 and String(porpie[0]["nombre"]) == "ext_prueba_arranque" and String(porpie[0]["tipo"]) == "arranque", "buscar por etiquetas (tipo + ang) la encuentra primero")
	var lado := LeagueCatalogo.buscar({"tipo": "arranque", "pie": "I"}, {"ang": PI / 2.0})
	_comprobar(not lado.is_empty() and String(lado[0]["pie"]) == "I" and float(lado[0]["ang"]) > 1.0, "buscar con filtro de pie y giro a la izquierda")
	var tareas := LeagueAnim.tareas_movimiento().filter(func(t): return String(t[0]).begins_with("ext_"))
	_comprobar(tareas.is_empty(), "las extras NO se cargan por tandas en cada jugador (se cargan al elegirlas: 82 de 100STYLE costaban ~450 ms por tanda)")
	var lib := AnimationLibrary.new()
	var correr := Animation.new()
	correr.add_track(Animation.TYPE_ROTATION_3D)
	correr.track_set_path(0, NodePath("Armature/Skeleton3D:pelvis"))
	correr.track_insert_key(0, 0.0, Quaternion.IDENTITY)
	var ap := AnimationPlayer.new()
	lib.add_animation("correr", correr)
	ap.add_animation_library("", lib)
	var cargado := LeagueCatalogo.clip("ext_prueba_arranque", "Armature/Skeleton3D")
	_comprobar(cargado != null and cargado.loop_mode == Animation.LOOP_NONE and str(cargado.track_get_path(0)).begins_with("Armature/Skeleton3D:"), "el clip extra se carga bajo demanda, sin bucle y con las pistas reapuntadas")
	ap.free()
	LeagueCatalogo.reiniciar()
	LeagueMovimiento.reiniciar()
	_comprobar(LeagueMovimiento.clips().size() == base, "reiniciar deja el catálogo como de fábrica")

## MÁS VIDA (11-11, fase 4d): la falta leve de `LeagueAcciones` solo cambia el nombre del clip y es determinista.
func _probar_league_acciones() -> void:
	_titulo("MOTOR LEAGUE: ACCIONES DE LA TABLA (falta leve)")
	var p := {"id": "jugador_a"}
	_comprobar(LeagueAcciones.variante(p, "correr") == "correr" and not p.has("ls_golpes"), "otros gestos no se tocan")
	var visto := {}
	for i in 12:
		visto[LeagueAcciones.variante(p, "duelo_empujado_der")] = true
	_comprobar(int(p["ls_golpes"]) == 12 and visto.has("duelo_empujado_der"), "sin cuerpo cargado el choque conserva su clip (y cuenta los golpes)")
	var q := {"id": "jugador_a"}
	var r := {"id": "jugador_a"}
	var igual := true
	for i in 9:
		igual = igual and LeagueAcciones.variante(q, "duelo_empujado_izq") == LeagueAcciones.variante(r, "duelo_empujado_izq")
	_comprobar(igual, "el reparto es determinista")
	## Celebración con CMU: sin cuerpo cargado conserva «celebrar»; con uno de prueba, 2 de cada 5 veces cambia y el clip queda recortado.
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	var correr := Animation.new()
	correr.add_track(Animation.TYPE_ROTATION_3D)
	correr.track_set_path(0, NodePath("Armature/Skeleton3D:pelvis"))
	correr.track_insert_key(0, 0.0, Quaternion.IDENTITY)
	lib.add_animation("correr", correr)
	ap.add_animation_library("", lib)
	var c := {"id": "goleador", "anim": ap}
	var cambios := 0
	var nombres := {}
	for i in 20:
		var cel := LeagueAcciones.variante(c, "celebrar")
		if cel != "celebrar":
			cambios += 1
			nombres[cel] = true
	## (12-11) 2 de cada 5 un baile o una alegría y 1 de cada 5 una acrobacia (esta, con la duración del «celebrar» para el motor).
	_comprobar(cambios == 12, "celebra con CMU 3 de cada 5 veces: 2 bailes o alegrías y 1 acrobacia (%d de 20)" % cambios)
	var primero := String(nombres.keys()[0]) if not nombres.is_empty() else ""
	_comprobar(primero.begins_with("ext_cmu_") and lib.has_animation(primero) and lib.get_animation(primero).length <= LeagueAcciones.MAX_CELEBRACION + 0.001 \
		and str(lib.get_animation(primero).track_get_path(0)).begins_with("Armature/Skeleton3D:"), "el clip de CMU se carga recortado y con las pistas reapuntadas (%s)" % primero)
	ap.free()
	_comprobar(AnimExtra.UAL2.has("golpe_pecho") and AnimExtra.UAL2.has("golpe_cabeza"), "los dos clips de golpe están en la tabla de la UAL")

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
