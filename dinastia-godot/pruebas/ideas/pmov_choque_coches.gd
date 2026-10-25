extends BaseIdea
## pmov (25-10-2026): a pie o en coche, los coches del tráfico chocan con su
## FORMA (rectángulo orientado medido de sus mallas), no con un círculo de 1,7 m
## que dejaba atravesar morro y cola y chocaba con aire por los lados.

func _probar() -> void:
	_titulo("PMOV: CHOCAR CON LA FORMA REAL DE LOS COCHES")
	## Un «coche» de prueba: caja de 2 × 1,5 × 4,5 m (morro en +Z).
	var coche := Node3D.new()
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(2.0, 1.5, 4.5)
	malla.mesh = caja
	coche.add_child(malla)
	var v := {"nodo": coche, "alto": 0.0}
	var h := ExploradorCiudad._huella(v, coche)
	_comprobar(absf(h.x - 1.0) < 0.01 and absf(h.y - 2.25) < 0.01,
		"la huella sale de la malla: medio ancho %.2f, medio largo %.2f" % [h.x, h.y])
	## Con la escala del nodo (la flota va a 1,65) la huella crece.
	coche.scale = Vector3.ONE * 2.0
	var v2 := {"nodo": coche, "alto": 0.0}
	var h2 := ExploradorCiudad._huella(v2, coche)
	_comprobar(absf(h2.y - 4.5) < 0.01, "la escala del coche cuenta (medio largo %.2f)" % h2.y)
	coche.scale = Vector3.ONE

	var rc := PackedFloat32Array([0, 0, 0, 1, 1.0, 2.25])
	_comprobar(ExploradorCiudad._dentro_rect(rc, Vector3(0, 0, 2.6), 0.5),
		"a pie contra el morro (2,6 m del centro): choca (antes, círculo de 1,7 m, lo atravesabas)")
	_comprobar(not ExploradorCiudad._dentro_rect(rc, Vector3(1.6, 0, 0), 0.5),
		"al costado a 1,6 m: pasas (antes chocabas con aire)")
	_comprobar(not ExploradorCiudad._dentro_rect(rc, Vector3(1.4, 0, 2.6), 0.5),
		"la esquina es redonda: en diagonal a la esquina no se choca de más")
	## Girado 90°: el morro apunta a +X.
	var a := PI / 2.0
	var rg := PackedFloat32Array([0, 0, sin(a), cos(a), 1.0, 2.25])
	_comprobar(ExploradorCiudad._dentro_rect(rg, Vector3(2.6, 0, 0), 0.5) and not ExploradorCiudad._dentro_rect(rg, Vector3(0, 0, 1.6), 0.5),
		"girado 90° el rectángulo gira con el coche")

	## De punta a punta, con el explorador y el tráfico de verdad (sin ciudad).
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var ruta := t.agregar_ruta(PackedVector3Array([Vector3(-50, 0, 0), Vector3(50, 0, 0), Vector3(50, 0, 30), Vector3(-50, 0, 30)]))
	t.agregar_vehiculo(coche, ruta, 50.0, 0.0)   ## en (0, 0, 0) mirando a +X
	var e := ExploradorCiudad.new()
	e.trafico = t
	e.cuerpo = Node3D.new()
	e.cuerpo.position = Vector3(0, 0, 6)
	_comprobar(e._choca_moviles(Vector3(2.6, 0, 0), 0.45), "el explorador choca con la cola/morro de un coche del tráfico")
	_comprobar(not e._choca_moviles(Vector3(0, 0, 1.55), 0.45), "y pasa rozando su costado")
	_comprobar(e._choca_moviles(Vector3(0, 0, 1.3), 0.45), "pero no lo atraviesa por el lado")
	## Lejos del personaje (buscar sitio al aparecer) usa la misma forma.
	e.cuerpo.position = Vector3(0, 0, 90)
	_comprobar(e._choca_moviles(Vector3(2.6, 0, 0), 0.45), "también en la búsqueda lejana de sitio libre")
	e.cuerpo.free()
	e.free()
	t.queue_free()
