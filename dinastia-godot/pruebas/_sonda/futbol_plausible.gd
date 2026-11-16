extends Node
## SONDA «FÚTBOL PLAUSIBLE» DEL MOTOR C4 (16-11, informe AAA, hito H1, criterios A1.3-A1.6). Partidos COMPLETOS de CPU contra
## CPU con el motor de por defecto (C4), 10 clubes de 5 países (dos de cada; nunca un solo club), cada cruce entre países
## distintos, a pasos de 1/60 s (como el estadio) y con la duración del ritmo «normal» (45 × 5,5 s por parte).
## Cifras por partido y del total: goles (banda de ALARMA 2,5-3,3), remates (22-28) y % dentro del área (≥ 60 %), conversión real
## frente al xG propio (`EstadisticasVivo.xg_de`; diferencia ≤ 25 %), y PPDA (pases que el rival da en su 60 % del campo por cada
## acción defensiva allí: robo, corte o falta) del equipo con presión ALTA frente al de BLOQUE BAJO (el mismo cruce dos veces,
## cambiando solo la táctica del local; debe salir menor con presión alta).
##   N=50 DESDE=0 MITAD=247.5 PPDA=0 godot --headless --path . res://pruebas/_sonda/futbol_plausible.tscn
## Con `PPDA=1` juega los N cruces dos veces (local con presión alta y con bloque bajo). Para partir en tandas: `DESDE` y `N`.
## Una línea «PLAUSIBLE_JSON {…}» por partido (para sumar tandas) y el resumen al final.

const DT := 1.0 / 60.0
const PAISES: Array[String] = ["ESP", "ARG", "ITA", "BRA", "GER"]
const ALTA := {"presion": 2, "linea": 2, "tras_perdida": 2, "mentalidad": 2}
const BAJO := {"presion": 0, "linea": 0, "tras_perdida": 0, "mentalidad": 1}

var _clubes: Array = []

func _ready() -> void:
	await get_tree().process_frame
	var n := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 50
	var desde := int(OS.get_environment("DESDE")) if OS.get_environment("DESDE") != "" else 0
	var mitad := float(OS.get_environment("MITAD")) if OS.get_environment("MITAD") != "" else 247.5
	var ppda := OS.get_environment("PPDA") == "1"
	var m := Mundo.new()
	m.generar(PAISES, 4711)
	for liga: Liga in m.ligas:
		if int(liga.div) == 1 and liga.clubes.size() >= 4:
			_clubes.append(liga.clubes[1])
			_clubes.append(liga.clubes[liga.clubes.size() - 3])
	var filas: Array = []
	for k in range(desde, desde + n):
		var a: Club = _clubes[k % _clubes.size()]
		var b: Club = _clubes[(k * 3 + 3) % _clubes.size()]
		if a.pais == b.pais:
			b = _clubes[(k * 3 + 5) % _clubes.size()]
		if ppda:
			for modo in ["alta", "bajo"]:
				var r := _jugar(a, b, 300 + k, mitad, modo)
				print("PLAUSIBLE_JSON ", JSON.stringify(r))
				filas.append(r)
		else:
			var r := _jugar(a, b, 300 + k, mitad, "")
			print("PLAUSIBLE_JSON ", JSON.stringify(r))
			filas.append(r)
	print(resumen(filas))
	print("FIN sonda plausible")
	get_tree().quit()

