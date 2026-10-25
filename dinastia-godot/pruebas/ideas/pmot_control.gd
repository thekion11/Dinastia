extends BaseIdea
## EL CONTROL DEL USUARIO EN EL MOTOR REAL (25-10-2026, prefijo pmot): la barrida ya no teletransporta (antes
## saltaba 1,6 m en un fotograma y la entrada se decidía a 3 m del rival): se tira con inercia hacia donde va
## el rival y la entrada se resuelve al llegar. Y el regate que engaña al rival ya no lo mueve 0,7 m de golpe.

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("CONTROL: la barrida va por el suelo y se decide al llegar")
	var r := _motor()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var loc: Array = []
	var vis: Array = []
	for p: Dictionary in motor.jugadores:
		if not bool(p["por"]):
			(loc if bool(p["es_local"]) else vis).append(p)
	var u: Dictionary = loc[0]
	var rival: Dictionary = vis[0]
	## Los demás, lejos (que nadie se meta en la jugada).
	for i in range(1, loc.size()):
		(loc[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, -40.0)
	for i in range(1, vis.size()):
		(vis[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, 40.0)
	motor.estado = "juego"
	motor.autopiloto = false
	motor.usuario = u
	## El rival conduce hacia el arco del local (-Z); tú, delante de él a 2,8 m.
	(rival["node"] as Node3D).position = Vector3(0, 0, 5.0)
	rival["vel"] = Vector3(0, 0, -3.0)
	(u["node"] as Node3D).position = Vector3(0.6, 0, 2.3)
	u["vel"] = Vector3.ZERO
	u["enfriar"] = 0.0
	motor.poseedor = rival
	motor.balon.position = Vector3(0, 0.11, 4.5)
	motor._decision_en = motor.t + 99.0
	var antes := int(motor.stats["entradas"])
	motor._lanzar_barrida(u)
	_comprobar(float(u.get("barrida_hasta", 0.0)) > motor.t and String(u.get("anim_actual", "")).begins_with("barrida"),
		"al pulsar se tira al suelo (%s)" % String(u.get("anim_actual", "")))
	var salto := 0.0
	var resuelta_a := -1.0
	var previa := motor.pos(u)
	for k in 30:
		var d_antes := motor.pos(u).distance_to(motor.pos(rival))
		motor.paso(DT)
		salto = maxf(salto, Vector2(motor.pos(u).x - previa.x, motor.pos(u).z - previa.z).length())
		previa = motor.pos(u)
		if int(motor.stats["entradas"]) > antes and resuelta_a < 0.0:
			resuelta_a = d_antes
		if float(u.get("barrida_hasta", 0.0)) <= 0.0:
			break
	_comprobar(salto < 0.55, "sin saltos: como mucho %.2f m por fotograma (antes 1,6 m de golpe)" % salto)
	_comprobar(resuelta_a >= 0.0 and resuelta_a < 1.6, "la entrada se decide al llegar al rival (a %.2f m)" % resuelta_a)
	## Fallar la barrida se paga: si el rival se va, se queda en el suelo un momento.
	motor.estado = "juego"
	(rival["node"] as Node3D).position = Vector3(0, 0, -20.0)
	rival["vel"] = Vector3(0, 0, -7.0)
	motor.poseedor = rival
	motor.balon.position = Vector3(0, 0.11, -20.5)
	(u["node"] as Node3D).position = Vector3(3.0, 0, -18.0)
	u["vel"] = Vector3.ZERO
	u["enfriar"] = 0.0
	u["barrida_hasta"] = 0.0
	motor._lanzar_barrida(u)
	u["barrida_dir"] = Vector3(1, 0, 0)
	for k in 30:
		motor.paso(DT)
		if float(u.get("barrida_hasta", 0.0)) <= 0.0:
			break
	_comprobar(float(u.get("barrida_hasta", 0.0)) <= 0.0 and float(u["enfriar"]) > 0.3, "barrida al aire: se queda en el suelo (enfriar %.2f)" % float(u["enfriar"]))
	raiz.queue_free()

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
