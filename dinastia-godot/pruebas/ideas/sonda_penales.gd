extends BaseIdea
## SONDA DE PENALES EN PARTIDO (2-11, líder): ¿qué % se marca? En el fútbol, ~75 % (el 25-10 el motor daba 43 %). Sirve también para
## comprobar que la lectura del lanzador del portero (M-119, `PenalPortero`) no lo hunde. N penales del mismo equipo con semillas distintas,
## el lanzador y el portero llevados por la IA; se cuenta gol / parada / fuera. NO es una prueba de azar fino: el rango es amplio a propósito.
## NUMERO=n cambia cuántos (por defecto 60; con 120 el error típico es ~4 puntos, con 300 ~2,6).

const DT := 1.0 / 60.0

func _probar() -> void:
	_titulo("SONDA: % DE PENALES MARCADOS EN PARTIDO")
	var n := int(OS.get_environment("NUMERO")) if OS.get_environment("NUMERO") != "" else 120
	var r := _motor()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	var goles := 0
	var detalle: Array = []
	motor.remate.connect(func(_l: bool, _a: String, tipo: String) -> void:
		if tipo == "fallo" and detalle.size() < 12:
			detalle.append("x %.1f y %.1f z %.1f v %.1f" % [motor.balon.position.x, motor.balon.position.y, motor.balon.position.z, motor.vel_balon.length()]))
	var salidas := {}
	var sin_resolver := 0
	for i in n:
		## Mitad con cada equipo, en bloques: así los 10 de campo ya están fuera del área (si se alternara cada vez, correrían 100 m en 4 s
		## y bloquearían el tiro: un artefacto de la sonda, no del juego). El primero de cada bloque es de calentamiento y no cuenta.
		var saca_local := i < n / 2
		var cuenta := i != 0 and i != n / 2
		motor._rng.seed = 1000 + i * 7919
		motor.estado = "juego"
		motor.poseedor = {}
		motor._tiro_vivo = {}
		motor.saque = {}
		motor.autopiloto = true
		motor.control_equipo = -1
		motor.diag = {}
		var antes: int = int(motor.goles[0]) + int(motor.goles[1])
		var arco := Vector3(0, 0, MotorJugable.LARGO * MotorJugable.dir_ataque(saca_local))
		motor._empezar_saque("penal", saca_local, Vector3(0, MotorJugable.R, arco.z - signf(arco.z) * MotorJugable.PUNTO_PENAL))
		var resultado := ""
		for paso in int(25.0 / DT):
			motor.paso(DT)
			if int(motor.goles[0]) + int(motor.goles[1]) > antes:
				resultado = "gol"
				break
			for k: String in motor.diag:
				if k.begins_with("remate_penal_"):
					resultado = k.trim_prefix("remate_penal_")
			if resultado != "":
				break
		if not cuenta:
			continue
		if resultado == "":
			sin_resolver += 1
			resultado = "sin resolver"
		salidas[resultado] = int(salidas.get(resultado, 0)) + 1
		if resultado == "gol":
			goles += 1
		motor.vel_balon = Vector3.ZERO
	var dec := n - 2 - sin_resolver
	var pct := 100.0 * float(goles) / maxf(1.0, float(dec))
	if OS.get_environment("DETALLE") != "":
		print("  fallos: ", detalle)
	print("  penales %d: %s  →  %.0f %% marcados" % [n, str(salidas), pct])
	_comprobar(sin_resolver <= maxi(1, n / 20), "casi todos los penales se resuelven (%d sin resolver de %d)" % [sin_resolver, n])
	_comprobar(pct >= 62.0 and pct <= 86.0, "el %% de penales marcados es de fútbol (%.0f %%; objetivo ~75 %%, banda 62-86)" % pct)
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
	return [motor, raiz, a]
