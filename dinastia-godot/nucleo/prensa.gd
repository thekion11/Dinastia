class_name Prensa
extends "res://nucleo/prensa_p6.gd"
## [Capa 8/8 de `prensa.gd`] mesa_de_debate, ranking_entrenadores, nombrar_vocero, revisar_vocero, negociar_tv, factor_tv … (+7)

## Qué dice cada uno esta semana. Depende del ESTADO REAL del club -puesto,
## racha, ánimo-, no de un sorteo: si dijeran cosas al azar, se notaría a la
## segunda semana y dejarían de leerse.
func mesa_de_debate() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return salida
	var c := m.mi_club()
	var liga := m.liga_de(c)
	var puesto := 0
	var n := 0
	if liga != null:
		for f: Dictionary in liga.tabla():
			n += 1
			if f["club"] == c:
				puesto = n
	var arriba := puesto > 0 and puesto <= 4
	var abajo := puesto > 0 and puesto > n - 4
	var jovenes := 0
	for j in c.plantilla:
		if j.edad <= 21 and j.partidos > 3:
			jovenes += 1
	for f2: Array in TERTULIANOS:
		var frase := ""
		match String(f2[0]):
			"exdt":
				frase = ("Con esos chicos no se gana nada; ya se verá en marzo." if jovenes >= 3
					else "Ordenado atrás. Eso es lo primero, lo demás viene solo.")
			"periodista":
				frase = ("El club está donde tiene que estar. El entrenador es lo de menos." if arriba
					else "Aquí ha habido épocas peores, y también se salió de ellas.")
			"exjugador":
				frase = ("Ese vestuario está vivo. Se nota que corren por alguien." if animo >= 60
					else "Al vestuario lo veo solo. Y cuando el vestuario está solo, pasa lo que pasa.")
			"datos":
				frase = ("Los números lo sostienen: genera más de lo que concede." if arriba
					else "Los números no engañan, y ahora mismo no dan.")
			"polemista":
				frase = ("Que alguien explique qué es esto, porque yo no lo entiendo." if (abajo or funa > 45)
					else "Ganan, sí. Pero que no se relajen, que aquí se olvida rápido.")
		salida.append({"nombre": String(f2[1]), "perfil": String(f2[2]), "frase": frase})
	return salida

## El escalafón de entrenadores del país. La nota premia rendir POR ENCIMA de lo
## que el club permite: un séptimo con el decimoquinto presupuesto vale más que
## un tercero con el primero. Es la única métrica del juego que mide al
## entrenador y no al club.
func ranking_entrenadores() -> Array[Dictionary]:
	var m := _mundo()
	var salida: Array[Dictionary] = []
	if m == null or m.mi_club() == null:
		return salida
	var mio := m.mi_club()
	for l: Liga in m.ligas:
		if l.pais != mio.pais:
			continue
		## El puesto REAL en la tabla contra el puesto ESPERADO por reputación.
		var por_rep := l.clubes.duplicate()
		por_rep.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
		var esperado := {}
		for i in por_rep.size():
			esperado[(por_rep[i] as Club).id] = i + 1
		var puesto := 0
		for f: Dictionary in l.tabla():
			puesto += 1
			var c: Club = f["club"]
			var esp := int(esperado.get(c.id, puesto))
			var nota := clampi(60 + (esp - puesto) * 7 + int(round(float(int(f["pts"])) - float(int(f["pj"])) * 1.3) * 1.6), 10, 99)
			salida.append({
				"club": c, "nota": nota, "puesto": puesto, "esperado": esp,
				"mio": c == mio,
			})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["nota"]) > int(b["nota"]))
	return salida

