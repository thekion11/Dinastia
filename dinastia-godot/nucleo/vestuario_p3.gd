extends "res://nucleo/vestuario_p2.gd"
## (Parte 3 de 4 de `vestuario.gd`.)

## Sí o no a la solicitud activa. Devuelve el titular y el cuerpo para la
## noticia, o vacío si no había ninguna pendiente.
func resolver_solicitud(si: bool) -> Dictionary:
	var j := jugador_de_solicitud()
	if j == null:
		return {}
	var k := String(solicitud.get("k", ""))
	var d := def_solicitud(k)
	solicitud = {}
	if d.is_empty():
		return {}
	if si:
		match k:
			"minutos":
				var t := tabla_roles()
				var idx := maxi(0, indice_rol(rol_plantel(j)) - 1)
				if idx < t.size():
					fijar_rol(j, String((t[idx] as Array)[0]))
				_mover_moral(j, 9)
			"sueldo":
				j.sueldo = int(round(float(j.sueldo) * 1.12))
				_mover_moral(j, 8)
			"salida":
				j.transferible = true
				_mover_moral(j, 4)
			"compa":
				## `Cantera.prometer_compatriota()` -motor listo, sin nadie que lo
				## llamara- vive en otra clase: `Vestuario` no conoce `Cantera`,
				## así que solo se mueve la moral aquí y el llamado cruzado lo
				## hace quien orquesta la semana (`Mundo.avanzar_semana()`).
				_mover_moral(j, 7)
			"descanso":
				j.fisico = clampi(j.fisico + 16, 10, 100)
				_mover_moral(j, 6)
			"instal":
				_mover_moral(j, 4)
			"capitan":
				var c := _club()
				if c != null:
					for x in c.plantilla:
						x.capitan = false
				j.capitan = true
				_mover_moral(j, 12)
		return {"jugador": j, "clave": k, "titulo": "Acuerdo con %s" % j.nombre, "cuerpo": String(d[2])}
	## El rechazo golpea distinto según lo que le negaste. "salida" en el HTML
	## suma DOS golpes seguidos -4 y luego otros 6-, que en la práctica son 10:
	## se deja aquí como un solo número correcto en vez de portar el doble golpe
	## letra por letra, porque el aviso original decía "perdiste 4" cuando en
	## los hechos perdía 10 -un desfase entre el texto y el efecto real, no una
	## regla a propósito-.
	var golpe := 10 if k == "salida" else (6 if k == "capitan" else (9 if k == "sueldo" else 7))
	_mover_moral(j, -golpe)
	return {"jugador": j, "clave": k, "titulo": "Le dijiste que no a %s" % j.nombre,
		"cuerpo": "%s Perdió %d de moral." % [String(d[3]), golpe]}

## Cuánto rinde en la demarcación donde lo pones, de 0 a 1. En su puesto vale 1;
## un portero de campo (o al revés) se queda en 0,60, y el resto sale de comparar
## su media ponderada en ese puesto con su media real.
func _aptitud(j: Jugador, demarcacion: String) -> float:
	if demarcacion == "" or demarcacion == j.pos_e:
		return 1.0
	if (Datos.grupo(demarcacion) == "POR") != j.es_portero():
		return 0.60
	return clampf(float(j.media_en(demarcacion)) / float(maxi(1, j.ovr)), 0.70, 1.0)

