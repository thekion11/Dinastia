extends "res://visor/personaje_dt_p1_p1.gd"
## [Capa 2/3 de `personaje_dt.gd`] _ojos_vivos, _esfera

## OJOS DE VERDAD también con la cara clásica (13-10-2026): eran ranuras
## blancas. El shader de ojos (iris, párpados de su piel) y, con él, el
## parpadeo y las expresiones (`Expresion`).
static func _ojos_vivos(d: Dictionary, piel: Color, iris := Color(0.24, 0.16, 0.1), propio := true) -> void:
	for mi: MeshInstance3D in (d["nodo"] as Node).find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s)
			var actual := mi.get_surface_override_material(s)
			if base == null or base.resource_name != VestidorQ.MATERIAL_OJOS:
				continue
			if actual is ShaderMaterial and not propio:
				continue
			if actual is ShaderMaterial:
				## Cara de biblioteca: ya tiene el shader (compartido); uno propio con tu iris.
				var copia := (actual as ShaderMaterial).duplicate() as ShaderMaterial
				copia.set_shader_parameter("iris", iris)
				mi.set_surface_override_material(s, copia)
				continue
			VestidorQ._con_reposo_simple(mi)
			var mujer := (d["nodo"] as Node).find_child("Superhero_Female", true, false) != null
			mi.set_surface_override_material(s, material_ojos(piel, iris, mujer))

static func _esfera(padre: Node3D, pos: Vector3, r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.material_override = m
	mi.position = pos
	padre.add_child(mi)
	return mi
