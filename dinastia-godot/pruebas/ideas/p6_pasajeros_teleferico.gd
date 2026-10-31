extends BaseIdea
## La gente del teleférico (orden del líder): al llegar la cabina abajo bajan dos personas y, unos segundos después, suben otras dos.

func _probar() -> void:
	_titulo("P6: PASAJEROS DEL TELEFÉRICO")
	var raiz := Node3D.new()
	add_child(raiz)
	var cam := Camera3D.new()
	raiz.add_child(cam)
	cam.make_current()
	var tele := Teleferico.new()
	tele.process_mode = Node.PROCESS_MODE_DISABLED   ## sin cable ni cabinas: solo se usa su reloj
	raiz.add_child(tele)
	var est := Node3D.new()
	raiz.add_child(est)
	var pt := PasajerosTeleferico.crear(tele, est)
	tele._t = PasajerosTeleferico.llegada() + 0.2
	pt._process(0.05)
	_comprobar(pt._andando.is_empty(), "antes de los 0,5 s de la llegada aún no sale nadie")
	tele._t = PasajerosTeleferico.llegada() + 1.0
	pt._process(0.05)
	_comprobar(pt._andando.size() == 2, "al llegar la cabina bajan dos personas (%d)" % pt._andando.size())
	tele._t = PasajerosTeleferico.llegada() + 5.0
	pt._process(0.05)
	_comprobar(pt._andando.size() == 4, "unos segundos después suben otras dos (%d en marcha)" % pt._andando.size())
	var antes := pt._andando.size()
	tele._t = PasajerosTeleferico.llegada() + 5.2
	pt._process(0.05)
	_comprobar(pt._andando.size() == antes, "no se repiten en el mismo ciclo")
	for i in 40:
		pt._process(1.0)
	_comprobar(pt._andando.is_empty(), "al llegar a su sitio (plaza o puerta) las figuras desaparecen")
	tele._t = PasajerosTeleferico.llegada() + 1.0 + Teleferico.CICLO
	pt._process(0.05)
	_comprobar(pt._andando.size() == 2, "en el ciclo siguiente vuelve a haber gente")
	cam.global_position = Vector3(9000, 0, 0)
	var n0 := pt._andando.size()
	tele._t += Teleferico.CICLO
	pt._process(0.05)
	_comprobar(pt._andando.size() == n0, "con la cámara lejos no se monta gente")
