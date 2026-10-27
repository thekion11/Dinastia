class_name TelefericoCabina
extends RefCounted
## LA CABINA DEL TELEFÉRICO (27-10-2026, el dueño: «cabina de verdad: ventanas por los cuatro lados, techo, brazo de suspensión con la
## pinza al cable, puerta y gente dentro»). Origen en el cable. De arriba abajo: carro con la PINZA y dos ruedas, brazo vertical
## con horquilla, techo con un lucernario, un zócalo de color con la PUERTA, ventanas de cristal por los cuatro lados entre cuatro
## montantes, suelo y siete viajeros (cápsula + cabeza, ropa de colores). Tamaño base 2,5 × 1,9 m; `Teleferico` la escala ×1,8.

const ANCHO := 2.5                ## a lo largo del cable (x local)
const FONDO := 1.9                ## a lo ancho (z local)
const Y_TECHO := -1.6
const Y_SUELO := -3.4

static func _caja(raiz: Node3D, pos: Vector3, tam: Vector3, mat: Material, giro: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = giro
	raiz.add_child(mi)

static func _mat(c: Color, rug: float = 0.55, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	m.metallic = metal
	return m

static func montar(color: Color) -> Node3D:
	var raiz := Node3D.new()
	var pintura := _mat(color, 0.4)
	var oscuro := _mat(Color(0.14, 0.15, 0.17), 0.6, 0.3)
	var acero := _mat(Color(0.5, 0.52, 0.55), 0.4, 0.6)
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.55, 0.75, 0.9, 0.32)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.roughness = 0.08
	cristal.metallic = 0.1
	cristal.cull_mode = BaseMaterial3D.CULL_DISABLED
	## Carro y pinza al cable: bloque oscuro con la mordaza naranja y dos ruedas encima.
	_caja(raiz, Vector3(0, -0.12, 0), Vector3(0.7, 0.26, 0.42), oscuro)
	_caja(raiz, Vector3(0, -0.34, 0), Vector3(0.34, 0.2, 0.34), _mat(Color(0.9, 0.45, 0.1), 0.5))
	for dx: float in [-0.3, 0.3]:
		var rueda := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.17
		cm.bottom_radius = 0.17
		cm.height = 0.14
		cm.radial_segments = 10
		rueda.mesh = cm
		rueda.material_override = acero
		rueda.rotation.x = PI * 0.5
		rueda.position = Vector3(dx, 0.05, 0)
		raiz.add_child(rueda)
	## Brazo de suspensión: varilla vertical y horquilla a los dos extremos del techo.
	_caja(raiz, Vector3(0, -0.85, 0), Vector3(0.1, 1.0, 0.1), acero)
	for s: float in [-1.0, 1.0]:
		_caja(raiz, Vector3(s * 0.55, (-1.3 + Y_TECHO) * 0.5, 0), Vector3(0.07, 0.46, 0.07), acero, Vector3(0, 0, s * 1.05))
	## Techo con lucernario.
	_caja(raiz, Vector3(0, Y_TECHO, 0), Vector3(ANCHO + 0.1, 0.12, FONDO + 0.1), pintura)
	_caja(raiz, Vector3(0, Y_TECHO + 0.12, 0), Vector3(ANCHO * 0.6, 0.1, FONDO * 0.5), pintura)
	_caja(raiz, Vector3(0, Y_TECHO + 0.2, 0), Vector3(ANCHO * 0.45, 0.04, FONDO * 0.35), cristal)
	## Suelo y zócalo (0,45 m de color por los cuatro lados).
	_caja(raiz, Vector3(0, Y_SUELO, 0), Vector3(ANCHO + 0.1, 0.14, FONDO + 0.1), oscuro)
	var y_z := Y_SUELO + 0.32
	_caja(raiz, Vector3(0, y_z, FONDO * 0.5), Vector3(ANCHO, 0.45, 0.06), pintura)
	_caja(raiz, Vector3(0, y_z, -FONDO * 0.5), Vector3(ANCHO, 0.45, 0.06), pintura)
	for sx: float in [-1.0, 1.0]:
		_caja(raiz, Vector3(sx * ANCHO * 0.5, y_z, 0), Vector3(0.06, 0.45, FONDO), pintura)
	## Cuatro montantes y las ventanas de cristal por los cuatro lados (de encima del zócalo al techo).
	var y_v := (Y_SUELO + 0.55 + Y_TECHO) * 0.5
	var alto_v := Y_TECHO - (Y_SUELO + 0.55)
	for sx2: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_caja(raiz, Vector3(sx2 * ANCHO * 0.5, y_v, sz * FONDO * 0.5), Vector3(0.1, alto_v, 0.1), pintura)
	for sz2: float in [-1.0, 1.0]:
		_caja(raiz, Vector3(0, y_v, sz2 * FONDO * 0.5), Vector3(ANCHO - 0.1, alto_v - 0.05, 0.03), cristal)
	for sx3: float in [-1.0, 1.0]:
		_caja(raiz, Vector3(sx3 * ANCHO * 0.5, y_v, 0), Vector3(0.03, alto_v - 0.05, FONDO - 0.1), cristal)
	## La puerta: en el lado +z, dos hojas con su junta, un marco oscuro y las manillas.
	_caja(raiz, Vector3(0, y_v, FONDO * 0.5 + 0.035), Vector3(0.04, alto_v - 0.05, 0.02), oscuro)
	_caja(raiz, Vector3(0, y_z, FONDO * 0.5 + 0.04), Vector3(0.04, 0.4, 0.03), oscuro)
	for dx2: float in [-0.12, 0.12]:
		_caja(raiz, Vector3(dx2, y_v - 0.1, FONDO * 0.5 + 0.06), Vector3(0.025, 0.16, 0.03), acero)
	for dx3: float in [-0.5, 0.5]:
		_caja(raiz, Vector3(dx3, y_v, FONDO * 0.5 + 0.03), Vector3(0.05, alto_v - 0.05, 0.02), oscuro)
	## Los viajeros: cápsula de cuerpo y esfera de cabeza, en grupos separados.
	var gente := [[-0.8, -0.3, Color(0.8, 0.2, 0.2)], [-0.35, 0.4, Color(0.2, 0.45, 0.8)], [0.1, -0.35, Color(0.9, 0.75, 0.2)], [0.55, 0.3, Color(0.25, 0.65, 0.35)],
		[0.85, -0.2, Color(0.9, 0.9, 0.9)], [-0.1, 0.1, Color(0.6, 0.3, 0.7)], [0.3, 0.55, Color(0.95, 0.5, 0.15)]]
	var piel := [Color(0.9, 0.72, 0.58), Color(0.62, 0.43, 0.3), Color(0.8, 0.6, 0.45), Color(0.4, 0.28, 0.2)]
	for i in gente.size():
		var g: Array = gente[i]
		var alto_p := 1.15 + float(i % 3) * 0.06
		var cuerpo := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.15
		cap.height = alto_p
		cap.radial_segments = 8
		cap.rings = 3
		cuerpo.mesh = cap
		cuerpo.material_override = _mat(g[2], 0.8)
		cuerpo.position = Vector3(float(g[0]), Y_SUELO + 0.07 + alto_p * 0.5, float(g[1]) * 0.5)
		raiz.add_child(cuerpo)
		var cabeza := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.11
		sp.height = 0.22
		sp.radial_segments = 8
		sp.rings = 4
		cabeza.mesh = sp
		cabeza.material_override = _mat(piel[i % piel.size()], 0.8)
		cabeza.position = Vector3(float(g[0]), Y_SUELO + 0.07 + alto_p + 0.08, float(g[1]) * 0.5)
		raiz.add_child(cabeza)
	return raiz
