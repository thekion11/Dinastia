extends "res://nucleo/prensa_p5.gd"
## [Capa 7/8 de `prensa.gd`] clasificar_respuesta, opcion_de_texto, responder_texto, pie_de_campo, revisar_al_paso, abrir_al_paso … (+18)

## El tono de una frase escrita. Menos de ocho letras tampoco es una respuesta.
func clasificar_respuesta(texto: String) -> String:
	var t := texto.strip_edges().to_lower()
	if t.length() < 8:
		return "evasiva"
	for k: String in _SOBERBIAS:
		if t.contains(k):
			return "soberbia"
	for k: String in _EVASIVAS:
		if t.contains(k):
			return "evasiva"
	return "calma"

## La opción que sale de un texto libre: el tono pone la base y lo que nombras
## la matiza -hablar de la gente suma socios, del grupo suma moral, de los
## árbitros los pone en tu contra-.
func opcion_de_texto(texto: String) -> Dictionary:
	var tono := clasificar_respuesta(texto)
	var base: Dictionary = {"calma": [1, 1, 0], "soberbia": [2, 1, 1], "evasiva": [-1, 0, -1]}
	var v: Array = base[tono]
	var t := texto.to_lower()
	var dm := int(v[0])
	var dc := int(v[1])
	var ds := int(v[2])
	if t.contains("hinch") or t.contains("afici") or t.contains("la gente") or t.contains("cantera") or t.contains("juvenil"):
		ds += 1
	if t.contains("plantel") or t.contains("grupo") or t.contains("jugadores") or t.contains("equipo"):
		dm += 1
	if (t.contains("directiv") or t.contains("directorio") or t.contains("presidente")) and tono != "calma":
		dc -= 1
	return {"txt": texto.strip_edges().substr(0, 120), "moral": dm, "confianza": dc, "socios": ds,
		"tono": tono, "arbitros": t.contains("árbitr") or t.contains("arbitr")}

func responder_texto(texto: String, segundos: float = -1.0) -> Dictionary:
	if entrevista.is_empty() or texto.strip_edges() == "":
		return {}
	var o := opcion_de_texto(texto)
	## Hablar de los árbitros en una rueda nunca sale gratis.
	if bool(o["arbitros"]):
		enojo_arbitral += 1
	(entrevista["opciones"] as Array).append(o)
	return responder((entrevista["opciones"] as Array).size() - 1, segundos)

# --- a pie de campo ------------------------------------------------------------
## La entrevista corta al terminar el partido que dirigiste: una pregunta y
## tres salidas. Mueve poco -ánimo de la hinchada y moral- porque es caliente y
## todos lo saben; lo que cuenta es la frase, que va al registro.
func pie_de_campo(gane: bool, empate: bool, gf: int, gc: int) -> Dictionary:
	var f := periodista_de("navarrete")
	var q := ""
	var ops: Array = []
	if gane:
		q = "¡Victoria por %d-%d! ¿Qué le dice a la gente que vino hoy?" % [gf, gc]
		ops = [
			{"txt": "Gracias a ellos: este triunfo es de todos", "tono": "calma", "animo": 2, "moral": 1},
			{"txt": "Que se vayan acostumbrando", "tono": "soberbia", "animo": 1, "moral": 1},
			{"txt": "Ahora toca descansar", "tono": "evasiva", "animo": 0, "moral": 0},
		]
	elif empate:
		q = "Empate %d-%d. ¿Sabe a poco?" % [gf, gc]
		ops = [
			{"txt": "Sumamos; el equipo dio la cara", "tono": "calma", "animo": 1, "moral": 1},
			{"txt": "El árbitro nos quitó el partido", "tono": "soberbia", "animo": 1, "moral": 0, "arbitros": true},
			{"txt": "Lo analizaremos en frío", "tono": "evasiva", "animo": 0, "moral": 0},
		]
	else:
		q = "Derrota %d-%d, duro golpe. ¿Qué pasó hoy?" % [gf, gc]
		ops = [
			{"txt": "Lo asumo yo: hoy no estuvimos", "tono": "calma", "animo": 1, "moral": 1},
			{"txt": "Los jugadores tendrán que dar explicaciones", "tono": "soberbia", "animo": 0, "moral": -2},
			{"txt": "No es momento de hablar", "tono": "evasiva", "animo": -1, "moral": 0},
		]
	pie = {"pregunta": q, "opciones": ops, "quien": "%s · %s, a pie de campo" % [String(f[1]), String(f[2])]}
	return pie

