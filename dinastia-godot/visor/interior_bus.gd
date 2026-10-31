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

## Monta las plazas (asientos y siluetas, ocultas) dentro del autobús. Dos filas de asientos pegadas a las ventanas.
static func montar(bus: Node3D) -> void:
	var asiento := StandardMaterial3D.new()
	asiento.albedo_color = Color(0.2, 0.22, 0.3)
	asiento.roughness = 0.8
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.8, 0.62, 0.5)
	var interior := Node3D.new()
	interior.name = "Interior"
	bus.add_child(interior)
	var cuerpo := CapsuleMesh.new()
	cuerpo.radius = 0.2
	cuerpo.height = 0.75
	var cabeza := SphereMesh.new()
	cabeza.radius = 0.12
	cabeza.height = 0.24
	var banco := BoxMesh.new()
	banco.size = Vector3(0.5, 0.12, 0.5)
	for k in PLAZAS:
		var x := -0.8 if k % 2 == 0 else 0.8
		var z := -4.6 + 1.8 * float(k / 2)
		var plaza := Node3D.new()
		plaza.name = "Plaza%d" % k
		plaza.position = Vector3(x, 1.6, z)
		interior.add_child(plaza)
		var s := MeshInstance3D.new()
		s.mesh = banco
		s.material_override = asiento
		s.position = Vector3(0, 0.45, 0)
		plaza.add_child(s)
		var persona := Node3D.new()
		persona.name = "Persona"
		persona.visible = false
		plaza.add_child(persona)
		var c := MeshInstance3D.new()
		c.mesh = cuerpo
		c.position = Vector3(0, 0.8, 0)
		persona.add_child(c)
		var h := MeshInstance3D.new()
		h.mesh = cabeza
		h.material_override = piel
		h.position = Vector3(0, 1.25, 0)
		persona.add_child(h)

## Enciende una silueta por pasajero (ropa de un color apagado sacado de su semilla) y apaga el resto.
static func actualizar(bus: Node3D) -> void:
	var interior := bus.get_node_or_null("Interior")
	if interior == null:
		return
	var abordo: Array = bus.get_meta("pasajeros", [])
	for k in PLAZAS:
		var persona: Node3D = interior.get_node("Plaza%d/Persona" % k)
		persona.visible = k < abordo.size()
		if persona.visible:
			var cuerpo: MeshInstance3D = persona.get_child(0)
			var h := hash([int(abordo[k]), 7])
			var m := cuerpo.material_override as StandardMaterial3D
			if m == null:
				m = StandardMaterial3D.new()
				cuerpo.material_override = m
			m.albedo_color = Color.from_hsv(float(absi(h) % 360) / 360.0, 0.35, 0.55)
