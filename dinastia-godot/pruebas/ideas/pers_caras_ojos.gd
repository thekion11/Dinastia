extends BaseIdea
## LOS ÓVALOS NEGROS BAJO LOS OJOS (26-10-2026, agente «pers»). En peatones
## salían dos óvalos negros y brillantes bajo los ojos. Causa real: las GAFAS DE
## SOL de `PeatonQ` -dos esferas aplastadas en alto (un disco tumbado de 4,8 cm
## de fondo), colgadas de un nodo con la escala `k` y por debajo del ojo-. Se
## comprueban aquí:
##   1. que las gafas quedan centradas en los ojos, por delante y finas;
##   2. (descartado como causa, pero vigilado) que en NINGUNA cara 3D (las de la
##      biblioteca y las reales) el globo ocular asoma por delante de la piel
##      fuera de la abertura del párpado: se muestrea cada triángulo que queda.
##      Tolerancia 0,5 mm (menos de un píxel aun en el primer plano más cercano;
##      la peor cara mide 0,3 mm).

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
						hundido = maxf(hundido, zg - p.z - 0.0005)
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
	_gafas()

## Las gafas de sol de los peatones, en el espacio del hueso de la cabeza.
func _gafas() -> void:
	_titulo("PEATONES: las gafas de sol, sobre los ojos")
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var cristales := 0
	for i in 60:
		var d := PeatonQ.crear(rng)
		if d.is_empty():
			continue
		add_child(d["nodo"])
		PeatonQ.terminar(d)
		var esq: Skeleton3D = d["esqueleto"]
		var mujer := bool(d["mujer"])
		## Centro del globo de cada ojo sobre el hueso «Head» (mallas «Eyes»).
		var ojo_y := (1.656 - 1.55) if mujer else (1.6986 - 1.6)
		var frente := 0.0753 if mujer else 0.0806
		for ba in esq.get_children():
			if not (ba is BoneAttachment3D) or String((ba as BoneAttachment3D).bone_name) != "Head":
				continue
			for n: Node in ba.get_children():
				for mi in n.get_children():
					if not (mi is MeshInstance3D) or not ((mi as MeshInstance3D).mesh is SphereMesh):
						continue
					var esf := (mi as MeshInstance3D).mesh as SphereMesh
					if esf.is_hemisphere or esf.radius > 0.03 or esf.radius < 0.015:
						continue
					cristales += 1
					var t := (n as Node3D).transform * (mi as MeshInstance3D).transform
					var c := t.origin
					var fondo := (t.basis * Vector3(0, 0, esf.radius * 2.0)).length()
					var alto := (t.basis * Vector3(0, esf.height, 0)).length()
					_comprobar(absf(c.y - ojo_y) < 0.004 and absf(absf(c.x) - 0.0342) < 0.004,
						"peatón %d: cristal centrado en su ojo (dy %.1f mm, x %.4f)" % [i, (c.y - ojo_y) * 1000.0, c.x])
					_comprobar(fondo < 0.015 and alto > 0.025, "peatón %d: cristal fino de frente (%.1f cm de fondo, %.1f de alto)" % [i, fondo * 100.0, alto * 100.0])
					_comprobar(c.z - fondo * 0.5 > frente + 0.005, "peatón %d: cristal por delante del ojo" % i)
		(d["nodo"] as Node).queue_free()
	_comprobar(cristales >= 4, "hay gafas en la muestra (%d cristales)" % cristales)
