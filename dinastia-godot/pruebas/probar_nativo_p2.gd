extends Node
## Capa de `probar_nativo.gd`: las secciones de comprobación de la extensión nativa (una función por bloque) y el contador de fallos.

var _fallos := 0

func _probar_rampa_y_ruido(nat) -> void:
	## La rampa: dos pisos distintos y ruido de verdad.
	for piso: float in [0.78, 0.55]:
		var lut := RuidosFondo._lut(piso)
		var n := FastNoiseLite.new()
		n.seed = 97
		var img := n.get_seamless_image(512, 512, false, false, 0.1, true)
		var t0 := Time.get_ticks_usec()
		var a := RuidosFondo._con_rampa_gd(img, lut).get_data()
		var t1 := Time.get_ticks_usec()
		var b := RuidosFondo._con_rampa(img, lut).get_data()
		var t2 := Time.get_ticks_usec()
		_comprobar(a == b, "rampa (piso %s) igual byte a byte" % piso)
		print("rampa %.2f: GDScript %d ms, C++ %d ms" % [piso, (t1 - t0) / 1000, (t2 - t1) / 1000])

func _probar_relieve_y_hierba(nat) -> void:
	## El relieve de la ciudad (64 baldosas) y la textura de hierba.
	var r := FastNoiseLite.new()
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.seed = 20260912
	r.frequency = 0.00055
	r.fractal_octaves = 4
	r.fractal_lacunarity = 2.1
	var d := FastNoiseLite.new()
	d.noise_type = FastNoiseLite.TYPE_SIMPLEX
	d.seed = 771
	d.frequency = 0.0035
	var u0 := Time.get_ticks_usec()
	var tg := TerrenoArreglos.calcular_gd(r, d)
	var u1 := Time.get_ticks_usec()
	var tn := TerrenoArreglos.calcular(r, d)
	var u2 := Time.get_ticks_usec()
	_comprobar(var_to_bytes(tg) == var_to_bytes(tn), "terreno igual byte a byte (%d baldosas)" % tn.size())
	print("terreno: GDScript %d ms, C++ %d ms" % [(u1 - u0) / 1000, (u2 - u1) / 1000])
	u0 = Time.get_ticks_usec()
	var hg := CityBuilder._imagen_hierba_gd()
	u1 = Time.get_ticks_usec()
	var hn := CityBuilder._imagen_hierba()
	u2 = Time.get_ticks_usec()
	_comprobar(hg.get_data() == hn.get_data(), "hierba igual byte a byte")
	print("hierba: GDScript %d ms, C++ %d ms" % [(u1 - u0) / 1000, (u2 - u1) / 1000])

func _probar_once_y_multimallas(nat) -> void:
	## El once automático (M-469, 3-11): el bucle de puestos de `Club.once` en C++ elige a los mismos, en el mismo orden, que su versión GDScript, en todos los clubes
	## del mundo, con todas las formaciones, y con forma, moral y puestos secundarios al azar (para que cuenten el encaje y los desempates).
	var mundo := Mundo.new()
	mundo.generar([], 777)
	var forms: Dictionary = Datos.tabla("FORMS")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var s1 := _once_s1(nat, mundo, forms, rng)
	_once_s2(nat, mundo, forms, rng)
	print("once automático: GDScript %.0f µs, C++ %.0f µs por once" % [s1[1] / float(s1[0]), s1[2] / float(s1[0])])
	_once_alisado(nat)
	_once_multimallas(nat)
	_once_goleador(nat, mundo)

