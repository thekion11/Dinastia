extends Node
## SONDA DE GOLES DEL PARTIDO JUGABLE C4 (17-11-2026, alarma de goles que pasó la sesión de auditoría: C4 daba ~5,5-6 goles por partido).
## Juega N partidos C4 completos en piloto automático (los dos equipos de la CPU, duración calibrada de 240 s por tiempo) entre clubes de primera de
## SEIS ligas distintas (orden 34: nunca un solo equipo) y da, por partido: goles, tiros, a puerta, paradas, postes, fuera, cabezazos, tiros desde dentro
## del área (a menos de 16,5 m del arco) y su acierto, y la distancia media del tiro. Cifras reales de referencia: ~2,6-2,8 goles y ~25 tiros por partido,
## ~8,5 a puerta, ~30 % de lo que va a puerta acaba en gol.
##   N=24 BANDERAS="C4_X=1" godot --headless --path . res://pruebas/_sonda/sonda_goles_c4.tscn      (las banderas se leen del entorno del proceso)
const DT := 1.0 / 30.0
const LIGAS: Array[String] = ["ESP", "ENG", "ITA", "GER", "ARG", "BRA"]

func _ready() -> void:
	await get_tree().process_frame
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 24
	var mitad := float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 240.0
	var m := Mundo.new()
	m.generar(LIGAS, 2611)
	var por_liga: Array = []
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and liga.clubes.size() >= 10:
			por_liga.append(liga.clubes)
	var tot := {"goles": 0, "tiros": 0, "puerta": 0, "paradas": 0, "postes": 0, "fuera": 0, "cabeza": 0, "area": 0, "area_gol": 0, "dist": 0.0, "n_dist": 0}
	var por_partido: Array = []
	for k in n:
		var la: Array = por_liga[k % por_liga.size()]
		var lb: Array = por_liga[(k + 1 + k / por_liga.size()) % por_liga.size()]
		var a: Club = la[(k * 3) % la.size()]
		var b: Club = lb[(k * 5 + 1) % lb.size()]
		var r := _jugar(a, b, mitad, 900 + k)
		por_partido.append(r["goles"])
		for c: String in tot:
			tot[c] += r[c]
		print("SONDA partido %2d %s (%s) - %s (%s): %d goles, %d tiros, %d a puerta, %d desde el área (%d gol)" % [k + 1, a.nombre, a.pais, b.nombre, b.pais,
			r["goles"], r["tiros"], r["puerta"], r["area"], r["area_gol"]])
	var media := float(tot["goles"]) / n
	var s2 := 0.0
	for g: int in por_partido:
		s2 += (g - media) * (g - media)
	print("SONDA RESUMEN %d partidos, banderas «%s»: %.2f goles (±%.2f), %.1f tiros, %.1f a puerta, %.1f paradas, %.1f postes, %.1f fuera, %.1f de cabeza; %.1f tiros desde el área (%.0f %% gol); gol/a puerta %.0f %%; distancia media del tiro %.1f m" % [
		n, OS.get_environment("BANDERAS"), media, sqrt(s2 / maxf(1.0, n - 1)) / sqrt(n), float(tot["tiros"]) / n, float(tot["puerta"]) / n, float(tot["paradas"]) / n,
		float(tot["postes"]) / n, float(tot["fuera"]) / n, float(tot["cabeza"]) / n, float(tot["area"]) / n, 100.0 * tot["area_gol"] / maxf(1.0, tot["area"]),
		100.0 * tot["goles"] / maxf(1.0, tot["puerta"]), tot["dist"] / maxf(1.0, tot["n_dist"])])
	get_tree().quit()

func _jugar(a: Club, b: Club, mitad: float, semilla: int) -> Dictionary:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorCombinado.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.duracion_mitad = mitad
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	motor.preparar(lista, ball, "", semilla)
	var r := {"goles": 0, "tiros": 0, "puerta": 0, "paradas": 0, "postes": 0, "fuera": 0, "cabeza": 0, "area": 0, "area_gol": 0, "dist": 0.0, "n_dist": 0}
	var tiro_antes: Dictionary = {}
	var en_area := {}   ## instancia del tiro → ¿desde el área?
	var goles_antes := 0
	var tope := int((mitad * 2.0 * 1.6 + 300.0) / DT)
	var i := 0
	while motor.estado != "fin" and i < tope:
		motor.paso(DT)
		i += 1
		## Un tiro nuevo: se mide desde dónde salió.
		var tv: Dictionary = motor._tiro_vivo
		if not tv.is_empty() and not is_same(tv, tiro_antes):
			var p: Dictionary = tv["p"]
			var d := motor.pos(p).distance_to(motor._arco_rival(p))
			r["dist"] += d
			r["n_dist"] += 1
			if d < 16.5:
				r["area"] += 1
			en_area = {"area": d < 16.5}
		tiro_antes = tv
		var g := int(motor.goles[0]) + int(motor.goles[1])
		if g > goles_antes and bool(en_area.get("area", false)):
			r["area_gol"] += g - goles_antes
		goles_antes = g
	r["goles"] = int(motor.goles[0]) + int(motor.goles[1])
	r["tiros"] = int(motor.tiros[0]) + int(motor.tiros[1])
	for clave: String in motor.diag:
		var c := int(motor.diag[clave])
		if clave.begins_with("remate_"):
			if clave.ends_with("_atajada"):
				r["paradas"] += c
			elif clave.ends_with("_poste"):
				r["postes"] += c
			elif clave.ends_with("_fallo"):
				r["fuera"] += c
			if clave.begins_with("remate_cabeza_"):
				r["cabeza"] += c
	r["puerta"] = r["goles"] + r["paradas"]
	raiz.queue_free()
	return r
