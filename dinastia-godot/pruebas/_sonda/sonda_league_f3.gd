extends Node
## Sonda temporal de la fase 3 del motor League (no va al banco).
func _ready() -> void:
	await get_tree().process_frame
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[1].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor: MotorJugable = MotorJugable.new() if OS.get_environment("SIEMPRE") == "1" else MotorLeague.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = 120.0
	motor.preparar(lista, ball, "", 7)
	var cambios := 0
	var ult := -1
	var pos_t := [0, 0]
	var motivos := {}
	var antes_estado := ""
	for i in 3600:
		motor.paso(1.0 / 30.0)
		if motor.estado != antes_estado:
			motivos[motor.estado] = int(motivos.get(motor.estado, 0)) + 1
			antes_estado = motor.estado
		if not motor.poseedor.is_empty():
			var eqp := 0 if bool(motor.poseedor["es_local"]) else 1
			pos_t[eqp] += 1
			if ult != -1 and eqp != ult:
				cambios += 1
			ult = eqp
	print("CAMBIOS de posesión: ", cambios, " pasos con balón ", pos_t, " estados ", motivos, " duelos ", motor.duelos)
	print("FIN sonda ", motor.goles, " tiros ", motor.tiros, " toques ", motor.get("cuenta_toques"))
	get_tree().quit()
