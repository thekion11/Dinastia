class_name CabinaCoche
extends RefCounted
## LA CABINA DEL COCHE POR DENTRO (27-10-2026, pedido del dueño: «mejora el tema de la visión por dentro de los vehículos»).
## Antes: cajas planas sin luz, un pilar enorme que tapaba un tercio de la pantalla y un volante gris. Ahora: salpicadero con
## sus dos esferas (velocímetro y cuentarrevoluciones con marcas), pantalla central, ventilaciones, consola, paneles de puerta con
## reposabrazos, pilares finos, techo con luz de cortesía, parasoles, retrovisor y un volante de cuero con costuras. Todo son
## piezas sombreadas (no «sin luz») hijas de la cámara; medidas en metros desde los ojos del conductor (x derecha, y arriba, −z
## delante; el centro del coche queda 0,34 m a la derecha). `montar` devuelve {volante, kmh} para que `_cabina_3d` los mueva.

static var _mats := {}

static func _m(clave: String, c: Color, rug: float = 0.7, metal: float = 0.0, emi: float = 0.0) -> StandardMaterial3D:
	if not _mats.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rug
		m.metallic = metal
		if emi > 0.0:
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = emi
		else:
			## Un poco de luz propia: de noche o en sombra no se queda negro del todo.
			m.emission_enabled = true
			m.emission = c * 0.12
		_mats[clave] = m
	return _mats[clave]

