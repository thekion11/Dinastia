extends BaseIdea
func _probar() -> void:
	CaraMalla._cargar()
	var nombres: Array = BibliotecaCaras._caras.keys()
	nombres.sort()
	for nombre: String in nombres.slice(0, 72):
		var m := CaraMalla.malla_de_prueba(nombre)
		var pos: PackedVector3Array = m[0]
		var idx: PackedInt32Array = m[1]
		var pos_n := 0
		var neg := 0
		for t in range(0, idx.size() - 2, 3):
			var a := pos[idx[t]]
			var c := (a + pos[idx[t + 1]] + pos[idx[t + 2]]) / 3.0
			var n := (pos[idx[t + 1]] - a).cross(pos[idx[t + 2]] - a)
			if absf(absf(c.x) - 0.0338) < 0.02 and absf(c.y - 1.69) < 0.02:
				if n.z > 0.0: pos_n += 1
				else: neg += 1
		var co := CaraMalla.centros_ojos(nombre)
		print("CARA %s +%d -%d centros %s" % [nombre, pos_n, neg, co])
