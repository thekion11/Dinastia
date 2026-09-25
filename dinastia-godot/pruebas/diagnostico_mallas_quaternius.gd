extends Node
## Paso 1 para adaptar `Vestidor.vestir()` al modelo Quaternius: cuales son sus
## mallas y materiales de verdad -mismo metodo que ya uso `Vestidor` con el
## modelo viejo ("QUE MALLA ES QUE... sacado con scripts/debug_materiales.gd,
## no adivinado")-, no adivinar nombres.

func _ready() -> void:
	var d := FutbolistaQ.crear(1.80, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	_listar(d["modelo"], 0)
	print("FIN. 0 fallos")
	get_tree().quit(0)

func _listar(n: Node, prof: int) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		print("  ".repeat(prof), "MALLA ", mi.name, " (mesh=", mi.mesh.resource_path if mi.mesh else "?", ")")
		for s in range(mi.mesh.get_surface_count() if mi.mesh else 0):
			var m: Material = mi.get_active_material(s)
			if m is StandardMaterial3D:
				var sm := m as StandardMaterial3D
				var t := sm.albedo_texture
				print("  ".repeat(prof + 1), "sup", s, ": tex=", (t.resource_path if t else "ninguna"),
					" size=", (Vector2(t.get_width(), t.get_height()) if t else Vector2.ZERO),
					" color=", sm.albedo_color)
			else:
				print("  ".repeat(prof + 1), "sup", s, ": material tipo ", m)
	for c in n.get_children():
		_listar(c, prof + 1)
