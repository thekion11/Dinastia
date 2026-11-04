extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), mundo_3d, repaso 2: RECORRER TODO EL MAPA con una rejilla de 16 m: qué se puede pisar a pie (radio 0,4) y en coche (radio 2,2), qué es alcanzable
## desde la puerta del club, qué zonas pisables quedan aisladas, pendientes que un peatón subiría, y que el suelo cubre hasta el límite del mundo.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const PASO := 16.0

func _probar() -> void:
	_titulo("A4 MUNDO_3D: recorrido del mapa entero (a pie y en coche)")
	var c: Dictionary = await Comun.abrir(self, 777, int(OS.get_environment("CALIDAD_NIVEL")) if OS.get_environment("CALIDAD_NIVEL") != "" else Calidad.MEDIO)
	var cb: CityBuilder = c["cb"]
	var obst: Array[Rect2] = ExploradorCiudad.construir_obstaculos(cb)
	var circulos: PackedVector3Array = cb.get("circulos")
	var rej := {}
	for v in circulos:
		var k := Vector2i(floori(v.x / 8.0), floori(v.y / 8.0))
		if not rej.has(k):
			rej[k] = []
		rej[k].append(v)
	for modo in [["a pie", 0.4], ["en coche", 2.2]]:
		_recorrer(cb, obst, rej, String(modo[0]), float(modo[1]))
	(c["vc"] as Node).free()

func _libre_circ(rej: Dictionary, p: Vector3, radio: float) -> bool:
	var cx := floori(p.x / 8.0)
	var cz := floori(p.z / 8.0)
	for i in range(cx - 1, cx + 2):
		for j in range(cz - 1, cz + 2):
			for v: Vector3 in rej.get(Vector2i(i, j), []):
				var dx := p.x - v.x
				var dz := p.z - v.y
				var rr := radio + v.z
				if dx * dx + dz * dz < rr * rr:
					return false
	return true

func _recorrer(cb: CityBuilder, obst: Array[Rect2], rej: Dictionary, modo: String, radio: float) -> void:
	var lim := int(ExploradorCiudad.LIMITE / PASO)
	var libres := {}
	var nan := 0
	var alturas := {}
	for ix in range(-lim, lim + 1):
		for iz in range(-lim, lim + 1):
			var p := Vector3(float(ix) * PASO, 0.0, float(iz) * PASO)
			var h: float = cb.altura_en(p.x, p.z)
			if is_nan(h) or is_inf(h):
				nan += 1
				continue
			alturas[Vector2i(ix, iz)] = h
			if ExploradorCiudad.libre(p, radio, obst) and _libre_circ(rej, p, radio):
				libres[Vector2i(ix, iz)] = true
	## Alcanzable desde la puerta del club (el punto libre más cercano al estadio).
	var inicio := Vector2i(0, 0)
	var mejor := INF
	for k: Vector2i in libres:
		var d := Vector2(float(k.x) * PASO, float(k.y) * PASO).distance_to(Vector2(CityBuilder.ESTADIO_EN.x, CityBuilder.ESTADIO_EN.z + 120.0))
		if d < mejor:
			mejor = d
			inicio = k
	var vistos := {}
	var pila: Array[Vector2i] = [inicio]
	vistos[inicio] = true
	var empinados := 0
	var peor_pend := 0.0
	while not pila.is_empty():
		var k: Vector2i = pila.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var j: Vector2i = k + d
			if libres.has(j) and not vistos.has(j):
				var pend := absf(float(alturas[j]) - float(alturas[k])) / PASO
				peor_pend = maxf(peor_pend, pend)
				if pend > 0.6:
					empinados += 1
				vistos[j] = true
				pila.append(j)
	## Islas: componentes libres no alcanzadas.
	var restantes := {}
	for k in libres:
		if not vistos.has(k):
			restantes[k] = true
	var islas: Array[int] = []
	while not restantes.is_empty():
		var s: Vector2i = restantes.keys()[0]
		var n := 0
		var q: Array[Vector2i] = [s]
		restantes.erase(s)
		while not q.is_empty():
			var k2: Vector2i = q.pop_back()
			n += 1
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var j2: Vector2i = k2 + d
				if restantes.has(j2):
					restantes.erase(j2)
					q.append(j2)
		islas.append(n)
	islas.sort()
	islas.reverse()
	var total := (2 * lim + 1) * (2 * lim + 1)
	print("  %s: %d de %d celdas pisables (%.0f %%), %d alcanzables desde el club, %d islas aisladas %s, pasos con pendiente >0,6: %d (peor %.2f), alturas NaN: %d" % [modo, libres.size(), total, 100.0 * float(libres.size()) / float(total), vistos.size(), islas.size(), str(islas.slice(0, 8)), empinados, peor_pend, nan])
	_comprobar(nan == 0, "%s: el terreno tiene altura definida en todo el mapa (%d celdas sin)" % [modo, nan])
	_comprobar(float(vistos.size()) >= 0.9 * float(libres.size()), "%s: al menos el 90 %% de lo pisable es alcanzable desde la puerta del club (%.0f %%)" % [modo, 100.0 * float(vistos.size()) / maxf(1.0, float(libres.size()))])
	_comprobar(peor_pend <= 0.7, "%s: ningún paso entre celdas contiguas pisables pasa del 70 %% de pendiente (%d pasos por encima del 60 %%, peor %.2f)" % [modo, empinados, peor_pend])
	var cubierto := 0
	var suelos := 0
	var caja := AABB()
	var primero := true
	for g in cb.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh != null and mi.get_aabb().size.x > 1500.0 and mi.get_aabb().size.y < 400.0:
			var a := mi.global_transform * mi.get_aabb()
			caja = a if primero else caja.merge(a)
			primero = false
			suelos += 1
	if modo == "a pie":
		for punto in [Vector3(1470, 0, 0), Vector3(-1470, 0, 0), Vector3(0, 0, 1470), Vector3(0, 0, -1470), Vector3(1470, 0, 1470)]:
			var cubren: Array[String] = []
			for g in cb.find_children("*", "MeshInstance3D", true, false):
				var mi2 := g as MeshInstance3D
				if mi2.mesh == null:
					continue
				var a2 := mi2.global_transform * mi2.get_aabb()
				if punto.x >= a2.position.x and punto.x <= a2.end.x and punto.z >= a2.position.z and punto.z <= a2.end.z and a2.size.x > 100.0:
					cubren.append("%s %s y %.0f..%.0f" % [mi2.name, str(a2.size.snapped(Vector3.ONE)), a2.position.y, a2.end.y])
			print("  en el borde %s: %d mallas grandes lo cubren (altura del terreno %.1f)" % [str(punto), cubren.size(), cb.altura_en(punto.x, punto.z)])
			_comprobar(cubren.size() >= 1, "el terreno existe en el borde %s (%d mallas)" % [str(punto), cubren.size()])
		print("  suelo: %d mallas grandes, cubren x %.0f..%.0f z %.0f..%.0f" % [suelos, caja.position.x, caja.end.x, caja.position.z, caja.end.z])
