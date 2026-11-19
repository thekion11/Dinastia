class_name ProbarNativoLimites
extends RefCounted
## CASOS LÍMITE del C++ de League (16-11-2026, auditoría; lo llama `probar_nativo.gd`): lo que la prueba aleatoria no cubre. Gemela GDScript contra C++ con `var_to_bytes`:
## historiales de 0/1/2 entradas, jugadores de un solo equipo o sin nodo, NaN/inf, balón en la red, delta 0 o negativo, humedad y viento, campos con escala 0, tácticas con ints,
## puestos como StringName, `balon_pred` empaquetado, empates exactos del catálogo. Además comprueba que las entradas inválidas (nodo liberado, `k` corto, total negativo,
## cuadro negativo) NO cierran Godot. Casos donde GDScript da ERROR (clave que falta en la mezcla o en `cfg`, `id` que no es texto) no se comparan: solo se anotan en el informe.
## Devuelve {fallos: Array[String], textos: Array[String]}.

static func _igual(a: Variant, b: Variant) -> bool:
	return var_to_bytes(a) == var_to_bytes(b)

static func probar(nat: Object) -> Dictionary:
	var f: Array[String] = []
	var n := [0]   ## casos comparados
	_balon(nat, f, n)
	_cercano(nat, f, n)
	_toques(nat, f, n)
	_equipo(nat, f, n)
	_apoyo(nat, f, n)
	_invalidos(nat, f, n)
	return {"fallos": f, "textos": ["casos límite de League: %d comparados gemela contra C++" % n[0]]}

static func _chk(f: Array[String], n: Array, nombre: String, a: Variant, b: Variant) -> void:
	n[0] += 1
	if not _igual(a, b):
		f.append("%s: gd=%s cpp=%s" % [nombre, str(a), str(b)])