func revisar_al_paso(anio: int, sem: int) -> Dictionary:
	if not al_paso.is_empty() or not pie.is_empty():
		return {}
	var h := _hash_de("alpaso|%d|%d" % [anio, sem])
	if h % 8 != 0:
		return {}
	var medio: Array = MEDIOS_NUEVOS[(h / 8) % MEDIOS_NUEVOS.size()]
	var q: Array = PREGUNTAS_AL_PASO[(h / 64) % PREGUNTAS_AL_PASO.size()]
	var ops: Array = []
	for o: Array in q[1]:
		ops.append({"txt": String(o[0]), "tono": String(o[1]), "seguidores": int(o[2]), "animo": int(o[3]), "moral": 0})
	al_paso = {"pregunta": String(q[0]), "opciones": ops,
		"quien": "%s · %s, %s" % [String(medio[0]), String(medio[1]), String(medio[2])], "rotulo": "📱 Al paso"}
	return al_paso

## Pasa la entrevista al paso a la "entrevista abierta" que contesta la
## pantalla (la misma de pie de campo).
func abrir_al_paso() -> Dictionary:
	if al_paso.is_empty():
		return {}
	pie = al_paso
	al_paso = {}
	return pie

## `i` = -1: pasas de largo ante la cámara.
func responder_pie(i: int) -> Dictionary:
	if pie.is_empty():
		return {}
	var ops: Array = pie["opciones"]
	pie = {}
	if i < 0 or i >= ops.size():
		mover_animo(-1)
		noticia.emit("🎤 A pie de campo", "Pasaste de largo ante la cámara. La imagen, sin palabras, se vio igual.")
		return {"titular": "", "tono": "evasiva"}
	var o: Dictionary = ops[i]
	mover_animo(int(o.get("animo", 0)))
	## Los medios nuevos mueven seguidores, no confianza (C6).
	if o.has("seguidores"):
		seguidores = maxi(0, seguidores + int(o["seguidores"]))
	var dm := int(o.get("moral", 0))
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	if dm != 0 and mio != null:
		for j in mio.plantilla:
			j.cambiar_moral(dm, "Prensa y declaraciones")
	if bool(o.get("arbitros", false)):
		enojo_arbitral += 1
	var frase := String(o["txt"])
	var donde := "🎤 A pie de campo"
	if o.has("seguidores"):
		donde = "📱 Al paso"
	noticia.emit(donde, "«%s»." % frase + (" %+d seguidores." % int(o["seguidores"]) if o.has("seguidores") else ""))
	return {"titular": frase, "tono": String(o["tono"])}


# ===========================================================================
#  EL PULSO SEMANAL Y LOS GANCHOS PARA EL RESTO DEL JUEGO
# ===========================================================================

