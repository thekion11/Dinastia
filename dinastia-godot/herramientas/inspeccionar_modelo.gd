extends SceneTree
## Inspecciona un modelo 3D: huesos, mallas, altura, materiales.
## Uso: godot --headless --script herramientas/inspeccionar_modelo.gd -- res://ruta.glb

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for ruta: String in args:
		var ps = load(ruta)
		if ps == null:
			print("NO CARGA ", ruta)
			continue
		var n: Node = ps.instantiate()
		root.add_child(n)
		var esqs := n.find_children("*", "Skeleton3D", true, false)
		print("== ", ruta, " esqueletos=", esqs.size())
		for e in esqs:
			var sk := e as Skeleton3D
			var nombres := PackedStringArray()
			for i in mini(sk.get_bone_count(), 90):
				nombres.append(sk.get_bone_name(i))
			print("  ", sk.name, " huesos=", sk.get_bone_count(), " ", ", ".join(nombres))
		var ymin := 1e9
		var ymax := -1e9
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var bb := m.global_transform * m.get_aabb()
			ymin = minf(ymin, bb.position.y)
			ymax = maxf(ymax, bb.end.y)
			var mats := []
			for s in m.mesh.get_surface_count():
				var mt := m.get_active_material(s)
				mats.append(mt.resource_name if mt else "-")
			print("  malla ", m.name, " aabb_y=", snappedf(bb.position.y, 0.01), "..", snappedf(bb.end.y, 0.01), " mats=", mats)
		print("  altura aabb=", snappedf(ymax - ymin, 0.01), " escala_raiz=", (n as Node3D).scale if n is Node3D else "-")
		for ap in n.find_children("*", "AnimationPlayer", true, false):
			print("  anims: ", (ap as AnimationPlayer).get_animation_list())
	quit()
