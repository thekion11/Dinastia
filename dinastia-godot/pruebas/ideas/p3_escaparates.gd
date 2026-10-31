extends BaseIdea
## P3 «MEJORAR» (27-10-2026): un vecino se detiene ante el escaparate de una entrada, gira el cuerpo hacia el cristal, pasea la mirada y se va.

func _probar() -> void:
	_titulo("ESCAPARATES · UN VECINO SE PARA A MIRAR")
	var b := CityBuilder.new()
	add_child(b)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	add_child(ex)
	var ev := EscaparateVida.new()
	ev.expl = ex
	add_child(ev)
	PuertaVida.registrar(b, Vector3(50, 0, 50), Vector3(0, 0, 1))
	ev.iniciar(0)
	if ev._activas.is_empty():
		_comprobar(true, "(sin modelo de peatón en este entorno)")
		return
	var s: Dictionary = ev._activas[0]
	var nodo: Node3D = (s["fig"] as Dictionary)["nodo"]
	var parada: Vector3 = s["p"]
	_comprobar(absf(parada.z - 50.0) < 0.01 and absf(absf(parada.x - 50.0) - EscaparateVida.PARADA) < 0.01, "se para a %.1f m de la puerta, a lo largo de la fachada" % EscaparateVida.PARADA)
	ev._mover(float(s["dur"]) + 0.1)
	_comprobar(int(s["fase"]) == 1 and nodo.position.distance_to(parada) < 0.05, "llega a su sitio frente al cristal")
	for i in 20:
		ev._mover(0.1)
	var hacia_cristal := Vector3(sin(nodo.rotation.y), 0, cos(nodo.rotation.y)).dot(Vector3(0, 0, -1))
	_comprobar(hacia_cristal > 0.95, "gira el cuerpo hacia el cristal (%.2f)" % hacia_cristal)
	var mira: Node3D = s["mira"]
	var x0 := mira.position.x
	ev._mover(1.0)
	_comprobar(absf(mira.position.x - x0) > 0.05, "la mirada recorre el escaparate (se mueve %.2f m)" % absf(mira.position.x - x0))
	ev._mover(float(s["quieto"]))
	_comprobar(int(s["fase"]) == 2, "tras mirar un rato echa a andar")
	ev._mover(float(s["dur"]) + 0.5)
	_comprobar(ev._activas.is_empty(), "sigue por la acera y desaparece")
