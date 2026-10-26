extends BaseIdea
## s3 (26-10-2026): LOS PEATONES ESQUIVAN DE LADO en vez de quedarse plantados (plan §8).
## Tres casos con el `TraficoCiudad` real y el reloj a mano: adelantar al que va delante
## parado, cruzarse de frente en la misma acera y pasar junto al jugador. En los tres:
## nadie atraviesa a nadie, nadie se queda atascado y, al acabar, vuelven a su eje.
const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("S3: PEATONES QUE ESQUIVAN DE LADO")
	_adelantar()
	_de_frente()
	_al_jugador()

func _trafico() -> TraficoCiudad:
	## Las pausas al azar (mirar el móvil) con semilla fija: la prueba no depende de la suerte.
	seed(4321)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	return t

## Una recta larga cerrada por detrás (bucle de 400 m): los peatones van por el tramo z = 0.
func _recta(t: TraficoCiudad, hacia_x: bool) -> int:
	if hacia_x:
		return t.agregar_ruta(PackedVector3Array([Vector3(-100, 0, 0), Vector3(100, 0, 0), Vector3(100, 0, -20), Vector3(-100, 0, -20)]))
	return t.agregar_ruta(PackedVector3Array([Vector3(100, 0, 0), Vector3(-100, 0, 0), Vector3(-100, 0, 20), Vector3(100, 0, 20)]))

func _dist(a: Node3D, b: Node3D) -> float:
	return Vector2(a.position.x - b.position.x, a.position.z - b.position.z).length()

## Uno parado (mirando el móvil 20 s) y otro que llega por detrás a 1,4 m/s.
func _adelantar() -> void:
	var t := _trafico()
	var r := _recta(t, true)
	t.agregar_vehiculo(Node3D.new(), r, 104.0, 1.4, 0.1)
	t.agregar_vehiculo(Node3D.new(), r, 100.0, 1.4, 0.1)
	var parado: Dictionary = t._vehiculos[0]
	var va: Dictionary = t._vehiculos[1]
	parado["espera"] = 20.0
	var minimo := INF
	var max_lado := 0.0
	for i in int(8.0 / DT):
		t._process(DT)
		minimo = minf(minimo, _dist(parado["nodo"], va["nodo"]))
		max_lado = maxf(max_lado, absf(float(va.get("lat", 0.0))))
	var pasa := float(va["s"]) - float(parado["s"])
	_comprobar(pasa > 3.0, "el que llega por detrás adelanta al parado (le saca %.1f m en 8 s; antes se quedaba detrás)" % pasa)
	_comprobar(max_lado >= 0.6, "se aparta de lado para pasar (%.2f m)" % max_lado)
	_comprobar(minimo > 0.5, "sin atravesarle (mínimo %.2f m > 0,5)" % minimo)
	for i in int(4.0 / DT):
		t._process(DT)
	_comprobar(absf(float(va.get("lat", 0.0))) < 0.05, "y luego vuelve a su eje (lado %.2f)" % float(va.get("lat", 0.0)))
	t.queue_free()

## Dos por la misma acera en sentidos contrarios (rutas distintas sobre la misma línea).
func _de_frente() -> void:
	var t := _trafico()
	var ra := _recta(t, true)
	var rb := _recta(t, false)
	t.agregar_vehiculo(Node3D.new(), ra, 95.0, 1.4, 0.1)
	t.agregar_vehiculo(Node3D.new(), rb, 95.0, 1.4, 0.1)
	var a: Dictionary = t._vehiculos[0]
	var b: Dictionary = t._vehiculos[1]
	var sa := float(a["s"])
	var sb := float(b["s"])
	var minimo := INF
	var parado := 0.0
	for i in int(10.0 / DT):
		var s_antes := float(a["s"])
		t._process(DT)
		minimo = minf(minimo, _dist(a["nodo"], b["nodo"]))
		if float(a["s"]) - s_antes < 0.001 and float(a.get("espera", 0.0)) <= 0.0:
			parado += DT
	_comprobar(minimo > 0.6, "de frente se cruzan sin chocar (mínimo %.2f m > 0,6)" % minimo)
	_comprobar(float(a["s"]) - sa > 9.0 and float(b["s"]) - sb > 9.0,
		"y siguen andando (%.1f m y %.1f m en 10 s)" % [float(a["s"]) - sa, float(b["s"]) - sb])
	_comprobar(parado < 0.5, "sin quedarse plantados esperando (%.1f s parado)" % parado)
	t.queue_free()

## El jugador quieto en mitad de la acera: el peatón pasa a su lado, sin pararse delante.
func _al_jugador() -> void:
	var t := _trafico()
	var r := _recta(t, true)
	var yo := Node3D.new()
	t.add_child(yo)
	yo.position = Vector3(5.0, 0, 0)
	t.jugador = yo
	t.agregar_vehiculo(Node3D.new(), r, 100.0, 1.4, 0.1)
	var v: Dictionary = t._vehiculos[0]
	var minimo := INF
	for i in int(10.0 / DT):
		t._process(DT)
		minimo = minf(minimo, _dist(v["nodo"], yo))
	var nodo: Node3D = v["nodo"]
	_comprobar(nodo.position.x > 8.0, "el peatón te rodea y sigue (x = %.1f, tú en 5)" % nodo.position.x)
	_comprobar(minimo > 0.6, "sin rozarte (mínimo %.2f m > 0,6)" % minimo)
	## Y los coches siguen frenando a 7 m si estás delante (lo que decía el comentario).
	var t2 := _trafico()
	var r2 := _recta(t2, true)
	var yo2 := Node3D.new()
	t2.add_child(yo2)
	yo2.position = Vector3(20.0, 0, 0)
	t2.jugador = yo2
	t2.agregar_vehiculo(Node3D.new(), r2, 100.0, 10.0)
	for i in int(5.0 / DT):
		t2._process(DT)
	var coche: Node3D = t2._vehiculos[0]["nodo"]
	_comprobar(coche.position.x < 20.0 - 6.5 and coche.position.x > 20.0 - 7.5,
		"un coche se para a ~7 m de ti (a %.1f m)" % (20.0 - coche.position.x))
	t.queue_free()
	t2.queue_free()
