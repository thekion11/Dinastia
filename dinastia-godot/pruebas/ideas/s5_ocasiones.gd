extends BaseIdea
## LAS OCASIONES JUGABLES DEL DT (26-10-2026, sesión 5, fila 14 de la propuesta). En 3-6 llegadas claras de
## tu equipo el motor del césped se para, eliges pase/conducción/tiro y lo ejecuta el MISMO motor (su
## `_tirar`/`_pasar_a`): el resultado es el del césped. Se prueba: el cupo, el criterio de «clara», la lectura
## con `MotorLibre.tomar_control`, cada elección en el motor real, la elección automática al agotarse el
## tiempo, el tope de 15 s, un partido entero en piloto automático con sus 3-6 ocasiones y que el porcentaje
## de cada botón se parece a lo que de verdad pasa en el césped (partidos enteros eligiendo siempre lo mismo).

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("OCASIONES: cupo y criterio")
	var fuera := 0
	var suma := 0
	for s in 200:
		var c := OcasionesDT.cupo(s * 7919, 0)
		suma += c
		if c < 3 or c > 6:
			fuera += 1
	_comprobar(fuera == 0, "el cupo de un partido entero está siempre entre 3 y 6 (media %.2f)" % (float(suma) / 200.0))
	_comprobar(OcasionesDT.cupo(11, 46) <= 3 and OcasionesDT.cupo(11, 46) >= 1, "abierto en el 46', la mitad (%d)" % OcasionesDT.cupo(11, 46))
	_comprobar(OcasionesDT.cupo(11, 88) == 0, "abierto en el 88', ninguna")
	_comprobar(OcasionesDT.es_clara(18.0, 3.0, 3.0) and not OcasionesDT.es_clara(18.0, 3.0, 0.8), "a 18 m con espacio es clara; con el rival encima, no")
	_comprobar(not OcasionesDT.es_clara(30.0, 0.0, 5.0) and OcasionesDT.es_clara(30.0, 0.0, 5.0, 1), "a 30 m solo si el partido va apurado de ocasiones")
	_comprobar(not OcasionesDT.es_clara(15.0, 25.0, 5.0), "pegado a la banda no es clara")
	_comprobar(OcasionesDT.nivel(20, 90, 0, 5) == 0 and OcasionesDT.nivel(70, 90, 3, 5) == 1 and OcasionesDT.nivel(80, 90, 1, 5) == 2,
		"el listón baja solo cuando faltan minutos para las que quedan")
	_comprobar(OcasionesDT.prob_tiro_3d(10, 0, false, 0.9) > OcasionesDT.prob_tiro_3d(25, 0, false, 0.9)
		and OcasionesDT.prob_tiro_3d(18, 0, false, 0.9) > 5.0 * OcasionesDT.prob_tiro_3d(18, 0, true, 0.9)
		and OcasionesDT.prob_tiro_3d(18, 0, false, 0.95) > OcasionesDT.prob_tiro_3d(18, 0, false, 0.55),
		"la curva del tiro baja con la distancia y con la línea tapada y sube con la calidad")
	var sin_tiro := {"pase": {"prob": 0.9}, "conducir": {"prob": 0.8}, "tiro": {"prob": 0.1}}
	_comprobar(OcasionesDT.recomendar(sin_tiro, 0.5, 0.2) == "pase" and OcasionesDT.recomendar({"tiro": {"prob": 0.6}, "pase": {"prob": 0.9}}, 0.3, 0.0) == "tiro",
		"recomienda lo que más acerca al gol (pasar a uno solo, tirar si es claro)")
	_titulo("OCASIONES: la lectura con MotorLibre")
	var r := _motor(4711, 7, 0, 1)
	var motor: MotorJugable = r[0]
	var partido: Partido = r[2]
	var loc: Array = []
	var vis: Array = []
	for p: Dictionary in motor.jugadores:
		(loc if bool(p["es_local"]) else vis).append(p)
	var del := _delantero(loc)
	var comp := _otro(loc, del)
	_escena(motor, loc, vis, del, comp)
	var oc := _ocasion(motor, partido)
	_comprobar(oc.cupo >= 3 and oc.cupo <= 6, "el cupo del partido es %d" % oc.cupo)
	var lect := oc._leer(del)
	_comprobar(lect.has("tiro") and lect.has("pase") and lect.has("conducir"), "a 20 m con espacio hay tiro, pase y conducción")
	if lect.has("tiro") and lect.has("pase"):
		_comprobar(float(lect["tiro"]["prob"]) > 0.03 and float(lect["tiro"]["prob"]) < 0.6, "el tiro, con su probabilidad de gol en el motor 3D (%.0f %%)" % (float(lect["tiro"]["prob"]) * 100.0))
		_comprobar(float(lect["pase"]["prob"]) > 0.3, "el pase, con su probabilidad de llegar (%.0f %%)" % (float(lect["pase"]["prob"]) * 100.0))
		_comprobar(lect.has("recomendada"), "y una recomendada: %s" % String(lect.get("recomendada", "?")))
	_titulo("OCASIONES: el tiro lo resuelve el motor del césped")
	oc._proxima = 0
	_comprobar(oc.tras_paso() and oc.congela(), "la llegada clara para el partido (el motor no avanza)")
	var t0 := motor.t
	for k in 5:
		if oc.congela():
			oc.vigilar(DT)
	_comprobar(motor.t == t0, "mientras eliges, el reloj del motor no corre")
	_comprobar(oc._caja.visible and (oc._botones["tiro"] as Button).visible and (oc._botones["tiro"] as Button).text.contains("%"),
		"aparecen los botones con su porcentaje: «%s»" % (oc._botones["tiro"] as Button).text)
	var tiros := int(motor.tiros[0])
	oc.elegir("tiro")
	var res := _hasta_cerrar(motor, oc)
	_comprobar(int(motor.tiros[0]) == tiros + 1, "el tiro sale del motor real (tiros %d → %d)" % [tiros, int(motor.tiros[0])])
	_comprobar(res in ["gol", "atajada", "poste", "fallo", "parado"], "y su resultado es el del césped: %s" % res)
	_comprobar(oc._t_total <= OcasionesDT.SEGUNDOS_MAX, "la ocasión duró %.1f s (≤ 15)" % oc._t_total)
	_comprobar(Engine.time_scale == 1.0, "al cerrar, el tiempo vuelve a su ritmo")
	_titulo("OCASIONES: conducir y volver a decidir")
	_escena(motor, loc, vis, del, comp)
	oc._proxima = 0
	oc.hechas = 0
	oc.tras_paso()
	oc.elegir("conducir")
	var z0 := motor.pos(del).z
	var otra := false
	for k in 90:
		motor.paso(DT)
		oc.vigilar(DT)
		if oc.tras_paso():
			otra = true
			break
	_comprobar(otra and oc._pasos == 2 and motor.pos(del).z > z0 + 2.0, "tras 1,3 s conduciendo (%.1f m más cerca) toca decidir otra vez" % (motor.pos(del).z - z0))
	_titulo("OCASIONES: sin elegir, decide el cuerpo técnico")
	var antes := oc.historial.size()
	for k in 400:
		oc.vigilar(0.05)
		if not oc.congela():
			break
	var auto: Dictionary = oc.historial[antes] if oc.historial.size() > antes else {}
	_comprobar(bool(auto.get("auto", false)) and String(auto.get("eleccion", "")) == String(auto.get("recomendada", "-")),
		"al agotarse el tiempo se hace lo recomendado (%s)" % String(auto.get("eleccion", "?")))
	_hasta_cerrar(motor, oc)
	_titulo("OCASIONES: el pase")
	_escena(motor, loc, vis, del, comp)
	oc._proxima = 0
	oc.hechas = 0
	oc.tras_paso()
	if oc._lect.has("pase"):
		var pases := int(motor.pases[0])
		oc.elegir("pase")
		_comprobar(int(motor.pases[0]) == pases + 1, "el pase lo da el motor del césped")
		_hasta_cerrar(motor, oc)
	_titulo("OCASIONES: el tiro de la escena, repetido")
	var goles_m := 0
	var tiros_m := 0
	var est_m := 0.0
	for n in 80:
		_escena(motor, loc, vis, del, comp)
		oc._proxima = 0
		oc.hechas = 0
		if not oc.tras_paso() or not oc._lect.has("tiro"):
			continue
		est_m += float(oc._lect["tiro"]["prob"])
		var g0 := int(motor.goles[0])
		oc.elegir("tiro")
		_hasta_cerrar(motor, oc)
		tiros_m += 1
		goles_m += int(motor.goles[0]) - g0
	est_m /= maxf(tiros_m, 1)
	var real_t := float(goles_m) / maxf(tiros_m, 1)
	## Sin defensas que se cierren, el césped convierte algo más que en pleno partido (el botón ya trae el
	## ajuste de partido): se le pide estar cerca, no clavado.
	_comprobar(tiros_m >= 70 and absf(real_t - est_m) <= 0.15, "solo ante el portero: el botón decía %.0f %% y el motor marcó %d de %d (%.0f %%)" % [est_m * 100.0, goles_m, tiros_m, real_t * 100.0])
	oc.queue_free()
	(r[1] as Node3D).queue_free()
	_titulo("OCASIONES: un partido entero en piloto automático")
	_partido_entero()
	_titulo("OCASIONES: lo que dice el botón es lo que pasa (partidos enteros)")
	_coherencia()