func _jugar(a: Club, b: Club, semilla: int, mitad: float, modo: String) -> Dictionary:
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(a.once())
	var v := Puente3D.once(b.once())
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var bola := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var mo := MotorFabrica.crear(OS.get_environment("MOTOR") if OS.get_environment("MOTOR") != "" else "")
	raiz.add_child(mo)
	mo.set_physics_process(false)
	mo.autopiloto = true
	mo.duracion_mitad = mitad
	mo.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	if modo != "":
		(mo.tacticas[0] as Dictionary).merge(ALTA if modo == "alta" else BAJO, true)
	mo.preparar(lista, bola, "", semilla)
	var st := EstadisticasVivo.new()
	var pp := [[0, 0], [0, 0]]   ## [pases del rival en su 60 %, acciones defensivas en esa zona] del equipo 0 y del 1
	var eq_prev := -1
	var pases_prev := [0, 0]
	var faltas_prev := [0, 0]
	var pasos := 0
	## Cada remate por zona (dentro < 16,5 m, frontal < 25, lejos) y si ACABA en gol él mismo (gol en ≤ 4 s sin otro remate
	## en medio, separando los que entran tras un rechace del portero): «z_<zona>» remates, «zg_<zona>» goles directos, «zr_<zona>» tras rechace.
	var zonas := {}
	var ult := {"zona": "", "t": -99.0, "rech": 0}
	var tiros_prev := 0
	var goles_prev := 0
	var tope := int((mitad * 2.0 * 1.6 + 300.0) / DT)
	while mo.estado != "fin" and pasos < tope:
		var bpos := mo.balon.position
		mo.paso(DT)
		st.muestrear(mo, DT)
		pasos += 1
		var nt := int(mo.tiros[0]) + int(mo.tiros[1])
		if nt > tiros_prev:
			tiros_prev = nt
			var tv: Dictionary = mo.get("_tiro_vivo") if mo.get("_tiro_vivo") is Dictionary else {}
			var zona := "?"
			if not tv.is_empty():
				var tp: Dictionary = tv["p"]
				var ar: Vector3 = mo._arco_rival(tp)
				var lj := Vector2(mo.pos(tp).x - ar.x, mo.pos(tp).z - ar.z).length()
				zona = ("penal" if String(tv.get("clase", "")) == "penal" else ("dentro" if lj < 16.5 else ("frontal" if lj < 25.0 else "lejos")))
			zonas["z_" + zona] = int(zonas.get("z_" + zona, 0)) + 1
			ult = {"zona": zona, "t": mo.t, "rech": int((mo.diag as Dictionary).get("c4_rechace", 0))}
		var ng := int(mo.goles[0]) + int(mo.goles[1])
		if ng > goles_prev:
			goles_prev = ng
			if String(ult["zona"]) != "" and mo.t - float(ult["t"]) <= 4.0:
				var clave := ("zr_" if int((mo.diag as Dictionary).get("c4_rechace", 0)) > int(ult["rech"]) else "zg_") + String(ult["zona"])
				zonas[clave] = int(zonas.get(clave, 0)) + 1
			else:
				zonas["zg_sin_remate"] = int(zonas.get("zg_sin_remate", 0)) + 1
			ult = {"zona": "", "t": -99.0, "rech": 0}
		## Pases: cada pase del equipo e cuenta para el PPDA del rival si salió en el 60 % del campo propio de e.
		for e in 2:
			if int(mo.pases[e]) > int(pases_prev[e]):
				if _en_su_60(bpos, e == 0):
					pp[1 - e][0] += int(mo.pases[e]) - int(pases_prev[e])
				pases_prev[e] = int(mo.pases[e])
			if int(mo.faltas[e]) > int(faltas_prev[e]):
				## Falta del equipo e: acción defensiva si fue en el 60 % propio del rival.
				if _en_su_60(mo.balon.position, e != 0):
					pp[e][1] += int(mo.faltas[e]) - int(faltas_prev[e])
				faltas_prev[e] = int(mo.faltas[e])
		## Robos y cortes: el balón pasa a un jugador del otro equipo (en juego) dentro del 60 % del que lo perdió.
		if not mo.poseedor.is_empty():
			var eq := 0 if bool(mo.poseedor["es_local"]) else 1
			if eq_prev >= 0 and eq != eq_prev and mo.estado == "juego" and _en_su_60(mo.pos(mo.poseedor), eq_prev == 0):
				pp[eq][1] += 1
			eq_prev = eq
		elif mo.estado != "juego":
			eq_prev = -1
	var r := {"partido": "%s (%s, %s) - %s (%s, %s)" % [a.nombre, a.pais, EstiloClub.estilo_de(a), b.nombre, b.pais, EstiloClub.estilo_de(b)],
		"modo": modo, "goles": [int(mo.goles[0]), int(mo.goles[1])], "tiros": [int(mo.tiros[0]), int(mo.tiros[1])], "pasos": pasos,
		"terminado": mo.estado == "fin"}
	var dentro := 0
	var xg := [0.0, 0.0]
	var penales := 0
	for t: Dictionary in st.tiros:
		var p: Vector2 = t["pos"]
		var loc := bool(t["local"])
		var arco := MotorJugable.LARGO if loc else -MotorJugable.LARGO
		if absf(p.x) <= 20.16 and absf(arco - p.y) <= 16.5:
			dentro += 1
		xg[0 if loc else 1] += float(t["xg"])
		if is_equal_approx(float(t["xg"]), 0.76):
			penales += 1
	r["tiros_vistos"] = st.tiros.size()
	r["dentro"] = dentro
	r["xg"] = [snappedf(xg[0], 0.01), snappedf(xg[1], 0.01)]
	r["penales"] = penales
	r["ppda"] = pp
	## De dónde salen los remates y los goles (contadores del motor: zona del tiro, clase, origen del gol, rechaces de C4).
	var dg := {}
	for k: String in (mo.diag as Dictionary).keys():
		if k.begins_with("tiro_") or k.begins_with("a_puerta") or k.begins_with("gol_") or k.begins_with("traza_gol") or k.begins_with("c4_gol") or k == "c4_rechace" or k == "c4_alcance_area":
			dg[k] = mo.diag[k]
	dg.merge(zonas)
	r["diag"] = dg
	raiz.queue_free()
	return r

