extends "res://nucleo/entrenamiento_p1.gd"
## [Capa 2/3 de `entrenamiento.gd`] _sesion_general, _dado_de_la_intensidad, _plan_por_dias, _hay_capitan, tiene_habilidad, nombre_habilidad … (+15)

## La sesión general del HTML: reparte físico, sube la moral si hay con qué,
## hace progresar a los jóvenes y desgasta a los veteranos.
func _sesion_general(j: Jugador, mult: float, ritmo: float, joven: float, res: Dictionary) -> void:
	## Físico. El `recup` reparte 26 en vez de 16, y el preparador físico suma
	## de tres en tres: es el número que hace que contratarlo se note el lunes.
	##
	## EL NUTRICIONISTA Y EL UTILERO ya existen -llegaron con las ideas 91-105-,
	## asi que la recuperacion semanal ya no sale solo del comedor y la piscina.
	## Suman poco cada uno; el punto es que son baratos y se contratan pronto.
	var base := 26 if foco == "recup" else 16
	var extra := (staff.aguante() * 3) if staff != null else 0
	extra += (staff.recuperacion_fisica() * 2) if staff != null else 0
	extra += obras.aguante() if obras != null else 0
	j.fisico = clampi(j.fisico + base + extra, 10, 100)

	## El jugador en desarrollo prioritario paga la carga extra en físico.
	if es_prioritario(j):
		j.fisico = clampi(j.fisico - 1, 10, 100)

	## En el HTML esto lo hacía el psicólogo del staff, que no está portado. La
	## puerta equivalente que sí existe es el espacio de bienestar y la
	## guardería: si el club los tiene, el vestuario va levantando el ánimo solo.
	var calma := obras.calma_del_vestuario() if obras != null else 0
	if calma > 0 and j.moral < 40 + 5 * calma:
		j.cambiar_moral(1, "Entrenamiento")
	## Progreso de los menores de 24. La probabilidad base es 0,10 y encima se
	## multiplican intensidad, formador del DT, rasgo motor, plan prioritario,
	## centro de entrenamiento y foco técnico. Todos son del HTML.
	if j.edad < 24 and j.ovr < j.pot:
		## `ProgresoJugador.freno()`: más lento con la edad y al acercarse al techo (antes, 0,10 plano).
		var p := 0.10 * mult * ritmo * ProgresoJugador.freno(j)
		if j.edad < 23:
			p *= joven
		if j.rasgo == "motor":
			p *= 1.5
		if es_prioritario(j):
			p *= 1.5
		if foco == "tecnico":
			p *= 1.5
		if Azar.suerte(p):
			_subir_media(j, Azar.ent(1, 2), res)

	## Y la otra cara: a partir de los 31 se empieza a perder, un 5% de las
	## semanas. El suelo son 45 de media, no 0: un veterano se apaga, no
	## desaparece.
	if j.edad >= 31 and Azar.suerte(0.05) and j.ovr > 45:
		var antes := j.ovr
		j.ajustar_media(-1)
		## Lo que se va primero son las piernas: ritmo y físico en un jugador de
		## campo, velocidad en un portero.
		var decae: Array = ["rit", "fis"] if j.atributos.has("rit") else ["vel"]
		var k := String(Azar.uno(decae))
		if j.atributos.has(k):
			j.atributos[k] = clampi(int(j.atributos[k]) - Azar.ent(1, 2), 22, 99)
		_tasar(j)
		res["bajaron"].append(j)
		progreso.emit(j, antes, j.ovr)