func _probar_choques_y_movimiento(nat) -> void:
	## (10-11, paso a C++) Los choques entre cuerpos del motor jugable: posiciones y velocidades iguales byte a byte tras muchas rondas, con jugadores amontonados (incluidos dos en el mismo punto).
	var motor := MotorJugable.new()
	var rr := RandomNumberGenerator.new()
	rr.seed = 11
	var raiz_c := Node3D.new()
	add_child(raiz_c)
	var grupos_c: Array = [[], []]
	for g in 2:
		for q in 22:
			var nd := Node3D.new()
			raiz_c.add_child(nd)
			grupos_c[g].append({"node": nd, "vel": Vector3.ZERO, "fuerza": 0.4 + 0.5 * float(q % 5) / 4.0, "aguante": 0.5 + float(q % 3) / 4.0})
	var cuerpos_dis := 0
	var tc1 := 0
	var tg1 := 0
	for ronda in 40:
		for q in 22:
			var px := rr.randf_range(-3.0, 3.0)
			var pz := rr.randf_range(-3.0, 3.0)
			var vel := Vector3(rr.randf_range(-6, 6), 0, rr.randf_range(-6, 6))
			if q == 5 or q == 6:   ## dos en el mismo punto: la normal sale del giro fijo
				px = 1.0
				pz = 1.0
			for g in 2:
				(grupos_c[g][q]["node"] as Node3D).position = Vector3(px, 0, pz)
				grupos_c[g][q]["vel"] = vel
		motor.jugadores = grupos_c[0]
		var k0 := Time.get_ticks_usec()
		motor._cuerpos_gd()
		var k1 := Time.get_ticks_usec()
		nat.cuerpos_motor(grupos_c[1], Balance.RADIO_CUERPO * 2.0)
		var k2 := Time.get_ticks_usec()
		tg1 += k1 - k0
		tc1 += k2 - k1
		for q in 22:
			if (grupos_c[0][q]["node"] as Node3D).position != (grupos_c[1][q]["node"] as Node3D).position or var_to_bytes(grupos_c[0][q]["vel"]) != var_to_bytes(grupos_c[1][q]["vel"]):
				cuerpos_dis += 1
	_comprobar(cuerpos_dis == 0, "choques de cuerpos del motor: C++ = GDScript (40 rondas de 44 jugadores; distintos: %d)" % cuerpos_dis)
	print("cuerpos: GDScript %.1f µs, C++ %.1f µs por ronda" % [tg1 / 40.0, tc1 / 40.0])

	## (15-11, paso a C++) El movimiento de los 22 (`_mover_fisica_gd` frente a `mover_jugadores_fisica`): posición, rumbo, velocidad, empujón y aguante iguales byte a byte tras 120 pasos.
	var raiz_m := Node3D.new()
	add_child(raiz_m)
	var gm: Array = [[], []]
	for g in 2:
		for q in 22:
			var nm := Node3D.new()
			raiz_m.add_child(nm)
			gm[g].append({"node": nm, "id": "j%d" % q, "vel": Vector3.ZERO, "objetivo": Vector3.ZERO, "attr": {"rit": 0.4 + 0.5 * float(q % 5) / 4.0, "fis": 0.5 + float(q % 3) / 4.0},
				"aguante": 0.7, "correr": q % 2 == 0, "por": q == 0 or q == 11, "es_local": q < 11, "jockey": q % 7 == 3})
	var mov_dis := 0
	var tmg := 0
	var tmc := 0
	motor.t = 0.0
	for paso in 120:
		var bp := Vector3(rr.randf_range(-30, 30), 0, rr.randf_range(-45, 45))
		if paso % 10 == 0:
			for q in 22:
				var obj := Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52))
				var fr := rr.randf_range(0.5, 1.0)
				var eo := Vector3(rr.randf_range(-3, 3), 0, 0)
				for g in 2:
					gm[g][q]["objetivo"] = obj
					gm[g][q]["freno"] = fr
					if q % 6 == 2:
						gm[g][q]["empujon_obj"] = eo
						gm[g][q]["giro_firme"] = true
					if q % 9 == 4:
						gm[g][q]["mirar_hasta"] = motor.t + 0.5
						gm[g][q]["mirar"] = float(q)
		var posq := paso % 22
		motor.jugadores = gm[0]
		motor.poseedor = gm[0][posq]
		var m0 := Time.get_ticks_usec()
		var res_g := motor._mover_fisica_gd(1.0 / 60.0, bp)
		var m1 := Time.get_ticks_usec()
		motor.poseedor = gm[1][posq]
		var res_c: PackedFloat64Array = nat.mover_jugadores_fisica(gm[1], bp, 1.0 / 60.0, motor.t, true, gm[1][posq]["id"], bool(gm[1][posq]["es_local"]), MotorJugable.a_max_v, MotorJugable.ANCHO,
			MotorJugable.LARGO, Balance.GIRO_RAPIDO, PackedFloat64Array([motor._coste_aguante(true), motor._coste_aguante(false)]))
		var m2 := Time.get_ticks_usec()
		tmg += m1 - m0
		tmc += m2 - m1
		if var_to_bytes(res_g) != var_to_bytes(res_c):
			mov_dis += 1
		for q in 22:
			var a0: Dictionary = gm[0][q]
			var a1: Dictionary = gm[1][q]
			var n0: Node3D = a0["node"]
			var n1: Node3D = a1["node"]
			if n0.position != n1.position or n0.rotation != n1.rotation or var_to_bytes(a0["vel"]) != var_to_bytes(a1["vel"]) or var_to_bytes(a0["aguante"]) != var_to_bytes(a1["aguante"]) 					or var_to_bytes(a0.get("sp_antes", 0.0)) != var_to_bytes(a1.get("sp_antes", 0.0)) or a0.get("empujon", Vector3.ZERO) != a1.get("empujon", Vector3.ZERO) 					or a0.get("empujon_obj", Vector3.ZERO) != a1.get("empujon_obj", Vector3.ZERO):
				mov_dis += 1
		motor.t += 1.0 / 60.0
	_comprobar(mov_dis == 0, "movimiento de los 22: C++ = GDScript (120 pasos de 44 jugadores; distintos: %d)" % mov_dis)
	print("movimiento: GDScript %.1f µs, C++ %.1f µs por paso" % [tmg / 120.0, tmc / 120.0])
	raiz_m.queue_free()
	motor.free()
	raiz_c.queue_free()

