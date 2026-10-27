extends BaseIdea
## LA ESTACIÓN CENTRAL CON TRENES (27-10-2026): vías, andén, túnel y dos trenes que entran, esperan y salen desfasados.

func _probar() -> void:
	_titulo("CIUDAD · ESTACIÓN CENTRAL CON TRENES")
	var b := CityBuilder.new()
	add_child(b)
	var m := StandardMaterial3D.new()
	var est := EstacionCentral.montar(b, Vector3(110, 0.2, -550), 96.0, 96.0, {"claro": m, "vidrio": m, "piedra": m})
	_comprobar(est.cuenta["trenes"] == 2 and est.cuenta["tramos"] >= 8, "dos vías con %d tramos del kit y un tren en cada una" % est.cuenta["tramos"])
	var p0 := est.posicion_tren(0, 0.0)
	_comprobar(bool(p0["visible"]) and not bool(p0["parado"]), "al empezar, el tren 1 está llegando por el túnel")
	var p1 := est.posicion_tren(0, EstacionCentral.LLEGADA + 5.0)
	_comprobar(bool(p1["parado"]) and is_equal_approx(float(p1["z"]), float(est._trenes[0]["z1"])), "luego espera parado en el andén")
	var p2 := est.posicion_tren(0, EstacionCentral.CICLO - 3.0)
	_comprobar(not bool(p2["visible"]), "y al final del ciclo la vía queda vacía")
	var q0 := est.posicion_tren(1, 0.0)
	_comprobar(bool(q0["parado"]) and bool(p0["parado"]) == false, "el segundo tren va desfasado media vuelta")
	var dentro := true
	for k in 70:
		var pk := est.posicion_tren(0, float(k))
		var z: float = pk["z"]
		dentro = dentro and z >= float(est._trenes[0]["z0"]) - 0.01 and z <= float(est._trenes[0]["z1"]) + 0.01
	_comprobar(dentro, "el tren nunca se sale de la vía (ni atraviesa el tope)")
	est._process(10.0)
	_comprobar((est._trenes[0]["nodo"] as Node3D).position.z > float(est._trenes[0]["z0"]), "con el tiempo el nodo del tren avanza")
	_comprobar(est.get_child_count() > 35, "estación levantada (%d piezas)" % est.get_child_count())
