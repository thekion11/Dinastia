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

## (13-11) Las butacas de grada sin caras ocultas (`MallasGradaMinima`) son las de siempre MENOS el suelo de cada caja y el techo de la viga: mismas superficies (área por plano y normal), todas hacia fuera.
func _butaca_antigua(completa: bool) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cajas := [[Vector3(1.46, 0.07, 0.40), Vector3(-0.05, 0.40, 0.04), 0.0], [Vector3(1.40, 0.30, 0.06), Vector3(-0.05, 0.20, -0.08), 0.0]]
	if completa:
		for k in 3:
			cajas.append([Vector3(0.44, 0.38, 0.05), Vector3(-0.55 + float(k) * 0.5, 0.58, -0.20), -0.14])
		for xb in [-0.30, 0.20]:
			cajas.append([Vector3(0.05, 0.05, 0.32), Vector3(xb, 0.50, -0.02), 0.0])
	else:
		cajas.append([Vector3(1.46, 0.38, 0.05), Vector3(-0.05, 0.58, -0.20), -0.14])
	for c: Array in cajas:
		var b := BoxMesh.new()
		b.size = c[0]
		st.append_from(b, 0, Transform3D(Basis(Vector3(1, 0, 0), float(c[2])), c[1]))
	return st.commit()

func _areas_por_normal(m: Mesh) -> Dictionary:
	var arr: Array = m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ind: Variant = arr[Mesh.ARRAY_INDEX]
	var out := {}
	for t in (ind.size() if ind != null else v.size()) / 3:
		var i0: int = ind[t * 3] if ind != null else t * 3
		var cruz := (v[ind[t * 3 + 1] if ind != null else t * 3 + 1] - v[i0]).cross(v[ind[t * 3 + 2] if ind != null else t * 3 + 2] - v[i0])
		var k := str(n[i0].snapped(Vector3.ONE * 0.01))
		out[k] = float(out.get(k, 0.0)) + cruz.length() * 0.5
		if cruz.dot(n[i0]) >= 0.0:
			out["revés"] = int(out.get("revés", 0)) + 1
	return out