func _probar_partido_simulado_y_clima(nat) -> void:
	## (10-11, paso a C++) El partido simulado de la IA entero (90 minutos) en C++: mismo marcador, estadísticas, jugadores y azar que `Partido.simular()`, en cuatro mundos.
	## (17-11) El clima del partido: `clima_partido` frente a `Clima.del_partido` + `factor` + `factor_visita`, en todas las parejas de países del globo.
	var globo: Dictionary = Datos.tabla("GLOBO_PAIS")
	var paises: Array = globo.keys() + ["XXX"]
	var cl_dis := 0
	var cl_n := 0
	for a: int in paises.size():
		for s in range(1, 53, 3):
			var pl: String = paises[a]
			var pv: String = paises[(a * 7 + s) % paises.size()]
			var semilla := "c%d" % (a * 31 + s)
			var info := Clima.del_partido(pl, s, 2026 + s % 3, semilla)
			var fv := 1.0 if s % 5 == 0 else Clima.factor_visita(info, pv, pl)
			var cc: Array = nat.clima_partido(pl, pv, s, 2026 + s % 3, semilla, s % 5 == 0, globo)
			cl_n += 1
			if var_to_bytes(info) != var_to_bytes(cc[0]) or var_to_bytes(Clima.factor(info)) != var_to_bytes(cc[1]) or var_to_bytes(fv) != var_to_bytes(cc[2]):
				cl_dis += 1
	_comprobar(cl_dis == 0 and cl_n > 500, "clima del partido: C++ = GDScript en %d casos (distintos: %d)" % [cl_n, cl_dis])
	LeyesPais.comparar = true
	LeyesPais.comparados = 0
	Partido.comparar_fuerza = true
	Partido.fuerza_comparadas = 0
	Partido.fuerza_distintas = 0
	LeyesPais.distintos = 0
	var np := NativoPartido.probar(6)
	LeyesPais.comparar = false
	Partido.comparar_fuerza = false
	print("fuerza de los onces: %d comparadas, %d distintas" % [Partido.fuerza_comparadas, Partido.fuerza_distintas])
	_comprobar(Partido.fuerza_distintas == 0 and Partido.fuerza_comparadas > 100, "fuerza de los onces (fuerza_dos): C++ = GDScript")
	var fz := ProbarNativoFuerza.probar()   ## (17-11) con toda la pizarra y todos los roles, no solo la de por defecto
	_comprobar(int(fz["distintas"]) == 0 and int(fz["comparadas"]) > 200, "fuerza con toda la pizarra y los roles: C++ = GDScript en %d casos de %d variantes (distintas: %d)" % [fz["comparadas"], fz["variantes"], fz["distintas"]])
	print("reglas de la liga sobre el once: %d comparados, %d distintos" % [LeyesPais.comparados, LeyesPais.distintos])
	_comprobar(LeyesPais.distintos == 0 and LeyesPais.comparados > 100, "reglas de la liga sobre el once (_ya_cumple): C++ = GDScript en %d onces (distintos: %d)" % [LeyesPais.comparados, LeyesPais.distintos])
	for f: String in np["fallos"]:
		_comprobar(false, "partido simulado en C++: " + f)
	_comprobar(np["fallos"].is_empty() and int(np["rapidos"]) > 300, "partido simulado en C++ = GDScript en %d cruces (por la ruta nativa: %d)" % [np["cruces"], np["rapidos"]])
	print("partido simulado completo (%d cruces, %d por la ruta nativa): GDScript %.0f µs, C++ %.0f µs por cruce" % [np["cruces"], np["rapidos"], np["t_gd_us"] / float(np["cruces"]), np["t_cpp_us"] / float(np["cruces"])])
	var med := NativoPartido.probar_medias(400)
	_comprobar(int(med["comparados"]) > 500 and int(med["distintos"]) == 0, "medias por línea de la fuerza: C++ = GDScript en %d onces (distintos: %d)" % [med["comparados"], med["distintos"]])
	print("medias por línea: GDScript %.0f µs, C++ %.0f µs por once" % [med["t_gd_us"] / float(med["comparados"]), med["t_cpp_us"] / float(med["comparados"])])
	var nn := NativoPartido.probar_notas(300)
	_comprobar(int(nn["comparados"]) > 200 and int(nn["distintos"]) == 0, "notas finales del partido (_cerrar_notas): C++ = GDScript en %d cruces (distintos: %d)" % [nn["comparados"], nn["distintos"]])
	print("cerrar notas: GDScript %.0f µs, C++ %.0f µs por cruce" % [nn["t_gd_us"] / float(nn["comparados"]), nn["t_cpp_us"] / float(nn["comparados"])])

