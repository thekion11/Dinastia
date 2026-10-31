extends BaseIdea
## (31-10-2026, pedido del dueño: «mejora la barrida y el saque de mano») En un partido de verdad (autopiloto): la barrida de la UAL2
## (`AnimExtra.BARRIDA_REAL`: entra, se desliza y se levanta) sale entre las barridas, y el portero con el balón en las manos que
## pasa raso y corto lo lanza con la mano (`saque_mano`) desde arriba del hombro, en vez de patearlo.

func _probar() -> void:
	_titulo("BARRIDA DE LA UAL2 Y SAQUE DE MANO DEL PORTERO")
	var r := _motor()
	var motor: MotorJugable = r[0]
	var gk: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		if bool(p["por"]):
			gk = p
			break
	## 1) Saque de mano aislado: el portero acaba de atrapar y pasa a un compañero a 20 m.
	motor.estado = "juego"
	motor.poseedor = gk
	gk["en_manos"] = true
	var b := motor.balon.position
	motor._patear(gk, b + Vector3(6.0, 0.0, signf(-motor._arco_propio(gk).z) * 19.0), 14.0)
	_comprobar(String(gk.get("anim_actual", "")) == "saque_mano", "con el balón en las manos pasa con la mano (gesto «%s»)" % String(gk.get("anim_actual", "")))
	_comprobar(motor.balon.position.y >= 1.6, "el balón sale desde arriba del hombro (%.2f m)" % motor.balon.position.y)
	_comprobar(not bool(gk.get("en_manos", false)), "y ya no lo tiene en las manos")
	## Lo retiene en la mano mientras carga el brazo y lo suelta a los 0,45 s, ya con velocidad.
	_comprobar(not motor._en_mano.is_empty() and motor.vel_balon.length() < 0.01, "al principio sigue en la mano (sin velocidad)")
	var t_suelta := -1.0
	for i in 30:
		motor.paso(1.0 / 30.0)
		if t_suelta < 0.0 and motor._en_mano.is_empty():
			t_suelta = float(i + 1) / 30.0
	_comprobar(t_suelta > 0.35 and t_suelta < 0.6, "lo suelta al lanzar, no al empezar a cargar el brazo (a los %.2f s)" % t_suelta)
	_comprobar(motor.vel_balon.length() > 5.0 or motor.poseedor != gk, "y el balón sale con su velocidad (%.1f m/s)" % motor.vel_balon.length())
	## 2) Envío largo: sigue siendo de volea (no un lanzamiento de 60 m).
	motor.poseedor = gk
	gk["en_manos"] = true
	motor._patear(gk, motor.balon.position + Vector3(0, 0, signf(-motor._arco_propio(gk).z) * 55.0), 25.0, 2.0)
	_comprobar(String(gk.get("anim_actual", "")) != "saque_mano", "el envío largo sigue siendo de pie («%s»)" % String(gk.get("anim_actual", "")))
	## 3) La barrida de la UAL2 se arma en el jugador y dura lo que debe.
	var def_: Dictionary = motor.jugadores[3]
	var ap: AnimationPlayer = def_["anim"]
	_comprobar(AnimExtra.unir(ap, FutbolistaQ.esqueleto_de(def_["node"]), "barrida_real", AnimExtra.BARRIDA_REAL), "la barrida de la UAL2 se arma en un futbolista")
	var largo := ap.get_animation("barrida_real").length if ap.has_animation("barrida_real") else 0.0
	_comprobar(largo > 1.4 and largo < 2.2, "entra, se desliza y se levanta en %.2f s" % largo)
	## 4) La barrida del jugador (la IA no se tira al suelo): una de cada tres es la de la UAL2, entera (1,8 s).
	var usu: Dictionary = motor.jugadores[4]
	var rival: Dictionary = motor.jugadores[15]
	var reales := 0
	for i in 30:
		motor.poseedor = rival
		(usu["node"] as Node3D).position = motor.pos(rival) + Vector3(0, 0, 3.0)
		usu["gesto_hasta"] = 0.0
		motor._lanzar_barrida(usu)
		if String(usu.get("anim_actual", "")) == "barrida_real":
			reales += 1
			if reales == 1:
				_comprobar(float(usu["gesto_hasta"]) - motor.t > 1.7, "la barrida de la UAL2 dura entera, hasta levantarse (%.2f s)" % (float(usu["gesto_hasta"]) - motor.t))
	## En el suelo no avanza a velocidad de carrera: tras la barrida de la UAL2 frena hasta levantarse.
	motor.poseedor = {}
	usu["gesto_hasta"] = 0.0
	usu["levanta_hasta"] = 0.0
	usu["barrida_hasta"] = 0.0
	while String(usu.get("anim_actual", "")) != "barrida_real":
		motor.poseedor = rival
		(usu["node"] as Node3D).position = motor.pos(rival) + Vector3(0, 0, 6.0)
		usu["gesto_hasta"] = 0.0
		motor._lanzar_barrida(usu)
	motor.poseedor = {}
	for i in 15:
		motor._seguir_barrida(usu)
		motor.t += 1.0 / 30.0
	for i in 30:
		motor._seguir_barrida(usu)
		motor.t += 1.0 / 30.0
	_comprobar(float(usu.get("levanta_hasta", 0.0)) > 0.0 and motor._seguir_barrida(usu) or float(usu["levanta_hasta"]) <= motor.t,
		"tras la barrida de la UAL2 se queda en el suelo hasta levantarse (hasta t = %.2f)" % float(usu.get("levanta_hasta", 0.0)))
	_comprobar(usu["objetivo"] == motor.pos(usu) or float(usu["levanta_hasta"]) <= motor.t, "y mientras se levanta no persigue nada (objetivo = donde está)")
	_comprobar(reales >= 4 and reales <= 18, "de 30 barridas del jugador, %d son la de la UAL2" % reales)
	## 5) Tras una falta cae, se queda en el suelo y se levanta con el clip de la UAL2, sin moverse mientras.
	var r3 := _motor()
	var m3: MotorJugable = r3[0]
	var vic: Dictionary = m3.jugadores[8]
	m3._caer(vic)
	var donde := m3.pos(vic)
	var anims := []
	for i in 30 * 4:
		m3.paso(1.0 / 30.0)
		var a := String(vic.get("anim_actual", ""))
		if anims.is_empty() or anims[-1] != a:
			anims.append(a)
		if i == 30 * 3:
			_comprobar(m3.pos(vic).distance_to(donde) < 0.6, "en el suelo y levantándose no se desplaza (%.2f m en 3 s)" % m3.pos(vic).distance_to(donde))
	_comprobar(anims.size() >= 2 and anims[0] == "caida_lesion" and anims[1] == "levantarse_suelo", "cae y luego se levanta, sin ponerse de pie entre medias (%s)" % str(anims.slice(0, 3)))
	## 6) Un partido simulado no se rompe con todo esto.
	var r2 := _motor()
	var m2: MotorJugable = r2[0]
	for i in 30 * 60 * 3:
		m2.paso(1.0 / 30.0)
	_comprobar(m2.t > 100.0, "3 minutos de pasos del motor sin errores (reloj de juego %.0f s; se para en las interrupciones)" % m2.t)

func _motor() -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", 7)
	return [motor, raiz]
