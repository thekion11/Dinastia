extends BaseIdea
## INTERPOLACIÓN DE LA FÍSICA DEL PARTIDO (H-01, 2-11-2026): con el motor corriendo en tiempo real, cuántas posiciones DISTINTAS por segundo ve el render del balón y de un jugador:
## sin interpolación son las del paso de física (60/s); con ella, tantas como fotogramas. Y que un salto (saque de centro) no se dibuja cruzando el campo.
## Sin pantalla el bucle va a miles de fotogramas por segundo, así que se compara con el número de pasos de física del mismo tiempo.

func _escena(interpolar: bool) -> Dictionary:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
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
	motor.autopiloto = true
	motor.preparar(lista, ball, "", 5)
	var falso := Node.new()   ## hace de `PartidoJugable` para `InterpolacionPartido` (motor, _cine, _repe, _actualizar_camara)
	falso.set_script(load("res://pruebas/ideas/int_partido_pj.gd"))
	falso.set("motor", motor)
	add_child(falso)
	InterpolacionPartido.activar = interpolar
	var ip := InterpolacionPartido.montar(falso, raiz)
	var jugador: Node3D = (lista[8]["node"] as Node3D)
	var vistas := {}
	var pasos0 := Engine.get_physics_frames()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1500:
		await get_tree().process_frame
		var q := ball.get_global_transform_interpolated().origin
		var j := jugador.get_global_transform_interpolated().origin
		vistas["%.4f,%.4f,%.4f|%.4f,%.4f" % [q.x, q.y, q.z, j.x, j.z]] = true
	var pasos := Engine.get_physics_frames() - pasos0
	var r := {"distintas": vistas.size(), "pasos": pasos, "activa": ip.activa, "raiz": raiz, "ball": ball, "motor": motor, "lista": lista, "ip": ip}
	return r

func _ready() -> void:
	await get_tree().process_frame
	_titulo("INTERPOLACIÓN DE LA FÍSICA DEL PARTIDO")
	var sin := await _escena(false)
	var con := await _escena(true)
	print("  sin interpolación: %d posiciones distintas en %d pasos de física" % [sin["distintas"], sin["pasos"]])
	print("  con interpolación: %d posiciones distintas en %d pasos de física" % [con["distintas"], con["pasos"]])
	_comprobar(not bool(sin["activa"]) and bool(con["activa"]), "`activar = false` la deja apagada y por defecto está encendida")
	_comprobar(int(con["pasos"]) > 20, "la física corrió (%d pasos)" % int(con["pasos"]))
	_comprobar(int(sin["distintas"]) <= int(sin["pasos"]) + 3, "sin interpolación no hay más posiciones que pasos de física")
	_comprobar(int(con["distintas"]) > 2 * int(con["pasos"]) or int(con["distintas"]) > int(sin["distintas"]) * 2, "con interpolación hay muchas más posiciones distintas que pasos (%d)" % int(con["distintas"]))
	## Un salto: se coloca el balón y un jugador al otro lado del campo y se mira, un paso después, que lo dibujado está en el sitio nuevo y no a medio camino.
	var ball: Node3D = con["ball"]
	var jug: Node3D = (con["lista"][8]["node"] as Node3D)
	var motor: MotorJugable = con["motor"]
	motor.set_physics_process(false)
	jug.position = Vector3(-20, 0, -30)
	ball.position = Vector3(20, 0.11, 30)
	motor.set_physics_process(true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	var dib := jug.get_global_transform_interpolated().origin
	_comprobar(dib.distance_to(jug.position) < 3.0, "tras un salto el jugador se dibuja donde está, no cruzando el campo (a %.1f m)" % dib.distance_to(jug.position))
	InterpolacionPartido.activar = true
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
