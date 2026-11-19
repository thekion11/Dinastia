class_name ProbarNativoDtMapa
extends RefCounted
## (19-11-2026) EL MAPA UV DE LA CABEZA DEL DT EN C++ = GDScript (`nativo/src/dtmapa_nativo.cpp`; gemela `PersonajeVida._mapa_gd`). Mallas de mentira (triángulos al azar con UV en [0, 1] a
## varias alturas, también degenerados y por debajo de 1,5 m, que no cuentan) de una y de dos superficies; se comparan los bytes RGBAF del mapa. Devuelve {fallos, textos}.
static func _malla(rng: RandomNumberGenerator, triangulos: int, alto_min: float, superficies: int) -> ArrayMesh:
	var m := ArrayMesh.new()
	for _s in superficies:
		var v := PackedVector3Array()
		var uv := PackedVector2Array()
		var idx := PackedInt32Array()
		for t in triangulos:
			var u0 := Vector2(rng.randf(), rng.randf())
			var tam := rng.randf_range(0.002, 0.25)
			for k in 3:
				v.append(Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(alto_min, 1.95), rng.randf_range(-0.1, 0.12)))
				uv.append(u0 + (Vector2(rng.randf(), rng.randf()) * tam if t % 17 != 0 else Vector2.ZERO))   ## algún triángulo degenerado
				idx.append(v.size() - 1)
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2610
	var comparados := 0
	var clave := 0
	for caso in [[1, 1.4, 1], [30, 1.4, 1], [400, 1.45, 2], [2000, 1.0, 1], [60, 0.2, 3]]:
		var malla := _malla(rng, caso[0], caso[1], caso[2])
		clave += 1
		var gd: ImageTexture = PersonajeVida._mapa_gd(malla, "prueba_nat_%d" % clave)
		var sups: Array = []
		for s in malla.get_surface_count():
			var arr := malla.surface_get_arrays(s)
			sups.append([arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_TEX_UV], arr[Mesh.ARRAY_INDEX]])
		var c: Image = nat.dt_mapa(sups)
		comparados += 1
		if (gd == null) != (c == null) or (gd != null and gd.get_image().get_data() != c.get_data()):
			fallos.append("mapa distinto con %d triángulos (altura mínima %s, %d superficies)" % [caso[0], caso[1], caso[2]])
	comparados += 1
	if nat.dt_mapa([]) != null:
		fallos.append("sin superficies debía dar null")
	return {"fallos": fallos, "textos": ["mapa de la cabeza del DT: %d mallas comparadas (bytes RGBAF)" % comparados]}
