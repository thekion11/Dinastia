class_name ModeloCC0
extends RefCounted
## MUEBLES CC0 DE POLY HAVEN (10-11-2026, orden del líder/dueño: «muebles reales en lugar de cajas»). Modelos glTF 1K (~9 000 triángulos, sin
## clave; `herramientas/bajar_cc0_modelos.py`, licencia en LICENCIAS.md) en `assets/cc0_modelos/<id>/`. Solo MEDIA y ALTA (`VestuarioRealista.activo`);
## en el resto, o sin el recurso, devuelve null y quien llama pone el mueble de siempre. Origen en el suelo, centrado; se escala a `alto` metros
## y lleva su caja de choque (la del AABB real), igual que `SillonOficina`.
static var _escenas := {}

static func poner(nodo: Node3D, ident: String, pos: Vector3, giro: float, alto: float, solido := true) -> Node3D:
	if not VestuarioRealista.activo() or OS.get_environment("SIN_MUEBLES_CC0") != "":
		return null
	var esc: PackedScene = _escenas.get(ident)
	if esc == null:
		var ruta := "res://assets/cc0_modelos/%s/%s_1k.gltf" % [ident, ident]
		if not ResourceLoader.exists(ruta):
			return null
		esc = load(ruta) as PackedScene
		_escenas[ident] = esc
	if esc == null:
		return null
	var n := esc.instantiate() as Node3D
	n.name = "CC0_" + ident
	var caja := AABB()
	var primero := true
	for mi: Node in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var a := m.global_transform * m.get_aabb() if m.is_inside_tree() else m.transform * m.get_aabb()
		caja = a if primero else caja.merge(a)
		primero = false
	if primero or caja.size.y < 0.01:
		n.free()
		return null
	var k := alto / caja.size.y
	n.scale = Vector3.ONE * k
	n.position = pos - Vector3(0, caja.position.y * k, 0)
	n.rotation.y = giro
	nodo.add_child(n)
	if solido:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = caja.size
		forma.shape = bs
		forma.position = caja.get_center()
		cuerpo.add_child(forma)
		n.add_child(cuerpo)
	return n
