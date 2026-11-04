extends BaseIdea
## M-197 (3-11): peajes en las rampas de la autopista: se montan 4, cobran solo al subir en coche por la rampa y dentro de su anchura.

func _probar() -> void:
	_titulo("P6: PEAJES DE LA AUTOPISTA")
	var b := CityBuilder.new()
	add_child(b)
	var enlaces := [Vector3(0, 0, -Autopista.R), Vector3(0, 0, Autopista.R), Vector3(Autopista.R, 0, 0), Vector3(-Autopista.R, 0, 0)]
	Peaje.montar(b, enlaces, Autopista.ALTO, Autopista.ANCHO, Autopista.RAMPA)
	_comprobar(Peaje.puntos.size() == 4, "un peaje por rampa (%d)" % Peaje.puntos.size())
	var carteles := 0
	for l in b.find_children("*", "Label3D", true, false):
		if (l as Label3D).text.contains("PEAJE") or (l as Label3D).text.contains("TOLL"):
			carteles += 1
	_comprobar(carteles == 4, "cada uno con su cartel (%d)" % carteles)
	var pu: Dictionary = Peaje.puntos[0]   ## rampa del norte: n apunta a la ciudad (+z)
	var p: Vector3 = pu["p"]
	var n: Vector3 = pu["n"]
	var lat := Vector3(-n.z, 0, n.x)
	_comprobar(Peaje.sube(pu, p + n * 3.0, p - n * 1.0), "subiendo (de la ciudad hacia el anillo) cobra")
	_comprobar(not Peaje.sube(pu, p - n * 3.0, p + n * 1.0), "bajando no cobra")
	_comprobar(not Peaje.sube(pu, p + n * 3.0 + lat * 12.0, p - n * 1.0 + lat * 12.0), "fuera de la anchura de la rampa no cobra")
	_comprobar(not Peaje.sube(pu, p + n * 60.0, p - n * 1.0), "un salto largo (teletransporte) no cobra")
	_comprobar(not Peaje.sube(pu, p + n * 3.0, p + n * 1.0), "sin cruzar la línea no cobra")
