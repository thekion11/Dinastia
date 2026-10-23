class_name Vestuario
extends "res://nucleo/vestuario_p3.gd"
## (Parte 4 de 4 de `vestuario.gd`.)

func semana(sem: int) -> void:
	var c := _club()
	if c == null:
		return
	var once_ids: Array = []
	for j: Jugador in c.once():
		once_ids.append(j.id)
	_capitan_si_falta(c)
	_proceso_mental()
	chequeo_clanes(once_ids)
	_chequeo_roles(once_ids)
	_proceso_satisfaccion()
	if sem % CADA_CUANTAS_SEMANAS == 0:
		armar()

## Lo que le toca al vestuario al empezar la temporada.
func nueva_temporada() -> void:
	generar_hermanos()
	armar()

## Lo que la interfaz necesita para el panel de "te falta revisar", sin tener
## que recorrer el plantel por su cuenta.
func resumen() -> Dictionary:
	var c := _club()
	var ansiosos := 0
	var en_baja := 0
	if c != null:
		for j in c.plantilla:
			if ansiedad(j) >= 60:
				ansiosos += 1
			if int(mente(j)["baja"]) > 0:
				en_baja += 1
	var molestos := 0
	for cl in camarillas:
		if int(cl["humor"]) < -25:
			molestos += 1
	return {
		"grupos": camarillas.size(),
		"molestos": molestos,
		"ansiosos": ansiosos,
		"en_baja": en_baja,
		"factor_ataque": factor_ataque(),
		"factor_defensa": factor_defensa(),
	}

## Da la charla al once. Devuelve qué pasó, para que la pantalla lo cuente.
##
## El psicólogo del cuerpo técnico -`Staff.nivel("psi")`- suma a los dos
## extremos del margen: con un buen psicólogo hasta una bronca sale mejor,
## que es exactamente para lo que se le paga.
func charla(once: Array, tono: String) -> Dictionary:
	if not TONOS.has(tono):
		tono = "calma"
	var t: Array = TONOS[tono]
	var psi := 0
	var m := _mundo()
	if m != null and m.staff != null:
		psi = m.staff.nivel("psi")
	var suben := 0
	var bajan := 0
	for j: Jugador in once:
		var prefiere := String(PREFIERE.get(j.rasgo, ""))
		var gusta := String(t[5])
		var d := Azar.ent(int(t[2]) + psi, int(t[3]) + psi)
		if gusta != "" and prefiere != "":
			d += Azar.ent(2, 5) if prefiere == gusta else -Azar.ent(2, 6)
		var extra := 4 if (prefiere != "" and gusta != "" and prefiere != gusta) else 0
		_mover_ansiedad(j, int(t[4]) + extra)
		## Un jugador desbordado no escucha: por encima de 72 de ansiedad, la
		## charla le llega peor haga lo que haga el entrenador.
		if ansiedad(j) > 72:
			d -= Azar.ent(2, 6)
		_mover_moral(j, d)
		if d > 2:
			suben += 1
		elif d < 0:
			bajan += 1
	var reaccion := "el mensaje llega a medias"
	if suben > bajan + 3:
		reaccion = "el camarín reacciona, salen enchufados"
	elif bajan > suben:
		reaccion = "a varios no les cayó bien; hay caras largas"
	return {
		"tono": tono, "nombre": String(t[0]), "icono": String(t[1]),
		"suben": suben, "bajan": bajan, "reaccion": reaccion,
	}

func _tiene(texto: String, claves: Array) -> bool:
	for k: String in claves:
		if texto.contains(k):
			return true
	return false

