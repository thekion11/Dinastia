class_name AbrigoDT
extends RefCounted
## EL FALDÓN DEL ABRIGO LARGO de `PersonajeDT` (20-11-2026): un tronco de cono oval, algo acampanado al bajar, que envuelve las caderas hasta la rodilla.
## Antes eran dos cajas rectas (un delantal rígido que acababa en línea recta). `cadera`: el hueso de la pelvis (`PersonajeDT._pegar`); `pano`: la tela.

static func faldon(cadera: Node3D, pano: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.height = 0.46
	cono.top_radius = 0.165
	cono.bottom_radius = 0.215
	cono.radial_segments = 20
	cono.rings = 1
	mi.mesh = cono
	mi.material_override = pano
	mi.position = Vector3(0.0, 0.72, 0.01)
	mi.scale = Vector3(1.0, 1.0, 0.78)   ## oval: más ancho que hondo, como las caderas
	cadera.add_child(mi)
	return mi
