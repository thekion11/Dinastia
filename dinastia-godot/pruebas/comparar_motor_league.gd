extends Node
## COMPARAR EL MOTOR DE LEAGUE-SOCCER CON EL DE SIEMPRE (10-11-2026; plan en `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`).
## Partidos COMPLETOS en autopiloto (dos mitades hasta «fin», sin pantalla), con clubes de VARIOS países y emparejamientos
## distintos (orden 34: nunca un solo equipo). Para cada uno juega primero `MotorJugable` y luego `MotorLeague` con la misma
## semilla y los mismos onces. Mide: µs de CPU por paso, goles, remates, pases y acierto, posesión, despejes y las decisiones
## de League (pase, pánico, tiro, conducir). Al final repite el primer partido de League para comprobar el DETERMINISMO.
##   N_PARTIDOS=6 MITAD=240 [INVERTIR=1] godot --headless --path . res://pruebas/comparar_motor_league.tscn
## Salida: líneas «LIGA_CMP …» (una por partido y motor), «LIGA_RES …» (medias) y «LIGA_DET …»; termina en «FIN. N fallos».
const PAISES: Array[String] = ["CHI", "ARG", "ESP", "ENG", "BRA", "ITA"]
const DT := 1.0 / 30.0

var fallos := 0

func _ready() -> void:
	await get_tree().process_frame
	var n := int(OS.get_environment("N_PARTIDOS")) if OS.get_environment("N_PARTIDOS") != "" else 6
	var mitad := float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 240.0
	var m := Mundo.new()
	m.generar(PAISES, 4711)
	var pares := _pares(m, n)
	var suma := [{}, {}]
	var primera_huella := ""
	for k in pares.size():
		var par: Array = pares[k]
		for cual in 2:
			var r := _jugar(par[0], par[1], 100 + k, cual == 1, mitad)
			_sumar(suma[cual], r)
			print("LIGA_CMP ", "league " if cual == 1 else "siempre", " ", r)
			if k == 0 and cual == 1:
				primera_huella = String(r["huella"])
	for cual in 2:
		var s: Dictionary = suma[cual]
		var c := maxf(float(s.get("partidos", 1)), 1.0)
		print("LIGA_RES ", "league " if cual == 1 else "siempre", " ", {
			"partidos": s.get("partidos", 0), "us_paso": snappedf(float(s["us_paso"]) / c, 0.1), "us_paso_max": s.get("us_max", 0),
			"goles_pp": snappedf(float(s["goles"]) / c, 0.01), "tiros_pp": snappedf(float(s["tiros"]) / c, 0.1),
			"pases_pp": snappedf(float(s["pases"]) / c, 0.1), "acierto_pase_pct": snappedf(100.0 * float(s["pases_ok"]) / maxf(float(s["pases"]), 1.0), 0.1),
			"despejes_pp": snappedf(float(s["despejes"]) / c, 0.1), "posesion_local_pct": snappedf(float(s["poses_local"]) / c, 0.1),
			"cambios_posesion_pp": snappedf(float(s["cambios_posesion"]) / c, 0.1)})
	## Determinismo: el mismo partido, con la misma semilla, tiene que dar EXACTAMENTE lo mismo.
	var par0: Array = pares[0]
	var otra := String(_jugar(par0[0], par0[1], 100, true, mitad)["huella"])
	var igual := otra == primera_huella
	print("LIGA_DET ", "IGUAL" if igual else "DISTINTO", " ", primera_huella, " | ", otra)
	if not igual:
		fallos += 1
	print("FIN. %d fallos" % fallos)
	get_tree().quit()

## Emparejamientos: cada partido entre clubes de dos países distintos, con clubes distintos cada vez.
func _pares(m: Mundo, n: int) -> Array:
	var por_pais := {}
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and not liga.clubes.is_empty():
			por_pais[liga.pais] = liga.clubes
	var paises := por_pais.keys()
	var r: Array = []
	for i in n:
		var pa: Array = por_pais[paises[i % paises.size()]]
		var pb: Array = por_pais[paises[(i + 1) % paises.size()]]
		## Estilos DISTINTOS en cada cruce (posesión contra bloque bajo, presión contra contra…: `EstiloClub`).
		var ca: Club = pa[(i * 3) % pa.size()]
		var cb: Club = pb[(i * 5 + 1) % pb.size()]
		for k in pb.size():
			var otro: Club = pb[(i * 5 + 1 + k) % pb.size()]
			if EstiloClub.estilo_de(otro) != EstiloClub.estilo_de(ca):
				cb = otro
				break
		var par := [ca, cb]
		if OS.get_environment("INVERTIR") == "1":   ## los mismos cruces con local y visita cambiados (asimetrías)
			par.reverse()
		r.append(par)
	return r