## `charlaLibre()`: el tono se DEDUCE de lo que escribes. Es de las cosas más
## baratas del HTML y de las que más hacen por meterte en el papel — decir
## "así no, señores" y ver que el equipo lo acusa vale más que elegir "Exigir"
## en una lista. El orden de las comprobaciones importa: un grito con palabrota
## es furia aunque además diga "tranquilos".
func tono_de_texto(texto: String) -> String:
	var t := texto.to_lower()
	if _tiene(t, ["!!", "carajo", "mierda", "puta", "ya basta", "dejen de"]):
		return "furia"
	if _tiene(t, ["vergüenza", "verguenza", "inaceptable", "basta", "despierten",
			"jugando mal", "así no", "así no", "ridícul", "ridicul", "desastre", "regalan"]):
		return "exigir"
	if _tiene(t, ["tranquil", "calma", "confi", "confío", "confio", "bien",
			"sigan", "paciencia", "así se juega", "así se juega", "orgullo"]):
		return "animar"
	if _tiene(t, ["línea", "linea", "presi", "banda", "pelota", "espacio",
			"marca", "orden", "salida", "bloque", "contra"]):
		return "tactico"
	return "calma"

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Solo se guarda lo que dice algo. La ficha mental de un jugador tranquilo, sin
## terapia y sin baja es la que le tocaría igual al recrearla, y escribir miles
## de diccionarios idénticos engorda la partida sin aportar nada: el guardado ya
## costó una depuración entera por tamaño.
##
## La ansiedad SÍ se guarda siempre que exista ficha, porque se sortea al nacer y
## no se puede reconstruir: perderla haría que cargar la partida barajara de
## nuevo la cabeza de todo el plantel.
func a_dic() -> Dictionary:
	return {
		"camarillas": camarillas.duplicate(true),
		"clan_de": _clan_de.duplicate(),
		"mente": _mente.duplicate(true),
		"rol": _rol.duplicate(),
		"rol_cuenta": _rol_cuenta.duplicate(true),
		"rol_tactico": _rol_tactico.duplicate(),
		"hermano": _hermano.duplicate(),
		"solicitud": solicitud.duplicate(),
	}

func desde_dic(d: Dictionary) -> void:
	camarillas.clear()
	for x: Dictionary in d.get("camarillas", []):
		camarillas.append({
			"id": String(x.get("id", "")),
			"tipo": String(x.get("tipo", "")),
			"nombre": String(x.get("nombre", "")),
			"miembros": x.get("miembros", []),
			"lider": String(x.get("lider", "")),
			"humor": int(x.get("humor", 0)),
			"fuera": int(x.get("fuera", 0)),
		})
	_clan_de = (d.get("clan_de", {}) as Dictionary).duplicate()
	_mente.clear()
	var fichas: Dictionary = d.get("mente", {})
	for id: String in fichas:
		var f: Dictionary = fichas[id]
		_mente[id] = {
			"ansiedad": int(f.get("ansiedad", 20)),
			"confianza": int(f.get("confianza", 60)),
			"terapia": int(f.get("terapia", 0)),
			"descanso": int(f.get("descanso", 0)),
			"baja": int(f.get("baja", 0)),
		}
	_rol = (d.get("rol", {}) as Dictionary).duplicate()
	_rol_cuenta.clear()
	var cuentas: Dictionary = d.get("rol_cuenta", {})
	for id: String in cuentas:
		var x: Dictionary = cuentas[id]
		_rol_cuenta[id] = {"pj": int(x.get("pj", 0)), "min": int(x.get("min", 0))}
	_rol_tactico = (d.get("rol_tactico", {}) as Dictionary).duplicate()
	_hermano = (d.get("hermano", {}) as Dictionary).duplicate()
	solicitud = (d.get("solicitud", {}) as Dictionary).duplicate()

func _con_rasgo(c: Club, rasgo: String) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.rasgo == rasgo:
			salida.append(j)
	return salida

func _jovenes(c: Club) -> Array[Jugador]:
	var salida: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.edad <= 20:
			salida.append(j)
	return salida

