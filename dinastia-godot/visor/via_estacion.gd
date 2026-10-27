class_name ViaEstacion
extends RefCounted
## LA VÍA QUE SALE DE LA CIUDAD (27-10-2026, pieza F-3c, pedido del líder: «una vía que salga de la ciudad hacia el horizonte, con
## el tren entrando y saliendo»). Las dos vías de la Estación Central siguen BAJO TIERRA hasta pasada la autopista del anillo (z mundo ≈ −1480:
## así NO cruzan a nivel ninguna calle —Almendros, Rocío, Alameda, Constitución—, ni la rampa ni los pilares de la autopista) y allí salen a la luz por una boca de túnel (`Z_BOCA_A`), corren a cielo abierto 200 m (balasto,
## traviesas, carriles y pórticos de catenaria) y se meten en otro túnel en el horizonte (`Z_BOCA_B`). Todo en coordenadas
## LOCALES de la estación (z negativa = al norte). El tren sale de la boca lejana, cruza el tramo abierto, desaparece en la boca
## cercana y reaparece por la boca del andén; mientras va bajo tierra se oculta (`visible_en`).
const Z_BOCA_A := -930.0          ## la boca cercana (más allá de la autopista: z mundo ≈ −1480); el túnel se extiende 36 m hacia el sur
const Z_BOCA_B := -1130.0         ## la boca lejana (el horizonte); el túnel se extiende 36 m hacia el norte
const LARGO_BOCA := 36.0
const VIA_X := 8.0
const Y_VIA := 0.25

## ¿Se ve un tren con el morro en `z` y `largo` de coches? Solo si todo él está a cielo abierto o dentro de una boca: no
## mientras va por el subsuelo entre la boca cercana y el túnel del andén (`z_tunel_andén`, el z donde empieza ese túnel).
static func visible_en(z: float, largo: float, z_tunel_anden: float) -> bool:
	return z <= Z_BOCA_A + LARGO_BOCA or z - largo >= z_tunel_anden

const PASO_PERFIL := 10.0
const MARGEN_PERFIL := 40.0

## Altura del terreno (la MISMA función que pinta la malla, `CityBuilder.altura_en` vía `TelefericoFlora.altura_malla`) a lo largo de la vía exterior, respecto al suelo
## de la estación: una muestra cada 10 m, la mayor de las dos vías y el centro, y nunca por debajo de 0. La loma del norte sube hasta ~2 m: la vía y el balasto la siguen
## (terraplén) en vez de quedar enterrados.
static func perfil(est: Node3D, b: CityBuilder) -> PackedFloat32Array:
	var r := PackedFloat32Array()
	var z := Z_BOCA_B - MARGEN_PERFIL
	while z <= Z_BOCA_A + MARGEN_PERFIL + 0.01:
		var h := 0.0
		for dx: float in [-VIA_X, 0.0, VIA_X]:
			h = maxf(h, TelefericoFlora.altura_malla(b, est.position.x + dx, est.position.z + z) - est.position.y)
		r.append(h)
		z += PASO_PERFIL
	return r

## Altura de la vía en `z` (local de la estación), interpolando el perfil; fuera de él, la del extremo.
static func altura(p: PackedFloat32Array, z: float) -> float:
	if p.is_empty():
		return 0.0
	var f := clampf((z - (Z_BOCA_B - MARGEN_PERFIL)) / PASO_PERFIL, 0.0, float(p.size() - 1))
	var i := mini(int(f), p.size() - 2)
	return lerpf(p[i], p[i + 1], f - float(i))

