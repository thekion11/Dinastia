extends BaseIdea
## M-180 (3-11): carteles publicitarios en la pared del andén y megafonía en texto que rota en las pantallas.

func _probar() -> void:
	_titulo("P6: METRO · CARTELES Y MEGAFONIA EN TEXTO")
	var raiz := Node3D.new()
	add_child(raiz)
	var n := MetroPublicidad.carteles(raiz, Vector3(10, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 0), 0.0, 0)
	_comprobar(n == 3 and raiz.find_children("*", "Label3D", true, false).size() == 3, "tres carteles con su anunciante (%d)" % n)
	var l := raiz.find_children("*", "Label3D", true, false)[0] as Label3D
	_comprobar(absf(l.rotation.y) < 0.01 and not l.double_sided, "miran al andén y no se ven por detrás")
	var distintos := {}
	for t in 40:
		distintos[MetroPublicidad.mensaje(float(t) * MetroPublicidad.CADA)] = true
	_comprobar(distintos.size() == MetroPublicidad.MENSAJES.size(), "la megafonía rota por sus %d avisos" % distintos.size())
	_comprobar(MetroPublicidad.mensaje(0.0) == MetroPublicidad.mensaje(MetroPublicidad.CADA - 0.1), "cada aviso dura %d s" % int(MetroPublicidad.CADA))