## Nombrar o quitar al vocero. Solo un capitán o un líder de vestuario sirve:
## poner a hablar al último fichaje de dieciocho años no lo aguantaría nadie.
func nombrar_vocero(mio: Club) -> String:
	if not vocero.is_empty():
		vocero = {}
		return "Vuelves a dar tú la cara en cada rueda de prensa."
	if mio == null or mio.plantilla.is_empty():
		return "no hay plantilla"
	var candidatos: Array[Jugador] = []
	for j: Jugador in mio.plantilla:
		if j.capitan or j.rasgo == "lider":
			candidatos.append(j)
	if candidatos.is_empty():
		return "hace falta un capitán o un líder de vestuario: nadie más tiene el peso para hablar por el club"
	var elegido: Jugador = candidatos[Azar.ent(0, candidatos.size() - 1)]
	vocero = {"id": elegido.id, "nombre": elegido.nombre}
	noticia.emit("Nuevo vocero del club",
		"%s hablará por ti en las ruedas de prensa. Menos desgaste para ti, pero también menos control sobre el mensaje." % elegido.nombre)
	return "%s habla por ti desde hoy." % elegido.nombre

## El vocero se va con el jugador. Si lo vendes, lo cedes o se retira, el club
## se queda sin quien hable: no avisarlo dejaría un nombre fantasma en pantalla.
func revisar_vocero(mio: Club) -> void:
	if vocero.is_empty() or mio == null:
		return
	for j: Jugador in mio.plantilla:
		if j.id == String(vocero.get("id", "")):
			return
	var quien := String(vocero.get("nombre", "el vocero"))
	vocero = {}
	noticia.emit("El club se queda sin vocero",
		"%s ya no está en el plantel. A partir de la próxima rueda vuelves a dar tú la cara." % quien)

func negociar_tv(individual: bool, mio: Club) -> String:
	if tv_individual == individual:
		return "ya estás en ese modelo"
	tv_individual = individual
	if not individual:
		noticia.emit("Vuelves al reparto en bloque",
			"El club vuelve a negociar la televisión junto al resto de la liga. Menos techo, más seguridad.")
		return "Vuelves al reparto en bloque."
	var m := _mundo()
	if m != null and m.federacion != null:
		m.federacion.aliados = clampi(m.federacion.aliados - 2, -10, 10)
	if mio != null and mio.rep >= REP_VENDE_SOLO:
		noticia.emit("Contrato de TV individual",
			"Negociaste por tu cuenta y te fue bien: tu marca vende. Los derechos suben un 35%, pero los clubes pequeños te lo van a cobrar en la asamblea.")
		return "Los derechos suben un 35%."
	noticia.emit("Contrato de TV individual",
		"Negociaste por tu cuenta y te fue mal: sin la fuerza del bloque, los derechos caen un 30%.")
	return "Los derechos caen un 30%."

## El multiplicador que sale de esta decisión. En bloque no toca nada.
func factor_tv() -> float:
	if not tv_individual:
		return 1.0
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio != null and mio.rep >= REP_VENDE_SOLO:
		return 1.35
	return 0.70

## La media de las relaciones con los cinco periodistas, de 0 a 100.
func relacion_media() -> int:
	var s := 0
	for f: Array in PERIODISTAS:
		s += relacion_con(String(f[0]))
	return int(round(float(s) / float(maxi(1, PERIODISTAS.size()))))

# ---------------------------------------------------------------------------
#  EL AÑO CONTADO
# ---------------------------------------------------------------------------
#
# Un párrafo, no una tabla. Toda la información ya está repartida por seis
# pantallas: el puesto, los títulos, las rachas, los récords, el goleador. Aquí
# se cuenta como se lo contaría alguien, que es la única forma de que un
# resultado deportivo se lea como una temporada y no como una fila.