## Lo que hay que llamar una vez por semana, junto al resto del calendario.
##
## Aparte de descontar las cámaras, aquí está la deriva del ánimo de la hinchada
## hacia su punto de reposo (55) y los dos sucesos que dispara cuando se va a un
## extremo: el banderazo en la práctica y los lienzos contra el club. Son la
## prueba visible de que la opinión pública existe; sin ellos el número sería
## decorativo.
func semana() -> void:
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	## LAS CÁMARAS EN EL VESTUARIO. `hay_camaras()` estaba escrita y no la leía
	## nadie: aceptabas el documental, cobrabas, y las cámaras no hacían nada.
	## Ahora sí: al plantel le incomoda que lo graben, y ese es el precio de la
	## plata. Es poco por semana, pero seis semanas seguidas se notan.
	if mio != null and not efectos.is_empty():
		_aplicar_efectos(mio)
	publicar_titular_pendiente()
	revisar_identidad(mio)
	if m != null:
		revisar_al_paso(m.anio, m.semana)
	if semanas_documental > 0:
		semanas_documental -= 1
		if mio != null:
			for j in mio.plantilla:
				if j.rasgo == "fragil" or j.rasgo == "cerebro":
					j.cambiar_moral(-1, "Prensa y declaraciones")
	## EL PUNTO DE REPOSO NO ES 55 FIJO: lo mueve el AMBIENTE del estadio -la
	## forma del recinto, el techo, la pista de atletismo, las banderas- y las
	## luces y pantallas del estadio premium. `EstadioPropio.ambiente()` llevaba
	## meses calculado, enseñado en la pantalla del estadio y sin efecto ninguno:
	## elegir una caldera de 20.000 en vez de un óvalo de 30.000 no cambiaba nada.
	var reposo := 55.0
	if m != null:
		if m.estadio != null:
			reposo += float(m.estadio.ambiente())
		if m.comercial != null:
			reposo += float(m.comercial.bono_ambiente())
	animo = clampi(int(round(float(animo) + (reposo - float(animo)) * 0.03)), 0, 100)
	if mio == null:
		return
	if animo > 82 and Azar.suerte(0.09):
		for j in mio.plantilla:
			j.cambiar_moral(2, "Prensa y declaraciones")
		noticia.emit("Banderazo en la práctica",
			"Cientos de hinchas coparon el entrenamiento con bombos y lienzos de aliento. El plantel se agranda.")
	elif animo < 22 and Azar.suerte(0.14):
		for j in mio.plantilla:
			j.cambiar_moral(-2, "Prensa y declaraciones")
		noticia.emit("Lienzos contra el club",
			"Amanecieron rayados frente al estadio: 'jugadores sin sangre'. Semana tensa en la ciudad deportiva.")

## Lo llama quien simule el partido cuando el arbitraje fue un escándalo y
## perdiste. Mientras esté puesto, el directorio puede preguntarte si reclamas.
func arbitro_dudoso(nombre: String) -> void:
	arbitro_polemico = Nombres.visible(nombre)

## El parte médico robado sale UNA vez: es lo que compraste.
func consumir_dato_del_rival() -> bool:
	var s := dato_del_rival
	dato_del_rival = false
	return s

## La promesa hecha en conferencia se cobra en el próximo partido y se apaga.
func consumir_presion() -> bool:
	var s := presion_prometida
	presion_prometida = false
	return s

## ¿Hay cámaras en el camarín esta semana? Seis semanas después del documental,
## dos después de la pauta de televisión.
func hay_camaras() -> bool:
	return semanas_documental > 0

## Devuelve a los cedidos cuyo año se cumplió. Se llama al cambiar de temporada.
##
## Sin esto, aceptar la cesión sería vender al chico para siempre y el jugador se
## enteraría un año tarde: el texto promete que "vuelve hecho jugador".
func volver_de_cesion(anio: int) -> Array[Jugador]:
	var m := _mundo()
	var vueltos: Array[Jugador] = []
	if m == null:
		return vueltos
	for pid: String in cesiones.keys():
		var d: Dictionary = cesiones[pid]
		if anio < int(d["vuelve"]):
			continue
		var casa: Club = m.clubes.get(String(d["de"]))
		if casa == null:
			cesiones.erase(pid)
			continue
		for c: Club in m.clubes.values():
			var j := _jugador(c, pid)
			if j == null:
				continue
			c.soltar(j)
			casa.fichar(j)
			vueltos.append(j)
			noticia.emit("Vuelve de la cesión",
				"%s termina su préstamo y se reincorpora a la pretemporada." % j.nombre)
			break
		cesiones.erase(pid)
	return vueltos