## Igual, pero con las ranuras ya calculadas. Armar el once cuesta un sorteo por
## ranura sobre la plantilla entera, y la deriva semanal pregunta por los
## veinticuatro jugadores: sin esto se rearmaba el equipo veinticuatro veces
## para pintar el mismo dibujo.
func _satisfaccion(j: Jugador, slots: Dictionary) -> Dictionary:
	var r := def_rol(rol_plantel(j))
	var exig := float(r[3]) if not r.is_empty() else 0.38

	## 1 · minutos frente a lo prometido
	var cta: Dictionary = _rol_cuenta.get(j.id, {"pj": 0, "min": 0})
	var cumple := 0.5
	if int(cta["pj"]) > 0:
		cumple = clampf(float(cta["min"]) / float(cta["pj"]), 0.0, 1.0)
	elif j.partidos > 0:
		cumple = 0.6
	var v_min := clampf(50.0 + (cumple - exig) * 140.0, 0.0, 100.0)

	## 2 · su propio rendimiento, con las cinco últimas notas
	var nn := j.notas.slice(maxi(0, j.notas.size() - 5))
	var nota := 6.2
	if not nn.is_empty():
		var s := 0.0
		for x in nn:
			s += float(x)
		nota = s / float(nn.size())
	var v_rend := clampf((nota - 4.5) * 100.0 / 4.0, 0.0, 100.0)

	## 3 · comodidad táctica: si juega fuera de puesto, sufre
	var apt := _aptitud(j, String(slots.get(j.id, j.pos_e)))
	var v_tact := clampf(40.0 + (apt - 0.8) * 260.0, 0.0, 100.0)

	## 4 · instalaciones del club
	var inst := 0
	var m := _mundo()
	if m != null and m.obras != null:
		inst = m.obras.nivel("ct") + m.obras.nivel("med") + m.obras.nivel("gim") + m.obras.nivel("cocina")
	var v_inst := clampf(float(inst) * 100.0 / 14.0 + 22.0, 0.0, 100.0)

	var total := int(round(v_min * 0.34 + v_rend * 0.28 + v_tact * 0.20 + v_inst * 0.18))
	return {
		"min": int(round(v_min)),
		"rend": int(round(v_rend)),
		"tact": int(round(v_tact)),
		"inst": int(round(v_inst)),
		"total": total,
	}

## Qué ranura de la formación ocupa cada uno de los once de hoy.
##
## `Club.once()` devuelve a los jugadores EN EL ORDEN de las ranuras de FORMS,
## así que la posición en el array es la posición en la pizarra. Es la única
## forma de saber quién está jugando fuera de puesto sin tocar `Jugador`.
func _slots_del_once() -> Dictionary:
	var c := _club()
	if c == null:
		return {}
	var forms: Dictionary = Datos.tabla("FORMS")
	if forms == null:
		return {}
	var d: Dictionary = forms.get(c.tactica.formacion, forms.get("4-3-3", {}))
	var ranuras: Array = d.get("s", [])
	var once: Array = c.once()
	var salida := {}
	for i in mini(once.size(), ranuras.size()):
		salida[(once[i] as Jugador).id] = String((ranuras[i] as Array)[0])
	return salida

## Los cuatro frentes por los que un jugador está o no a gusto: los minutos que
## le prometiste, cómo se ve él en sus últimos partidos, si lo pones en su
## puesto y en qué instalaciones entrena.
##
## De aquí sale la deriva semanal de la moral, que es la vía por la que todo
## este fichero llega al marcador.
func satisfaccion(j: Jugador) -> Dictionary:
	return _satisfaccion(j, _slots_del_once())

## Qué parte de la satisfacción explica el cambio, en palabras del vestuario.
static func motivo_satisfaccion(sat: Dictionary, baja: bool) -> String:
	var claves := ["min", "rend", "tact", "inst"]
	var elegida: String = claves[0]
	for k: String in claves:
		if (baja and int(sat[k]) < int(sat[elegida])) or (not baja and int(sat[k]) > int(sat[elegida])):
			elegida = k
	if baja:
		return {"min": "Pocos minutos de juego", "rend": "Su mal rendimiento", "tact": "Juega fuera de su puesto", "inst": "Instalaciones pobres"}[elegida]
	return {"min": "Minutos de juego", "rend": "Su buen rendimiento", "tact": "Cómodo en su puesto", "inst": "Buenas instalaciones"}[elegida]

## Lo que pesa en la satisfacción de un jugador (para el Camarín).
func satisfaccion_de(j: Jugador) -> Dictionary:
	return _satisfaccion(j, _slots_del_once())

