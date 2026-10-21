class_name EntornoEstadio
extends RefCounted
## LO QUE RODEA AL ESTADIO (21-10-2026, «el estadio por fuera»). En el partido y
## en la Carrera de Jugador, alrededor del estadio no había nada: un suelo gris y
## el horizonte oscuro. Ahora, de dentro hacia fuera: una plaza peatonal, la
## avenida que lo rodea con farolas y árboles, dos aparcamientos con coches y un
## horizonte de edificios (kits de Kenney, CC0). En la ciudad 3D no se pone: allí
## el estadio ya tiene la ciudad de verdad alrededor.
##   EntornoEstadio.montar(raiz, perfil, niveles)

const ARBOLES := ["res://assets/kenney/suburbano/tree-large.glb", "res://assets/kenney/suburbano/tree-small.glb"]
const EDIFICIOS := [
	"res://assets/ciudad/kenney_buildings/building-skyscraper-a.glb", "res://assets/ciudad/kenney_buildings/building-skyscraper-b.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-c.glb", "res://assets/ciudad/kenney_buildings/building-skyscraper-d.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-e.glb",
	"res://assets/ciudad/kenney_comercial/building-a.glb", "res://assets/ciudad/kenney_comercial/building-c.glb",
	"res://assets/ciudad/kenney_comercial/building-f.glb", "res://assets/ciudad/kenney_comercial/building-h.glb",
	"res://assets/ciudad/kenney_comercial/building-k.glb", "res://assets/ciudad/kenney_comercial/building-n.glb",
]
const PLAZA := 22.0        ## metros de plaza alrededor de la huella del estadio
const BANDA := 34.0        ## de la plaza a la avenida (aparcamientos)
const CALLE := 12.0

static func montar(raiz: Node3D, est: Dictionary, niveles: int) -> Node3D:
	if raiz == null or raiz.get_node_or_null("EntornoEstadio") != null:
		return null
	var e := Node3D.new()
	e.name = "EntornoEstadio"
	raiz.add_child(e)
	var g := StadiumBuilder.geom_de_forma(String(est.get("forma", "cuenco")))
	var fondo := StadiumBuilder.fondo_tribuna(niveles)
	var hx: float = float(g["dx"]) + fondo + 10.0
	var hz: float = float(g["dz"]) + fondo + 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(est.get("nombre", "estadio")) + String(est.get("forma", "")))
	_suelos(e, hx, hz)
	var px := hx + PLAZA
	var pz := hz + PLAZA
	var cx := px + BANDA
	var cz := pz + BANDA
	_avenida(e, cx, cz)
	_arboles_y_farolas(e, px, pz, cx, cz, rng)
	_aparcamiento(e, Vector3(-(px + BANDA * 0.5), 0, 0), true, pz * 1.4, rng)
	_aparcamiento(e, Vector3(0, 0, -(pz + BANDA * 0.5)), false, px * 1.4, rng)
	_horizonte(e, cx, cz, rng)
	_banderas(e, px, pz, est)
	return e

## Mástiles con las banderas del club en la plaza, delante de la tribuna
## principal (+X) y del fondo del túnel (+Z), alternando los dos colores.
static func _banderas(e: Node3D, px: float, pz: float, est: Dictionary) -> void:
	var c1 := Color(str(est.get("hincha1", est.get("asiento1", "#1f5f3d"))))
	var c2 := Color(str(est.get("hincha2", est.get("asiento2", "#ffffff"))))
	var mastil := CylinderMesh.new()
	mastil.top_radius = 0.05
	mastil.bottom_radius = 0.08
	mastil.height = 12.0
	var xfs: Array[Transform3D] = []
	var k := 0
	for i in range(-3, 4):
		for lado: Array in [[Vector3(px - 6.0, 0, float(i) * 9.0), -PI * 0.5], [Vector3(float(i) * 9.0, 0, pz - 6.0), PI]]:
			var p: Vector3 = lado[0]
			xfs.append(Transform3D(Basis(), p + Vector3(0, 6.0, 0)))
			StadiumBuilder._bandera_ondeante(e, p + Vector3(0, 10.6, 0), Vector2(2.6, 1.6), c1 if k % 2 == 0 else c2, float(lado[1]), float(k) * 0.7)
			k += 1
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.8, 0.8, 0.82)
	metal.metallic = 0.7
	metal.roughness = 0.3
	_multi(e, mastil, xfs, metal)

static func _plano(padre: Node3D, tam: Vector2, pos: Vector3, mat: Material) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi

static func _suelos(e: Node3D, hx: float, hz: float) -> void:
	## Hierba hasta el horizonte (antes: el vacío oscuro).
	var hierba := StandardMaterial3D.new()
	hierba.albedo_color = Color(0.30, 0.42, 0.24)
	hierba.roughness = 1.0
	_plano(e, Vector2(2400, 2400), Vector3(0, -0.22, 0), hierba)
	## La plaza: losas claras alrededor del estadio.
	var losa: StandardMaterial3D = Texturas.hormigon(Color(0.62, 0.60, 0.56), 7).duplicate()
	losa.uv1_world_triplanar = true
	losa.uv1_scale = Vector3(0.35, 0.35, 0.35)
	losa.normal_enabled = false
	_plano(e, Vector2((hx + PLAZA) * 2.0, (hz + PLAZA) * 2.0), Vector3(0, -0.12, 0), losa)

static func _avenida(e: Node3D, cx: float, cz: float) -> void:
	var asfalto := StandardMaterial3D.new()
	asfalto.albedo_color = Color(0.16, 0.16, 0.17)
	asfalto.roughness = 0.95
	var acera := StandardMaterial3D.new()
	acera.albedo_color = Color(0.55, 0.54, 0.52)
	var lx := (cx + CALLE) * 2.0
	var lz := (cz + CALLE) * 2.0
	for s: float in [-1.0, 1.0]:
		_plano(e, Vector2(lx, CALLE), Vector3(0, -0.1, s * cz), asfalto)
		_plano(e, Vector2(CALLE, lz), Vector3(s * cx, -0.1, 0), asfalto)
		_plano(e, Vector2(lx, 3.0), Vector3(0, -0.08, s * (cz - CALLE * 0.5 - 1.5)), acera)
		_plano(e, Vector2(3.0, lz), Vector3(s * (cx - CALLE * 0.5 - 1.5), -0.08, 0), acera)
	## Línea discontinua del centro.
	var raya := QuadMesh.new()
	raya.size = Vector2(0.18, 3.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = raya
	var xfs: Array[Transform3D] = []
	var acostada := Basis(Vector3.RIGHT, -PI * 0.5)
	for s: float in [-1.0, 1.0]:
		var z := -cz
		while z <= cz:
			xfs.append(Transform3D(acostada, Vector3(s * cx, -0.07, z)))
			z += 7.0
		var x := -cx
		while x <= cx:
			xfs.append(Transform3D(Basis(Vector3.UP, PI * 0.5) * acostada, Vector3(x, -0.07, s * cz)))
			x += 7.0
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.92, 0.92, 0.88)
	mmi.material_override = blanco
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	e.add_child(mmi)

static func _arboles_y_farolas(e: Node3D, px: float, pz: float, cx: float, cz: float, rng: RandomNumberGenerator) -> void:
	var escenas: Array = []
	for r: String in ARBOLES:
		if ResourceLoader.exists(r):
			escenas.append(load(r))
	## Farola: poste y luminaria (dos piezas en dos MultiMesh).
	var poste := CylinderMesh.new()
	poste.top_radius = 0.07
	poste.bottom_radius = 0.1
	poste.height = 8.0
	var cabeza := BoxMesh.new()
	cabeza.size = Vector3(0.5, 0.18, 1.2)
	var postes: Array[Transform3D] = []
	var cabezas: Array[Transform3D] = []
	## Por el borde interior de la avenida (y la plaza): árboles y farolas alternos.
	var puntos: Array = []
	for s: float in [-1.0, 1.0]:
		var x := -cx + 8.0
		while x < cx - 8.0:
			puntos.append([Vector3(x, 0, s * (cz - CALLE * 0.5 - 4.0)), Vector3(0, 0, -s)])
			x += 13.0
		var z := -cz + 8.0
		while z < cz - 8.0:
			puntos.append([Vector3(s * (cx - CALLE * 0.5 - 4.0), 0, z), Vector3(-s, 0, 0)])
			z += 13.0
	var k := 0
	for par: Array in puntos:
		var p: Vector3 = par[0]
		k += 1
		if k % 3 == 0:
			postes.append(Transform3D(Basis(), p + Vector3(0, 4.0, 0)))
			var hacia: Vector3 = par[1]
			cabezas.append(Transform3D(Basis(Vector3.UP, atan2(hacia.x, hacia.z)), p + Vector3(0, 8.0, 0) - hacia * 0.0 + hacia * 0.5))
		elif not escenas.is_empty():
			var a: Node3D = (escenas[rng.randi() % escenas.size()] as PackedScene).instantiate()
			a.position = p
			a.rotation.y = rng.randf() * TAU
			a.scale = Vector3.ONE * rng.randf_range(7.0, 10.0)
			e.add_child(a)
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.35, 0.36, 0.38)
	gris.metallic = 0.5
	_multi(e, poste, postes, gris)
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color(0.9, 0.9, 0.85)
	luz.emission_enabled = true
	luz.emission = Color(1.0, 0.92, 0.75)
	luz.emission_energy_multiplier = 0.6
	_multi(e, cabeza, cabezas, luz)