static func _balon(nat: Object, f: Array[String], n: Array) -> void:
	var cfg := LeagueNucleo.config_balon()
	var motor := MotorLeague.new()
	var r_loc := MotorJugable.R
	var k := PackedFloat64Array([MotorLeague.PASO_BALON, r_loc, r_loc + 0.02, 0.2, 0.012, Balance.GIRO_AIRE, Balance.GIRO_SUELO, MotorJugable.LARGO, MotorJugable.PALO, MotorJugable.LARGUERO])
	var cfg_int := cfg.duplicate()
	cfg_int["humedad"] = 1       ## ints donde GDScript espera float
	cfg_int["cesped"] = 1
	var cfg_c0 := cfg.duplicate()
	cfg_c0["cesped"] = 0.0
	var cfg_arr := cfg.duplicate()
	cfg_arr["arrastre"] = 5.0    ## frenada negativa
	var cfg_mojado := LeagueNucleo.config_balon(7.0, Vector3(30, 0, -30))   ## humedad fuera de 0..1 y viento fuerte
	var cfgs := {"base": cfg, "int": cfg_int, "cesped0": cfg_c0, "arrastre": cfg_arr, "mojado": cfg_mojado}
	var estados := {
		"reposo": [Vector3(1, r_loc, 1), Vector3.ZERO], "bajo tierra": [Vector3(1, -2.0, 1), Vector3(3, -4.0, 1)], "suelo exacto": [Vector3(1, r_loc, 1), Vector3(3, 0, 1)],
		"aire": [Vector3(1, 3, 1), Vector3(30, 5, 10)], "rebote": [Vector3(1, 0.05, 1), Vector3(3, -9, 1)], "NaN": [Vector3(1, r_loc, 1), Vector3(NAN, 0, 0)],
		"inf": [Vector3(1, r_loc, 1), Vector3(INF, 0, 0)], "enorme": [Vector3(1, r_loc, 1), Vector3(1e30, 1e30, 1e30)], "sobre el cesped": [Vector3(1, r_loc + 0.025, 1), Vector3(5, 0, 5)]}
	for cn: String in cfgs:
		for en: String in estados:
			var p: Vector3 = estados[en][0]
			var v: Vector3 = estados[en][1]
			for total in [0, 1, 70]:
				_chk(f, n, "predicción %s/%s/%d" % [cn, en, total], MotorLeague.prediccion_gd(p, v, cfgs[cn], false, Vector3.ZERO, total), nat.balon_prediccion(p, v, cfgs[cn], false, Vector3.ZERO, total, 0.01, r_loc))
			_chk(f, n, "predicción con portador %s/%s" % [cn, en], MotorLeague.prediccion_gd(p, v, cfgs[cn], true, Vector3(3, 0, -2), 20), nat.balon_prediccion(p, v, cfgs[cn], true, Vector3(3, 0, -2), 20, 0.01, r_loc))
			for delta in [0.0, -0.01, 0.0099999, 0.01, 1.0, 1e-9]:
				motor.cfg_balon = cfgs[cn]
				motor.vel_balon = v
				motor.giro_balon = Vector3(1, 2, 3)
				motor._resto_balon = 0.009999
				var pg := motor._avanzar_balon_gd(p, delta)
				var rc: Array = nat.balon_avanzar(p, v, Vector3(1, 2, 3), 0.009999, delta, cfgs[cn], k)
				_chk(f, n, "pasos %s/%s/delta %s" % [cn, en, delta], [pg, motor.vel_balon, motor.giro_balon, motor._resto_balon], rc)
	## En la red (borde exacto del largo, justo dentro y fuera, los dos lados).
	for pz: float in [MotorJugable.LARGO, MotorJugable.LARGO + 0.0001, -MotorJugable.LARGO - 1.0, MotorJugable.LARGO + 5.0]:
		for px: float in [0.0, MotorJugable.PALO, MotorJugable.PALO + 0.1]:
			motor.cfg_balon = cfg
			motor.vel_balon = Vector3(0.5, 0.0, 9)
			motor.giro_balon = Vector3.ZERO
			motor._resto_balon = 0.0
			var pg2 := motor._avanzar_balon_gd(Vector3(px, 0.5, pz), 0.05)
			_chk(f, n, "red z=%s x=%s" % [pz, px], [pg2, motor.vel_balon, motor.giro_balon, motor._resto_balon], nat.balon_avanzar(Vector3(px, 0.5, pz), Vector3(0.5, 0.0, 9), Vector3.ZERO, 0.0, 0.05, cfg, k))
	motor.free()

static func _lista(cuantos: int, locales: int, rr: RandomNumberGenerator, raiz: Node3D) -> Array:
	var lista: Array = []
	for q in cuantos:
		var nd := Node3D.new()
		raiz.add_child(nd)
		nd.position = Vector3(rr.randf_range(-34, 34), 0, rr.randf_range(-52, 52))
		lista.append({"node": nd, "es_local": q < locales, "id": "j%d" % q, "vel": Vector3(rr.randf_range(-8, 8), 0, rr.randf_range(-8, 8))})
	return lista