## La moral deriva hacia el nivel de satisfacción, un 6% por semana. Es lenta a
## propósito: un plantel descontento se desinfla en un mes, no en un domingo.
func _proceso_satisfaccion() -> void:
	var c := _club()
	if c == null:
		return
	var slots := _slots_del_once()
	for j in c.plantilla:
		var sat := _satisfaccion(j, slots)
		var s: int = sat["total"]
		var antes := j.moral
		j.moral = clampi(int(round(float(j.moral) + (float(s) - float(j.moral)) * 0.06)), 10, 99)
		## El motivo: lo que más le tira para abajo si baja, o lo que más le
		## anima si sube (17-10-2026, el Camarín lo explica).
		if j.moral != antes:
			j.anotar_moral(j.moral - antes, motivo_satisfaccion(sat, j.moral < antes))

# ---------------------------------------------------------------------------
#  4 · LO QUE LLEGA AL MARCADOR
# ---------------------------------------------------------------------------

## Los roles tácticos del HTML: [nombre, grupo, Δataque, Δdefensa, atributos que
## lo hacen bueno].
func tabla_roles_tacticos() -> Dictionary:
	var t: Variant = Datos.tabla("ROLES")
	return t if t is Dictionary else {}

## Los roles que puede desempeñar una línea concreta (POR/DEF/MED/DEL).
func roles_de_grupo(grupo: String) -> Array:
	var salida: Array = []
	var t := tabla_roles_tacticos()
	for k: String in t:
		if String((t[k] as Array)[1]) == grupo:
			salida.append(k)
	return salida

## El rol que se le supone a una demarcación si nadie le ha dicho otra cosa.
func rol_tactico_por_defecto(demarcacion: String) -> String:
	match Datos.grupo(demarcacion):
		"POR": return "porArea"
		"DEF": return "centralMar" if demarcacion == "DFC" else "latDef"
		"MED":
			if demarcacion == "MCD":
				return "pivote"
			return "organizad" if demarcacion == "MCO" else "boxToBox"
		_: return "nueveFijo" if demarcacion == "DC" else "extAbierto"

func rol_tactico(j: Jugador) -> String:
	return String(_rol_tactico.get(j.id, rol_tactico_por_defecto(j.pos_e)))

func fijar_rol_tactico(j: Jugador, rol_id: String) -> void:
	if tabla_roles_tacticos().has(rol_id):
		_rol_tactico[j.id] = rol_id

## Cuánto encaja el jugador en el rol que le pediste. Se mira SOLO los atributos
## que ese rol usa contra su propia media: un central de 80 con 90 de marca es
## un gran central marcador, y el mismo central es un mal central de salida.
func aptitud_rol(j: Jugador, rol_id: String) -> float:
	var t := tabla_roles_tacticos()
	if not t.has(rol_id) or j.atributos.is_empty():
		return 1.0
	var claves: Array = (t[rol_id] as Array)[4]
	var s := 0.0
	var n := 0
	for k: String in claves:
		if j.atributos.has(k):
			s += float(j.atributos[k])
			n += 1
	if n == 0:
		return 1.0
	return clampf(0.88 + (s / float(n) - float(j.ovr)) * 0.012, 0.82, 1.14)

## Efecto agregado de los roles individuales sobre el equipo. Se divide entre
## once porque el reparto es por jugador: un once entero de llegadores suma
## mucho ataque y regala la espalda.
func bonus_roles(once: Array) -> Dictionary:
	var t := tabla_roles_tacticos()
	var a := 0.0
	var d := 0.0
	for j: Jugador in once:
		var r := rol_tactico(j)
		if not t.has(r):
			continue
		var fila: Array = t[r]
		var apt := aptitud_rol(j, r)
		a += float(fila[2]) * apt
		d += float(fila[3]) * apt
	return {"att": 1.0 + a / 11.0, "def": 1.0 + d / 11.0}

## Química de hermanos: solo cuenta si comparten el once. Un 1,8% por pareja,
## que es poco y es de los dos lados —ataque y defensa—, exactamente como en el
## HTML: es un guiño, no una estrategia.
func bonus_hermanos(once: Array) -> float:
	var ids := {}
	for j: Jugador in once:
		ids[j.id] = true
	var n := 0
	for j: Jugador in once:
		var h := String(_hermano.get(j.id, ""))
		if h != "" and ids.has(h):
			n += 1
	return 1.0 + (float(n) / 2.0) * 0.018

