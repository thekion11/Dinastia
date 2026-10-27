extends BaseIdea
## P4 · SOMBRA DE CONTACTO (27-10-2026): cada peatón lleva una mancha suave bajo los pies, compartida y sin lanzar sombra.

func _probar() -> void:
	_titulo("P4 · SOMBRA DE CONTACTO BAJO LOS PEATONES")
	var raiz := Node3D.new()
	add_child(raiz)
	var a := PeatonVida.nuevo(raiz, 11)
	var b := PeatonVida.nuevo(raiz, 12)
	_comprobar(not a.is_empty() and not b.is_empty(), "nacen dos peatones")
	var ca := (a["nodo"] as Node3D).get_node_or_null("Contacto") as MeshInstance3D
	var cb := (b["nodo"] as Node3D).get_node_or_null("Contacto") as MeshInstance3D
	_comprobar(ca != null and cb != null, "los dos llevan la mancha de contacto")
	if ca != null and cb != null:
		_comprobar(ca.mesh == cb.mesh, "la malla y el material se comparten (coste mínimo)")
		_comprobar(ca.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and ca.visibility_range_end == 70.0, "no lanza sombra y desaparece a 70 m")
		_comprobar(absf(ca.position.y - 0.03) < 0.001, "queda a ras del suelo")
		var tex := ((ca.mesh as QuadMesh).material as StandardMaterial3D).albedo_texture as GradientTexture2D
		_comprobar(tex != null and tex.gradient.colors[0].a > 0.3 and tex.gradient.colors[2].a == 0.0, "es un degradado radial: oscuro al centro, transparente en el borde")
