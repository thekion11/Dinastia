extends BaseIdea
## FILA 18, PRIMERA PARTE (26-10-2026, sesión 5): táctica con y sin balón y roles por jugador en el núcleo,
## con su efecto MEDIDO. Cada comparación juega N partidos en dos mundos idénticos (misma semilla del mundo
## y la misma de `Azar` partido a partido) que solo se diferencian en la decisión táctica: lo que cambia el
## resultado es esa decisión. Y en el motor 3D, las dos perillas nuevas cambian lo que hace la IA.

const N := 300

func _probar() -> void:
	_titulo("TÁCTICA: sin tocar nada, todo igual que antes")
	var m := _mundo(8181)
	var yo := m.mi_club()
	var t := Tactica.new()
	_comprobar(is_equal_approx(t.multiplicador_ataque(), 1.0) and is_equal_approx(t.multiplicador_defensa(), 1.0), "las perillas nuevas, en lo normal, no mueven nada")
	var once := yo.once()
	_comprobar(RolTactico.multiplicadores(yo.tactica, once) == [1.0, 1.0] and is_equal_approx(RolTactico.peso(yo.tactica, once[0], "gol"), 1.0), "sin roles, ni la fuerza ni el reparto de goles cambian")
	_comprobar(t.perillas_con_balon().size() == 5 and t.perillas_sin_balon().size() == 5, "la pizarra tendrá sus dos fases: 5 perillas con balón y 5 sin balón")
	var del := _de_linea(once, "DEL")
	var defe := _de_linea(once, "DEF")
	_comprobar(yo.tactica.poner_rol(del, "pivote") != "" and yo.tactica.poner_rol(del, "nueve_area") == "", "un rol solo se puede dar a quien juega en su línea")
	yo.tactica.roles.clear()
	_comprobar(RolTactico.de_grupo("DEF").size() == 4 and RolTactico.de_grupo("POR").size() == 2, "hay roles para cada línea")
	_titulo("ROLES: el nueve de área frente al falso nueve (%d partidos)" % N)
	var a := _medir(func(c: Club) -> void: c.tactica.poner_rol(_de_linea(c.once(), "DEL"), "nueve_area"))
	var b := _medir(func(c: Club) -> void: c.tactica.poner_rol(_de_linea(c.once(), "DEL"), "falso_nueve"))
	_linea("  nueve de área: %s" % _txt(a))
	_linea("  falso nueve:   %s" % _txt(b))
	_comprobar(float(a["goles_del"]) / maxf(a["gf"], 1) > float(b["goles_del"]) / maxf(b["gf"], 1) + 0.05,
		"el nueve de área se lleva más goles del equipo (%.0f %% frente a %.0f %%)" % [100.0 * a["goles_del"] / maxf(a["gf"], 1), 100.0 * b["goles_del"] / maxf(b["gf"], 1)])
	_comprobar(int(b["asist_del"]) > int(a["asist_del"]), "y el falso nueve da más asistencias (%d frente a %d)" % [b["asist_del"], a["asist_del"]])
	_titulo("ROLES: carrileros frente a laterales defensivos (%d partidos)" % N)
	var car := _medir(func(c: Club) -> void: _laterales(c, "carrilero", true))
	var lat := _medir(func(c: Club) -> void: _laterales(c, "lateral_defensivo", true))
	var malos := _medir(func(c: Club) -> void: _laterales(c, "carrilero", false))
	var base := _medir(func(_c: Club) -> void: pass)
	_linea("  sin roles:          %s" % _txt(base))
	_linea("  carrileros:         %s" % _txt(car))
	_linea("  laterales cerrados: %s" % _txt(lat))
	_linea("  carrileros sin piernas: %s" % _txt(malos))
	_comprobar(float(car["esp"]) > float(lat["esp"]) and float(car["esp_c"]) > float(lat["esp_c"]), "con carrileros se llega más y se concede más; con laterales cerrados, menos de todo (esperadas %.0f-%.0f frente a %.0f-%.0f)" % [car["esp"], car["esp_c"], lat["esp"], lat["esp_c"]])
	_comprobar(float(malos["esp"]) < float(base["esp"]) and float(malos["esp_c"]) > float(base["esp_c"]), "carrileros que no encajan (sin velocidad ni físico) restan por los dos lados")
	_titulo("ROLES: el pivote (%d partidos)" % N)
	var piv := _medir(func(c: Club) -> void: c.tactica.poner_rol(_mejor_para(c.once(), "pivote"), "pivote"))
	var piv_mal := _medir(func(c: Club) -> void: c.tactica.poner_rol(_peor_para(c.once(), "pivote"), "pivote"))
	_linea("  pivote que encaja:    %s" % _txt(piv))
	_linea("  pivote que no encaja: %s" % _txt(piv_mal))
	_comprobar(float(piv["esp_c"]) < float(base["esp_c"]) * 0.98 and float(piv["esp"]) < float(base["esp"]), "un pivote que encaja frena las llegadas del rival (esperadas %.0f frente a %.0f) a cambio de algo de las propias" % [piv["esp_c"], base["esp_c"]])
	_comprobar(float(piv_mal["esp_c"]) > float(piv["esp_c"]), "y uno que no encaja, no (%.0f)" % piv_mal["esp_c"])
	_titulo("CON Y SIN BALÓN: verticalidad y contrapresión (%d partidos)" % N)
	var vert := _medir(func(c: Club) -> void: c.tactica.verticalidad = Tactica.Nivel.ALTO)
	var pac := _medir(func(c: Club) -> void: c.tactica.verticalidad = Tactica.Nivel.BAJO)
	var cp := _medir(func(c: Club) -> void: c.tactica.tras_perdida = Tactica.Nivel.ALTO)
	var rep := _medir(func(c: Club) -> void: c.tactica.tras_perdida = Tactica.Nivel.BAJO)
	_linea("  vertical:      %s" % _txt(vert))
	_linea("  paciente:      %s" % _txt(pac))
	_linea("  contrapresión: %s" % _txt(cp))
	_linea("  repliegue:     %s" % _txt(rep))
	_comprobar(float(vert["esp"]) > float(pac["esp"]) and float(vert["esp_c"]) > float(pac["esp_c"]) and int(vert["rem"]) > int(pac["rem"]), "vertical: más llegadas propias y también del rival (%d/%d frente a %d/%d)" % [vert["rem"], vert["rem_c"], pac["rem"], pac["rem_c"]])
	_comprobar(float(cp["esp"]) > float(rep["esp"]) and float(cp["esp_c"]) > float(rep["esp_c"]) and int(cp["rem"]) > int(rep["rem"]), "contrapresión: más llegadas de los dos; replegar cierra el partido")
	_titulo("GUARDADO")
	var c := m.mi_club()
	c.tactica.verticalidad = Tactica.Nivel.ALTO
	c.tactica.tras_perdida = Tactica.Nivel.BAJO
	c.tactica.poner_rol(_de_linea(c.once(), "DEL"), "falso_nueve")
	var d := Partida._club_a_dic(c)
	_comprobar(int(d.get("vert", -1)) == Tactica.Nivel.ALTO and int(d.get("trasp", -1)) == Tactica.Nivel.BAJO and (d.get("roles_t", {}) as Dictionary).size() == 1, "las perillas nuevas y los roles se guardan con el club")
	var cp2 := c.tactica.duplicar()
	_comprobar(cp2.verticalidad == Tactica.Nivel.ALTO and cp2.roles.size() == 1 and cp2.roles != null, "y se copian con la táctica (el plan del 60' la duplica)")
	_titulo("MOTOR 3D: las perillas nuevas cambian lo que hace la IA")
	_motor_3d()