## Lo que el nerviosismo del vestuario le quita al equipo.
##
## En el HTML esto vivía dentro de `fuerzaJug()`, jugador a jugador
## (`1 - ansiedad*0.0018`). Aquí no se puede: `Partido._media_linea()` no es mío
## y `Jugador` no guarda la ansiedad. Se aplica agregado sobre el once, que da
## prácticamente el mismo número porque la fuerza de línea ya es una media.
##
## Y se mide CONTRA `ANSIEDAD_NEUTRA`, no contra cero: los otros 383 clubes no
## simulan su camarín, así que su ansiedad se queda en la de fábrica. Midiendo
## desde cero, tu equipo sería el único penalizado del mundo por existir. Con el
## cero puesto en la media del mundo, un vestuario normal vale 1,0 y solo se
## mueve el que está mejor o peor que el resto.
func factor_animo(once: Array) -> float:
	if once.is_empty():
		return 1.0
	var s := 0.0
	for j: Jugador in once:
		s += 1.0 - (float(ansiedad(j)) - ANSIEDAD_NEUTRA) * PESO_ANSIEDAD
	return clampf(s / float(once.size()), 0.85, 1.05)

## Los dos multiplicadores que aporta el vestuario, calculados de una vez porque
## comparten el mismo once y el mismo recorrido.
##
## Quien los combina con el resto es `Mundo.aplicar_bonificadores()`, que es el
## único sitio del proyecto que escribe en `Club.bonus_ataque` /
## `Club.bonus_defensa`. Aquí no se escribe en el club a propósito: dos sistemas
## escribiendo el mismo campo se pisan, y cargar la partida dejaba el equipo con
## el doble de bonificación.
func factores(c: Club = null) -> Dictionary:
	var club := c if c != null else _club()
	if club == null:
		return {"ata": 1.0, "def": 1.0}
	var once: Array = club.once()
	if once.is_empty():
		return {"ata": 1.0, "def": 1.0}
	var hermanos := bonus_hermanos(once)
	var roles := bonus_roles(once)
	var animo := factor_animo(once)
	return {
		"ata": hermanos * float(roles["att"]) * animo,
		"def": hermanos * float(roles["def"]) * animo,
	}

func factor_ataque(c: Club = null) -> float:
	return float(factores(c)["ata"])

func factor_defensa(c: Club = null) -> float:
	return float(factores(c)["def"])

# ---------------------------------------------------------------------------
#  5 · HERMANOS Y GEMELOS
# ---------------------------------------------------------------------------

func hermano_de(j: Jugador) -> String:
	return String(_hermano.get(j.id, ""))

## Los declara hermanos. Está expuesto para que la cantera o un evento puedan
## emparentar a dos que ya existen sin tener que crear a nadie.
func emparentar(a: Jugador, b: Jugador) -> void:
	_hermano[a.id] = b.id
	_hermano[b.id] = a.id

