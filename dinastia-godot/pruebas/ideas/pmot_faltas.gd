extends BaseIdea
## FALTAS POR PUNTOS, ENTERAS (25-10-2026, plan del lunes: «comprobar si `_probar_faltas_puntos` lo
## cubre entero»). El banco probaba la roja (por detrás + velocidad + último hombre) y que la carga de
## hombro no es amarilla. Aquí van los nueve pesos del vídeo, los tres umbrales (falta ≥ 1,0, amarilla
## ≥ 4,0, roja ≥ 7,0) y lo que faltaba en el motor: la carga de hombro limpia (0,9) NO se pita.

func _probar() -> void:
	_titulo("FALTAS POR PUNTOS: los nueve factores y los tres umbrales")
	var r := _motor()
	var motor: MotorJugable = r[0]
	var raiz: Node3D = r[1]
	## 1) Los pesos y los umbrales son los del vídeo del 20-10.
	var del_video := {"agarron": 1.4, "por_detras": 3.0, "empujon": 1.7, "gran_velocidad": 2.0, "deslizante": 2.6,
		"profesional": 2.3, "de_pie": 1.2, "hombro": 0.9, "agresiva": 2.4}
	var iguales := del_video.size() == MotorJugable.PESO_FALTA.size()
	for k: String in del_video:
		iguales = iguales and is_equal_approx(float(MotorJugable.PESO_FALTA.get(k, -1.0)), float(del_video[k]))
	_comprobar(iguales, "los nueve pesos son los del vídeo (%s)" % str(MotorJugable.PESO_FALTA))
	_comprobar(is_equal_approx(MotorJugable.UMBRAL_FALTA, 1.0) and is_equal_approx(MotorJugable.UMBRAL_AMARILLA, 4.0)
		and is_equal_approx(MotorJugable.UMBRAL_ROJA, 7.0), "umbrales: falta 1,0 · amarilla 4,0 · roja 7,0")
	var loc: Array = []
	var vis: Array = []
	for p: Dictionary in motor.jugadores:
		if not bool(p["por"]):
			(loc if bool(p["es_local"]) else vis).append(p)
	var atacante: Dictionary = loc[0]
	var defensa: Dictionary = vis[0]
	var d := signf(motor._arco_rival(atacante).z)
	## Todos los demás lejos (y los defensores tapando el arco: no hay ocasión clara).
	for i in range(1, loc.size()):
		(loc[i]["node"] as Node3D).position = Vector3(-30 + i * 3, 0, -d * 45.0)
	for i in range(1, vis.size()):
		(vis[i]["node"] as Node3D).position = Vector3(-12 + i * 3, 0, d * 30.0)
	## 2) Cada factor, aislado: de frente y despacio en el medio campo.
	var de_frente := func(tipo: String, agr: float) -> Dictionary:
		(atacante["node"] as Node3D).position = Vector3(5, 0, 0)
		atacante["vel"] = Vector3(0, 0, d * 2.0)
		(defensa["node"] as Node3D).position = Vector3(5, 0, d * 1.0)
		defensa["vel"] = Vector3(0, 0, -d * 1.0)
		defensa["agresividad"] = agr
		return motor.puntos_falta(defensa, atacante, tipo)
	for tipo: String in ["agarron", "de_pie", "hombro", "empujon", "deslizante"]:
		var pf: Dictionary = de_frente.call(tipo, 0.5)
		_comprobar(pf["factores"] == [tipo] and is_equal_approx(float(pf["puntos"]), float(del_video[tipo])),
			"«%s» solo, de frente: %.1f puntos (%s)" % [tipo, float(pf["puntos"]), str(pf["factores"])])
	var pf_agr: Dictionary = de_frente.call("empujon", 0.9)
	_comprobar((pf_agr["factores"] as Array).has("agresiva") and float(pf_agr["puntos"]) >= MotorJugable.UMBRAL_AMARILLA,
		"empujón de un jugador de mal genio: + agresiva = %.1f (amarilla)" % float(pf_agr["puntos"]))
	var pf_agr2: Dictionary = de_frente.call("agarron", 0.9)
	_comprobar(not (pf_agr2["factores"] as Array).has("agresiva"), "el agarrón no cuenta como entrada agresiva (%s)" % str(pf_agr2["factores"]))
	## Por detrás: la víctima corre alejándose del que entra.
	(atacante["node"] as Node3D).position = Vector3(5, 0, 0)
	atacante["vel"] = Vector3(0, 0, d * 5.0)
	(defensa["node"] as Node3D).position = Vector3(5, 0, -d * 1.0)
	defensa["vel"] = Vector3(0, 0, d * 4.0)
	defensa["agresividad"] = 0.5
	var pf_det := motor.puntos_falta(defensa, atacante, "deslizante")
	_comprobar(pf_det["factores"] == ["deslizante", "por_detras"], "en plancha por detrás: %.1f (%s)" % [float(pf_det["puntos"]), str(pf_det["factores"])])
	defensa["vel"] = Vector3(0, 0, d * 7.0)
	var pf_vel := motor.puntos_falta(defensa, atacante, "de_pie")
	_comprobar((pf_vel["factores"] as Array).has("gran_velocidad"), "lanzado a más de 6 m/s: a gran velocidad (%s)" % str(pf_vel["factores"]))
	## 3) Lo que pita el árbitro (con su margen de ±0,4), 30 veces cada una.
	var pitadas := func(tipo: String, colocar: Callable) -> Dictionary:
		var n := {"falta": 0, "amarilla": 0, "roja": 0, "nada": 0}
		for k in 30:
			motor.estado = "juego"
			motor.poseedor = {}
			motor.ultima_falta = {}
			colocar.call()
			var antes := int(motor.faltas[1])
			var pito: Variant = motor._falta(defensa, atacante, 0.25, "", tipo)
			if int(motor.faltas[1]) == antes:
				n["nada"] += 1
				if k == 0:
					_comprobar(pito == false and motor.estado == "juego", "si no se pita, el juego sigue (%s)" % tipo)
			else:
				n[String(motor.ultima_falta.get("sancion", "falta"))] += 1
		return n
	var frente := func() -> void:
		(atacante["node"] as Node3D).position = Vector3(5, 0, 0)
		atacante["vel"] = Vector3(0, 0, d * 2.0)
		(defensa["node"] as Node3D).position = Vector3(5, 0, d * 1.0)
		defensa["vel"] = Vector3(0, 0, -d * 1.0)
	var detras := func() -> void:
		(atacante["node"] as Node3D).position = Vector3(5, 0, 0)
		atacante["vel"] = Vector3(0, 0, d * 5.0)
		(defensa["node"] as Node3D).position = Vector3(5, 0, -d * 1.0)
		defensa["vel"] = Vector3(0, 0, d * 4.0)
	var h: Dictionary = pitadas.call("hombro", frente)
	_comprobar(int(h["nada"]) == 30, "la carga de hombro limpia (0,9 < 1,0) no se pita: %s" % str(h))
	var p_: Dictionary = pitadas.call("de_pie", frente)
	_comprobar(int(p_["falta"]) == 30, "la entrada de pie (1,2) es falta sin tarjeta: %s" % str(p_))
	var a_: Dictionary = pitadas.call("agarron", frente)
	_comprobar(int(a_["falta"]) == 30, "el agarrón (1,4) es falta sin tarjeta: %s" % str(a_))
	var dt_: Dictionary = pitadas.call("deslizante", detras)
	_comprobar(int(dt_["amarilla"]) == 30, "en plancha por detrás (5,6) es amarilla: %s" % str(dt_))
	defensa["agresividad"] = 0.9
	var ag_: Dictionary = pitadas.call("empujon", frente)
	_comprobar(int(ag_["falta"]) + int(ag_["amarilla"]) == 30 and int(ag_["amarilla"]) > 0,
		"empujón agresivo (4,1 ± 0,4): falta o amarilla según el criterio: %s" % str(ag_))
	defensa["agresividad"] = 0.5
	## 4) La falta táctica del usuario (RB + A): agarrón con amarilla segura.
	motor.estado = "juego"
	frente.call()
	motor._falta_tactica = true
	motor._falta(defensa, atacante, 0.25, "", "agarron")
	motor._falta_tactica = false
	_comprobar(String(motor.ultima_falta.get("sancion", "")) == "amarilla" and (motor.ultima_falta["factores"] as Array).has("profesional"),
		"la falta táctica es amarilla y cuenta como profesional (%s)" % str(motor.ultima_falta))
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
	return [motor, raiz]
