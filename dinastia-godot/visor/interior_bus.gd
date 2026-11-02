class_name InteriorBus
extends RefCounted
## LA GENTE DENTRO DEL AUTOBÚS (27-10-2026): los cristales son semitransparentes y algo tintados, y por dentro hay hasta
## `PLAZAS` siluetas sentadas (cuerpo y cabeza, una malla cada una, sin esqueleto) que se encienden según `meta "pasajeros"`
## del autobús (las semillas de `PasajerosBus`): cada pasajero que sube se ve sentarse en su sitio y el que baja se apaga.
const PLAZAS := 10

## Cristal tintado y semitransparente (sin escribir en profundidad para no tapar a los de dentro).
static func vidrio() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.16, 0.24, 0.28, 0.32)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.06
	m.metallic = 0.3
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m

## Mallas y materiales COMPARTIDOS por todos los autobuses (antes cada autobús creaba los suyos).
static var _cuerpo: CapsuleMesh
static var _cabeza: SphereMesh
static var _banco: BoxMesh
static var _mat_asiento: StandardMaterial3D
static var _mat_piel: StandardMaterial3D

static func _compartidos() -> void:
	if _banco != null:
		return
	_mat_asiento = StandardMaterial3D.new()
	_mat_asiento.albedo_color = Color(0.2, 0.22, 0.3)
	_mat_asiento.roughness = 0.8
	_mat_piel = StandardMaterial3D.new()
	_mat_piel.albedo_color = Color(0.8, 0.62, 0.5)
	_cuerpo = CapsuleMesh.new()
	_cuerpo.radius = 0.2
	_cuerpo.height = 0.75
	_cabeza = SphereMesh.new()
	_cabeza.radius = 0.12
	_cabeza.height = 0.24
	_banco = BoxMesh.new()
	_banco.size = Vector3(0.5, 0.12, 0.5)

static func _pos_plaza(k: int) -> Vector3:
	return Vector3(-0.8 if k % 2 == 0 else 0.8, 1.6, -4.6 + 1.8 * float(k / 2))

## Monta los asientos (una sola malla) dentro del autobús. Dos filas pegadas a las ventanas. Las siluetas de los pasajeros NO se
## crean aquí: `actualizar` las crea la primera vez que alguien ocupa esa plaza (M-476: ~40 nodos menos por autobús vacío).
static func montar(bus: Node3D) -> void:
	_compartidos()
	var interior := Node3D.new()
	interior.name = "Interior"
	bus.add_child(interior)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in PLAZAS:
		st.append_from(_banco, 0, Transform3D(Basis.IDENTITY, _pos_plaza(k) + Vector3(0, 0.45, 0)))
	var asientos := MeshInstance3D.new()
	asientos.name = "Asientos"
	asientos.mesh = st.commit()
	asientos.material_override = _mat_asiento
	interior.add_child(asientos)

## La plaza `k` con su silueta (cuerpo y cabeza), creada al vuelo.
static func _persona(interior: Node, k: int) -> Node3D:
	var plaza := interior.get_node_or_null("Plaza%d" % k) as Node3D
	if plaza != null:
		return plaza.get_node("Persona")
	plaza = Node3D.new()
	plaza.name = "Plaza%d" % k
	plaza.position = _pos_plaza(k)
	interior.add_child(plaza)
	var persona := Node3D.new()
	persona.name = "Persona"
	plaza.add_child(persona)
	var c := MeshInstance3D.new()
	c.mesh = _cuerpo
	c.position = Vector3(0, 0.8, 0)
	persona.add_child(c)
	var h := MeshInstance3D.new()
	h.mesh = _cabeza
	h.material_override = _mat_piel
	h.position = Vector3(0, 1.25, 0)
	persona.add_child(h)
	return persona

## Enciende una silueta por pasajero (ropa de un color apagado sacado de su semilla) y apaga el resto.
static func actualizar(bus: Node3D) -> void:
	var interior := bus.get_node_or_null("Interior")
	if interior == null:
		return
	var abordo: Array = bus.get_meta("pasajeros", [])
	for k in PLAZAS:
		var sube := k < abordo.size()
		if not sube and interior.get_node_or_null("Plaza%d" % k) == null:
			continue   ## nunca se sentó nadie ahí: no hay silueta que apagar
		var persona := _persona(interior, k)
		persona.visible = sube
		if persona.visible:
			var cuerpo: MeshInstance3D = persona.get_child(0)
			var h := hash([int(abordo[k]), 7])
			var m := cuerpo.material_override as StandardMaterial3D
			if m == null:
				m = StandardMaterial3D.new()
				cuerpo.material_override = m
			m.albedo_color = Color.from_hsv(float(absi(h) % 360) / 360.0, 0.35, 0.55)
