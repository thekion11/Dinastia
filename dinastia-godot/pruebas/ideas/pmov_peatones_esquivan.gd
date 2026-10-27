extends BaseIdea
## pmov (26-10-2026): los peatones ya no solo esperan. Adelantan al lento o al
## parado abriéndose a un lado libre, rodean al jugador a pie, no se meten en
## paredes al esquivar, y los botes del río no cuentan como gente.

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("PMOV: PEATONES QUE ADELANTAN Y ESQUIVAN")
	_adelanta_al_lento()
	_adelanta_al_parado()
	_lado_con_pared()
	_rodea_mobiliario()
	_rodea_al_jugador()
	_botes_no_son_gente()

func _trafico() -> TraficoCiudad:
	seed(4321)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	return t

## Una acera recta de 200 m (el primer tramo va hacia +X; «fuera» es -Z).
func _acera(t: TraficoCiudad) -> int:
	return t.agregar_ruta(PackedVector3Array([Vector3(-100, 0, 0), Vector3(100, 0, 0), Vector3(100, 0, 40), Vector3(-100, 0, 40)]))

## Simula y devuelve la distancia mínima entre los dos peatones.
func _simular(t: TraficoCiudad, a: int, b: int, seg: float) -> float:
	var na: Node3D = t._vehiculos[a]["nodo"]
	var nb: Node3D = t._vehiculos[b]["nodo"]
	var m := INF
	for i in int(seg / DT):
		t._process(DT)
		m = minf(m, Vector2(na.position.x - nb.position.x, na.position.z - nb.position.z).length())
	return m

## Una papelera (círculo de 0,4 m) en mitad del carril: el peatón la ve 1,2 m antes, se
## abre a un lado y la deja atrás sin atravesarla (27-10-2026, plan §4).
func _rodea_mobiliario() -> void:
	var t := _trafico()
	var r := _acera(t)
	var papelera := Vector2(-70.0, 0.0)   ## s = 30 (la acera empieza en x = -100)
	t.libre_fn = func(q: Vector3) -> bool: return Vector2(q.x, q.z).distance_to(papelera) > 0.4 + 0.3
	t.agregar_vehiculo(Node3D.new(), r, 24.0, 1.2, 0.18)
	var n: Node3D = t._vehiculos[0]["nodo"]
	var m := INF
	for i in int(12.0 / DT):
		t._process(DT)
		m = minf(m, Vector2(n.position.x, n.position.z).distance_to(papelera))
	_comprobar(float(t._vehiculos[0]["s"]) > 34.0, "pasa la papelera (s=%.1f, papelera en 30)" % float(t._vehiculos[0]["s"]))
	_comprobar(m > 0.4, "sin atravesarla (mínimo %.2f m del centro; antes 0)" % m)
	t.queue_free()

func _adelanta_al_lento() -> void:
	var t := _trafico()
	var r := _acera(t)
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 0.6, 0.18)   ## el lento, 3 m por delante
	t.agregar_vehiculo(Node3D.new(), r, 17.0, 1.4, 0.18)
	var lento: Dictionary = t._vehiculos[0]
	var rapido: Dictionary = t._vehiculos[1]
	var m := _simular(t, 0, 1, 12.0)
	_comprobar(float(rapido["s"]) > float(lento["s"]) + 2.0,
		"el rápido adelanta al lento (s %.1f frente a %.1f; antes se quedaba detrás)" % [float(rapido["s"]), float(lento["s"])])
	_comprobar(m > 0.55, "sin atravesarlo al pasar (mínimo %.2f m)" % m)
	_simular(t, 0, 1, 6.0)
	_comprobar(absf(float(rapido.get("lat", 0.0))) < 0.05, "y luego vuelve a su línea (lat %.2f)" % float(rapido.get("lat", 0.0)))
	t.queue_free()