static func _caja(padre: Node3D, tam: Vector3, pos: Vector3, mat: Material, giro: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = giro
	padre.add_child(mi)
	return mi

static func _cil(padre: Node3D, r: float, h: float, pos: Vector3, mat: Material, giro: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 20
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = giro
	padre.add_child(mi)
	return mi

static func _barra(padre: Node3D, a: Vector3, b: Vector3, grosor: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(grosor, a.distance_to(b), grosor)
	mi.mesh = bm
	mi.material_override = mat
	var eje := (b - a).normalized()
	var lado := eje.cross(Vector3.FORWARD)
	if lado.length() < 0.01:
		lado = eje.cross(Vector3.RIGHT)
	lado = lado.normalized()
	mi.transform = Transform3D(Basis(lado, eje, lado.cross(eje)), (a + b) * 0.5)
	padre.add_child(mi)

## Una esfera de instrumentos: fondo oscuro, aro cromado y 11 marcas en 270°. Mira al conductor (inclinada hacia atrás).
static func _esfera(padre: Node3D, pos: Vector3, r: float) -> void:
	var fondo := _m("esfera", Color(0.02, 0.025, 0.03), 0.4)
	var aro := _m("cromo", Color(0.75, 0.76, 0.78), 0.25, 0.9)
	var marca := _m("marca", Color(0.85, 0.95, 1.0), 0.4, 0.0, 1.2)
	var nodo := Node3D.new()
	nodo.position = pos
	nodo.rotation_degrees = Vector3(62.0, 0, 0)
	padre.add_child(nodo)
	_cil(nodo, r, 0.01, Vector3.ZERO, fondo)
	var tm := TorusMesh.new()
	tm.inner_radius = r * 0.93
	tm.outer_radius = r * 1.04
	var t := MeshInstance3D.new()
	t.mesh = tm
	t.material_override = aro
	nodo.add_child(t)
	for k in 11:
		var ang := deg_to_rad(-135.0 + float(k) * 27.0)
		var en := Vector3(sin(ang), 0.012, -cos(ang)) * r * 0.78
		var mc := _caja(nodo, Vector3(0.004, 0.003, r * 0.14 if k % 2 == 0 else r * 0.08), en, marca)
		mc.rotation.y = -ang
	var aguja := _caja(nodo, Vector3(0.004, 0.003, r * 0.8), Vector3(sin(deg_to_rad(-60.0)), 0.014, -cos(deg_to_rad(-60.0))) * r * 0.4, _m("aguja", Color(1.0, 0.3, 0.1), 0.4, 0.0, 1.5))
	aguja.rotation.y = deg_to_rad(60.0)

static func montar(cab: Node3D) -> Dictionary:
	var cuero := _m("cuero", Color(0.1, 0.1, 0.12), 0.6)
	var plastico := _m("plastico", Color(0.24, 0.25, 0.28), 0.55)
	var gris := _m("gris", Color(0.3, 0.31, 0.34), 0.5)
	var tela := _m("tela", Color(0.52, 0.52, 0.5), 0.9)
	var costura := _m("costura", Color(0.6, 0.55, 0.45), 0.8)
	var negro := _m("negro", Color(0.015, 0.015, 0.02), 0.3)
	var cromo := _m("cromo", Color(0.75, 0.76, 0.78), 0.25, 0.9)
	var pantalla := _m("pantalla", Color(0.06, 0.2, 0.32), 0.2, 0.0, 0.45)
	## SALPICADERO: tapa que baja hacia el conductor, con una costura, y la cara vertical que da a él (más clara).
	_caja(cab, Vector3(1.76, 0.05, 0.5), Vector3(0.34, -0.205, -0.9), cuero)
	_caja(cab, Vector3(1.76, 0.012, 0.012), Vector3(0.34, -0.2, -0.7), costura)
	_caja(cab, Vector3(1.76, 0.3, 0.05), Vector3(0.34, -0.37, -0.66), plastico)
	## Cuadro de instrumentos bajo una visera: velocímetro y cuentarrevoluciones, y una pantalla digital entre ambos.
	_caja(cab, Vector3(0.62, 0.04, 0.12), Vector3(0.0, -0.19, -0.7), negro)
	_esfera(cab, Vector3(-0.16, -0.255, -0.64), 0.075)
	_esfera(cab, Vector3(0.16, -0.255, -0.64), 0.075)
	_caja(cab, Vector3(0.1, 0.05, 0.004), Vector3(0.0, -0.245, -0.64), pantalla)
	## Pantalla central, ventilaciones y consola.
	_caja(cab, Vector3(0.3, 0.17, 0.02), Vector3(0.34, -0.3, -0.62), negro)
	_caja(cab, Vector3(0.26, 0.14, 0.004), Vector3(0.34, -0.3, -0.608), pantalla)
	for vx: float in [-0.46, 1.14, 0.12, 0.56]:
		for rejilla in 3:
			_caja(cab, Vector3(0.09, 0.006, 0.01), Vector3(vx, -0.3 - float(rejilla) * 0.016, -0.632), negro)
	_caja(cab, Vector3(0.27, 0.22, 0.6), Vector3(0.34, -0.66, -0.25), plastico)
	_cil(cab, 0.022, 0.16, Vector3(0.34, -0.47, -0.33), cromo)
	_cil(cab, 0.04, 0.05, Vector3(0.34, -0.38, -0.33), cuero)
	_caja(cab, Vector3(0.26, 0.05, 0.28), Vector3(0.34, -0.54, 0.1), cuero)
	## Puertas: panel con la manilla y el reposabrazos, y el borde de la ventanilla.
	for lado: float in [-1.0, 1.0]:
		var x := 0.34 + lado * 0.9
		_caja(cab, Vector3(0.07, 0.55, 1.3), Vector3(x, -0.44, -0.12), plastico)
		_caja(cab, Vector3(0.09, 0.05, 1.3), Vector3(x - lado * 0.01, -0.17, -0.12), negro)
		_caja(cab, Vector3(0.12, 0.05, 0.45), Vector3(x - lado * 0.06, -0.33, -0.05), cuero)
		_caja(cab, Vector3(0.03, 0.03, 0.18), Vector3(x - lado * 0.05, -0.24, 0.18), cromo)
	## Pilares delanteros finos y larguero del techo (antes, un pilar de 7 cm a 40 cm del ojo tapaba media pantalla).
	_barra(cab, Vector3(-0.66, -0.17, -0.98), Vector3(-0.62, 0.33, -0.46), 0.026, plastico)
	_barra(cab, Vector3(1.34, -0.17, -0.98), Vector3(1.30, 0.33, -0.46), 0.026, plastico)
	_caja(cab, Vector3(1.8, 0.02, 0.04), Vector3(0.34, 0.345, -0.46), tela)
	_caja(cab, Vector3(1.7, 0.02, 1.0), Vector3(0.34, 0.38, 0.1), tela)
	_caja(cab, Vector3(0.12, 0.012, 0.08), Vector3(0.34, 0.365, 0.1), _m("luz", Color(1, 0.95, 0.85), 0.3, 0.0, 1.5))
	## Parasoles y retrovisor.
	_caja(cab, Vector3(0.28, 0.01, 0.14), Vector3(-0.15, 0.385, -0.3), tela)
	_caja(cab, Vector3(0.28, 0.01, 0.14), Vector3(0.83, 0.385, -0.3), tela)
	_caja(cab, Vector3(0.15, 0.04, 0.02), Vector3(0.34, 0.27, -0.62), negro, Vector3(0, -10, 0))
	_caja(cab, Vector3(0.012, 0.05, 0.012), Vector3(0.34, 0.305, -0.61), plastico)
	## EL VOLANTE (en su sitio de siempre: `(0, -0.3, -0.5)`, radio 18 cm): aro de cuero con tres radios y buje con logotipo.
	var volante := Node3D.new()
	volante.position = Vector3(0.0, -0.3, -0.5)
	cab.add_child(volante)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.16
	tm.outer_radius = 0.2
	tm.rings = 28
	tm.ring_segments = 10
	var aro := MeshInstance3D.new()
	aro.mesh = tm
	aro.material_override = cuero
	volante.add_child(aro)
	for ang: float in [90.0, 210.0, 330.0]:
		var radio := _caja(volante, Vector3(0.03, 0.022, 0.16), Vector3(sin(deg_to_rad(ang)), 0, cos(deg_to_rad(ang))) * 0.085, plastico)
		radio.rotation_degrees = Vector3(0, ang, 0)
	_cil(volante, 0.058, 0.05, Vector3.ZERO, plastico)
	_cil(volante, 0.026, 0.056, Vector3.ZERO, cromo)
	_caja(volante, Vector3(0.012, 0.01, 0.045), Vector3(0, 0, -0.18), costura)         ## marca de las 12
	## El velocímetro digital (entre las dos esferas); el texto lo pone `_cabina_3d` cada fotograma.
	var kmh := Label3D.new()
	kmh.font_size = 40
	kmh.pixel_size = 0.00055
	kmh.modulate = Color(0.55, 0.95, 0.8)
	kmh.outline_size = 0
	kmh.position = Vector3(0.0, -0.245, -0.636)
	kmh.rotation_degrees = Vector3(0, 0, 0)
	kmh.no_depth_test = false
	cab.add_child(kmh)
	return {"volante": volante, "kmh": kmh}