## ¿Está `p` en el 60 % del campo más cercano al arco propio del equipo (local = defiende −Z)?
func _en_su_60(p: Vector3, local: bool) -> bool:
	var d := MotorJugable.dir_ataque(local)
	return p.z * d <= -MotorJugable.LARGO + 1.2 * MotorJugable.LARGO

## El resumen de una lista de filas (también suma tandas: `herramientas` no hace falta, se reimprimen las JSON).
static func resumen(filas: Array) -> String:
	var n := 0
	var goles := 0
	var tiros := 0
	var vistos := 0
	var dentro := 0
	var xg := 0.0
	var ppda := {"alta": [0, 0], "bajo": [0, 0], "": [0, 0]}
	var por_partido: Array = []
	var dg := {}
	for r: Dictionary in filas:
		n += 1
		for k: String in (r.get("diag", {}) as Dictionary).keys():
			dg[k] = int(dg.get(k, 0)) + int(r["diag"][k])
		var g: int = int(r["goles"][0]) + int(r["goles"][1])
		goles += g
		tiros += int(r["tiros"][0]) + int(r["tiros"][1])
		vistos += int(r["tiros_vistos"])
		dentro += int(r["dentro"])
		xg += float(r["xg"][0]) + float(r["xg"][1])
		por_partido.append(g)
		var md := String(r.get("modo", ""))
		(ppda[md] as Array)[0] += int(r["ppda"][0][0])
		(ppda[md] as Array)[1] += int(r["ppda"][0][1])
	var nf := maxf(1.0, float(n))
	var s := "RESUMEN %d partidos de C4 (CPU contra CPU):\n" % n
	s += "  goles/partido %.2f (alarma fuera de 2,5-3,3) · reparto %s\n" % [goles / nf, str(por_partido)]
	s += "  remates/partido %.1f (22-28) · vistos en el mapa %.1f · dentro del área %.0f %% (≥ 60 %%)\n" % [tiros / nf, vistos / nf, 100.0 * dentro / maxf(1.0, float(vistos))]
	s += "  xG/partido %.2f · goles/xG %.2f (diferencia %.0f %%; ≤ 25 %%) · conversión %.1f %%\n" % [xg / nf, goles / maxf(xg, 0.01), 100.0 * absf(goles - xg) / maxf(xg, 0.01), 100.0 * goles / maxf(1.0, float(tiros))]
	var claves := dg.keys()
	claves.sort()
	var partes: Array = []
	for k: String in claves:
		partes.append("%s %.2f" % [k, float(dg[k]) / nf])
	s += "  por partido: %s\n" % " · ".join(partes)
	for md: String in ["alta", "bajo", ""]:
		var a: Array = ppda[md]
		if int(a[1]) > 0:
			s += "  PPDA del local%s: %.2f (%d pases / %d acciones)\n" % [" con presión ALTA" if md == "alta" else (" con BLOQUE BAJO" if md == "bajo" else ""), float(a[0]) / float(a[1]), int(a[0]), int(a[1])]
	return s
