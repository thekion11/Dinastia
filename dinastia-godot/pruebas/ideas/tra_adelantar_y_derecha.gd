extends BaseIdea
## M-171 (27-10-2026): el tráfico cede por la derecha en los cruces sin semáforo y adelanta a los autobuses parados.

const DT := 1.0 / 30.0

func _trafico() -> TraficoCiudad:
	seed(9)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	return t

func _probar() -> void:
	_titulo("TRÁFICO · PRIORIDAD DE LA DERECHA Y ADELANTAR AL AUTOBÚS PARADO")
	_derecha()
	_adelantar()

func _pos(v: Dictionary) -> Vector3:
	return (v["nodo"] as Node3D).position

func _derecha() -> void:
	_linea("· Cruce sin semáforo")
	var t := _trafico()
	## A va hacia el este (+x) y B hacia el norte (−z), se cruzan en (0, 0). Para A, B viene por el SUR = su derecha: A cede.
	var ra := t.agregar_ruta(PackedVector3Array([Vector3(-60, 0, 0), Vector3(60, 0, 0), Vector3(60, 0, 80), Vector3(-60, 0, 80)]))
	var rb := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(80, 0, -60), Vector3(80, 0, 60)]))
	var na := Node3D.new()
	var nb := Node3D.new()
	t.agregar_vehiculo(na, ra, 20.0, 10.0)   ## A (índice 0, el de siempre pasaba primero) a 40 m del cruce
	t.agregar_vehiculo(nb, rb, 20.0, 10.0)   ## B a 40 m del cruce
	var va: Dictionary = t._vehiculos[0]
	var vb: Dictionary = t._vehiculos[1]
	var minimo := 99.0
	var t_a := -1.0
	var t_b := -1.0
	for i in int(20.0 / DT):
		t._process(DT)
		minimo = minf(minimo, Vector2(_pos(va).x - _pos(vb).x, _pos(va).z - _pos(vb).z).length())
		if t_b < 0.0 and _pos(vb).z < -3.0:
			t_b = float(i) * DT
		if t_a < 0.0 and _pos(va).x > 3.0:
			t_a = float(i) * DT
	_comprobar(t_a > 0.0 and t_b > 0.0, "los dos cruzan (A a los %.1f s, B a los %.1f s)" % [t_a, t_b])
	_comprobar(t_b < t_a, "pasa primero el que viene por la derecha de A (B) y A cede")
	_comprobar(minimo > 2.4, "sin rozarse nunca (mínimo %.1f m entre centros)" % minimo)
	t.queue_free()

func _adelantar() -> void:
	_linea("· Autobús parado en la parada")
	var t := _trafico()
	var rb := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(600, 0, 0), Vector3(600, 0, 60), Vector3(0, 0, 60)]))
	var rc := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(600, 0, 0), Vector3(600, 0, 60), Vector3(0, 0, 60)]))
	t.agregar_vehiculo(Node3D.new(), rb, 120.0, 9.0)
	t.agregar_paradas_al_ultimo([130.0], 40.0)   ## el autobús para 40 s en s = 130
	t.agregar_vehiculo(Node3D.new(), rc, 40.0, 12.0)
	var bus: Dictionary = t._vehiculos[0]
	var coche: Dictionary = t._vehiculos[1]
	var lat_max := 0.0
	var pasado_en := -1.0
	var parado_visto := false
	var cerca_min := 99.0
	for i in int(40.0 / DT):
		t._process(DT)
		parado_visto = parado_visto or float(bus.get("espera", 0.0)) > 0.0
		lat_max = maxf(lat_max, float(coche.get("lat", 0.0)))
		if float(bus.get("espera", 0.0)) > 0.0:
			var d := Vector2(_pos(coche).x - _pos(bus).x, _pos(coche).z - _pos(bus).z)
			if absf(d.x) < 5.0:
				cerca_min = minf(cerca_min, absf(d.y))
		if pasado_en < 0.0 and _pos(coche).x > _pos(bus).x + 8.0 and parado_visto:
			pasado_en = float(i) * DT
	_comprobar(parado_visto, "el autobús se para en la parada")
	_comprobar(lat_max > 2.6, "el coche se abre hacia el eje de la calzada (%.1f m)" % lat_max)
	_comprobar(pasado_en > 0.0 and pasado_en < 25.0, "y lo adelanta sin esperar a que arranque (a los %.1f s)" % pasado_en)
	_comprobar(cerca_min > 2.3, "dejando %.1f m de lado al pasar" % cerca_min)
	for i in int(25.0 / DT):
		t._process(DT)
	_comprobar(absf(float(coche.get("lat", 0.0))) < 0.3, "después vuelve a su carril (%.2f m)" % float(coche.get("lat", 0.0)))
	t.queue_free()
