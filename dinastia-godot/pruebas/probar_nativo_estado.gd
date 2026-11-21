class_name ProbarNativoEstado
extends RefCounted
## El estado por paso del motor de League en C++ = el de GDScript (16-11-2026, agente C; lo llama `probar_nativo.gd`): `league_estado_base` (ms al balón, más cercano de todos y las 4 líneas del
## penúltimo) frente a `_ms_al_balon` / `_mas_cercano_a_todos_gd` / `_linea_penultimo_gd`, `league_cercanos_equipos` frente a `_mas_cercano_uno_gd`, `league_registrar` frente a
## `LeagueEquipo.registrar_acumular_gd` (secuencias largas, con el recorte de 600), `league_interferir_candidatos` frente a
## `_candidatos_interferir_gd`; byte a byte (`var_to_bytes`). Devuelve {fallos: Array[String], textos: Array[String]}.

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var rr := RandomNumberGenerator.new()
	rr.seed = 1611
	var raiz := Node3D.new()
	var lista: Array = []
	for q in 22:
		var nd := Node3D.new()
		raiz.add_child(nd)
		lista.append({"node": nd, "es_local": q < 11, "id": "j%d" % q, "por": q == 0 or q == 11, "vel": Vector3.ZERO, "enfriar": 0.0})
	var bola_nodo := Node3D.new()
	raiz.add_child(bola_nodo)
	var motor := MotorLeague.new()
	motor.jugadores = lista
	motor.balon = bola_nodo
	_pasada_estado(nat, rr, raiz, lista, bola_nodo, motor, fallos, textos)
	_mas_cercano_equipo(nat, rr, raiz, lista, bola_nodo, motor, fallos, textos)
	_historial(nat, rr, raiz, lista, bola_nodo, motor, fallos, textos)
	_filtro_interferir(nat, rr, raiz, lista, bola_nodo, motor, fallos, textos)
	_varios_cercanos(nat, rr, raiz, lista, bola_nodo, motor, fallos, textos)
	return {"fallos": fallos, "textos": textos}


## 1. La pasada de estado: ms al balón, el más cercano de todos y las 4 líneas.
static func _pasada_estado(nat: Object, rr: RandomNumberGenerator, raiz: Node3D, lista: Array, bola_nodo: Node3D, motor: MotorLeague, fallos: Array[String], textos: Array[String]) -> void:
	var dis := 0
	var t_gd := 0
	var t_c := 0
	var n1 := 2500
	for caso in n1:
		var todos_locales := caso % 17 == 0   ## un equipo vacío: 5000 ms
		for q in 22:
			(lista[q]["node"] as Node3D).position = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52)) if caso % 9 != 0 else Vector3(float(q % 3), 0, 1.0)
			lista[q]["vel"] = Vector3(rr.randf_range(-8, 8), 0, rr.randf_range(-8, 8))
			lista[q]["es_local"] = true if todos_locales else q < 11
		var b := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
		bola_nodo.position = Vector3(b.y, 0, b.x)
		var l0 := 1.0 if caso % 2 == 0 else -1.0
		var l1 := -l0
		var x0 := Time.get_ticks_usec()
		var gd := PackedFloat64Array([motor._ms_al_balon(true), motor._ms_al_balon(false)])
		var sel := motor._mas_cercano_a_todos_gd(b)
		gd.append(float(lista.find(sel)) if not sel.is_empty() else -1.0)
		gd.append(motor._linea_penultimo_gd(true, false, l0, b.x))
		gd.append(motor._linea_penultimo_gd(false, false, l1, b.x))
		gd.append(motor._linea_penultimo_gd(false, true, -l0, b.x))
		gd.append(motor._linea_penultimo_gd(true, true, -l1, b.x))
		var x1 := Time.get_ticks_usec()
		var cc: PackedFloat64Array = nat.league_estado_base(lista, b, l0, l1)
		var x2 := Time.get_ticks_usec()
		t_gd += x1 - x0
		t_c += x2 - x1
		if var_to_bytes(gd) != var_to_bytes(cc):
			dis += 1
	if dis > 0:
		fallos.append("pasada de estado distinta en %d de %d casos" % [dis, n1])
	textos.append("pasada de estado (ms al balón x2 + más cercano + 4 líneas): GDScript %.1f µs, C++ %.1f µs por conjunto" % [t_gd / float(n1), t_c / float(n1)])


