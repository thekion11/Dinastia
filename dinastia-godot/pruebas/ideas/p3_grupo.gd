extends BaseIdea
## P3 «MEJORAR» (27-10-2026): tres vecinos forman un corro ante una entrada, charlan mirándose entre sí y se van cada uno por su lado.

func _probar() -> void:
	_titulo("GRUPO · TRES VECINOS CHARLAN EN CORRO")
	var b := CityBuilder.new()
	add_child(b)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	add_child(ex)
	var gv := GrupoVida.new()
	gv.expl = ex
	add_child(gv)
	PuertaVida.registrar(b, Vector3(50, 0, 50), Vector3(0, 0, 1))
	gv.iniciar(0)
	if gv._grupos.is_empty():
		_comprobar(true, "(sin modelo de peatón en este entorno)")
		return
	var g: Dictionary = gv._grupos[0]
	var figs: Array = g["figs"]
	_comprobar(figs.size() == GrupoVida.PERSONAS, "llegan %d vecinos" % figs.size())
	gv._mover(float(g["dur"]) + 0.1)
	_comprobar(int(g["fase"]) == 1, "forman el corro")
	var clips := []
	for f: Dictionary in figs:
		clips.append(((f["fig"] as Dictionary)["anim"] as AnimationPlayer).current_animation)
	_comprobar(clips.all(func(x): return x == "charla"), "cada uno con el clip «charla» (%s)" % str(clips))
	var c: Vector3 = g["centro"]
	var ok := true
	for f: Dictionary in figs:
		var n: Node3D = (f["fig"] as Dictionary)["nodo"]
		ok = ok and absf(Vector2(n.position.x - c.x, n.position.z - c.z).length() - GrupoVida.RADIO) < 0.05
	_comprobar(ok, "a %.2f m del centro cada uno" % GrupoVida.RADIO)
	for i in 20:
		gv._mover(0.2)
	var mira := true
	for f: Dictionary in figs:
		var n: Node3D = (f["fig"] as Dictionary)["nodo"]
		var hacia := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y)).dot((c - n.position).normalized())
		mira = mira and hacia > 0.9
	_comprobar(mira, "todos de cara al centro")
	var m0: Vector3 = ((g["marcas"] as Array)[0] as Node3D).position
	gv._mover(3.1)
	var m1: Vector3 = ((g["marcas"] as Array)[0] as Node3D).position
	_comprobar(m0.distance_to(m1) > 0.3, "la mirada cambia al que habla (%.1f m)" % m0.distance_to(m1))
	gv._mover(float(g["charla"]))
	_comprobar(int(g["fase"]) == 2, "tras charlar echan a andar")
	gv._mover(float(g["dur"]) + 0.5)
	_comprobar(gv._grupos.is_empty(), "cada uno se va por su lado y el grupo desaparece")
