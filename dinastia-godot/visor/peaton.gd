class_name Peaton
extends Node3D
## UN PEATÓN (26-9-2026, plan B7: "peatones"). Figura ligera -sin esqueleto ni
## animaciones importadas, para poder poner decenas- que camina balanceando
## piernas y brazos. Lo mueve `TraficoCiudad` por la acera como a un coche;
## aquí solo se anima el paso. Mira hacia -Z (lo que espera el tráfico con
## `giro_base = 0`).

var _fase := 0.0
var _paso := 7.0
var _piernas: Array[Node3D] = []
var _brazos: Array[Node3D] = []

static func crear(rng: RandomNumberGenerator, escala: float = 1.0) -> Peaton:
	var p := Peaton.new()
	p._fase = rng.randf() * TAU
	p._paso = rng.randf_range(6.0, 8.0)
	var ropa := Color.from_hsv(rng.randf(), rng.randf_range(0.2, 0.7), rng.randf_range(0.3, 0.9))
	var pantalon: Color = [Color(0.15, 0.2, 0.35), Color(0.1, 0.1, 0.12), Color(0.45, 0.38, 0.28), Color(0.35, 0.35, 0.38)][rng.randi() % 4]
	var pieles := [Color("f1c7a5"), Color("d9a47c"), Color("b27a52"), Color("7a4e32"), Color("5a3a26")]
	var piel: Color = pieles[rng.randi() % pieles.size()]
	var alto := rng.randf_range(1.6, 1.9)
	var m_ropa := _mat(ropa)
	var m_pan := _mat(pantalon)
	var m_piel := _mat(piel)
	var cadera := alto * 0.52
	## Tronco y cabeza.
	_pieza(p, Vector3(0, cadera + alto * 0.17, 0), Vector3(0.36, alto * 0.32, 0.22), m_ropa)
	var cab := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = alto * 0.065
	sm.height = alto * 0.14
	cab.mesh = sm
	cab.material_override = m_piel
	cab.position = Vector3(0, cadera + alto * 0.4, 0)
	p.add_child(cab)
	## Piernas y brazos cuelgan de un pivote para poder balancearlos.
	for s: float in [-1.0, 1.0]:
		var pv := Node3D.new()
		pv.position = Vector3(0.09 * s, cadera, 0)
		p.add_child(pv)
		_pieza(pv, Vector3(0, -cadera * 0.5, 0), Vector3(0.13, cadera, 0.14), m_pan)
		p._piernas.append(pv)
		var pb := Node3D.new()
		pb.position = Vector3(0.23 * s, cadera + alto * 0.31, 0)
		p.add_child(pb)
		_pieza(pb, Vector3(0, -alto * 0.14, 0), Vector3(0.09, alto * 0.28, 0.1), m_ropa)
		p._brazos.append(pb)
	p.scale = Vector3.ONE * escala
	return p

static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m

static func _pieza(padre: Node3D, pos: Vector3, tam: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = minf(tam.x, tam.z) * 0.5
	cm.height = maxf(tam.y, cm.radius * 2.0 + 0.01)
	cm.radial_segments = 8
	cm.rings = 2
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)

func _process(delta: float) -> void:
	_fase += delta * _paso
	var a := sin(_fase) * 0.45
	if _piernas.size() == 2:
		_piernas[0].rotation.x = a
		_piernas[1].rotation.x = -a
		_brazos[0].rotation.x = -a * 0.8
		_brazos[1].rotation.x = a * 0.8