func _jugar(a: Club, b: Club, semilla: int, league: bool, mitad: float) -> Dictionary:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor: MotorJugable = MotorLeague.new() if league else MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = mitad
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]   ## la pizarra y el estilo de cada club
	motor.preparar(lista, ball, "", semilla)
	## LS_CAM=1: una cámara de televisión (de lado, alta, siguiendo al balón) para que cuente el recorte fuera de cámara de la locomoción.
	var cam: Camera3D = null
	if OS.get_environment("LS_CAM") == "1":
		cam = Camera3D.new()
		cam.fov = 40.0
		raiz.add_child(cam)
		cam.make_current()
	var loco_us0 := LeagueLocomocion.us_total
	var loco_p0 := LeagueLocomocion.pasos
	var us := 0
	var us_max := 0
	var pasos := 0
	var tope := int((mitad * 2.0 * 1.6 + 300.0) / DT)   ## saques, goles, descanso y añadido alargan el partido
	var cambios := 0
	var ult := -1
	var prev := {}   ## id → velocidad del paso anterior (MOVIMIENTO: sacudidas y giros)
	var hist := PackedInt32Array()
	hist.resize(40)
	var suma_a := 0.0
	var n_a := 0
	var suma_giro := 0.0
	var n_giro := 0
	LeagueGuia.reiniciar_cuenta()
	while motor.estado != "fin" and pasos < tope:
		if cam != null:
			cam.position = Vector3(ball.position.x * 0.8 + 62.0, 24.0, ball.position.z * 0.8)
			cam.look_at(Vector3(ball.position.x * 0.8, 0.0, ball.position.z * 0.8))
		var t0 := Time.get_ticks_usec()
		motor.paso(DT)
		if not motor.poseedor.is_empty():
			var eqp := 0 if bool(motor.poseedor["es_local"]) else 1
			if ult != -1 and eqp != ult:
				cambios += 1
			ult = eqp
		var d := Time.get_ticks_usec() - t0
		if motor.estado == "juego":
			for q: Dictionary in motor.jugadores:
				var vq := Vector2((q["vel"] as Vector3).x, (q["vel"] as Vector3).z)
				if prev.has(q["id"]):
					var vp: Vector2 = prev[q["id"]]
					var ac := (vq - vp).length() / DT
					hist[mini(int(ac), 39)] += 1
					suma_a += ac
					n_a += 1
					if vq.length() > 3.0 and vp.length() > 3.0:
						suma_giro += absf(vp.angle_to(vq)) / DT
						n_giro += 1
				prev[q["id"]] = vq
		us += d
		us_max = maxi(us_max, d)
		pasos += 1
	if motor.estado != "fin":
		fallos += 1
		print("FALLO: el partido no terminó (", a.nombre, " - ", b.nombre, ")")
	var pt := float(motor.posesion[0]) + float(motor.posesion[1])
	var r := {"partido": "%s (%s, %s %s) - %s (%s, %s %s)" % [a.nombre, a.pais, a.tactica.formacion, EstiloClub.estilo_de(a), b.nombre, b.pais, b.tactica.formacion, EstiloClub.estilo_de(b)], "marcador": "%d-%d" % [motor.goles[0], motor.goles[1]],
		"pasos": pasos, "us_paso": snappedf(float(us) / maxf(float(pasos), 1.0), 0.1), "us_max": us_max,
		"tiros": int(motor.tiros[0]) + int(motor.tiros[1]), "pases": int(motor.pases[0]) + int(motor.pases[1]),
		"pases_ok": int(motor.pases_ok[0]) + int(motor.pases_ok[1]), "despejes": int(motor.despejes[0]) + int(motor.despejes[1]),
		"poses_local": snappedf(100.0 * float(motor.posesion[0]) / pt, 0.1) if pt > 0.0 else 50.0, "cambios_posesion": cambios}
	if league:
		r["decisiones"] = (motor as MotorLeague).cuenta.duplicate()
		r["toques"] = (motor as MotorLeague).cuenta_toques.duplicate()
		var corte95 := int(0.95 * float(n_a))
		var acum := 0
		var p95 := 0
		for k in 40:
			acum += hist[k]
			if acum >= corte95:
				p95 = k
				break
		r["mov"] = {"acel_media": snappedf(suma_a / maxf(1.0, float(n_a)), 0.01), "acel_p95": p95, "giro_medio": snappedf(suma_giro / maxf(1.0, float(n_giro)), 0.01),
			"guiados": LeagueGuia.guiados, "cortes": LeagueGuia.cortes}
		r["us_loco"] = snappedf(float(LeagueLocomocion.us_total - loco_us0) / maxf(1.0, float(LeagueLocomocion.pasos - loco_p0)), 0.1)
	r["huella"] = "%s|%d|%d|%d|%.3f,%.3f" % [r["marcador"], r["tiros"], r["pases"], r["pases_ok"], ball.position.x, ball.position.z]
	raiz.queue_free()
	return r

func _sumar(s: Dictionary, r: Dictionary) -> void:
	s["partidos"] = int(s.get("partidos", 0)) + 1
	for k: String in ["us_paso", "tiros", "pases", "pases_ok", "despejes", "poses_local", "cambios_posesion"]:
		s[k] = float(s.get(k, 0.0)) + float(r[k])
	var g: PackedStringArray = String(r["marcador"]).split("-")
	s["goles"] = int(s.get("goles", 0)) + int(g[0]) + int(g[1])
	s["us_max"] = maxi(int(s.get("us_max", 0)), int(r["us_max"]))
