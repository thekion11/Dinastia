extends Node
## La extensión en C++ (`Nativo`) da los MISMOS bytes que las versiones GDScript a las que
## sustituye, con datos reales: la rampa de las texturas de ruido y el alisado de la ropa de los dos
## cuerpos (30-10-2026). En Linux y Windows la extensión tiene que estar; si falta, es un FALLO.

var _fallos := 0

func _ready() -> void:
	_probar.call_deferred()

func _probar() -> void:
	var nat := Nativo.obj()
	## (5-11) La expectativa es PROPIA del sistema: con binario (Linux, Windows x86_64, Android arm64) tiene que cargar; sin él (Web, macOS, iOS) tiene que
	## estar ausente y el respaldo GDScript es el que manda (lo comprueba pruebas/so/int_nativo_por_sistema).
	var esperada := BaseSO.se_espera_nativo() and OS.get_environment("DINASTIA_SIN_NATIVO") != "1"
	_comprobar((nat != null) == esperada, "la extensión nativa %s (se espera %s en %s)" % ["está cargada" if nat != null else "no está", "sí" if esperada else "no", BaseSO.sistema()])
	if nat == null:
		_fin()
		return
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
	## El once automático (M-469, 3-11): el bucle de puestos de `Club.once` en C++ elige a los mismos, en el mismo orden, que su versión GDScript, en todos los clubes
	## del mundo, con todas las formaciones, y con forma, moral y puestos secundarios al azar (para que cuenten el encaje y los desempates).
	var mundo := Mundo.new()
	mundo.generar([], 777)
	var forms: Dictionary = Datos.tabla("FORMS")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
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
	print("once automático: GDScript %.0f µs, C++ %.0f µs por once" % [t_gd / float(comparados), t_cpp / float(comparados)])
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
					var w4 := Time.get_ticks_usec()
					tc0 += (w1 - w0)
					tg0 += (w3 - w2b)
					jc += 1
					if a1 != b1 or a2 != b2 or s1 != s2:
						jd += 1
	_comprobar(jc > 500 and jd == 0, "goleador/asistente: C++ = GDScript en %d sorteos, con y sin roles (distintos: %d)" % [jc, jd])
	print("goleador: GDScript %.1f µs, C++ %.1f µs por sorteo" % [tg0 / float(jc), tc0 / float(jc)])
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
	motor.free()
	raiz_c.queue_free()
	## (10-11, paso a C++) El partido simulado de la IA entero (90 minutos) en C++: mismo marcador, estadísticas, jugadores y azar que `Partido.simular()`, en cuatro mundos.
	var np := NativoPartido.probar(6)
	for f: String in np["fallos"]:
		_comprobar(false, "partido simulado en C++: " + f)
	_comprobar(np["fallos"].is_empty() and int(np["rapidos"]) > 300, "partido simulado en C++ = GDScript en %d cruces (por la ruta nativa: %d)" % [np["cruces"], np["rapidos"]])
	print("partido simulado completo (%d cruces, %d por la ruta nativa): GDScript %.0f µs, C++ %.0f µs por cruce" % [np["cruces"], np["rapidos"], np["t_gd_us"] / float(np["cruces"]), np["t_cpp_us"] / float(np["cruces"])])
	var med := NativoPartido.probar_medias(400)
	_comprobar(int(med["comparados"]) > 500 and int(med["distintos"]) == 0, "medias por línea de la fuerza: C++ = GDScript en %d onces (distintos: %d)" % [med["comparados"], med["distintos"]])
	print("medias por línea: GDScript %.0f µs, C++ %.0f µs por once" % [med["t_gd_us"] / float(med["comparados"]), med["t_cpp_us"] / float(med["comparados"])])
	## (10-11, paso a C++) La locomoción de League-Soccer: elección de clip, legalidad y bucle de huesos de las intermedias.
	var lg := ProbarNativoLeague.probar(nat)
	for f: String in lg["fallos"]:
		_comprobar(false, "locomoción League en C++: " + f)
	_comprobar((lg["fallos"] as Array).is_empty(), "locomoción League: C++ = GDScript (elección, legalidad, intermedias)")
	for t: String in lg["textos"]:
		print(t)
	_fin()

func _comprobar(ok: bool, que: String) -> void:
	if not ok:
		_fallos += 1
		print("FALLO ", que)

func _fin() -> void:
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()
