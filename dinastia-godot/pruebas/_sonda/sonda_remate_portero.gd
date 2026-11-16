extends Node
## (16-11, informe AAA H1) REMATE CONTRA EL PORTERO, AISLADO: el tirador solo frente al portero (los demás lejos), 140 remates por
## distancia con apunte y fuerza al azar (semilla fija). Cuenta gol, parada (el portero toca o se queda el balón) y fuera, y da el %
## de gol de lo que va entre los palos. Sirve para ajustar el portero sin el ruido de un partido entero.
##   MOTOR=combinado_c4 godot --headless --path . res://pruebas/_sonda/sonda_remate_portero.tscn
## Referencia real (Opta, primeras divisiones): el portero para ~70 % de lo que va a puerta; desde fuera del área, ~85 %.

func _ready() -> void:
	seed(7)
	var mu := Mundo.new()
	mu.generar(["ARG", "ESP"], 31)
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
	var mo: MotorJugable = MotorFabrica.crear(OS.get_environment("MOTOR") if OS.get_environment("MOTOR") != "" else "combinado_c4")
	raiz.add_child(mo)
	mo.set_physics_process(false)
	mo.autopiloto = true
	var bola := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	mo.preparar(lista, bola, "", 5)
	var tirador: Dictionary = mo.jugadores[9]
	var gk: Dictionary = {}
	for q: Dictionary in mo.jugadores:
		if not bool(q["es_local"]) and bool(q["por"]):
			gk = q
	var arco: Vector3 = mo._arco_rival(tirador)
	var total := {"gol": 0, "parada": 0}
	for dist: float in [8.0, 12.0, 16.0, 22.0, 28.0]:
		var res := {"gol": 0, "parada": 0, "fuera": 0, "suelto": 0}
		for k in 140:
			mo.estado = "juego"
			mo.t = 10.0
			mo.set("_tiro_vivo", {})
			for q: Dictionary in mo.jugadores:
				if q != tirador and q != gk:
					(q["node"] as Node3D).position = Vector3(30.0 * (1 if bool(q["es_local"]) else -1), 0, 0)
					q["enfriar"] = 5.0
			var ang := deg_to_rad(float(k % 7 - 3) * 8.0)
			var donde := Vector3(arco.x + sin(ang) * dist, 0, arco.z - signf(arco.z) * cos(ang) * dist)
			(tirador["node"] as Node3D).position = donde
			(gk["node"] as Node3D).position = arco + Vector3(0, 0, -signf(arco.z) * 1.0)
			gk["vel"] = Vector3.ZERO
			for c: String in ["parada_pend", "_patada_vista"]:
				gk.erase(c)
			gk["gesto_hasta"] = 0.0
			gk["enfriar"] = 0.0
			mo.balon.position = donde + Vector3(0, 0.11, 0)
			mo.vel_balon = Vector3.ZERO
			mo.poseedor = {}
			mo._tomar(tirador)
			var g0: int = mo.goles[0]
			mo._tirar(tirador, Vector2(randf_range(-1, 1), randf_range(-0.8, 0.2)), randf_range(0.4, 1.0))
			var toco := false
			for i in 150:
				mo.paso(1.0 / 60.0)
				toco = toco or mo.ultimo_toque == gk
				if int(mo.goles[0]) > g0 or mo.estado != "juego" or not mo.poseedor.is_empty():
					break
			var r := "gol" if int(mo.goles[0]) > g0 else ("parada" if toco or mo.poseedor == gk else ("fuera" if mo.estado != "juego" else "suelto"))
			res[r] += 1
			mo.goles = [0, 0]
		total["gol"] += int(res["gol"])
		total["parada"] += int(res["parada"])
		print("%d m: %s · gol de lo que va a puerta %.0f %%" % [int(dist), str(res), 100.0 * float(res["gol"]) / maxf(1.0, float(res["gol"] + res["parada"]))])
	print("TOTAL gol de lo que va a puerta %.0f %% (real ~30 %%)" % (100.0 * float(total["gol"]) / maxf(1.0, float(total["gol"] + total["parada"]))))
	print("FIN")
	get_tree().quit()