## EL LÍO NOCTURNO. El único suceso que le cuesta algo al club, y el único donde
## las normas internas hacen algo: con el reglamento encendido entra la multa y
## al multado le baja más la moral. El nodo «Duro» del árbol la dobla.
func _suceso_lio(m: Mundo, mio: Club) -> Dictionary:
	var lista := _con_rasgo(mio, "polemico")
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	for x: Jugador in mio.plantilla:
		x.cambiar_moral(-2, "Vida del vestuario")
	var extra := ""
	var multa := 0
	if bool(m.normas.get("multas", false)):
		multa = maxi(1, j.sueldo * MULTA_SEMANAS)
		if m.entrenamiento != null and m.entrenamiento.multas_dobles():
			multa *= 2
			extra = " Con tu mano dura, la multa fue el doble de lo habitual: %s." % Cesiones.dinero(multa)
		else:
			extra = " El club aplicó la multa del reglamento interno: %s." % Cesiones.dinero(multa)
		mio.mover_saldo(multa)
		j.cambiar_moral(-3, "Vida del vestuario")
	noticia.emit("Lío nocturno: %s" % j.nombre,
		"Fotos del jugador de fiesta a mitad de semana. El camarín queda tocado y la prensa afila el lápiz.%s" % extra)
	if m.prensa != null:
		m.prensa._mover_funa(Azar.ent(3, 8))
	return {"tipo": "lio", "jugador": j, "multa": multa}

func _suceso_arenga(mio: Club) -> Dictionary:
	var lista := _con_rasgo(mio, "lider")
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	for x: Jugador in mio.plantilla:
		x.cambiar_moral(3, "Vida del vestuario")
	noticia.emit("Arenga de %s" % j.nombre,
		"Reunió al plantel a puertas cerradas: «aquí nadie se esconde». El grupo sale enchufado.")
	return {"tipo": "arenga", "jugador": j}

func _suceso_racha(mio: Club) -> Dictionary:
	var lista := _con_rasgo(mio, "killer")
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	j.forma = clampi(j.forma + 8, 20, 99)
	noticia.emit("Racha de %s" % j.nombre,
		"Se queda después de cada práctica definiendo. Huele gol.")
	return {"tipo": "racha", "jugador": j}

func _suceso_joya(mio: Club) -> Dictionary:
	var lista := _jovenes(mio)
	var j: Jugador = lista[Azar.ent(0, lista.size() - 1)]
	j.forma = clampi(j.forma + 6, 20, 99)
	noticia.emit("La joya pide pista",
		"%s la rompió en la práctica y golpea la puerta de la titularidad." % j.nombre)
	return {"tipo": "joya", "jugador": j}

func _suceso_cumple(mio: Club) -> Dictionary:
	var j: Jugador = mio.plantilla[Azar.ent(0, mio.plantilla.size() - 1)]
	for x: Jugador in mio.plantilla:
		x.cambiar_moral(1, "Vida del vestuario")
	j.cambiar_moral(4, "Vida del vestuario")
	noticia.emit("Cumpleaños en el camarín",
		"El plantel sorprendió a %s con torta y bromas. Buen ambiente." % j.nombre)
	return {"tipo": "cumple", "jugador": j}

func suceso_semanal() -> Dictionary:
	var m := _mundo()
	if m == null:
		return {}
	var mio := m.mi_club()
	if mio == null or mio.plantilla.is_empty():
		return {}
	## Se sortea entre los sucesos POSIBLES, no entre todos: si el catálogo fuera
	## fijo, saldría "arenga del líder" en un plantel sin ningún líder.
	var posibles: Array[String] = ["cumple"]
	if not _con_rasgo(mio, "polemico").is_empty():
		posibles.append("lio")
	if not _con_rasgo(mio, "lider").is_empty():
		posibles.append("arenga")
	if not _con_rasgo(mio, "killer").is_empty():
		posibles.append("racha")
	if not _jovenes(mio).is_empty():
		posibles.append("joya")
	var cual := String(Azar.uno(posibles))
	match cual:
		"lio": return _suceso_lio(m, mio)
		"arenga": return _suceso_arenga(mio)
		"racha": return _suceso_racha(mio)
		"joya": return _suceso_joya(mio)
		_: return _suceso_cumple(mio)