func narrador_temporada() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "Todavía no hay temporada que contar."
	var mio := m.mi_club()
	var partes: PackedStringArray = []

	var puesto := 0
	for l: Liga in m.ligas:
		if not l.clubes.has(mio):
			continue
		var n := 0
		for f: Dictionary in l.tabla():
			n += 1
			if f["club"] == mio:
				puesto = n
				break
	if puesto > 0:
		partes.append("La temporada %d de %s terminó en el puesto %d." % [m.anio, mio.nombre, puesto])
	else:
		partes.append("La temporada %d de %s todavía se está jugando." % [m.anio, mio.nombre])

	if m.roles != null:
		var del_anio: PackedStringArray = []
		for t: Dictionary in m.roles.trofeos:
			if int(t.get("anio", 0)) == m.anio:
				del_anio.append(String(t.get("titulo", "")))
		if del_anio.size() > 0:
			partes.append("Se levantaron %d título%s: %s." % [
				del_anio.size(), "" if del_anio.size() == 1 else "s",
				", ".join(del_anio)])
		else:
			partes.append("Sin títulos esta vez.")

	if m.logros != null:
		var r: Dictionary = m.logros.rachas
		if int(r.get("invicto_max", 0)) >= 8:
			partes.append("Hubo una racha de %d partidos sin perder que hizo soñar a la ciudad." % int(r["invicto_max"]))
		if int(r.get("sin_ganar_max", 0)) >= 6:
			partes.append("También hubo un bache de %d partidos sin ganar que puso todo en duda." % int(r["sin_ganar_max"]))
		var rec: Dictionary = m.logros.rec
		var mg: Variant = rec.get("mayor_goleada")
		if mg is Dictionary and int((mg as Dictionary).get("anio", 0)) == m.anio:
			partes.append("La noche grande fue el %s a %s." % [
				String((mg as Dictionary).get("marcador", "")), String((mg as Dictionary).get("rival", ""))])
		var pd: Variant = rec.get("peor_derrota")
		if pd is Dictionary and int((pd as Dictionary).get("anio", 0)) == m.anio:
			partes.append("La peor, el %s con %s." % [
				String((pd as Dictionary).get("marcador", "")), String((pd as Dictionary).get("rival", ""))])
		## El hombre gol. `rec["goles"]` va por id de jugador con {nombre, n} -no
		## por nombre-, que es la trampa que ya costó una lectura en vacío.
		var mejor := ""
		var mejor_n := 0
		var goles: Dictionary = rec.get("goles", {})
		for pid: String in goles:
			var g: Dictionary = goles[pid]
			if int(g.get("n", 0)) > mejor_n:
				mejor_n = int(g.get("n", 0))
				mejor = String(g.get("nombre", ""))
		if mejor != "" and mejor_n > 0:
			partes.append("%s fue el hombre gol con %d tantos." % [mejor, mejor_n])

	var media := relacion_media()
	if media > 60:
		partes.append("La prensa cerró el año de tu lado.")
	elif media < 40:
		partes.append("La prensa cerró el año afilando los cuchillos.")
	else:
		partes.append("La prensa mantuvo la distancia.")
	return " ".join(partes)

## El titular y su cuerpo, firmados por uno de los periodistas de la casa.
func titular_prensa(gane: bool, empate: bool, clasico: bool, semilla: String, nombre_clasico: String = "") -> Dictionary:
	var pool: Array = _TIT_GANE if gane else (_TIT_EMPATE if empate else _TIT_PERDI)
	var h := _hash_de(semilla)
	var t: Array = pool[h % pool.size()]
	var p: Array = PERIODISTAS[(h / 7) % PERIODISTAS.size()]
	return {
		## Con nombre propio si lo tiene: "SUPERCLÁSICO: ..." (C4).
		"tit": ((nombre_clasico.trim_prefix("el ").to_upper() + ": ") if nombre_clasico != "" else ("CLÁSICO: " if clasico else "")) + String(t[0]),
		"cuerpo": "%s — %s, %s." % [String(t[1]), String(p[1]), String(p[2])],
	}

