extends Node3D
## SONDA DEL MOTOR REAL EN EL PARTIDO DEL DT (13-10-2026). Juega partidos
## enteros sin pantalla con `MotorJugable` y compara, con las MISMAS semillas,
## lo que cambia cuando cambia algo que decide el entrenador:
##   ESCENARIO=calidad   el mejor de la liga contra el peor, y al revés de local
##   ESCENARIO=tactica   dos iguales; uno ofensivo con presión alta contra uno
##                       defensivo con línea baja (y luego al revés)
##   ESCENARIO=cambios   con cansancio real: un equipo mete 3 cambios frescos al
##                       60' y el otro no
##   godot --headless --path . res://pruebas/sonda_motor_dt.tscn   (N=partidos)
var _m: Mundo
var remates := {}

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI"], 777)
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 8
	var esc := OS.get_environment("ESCENARIO")
	if esc == "" or esc == "calidad":
		_calidad(n)
	if esc == "" or esc == "tactica":
		_tactica(n)
	if esc == "" or esc == "cambios":
		_cambios(n)
	if esc == "diag":
		_diag()
	if esc == "simetria":
		var cl := _clubes_por_media()
		var a: Club = cl[cl.size() / 2]
		print("===== SIMETRÍA: %s contra sí mismo =====" % a.nombre)
		var r: Array = []
		for i in n:
			r.append(_jugar(a, a, int(OS.get_environment("SEMILLA0")) + i if OS.get_environment("SEMILLA0") != "" else 400 + i))
		_resumen("mismo once a los dos lados", r)
	print("REMATES (todos los partidos): %s" % str(remates))
	print("===== FIN SONDA MOTOR DT =====")
	get_tree().quit()

func _clubes_por_media() -> Array:
	var cl: Array = _m.ligas[0].clubes.duplicate()
	cl.sort_custom(func(a: Club, b: Club) -> bool: return _media(a) > _media(b))
	return cl

func _media(c: Club) -> float:
	var s := 0.0
	for j in c.once():
		s += j.ovr
	return s / 11.0

## Un partido. `tac` = [local, visita]; `cambios_al_60` = cuántos cambios mete
## el local en el 60' (frescos de su banco). Devuelve [gl, gv, tiros_l, tiros_v].
func _jugar(a: Club, b: Club, semilla: int, tac: Array = [{}, {}], cansancio := false, cambios_al_60 := 0) -> Array:
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
	motor.tacticas = tac
	motor.cansancio_real = cansancio
	motor.tarjetas_reales = true
	motor.preparar(lista, ball, "", semilla)
	motor.remate.connect(func(_l: bool, _a: String, tipo: String) -> void: remates[tipo] = int(remates.get(tipo, 0)) + 1)
	motor.gol.connect(func(_l: bool, _a: String, _s: String) -> void: remates["gol"] = int(remates.get("gol", 0)) + 1)
	var hechos := false
	var dt := 1.0 / 30.0
	var pasos := 0
	while motor.estado != "fin" and pasos < 30 * 700:
		motor.paso(dt)
		pasos += 1
		if cambios_al_60 > 0 and not hechos and motor.minuto() >= 60:
			hechos = true
			var banca: Array = VistaEstadio.disponibles_fuera_del_once(a, a.once())
			var k := 0
			for j: Jugador in banca:
				if k >= cambios_al_60 or j.es_portero():
					continue
				## Sale el más cansado de campo del local.
				var peor: Dictionary = {}
				for q: Dictionary in motor.jugadores:
					if bool(q["es_local"]) and not bool(q["por"]) and (peor.is_empty() or motor.forma_fisica(q) < motor.forma_fisica(peor)):
						peor = q
				var una := Puente3D.once([j] as Array[Jugador])
				var nuevos := sp.spawn_team(raiz, una["xi"], una["jugadores"], {"s": [[j.pos_e, 50, 50]]}, true, Puente3D.kit(a))
				if not nuevos.is_empty() and motor.reemplazar(String(peor["id"]), nuevos[0]):
					k += 1
	var r := [motor.goles[0], motor.goles[1], motor.tiros[0], motor.tiros[1]]
	raiz.queue_free()
	return r

