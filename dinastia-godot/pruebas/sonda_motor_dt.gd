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
##   ESCENARIO=simetria  el mismo once a los dos lados (sesgo de local). Para
##                       cazar sesgos hace falta N grande: N=25 en 4 procesos con
##                       SEMILLA0=400/500/600/700 y MITAD=120 (≈11 min); la línea
##                       LADOS da goles/tiros/córners/faltas/fueras/despejes L-V.
##   TRAMPA=1  la visita con la trampa del fuera de juego (fueras L-V en LADOS).
##   SEMILLA0=primera semilla, MITAD=segundos de motor por tiempo (240).
var _m: Mundo
var duelos_tot := {}
var remates := {}
## Totales de todos los partidos: pases [L, V], pases buenos, fintas de la IA
## (intentadas, logradas), posesión en segundos [L, V] y partidos jugados.
var extra := {"pases": [0, 0], "pases_ok": [0, 0], "fintas": 0, "fintas_ok": 0, "posesion": [0.0, 0.0], "partidos": 0,
	"faltas": [0, 0], "corners": [0, 0], "fueras": [0, 0], "despejes": [0, 0], "goles": [0, 0], "tiros": [0, 0],
	"amarillas": [0, 0], "rojas": [0, 0]}

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
			r.append(_jugar(a, a, _s0(400) + i))
		_resumen("mismo once a los dos lados", r)
	print("REMATES (todos los partidos): %s" % str(remates))
	var np := float(maxi(int(extra["partidos"]), 1))
	var pt: Array = extra["pases"]
	var po: Array = extra["pases_ok"]
	var ps: Array = extra["posesion"]
	print("PASES buenos L %.0f %%  V %.0f %%  | POSESIÓN L %.0f %% | FINTAS IA %.1f por partido (%.0f %% logradas)" % [
		100.0 * po[0] / maxf(pt[0], 1.0), 100.0 * po[1] / maxf(pt[1], 1.0), 100.0 * ps[0] / maxf(ps[0] + ps[1], 0.01),
		float(extra["fintas"]) / np, 100.0 * float(extra["fintas_ok"]) / maxf(float(extra["fintas"]), 1.0)])
	## Lado a lado (L-V) por partido: para cazar sesgos de campo.
	var lado := ""
	for k: String in ["goles", "tiros", "corners", "faltas", "fueras", "despejes", "amarillas", "rojas"]:
		lado += "%s %.2f-%.2f  " % [k, float(extra[k][0]) / np, float(extra[k][1]) / np]
	print("LADOS " + lado)
	var du_txt := ""
	for k: String in duelos_tot:
		du_txt += "%s %.1f  " % [k, float(duelos_tot[k]) / np]
	print("DUELOS por partido: " + du_txt)
	print("===== FIN SONDA MOTOR DT =====")
	get_tree().quit()