## Entrenar al límite tiene un precio: una de cada cuatro semanas alguien se
## queda en el camino, y si hay un frágil en el plantel suele ser él.
func _dado_de_la_intensidad(c: Club, anio: int, semana: int, res: Dictionary) -> void:
	if intensidad != "alta":
		return
	var nivel_med := staff.nivel("medico") if staff != null else 0
	if not Azar.suerte(0.25 * (1.0 - 0.12 * float(nivel_med))):
		return
	var libres := c.disponibles()
	if libres.is_empty():
		return
	var j: Jugador = Azar.uno(libres)
	## La mitad de las veces el dado se corrige hacia el frágil. No es un capricho
	## del HTML: es lo que hace que el rasgo se note y que machacar al plantel sea
	## una decisión y no una estadística invisible.
	if j.rasgo != "fragil" and Azar.suerte(0.5):
		for x in libres:
			if x.rasgo == "fragil":
				j = x
				break
	var sem := 0
	if medico != null:
		var sev: int = Medico.MEDIA if Azar.suerte(0.20) else Medico.LEVE
		sem = medico.lesionar(j, sev, "entrenando al límite", anio, semana)
	else:
		sem = Azar.ent(1, 3)
		j.lesionar(sem)
	res["lesionados"].append({"jugador": j, "semanas": sem})
	noticia.emit("Lesión en entrenamiento",
		"%s se queda en el camino entrenando al límite: %d semana(s) de baja. El cuerpo médico sugiere bajar la intensidad."
		% [j.nombre, sem])

## El plan por días: la carga del lunes al sábado se reparte sobre el plantel.
func _plan_por_dias(c: Club, carg: Dictionary, ritmo: float, res: Dictionary) -> void:
	## El gimnasio multiplica lo que se recupera; el 0,55 es el freno del HTML,
	## sin él una semana de descanso completo llenaba el depósito de golpe.
	var gim := (1.0 + 0.08 * float(obras.nivel("gim"))) if obras != null else 1.0
	for j in c.plantilla:
		j.fisico = clampi(j.fisico + int(round(float(carg["fis"]) * gim * 0.55)), 10, 100)
		j.cambiar_moral(int(round(float(carg["moral"]) * 0.4)), "Entrenamiento")
		## El riesgo de romperse por acumulación NO se tira aquí: lo tira
		## `Medico.chequeo_de_fatiga` con la carga que devuelve `carga_riesgo()`.
		if j.edad < 24 and j.ovr < j.pot:
			var p := float(carg["ovr"]) * 0.014 * ritmo * ProgresoJugador.freno(j)
			if j.rasgo == "motor":
				p *= 1.5
			if Azar.suerte(p):
				_subir_media(j, 1, res)

func _hay_capitan(c: Club) -> bool:
	for j in c.plantilla:
		if j.capitan:
			return true
	return false

func tiene_habilidad(j: Jugador, clave: String) -> bool:
	return _lista(j.id).has(clave)

func nombre_habilidad(clave: String) -> String:
	var t := _habs_tabla()
	if not t.has(clave):
		return clave
	return Nombres.limpiar(String((t[clave] as Array)[0]))

## Los planes individuales. Tardan entre cinco y nueve semanas y terminan
## enseñando una habilidad de verdad, no un +1 invisible.
func _trabajo_individual(c: Club, res: Dictionary) -> void:
	for j in c.plantilla:
		if not individual.has(j.id):
			continue
		var plan: Dictionary = individual[j.id]
		plan["semanas"] = int(plan["semanas"]) + 1
		## El trabajo extra se paga en piernas. El HTML descontaba 1,5 sobre un
		## físico decimal; aquí `Jugador.fisico` es entero y se redondea a 2, que
		## es la diferencia de medio punto cada varias semanas y no mueve nada.
		j.fisico = clampi(j.fisico - 2, 10, 100)
		if int(plan["semanas"]) < Azar.ent(IND_MIN, IND_MAX):
			continue
		var e := especial(String(plan["clave"]))
		individual.erase(j.id)
		if e.is_empty():
			continue
		var hab: Variant = e[3]
		if hab == null:
			## El plan de liderazgo no da habilidad: da peso en el vestuario y la
			## cinta si no hay capitán.
			j.cambiar_moral(12, "Entrenamiento")
			if not _hay_capitan(c):
				j.capitan = true
			noticia.emit("%s crece como líder" % j.nombre,
				"Termina su plan de liderazgo: más peso en el vestuario y candidato natural a la cinta.")
			continue
		var k := String(hab)
		if not tiene_habilidad(j, k):
			_lista(j.id).append(k)
			res["aprendieron"].append({"jugador": j, "habilidad": k})
			habilidad_aprendida.emit(j, k, nombre_habilidad(k))
			noticia.emit("%s domina una habilidad nueva" % j.nombre,
				"%s termina su plan de %s y suma la habilidad «%s». Se nota en el campo desde ya."
				% [j.nombre, String(e[1]).to_lower(), nombre_habilidad(k)])
		else:
			## Ya la tenía: el trabajo se traduce en atributos, que es lo que
			## impide que repetir el mismo plan sea tiempo tirado.
			var ks: Array = j.atributos.keys()
			if not ks.is_empty():
				var kk := String(ks[0])
				j.atributos[kk] = clampi(int(j.atributos[kk]) + 2, 22, 99)
				_tasar(j)
			noticia.emit("%s afina lo que ya sabía" % j.nombre,
				"Ya tenía la habilidad, así que el trabajo se tradujo en atributos.")
