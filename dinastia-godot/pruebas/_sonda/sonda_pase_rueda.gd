extends Node
## (16-11, informe M6-06) ¿Cuánto rueda de verdad un pase raso de N m en cada motor? Pide la velocidad como la piden
## `_pase_manual` (usuario) y `_pasar_a` (IA) y deja rodar el balón con la física del motor (sin jugadores cerca).
## Uso: godot --headless --path . res://pruebas/_sonda/sonda_pase_rueda.tscn

func _ready() -> void:
	var mu := Mundo.new()
	mu.generar(["ARG", "ESP"], 31)
	for cual in ["siempre", "combinado_c4"]:
		var raiz := Node3D.new()
		add_child(raiz)
		var sp := PlayerSpawner.new()
		var lista: Array = []
		var a: Club = mu.ligas[0].clubes[2]
		var b: Club = mu.ligas[mu.ligas.size() - 1].clubes[3]
		var l := Puente3D.once(a.once())
		var v := Puente3D.once(b.once())
		lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
		lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
		var mo: MotorJugable = MotorFabrica.crear(cual)
		raiz.add_child(mo)
		mo.set_physics_process(false)
		var bola := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
		mo.preparar(lista, bola, "", 5)
		for clima in ["", "lluvia", "nieve"]:
			GestoTecnico.fijar_clima(mo, clima)
			var linea := "%s %s:" % [cual, clima if clima != "" else "sol"]
			for n: float in [8.0, 12.0, 16.0, 20.0, 25.0, 30.0]:
				var vu := clampf(_vel(mo, n, 4.0), 7.0, 24.0)
				var vi := clampf(_vel(mo, n, 4.0 + n * 1.5) * MotorPaseMejora.vel_k, 7.0, 26.0 * MotorPaseMejora.vel_k)
				linea += "\n   %dm: usuario %.1f m/s -> %.1f m | IA %.1f m/s -> %.1f m" % [int(n), vu, _rueda(mo, bola, vu), vi, _rueda(mo, bola, vi)]
			print(linea)
			var bote := "%s %s, a media altura (`_pasar_a` largo):" % [cual, clima if clima != "" else "sol"]
			for n: float in [24.0, 28.0, 32.0, 36.0]:
				bote += "  %dm -> cae a %.1f m, para a %.1f m" % _bombeado(mo, bola, n)
			print(bote)
		raiz.queue_free()
	print("FIN sonda")
	get_tree().quit()

func _bombeado(mo: MotorJugable, bola: Node3D, n: float) -> Array:
	var p: Dictionary = mo.jugadores[5]
	mo.poseedor = {}
	mo.estado = "saque"
	bola.position = Vector3(0, 0.11, -45.0)
	mo.vel_balon = Vector3.ZERO
	mo._patear(p, Vector3(0, 0.11, -45.0 + n), clampf(n * 0.45 + 6.0, 10.0, 19.0), 1.0, 0.0, "pase")
	var cae := -1.0
	var alto := false
	for i in 1200:
		mo._mover_balon(1.0 / 60.0)
		if bola.position.y > 0.4:
			alto = true
		elif alto and cae < 0.0:
			cae = bola.position.z + 45.0
		if mo.vel_balon.length() < 0.05:
			break
	return [int(n), cae, bola.position.z + 45.0]

func _vel(mo: MotorJugable, n: float, sobra: float) -> float:
	return float(mo.call("_velocidad_pase", n, sobra)) if mo.has_method("_velocidad_pase") else MotorJugable.velocidad_para(n, sobra)

func _rueda(mo: MotorJugable, bola: Node3D, v0: float) -> float:
	mo.poseedor = {}
	mo.estado = "saque"
	bola.position = Vector3(0, 0.11, -45.0)
	mo.vel_balon = Vector3(0, 0, v0)
	mo.giro_balon = Vector3.ZERO
	for i in 1200:
		mo._mover_balon(1.0 / 60.0)
		if mo.vel_balon.length() < 0.05:
			break
	return bola.position.z + 45.0
