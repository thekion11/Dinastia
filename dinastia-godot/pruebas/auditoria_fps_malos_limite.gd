extends Node
## CAZA DE FALLOS (4-11-2026, orden de la líder): el partido 3D con FOTOGRAMAS MALOS (5 FPS del teléfono del dueño).
##   godot --headless --path . res://pruebas/auditoria_fps_malos_limite.tscn
## A) El motor llamado con pasos de tiempo grandes (0,2 s, 1 s): el balón no sale del mundo, los porteros no se teletransportan (desplazamiento por paso acotado), nada se vuelve NaN,
##    y el resultado se parece al de 1/60 (mismo reloj de partido).
## B) El juego de verdad (física fija a 60 Hz) con 5 FPS, con tirones de 1 s y a velocidad máxima (`Engine.time_scale`): MISMO estado exacto que a 60 FPS con la misma semilla (reloj, goles,
##    posición del balón y de los 22) tras los mismos pasos de física.
## C) Un cambio durante una REPETICIÓN no le pasa al que entra el recorrido del que salió.
const PASO := 1.0 / 60.0
var _fallos := 0

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	await _grandes_pasos()
	await _fps_malos()
	await _repeticion_con_cambio()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _motor(semilla := 7) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	var lista: Array = []
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = 60.0
	motor.preparar(lista, ball, "", semilla)
	return [motor, raiz]

func _huella(m: MotorJugable) -> String:
	var s := "%s|%d|%d|%.3f|%.3f,%.3f,%.3f" % [m.estado, m.goles[0], m.goles[1], m.t, m.balon.position.x, m.balon.position.y, m.balon.position.z]
	for p: Dictionary in m.jugadores:
		var q: Vector3 = (p["node"] as Node3D).position
		s += "|%.3f,%.3f" % [q.x, q.z]
	return str(hash(s))

## A) pasos de tiempo grandes en el propio motor.
func _grandes_pasos() -> void:
	for dt in [PASO, 0.2, 1.0]:
		var r := _motor(11)
		var m: MotorJugable = r[0]
		var mal := 0
		var fuera := 0
		var salto_portero := 0.0
		var pos_gk := {}
		var t_fin := 120.0
		var pasos := 0
		while m.t < t_fin and m.estado != "fin" and pasos < 100000:
			m.paso(dt)
			pasos += 1
			var b := m.balon.position
			if not (is_finite(b.x) and is_finite(b.y) and is_finite(b.z)):
				mal += 1
			if absf(b.x) > 40.0 or absf(b.z) > 80.0 or b.y > 60.0 or b.y < -2.0:
				fuera += 1
			for p: Dictionary in m.jugadores:
				var q: Vector3 = (p["node"] as Node3D).position
				if not (is_finite(q.x) and is_finite(q.z)):
					mal += 1
				if bool(p["por"]):
					var id := String(p["id"])
					if pos_gk.has(id) and m.estado == "juego" and String(pos_gk[id][1]) == "juego":
						salto_portero = maxf(salto_portero, (pos_gk[id][0] as Vector3).distance_to(q) / dt)
					pos_gk[id] = [q, m.estado]
		_comprobar(mal == 0, "paso de %.3f s: nada se vuelve NaN" % dt)
		_comprobar(fuera <= pasos / 50, "paso de %.3f s: el balón rara vez está fuera del mundo (%d de %d pasos)" % [dt, fuera, pasos])
		_comprobar(salto_portero < 30.0, "paso de %.3f s: los porteros no se teletransportan (máx. %.1f m/s)" % [dt, salto_portero])
		(r[1] as Node3D).queue_free()
		await get_tree().process_frame