func procesar_semana(c: Club, anio: int = 0, semana: int = 0) -> Dictionary:
	var res := {"subieron": [], "bajaron": [], "aprendieron": [], "lesionados": [], "punto_dt": false}
	if c == null:
		return res
	_procesar_mentorias(c)

	var mult := multiplicador_intensidad()
	var ritmo := obras.ritmo_de_progreso() if obras != null else 1.0
	var joven := factor_progreso_joven()

	for j in c.plantilla:
		_sesion_general(j, mult, ritmo, joven, res)
	_dado_de_la_intensidad(c, anio, semana, res)

	var carg := carga()
	_plan_por_dias(c, carg, ritmo, res)
	_trabajo_individual(c, res)

	if concentracion:
		var costo := Eco.escalar(COSTE_CONCENTRACION, float(c.rep))
		c.mover_saldo(-costo)
		gasto.emit("Concentración de la semana", costo)
		for j in c.plantilla:
			j.fisico = clampi(j.fisico + 3, 10, 100)

	## El punto de habilidad del entrenador: uno cada diez semanas de trabajo.
	semanas_trabajadas += 1
	if semanas_trabajadas % SEMANAS_POR_PUNTO_DT == 0:
		dt_puntos += 1
		res["punto_dt"] = true
		punto_dt_ganado.emit(dt_puntos)
		noticia.emit("Punto de habilidad de entrenador",
			"Diez semanas más de trabajo en el banquillo. Tienes %d punto(s) por gastar en tu árbol de carrera."
			% dt_puntos)
	return res

## Progresión de un jugador que NO es tuyo. El HTML entrenaba al mundo entero en
## la misma pasada, sin foco ni intensidad ni instalaciones: solo el 0,10 base y
## el desgaste de los veteranos. Sin esto, los rivales se quedan congelados y en
## tres temporadas tu cantera domina el continente sola.
func procesar_ajeno(j: Jugador) -> void:
	j.fisico = clampi(j.fisico + 16, 10, 100)
	## La probabilidad la da `ProgresoJugador` (baja con la edad); antes un 0,10 plano hasta los 24.
	var p := ProgresoJugador.prob_semanal(j)
	if p > 0.0:
		if Azar.suerte(p):
			var antes := j.ovr
			j.ajustar_media(1)
			if not j.atributos.is_empty():
				var k := String(Azar.uno(j.atributos.keys()))
				j.atributos[k] = clampi(int(j.atributos[k]) + Azar.ent(1, 2), 22, 99)
			j.tasar()
			progreso.emit(j, antes, j.ovr)
	if j.edad >= 31 and Azar.suerte(0.05) and j.ovr > 45:
		var antes2 := j.ovr
		j.ajustar_media(-1)
		var decae: Array = ["rit", "fis"] if j.atributos.has("rit") else ["vel"]
		var k2 := String(Azar.uno(decae))
		if j.atributos.has(k2):
			j.atributos[k2] = clampi(int(j.atributos[k2]) - Azar.ent(1, 2), 22, 99)
		j.tasar()
		progreso.emit(j, antes2, j.ovr)

func reiniciar_subidas() -> void:
	_subidas.clear()

# ---------------------------------------------------------------------------
#  PRETEMPORADA
# ---------------------------------------------------------------------------

