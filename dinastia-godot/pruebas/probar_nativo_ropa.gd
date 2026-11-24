class_name ProbarNativoRopa
extends RefCounted
## (19-11-2026) LA ROPA APARTE EN C++ = GDScript (`nativo/src/ropa_nativo.cpp`, gemela `RopaSeparada._prenda_gd` y `_subconjunto_gd`). Un cuerpo de mentira
## (vértices al azar de pies a cabeza, también sobre los límites de cada zona) y sus triángulos: se comparan, byte a byte, los índices, el orden, las
## posiciones y las normales de cada prenda, y los subconjuntos de cada tipo de array. Devuelve {fallos, textos}.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2609
	var comparadas := 0
	for caso in range(6):
		var n: int = [0, 3, 40, 500, 4000, 9000][caso]
		var cuerpo := _cuerpo_al_azar(n, rng)
		var pos: PackedVector3Array = cuerpo[0]
		var nor: PackedVector3Array = cuerpo[1]
		var idx := _triangulos_al_azar(n, rng)
		for cual in [1, 2, 3]:
			var a_gd: Array = RopaSeparada._prenda_gd(pos, nor, idx, cual)
			var a_c: Array = nat.ropa_prenda(pos, nor, idx, cual)
			comparadas += 1
			if var_to_bytes(a_gd) != var_to_bytes([] if a_c.is_empty() else [a_c[0], Array(a_c[1]), a_c[2], a_c[3]]):
				## El orden en GDScript es Array y en C++ PackedInt32Array: se compara el contenido.
				if a_gd.is_empty() != a_c.is_empty() or (not a_gd.is_empty() and (a_gd[0] != a_c[0] or PackedInt32Array(a_gd[1]) != a_c[1] or a_gd[2] != a_c[2] or a_gd[3] != a_c[3])):
					fallos.append("prenda %d con %d vértices distinta" % [cual, n])
			if not a_c.is_empty():
				_comparar_subconjuntos(fallos, nat, a_c[1], pos, n, rng)
	return {"fallos": fallos, "textos": ["ropa aparte: %d prendas comparadas en 6 cuerpos de 0 a 9000 vértices" % comparadas]}

## Cuerpo de mentira de `n` vértices: [posiciones, normales]. No cambiar el orden del azar.
static func _cuerpo_al_azar(n: int, rng: RandomNumberGenerator) -> Array:
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	for i in n:
		## Alturas y anchos sobre los límites de cada zona (0,215 / 0,44 de ancho; 0,09 / 0,48 / 0,6 / 0,955 / 1,03 / 1,2 / 1,535 de alto) y en medio.
		var y := rng.randf_range(0.0, 1.8)
		var x := rng.randf_range(-0.6, 0.6)
		if i % 7 == 0:
			y = [0.09, 0.48, 0.6, 0.955, 1.03, 1.2, 1.535, 0.96, 1.0][rng.randi() % 9]
		if i % 11 == 0:
			x = [0.215, 0.44, -0.215, -0.44, 0.0][rng.randi() % 5]
		pos.append(Vector3(x, y, rng.randf_range(-0.3, 0.3)))
		nor.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized())
	return [pos, nor]

## Triángulos de `n` vértices: de vértices cercanos (misma zona casi siempre) y algunos sueltos.
static func _triangulos_al_azar(n: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var idx := PackedInt32Array()
	if n > 0:
		for t in range(n * 2):
			var a: int = rng.randi() % n
			var b: int = clampi(a + rng.randi_range(-3, 3), 0, n - 1)
			var c: int = clampi(a + rng.randi_range(-3, 3), 0, n - 1) if t % 5 != 0 else rng.randi() % n
			idx.append_array(PackedInt32Array([a, b, c]))
	return idx

## Compara, atributo a atributo, el subconjunto de GDScript y el de C++ para cada tipo de array.
static func _comparar_subconjuntos(fallos: Array[String], nat: Object, orden: PackedInt32Array,
		pos: PackedVector3Array, n: int, rng: RandomNumberGenerator) -> void:
	var fuentes: Array = [
		PackedVector2Array([Vector2(1, 2)] if n == 0 else _v2(n, rng)), pos, PackedColorArray(_col(n)),
		PackedFloat32Array(_fl(n * 4, rng)), PackedInt32Array(_en(n * 4, rng)),
	]
	for src: Variant in fuentes:
		var ancho := 4 if (src is PackedFloat32Array or src is PackedInt32Array) else 1
		if (src is PackedVector2Array) and n == 0:
			continue
		if var_to_bytes(RopaSeparada._subconjunto_gd(src, orden, ancho)) != var_to_bytes(nat.ropa_subconjunto(src, orden, ancho)):
			fallos.append("subconjunto de %s con %d vértices distinto" % [type_string(typeof(src)), n])

static func _v2(n: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n:
		o.append(Vector2(rng.randf(), rng.randf()))
	return o

static func _col(n: int) -> Array:
	var o: Array = []
	for i in n:
		o.append(Color(float(i % 7) / 7.0, 0.5, 0.25, 1.0))
	return o

static func _fl(n: int, rng: RandomNumberGenerator) -> Array:
	var o: Array = []
	for i in n:
		o.append(rng.randf())
	return o

static func _en(n: int, rng: RandomNumberGenerator) -> Array:
	var o: Array = []
	for i in n:
		o.append(rng.randi() % 70)
	return o
