class_name PelucheModelo
extends RefCounted
## UN PELUCHE EN 3D (27-10-2026): si la tabla `Peluches.PELUCHES` trae un `modelo` (.glb del regalo del dueño) se usa; si no, un peluche de RELLENO hecho con
## esferas —cuerpo, cabeza, orejas redondas o en punta o aletas, ojos y hocico— en el color de su ficha. Mide unos 0,3 m; `escala` la cambia. Sin azar.

static func _esfera(padre: Node3D, pos: Vector3, r: float, mat: Material, achatar: Vector3 = Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = achatar
	padre.add_child(mi)

static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m

static func montar(d: Dictionary, escala: float = 1.0) -> Node3D:
	var raiz := Node3D.new()
	var ruta := String(d.get("modelo", ""))
	if ruta != "" and ResourceLoader.exists(ruta):
		var ps := load(ruta) as PackedScene
		if ps != null:
			var n := ps.instantiate() as Node3D
			n.scale = Vector3.ONE * float(d.get("escala", 1.0)) * escala
			raiz.add_child(n)
			return raiz
	var c: Color = d["color"]
	var piel := _mat(c)
	var claro := _mat(c.lerp(Color.WHITE, 0.55))
	var oscuro := _mat(Color(0.05, 0.05, 0.06))
	var forma := String(d.get("forma", "oso"))
	_esfera(raiz, Vector3(0, 0.11, 0), 0.11, piel, Vector3(1.0, 1.08, 0.92))              ## cuerpo
	_esfera(raiz, Vector3(0, 0.1, 0.075), 0.07, claro, Vector3(1.0, 1.1, 0.5))            ## barriga
	_esfera(raiz, Vector3(0, 0.255, 0), 0.085, piel)                                      ## cabeza
	match forma:
		"oso":
			for s: float in [-1.0, 1.0]:
				_esfera(raiz, Vector3(s * 0.062, 0.32, 0), 0.032, piel)
				_esfera(raiz, Vector3(s * 0.062, 0.32, 0.012), 0.017, claro)
		"puntas":
			for s2: float in [-1.0, 1.0]:
				var oreja := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = 0.032
				cm.height = 0.085
				cm.radial_segments = 6
				cm.rings = 0
				oreja.mesh = cm
				oreja.material_override = piel
				oreja.position = Vector3(s2 * 0.05, 0.335, 0)
				oreja.rotation.z = -s2 * 0.25
				raiz.add_child(oreja)
		_:
			for s3: float in [-1.0, 1.0]:
				_esfera(raiz, Vector3(s3 * 0.12, 0.1, 0.02), 0.04, piel, Vector3(0.6, 1.3, 1.0))   ## aletas
	for s4: float in [-1.0, 1.0]:
		_esfera(raiz, Vector3(s4 * 0.03, 0.268, 0.072), 0.013, oscuro)                    ## ojos
		_esfera(raiz, Vector3(s4 * 0.085, 0.045, 0.02), 0.04, piel)                       ## patitas
	_esfera(raiz, Vector3(0, 0.243, 0.083), 0.02, claro if forma != "bola" else _mat(Color(1.0, 0.7, 0.2)))   ## hocico o pico
	raiz.scale = Vector3.ONE * escala
	return raiz
