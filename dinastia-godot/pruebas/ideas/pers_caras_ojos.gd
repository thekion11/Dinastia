extends BaseIdea
## LOS OJOS DE LAS CARAS 3D (26-10-2026, agente «pers»). En peatones con cara de
## la biblioteca salían dos óvalos negros BAJO los ojos: el globo 3D del cuerpo
## asomaba por delante de la piel del párpado de abajo de la malla de la cara.
## Aquí, para TODAS las caras (biblioteca y reales), se muestrea cada triángulo
## que queda en la malla (los de la abertura del ojo se quitan) y ningún punto
## que caiga delante de un globo puede quedar por detrás de su superficie.

## Globos del cuerpo (medidos en `Superhero_Male_FullBody.gltf`, malla «Eyes»:
## x ±0,0338, y 1,6836-1,7135, z 0,0512-0,0806).
const GLOBO_X := 0.0338
const GLOBO_Y := 1.6986
const GLOBO_Z := 0.0657
const GLOBO_R := 0.0149

func _z_globo(p: Vector3) -> float:
	var c := Vector2(GLOBO_X * signf(p.x), GLOBO_Y)
	var d := Vector2(p.x, p.y).distance_to(c)
	if d >= GLOBO_R:
		return -1.0
	return GLOBO_Z + sqrt(GLOBO_R * GLOBO_R - d * d)

func _probar() -> void:
	_titulo("CARAS 3D: ningún globo ocular asoma fuera de la abertura del párpado")
	CaraMalla._cargar()
	var nombres: Array = CaraMalla._mallas.keys()
	nombres.sort()
	var tri := CaraMalla._tri
	var malas := 0
	var peor := 0.0
	var revisadas := 0
	var de_biblioteca := 0
	for nombre: String in nombres:
		var malla := CaraMalla.malla_de_prueba(nombre)
		if malla.is_empty():
			continue
		revisadas += 1
		if BibliotecaCaras._caras.has(nombre):
			de_biblioteca += 1
		var pos: PackedVector3Array = malla[0]
		var idx: PackedInt32Array = malla[1]
		var hundido := 0.0
		for t in range(0, idx.size() - 2, 3):
			var a := pos[idx[t]]
			var b := pos[idx[t + 1]]
			var c := pos[idx[t + 2]]
			for i in 7:
				for j in 7 - i:
					var u := float(i) / 6.0
					var v := float(j) / 6.0
					var p := a + (b - a) * u + (c - a) * v
					var zg := _z_globo(p)
					if zg > 0.0:
						hundido = maxf(hundido, zg - p.z)
		if hundido > 0.0:
			malas += 1
			peor = maxf(peor, hundido)
			if malas <= 8:
				_linea("  %s: el globo asoma %.1f mm por delante de la piel" % [nombre, hundido * 1000.0])
	_comprobar(revisadas > 50 and de_biblioteca > 30, "se revisan todas las caras (%d, %d de la biblioteca)" % [revisadas, de_biblioteca])
	_comprobar(malas == 0, "ninguna cara deja asomar un globo fuera de la abertura (%d con globo asomando, peor %.1f mm)" % [malas, peor * 1000.0])
	## Y la abertura sigue abierta (no se taparon los ojos para pasar la prueba).
	var abiertas := 0
	for nombre: String in nombres:
		var malla2 := CaraMalla.malla_de_prueba(nombre)
		if not malla2.is_empty() and (malla2[1] as PackedInt32Array).size() < tri.size():
			abiertas += 1
	_comprobar(abiertas == revisadas, "todas las caras conservan la abertura de los ojos (%d de %d)" % [abiertas, revisadas])
