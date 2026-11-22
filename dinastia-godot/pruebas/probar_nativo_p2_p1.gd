extends Node
## Capa base de `probar_nativo_p2.gd`: el contador de fallos, la comprobación y las pruebas del once.

var _fallos := 0
func _comprobar(ok: bool, que: String) -> void:
	if not ok:
		_fallos += 1
		print("FALLO ", que)

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