func _probar_locomocion_balon_y_equipo(nat) -> void:
	## (10-11, paso a C++) La locomoción de League-Soccer: elección de clip, legalidad y bucle de huesos de las intermedias.
	var lg := ProbarNativoLeague.probar(nat)
	for f: String in lg["fallos"]:
		_comprobar(false, "locomoción League en C++: " + f)
	_comprobar((lg["fallos"] as Array).is_empty(), "locomoción League: C++ = GDScript (elección, legalidad, intermedias)")
	for t: String in lg["textos"]:
		print(t)
	## (16-11, paso a C++) El balón del motor de League: predicción de 70 pasos y bucle de pasos de 10 ms.
	var bl := ProbarNativoBalon.probar(nat)
	for f: String in bl["fallos"]:
		_comprobar(false, "balón de League en C++: " + f)
	_comprobar((bl["fallos"] as Array).is_empty(), "balón de League: C++ = GDScript (predicción y pasos, 600 casos)")
	for t: String in bl["textos"]:
		print(t)
	var eq := ProbarNativoEquipo.probar(nat)
	for f: String in eq["fallos"]:
		_comprobar(false, "colocación de League en C++: " + f)
	_comprobar((eq["fallos"] as Array).is_empty(), "colocación e historial de League: C++ = GDScript (5000 posiciones, 300 historiales)")
	for t: String in eq["textos"]:
		print(t)
	var po := ProbarNativoPortador.probar(nat)
	for f: String in po["fallos"]:
		_comprobar(false, "decisión con balón de League en C++: " + f)
	_comprobar((po["fallos"] as Array).is_empty(), "decisión con balón de League (situación, regate, decidir): C++ = GDScript (4000 casos cada una)")
	for t: String in po["textos"]:
		print(t)
	var raiz_gu := Node3D.new()
	add_child(raiz_gu)
	var gu := ProbarNativoGuia.probar(nat, raiz_gu)
	for f: String in gu["fallos"]:
		_comprobar(false, "guía de clips de League en C++: " + f)
	_comprobar((gu["fallos"] as Array).is_empty(), "guía de clips de League: C++ = GDScript (600 pasos de 22 jugadores)")
	for t: String in gu["textos"]:
		print(t)
	var ci := ProbarNativoCiudad.probar(nat, raiz_gu)
	for f: String in ci["fallos"]:
		_comprobar(false, "tráfico de la ciudad en C++: " + f)
	_comprobar((ci["fallos"] as Array).is_empty(), "tráfico de la ciudad: C++ = GDScript (900 pasos de un cruce lleno)")
	for t: String in ci["textos"]:
		print(t)
	var sb := ProbarNativoSinBalon.probar(nat, raiz_gu)
	for f: String in sb["fallos"]:
		_comprobar(false, "colocación sin balón de League en C++: " + f)
	_comprobar((sb["fallos"] as Array).is_empty(), "colocación sin balón de League: C++ = GDScript (3 cruces reales)")
	for t: String in sb["textos"]:
		print(t)
	raiz_gu.queue_free()

