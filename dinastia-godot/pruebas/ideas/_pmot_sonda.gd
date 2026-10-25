extends Node
## SONDA DEL PULIDO DEL PARTIDO (25-10-2026, prefijo pmot). No es una prueba (empieza por «_»: `ideas.sh todo`
## no la corre). Juega N partidos enteros con `MotorJugable` y saca lo que la sonda del DT no enseña: los
## remates por clase (pie, cabeza, falta, penal) y cómo acaban, la puntería, las paradas, las cargas legales
## y las tarjetas. Con PMOT=0 / PMOT=1 se comparan, con las mismas semillas, el motor de antes y el pulido.
##   PMOT=1 N=20 ESC=medio|calidad SEMILLA0=900 MITAD=240 godot --headless --path . res://pruebas/ideas/_pmot_sonda.tscn

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var cl: Array = m.ligas[0].clubes.duplicate()
	cl.sort_custom(func(a: Club, b: Club) -> bool: return _media(a) > _media(b))
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 6
	var s0 := int(OS.get_environment("SEMILLA0")) if OS.get_environment("SEMILLA0") != "" else 900
	var esc := OS.get_environment("ESC") if OS.get_environment("ESC") != "" else "medio"
	var a: Club = cl[cl.size() / 2]
	var b: Club = cl[cl.size() / 2 + 1]
	if esc == "calidad":
		a = cl[0]
		b = cl[cl.size() - 1]
	var tot := {}
	var gana := [0, 0, 0]
	for i in n:
		## Se alterna quién juega de local (el sesgo de campo no se cuela).
		var loc := a if i % 2 == 0 else b
		var vis := b if i % 2 == 0 else a
		var r := _jugar(loc, vis, s0 + i)
		var ga: int = int(r["goles_a"]) if i % 2 == 0 else int(r["goles_b"])
		var gb: int = int(r["goles_b"]) if i % 2 == 0 else int(r["goles_a"])
		gana[0 if ga > gb else (2 if ga < gb else 1)] += 1
		for k: String in r:
			tot[k] = float(tot.get(k, 0.0)) + float(r[k])
	var np := float(maxi(n, 1))
	var txt := ""
	var claves: Array = tot.keys()
	claves.sort()
	for k: String in claves:
		txt += "%s %.2f  " % [k, float(tot[k]) / np]
	print("PMOT %s PMOT=%s N=%d  G/E/P de %s: %d/%d/%d" % [esc, OS.get_environment("PMOT"), n, a.nombre, gana[0], gana[1], gana[2]])
	print("PMOT_POR_PARTIDO " + txt)
	var pases := float(tot.get("pases", 0.0))
	print("PMOT_RESUMEN goles %.2f tiros %.1f a_puerta %.1f paradas %.0f %% pases %.0f %% faltas %.1f amarillas %.2f rojas %.2f" % [
		float(tot.get("goles", 0.0)) / np, float(tot.get("tiros", 0.0)) / np, float(tot.get("a_puerta", 0.0)) / np,
		100.0 * float(tot.get("atajadas", 0.0)) / maxf(float(tot.get("atajadas", 0.0)) + float(tot.get("goles_de_tiro", 0.0)), 1.0),
		100.0 * float(tot.get("pases_ok", 0.0)) / maxf(pases, 1.0), float(tot.get("faltas", 0.0)) / np,
		float(tot.get("amarillas", 0.0)) / np, float(tot.get("rojas", 0.0)) / np])
	print("===== FIN SONDA PMOT =====")
	get_tree().quit()

func _media(c: Club) -> float:
	var s := 0.0
	for j in c.once():
		s += j.ovr
	return s / 11.0

func _jugar(a: Club, b: Club, semilla: int) -> Dictionary:
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
	motor.duracion_mitad = float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 240.0
	motor.tarjetas_reales = true
	motor.preparar(lista, ball, "", semilla)
	var dt := 1.0 / 30.0
	var pasos := 0
	while motor.estado != "fin" and pasos < 30 * 900:
		motor.paso(dt)
		pasos += 1
	var r := {"goles_a": motor.goles[0], "goles_b": motor.goles[1]}
	r["goles"] = int(motor.goles[0]) + int(motor.goles[1])
	r["tiros"] = int(motor.tiros[0]) + int(motor.tiros[1])
	r["pases"] = int(motor.pases[0]) + int(motor.pases[1])
	r["pases_ok"] = int(motor.pases_ok[0]) + int(motor.pases_ok[1])
	r["faltas"] = int(motor.faltas[0]) + int(motor.faltas[1])
	r["corners"] = int(motor.corners[0]) + int(motor.corners[1])
	r["fueras"] = int(motor.fueras_de_juego[0]) + int(motor.fueras_de_juego[1])
	r["amarillas"] = int(motor.tarjetas_motor[0][0]) + int(motor.tarjetas_motor[1][0])
	r["rojas"] = int(motor.tarjetas_motor[0][1]) + int(motor.tarjetas_motor[1][1])
	r["fintas"] = motor.regates_ia
	var at := 0
	var gt := 0
	var ap := 0
	for k: String in motor.diag:
		r["d_" + k] = motor.diag[k]
		if k.begins_with("remate_") and k.ends_with("_atajada"):
			at += int(motor.diag[k])
		if k.begins_with("gol_") and k != "gol_sin_tiro":
			gt += int(motor.diag[k])
		if k.begins_with("a_puerta_"):
			ap += int(motor.diag[k])
	r["atajadas"] = at
	r["goles_de_tiro"] = gt
	r["a_puerta"] = ap + int(motor.diag.get("tiro_cabeza", 0))
	for k: String in motor.duelos:
		r["duelo_" + k] = motor.duelos[k]
	raiz.queue_free()
	return r