## "if(G.impuesto&&G.impuesto.pid){...}" del HTML: el trato -de la ocupación
## hostil o del patrocinador- que obliga a alinear a un jugador concreto. Se
## revisa TRAS cada partido tuyo, con el once que de verdad saliste a jugar
## -`Mundo._avisar_a_la_directiva()` es quien lo llama, justo al lado de la
## revisión del cupo juvenil, que sigue el mismo patrón-.
func revisar_impuesto(mio: Club, xi: Array[Jugador], anio: int) -> void:
	if impuesto_pid == "":
		return
	if impuesto_hasta >= 0 and anio > impuesto_hasta:
		impuesto_pid = ""
		impuesto_hasta = -1
		noticia.emit("Se acabó el compromiso comercial",
			"El acuerdo que te obligaba a alinear a un jugador concreto llegó a su fin. Vuelves a elegir el once sin condiciones.")
		return
	var imp := _jugador(mio, impuesto_pid)
	if imp == null:
		impuesto_pid = ""
		impuesto_hasta = -1
		return
	var jugo := xi.any(func(x: Jugador) -> bool: return x.id == imp.id)
	if jugo or imp.lesion > 0 or imp.suspension > 0:
		return
	var cobro := Eco.escalar(140000.0, float(mio.rep))
	_pagar(mio, -cobro, "Penalización del patrocinador: %s fuera del once" % imp.nombre)
	var m := _mundo()
	if m != null and m.directiva != null:
		m.directiva.mover_confianza(-3, "%s fuera del once pese al pacto" % imp.nombre)
	noticia.emit("El patrocinador te lo cobra",
		"Dejaste a %s fuera del once y el acuerdo comercial exigía que jugara. Descuento de %s y una llamada incómoda del directorio." % [imp.nombre, _dinero(cobro)])

## La misma subida/bajada, para quien esté fuera de esta clase -por ejemplo,
## fichar un embajador del club sube el ánimo, y ese evento vive en Directiva-.
func sumar_animo(d: int) -> void:
	mover_animo(d)

func publicar(texto: String, voz: String = "hincha", empuje: float = 1.0) -> void:
	var perfil: Array = VOCES[0]
	for v: Array in VOCES:
		if String(v[0]) == voz:
			perfil = v
	## Los "me gusta" salen de los seguidores, no de un número al azar: si el
	## club crece, sus publicaciones crecen con él, y eso es lo que hace que
	## subir de seguidores signifique algo.
	##
	## Y NO SE USA `Azar` AQUÍ. `Azar` es el generador determinista del que
	## depende la simulación entera: consumirlo para un adorno desplaza la
	## secuencia y cambia los partidos. Pasó de verdad -el banco cazó que el
	## prestigio del entrenador dejaba de moverse en diez jornadas- y es la clase
	## de fallo que no se encuentra mirando el código, porque el código de al
	## lado está bien. Las cifras salen de un hash del propio texto: estables,
	## distintas entre mensajes, y sin tocar el azar del juego.
	var h := 0
	for i in texto.length():
		h = (h * 31 + texto.unicode_at(i)) & 0x7FFFFFFF
	var base := maxi(10, int(float(seguidores) * 0.02 * empuje))
	posts.push_front({
		"usuario": String(perfil[1]), "avatar": String(perfil[2]),
		"texto": texto, "likes": base + h % maxi(1, base * 2),
		"rt": int(base / 4) + (h >> 7) % maxi(1, base),
	})
	while posts.size() > POSTS_MAX:
		posts.pop_back()

## El pulso semanal de las redes. Los seguidores siguen al ánimo con inercia:
## se gana audiencia despacio y se pierde deprisa, como en la vida.
func semana_redes() -> void:
	## Tampoco aquí se toca `Azar`: ver la nota de `publicar()`. La variación
	## sale de la propia semana, que ya es distinta cada vez.
	var d := int(round(float(animo - 55) * 2.4)) - funa * 3
	var m := _mundo()
	var ruido := ((m.semana * 37 + m.anio * 11) % 130) - 40 if m != null else 0
	seguidores = maxi(200, seguidores + d + ruido)
	## EL COMMUNITY MANAGER. Suma un porcentaje fijo todas las semanas, pase lo
	## que pase en la cancha: es el unico crecimiento de seguidores que no depende
	## de ganar, y por eso vale la pena pagarlo en un club chico.
	if m != null and m.staff != null:
		var empuje := m.staff.empuje_redes()
		if empuje > 0.0:
			seguidores += int(round(float(seguidores) * empuje))