func _ocasion(motor: MotorJugable, partido: Partido) -> OcasionJugable:
	var oc := OcasionJugable.new()
	add_child(oc)
	oc.camara_lenta = false
	oc.reloj_real = false
	oc.configurar(motor, partido, 0)
	return oc

## Corre el motor hasta que la ocasión se cierre (eligiendo lo recomendado); devuelve el resultado.
func _hasta_cerrar(motor: MotorJugable, oc: OcasionJugable) -> String:
	for k in 600:
		if not oc.activa():
			break
		if oc.congela():
			oc.elegir(String(oc._lect["recomendada"]))
		motor.paso(DT)
		oc.vigilar(DT)
		oc.tras_paso()
	for i in range(oc.historial.size() - 1, -1, -1):
		if (oc.historial[i] as Dictionary).has("resultado"):
			return String(oc.historial[i]["resultado"])
	return ""

## El delantero local con el balón a 20 m del arco rival (el local ataca hacia +z), un compañero libre al
## lado y los rivales lejos (salvo el portero, en su arco).
func _escena(motor: MotorJugable, loc: Array, vis: Array, del: Dictionary, comp: Dictionary) -> void:
	## El reloj del motor, siempre a mitad de la primera parte (si no, la mitad se acaba entre repeticiones).
	motor.estado = "juego"
	motor.t = 20.0
	motor.mitad = 1
	motor.lento = 0.0
	motor._goleador = {}
	motor.saque = {}
	motor._tiro_vivo = {}
	motor.pase_a = {}
	_limpiar_relojes(motor)
	for i in loc.size():
		var p: Dictionary = loc[i]
		if bool(p["por"]):
			(p["node"] as Node3D).position = Vector3(0, 0, -50)
		elif p != del and p != comp:
			(p["node"] as Node3D).position = Vector3(-30 + i * 4, 0, -10.0)
	for i in vis.size():
		var q: Dictionary = vis[i]
		## Los defensas, hundidos y abiertos: así nadie queda en fuera de juego.
		(q["node"] as Node3D).position = Vector3(0, 0, 51.0) if bool(q["por"]) else Vector3((1.0 if i % 2 == 0 else -1.0) * (22.0 + i), 0, 46.0)
	(del["node"] as Node3D).position = Vector3(2.0, 0, 32.5)
	(comp["node"] as Node3D).position = Vector3(-9.0, 0, 34.0)
	motor.poseedor = del
	motor.ultimo_toque = del
	motor.balon.position = Vector3(2.0, 0.11, 33.0)
	motor.vel_balon = Vector3.ZERO
	motor._decision_en = motor.t + 0.5