static func _cercano(nat: Object, f: Array[String], n: Array) -> void:
	var rr := RandomNumberGenerator.new()
	rr.seed = 1613
	var raiz := Node3D.new()
	var motor := MotorLeague.new()
	## Tamaños: ninguno, uno, dos, y equipos desparejos (todos locales, ninguno local).
	for cuantos in [0, 1, 2, 3, 22]:
		for locales in [0, 1, 2, cuantos]:
			var lista := _lista(cuantos, mini(locales, cuantos), rr, raiz)
			motor.jugadores = lista
			for punto in [Vector2.ZERO, Vector2(1e7, 1e7), Vector2(NAN, 0), Vector2(INF, 0)]:
				for loc in [true, false]:
					var rg := motor._mas_cercano_uno_gd(punto, loc, [])
					var kc: int = nat.league_mas_cercano(lista, punto, loc)
					_chk(f, n, "más cercano %d/%d %s %s" % [cuantos, locales, punto, loc], rg.size(), 0 if kc < 0 else 1)
					if kc >= 0 and rg.size() == 1:
						_chk(f, n, "más cercano (quién) %d/%d" % [cuantos, locales], rg[0]["id"], lista[kc]["id"])
				var tg := motor._mas_cercano_a_todos_gd(punto)
				var kt: int = nat.league_mas_cercano_todos(lista, punto)
				_chk(f, n, "más cercano de todos %d/%d %s" % [cuantos, locales, punto], tg.get("id", ""), lista[kt]["id"] if kt >= 0 else "")
			for lado in [1.0, -1.0, 0.0]:
				for loc in [true, false]:
					for con_vel in [true, false]:
						for bx in [0.0, 60.0, -60.0, 10.0]:
							_chk(f, n, "penúltimo %d/%d lado %s" % [cuantos, locales, lado], motor._linea_penultimo_gd(loc, con_vel, lado, bx), nat.league_linea_penultimo(lista, loc, con_vel, lado, bx))
			var d_g := {}
			var d_c := {"basura": 1}
			motor._indexar_gd(d_g)
			nat.league_indexar(lista, d_c)
			_chk(f, n, "índice %d" % cuantos, d_g.size(), d_c.size())
			for id: String in d_g:
				if not (d_c.has(id) and is_same(d_c[id], d_g[id])):
					f.append("índice: falta %s" % id)
	## Mismas posiciones (empates exactos: gana el primero) y mismas raíces con cuadrados distintos.
	var emp := _lista(6, 3, rr, raiz)
	for q in 6:
		(emp[q]["node"] as Node3D).position = Vector3(1e7 + float(q % 2), 0, 1e7)
	motor.jugadores = emp
	for loc in [true, false]:
		_chk(f, n, "empate exacto", motor._mas_cercano_uno_gd(Vector2(1e7, 1e7), loc, []).map(func(x: Dictionary) -> String: return x["id"]), [] if nat.league_mas_cercano(emp, Vector2(1e7, 1e7), loc) < 0 else [emp[nat.league_mas_cercano(emp, Vector2(1e7, 1e7), loc)]["id"]])
	_chk(f, n, "empate de raíz", motor._mas_cercano_a_todos_gd(Vector2(1e7, 1e7))["id"], emp[nat.league_mas_cercano_todos(emp, Vector2(1e7, 1e7))]["id"])
	## Un id repetido: manda el último, igual que la asignación de GDScript.
	var dup := [{"node": null, "id": "x", "n": 1}, {"node": null, "id": "x", "n": 2}]
	var d1 := {}
	var d2 := {}
	motor.jugadores = dup
	motor._indexar_gd(d1)
	nat.league_indexar(dup, d2)
	_chk(f, n, "índice con id repetido", d1["x"]["n"], d2["x"]["n"])
	motor.free()
	raiz.free()