func _probar_casos_limite_y_estado(nat) -> void:
	## (16-11, auditoría) Casos límite: historiales cortos, equipos vacíos, NaN/inf, entradas inválidas que no deben cerrar Godot.
	var li := ProbarNativoLimites.probar(nat)
	for f: String in li["fallos"]:
		_comprobar(false, "casos límite de League en C++: " + f)
	_comprobar((li["fallos"] as Array).is_empty(), "casos límite de League: C++ = GDScript y sin cierres")
	for t: String in li["textos"]:
		print(t)
	var es := ProbarNativoEstado.probar(nat)   ## (16-11, agente C) el estado por paso del motor de League
	for f: String in es["fallos"]:
		_comprobar(false, "estado de League en C++: " + f)
	_comprobar((es["fallos"] as Array).is_empty(), "estado por paso de League: C++ = GDScript (pasada de estado, historial y filtro de interferir)")
	for t: String in es["textos"]:
		print(t)
	var nu := ProbarNativoNuevas.probar(nat)   ## (19-11) progreso, La Ruta, jugador del mes, ropa, cara, pelo, espejo, texturas, kit de la cabeza, grada y mapa del DT
	for f: String in nu["fallos"]:
		_comprobar(false, "nuevas en C++: " + f)
	_comprobar((nu["fallos"] as Array).is_empty(), "portes del 19-11 (carrera, ropa, cara, pelo, espejo, texturas, kit, grada, DT): C++ = GDScript (byte a byte)")
	for t: String in nu["textos"]:
		print(t)
	var so := ProbarNativoSonido.probar(nat)   ## (19-11) la síntesis del sonido
	for f: String in so["fallos"]:
		_comprobar(false, "síntesis del sonido en C++: " + f)
	_comprobar((so["fallos"] as Array).is_empty(), "síntesis del sonido: C++ = GDScript (214 sonidos × 4 variantes, byte a byte)")
	for t: String in so["textos"]:
		print(t)
	var pu := ProbarNativoPuras.probar(nat)   ## (20-11, orden 63) las funciones puras del núcleo
	for f: String in pu["fallos"]:
		_comprobar(false, "funciones puras en C++: " + f)
	_comprobar((pu["fallos"] as Array).is_empty(), "funciones puras del núcleo: C++ = GDScript (bytes del resultado)")
	for t: String in pu["textos"]:
		print(t)

func _comprobar(ok: bool, que: String) -> void:
	if not ok:
		_fallos += 1
		print("FALLO ", que)

func _fin() -> void:
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()

## El once automático (M-469): el bucle de puestos de `Club.once` en C++ = GDScript.
func _once_s1(nat, mundo: Mundo, forms: Dictionary, rng: RandomNumberGenerator) -> Array:
	var puestos_sec := ["MC", "DFC", "LD", "LI", "MCO", "ED", "EI", "DC", "MCD"]
	var comparados := 0
	var distintos := 0
	var t_gd := 0
	var t_cpp := 0
	for c: Club in mundo.clubes.values():
		for j: Jugador in c.plantilla:
			j.forma = rng.randi_range(30, 100)
			j.moral = rng.randi_range(30, 100)
			if rng.randf() < 0.35:
				j.pos_sec.append(String(puestos_sec[rng.randi() % puestos_sec.size()]))
		for fk: String in forms:
			var ranuras: Array = (forms[fk] as Dictionary).get("s", [])
			var orden: Array = []
			for i in ranuras.size():
				orden.append(i)
			orden.sort_custom(func(a: int, b: int) -> bool: return PesosPuesto.es_portero(String(ranuras[a][0])) and not PesosPuesto.es_portero(String(ranuras[b][0])))
			var libres: Array = c.disponibles()
			var w0 := Time.get_ticks_usec()
			var ag := OnceAuto.asignar_gd(libres, ranuras, orden)
			var w1 := Time.get_ticks_usec()
			var an := OnceAuto._nativo(nat, libres, ranuras, orden)
			var w2 := Time.get_ticks_usec()
			t_gd += w1 - w0
			t_cpp += w2 - w1
			comparados += 1
			var igual := ag.keys() == an.keys()
			if igual:
				for i: int in ag:
					igual = igual and (ag[i] as Jugador).id == (an[i] as Jugador).id
			if not igual:
				distintos += 1
	_comprobar(comparados > 1000 and distintos == 0, "once automático: C++ = GDScript en %d armados de %d clubes (distintos: %d)" % [comparados, mundo.clubes.size(), distintos])
	return [comparados, t_gd, t_cpp]

