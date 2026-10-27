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

static func montar(est: Node3D, b: CityBuilder, beton: Material) -> void:
	var largo := Z_BOCA_A - Z_BOCA_B
	var z_c := (Z_BOCA_A + Z_BOCA_B) * 0.5
	var balasto := b._mat_simple(Color(0.5, 0.48, 0.45), 0.95)
	var acero := b._mat_simple(Color(0.45, 0.47, 0.5), 0.4)
	var madera := b._mat_simple(Color(0.34, 0.25, 0.18), 0.9)
	var poste := b._mat_simple(Color(0.3, 0.32, 0.34), 0.5)
	for sx: float in [-VIA_X, VIA_X]:
		_caja(est, b, Vector3(sx, 0.2, z_c), Vector3(6.0, 0.4, largo), balasto)
		for dx: float in [-0.72, 0.72]:
			_caja(est, b, Vector3(sx + dx, Y_VIA + 0.3, z_c), Vector3(0.14, 0.18, largo), acero)
	## Traviesas: una sola malla con todas.
	var n := int(largo / 1.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 0.14, 0.45)
	mm.mesh = bm
	mm.instance_count = n * 2
	for k in n:
		for i in 2:
			mm.set_instance_transform(k * 2 + i, Transform3D(Basis.IDENTITY, Vector3((-VIA_X if i == 0 else VIA_X), Y_VIA + 0.22, Z_BOCA_B + (float(k) + 0.5) * 1.4)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = madera
	est.add_child(mmi)
	## Pórticos de catenaria cada 60 m y los dos hilos.
	var k_p := 0
	var zp := Z_BOCA_B + 30.0
	while zp < Z_BOCA_A - 10.0:
		for sx2: float in [-VIA_X * 1.85, VIA_X * 1.85]:
			_caja(est, b, Vector3(sx2, 4.0, zp), Vector3(0.4, 8.0, 0.4), poste)
		_caja(est, b, Vector3(0, 7.8, zp), Vector3(VIA_X * 3.7, 0.35, 0.35), poste)
		zp += 60.0
		k_p += 1
	for sx3: float in [-VIA_X, VIA_X]:
		_caja(est, b, Vector3(sx3, 6.4, z_c), Vector3(0.06, 0.06, largo), poste)
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
		cuerpo.position = Vector3(0, 0, z_boca + hacia * LARGO_BOCA * 0.5)
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
		boca.position = Vector3(0, 0, z_boca - hacia * 0.06)
		est.add_child(boca)
	est.set_meta("via_exterior", {"z_a": Z_BOCA_A, "z_b": Z_BOCA_B, "porticos": k_p})

static func _caja(est: Node3D, b: CityBuilder, pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := b._caja_en(pos, tam, mat)
	b.remove_child(mi)
	mi.position = pos
	est.add_child(mi)