## LA RUEDA DESPUÉS DE TU PARTIDO, sin necesitar el `Partido` completo.
##
## `sortear_rueda()` pedía un `Partido` y por eso no la llamaba nadie: el bucle
## de la semana solo tiene el marcador. Toda la sala de prensa —tres barajas de
## preguntas, cinco lenguajes corporales, trece decisiones— existía y no se
## abría una sola vez en una partida de verdad. Esta es la puerta que faltaba.
func rueda_tras_resultado(gane: bool, empate: bool) -> Dictionary:
	## El dado se tira SIEMPRE, aunque ya haya una rueda abierta: así el consumo
	## de azar es el mismo jornada a jornada, que es la regla de toda la casa.
	var toca := Azar.suerte(0.5)
	if not toca or not entrevista.is_empty():
		return {}
	return abrir_rueda(gane, empate)

## La portada del lunes: la escribe el resultado y la archiva la hemeroteca.
func portada_tras_resultado(gane: bool, empate: bool, clasico: bool, semilla: String, marcador: String = "", nombre_clasico: String = "") -> void:
	var h := _hash_de(semilla + "|portada")
	if h % PORTADA_DE_CADA >= PORTADAS_QUE_SALEN:
		return
	var t := titular_prensa(gane, empate, clasico, semilla, nombre_clasico)
	var tipo := "bien" if gane else ("neutro" if empate else "mal")
	guardar_portada(String(t["tit"]), String(t["cuerpo"]), tipo, {"img": "dt", "sub": marcador, "nueva": true})
	noticia.emit("🗞️ " + String(t["tit"]), String(t["cuerpo"]))

## Quién habla esta semana y qué dice. Devuelve {nombre, seguidores, texto, tono}.
func opinion_influencer() -> Dictionary:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if mio == null:
		return {}
	var lista: Variant = Datos.tabla("INFLUENCERS")
	if not (lista is Array) or (lista as Array).is_empty():
		return {}
	var quienes: Array = lista as Array
	var anio := m.anio
	var sem := m.semana
	var i: Array = quienes[_hash_de("inf%d%d" % [anio, sem]) % quienes.size()]

	## La racha REAL, leída de `Logros`. Si el creador dijera cualquier cosa se
	## notaría a la segunda semana y se dejaría de leer. El HTML miraba los
	## últimos cinco resultados; aquí se miran las rachas, que es la misma
	## información ya contada y sin guardar una lista aparte para esto.
	var g := 0
	var p := 0
	if m.logros != null:
		g = int(m.logros.rachas.get("ganando", 0))
		p = int(m.logros.rachas.get("sin_ganar", 0))
	var tono := "bien" if g >= 3 else ("mal" if p >= 2 else "neutro")
	var pool: Array = _INFLU_BIEN if tono == "bien" else (_INFLU_MAL if tono == "mal" else _INFLU_NEUTRO)
	return {
		"nombre": String(i[1]),
		"seguidores": String(i[2]) if i.size() > 2 else "",
		"texto": String(pool[_hash_de("op%d" % sem) % pool.size()]),
		"tono": tono,
	}

## Invitarlo al club o dejarlo hablando solo. Devuelve lo que pasó.
func responder_influencer(invitar: bool, c: Club) -> String:
	if not invitar:
		rep_entrenador = clampi(rep_entrenador - 2, 0, 100)
		return "Lo dejaste hablando solo. Se nota en el índice de prensa."
	if c == null:
		return "no hay club"
	var coste := Eco.escalar(COSTE_INVITAR, float(c.rep))
	if c.saldo < coste:
		return "invitarlo cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento.emit("Acción con creadores de contenido", -coste)
	var ganados := int(round(float(seguidores) * 0.06))
	seguidores += ganados
	rep_entrenador = clampi(rep_entrenador + 4, 0, 100)
	noticia.emit("Puertas abiertas",
		"Invitaste a un creador a un entrenamiento. El club ganó %d seguidores y algo de cariño en redes." % ganados)
	return "El club gana %d seguidores." % ganados
