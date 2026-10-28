extends BaseIdea
## M-170: semáforo peatonal con botón (hombrecito rojo/verde/intermitente y pulsador que adelanta el verde).

func _probar() -> void:
	_titulo("P6: SEMÁFOROS PEATONALES CON BOTÓN")
	var s := Semaforos.new()
	add_child(s)
	s.process_mode = Node.PROCESS_MODE_DISABLED
	s.montar([Vector3(0, 0, 0), Vector3(200, 0, 0)], null)
	_comprobar(s.botones.size() == 4, "cada cruce tiene dos postes con su botón (%d botones)" % s.botones.size())
	s.t = 1.0
	_comprobar(s.peatonal(0) == "v" and s.peatonal(1) == "r", "eje 0 en verde: su peatonal está en verde y la del otro eje en rojo")
	s.t = Semaforos.VERDE - 1.0
	_comprobar(s.peatonal(0) == "i", "los últimos %.0f s del verde el hombrecito parpadea" % Semaforos.INTERMITE)
	s.t = Semaforos.VERDE + Semaforos.AMBAR + 0.5
	_comprobar(s.peatonal(0) == "r", "con el ámbar y el todo rojo, rojo para los peatones")
	var falta := s.para_cruzar()
	_comprobar(falta > 0.0 and falta < Semaforos.CICLO * 0.5, "faltan %.1f s para el siguiente verde peatonal" % falta)
	_comprobar(s.pedir() == "espera", "el botón pide el verde")
	_comprobar(s.para_cruzar() <= 2.05, "y el verde llega en unos 2 s (%.1f)" % s.para_cruzar())
	s.t += 2.5
	_comprobar(s.pedir() == "ya", "con el verde puesto, el botón dice que ya se puede cruzar")
	_comprobar(s.boton_cerca(s.botones[0]) == 0.0 and s.boton_cerca(Vector3(60, 0, 60)) == INF, "se detecta el botón a menos de %.1f m y no a 60" % Semaforos.RADIO_BOTON)
