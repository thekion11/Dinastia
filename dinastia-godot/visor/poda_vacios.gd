class_name PodaVacios
extends RefCounted
## (4-11, A4-REND) Al pasar sus mallas a un MultiMesh, `Optimizar.agrupar` dejaba cada edificio instanciado
## («building-c2»…) como un `Node3D` VACÍO colgando de la raíz: 3.260 nodos en la ciudad que no dibujan, no
## colisionan ni guardan nada. Aquí se quitan SOLO los que agrupar acaba de vaciar y que son un `Node3D` pelado:
## sin script, sin metadatos ni grupos. Devuelve cuántos quitó.

static func de(raiz: Node, candidatos: Array) -> int:
	var n := 0
	for c in candidatos:
		var x: Node = c
		while x != null and is_instance_valid(x) and x != raiz and x.get_class() == "Node3D" and x.get_child_count() == 0 \
				and x.get_script() == null and x.get_meta_list().is_empty() and x.get_groups().is_empty():
			var padre := x.get_parent()
			if padre == null:
				break
			padre.remove_child(x)
			x.free()
			n += 1
			x = padre
	return n