## El once automático entero (`once_armar`): mismo once que el camino de GDScript.
func _once_s2(nat, mundo: Mundo, forms: Dictionary, rng: RandomNumberGenerator) -> void:
	## El once automático ENTERO (`once_armar`): mismo once que el camino de GDScript (`_once_auto_gd`), con lesionados y sancionados al azar.
	var armados := 0
	var armados_distintos := 0
	for c: Club in mundo.clubes.values():
		for j: Jugador in c.plantilla:
			j.lesion = 1 if rng.randf() < 0.15 else 0
			j.suspension = 1 if rng.randf() < 0.1 else 0
		for fk: String in forms:
			var ranuras2: Array = (forms[fk] as Dictionary).get("s", [])
			var rap := OnceAuto.armar(c.plantilla, ranuras2, OnceAuto.orden_de(ranuras2))
			if c.disponibles().size() < 7:
				_comprobar(rap.is_empty(), "once armado: con menos de 7 libres devuelve vacío (club %s)" % c.id)
				continue
			var viejo := c._once_auto_gd(ranuras2)
			armados += 1
			var mismo := rap.size() == viejo.size()
			if mismo:
				for i in rap.size():
					mismo = mismo and (rap[i] as Jugador).id == viejo[i].id
			if not mismo:
				armados_distintos += 1
	_comprobar(armados > 1000 and armados_distintos == 0, "once armado entero: C++ = GDScript en %d (distintos: %d)" % [armados, armados_distintos])
	for c: Club in mundo.clubes.values():
		for j: Jugador in c.plantilla:
			j.lesion = 0
			j.suspension = 0

## El alisado, con las mallas reales de los cuerpos.
func _once_alisado(nat) -> void:
	## El alisado, con las mallas reales de los cuerpos.
	for ruta in [FutbolistaQ.MODELO_MALE, FutbolistaQ.MODELO_FEMALE]:
		var raiz: Node = (load(ruta) as PackedScene).instantiate()
		for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
			var am := mi.mesh as ArrayMesh
			if am == null:
				continue
			for s in am.get_surface_count():
				var arr := am.surface_get_arrays(s)
				var pos: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				if pos.size() < 2000:
					continue
				var t0 := Time.get_ticks_usec()
				var a: Array = VestidorQ._alisado_gd(pos, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX])
				var t1 := Time.get_ticks_usec()
				var b: Array = VestidorQ._alisado(pos, arr[Mesh.ARRAY_NORMAL], arr[Mesh.ARRAY_INDEX])
				var t2 := Time.get_ticks_usec()
				var igual := var_to_bytes(a[0]) == var_to_bytes(b[0]) and var_to_bytes(a[1]) == var_to_bytes(b[1])
				_comprobar(igual, "alisado de %s/%s igual byte a byte" % [ruta.get_file(), mi.name])
				print("alisado %s (%d vértices): GDScript %d ms, C++ %d ms" % [mi.name, pos.size(), (t1 - t0) / 1000, (t2 - t1) / 1000])
		raiz.free()