## 2. El más cercano de cada equipo (a la vez).
static func _mas_cercano_equipo(nat: Object, rr: RandomNumberGenerator, raiz: Node3D, lista: Array, bola_nodo: Node3D, motor: MotorLeague, fallos: Array[String], textos: Array[String]) -> void:
	var n1 := 2500
	var dis := 0
	var t_gd := 0
	var t_c := 0
	for caso in n1:
		for q in 22:
			(lista[q]["node"] as Node3D).position = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52)) if caso % 9 != 0 else Vector3(float(q % 3), 0, 1.0)
			lista[q]["es_local"] = q < 11
		var pt := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
		var y0 := Time.get_ticks_usec()
		var a := motor._mas_cercano_uno_gd(pt, true, [])
		var c := motor._mas_cercano_uno_gd(pt, false, [])
		var y1 := Time.get_ticks_usec()
		var k: PackedInt32Array = nat.league_cercanos_equipos(lista, pt)
		var y2 := Time.get_ticks_usec()
		t_gd += y1 - y0
		t_c += y2 - y1
		if (lista[k[0]] if k[0] >= 0 else {}) != (a[0] if not a.is_empty() else {}) or (lista[k[1]] if k[1] >= 0 else {}) != (c[0] if not c.is_empty() else {}):
			dis += 1
	if dis > 0:
		fallos.append("más cercano de cada equipo distinto en %d de %d casos" % [dis, n1])
	textos.append("más cercano de cada equipo: GDScript %.1f µs, C++ %.1f µs por par" % [t_gd / float(n1), t_c / float(n1)])


## 3. El historial: secuencias largas (pasan de 600 entradas, con saltos de dt de 0 a 0,1 s).
static func _historial(nat: Object, rr: RandomNumberGenerator, raiz: Node3D, lista: Array, bola_nodo: Node3D, motor: MotorLeague, fallos: Array[String], textos: Array[String]) -> void:
	var dis := 0
	var t_gd := 0
	var t_c := 0
	var pasos := 0
	for serie in 20:
		var ea := LeagueEquipo.new(1.0)
		var eb := LeagueEquipo.new(1.0)
		for paso in 400:
			var dt := rr.randf_range(0.0, 0.1) if paso % 5 != 0 else 1.0 / 30.0
			var bal := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34))
			var lp := rr.randf_range(-1, 1) if paso % 4 != 0 else 0.0
			var z0 := Time.get_ticks_usec()
			var ma := ea.registrar_acumular_gd(bal, lp, dt)
			var z1 := Time.get_ticks_usec()
			var mb := eb.registrar_acumular(bal, lp, dt)
			var z2 := Time.get_ticks_usec()
			t_gd += z1 - z0
			t_c += z2 - z1
			pasos += 1
			if var_to_bytes([ea.balon_hist, ea.lado_hist, ea._resto, ea.acum, ma]) != var_to_bytes([eb.balon_hist, eb.lado_hist, eb._resto, eb.acum, mb]):
				dis += 1
	if dis > 0:
		fallos.append("historial (registrar + acumular + media) distinto en %d de %d pasos" % [dis, pasos])
	textos.append("historial (registrar + acumular + media_f): GDScript %.1f µs, C++ %.1f µs por paso" % [t_gd / float(pasos), t_c / float(pasos)])


