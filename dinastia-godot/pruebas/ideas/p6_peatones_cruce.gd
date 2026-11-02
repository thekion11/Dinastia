extends BaseIdea
## Peatones NPC que cruzan una avenida: esperan en el bordillo mientras su cabeza peatonal no está en verde fijo y cruzan cuando sí.

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("P6: PEATONES NPC RESPETAN LA FASE PEATONAL")
	var p := Vector3.ZERO
	var ctl := PeatonesCruce.controles(p)
	_comprobar(ctl.size() == 4 and int(ctl[0]["eje"]) == 1 and int(ctl[1]["eje"]) == 0 and int(ctl[2]["eje"]) == 1 and int(ctl[3]["eje"]) == 0, "cuatro pasos: los lados en x los gobierna el eje 1 y los de z el eje 0")
	seed(5)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var sem := Semaforos.new()
	t.semaforos = sem
	var id := t.agregar_ruta(PeatonesCruce.esquinas(p))
	for c: Dictionary in ctl:
		t.agregar_control(id, float(c["s"]), int(c["eje"]))
	t.agregar_vehiculo(Node3D.new(), id, 0.0, 1.3)
	var v: Dictionary = t._vehiculos[0]
	v["peaton"] = true
	## Primer lado (en x, eje 1): con el eje 1 en rojo para peatones (t = 1 → eje 0 en verde, peatonal(1) en rojo) NO cruza.
	sem.t = 1.0
	_comprobar(sem.peatonal(1) == "r", "preparado: la peatonal del eje 1 está en rojo")
	var s_ant := float(v["s"])
	for i in 300:
		sem.t = 1.0   ## congelado en esa fase
		t._process(DT)
	var lado := PeatonesCruce.esquinas(p)[0].distance_to(PeatonesCruce.esquinas(p)[1])
	var parada := float(ctl[0]["s"])
	_comprobar(float(v["s"]) <= parada + 0.1 and float(v["s"]) > parada - 1.5, "con la peatonal en rojo espera en la línea (s = %.2f de %.2f)" % [float(v["s"]), parada])
	## Con el eje 1 en verde (peatonal(1) = verde fijo) cruza el lado entero.
	sem.t = Semaforos.CICLO * 0.5 + 1.0
	_comprobar(sem.peatonal(1) == "v", "ahora la peatonal del eje 1 está en verde")
	for i in 200:
		sem.t = Semaforos.CICLO * 0.5 + 1.0
		t._process(DT)
	_comprobar(float(v["s"]) > parada + 5.0, "y cruza (s = %.1f; el lado mide %.1f m)" % [float(v["s"]), lado])
	## Tráfico de la rotonda: la ruta es cerrada, antihoraria y los coches avanzan por ella.
	var pts := CiudadRotonda.carril()
	var giro := 0.0
	for i in pts.size():
		var a := pts[i] - CiudadRotonda.CENTRO
		var b := pts[(i + 1) % pts.size()] - CiudadRotonda.CENTRO
		giro += Vector2(a.x, a.z).angle_to(Vector2(b.x, b.z))
	_comprobar(giro < -TAU + 0.1, "el carril de la rotonda da una vuelta antihoraria vista desde arriba (%.2f rad)" % giro)
	var t2 := TraficoCiudad.new()
	add_child(t2)
	t2.set_process(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var coches := CityBuilder.flota_coches()
	var n := CiudadRotonda.trafico(null, t2, coches, rng)
	_comprobar(n == CiudadRotonda.COCHES and t2._vehiculos.size() == n, "tres coches dan vueltas a la rotonda (%d)" % n)
	var s0 := float(t2._vehiculos[0]["s"])
	for i in 90:
		t2._process(DT)
	_comprobar(float(t2._vehiculos[0]["s"]) != s0, "y avanzan por el carril")