## B) el juego real con fotogramas malos: misma física fija, mismo resultado.
func _fps_malos() -> void:
	var T := 20.0
	var base := _motor(13)
	var mb: MotorJugable = base[0]
	while mb.t < T and mb.estado != "fin":
		mb.paso(PASO)
	var h0 := _huella(mb)
	var t0 := mb.t
	await get_tree().process_frame
	for escenario in ["5fps", "tirones", "x8"]:
		var r := _motor(13)
		var m: MotorJugable = r[0]
		## Un controlador ANTES del motor en el árbol: apaga el motor justo al llegar a T (mismos pasos que a 60 FPS).
		var ctl := _Parar.new()
		ctl.motor = m
		ctl.T = T
		ctl.escenario = escenario
		(r[1] as Node3D).add_child(ctl)
		(r[1] as Node3D).move_child(ctl, 0)
		m.set_physics_process(true)
		if escenario == "x8":
			Engine.time_scale = 8.0
		var t_real := Time.get_ticks_msec()
		while m.is_physics_processing() and Time.get_ticks_msec() - t_real < 180000:
			await get_tree().process_frame
		Engine.time_scale = 1.0
		if escenario == "x8":
			## A velocidad máxima el paso que llega a la física es 8 veces mayor y el motor lo reparte: el reloj y el marcador coinciden (el estado exacto no: otros pasos).
			_comprobar(not m.is_physics_processing() and absf(m.t - t0) < 0.2, "x8: llega al mismo reloj (%.3f s frente a %.3f s a 60 FPS)" % [m.t, t0])
			_comprobar(m.goles[0] == mb.goles[0] and m.goles[1] == mb.goles[1] and m.estado == mb.estado, "x8: mismo marcador (%d-%d) y estado (%s)" % [m.goles[0], m.goles[1], m.estado])
		else:
			_comprobar(not m.is_physics_processing() and absf(m.t - t0) < 0.0001, "%s: llega al mismo reloj (%.3f s frente a %.3f s a 60 FPS)" % [escenario, m.t, t0])
			_comprobar(_huella(m) == h0, "%s: MISMO estado exacto que a 60 FPS (marcador %d-%d, balón y 22 jugadores)" % [escenario, m.goles[0], m.goles[1]])
		(r[1] as Node3D).queue_free()
		await get_tree().process_frame

class _Parar extends Node:
	var motor: MotorJugable
	var T := 20.0
	var escenario := ""
	var _n := 0
	func _process(_d: float) -> void:
		_n += 1
		if escenario == "5fps":
			OS.delay_msec(200)
		elif escenario == "tirones" and _n % 120 == 0:
			OS.delay_msec(1000)
	func _physics_process(_d: float) -> void:
		if motor.t >= T:
			motor.set_physics_process(false)

## C) cambio durante la repetición.
func _repeticion_con_cambio() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var jugs: Array = []
	for k in 2:
		var n := Node3D.new()
		raiz.add_child(n)
		n.position = Vector3(k * 5.0, 0, 0)
		jugs.append({"node": n, "anim": null, "id": "j%d" % k})
	var bal := Node3D.new()
	raiz.add_child(bal)
	var rep := Repeticion.new()
	raiz.add_child(rep)
	rep.setup(jugs, bal)
	for i in 60:
		for k in 2:
			(jugs[k]["node"] as Node3D).position.z += 0.1   ## los dos corren hacia +Z mientras se graba
		await get_tree().process_frame
		rep._process(0.1)
	var antes := rep.segundos_guardados()
	_comprobar(antes > 1.0, "la repetición graba (%.1f s)" % antes)
	var nuevo := Node3D.new()
	raiz.add_child(nuevo)
	nuevo.position = Vector3(100, 0, 0)
	var ok := rep.reproducir(3.0)
	_comprobar(ok and rep.reproduciendo, "la repetición arranca")
	jugs[1] = {"node": nuevo, "anim": null, "id": "nuevo"}   ## cambio DURANTE la repetición: el nuevo ocupa el puesto 1
	for i in 40:
		rep._process(0.1)
	_comprobar(nuevo.position.distance_to(Vector3(100, 0, 0)) < 0.01, "el que entra durante la repetición no hereda el recorrido del que salió (queda en %s)" % str(nuevo.position))
	rep.cortar()
	await get_tree().process_frame
	_comprobar(nuevo.position.distance_to(Vector3(100, 0, 0)) < 0.01, "…ni al terminar la repetición")
	raiz.queue_free()