func _de_linea(once: Array, grupo: String) -> Jugador:
	for j: Jugador in once:
		if Datos.grupo(j.pos_e) == grupo:
			return j
	return null

func _mejor_para(once: Array, rol: String) -> Jugador:
	var mejor: Jugador = null
	for j: Jugador in once:
		if Datos.grupo(j.pos_e) == String(RolTactico.CATALOGO[rol]["grupo"]) and (mejor == null or RolTactico.encaje(j, rol) > RolTactico.encaje(mejor, rol)):
			mejor = j
	return mejor

func _peor_para(once: Array, rol: String) -> Jugador:
	var peor: Jugador = null
	for j: Jugador in once:
		if Datos.grupo(j.pos_e) == String(RolTactico.CATALOGO[rol]["grupo"]) and (peor == null or RolTactico.encaje(j, rol) < RolTactico.encaje(peor, rol)):
			peor = j
	return peor

func _laterales(c: Club, rol: String, buenos: bool) -> void:
	for j: Jugador in c.once():
		if Datos.es_lateral(j.pos_e):
			if not buenos:
				j.atributos["rit"] = 35
				j.atributos["fis"] = 35
				j.atributos["pas"] = 35
			c.tactica.poner_rol(j, rol)

## N partidos de tu club contra rivales de su liga en un mundo nuevo (siempre el mismo) al que se le aplica
## `cambio`; la misma semilla de `Azar` en cada partido. Devuelve goles, remates y lo del delantero.
func _medir(cambio: Callable) -> Dictionary:
	var m := _mundo(9393)
	var yo := m.mi_club()
	Partido.limpiar_contexto()
	Partido.ctx_club_id = yo.id
	cambio.call(yo)
	var del := _de_linea(yo.once(), "DEL")
	var r := {"gf": 0, "gc": 0, "rem": 0, "rem_c": 0, "goles_del": 0, "asist_del": 0, "esp": 0.0, "esp_c": 0.0}
	var rivales: Array = m.ligas[0].clubes
	for i in N:
		Azar.sembrar(5000 + i)
		var otro: Club = rivales[1 + i % (rivales.size() - 1)]
		var p := Partido.new(yo, otro) if i % 2 == 0 else Partido.new(otro, yo)
		p.gol.connect(func(cl: Club, autor: Jugador, _mi: int, asis: Jugador) -> void:
			if cl == yo:
				if autor == del:
					r["goles_del"] += 1
				if asis == del:
					r["asist_del"] += 1)
		p.preparar()
		## Las llegadas ESPERADAS por minuto con esta fuerza (la probabilidad exacta del motor, sin el
		## ruido de los dados): el efecto de la decisión, limpio.
		var fm: Dictionary = p._fza_local if p.local == yo else p._fza_visita
		var fs: Dictionary = p._fza_visita if p.local == yo else p._fza_local
		r["esp"] += p._probabilidad(fm["ata"], fs["def"]) * 90.0
		r["esp_c"] += p._probabilidad(fs["ata"], fm["def"]) * 90.0
		while not p.terminado_ya:
			p.simular_minuto()
		var local := p.local == yo
		r["gf"] += p.goles_local if local else p.goles_visita
		r["gc"] += p.goles_visita if local else p.goles_local
		r["rem"] += p.remates_local if local else p.remates_visita
		r["rem_c"] += p.remates_visita if local else p.remates_local
		## Sin cerrar notas ni lesiones de semana: cada partido arranca del mismo plantel.
		for j in p._todos:
			j.lesion = 0
			j.suspension = 0
	return r