## Un hermano más en el plantel, al empezar la temporada y solo tres de cada
## diez años. Un 22% de las veces es gemelo: misma edad, media casi idéntica y
## los mismos atributos con tres puntos de margen.
##
## El apellido se copia del hermano, que es lo que hace que la broma se entienda
## sin explicarla en ningún texto.
func generar_hermanos() -> Jugador:
	if not Azar.suerte(0.30):
		return null
	var c := _club()
	var m := _mundo()
	if c == null or m == null:
		return null
	var candidatos: Array[Jugador] = []
	for j in c.plantilla:
		if j.edad <= 23 and not _hermano.has(j.id):
			candidatos.append(j)
	if candidatos.is_empty():
		return null
	var base: Jugador = candidatos[Azar.ent(0, candidatos.size() - 1)]
	var gemelo := Azar.suerte(0.22)
	var edad := base.edad if gemelo else clampi(base.edad + Azar.ent(-3, 3), 16, 24)
	var ovr := base.ovr + Azar.ent(-2, 2) if gemelo else base.ovr + Azar.ent(-8, 6)
	var nuevo := m.crear_jugador(c, base.pos, base.pos_e, edad, ovr)
	nuevo.pais = base.pais
	var apellido := base.nombre.split(" ")[base.nombre.split(" ").size() - 1]
	var pila: Array = Datos.tabla("NOMBRES")
	var nombre_pila := String(Azar.uno(pila)) if pila != null and not pila.is_empty() else "Hermano"
	nuevo.nombre = "%s %s" % [Nombres.limpiar(nombre_pila), apellido]
	if gemelo:
		## El gemelo no es un jugador nuevo: es una copia con ruido. Se le
		## reparten los atributos del hermano con tres puntos de margen y hay
		## que volver a tasarlo, o el valor seguiría siendo el del sorteo.
		for k: String in nuevo.atributos:
			if base.atributos.has(k):
				nuevo.atributos[k] = clampi(int(base.atributos[k]) + Azar.ent(-3, 3), 22, 99)
		nuevo.tasar()
	c.plantilla.append(nuevo)
	emparentar(nuevo, base)
	hermanos_nuevos.emit(nuevo, base, gemelo)
	if gemelo:
		noticia.emit("👯 Llegan los gemelos " + apellido,
			"El club incorpora a %s, hermano gemelo de %s. Se parecen tanto que el utilero ya se equivocó dos veces. Juntos en cancha se entienden sin mirarse." % [nuevo.nombre, base.nombre])
	else:
		noticia.emit("👨‍👦 Un hermano más en el plantel",
			"%s (%d años, %s) sube al primer equipo. Es hermano de %s: jugar juntos les da un plus." % [nuevo.nombre, nuevo.edad, nuevo.pos_e, base.nombre])
	return nuevo

# ---------------------------------------------------------------------------
#  EL PULSO
# ---------------------------------------------------------------------------

## Una semana de vestuario, en el orden del HTML: primero la cabeza, después los
## grupos, después las promesas y al final la deriva de moral, que es la que
## recoge todo lo anterior.
##
## Los grupos se redibujan cada seis semanas y no cada una: un plantel no cambia
## de camarillas todos los lunes, y rehacerlas cada semana borraba la cuenta de
## paciencia antes de que llegara a tres.
## LA CINTA SE VOTA (M-237, 20-10): si el club se queda sin capitán (se vendió,
## se retiró), el vestuario lo elige. Cada jugador vota al compañero que más
## respeta: veteranía y calidad, con un plus si es de su camarilla (los grupos
## votan en bloque) y un castigo si anda con la moral por el suelo.
## Devuelve {ganador: Jugador, votos: {id: n}, total: n}.
func votar_capitan(c: Club) -> Dictionary:
	var votos := {}
	var candidatos: Array[Jugador] = []
	for j: Jugador in c.plantilla:
		if j.edad >= 21:
			candidatos.append(j)
	if candidatos.is_empty():
		candidatos.assign(c.plantilla)
	if candidatos.is_empty():
		return {}
	for votante: Jugador in c.plantilla:
		var mi_clan := String(_clan_de.get(votante.id, ""))
		var mejor: Jugador = null
		var mejor_nota := -INF
		for cand: Jugador in candidatos:
			if cand == votante:
				continue
			var nota := float(cand.edad) * 0.9 + float(cand.ovr) * 0.35 + float(cand.moral) * 0.05
			if mi_clan != "" and String(_clan_de.get(cand.id, "")) == mi_clan:
				nota += 6.0
			if cand.moral < 35:
				nota -= 8.0
			if nota > mejor_nota:
				mejor_nota = nota
				mejor = cand
		if mejor != null:
			votos[mejor.id] = int(votos.get(mejor.id, 0)) + 1
	var ganador: Jugador = null
	for cand: Jugador in candidatos:
		if votos.has(cand.id) and (ganador == null or int(votos[cand.id]) > int(votos[ganador.id])):
			ganador = cand
	return {"ganador": ganador, "votos": votos, "total": c.plantilla.size()}

func _capitan_si_falta(c: Club) -> void:
	for j: Jugador in c.plantilla:
		if j.capitan:
			return
	var v := votar_capitan(c)
	var g: Jugador = v.get("ganador")
	if g == null:
		return
	g.capitan = true
	_mover_moral(g, 8)
	noticia.emit("🗳️ El vestuario elige capitán", "%s lleva la cinta: %d votos de %d." % [g.nombre, int((v["votos"] as Dictionary)[g.id]), int(v["total"])])