static func _multi(e: Node3D, malla: Mesh, xfs: Array[Transform3D], mat: Material) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	e.add_child(mmi)

## Un aparcamiento: hileras de plazas con rayas blancas y coches (no todas
## ocupadas). `centro` en el suelo; `a_lo_largo_z`: si las hileras corren en z.
static func _aparcamiento(e: Node3D, centro: Vector3, a_lo_largo_z: bool, largo: float, rng: RandomNumberGenerator) -> void:
	var flota := CityBuilder.flota_coches()
	var raya := QuadMesh.new()
	raya.size = Vector2(0.14, 5.0)
	var rayas: Array[Transform3D] = []
	var acostada := Basis(Vector3.RIGHT, -PI * 0.5)
	var giro_r := Basis() if a_lo_largo_z else Basis(Vector3.UP, PI * 0.5)
	var plazas := int(largo / 2.7)
	for hilera: float in [-1.0, 1.0]:
		for i in plazas:
			var a := -largo * 0.5 + float(i) * 2.7
			var lado: float = hilera * 6.5
			var pos := Vector3(lado, 0, a) if a_lo_largo_z else Vector3(a, 0, lado)
			## Las rayas van perpendiculares a la hilera (separan las plazas).
			rayas.append(Transform3D((Basis(Vector3.UP, PI * 0.5) if a_lo_largo_z else Basis()) * acostada, centro + pos + (Vector3(0, -0.06, 1.35) if a_lo_largo_z else Vector3(1.35, -0.06, 0))))
			if flota.is_empty() or rng.randf() > 0.62:
				continue
			var coche := CityBuilder.instanciar_coche(flota[rng.randi() % flota.size()], rng)
			coche.position = centro + pos
			## Aparcados de morro hacia el pasillo central (cada hilera mira a la otra).
			var mira: float = -hilera
			coche.rotation.y = (PI * 0.5 if mira > 0 else -PI * 0.5) if a_lo_largo_z else (0.0 if mira > 0 else PI)
			e.add_child(coche)
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.9, 0.9, 0.86)
	_multi(e, raya, rayas, blanco)
	## El asfalto del aparcamiento.
	var asfalto := StandardMaterial3D.new()
	asfalto.albedo_color = Color(0.2, 0.2, 0.21)
	var tam := Vector2(19.0, largo + 4.0) if a_lo_largo_z else Vector2(largo + 4.0, 19.0)
	_plano(e, tam, centro + Vector3(0, -0.1, 0), asfalto)

## El horizonte: edificios de la ciudad a 90-260 m de la avenida, más altos
## cuanto más lejos (no tapan el estadio desde fuera y cierran el fondo).
static func _horizonte(e: Node3D, cx: float, cz: float, rng: RandomNumberGenerator) -> void:
	var escenas: Array = []
	for r: String in EDIFICIOS:
		if ResourceLoader.exists(r):
			escenas.append(load(r))
	if escenas.is_empty():
		return
	for i in 64:
		var ang := float(i) / 64.0 * TAU + rng.randf_range(-0.04, 0.04)
		var lejos := rng.randf_range(90.0, 260.0)
		var dir := Vector3(sin(ang), 0, cos(ang))
		## Del borde de la avenida hacia fuera (el rectángulo, no un círculo).
		var borde := minf(cx / maxf(absf(dir.x), 0.001), cz / maxf(absf(dir.z), 0.001))
		var p := dir * (borde + CALLE + lejos)
		var b: Node3D = (escenas[rng.randi() % escenas.size()] as PackedScene).instantiate()
		b.position = p
		b.rotation.y = atan2(-dir.x, -dir.z) + float(rng.randi() % 4) * PI * 0.5
		b.scale = Vector3.ONE * rng.randf_range(9.0, 13.0) * (1.0 + (lejos - 90.0) / 300.0)
		e.add_child(b)