## Las tres respuestas del gabinete. Devuelve el texto de lo que pasó.
##
## No hay una buena: apoyar calma la funa pero gasta credibilidad, callar no
## cuesta nada hoy y deja que la bola crezca, y contestar puede apagar el fuego
## o echarle gasolina. Es la misma lógica que la charla del entretiempo.
func comunicado(tipo: String) -> String:
	match tipo:
		"apoyo":
			funa = maxi(0, funa - Azar.ent(6, 12))
			mover_animo(Azar.ent(2, 5))
			publicar("El club cierra filas con el entrenador. Veremos cuánto dura.", "periodista", 1.4)
			return "Comunicado de apoyo: la funa baja y la hinchada lo agradece, pero has gastado un cartucho."
		"silencio":
			## Callar es gratis HOY. La funa sigue su curso.
			publicar("Ni una palabra desde el club. El silencio también dice cosas.", "analista", 1.0)
			return "Silencio de prensa: no gastas nada, pero la bola sigue rodando sola."
		"contestar":
			## La jugada de riesgo: la mitad de las veces apaga el fuego y la
			## otra mitad lo dobla.
			if Azar.suerte(0.5):
				funa = maxi(0, funa - Azar.ent(10, 20))
				mover_animo(Azar.ent(3, 7))
				publicar("Respuesta directa y sin anestesia. La hinchada lo celebra.", "hincha", 2.0)
				return "Contestaste y salió bien: la funa se desinfla y el vestuario lo nota."
			funa = mini(100, funa + Azar.ent(8, 16))
			mover_animo(-Azar.ent(2, 6))
			publicar("Le contestaron a la prensa y ahora hay tres titulares más.", "troll", 2.2)
			return "Contestaste y salió mal: ahora hay tres titulares donde había uno."
	return ""

func _semana_actual() -> int:
	var m := _mundo()
	return m.semana if m != null else 0

## Atender a un periodista: le das material y mejora la relación. Uno por
## semana; si atendieras a los cinco no habría que elegir a quién cuidar.
func atender(clave: String) -> String:
	if relaciones.get("_semana_atendido", -1) == _semana_actual():
		return "ya has atendido a alguien esta semana"
	relaciones["_semana_atendido"] = _semana_actual()
	relaciones[clave] = clampi(relacion_con(clave) + Azar.ent(5, 12), 0, 100)
	## Un periodista contento escribe mejor de ti, y eso baja el ruido.
	if relacion_con(clave) >= 70:
		funa = maxi(0, funa - 2)
	return "Le das media hora y algo de material. La relación mejora."

## Cuánto amortigua la prensa amiga. Es la media de las relaciones, convertida
## en un factor: con toda la prensa a favor, la funa pesa un 30% menos.
func amortiguador_prensa() -> float:
	if relaciones.is_empty():
		return 1.0
	var s := 0
	var n := 0
	for f: Array in PERIODISTAS:
		s += relacion_con(String(f[0]))
		n += 1
	if n == 0:
		return 1.0
	var media := float(s) / float(n)
	var f := 1.3 - media / 100.0 * 0.6
	## LA SALA DE PRENSA DEL CLUB TAMBIEN AMORTIGUA. `Instalaciones.imagen_en_prensa()`
	## devolvia el nivel de la sala y no lo leia nadie: se podia subir la obra al
	## cinco y el ruido pegaba exactamente igual. Un 4% por nivel.
	var m := _mundo()
	if m != null and m.obras != null:
		f -= float(m.obras.imagen_en_prensa()) * 0.04
	return clampf(f, 0.55, 1.3)

func tiene_medio(clave: String) -> bool:
	return medios.has(clave)

func comprar_medio(clave: String, c: Club) -> String:
	if tiene_medio(clave):
		return "ya lo tienes"
	for f: Array in MEDIOS_PROPIOS:
		if String(f[0]) != clave:
			continue
		var coste := Eco.escalar(float(f[2]), float(c.rep))
		if c.saldo < coste:
			return "cuesta %s y no hay caja" % Cesiones.dinero(coste)
		c.mover_saldo(-coste)
		medios[clave] = true
		return ""
	return "ese medio no existe"

## Lo que rentan los medios propios cada mes.
func renta_medios(c: Club) -> int:
	var n := 0
	for f: Array in MEDIOS_PROPIOS:
		if tiene_medio(String(f[0])):
			n += Eco.escalar(float(f[3]), float(c.rep))
	return n
