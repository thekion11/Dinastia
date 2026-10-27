extends BaseIdea
## PEATONES QUE ABREN PUERTAS (27-10-2026): la hoja gira hacia dentro cuando alguien llega, el vecino la cruza y desaparece;
## otras veces sale. Nada de esto toca el azar de la partida.

func _probar() -> void:
	_titulo("PUERTAS · LOS VECINOS ABREN LA PUERTA, ENTRAN Y SALEN")
	var b := CityBuilder.new()
	add_child(b)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	add_child(ex)
	var pv := PuertaVida.new()
	pv.expl = ex
	add_child(pv)
	PuertaVida.registrar(b, Vector3(50, 0, 50), Vector3(0, 0, 1))
	_comprobar(b.puertas_vida.size() == 1, "la entrada queda registrada")
	## ENTRA
	pv.iniciar(0, true)
	_comprobar(pv._activas.size() == 1 and pv._hojas.has(0) and absf(pv.angulo(0)) < 0.01, "llega un vecino y la puerta está cerrada")
	var fig: Dictionary = (pv._activas[0] as Dictionary)["fig"]
	var nodo: Node3D = fig["nodo"]
	var lejos := nodo.position.distance_to(Vector3(50, 0, 50))
	pv._mover(3.0)
	_comprobar(nodo.position.distance_to(Vector3(50, 0, 50)) < lejos, "camina hacia la puerta")
	pv._mover(4.0)
	_comprobar((pv._hojas[0] as Dictionary)["objetivo"] == 1.0, "al llegar abre la puerta")
	pv._mover(1.0)
	_comprobar(pv.angulo(0) < -90.0, "la hoja gira hacia dentro (%.0f°)" % pv.angulo(0))
	pv._mover(1.5)
	_comprobar(pv._activas.is_empty() and (pv._hojas[0] as Dictionary)["objetivo"] == 0.0, "cruza el umbral, desaparece y la puerta se cierra")
	pv._mover(1.0)
	_comprobar(absf(pv.angulo(0)) < 0.5, "la hoja vuelve a quedar cerrada")
	## SALE
	pv.iniciar(0, false)
	_comprobar((pv._hojas[0] as Dictionary)["objetivo"] == 1.0, "quien sale abre la puerta")
	pv._mover(20.0)
	pv._mover(5.0)
	_comprobar(pv._activas.is_empty(), "sale a la calle y desaparece")
