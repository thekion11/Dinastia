extends BaseIdea
## EL PERSONAL DEL CLUB TRABAJA EN SU PUESTO (26-10-2026, paquete pint).
## Antes, al llegar a su puesto cada persona se quedaba «parado» 22-40 s: una
## estatua. Ahora hace de vez en cuando un gesto de su oficio (librería
## «banda» de `PersonajeDT`), uno distinto cada vez, y luego sigue su ronda.

func _probar() -> void:
	_titulo("PERSONAL CON RUTINA: GESTOS DE OFICIO EN EL PUESTO")
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var perfil := EstadioPropio.new().perfil(m.ligas[0].clubes[0])
	perfil["forma"] = "cuenco"
	perfil["tunel"] = "central"
	PersonajeDT.club_usuario = ""
	PersonalEstadio.hora = -1.0
	var raiz := Node3D.new()
	add_child(raiz)
	TunelVestuario.montar(raiz, perfil, 2, null)
	var pe := raiz.find_children("*", "PersonalEstadio", true, false)[0] as PersonalEstadio
	_comprobar(pe.gente.size() >= 10, "hay personal en el club (%d)" % pe.gente.size())
	var gestos := {}
	var distintos := {}
	var movidos := {}
	var inicio := {}
	for g: Dictionary in pe.gente:
		inicio[g["clave"]] = (g["nodo"] as Node3D).position
	## 90 s de juego a pasos de 0,1 s.
	for i in 900:
		pe._process(0.1)
		for g: Dictionary in pe.gente:
			var a := g.get("anim") as AnimationPlayer
			var k := String(g["clave"])
			if a != null and a.current_animation.begins_with("banda/"):
				gestos[k] = int(gestos.get(k, 0)) + 1
				var dk: Dictionary = distintos.get(k, {})
				dk[a.current_animation] = true
				distintos[k] = dk
			if (g["nodo"] as Node3D).position.distance_to(inicio[k]) > 0.5:
				movidos[k] = true
	_comprobar(gestos.size() >= pe.gente.size() - 2, "casi todos hacen gestos de su oficio en el puesto (%d de %d)" % [gestos.size(), pe.gente.size()])
	var con_dos := distintos.values().filter(func(d: Dictionary) -> bool: return d.size() >= 2).size()
	_comprobar(con_dos >= 5, "y no siempre el mismo: %d alternan dos gestos" % con_dos)
	_comprobar(movidos.size() >= pe.gente.size() - 2, "y siguen haciendo su ronda (%d se han movido)" % movidos.size())

	_titulo("EL PORTERO TE SALUDA AL PASAR")
	var por := pe.buscar("portero")
	var pn: Node3D = por["nodo"]
	por["espera"] = 30.0
	por["gesto_t"] = 0.0
	por.erase("saludo_ms")
	var yo := pn.position + Vector3(2.5, 0, 1.0)
	PersonalEstadio.avisar_jugador(yo, 0)
	pe._process(0.1)
	var ap := por.get("anim") as AnimationPlayer
	var mira := Vector2(sin(pn.rotation.y), cos(pn.rotation.y)).dot(Vector2(yo.x - pn.position.x, yo.z - pn.position.z).normalized())
	_comprobar(float(por.get("gesto_t", 0.0)) > 0.0 and ap != null and ap.current_animation in PersonalEstadio.SALUDAN["portero"],
		"al pasar a 2,7 m, el portero hace su saludo (%s)" % (ap.current_animation if ap != null else "sin cuerpo"))
	_comprobar(mira > 0.95, "y se gira hacia ti (%.2f)" % mira)
	## No repite enseguida.
	por["gesto_t"] = 0.0
	pe._process(0.1)
	_comprobar(not (ap.current_animation in PersonalEstadio.SALUDAN["portero"] and float(por.get("gesto_t", 0.0)) > 0.0),
		"y no vuelve a saludar a cada paso")
	## Lejos (10 m) no saluda.
	por.erase("saludo_ms")
	PersonalEstadio.avisar_jugador(pn.position + Vector3(10, 0, 0), 0)
	_comprobar(not pe._saludar(por), "a 10 m no saluda")
	raiz.queue_free()

	_titulo("LA FACHADA DEL EDIFICIO DEL CLUB (pedido de pgra)")
	var f := Node3D.new()
	add_child(f)
	var lote := FachadaClub.montar(f, 0.0, 60.0, 73.0, Color(0.1, 0.4, 0.2), "Club de Prueba")
	var letreros := f.find_children("LetreroClub*", "Label3D", true, false)
	_comprobar(letreros.size() == 3, "el nombre del club en los dos lados y atrás (%d)" % letreros.size())
	_comprobar(f.get_child_count() <= 12, "la fachada va en pocas mallas (%d nodos)" % f.get_child_count())
	## La planta 0 de atrás (la entrada del club) queda libre: ninguna pieza de
	## la fachada de atrás baja de 3,4 m.
	var tapa := lote.piezas.filter(func(p: Array) -> bool:
		var a: AABB = p[0]
		return a.position.z > 73.25 and a.position.y < 3.35)
	_comprobar(tapa.is_empty(), "no tapa la entrada del club (%d piezas bajas atrás)" % tapa.size())
	var vidrios := lote.piezas.filter(func(p: Array) -> bool: return (p[1] as StandardMaterial3D).metallic > 0.5).size()
	_comprobar(vidrios >= 8, "lleva vidrio en las plantas (%d bandas)" % vidrios)
	f.queue_free()