## Los círculos de choque de un MultiMesh: C++ y GDScript, byte a byte.
func _once_multimallas(nat) -> void:
	## (7-11) Los círculos de choque de un MultiMesh: C++ y GDScript, byte a byte, con instancias de todos los tamaños, torcidas, alargadas y algunas dentro de rectángulos sólidos.
	var rg := RandomNumberGenerator.new()
	rg.seed = 5
	var n_i := 6000
	var buf := PackedFloat32Array()
	buf.resize(n_i * 12)
	for i in n_i:
		var tr := Transform3D(Basis.from_euler(Vector3(0.0, rg.randf() * TAU, 0.0)).scaled(Vector3(rg.randf_range(0.05, 9.0), rg.randf_range(0.2, 6.0), rg.randf_range(0.05, 12.0))), Vector3(rg.randf_range(-300, 300), rg.randf_range(0.0, 1.5), rg.randf_range(-300, 300)))
		var fila := [tr.basis.x.x, tr.basis.y.x, tr.basis.z.x, tr.origin.x, tr.basis.x.y, tr.basis.y.y, tr.basis.z.y, tr.origin.y, tr.basis.x.z, tr.basis.y.z, tr.basis.z.z, tr.origin.z]
		for q in 12:
			buf[i * 12 + q] = fila[q]
	var rects: Array[Rect2] = []
	for i in 40:
		rects.append(Rect2(rg.randf_range(-300, 280), rg.randf_range(-300, 280), rg.randf_range(2, 25), rg.randf_range(2, 25)))
	var rej := Optimizar._rejilla(rects)
	var mm_t := MultiMesh.new()
	mm_t.transform_format = MultiMesh.TRANSFORM_3D
	mm_t.mesh = BoxMesh.new()
	mm_t.instance_count = n_i
	var nodo_t := Transform3D(Basis.from_euler(Vector3(0.0, 0.4, 0.0)), Vector3(12.5, 0.25, -7.75))
	var base_aabb := AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)
	var ga := PackedVector3Array()
	var q0 := Time.get_ticks_usec()
	Optimizar.circulos_mm_gd(ga, nodo_t, mm_t, buf, 12, true, base_aabb, 0.25, 0.9, 0.9, rej)
	var q1 := Time.get_ticks_usec()
	var gb: PackedVector3Array = nat.obstaculos_multimalla(nodo_t, buf, 12, n_i, base_aabb, 0.25, 0.9, 0.9, rej, Optimizar.CELDA_REJ)
	var q2 := Time.get_ticks_usec()
	_comprobar(ga.size() > 200 and var_to_bytes(ga) == var_to_bytes(gb), "círculos de un MultiMesh iguales byte a byte (%d círculos de %d instancias)" % [ga.size(), n_i])
	print("obstáculos de MultiMesh: GDScript %d ms, C++ %d ms" % [(q1 - q0) / 1000, (q2 - q1) / 1000])

## El sorteo ponderado del goleador y del asistente: C++ y GDScript eligen a lo mismo.
func _once_goleador(nat, mundo: Mundo) -> void:
	## (10-11, paso a C++) El sorteo ponderado del goleador y del asistente: C++ y GDScript eligen a los MISMOS con la misma semilla de `Azar`, sin roles y con roles asignados.
	var jc := 0
	var jd := 0
	var tg0 := 0
	var tc0 := 0
	var roles_por_grupo := {}
	for rk: String in RolTactico.CATALOGO:
		roles_por_grupo[String(RolTactico.CATALOGO[rk]["grupo"])] = rk
	for conroles in [false, true]:
		for c: Club in mundo.clubes.values():
			var rv: Club = mundo.clubes.values()[(jc * 7 + 3) % mundo.clubes.size()]
			var p := Partido.new(c, rv)
			p.preparar()
			if conroles:
				for j: Jugador in p.once_local:
					p.local.tactica.roles[j.id] = roles_por_grupo.get(Datos.grupo(j.pos_e), "")
			for q in 3:
				for lado in 2:
					var once: Array[Jugador] = p.once_local if lado == 0 else p.once_visita
					if once.is_empty():
						continue
					Azar.sembrar(1000 + jc)
					var w0 := Time.get_ticks_usec()
					var a1 := PartidoPonderado.goleador(p, once)
					var w1 := Time.get_ticks_usec()
					var a2 := PartidoPonderado.asistente(p, once, a1, 10 + q)
					var s1 := Azar.f()
					var w2 := Time.get_ticks_usec()
					Azar.sembrar(1000 + jc)
					var w2b := Time.get_ticks_usec()
					var b1 := PartidoPonderado.goleador_gd(p, once)
					var w3 := Time.get_ticks_usec()
					var b2 := PartidoPonderado.asistente_gd(p, once, b1, 10 + q)
					var s2 := Azar.f()
					tc0 += (w1 - w0)
					tg0 += (w3 - w2b)
					jc += 1
					if a1 != b1 or a2 != b2 or s1 != s2:
						jd += 1
	_comprobar(jc > 500 and jd == 0, "goleador/asistente: C++ = GDScript en %d sorteos, con y sin roles (distintos: %d)" % [jc, jd])
	print("goleador: GDScript %.1f µs, C++ %.1f µs por sorteo" % [tg0 / float(jc), tc0 / float(jc)])

