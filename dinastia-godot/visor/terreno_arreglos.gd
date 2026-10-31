class_name TerrenoArreglos
extends RefCounted
## EL RELIEVE DEL TERRENO DE LA CIUDAD, EN ARREGLOS (30-10-2026, rendimiento). Salió de
## `CityBuilder._terreno`: alturas (FastNoiseLite), normales por diferencias centrales y las 64
## baldosas [vértices, normales, UV], en el mismo orden. Con la extensión C++ (`Nativo`) lo hace
## `DinastiaNativo.terreno` con las mismas cuentas; `calcular_gd` es el original (respaldo y prueba).

static func altura(x: float, z: float, ruido: FastNoiseLite, detalle: FastNoiseLite) -> float:
	var d := Vector2(x, z).length()
	if d <= CityBuilder.LLANO_RADIO:
		return 0.0
	var t: float = clampf((d - CityBuilder.LLANO_RADIO) / CityBuilder.LLANO_TRANSICION, 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var h: float = ruido.get_noise_2d(x, z) * CityBuilder.TERRENO_ALTURA
	h += detalle.get_noise_2d(x, z) * 6.0
	var dm := Vector2(x, z).distance_to(CityBuilder.MONTE_CENTRO)
	return h * t + CityBuilder.MONTE_ALTURA * exp(-dm * dm / (2.0 * CityBuilder.MONTE_RADIO * CityBuilder.MONTE_RADIO)) * t

static func calcular(ruido: FastNoiseLite, detalle: FastNoiseLite) -> Array:
	if Nativo.obj() != null:
		return Nativo.obj().terreno(ruido, detalle, CityBuilder.TERRENO_LADO, CityBuilder.TERRENO_CELDAS,
			CityBuilder.TERRENO_BALDOSAS, CityBuilder.LLANO_RADIO, CityBuilder.LLANO_TRANSICION, CityBuilder.TERRENO_ALTURA,
			CityBuilder.MONTE_CENTRO, CityBuilder.MONTE_ALTURA, CityBuilder.MONTE_RADIO)
	return calcular_gd(ruido, detalle)

## Normal de la rejilla de alturas en el vértice (i, j), siempre hacia arriba.
static func _normal_rejilla(alturas: Array, i: int, j: int, paso: float) -> Vector3:
	var n := CityBuilder.TERRENO_CELDAS
	var h := func(ii: int, jj: int) -> float: return float(alturas[clampi(jj, 0, n) * (n + 1) + clampi(ii, 0, n)])
	var dx: float = (h.call(i + 1, j) - h.call(i - 1, j)) / (2.0 * paso)
	var dz: float = (h.call(i, j + 1) - h.call(i, j - 1)) / (2.0 * paso)
	return Vector3(-dx, 1.0, -dz).normalized()

static func calcular_gd(ruido: FastNoiseLite, detalle: FastNoiseLite) -> Array:
	var celdas := CityBuilder.TERRENO_CELDAS
	var paso := CityBuilder.TERRENO_LADO / float(celdas)
	var mitad := CityBuilder.TERRENO_LADO * 0.5
	var alturas: Array = []
	alturas.resize((celdas + 1) * (celdas + 1))
	for j in range(celdas + 1):
		for i in range(celdas + 1):
			var x := -mitad + i * paso
			var z := -mitad + j * paso
			alturas[j * (celdas + 1) + i] = altura(x, z, ruido, detalle)
	var por_baldosa: int = celdas / CityBuilder.TERRENO_BALDOSAS
	var fila := celdas + 1
	var normales := PackedVector3Array()
	normales.resize(fila * fila)
	for j in fila:
		for i in fila:
			normales[j * fila + i] = _normal_rejilla(alturas, i, j, paso)
	var salida: Array = []
	for bj in range(CityBuilder.TERRENO_BALDOSAS):
		for bi in range(CityBuilder.TERRENO_BALDOSAS):
			var vs := PackedVector3Array()
			var ns := PackedVector3Array()
			var uvs := PackedVector2Array()
			for j in range(bj * por_baldosa, (bj + 1) * por_baldosa):
				for i in range(bi * por_baldosa, (bi + 1) * por_baldosa):
					var x0 := -mitad + i * paso
					var z0 := -mitad + j * paso
					var p00 := Vector3(x0, alturas[j * fila + i], z0)
					var p10 := Vector3(x0 + paso, alturas[j * fila + i + 1], z0)
					var p01 := Vector3(x0, alturas[(j + 1) * fila + i], z0 + paso)
					var p11 := Vector3(x0 + paso, alturas[(j + 1) * fila + i + 1], z0 + paso)
					## Dos triángulos por celda, cara hacia arriba (ver la historia en `CityBuilder._terreno`).
					vs.append_array([p00, p10, p01, p10, p11, p01])
					ns.append_array([normales[j * fila + i], normales[j * fila + i + 1], normales[(j + 1) * fila + i],
						normales[j * fila + i + 1], normales[(j + 1) * fila + i + 1], normales[(j + 1) * fila + i]])
					uvs.append_array([Vector2(p00.x, p00.z) / 20.0, Vector2(p10.x, p10.z) / 20.0, Vector2(p01.x, p01.z) / 20.0,
						Vector2(p10.x, p10.z) / 20.0, Vector2(p11.x, p11.z) / 20.0, Vector2(p01.x, p01.z) / 20.0])
			salida.append([vs, ns, uvs])
	return salida