## Primera semilla: SEMILLA0 (para repartir una sonda larga en varios procesos)
## o la de siempre del escenario.
func _s0(por_defecto: int) -> int:
	return int(OS.get_environment("SEMILLA0")) if OS.get_environment("SEMILLA0") != "" else por_defecto

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
	## TRAMPA=1: la visita juega con la trampa del fuera de juego (M-123).
	if OS.get_environment("TRAMPA") != "":
		motor.tacticas = [(tac[0] as Dictionary).duplicate() if tac.size() > 0 else {}, (tac[1] as Dictionary).duplicate() if tac.size() > 1 else {}]
		motor.tacticas[1]["trampa"] = 1
	motor.cansancio_real = cansancio
	motor.tarjetas_reales = true
	motor.preparar(lista, ball, "", semilla)
	## SIN_DUELOS=1 / SIN_CUERPOS=1: para medir qué cambia cada parte.
	motor.duelos_activos = OS.get_environment("SIN_DUELOS") == ""
	motor.cuerpos_activos = OS.get_environment("SIN_CUERPOS") == ""
	motor.remate.connect(func(_l: bool, _a: String, tipo: String) -> void: remates[tipo] = int(remates.get(tipo, 0)) + 1)
	motor.gol.connect(func(_l: bool, _a: String, _s: String) -> void:
		remates["gol"] = int(remates.get("gol", 0)) + 1
		## El VAR (17-10-2026): cuántos goles llegan tras un pase medible y
		## cuántos con fuera de juego ajustado (revisión) o real (anulación).
		var mg := motor.margen_gol
		var k := "var_sin_pase" if mg == INF else ("var_anula" if mg > 0.0 and mg <= 0.3 else ("var_revisa" if mg > -1.0 and mg <= 0.0 else "var_claro"))
		remates[k] = int(remates.get(k, 0)) + 1
		if mg != INF and OS.get_environment("DEPURAR_VAR") != "":
			print("MARGEN_GOL %.2f" % mg))
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
	for k in 2:
		extra["pases"][k] += int(motor.pases[k])
		extra["pases_ok"][k] += int(motor.pases_ok[k])
		extra["posesion"][k] += float(motor.posesion[k])
		extra["faltas"][k] += int(motor.faltas[k])
		extra["corners"][k] += int(motor.corners[k])
		extra["fueras"][k] += int(motor.fueras_de_juego[k])
		extra["amarillas"][k] += int(motor.tarjetas_motor[k][0])
		extra["rojas"][k] += int(motor.tarjetas_motor[k][1])
		extra["despejes"][k] += int(motor.despejes[k])
		extra["goles"][k] += int(motor.goles[k])
		extra["tiros"][k] += int(motor.tiros[k])
	## Los duelos cuerpo a cuerpo (16-10-2026).
	var du: Variant = motor.get("duelos")
	if du is Dictionary:
		for k: String in du:
			duelos_tot[k] = int(duelos_tot.get(k, 0)) + int(du[k])
	extra["fintas"] += int(motor.regates_ia)
	var ok_f: Variant = motor.get("regates_ia_ok")
	extra["fintas_ok"] += int(ok_f) if ok_f != null else 0
	extra["partidos"] += 1
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
	var saques_n := {}
	var saques_t := {}
	var sueltos := {}
	var largo_b := [0.0, 0.0]
	var ancho_b := [0.0, 0.0]
	var presion_t := 0.0
	var t_pos := 0.0
	var cerca_suelto := 0.0
	var t_suelto := 0.0
	var dt := 1.0 / 30.0
	while motor.estado != "fin":
		motor.paso(dt)
		estados[motor.estado] = float(estados.get(motor.estado, 0.0)) + dt
		## Saques por tipo: cuántos y cuánto tiempo muerto cada uno (20-10-2026).
		if motor.estado == "saque":
			var tipo_s := String(motor.saque.get("tipo", "?"))
			if motor._t_estado <= dt * 1.01:
				saques_n[tipo_s] = int(saques_n.get(tipo_s, 0)) + 1
			saques_t[tipo_s] = float(saques_t.get(tipo_s, 0.0)) + dt
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
		## Compacidad: largo y ancho de cada bloque (sin porteros) y lo cerca
		## que está el defensor más próximo del que lleva el balón.
		for eqc in 2:
			var zs: Array = []
			var xs: Array = []
			for q: Dictionary in motor.jugadores:
				if (0 if bool(q["es_local"]) else 1) == eqc and not bool(q["por"]):
					zs.append(motor.pos(q).z)
					xs.append(motor.pos(q).x)
			if zs.size() > 2:
				zs.sort()
				xs.sort()
				largo_b[eqc] += float(zs[-1] - zs[0]) * dt
				ancho_b[eqc] += float(xs[-1] - xs[0]) * dt
		if not motor.poseedor.is_empty():
			var mdp := 99.0
			for q: Dictionary in motor.jugadores:
				if bool(q["es_local"]) != bool(motor.poseedor["es_local"]):
					mdp = minf(mdp, motor.pos(q).distance_to(motor.pos(motor.poseedor)))
			presion_t += mdp * dt
			t_pos += dt
		if ball.position.z > 17.5:
			tercio[0] += dt
		elif ball.position.z < -17.5:
			tercio[1] += dt
	print("DIAG goles %s tiros %s faltas %s córners %s" % [str(motor.goles), str(motor.tiros), str(motor.faltas), str(motor.corners)])
	print("DIAG por el aire: %s" % str(motor.cuenta_aire))
	print("DIAG pases %s llegaron %s despejes %s" % [str(motor.pases), str(motor.pases_ok), str(motor.despejes)])
	print("DIAG tiempo por estado %s" % str(estados))
	var txt := ""
	for k: String in saques_n:
		txt += "%s %d (%.1f s c/u)  " % [k, saques_n[k], float(saques_t.get(k, 0.0)) / maxf(1.0, float(saques_n[k]))]
	print("DIAG saques: " + txt)
	print("DIAG en juego %.0f s, con dueño %.0f %%, cambios de posesión %d (%.1f por minuto de juego)" % [total, 100.0 * con_dueno / total, cambios_pos, cambios_pos / (total / 60.0)])
	print("DIAG balón suelto por tipo (s): %s ; distancia media del más cercano al balón quieto/lento: %.1f m" % [str(sueltos), cerca_suelto / maxf(t_suelto, 0.01)])
	print("DIAG bloque largo %.0f/%.0f m, ancho %.0f/%.0f m; rival más cercano al poseedor %.1f m" % [largo_b[0] / total, largo_b[1] / total, ancho_b[0] / total, ancho_b[1] / total, presion_t / maxf(t_pos, 0.01)])
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
		r1.append(_jugar(mejor, peor, _s0(100) + i))
		r2.append(_jugar(peor, mejor, _s0(100) + i))
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
		r0.append(_jugar(a, b, _s0(200) + i))
		r1.append(_jugar(a, b, _s0(200) + i, [ofe, {}]))
		r2.append(_jugar(a, b, _s0(200) + i, [defe, {}]))
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
