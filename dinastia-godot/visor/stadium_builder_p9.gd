extends "res://visor/stadium_builder_p8.gd"
## (Parte 9 de 11 de `stadium_builder.gd`.)

## UNA SOLA MALLA PARA LAS SOMBRAS (16-10-2026, `pruebas/medir_partido` con
## ARBOL=1: el sol eran ~190 de las ~450 llamadas del plano de TV). Cada pieza
## fija del estadio que proyecta sombra se dibujaba otra vez en cada una de las
## 4 cascadas. Aquí se juntan todas en una malla invisible que SOLO proyecta
## sombra (misma forma, mismo sitio: la sombra no cambia) y las piezas dejan de
## proyectarla. Fuera: lo que se mueve (cualquier antepasado con script o con
## AnimationPlayer), lo que deforma su forma en el shader (banderas) y lo que
## tiene distancia de dibujo propia. SIN_SOMBRA_UNICA=1 lo apaga para medir.
static func _sombra_unica(root: Node3D) -> void:
	const SECTORES := 8
	var caras: Array = []
	for _k in SECTORES:
		caras.append(PackedVector3Array())
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.visible or mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
			continue
		if mi.visibility_range_end > 0.0 or mi.visibility_range_begin > 0.0 or mi.skin != null:
			continue
		if mi.material_override is ShaderMaterial or (mi.mesh.get_surface_count() > 0 and mi.get_active_material(0) is ShaderMaterial):
			continue
		var fijo := true
		var t := Transform3D.IDENTITY
		var q: Node = mi
		while q != null and q != root:
			if q.get_script() != null or q is Skeleton3D or (q is Node3D and not (q as Node3D).visible):
				fijo = false
				break
			for h in q.get_children():
				if h is AnimationPlayer:
					fijo = false
			if not fijo:
				break
			if q is Node3D:
				t = (q as Node3D).transform * t
			q = q.get_parent()
		if not fijo or q != root:
			continue
		## Lo que está a ras de suelo (césped, explanada, líneas) no da sombra
		## que se vea y, metido aquí, se la daba a sí mismo (césped más oscuro).
		var caja := t * mi.get_aabb()
		if caja.end.y < 0.4:
			continue
		## Sector por el ángulo del centro de la pieza: cada cascada del sol
		## recorta los sectores que no ve, como hacía con las piezas sueltas.
		var c := caja.get_center()
		var k := int(floor((atan2(c.z, c.x) + PI) / TAU * SECTORES)) % SECTORES
		var f := mi.mesh.get_faces()
		var dest: PackedVector3Array = caras[k]
		for v in f:
			dest.append(t * v)
		caras[k] = dest
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	## Una cara, como las piezas originales (con doble cara los techos planos
	## daban sombra que antes no daban y el césped salía más oscuro).
	var m := StandardMaterial3D.new()
	for k in SECTORES:
		if (caras[k] as PackedVector3Array).is_empty():
			continue
		var am := ArrayMesh.new()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = caras[k]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var sombra := MeshInstance3D.new()
		sombra.name = "SombraUnica%d" % k
		sombra.mesh = am
		sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		sombra.material_override = m
		root.add_child(sombra)