func _probar_mallas_grada_minima() -> void:
	_titulo("BUTACAS DE GRADA SIN CARAS OCULTAS: LAS DE SIEMPRE MENOS SUELO Y TECHO DE VIGA")
	for caso: Array in [["MÍNIMA", MallasGradaMinima.butaca(), _butaca_antigua(false), 28], ["MEDIA", MallasGradaMinima.butaca_lejos(), _butaca_antigua(true), 68]]:
		var nuevo := _areas_por_normal(caso[1])
		var viejo := _areas_por_normal(caso[2])
		var igual := not nuevo.has("revés")
		for k in viejo:
			var ny := float(String(k).split(",")[1].strip_edges())
			var a_n := float(nuevo.get(k, 0.0))
			var a_v := float(viejo[k])
			if ny < -0.5:
				igual = igual and not nuevo.has(k)                                    ## abajo: ninguna
			elif ny > 0.5:
				igual = igual and (absf(a_n - a_v) < 0.0003 or absf(a_v - a_n - 0.084) < 0.0003)   ## arriba: iguales (salvo el techo de la viga, 1,40 × 0,06)
			else:
				igual = igual and absf(a_n - a_v) < 0.0003                            ## costados: iguales
		_comprobar(igual, "%s: mismas superficies que la butaca de siempre; solo faltan las de abajo y el techo de la viga, y ninguna cara del revés" % caso[0])
		_comprobar((caso[1].surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3 == int(caso[3]), "%s: %d triángulos" % [caso[0], int(caso[3])])

## (13-11) Los conos de luz de los focos solo se dibujan si su alfa es mayor que 0 (de día no suman nada, y eran 9 cilindros enormes rasterizados para nada).
func _probar_conos_de_luz() -> void:
	_titulo("CONOS DE LUZ DE LOS FOCOS: SOLO SE DIBUJAN CUANDO SE VEN")
	var viejo: StandardMaterial3D = StadiumBuilder._mat_cono
	StadiumBuilder._mat_cono = StandardMaterial3D.new()
	var cono := MeshInstance3D.new()
	cono.add_to_group("foco_cono")
	add_child(cono)
	StadiumBuilder.encender_conos(0.0)
	_comprobar(not cono.visible and is_zero_approx(StadiumBuilder._mat_cono.albedo_color.a), "de día (oscuro 0): alfa 0 y el cono no se dibuja")
	StadiumBuilder.encender_conos(0.4)
	_comprobar(not cono.visible, "justo en el umbral (oscuro 0,4): sigue sin dibujarse")
	StadiumBuilder.encender_conos(1.0)
	_comprobar(cono.visible and absf(StadiumBuilder._mat_cono.albedo_color.a - 0.035) < 0.0001, "de noche (oscuro 1): alfa 0,035 y el cono se dibuja")
	StadiumBuilder.encender_conos(0.7)
	_comprobar(cono.visible and StadiumBuilder._mat_cono.albedo_color.a > 0.0, "al atardecer (oscuro 0,7): visible")
	cono.free()
	StadiumBuilder._mat_cono = viejo

## (13-11) El calentamiento de efectos del partido: no falla sin grada, se apaga con CALENTAR_EFECTOS=0 y no deja nada vivo encima del campo.
func _probar_calentamiento_efectos() -> void:
	_titulo("CALENTAMIENTO DE EFECTOS: INVISIBLE Y SIN TOCAR NADA")
	var raiz := Node3D.new()
	add_child(raiz)
	CalentamientoEfectos._guardados.clear()   ## el calentamiento es de UNA vez por proceso: aquí se pide de cero
	CalentamientoEfectos.calentar(raiz)   ## sin grada solo salen las banderas (en un sitio dado, bajo el campo); el confeti necesita sitios de grada
	var piezas := raiz.find_children("*", "VisualInstance3D", true, false)
	var altas := 0
	for p in piezas:
		if (p as Node3D).global_position.y > -CalentamientoEfectos.BAJO + 5.0:
			altas += 1
	_comprobar(not piezas.is_empty() and altas == 0, "todo lo que dibuja el calentamiento está a unos 60 m bajo el campo (%d piezas, %d por encima)" % [piezas.size(), altas])
	_comprobar(CalentamientoEfectos.encendido() == (OS.get_environment("CALENTAR_EFECTOS") != "0"), "encendido salvo que CALENTAR_EFECTOS sea 0")
	raiz.free()

## (14-11) Siluetas de jugadores a más de 30 m, ajuste de color apagado en ULTRA BAJA y el 3D de ULTRA BAJA al 40 %.
func _probar_impostores_lejanos() -> void:
	_titulo("SILUETAS LEJANAS DE JUGADORES, AJUSTE DE COLOR Y 3D AL 40 % EN ULTRA BAJA")
	_comprobar(ImpostorLejano.activo(Calidad.MINIMO) and ImpostorLejano.activo(Calidad.BAJA) and ImpostorLejano.activo(Calidad.MEDIA_BAJA), "activas de ULTRA BAJA a MEDIA BAJA")
	_comprobar(not ImpostorLejano.activo(Calidad.MEDIA) and not ImpostorLejano.activo(Calidad.ALTA), "MEDIA y superiores: jugadores como siempre")
	var nodo := Node3D.new()
	var cuerpo := MeshInstance3D.new()
	cuerpo.mesh = BoxMesh.new()
	nodo.add_child(cuerpo)
	var rotulo := Label3D.new()
	nodo.add_child(rotulo)
	add_child(nodo)
	ImpostorLejano.aplicar(nodo, 1.8, Color("d32f2f"), Calidad.MEDIA)
	_comprobar(nodo.get_child_count() == 2 and is_zero_approx(cuerpo.visibility_range_end), "en MEDIA no se toca nada")
	ImpostorLejano.aplicar(nodo, 1.8, Color("d32f2f"), Calidad.MINIMO)
	var imp := nodo.get_node_or_null("ImpostorLejano") as MeshInstance3D
	_comprobar(imp != null and is_equal_approx(cuerpo.visibility_range_end, ImpostorLejano.distancia) and is_equal_approx(imp.visibility_range_begin, ImpostorLejano.distancia)
		and imp.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF, "el cuerpo se oculta y la silueta aparece a la misma distancia (%.0f m), con fundido" % ImpostorLejano.distancia)
	## (17-11, auditoría) Por tamaño en pantalla: con la TV cercana (21°, 1080 px de alto) un jugador a 30 m es grande; la silueta, a ~130 m.
	var d_tv := ImpostorLejano.distancia_para(21.0, 1080.0)
	var d_ancha := ImpostorLejano.distancia_para(70.0, 720.0)
	_comprobar(d_tv > 100.0 and d_ancha >= ImpostorLejano.DISTANCIA and d_ancha < d_tv
		and is_equal_approx(1.8 * 1080.0 / (2.0 * d_tv * tan(deg_to_rad(10.5))), ImpostorLejano.PIXELES),
		"umbral por tamaño: con la TV cercana %.0f m (= %d px de alto), con una cámara abierta %.0f m" % [d_tv, int(ImpostorLejano.PIXELES), d_ancha])
	_comprobar(is_zero_approx(rotulo.visibility_range_end), "los rótulos 3D no se tocan")
	var tris: int = (imp.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	_comprobar(tris <= 90 and is_equal_approx(imp.scale.y, 1.8), "silueta de %d triángulos y a la altura del jugador" % tris)
	nodo.free()
	## (16-11, frente 2) Con la piel, la silueta lleva short y medias de su equipación (mismos triángulos).
	var n2 := Node3D.new()
	var c2 := MeshInstance3D.new()
	c2.mesh = BoxMesh.new()
	var eq := ShaderMaterial.new()
	eq.shader = load("res://visor/equipacion_q.gdshader")
	eq.set_shader_parameter("color_pantalon", Color("101010"))
	eq.set_shader_parameter("color_medias", Color("1565c0"))
	c2.material_override = eq
	n2.add_child(c2)
	add_child(n2)
	ImpostorLejano.aplicar(n2, 1.8, Color("d32f2f"), Calidad.MINIMO, null, Color("c08060"))
	var imp2 := n2.get_node_or_null("ImpostorLejano") as MeshInstance3D
	var m2 := imp2.material_override as ShaderMaterial if imp2 != null else null
	_comprobar(m2 != null and Color(m2.get_shader_parameter("c_short")).is_equal_approx(Color("101010"))
		and Color(m2.get_shader_parameter("c_medias")).is_equal_approx(Color("1565c0")) and ImpostorLejano.TONOS_PIEL.has(Color(m2.get_shader_parameter("c_piel"))),
		"silueta con su equipación: short, medias y uno de los 4 tonos de piel")
	var med := n2.get_node_or_null("CuerpoMedio") as MeshInstance3D   ## (17-11) el cuerpo barato de media distancia: sin sombra y desde 30 m
	_comprobar(med != null and med.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and is_equal_approx(med.visibility_range_begin, ImpostorLejano.DISTANCIA) and is_equal_approx(c2.visibility_range_end, ImpostorLejano.DISTANCIA), "cuerpo barato de media distancia: sin sombra, de 30 m al umbral; el completo, hasta 30 m")
	n2.free()
	## Animación lejana: a más de 36 m del ojo pasa a modo manual (5 Hz) y a menos de 33 m vuelve a su ritmo.
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()
	var jug := Node3D.new()
	add_child(jug)
	var ap := AnimationPlayer.new()
	jug.add_child(ap)
	AnimLejana.poner(jug, ap)
	var al := jug.get_node("AnimLejana") as AnimLejana
	jug.global_position = Vector3(0, 0, -50)
	al._process(0.016)
	_comprobar(ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL, "a 50 m: animación en modo manual")
	jug.global_position = Vector3(0, 0, -34.5)
	al._process(0.016)
	_comprobar(ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL, "a 34,5 m (histéresis): sigue manual")
	jug.global_position = Vector3(0, 0, -20)
	al._process(0.016)
	_comprobar(ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE, "a 20 m: vuelve a su ritmo normal")
	cam.free()
	jug.free()
	_comprobar(not ModoRendimiento.ajuste_color(Calidad.MINIMO) and ModoRendimiento.ajuste_color(Calidad.BAJA) and ModoRendimiento.ajuste_color(Calidad.MEDIA), "ajuste de color: no en ULTRA BAJA, sí en el resto")
	_comprobar(is_equal_approx(Calidad.ESCALA_MINIMO, 0.4), "3D de ULTRA BAJA al 40 % por defecto")

## (15-11) Mundo clásico / suave: la etapa de la entrada, el ahorro en todas las calidades y menos partículas en el clásico.
func _probar_estilo_mundo() -> void:
	_titulo("ESTILO DEL MUNDO: CLÁSICO (MENOS MOVIMIENTO) Y SUAVE (QUIETO)")
	var antes := EstiloMundo.suave
	var tenia := EstiloMundo.elegido_antes()
	_comprobar(OrquestadorEntrada.ETAPAS.any(func(e: Dictionary) -> bool: return e["clave"] == "estilo"), "la etapa «estilo» está en la entrada")
	var i_estilo := OrquestadorEntrada.ETAPAS.map(func(e: Dictionary) -> String: return e["clave"]).find("estilo")
	var i_modo := OrquestadorEntrada.ETAPAS.map(func(e: Dictionary) -> String: return e["clave"]).find("modo")
	_comprobar(i_estilo >= 0 and i_estilo < i_modo, "va antes de elegir el modo y de crear el mundo")
	EstiloMundo.suave = false
	_comprobar(is_equal_approx(EstiloMundo.factor_particulas(), 0.5) and EstiloMundo.factor_movimiento() < 1.0, "clásico: la mitad de partículas y menos movimiento")
	var f := FondoAnimado.new()
	f.modo = "motas"
	add_child(f)
	_comprobar(f.emitting and f.amount == 20, "clásico: las motas pasan de 40 a %d" % f.amount)
	EstiloMundo.suave = true
	f.aplicar()
	_comprobar(not f.emitting and not f.visible, "suave: sin partículas")
	_comprobar(AhorroMenu.nivel_ahorra(Calidad.ALTA, false) == false and (not AhorroMenu.toca() or DisplayServer.get_name() != "headless"), "el ahorro de siempre no cambia por nivel")
	f.free()
	var p := EstiloMundoPantalla.new()
	p.configurar({"estilo": "suave"})
	add_child(p)
	var recibido: Array = []
	p.terminado.connect(func(d: Dictionary) -> void: recibido.append(d))
	p.confirmar()
	_comprobar(recibido.size() == 1 and String((recibido[0] as Dictionary).get("estilo", "")) == "suave" and EstiloMundo.suave, "la pantalla devuelve el estilo y lo deja guardado")
	p.free()
	## El reposo del Mundo clásico: congela los shaders con TIME en un uniforme (sin salto) y cualquier toque lo devuelve.
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment(){ COLOR = vec4(sin(TIME), 0.0, 0.0, 1.0); }"
	var q := AhorroMenu._quieto_en(sh)
	_comprobar(q != null and not q.code.contains("TIME") and q.code.contains("uniform float _t_quieto;"), "el shader congelado lee un uniforme en vez de TIME")
	EstiloMundo.suave = false
	var am := AhorroMenu.new()
	add_child(am)
	var cr := ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = sh
	cr.material = mat
	add_child(cr)
	am._poner(true)
	_comprobar(OS.low_processor_usage_mode and mat.shader == q, "en reposo: bajo consumo y shader congelado")
	var tecla := InputEventKey.new()
	tecla.pressed = true
	am._input(tecla)
	_comprobar(not OS.low_processor_usage_mode and mat.shader == sh, "una tecla lo devuelve todo al momento")
	cr.free()
	am.free()
	if tenia:
		EstiloMundo.elegir(antes)
	else:
		DirAccess.remove_absolute(EstiloMundo.RUTA)
		EstiloMundo.suave = antes

## (10-11) El edificio del club solo se dibuja con la cámara en el túnel o detrás de la tribuna (picos de llamadas en planos a ras de césped).
func _probar_interior_oculto() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var tunel := Node3D.new()
	raiz.add_child(tunel)
	var ed := Node3D.new()
	ed.name = "EdificioClub"
	tunel.add_child(ed)
	var v := InteriorOculto.vigilar(tunel, 50.0, 70.0)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.make_current()
	var casos := [[Vector3(-30, 2, 25), false, "a ras de césped junto al túnel"], [Vector3(0, 4, 61), false, "repetición tras el arco, sobre la grada"],
		[Vector3(0, 1.7, 55), true, "en el pasillo del túnel"], [Vector3(3, 9, 74), true, "en una planta del edificio"]]
	for c: Array in casos:
		cam.global_position = c[0]
		v._process(0.0)
		_comprobar(ed.visible == c[1], "edificio del club %s: %s" % ["visible" if c[1] else "apagado", c[2]])
	raiz.free()
