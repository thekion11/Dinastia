extends Node
func _ready() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	StadiumBuilder.build(raiz, {"forma": "cuenco", "niveles": 2, "techo": "anillo", "aforo": 40000}, 40000, 0.8, 4242, null)
	for n: Node in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		if String(n.name).contains("Acceso"):
			var m := n as MultiMeshInstance3D
			print(n.name, " ", m.multimesh.instance_count, " pos ", m.position)
			for k in mini(12, m.multimesh.instance_count):
				var t := m.multimesh.get_instance_transform(k)
				print("   ", t.origin, " esc ", t.basis.get_scale())
	for n: Node in raiz.find_children("VigasTecho", "MultiMeshInstance3D", true, false):
		var m := n as MultiMeshInstance3D
		print("vigas ", m.global_position, " ", m.multimesh.get_instance_transform(0).origin)
	get_tree().quit()