static func montar(est: Node3D, b: CityBuilder, beton: Material) -> PackedFloat32Array:
	var prf := perfil(est, b)
	var largo := Z_BOCA_A - Z_BOCA_B
	var balasto := b._mat_simple(Color(0.5, 0.48, 0.45), 0.95)
	var acero := b._mat_simple(Color(0.45, 0.47, 0.5), 0.4)
	var madera := b._mat_simple(Color(0.34, 0.25, 0.18), 0.9)
	var poste := b._mat_simple(Color(0.3, 0.32, 0.34), 0.5)
	## Tramos de 10 m: terraplén de balasto (de 1,5 m bajo tierra hasta la cota de la vía), carriles y hilos, cada uno con la pendiente de su tramo.
	var z0 := Z_BOCA_B
	while z0 < Z_BOCA_A - 0.01:
		var z1 := minf(z0 + PASO_PERFIL, Z_BOCA_A)
		var h0 := altura(prf, z0)
		var h1 := altura(prf, z1)
		var hm := (h0 + h1) * 0.5
		var pend := -atan2(h1 - h0, z1 - z0)
		var zc := (z0 + z1) * 0.5
		var lar := (z1 - z0) / cos(pend) + 0.05
		for sx: float in [-VIA_X, VIA_X]:
			_caja(est, b, Vector3(sx, (hm + 0.4 - 1.5) * 0.5, zc), Vector3(6.0, hm + 1.9, z1 - z0 + 0.05), balasto)
			for dx: float in [-0.72, 0.72]:
				_caja(est, b, Vector3(sx + dx, hm + Y_VIA + 0.3, zc), Vector3(0.14, 0.18, lar), acero, pend)
			_caja(est, b, Vector3(sx, hm + 6.4, zc), Vector3(0.06, 0.06, lar), poste, pend)
		z0 = z1
	## Traviesas: una sola malla con todas.
	var n := int(largo / 1.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 0.14, 0.45)
	mm.mesh = bm
	mm.instance_count = n * 2
	for k in n:
		var zt := Z_BOCA_B + (float(k) + 0.5) * 1.4
		for i in 2:
			mm.set_instance_transform(k * 2 + i, Transform3D(Basis.IDENTITY, Vector3((-VIA_X if i == 0 else VIA_X), altura(prf, zt) + Y_VIA + 0.22, zt)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = madera
	est.add_child(mmi)
	## Pórticos de catenaria cada 60 m.
	var k_p := 0
	var zp := Z_BOCA_B + 30.0
	while zp < Z_BOCA_A - 10.0:
		var hp := altura(prf, zp)
		for sx2: float in [-VIA_X * 1.85, VIA_X * 1.85]:
			_caja(est, b, Vector3(sx2, hp + 4.0 - 0.5, zp), Vector3(0.4, 9.0, 0.4), poste)
		_caja(est, b, Vector3(0, hp + 7.8, zp), Vector3(VIA_X * 3.7, 0.35, 0.35), poste)
		zp += 60.0
		k_p += 1
	## Las dos bocas de túnel: cilindro de hormigón medio enterrado y disco oscuro al frente.
	var sombra := StandardMaterial3D.new()
	sombra.albedo_color = Color(0.015, 0.015, 0.02)
	sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for par: Array in [[Z_BOCA_A, 1.0], [Z_BOCA_B, -1.0]]:
		var z_boca: float = par[0]
		var hacia: float = par[1]       ## +1: el cuerpo del túnel se extiende hacia el sur; −1: hacia el norte
		var cuerpo := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 13.5
		cm.bottom_radius = 13.5
		cm.height = LARGO_BOCA
		cm.radial_segments = 28
		cuerpo.mesh = cm
		cuerpo.material_override = beton
		cuerpo.rotation.x = PI * 0.5
		cuerpo.position = Vector3(0, altura(prf, z_boca), z_boca + hacia * LARGO_BOCA * 0.5)
		est.add_child(cuerpo)
		var boca := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 12.0
		dm.bottom_radius = 12.0
		dm.height = 0.1
		dm.radial_segments = 28
		boca.mesh = dm
		boca.material_override = sombra
		boca.rotation.x = PI * 0.5
		boca.position = Vector3(0, altura(prf, z_boca), z_boca - hacia * 0.06)
		est.add_child(boca)
	est.set_meta("via_exterior", {"z_a": Z_BOCA_A, "z_b": Z_BOCA_B, "porticos": k_p, "perfil_max": _maximo(prf)})
	return prf

static func _caja(est: Node3D, b: CityBuilder, pos: Vector3, tam: Vector3, mat: Material, pitch: float = 0.0) -> void:
	var mi := b._caja_en(pos, tam, mat)
	b.remove_child(mi)
	mi.position = pos
	mi.rotation.x = pitch
	est.add_child(mi)

static func _maximo(p: PackedFloat32Array) -> float:
	var m := 0.0
	for v in p:
		m = maxf(m, v)
	return m
