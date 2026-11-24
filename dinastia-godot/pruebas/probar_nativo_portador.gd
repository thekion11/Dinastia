class_name ProbarNativoPortador
extends RefCounted
## La decisión con balón de League en C++ = la de GDScript (16-11-2026, paso a C++; lo llama `probar_nativo.gd`): `league_situacion`, `league_regate` y `league_decidir` frente a
## `LeagueNucleo.situacion_gd`, `regate_gd` y `decidir_gd`, byte a byte (`var_to_bytes`) y con el mismo estado del generador de azar después. Miles de entradas al azar: los 13 puestos,
## los dos lados, 0-11 rivales (con porteros, encima del balón, parados), compañeros encima del portador, zona de tiro y fuera de ella.
## Devuelve {fallos: Array[String], textos: Array[String]}.

const PUESTOS := ["POR", "DFC", "LD", "LI", "MCD", "CAD", "CAI", "MC", "MD", "MI", "MCO", "MP", "ED", "EI", "SD", "DC", "XX"]

static func _v(rr: RandomNumberGenerator, ax := 52.0, ay := 34.0) -> Vector2:
	return Vector2(rr.randf_range(-ax, ax), rr.randf_range(-ay, ay))

static func _rivales(rr: RandomNumberGenerator, caso: int, pos: Vector2) -> Array:
	var r: Array = []
	for i in rr.randi_range(0, 11):
		var p := _v(rr)
		if caso % 7 == 0 and i == 0:
			p = pos   ## encima del portador (seg degenerado / distancia 0)
		elif caso % 11 == 0 and i < 3:
			p = pos + Vector2(rr.randf_range(-2, 2), rr.randf_range(-2, 2))   ## muy cerca
		var m := Vector2.ZERO if caso % 5 == 0 else Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))
		r.append([p, m, i == 0 and caso % 2 == 0])
	return r

static func _pos_portador(rr: RandomNumberGenerator, caso: int, lado: float) -> Vector2:
	if caso % 3 == 0:   ## cerca del arco rival (zona de tiro)
		return Vector2(-lado * rr.randf_range(25.0, 52.5), rr.randf_range(-20, 20))
	return _v(rr)

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var rr := RandomNumberGenerator.new()
	rr.seed = 1613
	_situacion(nat, rr, fallos, textos)
	_regate(nat, rr, fallos, textos)
	_decidir(nat, rr, fallos, textos)
	return {"fallos": fallos, "textos": textos}


## 1. situación táctica (la extensión contra GDScript).
static func _situacion(nat: Object, rr: RandomNumberGenerator, fallos: Array[String],
		textos: Array[String]) -> void:
	var n := 4000
	var dis := 0
	var tg := 0
	var tc := 0
	for caso in n:
		var lado := 1.0 if caso % 2 == 0 else -1.0
		var pos := _pos_portador(rr, caso, lado)
		var mov := Vector2.ZERO if caso % 6 == 0 else Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))
		var riv := _rivales(rr, caso, pos)
		var t0 := Time.get_ticks_usec()
		var a := LeagueNucleo.situacion_gd(pos, mov, lado, riv)
		var t1 := Time.get_ticks_usec()
		var b: Array = nat.league_situacion(pos, mov, lado, riv)
		var t2 := Time.get_ticks_usec()
		tg += t1 - t0
		tc += t2 - t1
		if var_to_bytes(a) != var_to_bytes(b):
			dis += 1
	if dis > 0:
		fallos.append("situacion distinta en %d de %d casos" % [dis, n])
	textos.append("situación táctica: GDScript %.1f µs, C++ %.1f µs por llamada" % [tg / float(n), tc / float(n)])


## 2. regate (campo de fuerzas).
static func _regate(nat: Object, rr: RandomNumberGenerator, fallos: Array[String],
		textos: Array[String]) -> void:
	var n := 4000
	var dis := 0
	var tg := 0
	var tc := 0
	for caso in n:
		var lado := 1.0 if caso % 2 == 0 else -1.0
		var pos := _v(rr) if caso % 4 != 0 else Vector2(rr.randf_range(-1, 1), rr.randf_range(-1, 1))
		var mov := Vector2.ZERO if caso % 6 == 0 else Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))
		var mirada := Vector2.from_angle(rr.randf_range(0.0, TAU))
		var cerc: Array = _rivales(rr, caso, pos).slice(0, 5)
		var mente: float = [0.0, 0.25, 0.5, 0.75, 1.0][caso % 5]
		var ofensivo := rr.randf()
		var iman := rr.randf()
		var t0 := Time.get_ticks_usec()
		var a := LeagueNucleo.regate_gd(pos, mov, mirada, lado, cerc, mente, ofensivo, iman)
		var t1 := Time.get_ticks_usec()
		var b: Array = nat.league_regate(pos, mov, mirada, lado, cerc, mente, ofensivo, iman)
		var t2 := Time.get_ticks_usec()
		tg += t1 - t0
		tc += t2 - t1
		if var_to_bytes(a) != var_to_bytes(b):
			dis += 1
	if dis > 0:
		fallos.append("regate distinto en %d de %d casos" % [dis, n])
	textos.append("regate (campo de fuerzas): GDScript %.1f µs, C++ %.1f µs por llamada" % [tg / float(n), tc / float(n)])