## Los temporizadores de cada jugador («…_hasta», el enfriamiento) se miden con el reloj del motor: al
## devolverlo al 20 s, los de la repetición anterior quedarían en el futuro (jugadores celebrando o
## «sentados» para siempre; con ellos la primera medición del tiro salió inflada).
func _limpiar_relojes(motor: MotorJugable) -> void:
	for p: Dictionary in motor.jugadores:
		for k: String in p.keys():
			if k.ends_with("_hasta"):
				p[k] = 0.0
		p["enfriar"] = 0.0
		p["vel"] = Vector3.ZERO

func _delantero(l: Array) -> Dictionary:
	for p: Dictionary in l:
		if String(p.get("slot_code", "")) in ["DC", "ST", "DEL"]:
			return p
	return l[l.size() - 1]

func _otro(l: Array, no: Dictionary) -> Dictionary:
	for p: Dictionary in l:
		if p != no and not bool(p["por"]):
			return p
	return {}

func _partido_entero() -> void:
	var r := _motor(4711, 7, 0, 1)
	var motor: MotorJugable = r[0]
	var oc := _ocasion(motor, r[2])
	var goles_oc := [0]
	oc.termina.connect(func(res: String) -> void:
		if res == "gol":
			goles_oc[0] += 1)
	var max_t := 0.0
	var pasos := 0
	while motor.estado != "fin" and pasos < 30 * 1200:
		pasos += 1
		if oc.congela():
			oc.vigilar(0.5)
			continue
		motor.paso(DT)
		oc.vigilar(DT)
		oc.tras_paso()
		max_t = maxf(max_t, oc._t_total)
	var cerradas := 0
	for h: Dictionary in oc.historial:
		if h.has("resultado"):
			cerradas += 1
	_linea("  (cupo %d, hechas %d, goles en ocasiones %d, marcador %d-%d)" % [oc.cupo, oc.hechas, goles_oc[0], motor.goles[0], motor.goles[1]])
	_comprobar(motor.estado == "fin", "el partido llega al final")
	_comprobar(oc.hechas >= 3 and oc.hechas <= oc.cupo, "salen %d ocasiones de las %d del cupo (al menos 3)" % [oc.hechas, oc.cupo])
	_comprobar(cerradas == oc.hechas, "todas se cierran")
	_comprobar(max_t <= OcasionesDT.SEGUNDOS_MAX + 0.6, "ninguna pasa de 15 s (la más larga, %.1f s)" % max_t)
	_comprobar(goles_oc[0] <= int(motor.goles[0]), "los goles de las ocasiones están en el marcador del motor")
	## Tras el descanso en el camarín el estadio se reabre: el cupo y la cuenta siguen.
	var otra_vez := _ocasion(motor, r[2])
	_comprobar(otra_vez.cupo == oc.cupo and otra_vez.hechas == oc.hechas, "al reabrir el estadio el cupo sigue (%d/%d, no vuelve a cero)" % [otra_vez.hechas, otra_vez.cupo])
	otra_vez.queue_free()
	oc.queue_free()
	(r[1] as Node3D).queue_free()

