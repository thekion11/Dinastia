class_name TrenDetalle
extends RefCounted
## EL TREN DEL METRO MENOS INFANTIL (27-10-2026): `MetroCiudad._tren_real` lo dejaba en cajas blancas lisas. Aquí se le pone una
## carrocería de acero inoxidable (metálica, algo cepillada), bogies con ruedas y ejes bajo cada coche, equipos de aire
## acondicionado en el techo, marcos oscuros alrededor de las puertas, faldones y el rótulo «METRO · línea» en los costados.
## `vestir(tren, color_linea, piso)` se llama al final de `_tren_real`; `carroceria()` sustituye al blanco liso.

static var _acero: StandardMaterial3D

static func carroceria() -> StandardMaterial3D:
	if _acero == null:
		_acero = StandardMaterial3D.new()
		_acero.albedo_color = Color(0.74, 0.76, 0.79)
		_acero.albedo_texture = SubsueloDetalle._ruido(53, 0.02, FastNoiseLite.TYPE_SIMPLEX_SMOOTH)   ## vetas largas del cepillado
		_acero.uv1_triplanar = true
		_acero.uv1_scale = Vector3(0.12, 3.0, 0.12)
		_acero.metallic = 0.7
		_acero.roughness = 0.36
	return _acero

static func _caja(n: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	n.add_child(mi)

static func _mat(c: Color, rug: float = 0.6, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	m.metallic = metal
	return m

static func vestir(n: Node3D, col: Color, f: float, nombre_linea: String = "") -> void:
	var oscuro := _mat(Color(0.05, 0.05, 0.06), 0.7)
	var gris := _mat(Color(0.45, 0.47, 0.5), 0.5, 0.5)
	var hierro := _mat(Color(0.12, 0.12, 0.13), 0.45, 0.6)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.48
	cm.bottom_radius = 0.48
	cm.height = 0.16
	cm.radial_segments = 14
	cm.rings = 0
	for k in 3:
		var z := (float(k) - 1.0) * 16.6
		## Bogies: bastidor, dos ejes y cuatro ruedas (la vía queda a y ≈ 0).
		for dz: float in [-5.6, 5.6]:
			_caja(n, Vector3(0, 0.62, z + dz), Vector3(2.3, 0.3, 2.6), hierro)
			for ej: float in [-0.9, 0.9]:
				_caja(n, Vector3(0, 0.5, z + dz + ej), Vector3(1.9, 0.12, 0.12), hierro)
				for lado: float in [-1.0, 1.0]:
					var rueda := MeshInstance3D.new()
					rueda.mesh = cm
					rueda.material_override = hierro
					rueda.rotation.z = PI * 0.5
					rueda.position = Vector3(lado * 0.78, 0.48, z + dz + ej)
					n.add_child(rueda)
		## Faldones bajo el bastidor y equipos del techo.
		for lado2: float in [-1.0, 1.0]:
			_caja(n, Vector3(lado2 * 1.2, f - 0.75, z), Vector3(0.08, 0.35, 11.0), oscuro)
		for dz2: float in [-4.5, 4.5]:
			_caja(n, Vector3(0, f + 2.92, z + dz2), Vector3(1.7, 0.3, 2.0), gris)
			for r in 4:
				_caja(n, Vector3(0, f + 3.08, z + dz2 - 0.7 + float(r) * 0.46), Vector3(1.5, 0.02, 0.08), oscuro)
		## Marcos oscuros de las puertas (afuera) y el rótulo del costado.
		for lado3: float in [-1.0, 1.0]:
			for dz3: float in [-3.5, 3.5]:
				_caja(n, Vector3(lado3 * 1.5, f + 1.15, z + dz3), Vector3(0.04, 2.32, 1.56), oscuro)
			var l := Label3D.new()
			l.text = "METRO" if nombre_linea == "" else "METRO · %s" % nombre_linea
			l.font_size = 40
			l.pixel_size = 0.0045
			l.modulate = Color(0.12, 0.13, 0.16)
			l.outline_size = 0
			l.double_sided = false
			l.position = Vector3(lado3 * 1.52, f + 0.45, z)
			l.rotation_degrees = Vector3(0, 90.0 * lado3, 0)
			l.visibility_range_end = 60.0
			n.add_child(l)
		_caja(n, Vector3(0, f + 0.38, z + 8.0), Vector3(1.0, 0.18, 0.4), hierro)   ## acoplamiento entre coches
