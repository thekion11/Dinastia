extends Node3D
## EL SORTEO DEL SAQUE INICIAL (orden de «Auditoría de sesiones», 17-11): el menú del partido sortea quién saca y el motor lo respeta: la primera parte saca el
## elegido y la segunda, el otro. Con el valor de siempre (saca el local) el partido es idéntico (lo cubre `igualdad_motor`).

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _motor(saca_local: bool, paises: Array, semilla: int) -> MotorJugable:
	var m := Mundo.new()
	var ps: Array[String] = []
	for c in paises:
		ps.append(String(c))
	m.generar(ps, semilla)
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
	motor.duracion_mitad = 12.0
	motor.saca_primero_local = saca_local
	motor.preparar(lista, ball, "", semilla)
	return motor

func _ready() -> void:
	for cfg: Array in [[true, ["CHI"], 3], [false, ["ESP"], 4], [false, ["ARG", "BRA"], 5]]:
		var saca := bool(cfg[0])
		var e := "%s/%s" % [",".join(cfg[1]), "local" if saca else "visita"]
		var motor := _motor(saca, cfg[1], int(cfg[2]))
		_ok(String(motor.estado) == "saque" and bool(motor.saque["local"]) == saca, "%s: el saque inicial lo hace el sorteado" % e)
		var pasos := 0
		var vio_segunda := false
		while motor.estado != "fin" and pasos < 30 * 120 and not vio_segunda:
			motor.paso(1.0 / 30.0)
			pasos += 1
			if motor.mitad == 2 and motor.estado == "saque":
				vio_segunda = true
				_ok(bool(motor.saque["local"]) == (not saca), "%s: en la segunda parte saca el otro" % e)
		_ok(vio_segunda, "%s: se llegó a la segunda parte" % e)
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
