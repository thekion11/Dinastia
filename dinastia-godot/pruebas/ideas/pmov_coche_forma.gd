extends BaseIdea
## pmov (26-10-2026): TU COCHE choca con su forma (cápsula de 2,15 × 4,2 m que
## gira con él), no con un círculo de 2,2 m; y el tráfico te cede según esa
## forma (antes, con tu coche parado, los peatones atravesaban morro y cola).

func _probar() -> void:
	_titulo("PMOV: TU COCHE CON SU FORMA Y EL TRÁFICO QUE LA RESPETA")
	_pared_al_costado()
	_poste_al_costado()
	_girar_contra_pared()
	_de_frente()
	_peatones_y_tu_coche()

## Un explorador en coche, sin ciudad: solo los obstáculos que se le den.
func _explorador(rects: Array[Rect2], postes: Array[Vector3] = []) -> ExploradorCiudad:
	var e := ExploradorCiudad.new()
	e.modo = "coche"
	e.cuerpo = Node3D.new()
	e.obstaculos = rects
	e._indexar_obstaculos()
	for c: Vector3 in postes:
		var k := Vector2i(floori(c.x / ExploradorCiudad.CELDA_CIRC), floori(c.y / ExploradorCiudad.CELDA_CIRC))
		if not e._rej_circ.has(k):
			e._rej_circ[k] = []
		(e._rej_circ[k] as Array).append(c)
	return e

func _soltar(e: ExploradorCiudad) -> void:
	e.cuerpo.free()
	e.free()

## Avanza `metros` hacia donde mira, en trozos de 0,3 m como el juego.
func _avanzar(e: ExploradorCiudad, metros: float) -> void:
	var adelante := Vector3(sin(e.rumbo), 0, cos(e.rumbo))
	for i in int(metros / 0.3):
		e.vel = 10.0
		if not e._mover_un_trozo(adelante * 0.3, ExploradorCiudad.RADIO_COCHE):
			break

## Un paso de 2,6 m entre dos muros (el coche mide 2,15 de ancho): se cruza
## recto. Con el círculo de 2,2 m el coche chocaba con aire y se quedaba fuera.
func _pared_al_costado() -> void:
	var e := _explorador([Rect2(-6.0, -5.0, 4.7, 10.0), Rect2(1.3, -5.0, 4.7, 10.0)])
	e.cuerpo.position = Vector3(0, 0.2, -20.0)
	e.rumbo = 0.0
	_avanzar(e, 30.0)
	_comprobar(e.cuerpo.position.z > 9.0 and absf(e.cuerpo.position.x) < 0.01,
		"por un paso de 2,6 m (chapa a 0,2 m de cada muro) se pasa recto: z=%.1f (de -20 a ~10)" % e.cuerpo.position.z)
	_soltar(e)

## Un poste fino a 0,9 m del eje: está DENTRO de la chapa, el coche no lo atraviesa.
func _poste_al_costado() -> void:
	var e := _explorador([] as Array[Rect2], [Vector3(0.9, 0.0, 0.15)])
	e.cuerpo.position = Vector3(0, 0.2, -10.0)
	e.rumbo = 0.0
	_avanzar(e, 20.0)
	var z := e.cuerpo.position.z
	## El morro (2,1 m por delante) no pasa del poste.
	_comprobar(z + 2.1 < 0.6 and z > -4.0, "un poste junto a la puerta para el coche (morro en z=%.2f, poste en 0)" % (z + 2.1))
	_soltar(e)

## Paralelo a un muro, girar 90° metería el morro dentro: no se gira.
func _girar_contra_pared() -> void:
	var e := _explorador([Rect2(1.5, -50.0, 4.0, 100.0)])
	e.cuerpo.position = Vector3(0, 0.2, 0)
	e.rumbo = 0.0
	e.rumbo = PI / 2.0
	e._girar_si_cabe(0.0)
	_comprobar(is_zero_approx(e.rumbo), "no se gira metiendo el morro en la pared (rumbo %.2f)" % e.rumbo)
	## Un giro corto sí cabe (la cola se acerca, pero no llega al muro).
	e.rumbo = -0.3
	e._girar_si_cabe(0.0)
	_comprobar(is_equal_approx(e.rumbo, -0.3), "pero un giro que cabe, sí (rumbo %.2f)" % e.rumbo)
	_soltar(e)

