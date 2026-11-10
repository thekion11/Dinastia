class_name ProbarNativoLeague
extends RefCounted
## La locomoción de League-Soccer en C++ (`nativo/src/league_nativo.cpp`, 10-11) da LO MISMO que su GDScript: la elección de clip
## (`LeagueMovimiento.elegir_gd`), la legalidad de las intermedias (`LeagueAuto.legal_gd`) y el bucle de huesos con que se
## construyen (`LeagueAuto.mezclar_gd`). Lo llama `pruebas/probar_nativo.gd`.

## Devuelve {"fallos": [..], "textos": [..]} (los textos son las medidas de tiempo).
static func probar(nat: Object) -> Dictionary:
	var fallos: Array = []
	var textos: Array = []
	if not nat.has_method("league_elegir"):
		fallos.append("la extensión no trae la locomoción de League (binario viejo: recompilar)")
		return {"fallos": fallos, "textos": textos}
	## 1. La elección: 4.000 consultas al azar (velocidades, giros, cuerpos permitidos, mirada o sin ella, pie).
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261110
	var cuerpos := [0.0, 0.25 * PI, -0.25 * PI, 0.75 * PI, -0.75 * PI]
	var distintas := 0
	var vacias := 0
	var t_gd := 0
	var t_cpp := 0
	LeagueMovimiento.clips()
	for k in 4000:
		var sp := rng.randf_range(0.0, 9.0)
		var rel := rng.randf_range(-PI, PI)
		var des := LeagueMovimiento.rango(rng.randf_range(0.0, 9.0))
		var entra := LeagueMovimiento.rango(sp)
		var cuerpo: float = cuerpos[rng.randi() % cuerpos.size()] if entra != LeagueMovimiento.IDLE else 0.0
		var mirar := rng.randf_range(-PI, PI) if rng.randf() < 0.7 else NAN
		var pie: String = ["", "D", "I"][rng.randi() % 3]
		var grupos: Array = LeagueMovimiento._cuadrantes.get(LeagueMovimiento._clave(entra, cuerpo), {}).values()
		var u0 := Time.get_ticks_usec()
		var a := LeagueMovimiento.elegir_gd(grupos, sp, rel, des, entra == LeagueMovimiento.IDLE, mirar, pie)
		var u1 := Time.get_ticks_usec()
		var b: Dictionary = nat.league_elegir(grupos, sp, rel, des, entra == LeagueMovimiento.IDLE, mirar, pie)
		var u2 := Time.get_ticks_usec()
		t_gd += u1 - u0
		t_cpp += u2 - u1
		if a.is_empty():
			vacias += 1
		if not (is_same(a, b) or (a.is_empty() and b.is_empty())):
			distintas += 1
	if distintas != 0 or vacias > 3000:
		fallos.append("elección de clip: C++ ≠ GDScript en %d de 4000 consultas (vacías: %d)" % [distintas, vacias])
	textos.append("league elegir: GDScript %.1f µs, C++ %.1f µs por consulta (4000, distintas %d)" % [t_gd / 4000.0, t_cpp / 4000.0, distintas])
	## 2. La legalidad: todas las combinaciones de velocidades y de cuerpos permitidos, en las 9 direcciones y en 200 al azar.
	var dis_legal := 0
	var n_legal := 0
	for vi in 4:
		for vo in 4:
			for cs: float in cuerpos:
				for ci: float in cuerpos:
					for f: float in LeagueAuto.ANGULOS + [rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)]:
						n_legal += 1
						if LeagueAuto.legal_gd(vi, vo, cs, ci, f * PI) != bool(nat.league_legal(vi, vo, cs, ci, f * PI)):
							dis_legal += 1
	if dis_legal != 0:
		fallos.append("legalidad de las intermedias: C++ ≠ GDScript en %d de %d casos" % [dis_legal, n_legal])
	## 3. El bucle de huesos de las intermedias: 40 intermedias construidas de las dos maneras, igual clave a clave (bytes).
	var dis_mez := 0
	var hechas := 0
	var t_mg := 0
	var t_mc := 0
	var giro := Quaternion(Vector3(1, 0, 0), -PI * 0.5)
	for c: Dictionary in LeagueMovimiento.clips():
		if not c.has("auto") or hechas >= 40 or rng.randf() > 0.1:
			continue
		hechas += 1
		var datos: Array = c["auto"]
		var a1 := LeagueAuto._plantilla(String(datos[0]), "Esqueleto/Skeleton3D")
		var a2 := LeagueAuto._plantilla(String(datos[1]), "Esqueleto/Skeleton3D")
		if a1 == null or a2 == null:
			fallos.append("no se cargan las plantillas de %s" % c["nombre"])
			continue
		var cuadros := PackedInt32Array([0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 24])
		var mezclas := PackedFloat64Array()
		for f in cuadros:
			var m := LeagueAuto.mezcla(f, c)
			mezclas.append(float(m[0]))
			mezclas.append(float(m[1]))
		var sg := Animation.new()
		var sc := Animation.new()
		var u0 := Time.get_ticks_usec()
		LeagueAuto.mezclar_gd(sg, a1, a2, cuadros, mezclas, float(datos[2]), giro)
		var u1 := Time.get_ticks_usec()
		nat.league_mezclar(sc, a1, a2, cuadros, mezclas, float(datos[2]), giro)
		var u2 := Time.get_ticks_usec()
		t_mg += u1 - u0
		t_mc += u2 - u1
		if not _iguales(sg, sc):
			dis_mez += 1
	if hechas < 20 or dis_mez != 0:
		fallos.append("bucle de huesos de las intermedias: C++ ≠ GDScript en %d de %d" % [dis_mez, hechas])
	textos.append("league intermedias: GDScript %.0f µs, C++ %.0f µs por intermedia (%d, distintas %d)" % [t_mg / maxf(1.0, hechas), t_mc / maxf(1.0, hechas), hechas, dis_mez])
	return {"fallos": fallos, "textos": textos}

## Dos animaciones con las mismas pistas, claves, tiempos y valores (byte a byte).
static func _iguales(a: Animation, b: Animation) -> bool:
	if a.get_track_count() != b.get_track_count() or a.get_track_count() == 0:
		return false
	for i in a.get_track_count():
		if a.track_get_path(i) != b.track_get_path(i) or a.track_get_type(i) != b.track_get_type(i) or a.track_get_key_count(i) != b.track_get_key_count(i):
			return false
		for k in a.track_get_key_count(i):
			if a.track_get_key_time(i, k) != b.track_get_key_time(i, k) or var_to_bytes(a.track_get_key_value(i, k)) != var_to_bytes(b.track_get_key_value(i, k)):
				return false
	return true