## Partidos enteros eligiendo SIEMPRE lo mismo (cuando se puede): la media de lo que decía el botón frente
## a lo que pasó. Pocas semillas (la medición grande, 20 semillas, está en el informe de la sesión 5); son
## deterministas, así que la cifra no baila de una ejecución a otra.
func _coherencia() -> void:
	for forzada: String in ["pase", "tiro"]:
		var est := 0.0
		var ok := 0
		var n := 0
		for semilla in [131, 151, 173, 191]:
			var c := _jugar_forzando(semilla, forzada)
			est += float(c[0])
			ok += int(c[1])
			n += int(c[2])
		var e := est / maxf(n, 1)
		var real := float(ok) / maxf(n, 1)
		_comprobar(n >= 8 and absf(real - e) <= (0.2 if forzada == "pase" else 0.12),
			"%s: el botón decía %.0f %% de media y en el césped salió %d de %d (%.0f %%)" % [forzada, e * 100.0, ok, n, real * 100.0])

func _jugar_forzando(semilla: int, forzada: String) -> Array:
	var r := _motor(4000 + semilla, semilla, semilla % 6, (semilla + 3) % 6)
	var motor: MotorJugable = r[0]
	var oc := _ocasion(motor, r[2])
	var est := 0.0
	var ok := 0
	var n := 0
	var pendiente := false
	var g0 := 0
	var pasos := 0
	while motor.estado != "fin" and pasos < 30 * 1200:
		pasos += 1
		if oc.congela():
			## Un pase pendiente y otra decisión: el pase llegó.
			if pendiente and forzada == "pase":
				ok += 1
				pendiente = false
			var clave := forzada if oc._lect.has(forzada) else String(oc._lect["recomendada"])
			if clave == forzada:
				est += float(oc._lect[forzada]["prob"])
				n += 1
				pendiente = true
				g0 = int(motor.goles[0])
			oc.elegir(clave)
			continue
		var activa := oc.activa()
		motor.paso(DT)
		oc.vigilar(DT)
		oc.tras_paso()
		if activa and not oc.activa() and pendiente:
			var res := String(oc.historial[oc.historial.size() - 1].get("resultado", ""))
			if (forzada == "pase" and res == "pase") or (forzada == "tiro" and (res == "gol" or int(motor.goles[0]) > g0)):
				ok += 1
			pendiente = false
	oc.queue_free()
	(r[1] as Node3D).queue_free()
	return [est, ok, n]

func _motor(semilla_mundo: int, semilla_motor: int, i_local: int, i_visita: int) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], semilla_mundo)
	var a: Club = m.ligas[0].clubes[i_local]
	var b: Club = m.ligas[0].clubes[i_visita]
	Partido.ctx_club_id = a.id
	var partido := Partido.new(a, b)
	partido.preparar()
	partido.motor_externo = true
	var raiz := Node3D.new()
	add_child(raiz)
	var sp := PlayerSpawner.new()
	var lista: Array = []
	var l := Puente3D.once(partido.once_local)
	var v := Puente3D.once(partido.once_visita)
	lista.append_array(sp.spawn_team(raiz, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a)))
	lista.append_array(sp.spawn_team(raiz, v["xi"], v["jugadores"], Puente3D.formacion(b.tactica.formacion), false, Puente3D.kit(b), Puente3D.kit_portero(b)))
	var ball := StadiumBuilder.spawn_ball(raiz, Vector3(0, 0.11, 0))
	var motor := MotorJugable.new()
	raiz.add_child(motor)
	motor.set_physics_process(false)
	motor.autopiloto = true
	motor.preparar(lista, ball, "", semilla_motor)
	return [motor, raiz, partido]