static func _toques(nat: Object, f: Array[String], n: Array) -> void:
	var guardado: Dictionary = LeagueToques.catalogo().duplicate(true)
	var quieta := PackedVector3Array()
	quieta.resize(71)
	quieta.fill(Vector3(0.0, 0.0, 0.1))   ## balón quieto en (0, 0), a 0,1 m del suelo
	## Catálogo sintético con empates: dos animaciones iguales (gana la primera), el cuadro 0, el último cuadro (70), uno fuera (71), un cuadro decimal y una vecina de otra clase de velocidad.
	var anim := func(nombre: String, cuadro: Variant) -> Dictionary: return {"nombre": nombre, "cuadro": cuadro, "balon": [0.0, 0.0, 0.1]}
	var cats := {
		"pass": {"idle": [anim.call("a", 5), anim.call("b", 5), anim.call("c", 0), anim.call("d", 71), anim.call("e", 70), anim.call("g", 3.9)], "walk": [anim.call("w", 4)], "sprint": [anim.call("s", 1)]},
		"shot": {"idle": [anim.call("solo", 70)]},
		"trap": {"dribble": []}}
	LeagueToques._cat = cats
	for tipo: String in ["pass", "shot", "trap", "nada"]:
		for vel: float in [0.0, 1.79, 1.8, 4.4, 6.2, 9.0, -1.0, NAN, INF]:
			for mir: Vector2 in [Vector2.ZERO, Vector2(1, 0), Vector2(0, -1), Vector2(1e-30, 0), Vector2(NAN, 0)]:
				for pred: PackedVector3Array in [quieta, PackedVector3Array(), quieta.slice(0, 1), quieta.slice(0, 6)]:
					_chk(f, n, "alcanza %s vel %s mir %s pred %d" % [tipo, vel, mir, pred.size()], LeagueToques.alcanza_gd(tipo, Vector2(0.1, 0.1), mir, vel, pred), LeagueToques.alcanza(tipo, Vector2(0.1, 0.1), mir, vel, pred))
	## Que de verdad toque (no todo vacío): la que gana es la primera de las empatadas, «c» (cuadro 0) no llega y «a» sí.
	var r: Dictionary = LeagueToques.alcanza("pass", Vector2(0.0, 0.0), Vector2(1, 0), 0.0, quieta)
	n[0] += 1
	if r.get("anim", "") != "c" and r.get("anim", "") != "a":
		f.append("alcanza sintético: se esperaba 'c' o 'a' y salió %s" % str(r))
	LeagueToques._cat = guardado

