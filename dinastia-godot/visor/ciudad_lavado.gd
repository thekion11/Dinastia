class_name CiudadLavado
extends Node
## LAVADO DE AUTOS Y APARCAMIENTO DE LA GASOLINERA (28-10-2026, M-177). Al este de la marquesina, un túnel de lavado de 18 m: dos muros blancos con
## friso azul, techo, arco de entrada con el rótulo «LAVADO DE AUTOS» y un semáforo de entrada, dentro dos rodillos verticales por lado y un
## cepillo horizontal que GIRAN (mientras la cámara está a menos de `ALCANCE` m), espuma en el suelo y luz azul. Al oeste, un aparcamiento de
## 8 plazas con sus rayas, números y bordillo, con tres coches de la flota aparcados (los mismos modelos del tráfico).
const ALCANCE := 150.0
const LARGO := 18.0
const ANCHO := 6.4

var _giran: Array = []   ## [{nodo, vel (rad/s), eje}]

static func montar(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	var b := ex.b
	var l := CiudadLavado.new()
	l.name = "LavadoDeAutos"
	b.add_child(l)
	var blanco := b._mat_simple(Color(0.94, 0.94, 0.95), 0.5)
	var azul := b._mat_simple(Color(0.1, 0.4, 0.78), 0.5)
	var oscuro := b._mat_simple(Color(0.12, 0.13, 0.15), 0.8)
	var x0 := c.x + w * 0.3
	var z0 := c.z + f * 0.02
	var y0 := c.y
	l.set_meta("tunel", Vector3(x0, y0, z0))
	l.set_meta("aparcamiento", Vector3(c.x - w * 0.36, y0, c.z + f * 0.12 + 8.0))
	## Muros, friso azul y techo.
	for sx: float in [-1.0, 1.0]:
		b._caja_en(Vector3(x0 + sx * ANCHO * 0.5, y0 + 2.0, z0), Vector3(0.4, 4.0, LARGO), blanco)
		b._caja_en(Vector3(x0 + sx * (ANCHO * 0.5 + 0.21), y0 + 0.9, z0), Vector3(0.04, 0.5, LARGO), azul)
	b._caja_en(Vector3(x0, y0 + 4.2, z0), Vector3(ANCHO + 1.0, 0.4, LARGO + 0.6), blanco)
	b._caja_en(Vector3(x0, y0 + 0.03, z0), Vector3(ANCHO - 0.4, 0.06, LARGO), oscuro)   ## calzada mojada del túnel
	## Arcos de entrada y salida con el rótulo y la luz azul interior.
	for sz: float in [-1.0, 1.0]:
		b._caja_en(Vector3(x0, y0 + 4.5, z0 + sz * (LARGO * 0.5 + 0.1)), Vector3(ANCHO + 1.0, 1.3, 0.3), azul)
	b._rotulo(Vector3(x0, y0 + 4.6, z0 - LARGO * 0.5 - 0.35), "LAVADO DE AUTOS", Color(1, 1, 1), 34)
	b._caja_en(Vector3(x0, y0 + 3.9, z0), Vector3(ANCHO - 1.0, 0.06, LARGO - 1.0), b._mat_simple(Color(0.7, 0.9, 1.0), 0.4, 1.4))
	## Semáforo de entrada (rojo/verde) a un lado.
	b._caja_en(Vector3(x0 + ANCHO * 0.5 + 1.0, y0 + 2.2, z0 - LARGO * 0.5 - 0.6), Vector3(0.3, 1.0, 0.3), oscuro)
	b._caja_en(Vector3(x0 + ANCHO * 0.5 + 1.0, y0 + 2.45, z0 - LARGO * 0.5 - 0.46), Vector3(0.18, 0.18, 0.04), b._mat_simple(Color(1, 0.1, 0.1), 0.4, 2.0))
	## Rodillos verticales (dos por lado, uno rojo y uno azul) y cepillo horizontal: giran.
	for sx2: float in [-1.0, 1.0]:
		for k in 2:
			var cil := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.38
			cm.bottom_radius = 0.38
			cm.height = 2.6
			cil.mesh = cm
			cil.material_override = b._mat_simple(Color(0.85, 0.15, 0.15) if k == 0 else Color(0.15, 0.4, 0.85), 0.9)
			cil.position = Vector3(x0 + sx2 * 1.3, y0 + 1.4, z0 - 3.0 + float(k) * 6.0)
			cil.add_to_group("lavado_giratorio")   ## en un grupo: `Optimizar.agrupar` no lo funde con el resto (y así puede girar)
			b.add_child(cil)
			l._giran.append({"nodo": cil, "vel": 7.0 * -sx2, "eje": Vector3.UP})
	var horiz := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.3
	hm.bottom_radius = 0.3
	hm.height = ANCHO - 1.6
	horiz.mesh = hm
	horiz.material_override = b._mat_simple(Color(0.95, 0.8, 0.15), 0.9)
	horiz.position = Vector3(x0, y0 + 3.0, z0)
	horiz.rotation.z = PI * 0.5
	horiz.add_to_group("lavado_giratorio")
	b.add_child(horiz)
	l._giran.append({"nodo": horiz, "vel": 9.0, "eje": Vector3.RIGHT})
	## Espuma en el suelo del túnel.
	var espuma := b._mat_simple(Color(1, 1, 1), 0.95)
	for i in 14:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22 + float(i % 3) * 0.08
		sm.height = sm.radius * 1.2
		s.mesh = sm
		s.material_override = espuma
		s.position = Vector3(x0 + (float(i % 5) - 2.0) * 0.55, y0 + 0.15, z0 - LARGO * 0.4 + float(i) * 1.0)
		b.add_child(s)
	## Aparcamiento al oeste: 8 plazas con rayas, número y bordillo, y tres coches aparcados.
	var px := c.x - w * 0.36
	var pz := c.z + f * 0.12
	b._caja_en(Vector3(px, y0 + 0.02, pz + 8.0), Vector3(12.0, 0.04, 26.0), b._mat_simple(Color(0.3, 0.3, 0.32), 0.95))
	var raya := b._mat_simple(Color(0.95, 0.95, 0.9), 0.7)
	var coches := CityBuilder.flota_coches()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.x * 7.0 + c.z)
	for i in 8:
		var zz := pz + float(i) * 3.2
		b._caja_en(Vector3(px - 2.6, y0 + 0.05, zz - 1.6), Vector3(5.2, 0.02, 0.12), raya)
		b._caja_en(Vector3(px + 2.6, y0 + 0.05, zz - 1.6), Vector3(5.2, 0.02, 0.12), raya)
		b._rotulo(Vector3(px - 4.9, y0 + 0.12, zz), str(i + 1), Color(1, 1, 1), 18)
		if i in [1, 4, 6] and not coches.is_empty():
			var auto: Node3D = CityBuilder.instanciar_coche(coches[rng.randi() % coches.size()], rng)
			auto.position = Vector3(px - 2.6 if i % 2 == 0 else px + 2.6, y0 + 0.05, zz)
			auto.rotation.y = PI * 0.5 if i % 2 == 0 else -PI * 0.5
			b.add_child(auto)
	b._rotulo(Vector3(px, y0 + 3.2, pz - 3.6), "P", Color(0.2, 0.5, 1.0), 60)
	b._cil_en(Vector3(px, y0 + 1.6, pz - 3.6), 0.07, 3.2, b._mat_simple(Color(0.4, 0.4, 0.45), 0.6))

func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for g: Dictionary in _giran:
		if not is_instance_valid(g["nodo"]):
			continue
		var n := g["nodo"] as Node3D
		if n.global_position.distance_to(cam.global_position) < ALCANCE:
			n.rotate(g["eje"], float(g["vel"]) * delta)