func _txt(r: Dictionary) -> String:
	return "llegadas esperadas %.0f-%.0f · goles %d-%d · llegadas %d-%d · del delantero: %d goles, %d asistencias" % [r["esp"], r["esp_c"], r["gf"], r["gc"], r["rem"], r["rem_c"], r["goles_del"], r["asist_del"]]

func _motor_3d() -> void:
	var res := {}
	for clave: String in ["base", "vertical", "contrapresion"]:
		var s := {"tiros": 0, "pases": 0, "ok_rival": 0, "pases_rival": 0}
		for semilla in [3, 5, 7]:
			var r := _motor(semilla, clave)
			var motor: MotorJugable = r[0]
			while motor.estado != "fin":
				motor.paso(1.0 / 20.0)
			s["tiros"] += int(motor.tiros[0])
			s["pases"] += int(motor.pases[0])
			s["ok_rival"] += int(motor.pases_ok[1])
			s["pases_rival"] += int(motor.pases[1])
			(r[1] as Node3D).queue_free()
		res[clave] = s
		_linea("  %-13s tiros %d · pases %d · precisión del rival %.0f %%" % [clave, s["tiros"], s["pases"], 100.0 * s["ok_rival"] / maxf(s["pases_rival"], 1)])
	_comprobar(res["vertical"]["tiros"] != res["base"]["tiros"] or res["vertical"]["pases"] != res["base"]["pases"], "la verticalidad cambia el juego del motor 3D")
	var pr_base := float(res["base"]["ok_rival"]) / maxf(res["base"]["pases_rival"], 1)
	var pr_cp := float(res["contrapresion"]["ok_rival"]) / maxf(res["contrapresion"]["pases_rival"], 1)
	_comprobar(res["contrapresion"]["ok_rival"] != res["base"]["ok_rival"], "la contrapresión cambia cómo juega el rival en el 3D (precisión %.0f %% → %.0f %%)" % [pr_base * 100.0, pr_cp * 100.0])

func _motor(semilla: int, clave: String) -> Array:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	if clave == "vertical":
		a.tactica.verticalidad = Tactica.Nivel.ALTO
	elif clave == "contrapresion":
		a.tactica.tras_perdida = Tactica.Nivel.ALTO
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
	motor.duracion_mitad = 90.0
	motor.preparar(lista, ball, "", semilla)
	motor.tacticas = [MotorJugable.tactica_desde(a.tactica), MotorJugable.tactica_desde(b.tactica)]
	return [motor, raiz]