func _adelanta_al_parado() -> void:
	var t := _trafico()
	var r := _acera(t)
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 1.2, 0.18)
	t.agregar_vehiculo(Node3D.new(), r, 16.0, 1.3, 0.18)
	t._vehiculos[0]["espera"] = 30.0   ## mirando el móvil
	var m := _simular(t, 0, 1, 10.0)
	_comprobar(float(t._vehiculos[1]["s"]) > 25.0, "al que se para a mirar el móvil lo rodean (s=%.1f, parado en 20)" % float(t._vehiculos[1]["s"]))
	_comprobar(m > 0.55, "sin rozarlo (mínimo %.2f m)" % m)
	t.queue_free()

## Con pared por fuera, se abre por dentro; sin sitio a ningún lado, espera detrás.
func _lado_con_pared() -> void:
	var t := _trafico()
	var r := _acera(t)
	t.libre_fn = func(q: Vector3) -> bool: return q.z > -0.3   ## pared por fuera (-Z)
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 1.2, 0.18)
	t.agregar_vehiculo(Node3D.new(), r, 17.0, 1.3, 0.18)
	t._vehiculos[0]["espera"] = 30.0
	var nb: Node3D = t._vehiculos[1]["nodo"]
	var peor := INF
	for i in int(6.0 / DT):
		t._process(DT)
		peor = minf(peor, nb.position.z)
	_comprobar(peor > -0.31 and float(t._vehiculos[1]["s"]) > 21.0,
		"con pared por fuera adelanta por dentro sin pisarla (z mínima %.2f)" % peor)
	t.queue_free()
	var t2 := _trafico()
	var r2 := _acera(t2)
	t2.libre_fn = func(q: Vector3) -> bool: return absf(q.z) < 0.3   ## pasillo estrecho
	t2.agregar_vehiculo(Node3D.new(), r2, 20.0, 1.2, 0.18)
	t2.agregar_vehiculo(Node3D.new(), r2, 17.0, 1.3, 0.18)
	t2._vehiculos[0]["espera"] = 30.0
	var m := _simular(t2, 0, 1, 6.0)
	_comprobar(m > 0.85 and absf((t2._vehiculos[1]["nodo"] as Node3D).position.z) < 0.01,
		"en un pasillo sin sitio espera detrás, en su línea (mínimo %.2f m)" % m)
	t2.queue_free()

## Tú, a pie, plantado en mitad de la acera: te rodean, no te atraviesan ni se quedan atascados.
func _rodea_al_jugador() -> void:
	var t := _trafico()
	var r := _acera(t)
	var yo := Node3D.new()
	t.add_child(yo)
	yo.position = Vector3(-75.0, 0, 0.1)
	t.jugador = yo
	t.jugador_huella = Vector2(0.3, 0.3)
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 1.4, 0.18)   ## x = -80
	var n: Node3D = t._vehiculos[0]["nodo"]
	var m := INF
	for i in int(10.0 / DT):
		t._process(DT)
		m = minf(m, Vector2(n.position.x - yo.position.x, n.position.z - yo.position.z).length())
	_comprobar(n.position.x > -70.0, "te rodea y sigue su camino (x=%.1f; tú en -75)" % n.position.x)
	_comprobar(m > 0.6, "sin atravesarte (mínimo %.2f m)" % m)
	t.queue_free()

func _botes_no_son_gente() -> void:
	var t := _trafico()
	var rio := t.agregar_ruta(PackedVector3Array([Vector3(300, 0, -500), Vector3(300, 0, 500), Vector3(320, 0, 500), Vector3(320, 0, -500)]))
	var bote := Node3D.new()
	bote.name = "Bote"
	t.agregar_vehiculo(bote, rio, 0.0, 4.0, 0.15)
	var r := _acera(t)
	t.registrar_ruta_gente(r)
	_comprobar(not t.rutas_gente().has(rio), "el río no se apunta como acera")
	t.reciclar_peatones(Vector3(0, 0, 10), Vector3(1, 0, 0), 95.0, 3, 28, true)
	_comprobar(absf(bote.position.x - 300.0) < 0.01, "y el bote no se recicla a una acera (x=%.1f)" % bote.position.x)
	t.queue_free()
