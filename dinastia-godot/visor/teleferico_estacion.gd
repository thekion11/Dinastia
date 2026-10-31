class_name TelefericoEstacion
extends RefCounted
## DETALLES DE LAS ESTACIONES DEL TELEFÉRICO (27-10-2026, el dueño: «las estaciones de arriba y abajo con andén, techo y rótulo»): sobre
## el edificio de cajas que ya tenían (losa, cuerpo, tejado naranja, marquesina, rótulo), ahora ventanas de cristal en las fachadas, la
## puerta con su marco, una línea amarilla y una barandilla en el borde del andén, bancos, farolas bajo la marquesina y una barrera
## de cola. Coordenadas locales de la estación (+z = el andén, hacia donde mira); `base_n` es su nodo.

static func _caja(base_n: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	base_n.add_child(mi)

static func detalles(base_n: Node3D) -> int:
	var cristal := StandardMaterial3D.new()
	cristal.albedo_color = Color(0.25, 0.4, 0.55)
	cristal.roughness = 0.1
	cristal.metallic = 0.2
	var marco := StandardMaterial3D.new()
	marco.albedo_color = Color(0.9, 0.45, 0.1)
	marco.roughness = 0.5
	var oscuro := StandardMaterial3D.new()
	oscuro.albedo_color = Color(0.13, 0.14, 0.16)
	var amarillo := StandardMaterial3D.new()
	amarillo.albedo_color = Color(0.95, 0.8, 0.1)
	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.45, 0.3, 0.18)
	madera.roughness = 0.85
	var acero := StandardMaterial3D.new()
	acero.albedo_color = Color(0.4, 0.43, 0.46)
	acero.metallic = 0.5
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color(1.0, 0.95, 0.75)
	luz.emission_enabled = true
	luz.emission = Color(1.0, 0.9, 0.6)
	luz.emission_energy_multiplier = 1.4
	var n := 0
	## Fachada del andén (z = 4,5): cinco ventanas con marco y la puerta central.
	for k in 5:
		if k == 2:
			continue
		var x := (float(k) - 2.0) * 3.2
		_caja(base_n, Vector3(x, 3.9, 4.53), Vector3(2.2, 1.7, 0.08), cristal)
		_caja(base_n, Vector3(x, 3.9, 4.58), Vector3(2.4, 1.9, 0.04), marco)
		n += 2
	_caja(base_n, Vector3(0, 2.2, 4.55), Vector3(2.6, 2.8, 0.08), oscuro)
	_caja(base_n, Vector3(0, 2.2, 4.6), Vector3(3.0, 3.2, 0.04), marco)
	n += 2
	## Costados (x = ±8): dos ventanas.
	for sx: float in [-1.0, 1.0]:
		for z: float in [-1.8, 1.4]:
			_caja(base_n, Vector3(sx * 8.04, 3.9, z), Vector3(0.08, 1.7, 2.0), cristal)
			n += 1
	## Andén: línea amarilla en el borde, barandilla detrás y bancos.
	_caja(base_n, Vector3(0, 0.53, 13.6), Vector3(22.0, 0.04, 0.3), amarillo)
	## La barandilla deja una ENTRADA de 5 m en el centro (x ±2,5) donde empieza la rampa que baja a la plaza (28-10).
	for cx: float in [-6.75, 6.75]:
		_caja(base_n, Vector3(cx, 1.45, 13.9), Vector3(8.5, 0.08, 0.08), acero)
		_caja(base_n, Vector3(cx, 1.0, 13.9), Vector3(8.5, 0.05, 0.05), acero)
	for k2 in 12:
		var px := -10.5 + float(k2) * 1.9
		if absf(px) > 2.6:
			_caja(base_n, Vector3(px, 0.95, 13.9), Vector3(0.07, 1.0, 0.07), acero)
	n += 14 + rampa(base_n, acero, amarillo)
	for bx: float in [-6.0, 0.0, 6.0]:
		_caja(base_n, Vector3(bx, 0.95, 10.4), Vector3(2.2, 0.12, 0.6), madera)
		_caja(base_n, Vector3(bx, 1.25, 10.7), Vector3(2.2, 0.5, 0.08), madera)
		for dx: float in [-0.9, 0.9]:
			_caja(base_n, Vector3(bx + dx, 0.68, 10.4), Vector3(0.1, 0.5, 0.5), acero)
		n += 5
	## Farolas bajo la marquesina (cuatro) y la barrera de cola (postes con cinta).
	for lx: float in [-8.0, -2.7, 2.7, 8.0]:
		_caja(base_n, Vector3(lx, 5.15, 9.8), Vector3(0.5, 0.12, 0.5), luz)
		n += 1
	for bx2: float in [-3.8, -2.4, 2.4, 3.8]:   ## la barrera deja libre el paso de la puerta (x ±2,4)
		_caja(base_n, Vector3(bx2, 1.0, 7.4), Vector3(0.08, 1.0, 0.08), acero)
	for cx2: float in [-3.1, 3.1]:
		_caja(base_n, Vector3(cx2, 1.35, 7.4), Vector3(1.4, 0.05, 0.05), marco)
	n += 5
	return n

## RAMPA Y CAMINO (28-10): del borde del andén (z = 13,8, y = 0,5) baja a la hierba (y = −0,2) en 4,3 m, con pasamanos a los lados y,
## después, un camino de losas de 4 m de ancho hasta la plaza. Es por donde entra y sale la gente (`PasajerosTeleferico.RUTA_RAMPA`).
static func rampa(base_n: Node3D, acero: Material, amarillo: Material) -> int:
	var losas := StandardMaterial3D.new()
	losas.albedo_color = Color(0.72, 0.71, 0.68)
	losas.roughness = 0.9
	var r := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.6, 0.14, 4.3)
	r.mesh = bm
	r.material_override = losas
	r.position = Vector3(0, 0.1, 15.9)
	r.rotation_degrees.x = 9.3
	base_n.add_child(r)
	for sx: float in [-2.2, 2.2]:
		_caja(base_n, Vector3(sx, 0.95, 15.9), Vector3(0.05, 0.05, 4.3), acero)
		for zz: float in [14.2, 15.9, 17.6]:
			_caja(base_n, Vector3(sx, 0.7 - (zz - 13.8) * 0.16, zz), Vector3(0.06, 0.9, 0.06), acero)
	_caja(base_n, Vector3(0, -0.17, 24.0), Vector3(4.6, 0.06, 12.0), losas)
	_caja(base_n, Vector3(0, -0.13, 18.0), Vector3(4.6, 0.06, 0.25), amarillo)
	return 8
