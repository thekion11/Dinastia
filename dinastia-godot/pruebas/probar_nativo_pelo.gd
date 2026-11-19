class_name ProbarNativoPelo
extends RefCounted
## (19-11-2026) LAS CUENTAS DEL PELO POR CAPAS EN C++ = GDScript (`nativo/src/pelo_nativo.cpp`; gemelas `PeloCapas._normales_gd`, `_densidades_gd`, `_max_gd`, `_suavizar_gd`).
## Mallas de mentira de 2 a 6000 vértices (con la nariz, vértice 1, mirando a un lado y a otro), triángulos al azar (alguno con la lista cortada), densidades de 0 a 255
## y factores de suavizado; se comparan los bytes del resultado. Devuelve {fallos, textos}.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3009
	var comparados := 0
	for caso in range(8):
		var n: int = [2, 3, 17, 100, 468, 1500, 6000, 6001][caso]
		var pos := PackedVector3Array()
		for i in n:
			pos.append(Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(1.5, 1.8), rng.randf_range(-0.1, 0.1)))
		if caso % 2 == 1:
			pos[1] = Vector3(0, 1.6, -0.2)   ## otro lado
		var tri := PackedInt32Array()
		for t in range(n * 3 if n > 2 else 0):
			tri.append(rng.randi() % n)
		if caso == 3 and tri.size() > 2:
			tri.resize(tri.size() - 2)   ## lista que no es múltiplo de 3
		comparados += 1
		if var_to_bytes(PeloCapas._normales_gd(pos, tri)) != var_to_bytes(nat.pelo_normales(pos, tri)):
			fallos.append("normales distintas con %d vértices" % n)
		var bytes := PackedByteArray()
		for i in rng.randi_range(0, n + 5):
			bytes.append(rng.randi() % 256)
		for pedido: int in [0, n, n + 40]:
			comparados += 1
			if var_to_bytes(PeloCapas._densidades_gd(bytes, pedido)) != var_to_bytes(nat.pelo_densidades(bytes, pedido)):
				fallos.append("densidades distintas (%d bytes, %d pedidos)" % [bytes.size(), pedido])
		var a := PackedFloat32Array()
		for i in n:
			a.append(rng.randf() if i % 4 != 0 else 0.0)
		comparados += 1
		if var_to_bytes(PeloCapas._max_gd(a)) != var_to_bytes(nat.pelo_max(a)):
			fallos.append("máximo distinto con %d valores" % n)
		for f: float in [0.0, 0.5, 0.85, 1.0, 1.3]:
			comparados += 1
			if var_to_bytes(PeloCapas._suavizar_gd(a, tri, f)) != var_to_bytes(nat.pelo_suavizar(a, tri, f)):
				fallos.append("suavizado con f = %s distinto (%d vértices)" % [f, n])
		var corto := a.slice(0, maxi(1, n / 2))   ## con menos valores que vértices (el `if i0 < a.size()`)
		comparados += 1
		if var_to_bytes(PeloCapas._suavizar_gd(corto, tri, 0.7)) != var_to_bytes(nat.pelo_suavizar(corto, tri, 0.7)):
			fallos.append("suavizado con lista corta distinto (%d vértices)" % n)
	comparados += 1
	if var_to_bytes(PeloCapas._max_gd(PackedFloat32Array())) != var_to_bytes(nat.pelo_max(PackedFloat32Array())):
		fallos.append("máximo de lista vacía distinto")
	return {"fallos": fallos, "textos": ["pelo: %d comparaciones en 8 mallas de 2 a 6001 vértices" % comparados]}