## De frente contra un muro: el morro se para pegado a él, ni dentro ni a un metro.
func _de_frente() -> void:
	var e := _explorador([Rect2(-20.0, 10.0, 40.0, 4.0)])
	e.cuerpo.position = Vector3(0, 0.2, 0)
	e.rumbo = 0.0
	_avanzar(e, 20.0)
	var hueco := 10.0 - (e.cuerpo.position.z + 2.1)
	_comprobar(hueco > -0.01 and hueco < 0.4, "de frente, el morro se queda a %.2f m del muro" % hueco)
	_soltar(e)

## Tu coche parado en (0, 0) mirando a +Z. Un peatón cruza por delante del
## morro (z = 1,8: a 3 m del centro, fuera del radio de 1,6 m de antes) y otro
## pasa holgado (z = 3,2). Un coche viene por detrás, por tu carril.
func _peatones_y_tu_coche() -> void:
	var h := Vector2(ExploradorCiudad.RADIO_COCHE, ExploradorCiudad.SEP_COCHE + ExploradorCiudad.RADIO_COCHE)
	_comprobar(TraficoCiudad.tapa_al_jugador(Vector3(-2.5, 0, 1.8), Vector3(1, 0, 0), 1.25, 0.4, Vector3.ZERO, 0.0, h),
		"un peatón a 1 m del morro de tu coche se para")
	_comprobar(not TraficoCiudad.tapa_al_jugador(Vector3(-2.5, 0, 3.2), Vector3(1, 0, 0), 1.25, 0.4, Vector3.ZERO, 0.0, h),
		"el que pasa a 1 m por delante del morro sigue")
	_comprobar(not TraficoCiudad.tapa_al_jugador(Vector3(1.8, 0, -6.0), Vector3(0, 0, 1), 1.25, 0.4, Vector3.ZERO, 0.0, h),
		"y el que pasa por tu costado, a 0,7 m de la chapa, también")
	seed(99)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var yo := Node3D.new()
	t.add_child(yo)
	t.jugador = yo
	t.jugador_huella = h
	var rp := t.agregar_ruta(PackedVector3Array([Vector3(-30, 0, 1.8), Vector3(30, 0, 1.8), Vector3(30, 0, 40), Vector3(-30, 0, 40)]))
	t.agregar_vehiculo(Node3D.new(), rp, 25.0, 1.4, 0.1)
	var rc := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, -60), Vector3(0, 0, 60), Vector3(-40, 0, 60), Vector3(-40, 0, -60)]))
	t.agregar_vehiculo(Node3D.new(), rc, 30.0, 10.0)
	var np: Node3D = t._vehiculos[0]["nodo"]
	var nc: Node3D = t._vehiculos[1]["nodo"]
	var dentro_p := 0
	var min_c := INF
	for i in 300:
		t._process(1.0 / 30.0)
		if ExploradorCiudad._dentro_rect(PackedFloat32Array([0, 0, 0, 1, h.x, h.y]), np.position, 0.25):
			dentro_p += 1
		min_c = minf(min_c, -2.1 - (nc.position.z + 2.1))
	_comprobar(dentro_p == 0, "simulado: el peatón no atraviesa tu coche parado (%d fotogramas dentro)" % dentro_p)
	_comprobar(np.position.x < -1.0, "se queda esperando delante del morro (x=%.1f)" % np.position.x)
	_comprobar(min_c > 0.3, "el coche que viene detrás para sin tocarte (hueco mínimo %.1f m)" % min_c)
	t.queue_free()
