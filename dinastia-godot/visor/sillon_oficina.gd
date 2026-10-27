class_name SillonOficina
extends RefCounted
## EL SILLÓN DE OFICINA DEL DRIVE (27-10-2026, regalo del dueño: `assets/regalos/sillon_oficina.glb`, ~4 700 triángulos, 0,62 × 1,0 × 0,6 m, cuero
## marrón con ruedas y reposabrazos): el sillón del despacho del DT y el del presidente (`EdificioClub`), en lugar del «chairDesk» del kit y de la
## caja roja que hacía de sillón. Mira a +Z; origen en el suelo, centrado. Sin el recurso devuelve null y quien llama pone lo de antes.
const RUTA := "res://assets/regalos/sillon_oficina.glb"

static var _escena: PackedScene = null
static var _probada := false

static func poner(nodo: Node3D, pos: Vector3, giro: float, con_cuerpo := true) -> Node3D:
	if OS.get_environment("SIN_SILLON_DRIVE") != "":   ## para medir antes/después
		return null
	if not _probada:
		_probada = true
		if ResourceLoader.exists(RUTA):
			_escena = load(RUTA) as PackedScene
	if _escena == null:
		return null
	var n := _escena.instantiate() as Node3D
	n.name = "SillonOficina"
	n.position = pos
	n.rotation.y = giro
	for mi: Node in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	nodo.add_child(n)
	if con_cuerpo:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.62, 1.0, 0.6)
		forma.shape = bs
		forma.position = Vector3(0, 0.5, 0)
		cuerpo.add_child(forma)
		n.add_child(cuerpo)
	return n
