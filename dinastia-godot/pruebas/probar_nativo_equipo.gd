class_name ProbarNativoEquipo
extends RefCounted
## La colocación y el historial de League en C++ = los de GDScript (16-11-2026, paso a C++; lo llama `probar_nativo.gd`): `league_posicion_formacion` frente a
## `LeagueNucleo.posicion_formacion` (5000 entradas al azar: los 13 puestos, los dos lados, tácticas vivas distintas, trampa, ofensividad), `league_acumular` frente a
## `LeagueEquipo.acumular_gd` y `league_media_f` frente a `media_f_gd`, byte a byte. Devuelve {fallos: Array[String], textos: Array[String]}.

const PUESTOS := ["POR", "DFC", "LD", "LI", "MCD", "CAD", "CAI", "MC", "MD", "MI", "MCO", "MP", "ED", "EI", "SD", "DC", "XX"]

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var rr := RandomNumberGenerator.new()
	rr.seed = 1612
	## 1. posicion_formacion.
	var n := 5000
	var distintos := 0
	var tg := 0
	var tc := 0
	for caso in n:
		var viva := LeagueNucleo.TACTICA_BASE.duplicate()
		if caso % 3 != 0:
			for k: String in viva:
				viva[k] = clampf(float(viva[k]) + rr.randf_range(-0.5, 0.5), 0.0, 1.0)
		var puesto: String = PUESTOS[caso % PUESTOS.size()]
		var lado := 1.0 if caso % 2 == 0 else -1.0
		var contra := rr.randf()
		var e := {"forma": Vector2(rr.randf_range(-1, 1), rr.randf_range(-1, 1)), "puesto": puesto, "lado": lado, "pos": Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)),
			"foco": Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)), "balon_x_lento": rr.randf_range(-52, 52), "balon_y_lento": rr.randf_range(-34, 34),
			"balon_3s": Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)), "balon_2s": Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)),
			"posesion_desvanecida": rr.randf_range(0.5, 1.5), "lado_posesion_medio": rr.randf_range(-1, 1), "ofensividad": rr.randf(),
			"viva": viva, "contra": contra, "mezcla": LeagueNucleo.mezclas(viva, puesto, contra), "trampa_x": rr.randf_range(-52, 52) if caso % 4 == 0 else 52.5 * -lado}
		var t0 := Time.get_ticks_usec()
		var a := LeagueNucleo.posicion_formacion(e)
		var t1 := Time.get_ticks_usec()
		var b: Vector2 = nat.league_posicion_formacion(e)
		var t2 := Time.get_ticks_usec()
		tg += t1 - t0
		tc += t2 - t1
		if var_to_bytes(a) != var_to_bytes(b):
			distintos += 1
	if distintos > 0:
		fallos.append("posicion_formacion distinta en %d de %d casos" % [distintos, n])
	textos.append("posición de formación: GDScript %.1f µs, C++ %.1f µs por llamada" % [tg / float(n), tc / float(n)])
	## 2. acumular y media_f (historiales de 0 a 700 entradas: vacío, corto, lleno, desbordado).
	var dis_a := 0
	var dis_m := 0
	var ta := [0, 0]
	var tm := [0, 0]
	var m := 300
	for caso in m:
		var e := LeagueEquipo.new(1.0)
		var largo: int = [0, 1, 5, 100, 599, 600, 700][caso % 7]
		for i in largo:
			e.balon_hist.append(Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)))
			e.lado_hist.append(rr.randf_range(-1, 1))
		var u0 := Time.get_ticks_usec()
		e.acumular_gd()
		var u1 := Time.get_ticks_usec()
		var acum_gd := e.acum.duplicate()
		var acum_c: PackedVector2Array = nat.league_acumular(e.balon_hist)
		var u2 := Time.get_ticks_usec()
		ta[0] += u1 - u0
		ta[1] += u2 - u1
		if var_to_bytes(acum_gd) != var_to_bytes(acum_c):
			dis_a += 1
		for ms: float in [0.0, 5.0, 100.0, 6000.0, 99999.0]:
			var v0 := Time.get_ticks_usec()
			var ga := LeagueEquipo.media_f_gd(e.lado_hist, ms)
			var v1 := Time.get_ticks_usec()
			var gc: float = nat.league_media_f(e.lado_hist, ms)
			var v2 := Time.get_ticks_usec()
			tm[0] += v1 - v0
			tm[1] += v2 - v1
			if var_to_bytes(ga) != var_to_bytes(gc):
				dis_m += 1
	if dis_a > 0:
		fallos.append("acumular distinto en %d de %d historiales" % [dis_a, m])
	if dis_m > 0:
		fallos.append("media_f distinta en %d de %d consultas" % [dis_m, m * 5])
	textos.append("historial del balón: acumular GDScript %.1f µs, C++ %.1f µs; media_f GDScript %.1f µs, C++ %.1f µs por llamada" % [ta[0] / float(m), ta[1] / float(m), tm[0] / float(m * 5), tm[1] / float(m * 5)])
	## 3. El apoyo ofensivo y su campo de fuerzas.
	var dis_c := 0
	var dis_p := 0
	var tc2 := [0, 0]
	var tp2 := [0, 0]
	var k := 3000
	for caso in k:
		var rnd_v := func() -> Vector2: return Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
		var campo: Array = []
		for _i in rr.randi_range(0, 14):
			campo.append([rnd_v.call(), rr.randf() < 0.5, rr.randf() < 0.3, rr.randf_range(0.1, 2.0), rr.randf_range(1.0, 30.0), [1.0, 0.5, 0.7, 2.0][rr.randi() % 4]])
		var actual: Vector2 = rnd_v.call()
		if caso % 17 == 0 and not campo.is_empty():
			actual = campo[0][0]   ## distancia 0 al primer origen
		var amort: float = [1.0, 7.0][caso % 2]
		var a0 := Time.get_ticks_usec()
		var mg := LeagueNucleo.movimiento_campo_gd(campo, actual, amort)
		var a1 := Time.get_ticks_usec()
		var mc: Vector2 = nat.league_movimiento_campo(campo, actual, amort)
		var a2 := Time.get_ticks_usec()
		tc2[0] += a1 - a0
		tc2[1] += a2 - a1
		if var_to_bytes(mg) != var_to_bytes(mc):
			dis_c += 1
		var principal: Vector2 = rnd_v.call()
		var rivales: Array = []
		for _i in rr.randi_range(0, 3):
			rivales.append([principal if rr.randf() < 0.1 else rnd_v.call(), Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))])
		var mates: Array = []
		for _i in rr.randi_range(0, 5):
			mates.append([rnd_v.call(), Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))])
		var e := {"base": rnd_v.call(), "pos": rnd_v.call(), "mov": Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8)), "lado": 1.0 if caso % 2 == 0 else -1.0, "mente": [0.0, 0.25, 0.5, 0.75, 1.0][caso % 5],
			"puesto": PUESTOS[caso % PUESTOS.size()], "correr": caso % 3 == 0, "adelantado": caso % 4 == 0, "principal": principal, "es_principal": caso % 6 == 0, "rivales": rivales, "companeros": mates,
			"posesion_desv": rr.randf_range(0.8, 1.3), "balon_pred": [rnd_v.call(), rnd_v.call(), rnd_v.call(), rnd_v.call()], "linea_offside": rr.randf_range(-52, 52), "red": rr.randf_range(0.68, 0.88)}
		var b0 := Time.get_ticks_usec()
		var pg := LeagueSinBalon.apoyo_gd(e)
		var b1 := Time.get_ticks_usec()
		var pc: Vector2 = nat.league_apoyo(e)
		var b2 := Time.get_ticks_usec()
		tp2[0] += b1 - b0
		tp2[1] += b2 - b1
		if var_to_bytes(pg) != var_to_bytes(pc):
			dis_p += 1
	if dis_c > 0:
		fallos.append("movimiento_campo distinto en %d de %d campos" % [dis_c, k])
	if dis_p > 0:
		fallos.append("apoyo distinto en %d de %d casos" % [dis_p, k])
	textos.append("campo de fuerzas: GDScript %.1f µs, C++ %.1f µs; apoyo ofensivo: GDScript %.1f µs, C++ %.1f µs por llamada" % [tc2[0] / float(k), tc2[1] / float(k), tp2[0] / float(k), tp2[1] / float(k)])
	## 3b. `_destino_forma` entero (urgencia, medias del historial y colocación) con dos equipos y un historial real.
	var dis_d := 0
	var td := [0, 0]
	var dd := 1500
	var eq0 := LeagueEquipo.new(1.0)
	var eq1 := LeagueEquipo.new(-1.0)
	for caso in dd:
		if caso % 250 == 0:
			eq0.balon_hist.clear()
			eq0.lado_hist.clear()
		for _i in rr.randi_range(0, 120):
			eq0.balon_hist.append(Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)))
		eq0.acumular_gd()
		for q: LeagueEquipo in [eq0, eq1]:
			q.posesion_desvanecida = rr.randf_range(0.5, 1.5)
			q.trampa_x = rr.randf_range(-52, 52)
			q.contra = rr.randf()
			if caso % 5 == 0:
				q.viva = LeagueNucleo.tactica_viva({"od": rr.randf(), "ow": rr.randf(), "om": rr.randf(), "os": rr.randf()})
		var eq: LeagueEquipo = eq0 if caso % 2 == 0 else eq1
		var foco2 := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
		var yo2 := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)) if caso % 7 != 0 else foco2
		var forma2 := Vector2(rr.randf_range(-1, 1), rr.randf_range(-1, 1))
		var pst: String = PUESTOS[caso % PUESTOS.size()]
		var ofe := rr.randf()
		var lm := rr.randf_range(-1, 1)
		var x0 := Time.get_ticks_usec()
		var rg2 := LeagueEquipo.destino_forma_gd(eq0, eq, foco2, yo2, forma2, pst, ofe, lm)
		var x1 := Time.get_ticks_usec()
		var rc2: Vector2 = nat.league_destino_forma(eq0.acum, foco2, yo2, forma2, pst, eq.lado, eq.posesion_desvanecida, ofe, lm, eq.trampa_x, eq.mezcla_de(pst))
		var x2 := Time.get_ticks_usec()
		td[0] += x1 - x0
		td[1] += x2 - x1
		if var_to_bytes(rg2) != var_to_bytes(rc2):
			dis_d += 1
	if dis_d > 0:
		fallos.append("destino de formación distinto en %d de %d casos" % [dis_d, dd])
	textos.append("destino de formación entero: GDScript %.1f µs, C++ %.1f µs por llamada" % [td[0] / float(dd), td[1] / float(dd)])
	## 4. El más cercano a un punto (con nodos de verdad, dos equipos, empates exactos incluidos).
	var raiz := Node3D.new()
	var lista: Array = []
	for q in 22:
		var nd := Node3D.new()
		raiz.add_child(nd)
		lista.append({"node": nd, "es_local": q < 11, "id": "j%d" % q})
	var motor := MotorLeague.new()
	motor.jugadores = lista
	var dis_m2 := 0
	var tm2 := [0, 0]
	var z := 2000
	for caso in z:
		for q in 22:
			(lista[q]["node"] as Node3D).position = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52)) if caso % 9 != 0 else Vector3(float(q % 3), 0, 1.0)   ## cada 9: muchos en el mismo punto
		var punto := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
		var loc := caso % 2 == 0
		var w0 := Time.get_ticks_usec()
		var rg := motor._mas_cercano_uno_gd(punto, loc, [])
		var w1 := Time.get_ticks_usec()
		var rc: Array = motor._mas_cercano_al(punto, loc, [], 1)
		var w2 := Time.get_ticks_usec()
		tm2[0] += w1 - w0
		tm2[1] += w2 - w1
		if rg.size() != rc.size() or (rg.size() == 1 and rg[0] != rc[0]):
			dis_m2 += 1
	## 6. Las animaciones que tocan el balón (catálogo real de League): todos los tipos, velocidades de todas las clases, balones previstos de verdad.
	var dis_7 := 0
	var t7 := [0, 0]
	var vacios := 0
	var w := 1500
	var cfg7 := LeagueNucleo.config_balon()
	for caso in w:
		var tipo: String = ["interfere", "sliding", "pass", "highpass", "shot", "trap", "ballcontrol", "deflect"][caso % 8]
		var bp7 := Vector3(rr.randf_range(-3, 3), rr.randf_range(0.11, 1.5) if caso % 3 == 0 else 0.11, rr.randf_range(-3, 3))
		var bv7 := Vector3(rr.randf_range(-12, 12), rr.randf_range(0, 5) if caso % 3 == 0 else 0.0, rr.randf_range(-12, 12))
		var pred7 := MotorLeague.prediccion_gd(bp7, bv7, cfg7, caso % 11 == 0, Vector3(1, 0, 1), 70)
		var yo7 := Vector2(rr.randf_range(-3, 3), rr.randf_range(-3, 3))
		var mir7 := Vector2(rr.randf_range(-1, 1), rr.randf_range(-1, 1)) if caso % 13 != 0 else Vector2.ZERO
		var vel7 := rr.randf_range(0.0, 9.0)
		var c0 := Time.get_ticks_usec()
		var ag := LeagueToques.alcanza_gd(tipo, yo7, mir7, vel7, pred7)
		var c1 := Time.get_ticks_usec()
		var ac := LeagueToques.alcanza(tipo, yo7, mir7, vel7, pred7)
		var c2 := Time.get_ticks_usec()
		t7[0] += c1 - c0
		t7[1] += c2 - c1
		if ag.is_empty():
			vacios += 1
		if var_to_bytes(ag) != var_to_bytes(ac):
			dis_7 += 1
	if dis_7 > 0:
		fallos.append("alcance de animaciones distinto en %d de %d casos" % [dis_7, w])
	if vacios > w - 50:
		fallos.append("la prueba de alcance casi nunca toca el balón (%d de %d vacíos): no prueba nada" % [vacios, w])
	textos.append("alcance de animaciones (%d con toque de %d): GDScript %.1f µs, C++ %.1f µs por llamada" % [w - vacios, w, t7[0] / float(w), t7[1] / float(w)])
	## 5. El índice por id, el más cercano de todos (por la raíz) y la línea del penúltimo (con y sin velocidad).
	var dis_6 := 0
	var t6 := [0, 0]
	var y := 1500
	var motor2 := MotorLeague.new()
	motor2.jugadores = lista
	for caso in y:
		for q in 22:
			(lista[q]["node"] as Node3D).position = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52)) if caso % 9 != 0 else Vector3(float(q % 3), 0, 1.0)
			lista[q]["vel"] = Vector3(rr.randf_range(-8, 8), 0, rr.randf_range(-8, 8))
		var pt := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
		var lg := 1.0 if caso % 2 == 0 else -1.0
		var bxx := rr.randf_range(-52, 52)
		var d_g := {}
		var d_c := {"basura": 1}
		var z0 := Time.get_ticks_usec()
		motor2._indexar_gd(d_g)
		var cg := motor2._mas_cercano_a_todos_gd(pt)
		var l1 := motor2._linea_penultimo_gd(caso % 3 == 0, true, lg, bxx)
		var l2 := motor2._linea_penultimo_gd(caso % 4 == 0, false, lg, bxx)
		var z1 := Time.get_ticks_usec()
		nat.league_indexar(lista, d_c)
		var kk: int = nat.league_mas_cercano_todos(lista, pt)
		var m1: float = nat.league_linea_penultimo(lista, caso % 3 == 0, true, lg, bxx)
		var m2: float = nat.league_linea_penultimo(lista, caso % 4 == 0, false, lg, bxx)
		var z2 := Time.get_ticks_usec()
		t6[0] += z1 - z0
		t6[1] += z2 - z1
		var ok6: bool = d_g.size() == d_c.size() and (lista[kk] if kk >= 0 else {}) == cg and var_to_bytes(l1) == var_to_bytes(m1) and var_to_bytes(l2) == var_to_bytes(m2)
		for id: String in d_g:
			ok6 = ok6 and d_c.has(id) and is_same(d_c[id], d_g[id])
		if not ok6:
			dis_6 += 1
	motor2.free()
	if dis_6 > 0:
		fallos.append("índice, más cercano de todos o línea del penúltimo distintos en %d de %d casos" % [dis_6, y])
	textos.append("índice + más cercano de todos + 2 líneas del penúltimo: GDScript %.1f µs, C++ %.1f µs por conjunto" % [t6[0] / float(y), t6[1] / float(y)])
	for nd2: Dictionary in lista:
		(nd2["node"] as Node3D).free()
	raiz.free()
	motor.free()
	if dis_m2 > 0:
		fallos.append("más cercano distinto en %d de %d consultas" % [dis_m2, z])
	textos.append("más cercano al punto: GDScript %.1f µs, C++ %.1f µs por consulta" % [tm2[0] / float(z), tm2[1] / float(z)])
	return {"fallos": fallos, "textos": textos}