## Se elige una vez al año y marca la temporada entera. Devuelve "" si se hizo,
## o el motivo por el que no.
func elegir_pretemporada(clave: String, c: Club, anio: int = 0, semana: int = 0) -> String:
	if pretemporada != "":
		return "la pretemporada de este año ya está hecha"
	var d: Array = []
	for fila: Array in pretemporadas():
		if String(fila[0]) == clave:
			d = fila
			break
	if d.is_empty():
		return "esa pretemporada no existe"
	var costo := Eco.escalar(float(d[2]), float(c.rep)) if float(d[2]) > 0.0 else 0
	if costo > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, c.saldo]
	if costo > 0:
		c.mover_saldo(-costo)
		gasto.emit("Pretemporada: " + String(d[1]), costo)
	pretemporada = clave
	var ef: Dictionary = d[4]
	var rotos := 0
	for j in c.plantilla:
		j.fisico = clampi(j.fisico + int(ef.get("fis", 0)), 10, 100)
		## La forma sube seis décimas de lo que sube el físico: llegar fuerte a
		## agosto no es lo mismo que llegar enchufado.
		j.forma = clampi(j.forma + int(round(float(ef.get("fis", 0)) * 0.6)), 20, 99)
		var base := int(ef.get("base", 0))
		if base > 0 and j.ovr < j.pot and Azar.suerte(0.25 * float(base)):
			var antes := j.ovr
			j.ajustar_media(1)
			_subidas[j.id] = int(_subidas.get(j.id, 0)) + 1
			_tasar(j)
			progreso.emit(j, antes, j.ovr)
		if Azar.suerte(float(ef.get("riesgo", 0)) / 100.0):
			if medico != null:
				medico.lesionar(j, Medico.LEVE, "en la pretemporada", anio, semana)
			else:
				j.lesionar(Azar.ent(1, 3))
			rotos += 1
	var cola := " %d jugador(es) se resintieron durante el trabajo." % rotos if rotos > 0 else ""
	noticia.emit(String(d[1]), String(d[3]) + "." + cola)
	return ""

## Al empezar temporada vuelve a haber pretemporada que elegir.
func reiniciar_pretemporada() -> void:
	pretemporada = ""

## Mete una habilidad sin pasar por el árbol. Es lo que usa el sorteo de
## nacimiento y lo que necesita el que cargue una partida vieja.
func dar_habilidad(j: Jugador, clave: String) -> bool:
	if not _habs_tabla().has(clave):
		return false
	var l := _lista(j.id)
	if l.has(clave):
		return false
	l.append(clave)
	return true

func puntos(j: Jugador) -> int:
	return int(_puntos.get(j.id, 0))

## Qué se le puede ofrecer a este jugador. Al portero SOLO sus tres: parar
## penales, jugar con los pies y mandar en la línea. Ofrecerle una ruleta sería
## un menú lleno de botones muertos.
func disponibles(j: Jugador) -> Array[String]:
	var salida: Array[String] = []
	var por := j.es_portero()
	for k: String in _skill_tabla():
		var de_portero := k == "atajaPen" or k == "juegoPies"
		if por:
			if de_portero or k == "liderazgo":
				salida.append(k)
		elif not de_portero:
			salida.append(k)
	return salida

## Qué atributo gobierna esta habilidad EN ESTE jugador.
##
## TRAMPA HEREDADA DEL HTML: la tabla dice que «Voz de mando» la gobierna `def`,
## y un portero no tiene `def` -sus atributos son div/par/saq/ref/vel/pos-. El
## resultado era que al arquero se le ofrecía liderazgo en el menú y nunca podía
## aprenderlo, porque su `def` valía siempre 0. Aquí se le pide lo mismo (66)
## pero sobre `pos`, que es el atributo del portero que de verdad significa leer
## el juego y ordenar la línea. El número no cambia; lo que cambia es que el
## botón deja de estar muerto.
func atributo_de(j: Jugador, clave: String) -> String:
	var t := _skill_tabla()
	if not t.has(clave):
		return ""
	var at := String((t[clave] as Array)[1])
	if j.es_portero() and not j.atributos.has(at) and j.atributos.has("pos"):
		return "pos"
	return at