## 4. El filtro de `_interferir`.
static func _filtro_interferir(nat: Object, rr: RandomNumberGenerator, raiz: Node3D, lista: Array, bola_nodo: Node3D, motor: MotorLeague, fallos: Array[String], textos: Array[String]) -> void:
	var n1 := 2500
	var dis := 0
	var t_gd := 0
	var t_c := 0
	var con_cand := 0
	for caso in n1:
		for q in 22:
			(lista[q]["node"] as Node3D).position = Vector3(rr.randf_range(-8, 8), 0, rr.randf_range(-8, 8))
			lista[q]["es_local"] = q < 11
			lista[q]["por"] = q == 0 or q == 11
			lista[q]["enfriar"] = 0.0 if caso % 3 != 0 or q % 4 != 0 else 0.5
			if q % 5 == 0:
				lista[q]["gesto_hasta"] = rr.randf_range(0.0, 20.0)
			else:
				lista[q].erase("gesto_hasta")
		motor.t = rr.randf_range(0.0, 20.0)
		motor.autopiloto = caso % 4 == 0
		motor.usuario = lista[rr.randi_range(0, 21)] if caso % 5 != 0 else {}
		var rival_d: Dictionary = lista[rr.randi_range(0, 21)]
		var bola := Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))
		var v0 := Time.get_ticks_usec()
		var cg := motor._candidatos_interferir_gd(rival_d, bola)
		var v1 := Time.get_ticks_usec()
		var cn: PackedInt32Array = nat.league_interferir_candidatos(lista, bool(rival_d["es_local"]), "" if motor.usuario.is_empty() or motor.autopiloto else String(motor.usuario["id"]), motor.t, bola)
		var v2 := Time.get_ticks_usec()
		t_gd += v1 - v0
		t_c += v2 - v1
		if not cg.is_empty():
			con_cand += 1
		if var_to_bytes(cg) != var_to_bytes(cn):
			dis += 1
		## `_cortar_pase`: mismo filtro con `ls_cortar_hasta` (la orden de cortar vigente).
		for q in 22:
			if q % 3 == 0:
				lista[q]["ls_cortar_hasta"] = rr.randf_range(0.0, 20.0)
			else:
				lista[q].erase("ls_cortar_hasta")
		var lp: bool = bool(rival_d["es_local"])
		var kg := motor._candidatos_cortar_gd(lp, bola)
		var kn: PackedInt32Array = nat.league_cortar_candidatos(lista, lp, "" if motor.usuario.is_empty() or motor.autopiloto else String(motor.usuario["id"]), motor.t, bola)
		if var_to_bytes(kg) != var_to_bytes(kn):
			dis += 1
	if dis > 0:
		fallos.append("candidatos de `_interferir` distintos en %d de %d casos" % [dis, n1])
	if con_cand < n1 / 4:
		fallos.append("la prueba de candidatos casi nunca da alguno (%d de %d): no prueba nada" % [con_cand, n1])
	textos.append("candidatos de _interferir (%d con alguno de %d): GDScript %.1f µs, C++ %.1f µs por llamada" % [con_cand, n1, t_gd / float(n1), t_c / float(n1)])


## 5. Los varios más cercanos (con y sin excluidos; muchos empates exactos).
static func _varios_cercanos(nat: Object, rr: RandomNumberGenerator, raiz: Node3D, lista: Array, bola_nodo: Node3D, motor: MotorLeague, fallos: Array[String], textos: Array[String]) -> void:
	var dis := 0
	var t_gd := 0
	var t_c := 0
	var n5 := 3000
	for caso in n5:
		for q in 22:
			(lista[q]["node"] as Node3D).position = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52)) if caso % 4 != 0 else Vector3(float(q % 3), 0, 1.0)
			lista[q]["es_local"] = q < 11 or caso % 7 == 0   ## cada 7: los 22 de un equipo (más de 16: vuelve a GDScript)
		var pt5 := Vector2(rr.randf_range(-52, 52), rr.randf_range(-34, 34)) if caso % 4 != 0 else Vector2(1, 0)
		var loc5 := caso % 2 == 0
		var cu: int = [1, 3, 4, 5, 20][caso % 5]
		var excl: Array = []
		if caso % 3 == 0:
			excl.append(lista[rr.randi_range(0, 21)])
		var u0 := Time.get_ticks_usec()
		var rg5 := motor._mas_cercano_varios_gd(pt5, loc5, excl, cu)
		var u1 := Time.get_ticks_usec()
		var rc5 := motor._mas_cercano_al(pt5, loc5, excl, cu)
		var u2 := Time.get_ticks_usec()
		t_gd += u1 - u0
		t_c += u2 - u1
		var igual := rg5.size() == rc5.size()
		if igual:
			for k in rg5.size():
				igual = igual and is_same(rg5[k], rc5[k])
		if not igual:
			dis += 1
	if dis > 0:
		fallos.append("varios más cercanos distintos en %d de %d casos" % [dis, n5])
	textos.append("varios más cercanos (1, 3, 4, 5 o 20; con empates y excluidos): GDScript %.1f µs, C++ %.1f µs por llamada" % [t_gd / float(n5), t_c / float(n5)])
	motor.free()
	raiz.free()
