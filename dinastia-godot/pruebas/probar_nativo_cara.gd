class_name ProbarNativoCara
extends RefCounted
## (19-11-2026) EL BORDE DE LA CARA EN C++ = GDScript (`nativo/src/cara_nativo.cpp`; gemelas `CaraMalla._pegar_borde_gd` y `_rejilla_piel_gd`). Un cráneo de mentira (puntos y
## normales al azar en la zona de la cara) y un borde de 468 vértices con alfa 0, entre 0 y 1 y 1, cerca y lejos de la piel; se comparan la rejilla y, byte a byte,
## las posiciones pegadas y la distancia a la piel. Devuelve {fallos, textos}.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3009
	var comparados := 0
	for caso in range(5):
		var n_piel: int = [0, 12, 300, 2500, 9000][caso]
		var cv := PackedVector3Array()
		var nn := PackedVector3Array()
		for i in n_piel:
			cv.append(Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(1.45, 1.8), rng.randf_range(-0.1, 0.15)))
			var nor := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
			nn.append(nor if i % 13 != 0 else nor * 0.3)   ## algunas normales cortas (se descartan)
		var r_gd: Dictionary = CaraMalla._rejilla_piel_gd(cv, nn)
		var r_c: Dictionary = nat.cara_rejilla_piel(cv, nn)
		comparados += 1
		if r_gd.size() != r_c.size() or not r_gd.recursive_equal(r_c, 4):
			fallos.append("rejilla de piel distinta con %d puntos" % n_piel)
		var pos := PackedVector3Array()
		var alfa := PackedFloat32Array()
		for i in 468:
			if n_piel > 0 and i % 3 != 0:
				var base := cv[rng.randi() % n_piel]
				pos.append(base + Vector3(rng.randf_range(-0.03, 0.03), rng.randf_range(-0.03, 0.03), rng.randf_range(-0.03, 0.03)))
			else:
				pos.append(Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(1.3, 2.0), rng.randf_range(-0.3, 0.3)))
			alfa.append([0.0, 0.0, 0.5, 0.85, 0.95, 1.0][rng.randi() % 6])
		CaraMalla._alfa = alfa
		var a_gd: PackedVector3Array = CaraMalla._pegar_borde_gd(pos, r_gd)
		var l_gd: PackedFloat32Array = CaraMalla._lejos.duplicate()
		var res: Array = nat.cara_pegar_borde(pos, alfa, r_gd)
		comparados += 1
		if var_to_bytes(a_gd) != var_to_bytes(res[0]):
			fallos.append("posiciones pegadas distintas con %d puntos de piel" % n_piel)
		if var_to_bytes(l_gd) != var_to_bytes(res[1]):
			fallos.append("distancias a la piel distintas con %d puntos de piel" % n_piel)
	## Las normales de `_armar`: mallas con vértices sueltos (normal nula → hacia atrás).
	for n3: int in [3, 50, 468, 2000]:
		var pos3 := PackedVector3Array()
		for i in n3:
			pos3.append(Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(1.5, 1.8), rng.randf_range(-0.1, 0.1)))
		var tri3 := PackedInt32Array()
		for t in range((n3 - 2) * 3 if n3 > 4 else 3):
			tri3.append(rng.randi() % (n3 - 2))   ## los dos últimos vértices quedan sueltos
		comparados += 1
		if var_to_bytes(CaraMalla._normales_cara_gd(pos3, tri3, n3)) != var_to_bytes(nat.cara_normales(pos3, tri3, n3)):
			fallos.append("normales distintas con %d vértices" % n3)
	CaraMalla._alfa = PackedFloat32Array()
	return {"fallos": fallos, "textos": ["cara: %d comparaciones (rejilla y borde, 5 cráneos de 0 a 9000 puntos)" % comparados]}
