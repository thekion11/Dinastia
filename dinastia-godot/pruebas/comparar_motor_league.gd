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
			"despejes_pp": snappedf(float(s["despejes"]) / c, 0.1), "posesion_local_pct": snappedf(float(s["poses_local"]) / c, 0.1)})
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
		var par := [pa[(i * 3) % pa.size()], pb[(i * 5 + 1) % pb.size()]]
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
	motor.preparar(lista, ball, "", semilla)
	var us := 0
	var us_max := 0
	var pasos := 0
	var tope := int((mitad * 2.0 * 1.6 + 300.0) / DT)   ## saques, goles, descanso y añadido alargan el partido
	while motor.estado != "fin" and pasos < tope:
		var t0 := Time.get_ticks_usec()
		motor.paso(DT)
		var d := Time.get_ticks_usec() - t0
		us += d
		us_max = maxi(us_max, d)
		pasos += 1
	if motor.estado != "fin":
		fallos += 1
		print("FALLO: el partido no terminó (", a.nombre, " - ", b.nombre, ")")
	var pt := float(motor.posesion[0]) + float(motor.posesion[1])
	var r := {"partido": "%s (%s) - %s (%s)" % [a.nombre, a.pais, b.nombre, b.pais], "marcador": "%d-%d" % [motor.goles[0], motor.goles[1]],
		"pasos": pasos, "us_paso": snappedf(float(us) / maxf(float(pasos), 1.0), 0.1), "us_max": us_max,
		"tiros": int(motor.tiros[0]) + int(motor.tiros[1]), "pases": int(motor.pases[0]) + int(motor.pases[1]),
		"pases_ok": int(motor.pases_ok[0]) + int(motor.pases_ok[1]), "despejes": int(motor.despejes[0]) + int(motor.despejes[1]),
		"poses_local": snappedf(100.0 * float(motor.posesion[0]) / pt, 0.1) if pt > 0.0 else 50.0}
	if league:
		r["decisiones"] = (motor as MotorLeague).cuenta.duplicate()
	r["huella"] = "%s|%d|%d|%d|%.3f,%.3f" % [r["marcador"], r["tiros"], r["pases"], r["pases_ok"], ball.position.x, ball.position.z]
	raiz.queue_free()
	return r

func _sumar(s: Dictionary, r: Dictionary) -> void:
	s["partidos"] = int(s.get("partidos", 0)) + 1
	for k: String in ["us_paso", "tiros", "pases", "pases_ok", "despejes", "poses_local"]:
		s[k] = float(s.get(k, 0.0)) + float(r[k])
	var g: PackedStringArray = String(r["marcador"]).split("-")
	s["goles"] = int(s.get("goles", 0)) + int(g[0]) + int(g[1])
	s["us_max"] = maxi(int(s.get("us_max", 0)), int(r["us_max"]))