## Dónde se corta el ataque: cambios de posesión, balón en el último tercio,
## entradas, faltas y pases.
func _diag() -> void:
	var cl := _clubes_por_media()
	var a: Club = cl[cl.size() / 2]
	var b: Club = cl[cl.size() / 2 + 1]
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
	motor.preparar(lista, ball, "", 11)
	var cambios_pos := 0
	var antes := -1
	var tercio := [0.0, 0.0]
	var con_dueno := 0.0
	var total := 0.0
	var estados := {}
	var sueltos := {}
	var cerca_suelto := 0.0
	var t_suelto := 0.0
	var dt := 1.0 / 30.0
	while motor.estado != "fin":
		motor.paso(dt)
		estados[motor.estado] = float(estados.get(motor.estado, 0.0)) + dt
		if motor.estado != "juego":
			continue
		total += dt
		var eq := -1
		if not motor.poseedor.is_empty():
			eq = 0 if bool(motor.poseedor["es_local"]) else 1
			con_dueno += dt
		if eq >= 0 and eq != antes:
			if antes >= 0:
				cambios_pos += 1
			antes = eq
		if motor.poseedor.is_empty():
			var vb: Vector3 = motor.vel_balon
			var tipo_s := "aire" if ball.position.y > 0.3 else ("rapido" if Vector2(vb.x, vb.z).length() > 3.0 else ("lento" if Vector2(vb.x, vb.z).length() > 0.5 else "parado"))
			sueltos[tipo_s] = float(sueltos.get(tipo_s, 0.0)) + dt
			## Quién está más cerca del balón parado/lento.
			if tipo_s == "parado" or tipo_s == "lento":
				var md := 99.0
				for q: Dictionary in motor.jugadores:
					md = minf(md, Vector2(motor.pos(q).x - ball.position.x, motor.pos(q).z - ball.position.z).length())
				cerca_suelto += md * dt
				t_suelto += dt
		if ball.position.z > 17.5:
			tercio[0] += dt
		elif ball.position.z < -17.5:
			tercio[1] += dt
	print("DIAG goles %s tiros %s faltas %s córners %s" % [str(motor.goles), str(motor.tiros), str(motor.faltas), str(motor.corners)])
	print("DIAG pases %s llegaron %s despejes %s" % [str(motor.pases), str(motor.pases_ok), str(motor.despejes)])
	print("DIAG tiempo por estado %s" % str(estados))
	print("DIAG en juego %.0f s, con dueño %.0f %%, cambios de posesión %d (%.1f por minuto de juego)" % [total, 100.0 * con_dueno / total, cambios_pos, cambios_pos / (total / 60.0)])
	print("DIAG balón suelto por tipo (s): %s ; distancia media del más cercano al balón quieto/lento: %.1f m" % [str(sueltos), cerca_suelto / maxf(t_suelto, 0.01)])
	print("DIAG balón en el último tercio: local ataca %.0f %%, visita ataca %.0f %%" % [100.0 * tercio[0] / total, 100.0 * tercio[1] / total])

func _resumen(nombre: String, res: Array) -> void:
	var g := [0, 0]
	var t := [0, 0]
	var gana := [0, 0, 0]
	for r: Array in res:
		g[0] += int(r[0]); g[1] += int(r[1]); t[0] += int(r[2]); t[1] += int(r[3])
		gana[0 if r[0] > r[1] else (2 if r[0] < r[1] else 1)] += 1
	var n := float(maxi(res.size(), 1))
	print("  %-46s goles %.2f-%.2f  tiros %.1f-%.1f  G/E/P local %d/%d/%d" % [nombre, g[0] / n, g[1] / n, t[0] / n, t[1] / n, gana[0], gana[1], gana[2]])

func _calidad(n: int) -> void:
	var cl := _clubes_por_media()
	var mejor: Club = cl[0]
	var peor: Club = cl[cl.size() - 1]
	print("===== CALIDAD: %s (%.1f) vs %s (%.1f) =====" % [mejor.nombre, _media(mejor), peor.nombre, _media(peor)])
	var r1: Array = []
	var r2: Array = []
	for i in n:
		r1.append(_jugar(mejor, peor, 100 + i))
		r2.append(_jugar(peor, mejor, 100 + i))
	_resumen("el mejor de local", r1)
	_resumen("el peor de local", r2)

func _tactica(n: int) -> void:
	var cl := _clubes_por_media()
	var a: Club = cl[cl.size() / 2]
	var b: Club = cl[cl.size() / 2 + 1]
	print("===== TÁCTICA: %s (%.1f) vs %s (%.1f) =====" % [a.nombre, _media(a), b.nombre, _media(b)])
	var ofe := {"mentalidad": 2, "presion": 2, "linea": 2, "ritmo": 2, "amplitud": 2}
	var defe := {"mentalidad": 0, "presion": 0, "linea": 0, "ritmo": 0, "amplitud": 1}
	var r0: Array = []
	var r1: Array = []
	var r2: Array = []
	for i in n:
		r0.append(_jugar(a, b, 200 + i))
		r1.append(_jugar(a, b, 200 + i, [ofe, {}]))
		r2.append(_jugar(a, b, 200 + i, [defe, {}]))
	_resumen("los dos con la pizarra media", r0)
	_resumen("local ofensivo, presión y línea altas", r1)
	_resumen("local defensivo, presión y línea bajas", r2)

func _cambios(n: int) -> void:
	var cl := _clubes_por_media()
	var a: Club = cl[cl.size() / 2]
	var b: Club = cl[cl.size() / 2 + 1]
	print("===== CAMBIOS CON CANSANCIO: %s vs %s =====" % [a.nombre, b.nombre])
	var r0: Array = []
	var r1: Array = []
	for i in n:
		r0.append(_jugar(a, b, 300 + i, [{}, {}], true, 0))
		r1.append(_jugar(a, b, 300 + i, [{}, {}], true, 3))
	_resumen("sin cambios", r0)
	_resumen("local con 3 cambios frescos al 60'", r1)
