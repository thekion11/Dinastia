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
	return {"fallos": fallos, "textos": textos}