static func _equipo(nat: Object, f: Array[String], n: Array) -> void:
	var viva := LeagueNucleo.TACTICA_BASE.duplicate()
	var ceros := {}
	var unos := {}
	var enteros := {}
	for k: String in viva:
		ceros[k] = 0.0
		unos[k] = 1.0
		enteros[k] = 1
	## posicion_formacion con tácticas en los extremos (alto == bajo si ow = dw = 0: 0/0 = NaN en las dos), ints, lado 0, balón enorme, puesto como StringName.
	for mz: Dictionary in [ceros, unos, enteros, viva]:
		for puesto: Variant in ["MC", "DC", "POR", "XX", &"DFC"]:
			for lado in [1.0, -1.0, 0.0]:
				for bx in [0.0, 1e6, -1e6]:
					var e := {"forma": Vector2(0.5, -0.5), "puesto": puesto, "lado": lado, "pos": Vector2.ZERO, "foco": Vector2(10, 5), "balon_x_lento": bx, "balon_y_lento": -bx, "balon_3s": Vector2(3, 1),
						"balon_2s": Vector2(1, 1), "posesion_desvanecida": 0.5, "lado_posesion_medio": 5.0, "ofensividad": 3.0, "viva": viva, "contra": 0.5, "mezcla": mz, "trampa_x": 0.0}
					_chk(f, n, "formación %s %s lado %s bx %s" % [mz.get("od"), puesto, lado, bx], LeagueNucleo.posicion_formacion(e), nat.league_posicion_formacion(e))
					e["balon_3s"] = Vector2(NAN, 1)
					_chk(f, n, "formación con NaN", LeagueNucleo.posicion_formacion(e), nat.league_posicion_formacion(e))
	## Historial: ninguna, una, dos entradas y lleno; `acum` sin rehacer (vacío).
	var e0 := LeagueEquipo.new(1.0)
	var e1 := LeagueEquipo.new(-1.0)
	for largo in [0, 1, 2, 3, 600, 700]:
		e0.balon_hist = PackedVector2Array()
		e0.lado_hist = PackedFloat32Array()
		for i in largo:
			e0.balon_hist.append(Vector2(i, -i))
			e0.lado_hist.append(float(i) / 7.0)
		e0.acum = PackedVector2Array()
		for rehecho in [false, true]:
			if rehecho:
				e0.acumular_gd()
			for pst in ["MC", "DC"]:
				for foco in [Vector2(10, 5), Vector2.ZERO]:
					_chk(f, n, "destino hist %d rehecho %s" % [largo, rehecho], LeagueEquipo.destino_forma_gd(e0, e1, foco, Vector2.ZERO, Vector2(0.5, 0.5), pst, 0.5, 0.0),
						nat.league_destino_forma(e0.acum, foco, Vector2.ZERO, Vector2(0.5, 0.5), pst, e1.lado, e1.posesion_desvanecida, 0.5, 0.0, e1.trampa_x, e1.mezcla_de(pst)))
		e0.acumular_gd()
		_chk(f, n, "acumular %d" % largo, e0.acum, nat.league_acumular(e0.balon_hist))
		for ms: float in [-50.0, 0.0, 9.99, 10.0, 25.0, 1e30]:
			_chk(f, n, "media_f %d ms %s" % [largo, ms], LeagueEquipo.media_f_gd(e0.lado_hist, ms), nat.league_media_f(e0.lado_hist, ms))
	## Campo de fuerzas: vacío, escala 0 o negativa, exponente 0, potencia 0 o negativa, amortiguación 0 o negativa, ints y bools como int, origen NaN, distancia 0.
	_chk(f, n, "campo vacío", LeagueNucleo.movimiento_campo_gd([], Vector2(1, 1), 1.0), nat.league_movimiento_campo([], Vector2(1, 1), 1.0))
	for a: float in [0.0, 1.0, -1.0]:
		for esc: float in [0.0, 1.0, -3.0]:
			for ex: float in [0.0, 1.0, 0.5]:
				for pot: float in [0.0, 1.0, -1.0]:
					for actual: Vector2 in [Vector2(1, 1), Vector2(5, 5)]:
						var campo := [[Vector2(1, 1), false, false, pot, esc, ex], [Vector2(5, 5), true, false, 1, 2, 1], [Vector2(0, 0), false, true, 2, 1, 1]]
						_chk(f, n, "campo a %s esc %s ex %s pot %s" % [a, esc, ex, pot], LeagueNucleo.movimiento_campo_gd(campo, actual, a), nat.league_movimiento_campo(campo, actual, a))
	for campo: Array in [[[Vector2(4, 4), 1, 0, 1, 10, 1]], [[Vector2(NAN, 4), false, false, 1.0, 10.0, 1.0]], [[Vector2(1, 1), false, true, 0.0, 1.0, 1.0]]]:
		_chk(f, n, "campo ints/NaN/potencia 0", LeagueNucleo.movimiento_campo_gd(campo, Vector2(1, 1), 1.0), nat.league_movimiento_campo(campo, Vector2(1, 1), 1.0))

static func _apoyo(nat: Object, f: Array[String], n: Array) -> void:
	var base := {"base": Vector2(10, 5), "pos": Vector2(0, 0), "mov": Vector2(1, 1), "lado": 1.0, "mente": 0.5, "puesto": "MC", "correr": false, "adelantado": false, "principal": Vector2(20, 0), "es_principal": false,
		"rivales": [], "companeros": [], "posesion_desv": 1.1, "balon_pred": [], "linea_offside": 30.0, "red": 0.8}
	_chk(f, n, "apoyo sin rivales ni compañeros", LeagueSinBalon.apoyo_gd(base), nat.league_apoyo(base))
	var variantes := {"mente": [-0.5, 0.0, 1.5, NAN], "lado": [1.0, -1.0, 0.0, 2.0], "posesion_desv": [1.02, 1.06, 1.0199999, 1.0599999, NAN, 0.0], "red": [0.0, -1.0], "puesto": ["DFC", &"MCD", "POR", &"MP", ""],
		"principal": [Vector2(NAN, 0), Vector2(10, 5), Vector2(INF, 0)], "linea_offside": [-60.0, 60.0, 0.0], "correr": [true, false], "adelantado": [true, false], "es_principal": [true, false]}
	for clave: String in variantes:
		for v: Variant in variantes[clave]:
			for extra in [0, 1]:
				var e := base.duplicate()
				e[clave] = v
				if extra == 1:   ## con rivales (uno encima del principal), compañeros y el balón previsto, en Array y en PackedVector2Array
					e["rivales"] = [[Vector2(20, 0), Vector2(0, 0)], [Vector2(21, 1), Vector2(1, 1)], [e["principal"], Vector2.ZERO]]
					e["companeros"] = [[Vector2(3, 3), Vector2(1, 1)]]
					e["balon_pred"] = [Vector2(2, 2), Vector2(3, 3)] if clave != "red" else PackedVector2Array([Vector2(2, 2), Vector2(3, 3)])
					e["posesion_desv"] = 1.2 if clave != "posesion_desv" else v
				_chk(f, n, "apoyo %s=%s extra %d" % [clave, str(v), extra], LeagueSinBalon.apoyo_gd(e), nat.league_apoyo(e))