## 3. decidir: mismo azar sembrado dos veces; debe dar lo mismo y dejar el generador igual.
static func _decidir(nat: Object, rr: RandomNumberGenerator, fallos: Array[String],
		textos: Array[String]) -> void:
	var dis := 0
	var dis_az := 0
	var tg := 0
	var tc := 0
	var cuenta := {"pase": 0, "panico": 0, "tiro": 0, "conducir": 0}
	var m := 4000
	for caso in m:
		var lado := 1.0 if caso % 2 == 0 else -1.0
		var pos := _pos_portador(rr, caso, lado)
		var mov := Vector2.ZERO if caso % 6 == 0 else Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))
		var riv := _rivales(rr, caso, pos)
		var puesto: String = PUESTOS[caso % PUESTOS.size()]
		var yo := {"pos": pos, "mov": mov, "lado": lado, "puesto": puesto, "tec_pase": rr.randf(), "tec_tiro": rr.randf(),
			"posee_ms": rr.randf_range(0.0, 7000.0), "sit": LeagueNucleo.situacion_gd(pos, mov, lado, riv)}
		var mates: Array = []
		for i in rr.randi_range(0, 10):
			var qp := _v(rr) if caso % 13 != 0 or i != 0 else pos
			var qm := Vector2(rr.randf_range(-8, 8), rr.randf_range(-8, 8))
			var qs: Array = LeagueNucleo.situacion_gd(qp, qm, lado, riv)
			if caso % 9 == 0:
				qs = [rr.randf(), rr.randf(), rr.randf()]
			mates.append({"i": i + 100, "pos": qp, "mov": qm, "puesto": PUESTOS[rr.randi() % PUESTOS.size()], "sit": qs})
		var mov_balon := Vector2(rr.randf_range(-12, 12), rr.randf_range(-12, 12))
		var posesion := rr.randf_range(0.0, 4.0)
		var muestras: int = [1, 25, 1, 0][caso % 4]
		var zona: float = 16.0 if caso % 8 != 0 else 24.0
		var az1 := RandomNumberGenerator.new()
		var az2 := RandomNumberGenerator.new()
		az1.seed = caso + 77
		az2.seed = caso + 77
		var t0 := Time.get_ticks_usec()
		var prev := LeagueNucleo.zona_tiro
		LeagueNucleo.zona_tiro = zona
		var a := LeagueNucleo.decidir_gd(yo, mates, riv, mov_balon, posesion, az1, muestras)
		LeagueNucleo.zona_tiro = prev
		var t1 := Time.get_ticks_usec()
		var b: Dictionary = nat.league_decidir(yo, mates, riv, mov_balon, posesion, az2, muestras, zona)
		var t2 := Time.get_ticks_usec()
		tg += t1 - t0
		tc += t2 - t1
		cuenta[String(a["accion"])] = int(cuenta[String(a["accion"])]) + 1
		if var_to_bytes(a) != var_to_bytes(b):
			dis += 1
		if az1.state != az2.state:
			dis_az += 1
	if dis > 0:
		fallos.append("decidir distinto en %d de %d casos" % [dis, m])
	if dis_az > 0:
		fallos.append("decidir deja el azar en otro estado en %d de %d casos" % [dis_az, m])
	if int(cuenta["pase"]) < 100 or int(cuenta["tiro"]) < 100 or int(cuenta["panico"]) < 50 or int(cuenta["conducir"]) < 50:
		fallos.append("la prueba de decidir no cubre todas las acciones: %s" % str(cuenta))
	textos.append("decisión con balón (sin situación): GDScript %.1f µs, C++ %.1f µs por llamada; cobertura %s" % [tg / float(m), tc / float(m), str(cuenta)])