## Por qué NO puede aprenderla. Cadena vacía significa que sí puede. Devolver el
## motivo y no un booleano es a propósito: el menú tiene que decir "necesita REG
## 72", no apagar el botón y callarse.
func motivo(j: Jugador, clave: String) -> String:
	var t := _skill_tabla()
	if not t.has(clave):
		return "no disponible"
	var s: Array = t[clave]
	if tiene_habilidad(j, clave):
		return "ya la tiene"
	var req: Variant = s[3]
	if req != null and not tiene_habilidad(j, String(req)):
		return "antes: " + nombre_habilidad(String(req))
	var at := atributo_de(j, clave)
	var v := int(j.atributos.get(at, 0))
	var minimo := int(s[2])
	if v < minimo:
		return "necesita %s %d (tiene %d)" % [at.to_upper(), minimo, v]
	if puntos(j) < 1:
		return "sin puntos"
	return ""

func puede(j: Jugador, clave: String) -> bool:
	return motivo(j, clave) == ""

func descripcion_habilidad(clave: String) -> String:
	var t := _habs_tabla()
	if not t.has(clave):
		return ""
	return String((t[clave] as Array)[1])

## Gasta un punto y aprende. Devuelve "" si se aprendió, o el motivo por el que no.
func aprender(j: Jugador, clave: String) -> String:
	var m := motivo(j, clave)
	if m != "":
		return m
	_lista(j.id).append(clave)
	_puntos[j.id] = puntos(j) - 1
	## Aprender algo deja huella en el atributo que lo gobierna. Es un punto, no
	## es mucho, pero es lo que hace que el árbol se vea también en la ficha.
	var at := atributo_de(j, clave)
	if j.atributos.has(at):
		j.atributos[at] = clampi(int(j.atributos[at]) + 1, 1, 99)
	j.cambiar_moral(4, "Entrenamiento")
	_tasar(j)
	habilidad_aprendida.emit(j, clave, nombre_habilidad(clave))
	noticia.emit("Nueva habilidad: " + j.nombre,
		"%s termina de pulir «%s» en los entrenamientos. %s. Le quedan %d punto(s) por gastar."
		% [j.nombre, nombre_habilidad(clave), descripcion_habilidad(clave), puntos(j)])
	return ""

## El reparto de fin de temporada. Los puntos se ganan JUGANDO, no comprando:
## doce partidos dan uno, y los menores de 21 con ocho partidos ganan otro más.
## Devuelve la lista de [{jugador, puntos}] para que la interfaz lo cuente.
func repartir_puntos(c: Club) -> Array:
	var ganaron: Array = []
	if c == null:
		return ganaron
	for j in c.plantilla:
		var p := 0
		if j.partidos >= 12:
			p += 1
		if j.edad <= 21 and j.partidos >= 8:
			p += 1
		if p > 0:
			_puntos[j.id] = puntos(j) + p
			ganaron.append({"jugador": j, "puntos": p})
	if ganaron.is_empty():
		return ganaron
	ganaron.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["puntos"]) != int(b["puntos"]):
			return int(a["puntos"]) > int(b["puntos"])
		return (a["jugador"] as Jugador).pot > (b["jugador"] as Jugador).pot)
	var dobles: Array[String] = []
	for x: Dictionary in ganaron:
		if int(x["puntos"]) == 2 and dobles.size() < 6:
			var j: Jugador = x["jugador"]
			dobles.append("%s (%d)" % [j.nombre, j.edad])
	var cuerpo := "%d futbolistas ganaron puntos por los minutos que jugaron. " % ganaron.size()
	if not dobles.is_empty():
		cuerpo += "Con dos puntos, por ser jóvenes con rodaje: " + ", ".join(dobles) + ". "
	cuerpo += "Gástalos en la ficha de cada jugador, en el árbol de habilidades: lo que aprendan se nota en el campo."
	noticia.emit("Puntos de habilidad de la temporada", cuerpo)
	return ganaron