## Entradas inválidas: GDScript da error o ni existe el caso; lo exigido es que la extensión NO cierre Godot y devuelva algo sensato.
static func _invalidos(nat: Object, f: Array[String], n: Array) -> void:
	var cfg := LeagueNucleo.config_balon()
	n[0] += 1
	var neg: PackedVector3Array = nat.balon_prediccion(Vector3.ZERO, Vector3.ONE, cfg, false, Vector3.ZERO, -1, 0.01, MotorJugable.R)
	if neg.size() != 1:
		f.append("predicción con total -1: se esperaba 1 punto y salieron %d" % neg.size())
	n[0] += 1
	var k_corto: Array = nat.balon_avanzar(Vector3.ZERO, Vector3.ONE, Vector3.ZERO, 0.0, 0.05, cfg, PackedFloat64Array([0.01]))
	if not k_corto.is_empty():
		f.append("balon_avanzar con `k` de 1 valor: se esperaba un Array vacío")
	## Un nodo liberado en `jugadores` se salta (antes: SIGSEGV).
	var a := Node3D.new()
	var b := Node3D.new()
	b.position = Vector3(5, 0, 5)
	var lista := [{"node": a, "es_local": true, "id": "a", "vel": Vector3.ZERO}, {"node": b, "es_local": true, "id": "b", "vel": Vector3.ZERO}, {"node": null, "es_local": true, "id": "n", "vel": Vector3.ZERO}]
	a.free()
	n[0] += 1
	var kc: int = nat.league_mas_cercano(lista, Vector2(5, 5), true)
	var kt: int = nat.league_mas_cercano_todos(lista, Vector2(5, 5))
	var pen: float = nat.league_linea_penultimo(lista, true, true, 1.0, 0.0)
	if kc != 1 or kt != 1 or not is_finite(pen):
		f.append("jugadores con nodo liberado/null/ausente: más cercano %d, de todos %d, penúltimo %s" % [kc, kt, str(pen)])
	b.free()
	## Un cuadro negativo o un `balon` corto en el catálogo se saltan (antes: SIGSEGV con el negativo).
	var guardado: Dictionary = LeagueToques.catalogo().duplicate(true)
	var quieta := PackedVector3Array()
	quieta.resize(10)
	LeagueToques._cat = {"pass": {"idle": [{"nombre": "neg", "cuadro": -1, "balon": [0.0, 0.0, 0.0]}, {"nombre": "corto", "cuadro": 2, "balon": [0.0]}, {"nombre": "ok", "cuadro": 5, "balon": [0.0, 0.0, 0.0]}]}}
	n[0] += 1
	var r := LeagueToques.alcanza("pass", Vector2.ZERO, Vector2(1, 0), 0.0, quieta)
	if r.get("anim", "") != "ok":
		f.append("catálogo con cuadro negativo y `balon` corto: se esperaba 'ok' y salió %s" % str(r))
	LeagueToques._cat = guardado
