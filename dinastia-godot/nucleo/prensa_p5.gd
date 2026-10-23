extends "res://nucleo/prensa_p4.gd"
## (Parte 5 de 7 de `prensa.gd`.)

func _pregunta_identidad(que: String) -> Dictionary:
	return {"pregunta": "Prensa: 'El club estrena %s. Hay hinchas molestos: ¿por qué tocar algo tan sagrado?'" % que, "opciones": [
		{"txt": "Respetamos la historia; esto la pone al día", "moral": 0, "confianza": 1, "socios": 1, "tono": "calma"},
		{"txt": "El que no lo entienda, ya lo entenderá", "moral": 0, "confianza": 1, "socios": -2, "tono": "soberbia"},
		{"txt": "Eso es cosa del departamento de marketing", "moral": 0, "confianza": -1, "socios": -1, "tono": "evasiva"},
	]}

func _hash_de(clave: String) -> int:
	var h := 2166136261
	for i in clave.length():
		h = (h * 31 + clave.unicode_at(i)) & 0x7FFFFFFF
	return h

func _fecha() -> int:
	var m := _mundo()
	return (m.anio * 100 + m.semana) if m != null else 0

func _pregunta_clima(info: Dictionary, gane: bool, empate: bool) -> Dictionary:
	var que := String(info.get("texto", "el tiempo")).to_lower()
	var q := "Prensa: '¿Cuánto influyó el tiempo (%s) en el resultado?'" % que
	if gane:
		q = "Prensa: 'Con %s, ¿fue un triunfo de carácter más que de fútbol?'" % que
		## Tras ganar, quejarse del tiempo no tiene sentido: otras respuestas.
		return {"pregunta": q, "opciones": [
			{"txt": "De las dos cosas: el equipo supo sufrir", "moral": 1, "confianza": 1, "socios": 1, "tono": "calma"},
			{"txt": "Jugamos bien con sol, lluvia o lo que sea", "moral": 1, "confianza": 0, "socios": 0, "tono": "soberbia"},
			{"txt": "Prefiero hablar del partido", "moral": 0, "confianza": 0, "socios": -1, "tono": "evasiva"},
		]}
	return {"pregunta": q, "opciones": [
		{"txt": "Es igual para los dos: no es excusa", "moral": 1, "confianza": 1, "socios": 0, "tono": "calma"},
		{"txt": "Así no se puede jugar al fútbol", "moral": -1 if not gane else 0, "confianza": -1, "socios": 0, "tono": "soberbia"},
		{"txt": "Prefiero hablar del partido", "moral": 0, "confianza": 0, "socios": -1, "tono": "evasiva"},
	]}

func periodista_de(clave: String) -> Array:
	for f: Array in PERIODISTAS:
		if String(f[0]) == clave:
			return f
	return PERIODISTAS[2]

## Quién pregunta hoy. Tras una derrota, uno de cada tres días le toca al
## crítico, que es el que más ganas tiene.
func _poner_periodista(gane: bool, empate: bool) -> void:
	var h := _hash_de("%d|%s" % [_fecha(), String(entrevista.get("pregunta", ""))])
	var f: Array = PERIODISTAS[h % PERIODISTAS.size()]
	if not gane and not empate and h % 3 == 0:
		f = periodista_de("ibarra")
	var clave := String(f[0])
	entrevista["periodista"] = clave
	entrevista["quien"] = "%s · %s" % [String(f[1]), String(f[2])]
	entrevista["perfil"] = String(f[3])
	entrevista["paso"] = 0
	## La pregunta ya no la hace "Prensa": la hace él.
	var q := String(entrevista.get("pregunta", ""))
	if q.begins_with("Prensa: "):
		q = q.substr(8)
	var mem: Dictionary = memoria.get(clave, {})
	if not mem.is_empty() and _fecha() - int(mem.get("fecha", 0)) >= 1:
		if String(mem.get("tono", "")) == "soberbia" and not gane:
			## LA FRASE QUE VUELVE. Lo dijiste subido; hoy toca tragártelo.
			q = "'Hace poco dijo «%s». Hoy no ganaron. ¿Se arrepiente de esa frase?'" % String(mem["frase"])
			entrevista["opciones"] = [
				{"txt": "Me equivoqué en el tono; el trabajo sigue", "moral": 1, "confianza": 1, "socios": 1, "tono": "calma"},
				{"txt": "No vine a hablar del pasado", "moral": -1, "confianza": 0, "socios": -1, "tono": "evasiva"},
				{"txt": "Lo sostengo: al final de la temporada hablamos", "moral": 1, "confianza": -1, "socios": 0, "tono": "soberbia"},
			]
			entrevista["memoria"] = true
		elif String(mem.get("tono", "")) == "evasiva":
			q = "'La última vez no me contestó; a ver hoy. %s" % q.trim_prefix("'")
			entrevista["memoria"] = true
	entrevista["pregunta"] = q

## Abre una rueda con el guion que toca. Se puede llamar directa desde una prueba
## o desde un modo sin partido de por medio.
func abrir_rueda(gane: bool, empate: bool) -> Dictionary:
	var guion: Array = _GANE if gane else (_EMPATE if empate else _PERDI)
	entrevista = (Azar.uno(guion) as Dictionary).duplicate(true)
	cuerpo = CUERPO_POR_DEFECTO
	## LO QUE ES NOTICIA MANDA sobre la pregunta de siempre (C1): si cambiaste
	## el escudo o la camiseta, te preguntan por eso; si se jugó con temporal,
	## calor o altura, por el tiempo. El sorteo de arriba se hace igual, así
	## que el consumo de `Azar` no cambia.
	if cambio_identidad != "":
		entrevista = _pregunta_identidad(cambio_identidad)
		cambio_identidad = ""
	elif Clima.es_extremo(clima_ultimo) and _hash_de(str(_fecha()) + "clima") % 2 == 0:
		entrevista = _pregunta_clima(clima_ultimo, gane, empate)
	_poner_periodista(gane, empate)
	rueda_abierta.emit(String(entrevista["pregunta"]), entrevista["opciones"])
	return entrevista


# ===========================================================================
#  LA RUEDA DE PRENSA
# ===========================================================================

## Después de TU partido, la mitad de las veces te espera el micrófono.
##
## `penales` es la tanda, si la hubo, en el orden [local, visita]: sin ella una
## eliminatoria ganada desde los once metros se leería como un empate y te
## preguntarían por la falta de gol después de pasar de ronda.
func sortear_rueda(p: Partido, penales: Array = []) -> Dictionary:
	var m := _mundo()
	if m == null or p == null:
		return {}
	## Se tira el dado ANTES de mirar si ya hay entrevista abierta, igual que en
	## el HTML: mantiene el consumo de azar idéntico jornada a jornada.
	var toca := Azar.suerte(0.5)
	if not toca or not entrevista.is_empty():
		return {}
	var mio := m.mi_club()
	if mio == null or (p.local != mio and p.visita != mio):
		return {}

	var soy_local := p.local == mio
	var gf := p.goles_local if soy_local else p.goles_visita
	var gc := p.goles_visita if soy_local else p.goles_local
	var hubo_penales := penales.size() >= 2
	var pf := int(penales[0]) if hubo_penales else 0
	var pc := int(penales[1]) if hubo_penales else 0
	if hubo_penales and not soy_local:
		var t := pf
		pf = pc
		pc = t

	var gane := gf > gc or (hubo_penales and pf > pc)
	var empate := gf == gc and not hubo_penales
	return abrir_rueda(gane, empate)

func hay_rueda() -> bool:
	return not entrevista.is_empty()

## Elige el lenguaje corporal antes de responder. Devuelve la descripción de esa
## postura para poder enseñarla en pantalla.
func fijar_cuerpo(k: String) -> String:
	var t: Dictionary = Datos.tabla("CUERPOS")
	if t == null or not t.has(k):
		return ""
	cuerpo = k
	return String(t[k][2])

## Las cinco posturas, tal como las pinta la interfaz: clave -> [emoji, nombre,
## descripción].
func cuerpos() -> Dictionary:
	var t: Dictionary = Datos.tabla("CUERPOS")
	return t if t != null else {}

## Cómo lo dijiste, sumado a lo que dijiste.
##
## Cada postura tiene su moneda de cambio y ninguna es gratis: el firme es sólido
## pero anodino, el cercano compra hinchada a costa de no decir nada, el soberbio
## te hace grande ante la directiva y te pone a los árbitros en contra, y el
## dubitativo es un desastre completo. El seco es la salida para cuando no hay
## nada bueno que decir.
func _aplicar_cuerpo(dm: int, dc: int, ds: int) -> Dictionary:
	var texto := ""
	match cuerpo:
		"firme":
			dc += 1
			dm += 1
			texto = " Te viste sólido."
		"dubitativo":
			dc -= 3
			dm -= 1
			_mover_funa(Azar.ent(4, 10))
			texto = " Titubeaste al responder y la prensa lo notó: mañana te preguntan por tu continuidad."
		"soberbio":
			dc += 2
			ds += 1
			enojo_arbitral += 1
			texto = " Sonaste soberbio: el estamento arbitral tomó nota para el próximo partido."
		"cercano":
			dm += 2
			ds += 1
			_mover_funa(-Azar.ent(2, 6))
			texto = " Caíste bien: la hinchada agradece el tono."
		"seco":
			dc -= 1
			dm += 1
			texto = " Corto y sin regalar titulares."
	return {"moral": dm, "confianza": dc, "socios": ds, "texto": texto}

func relacion_con(clave: String) -> int:
	return int(relaciones.get(clave, 50))

func _mover_relacion(clave: String, d: int) -> void:
	if clave == "":
		return
	relaciones[clave] = clampi(relacion_con(clave) + d, 0, 100)

## El tono, aparte de las cifras de la opción. Mueve la relación con quien
## pregunta, y la soberbia la apunta el estamento arbitral.
func _aplicar_tono(tono: String, titubeo: bool) -> Dictionary:
	var per := String(entrevista.get("periodista", ""))
	var perfil := String(entrevista.get("perfil", ""))
	var dm := 0
	var dc := 0
	var texto := ""
	match tono:
		"calma":
			_mover_relacion(per, 2)
			funa = maxi(0, funa - 1)
		"soberbia":
			## El cuerpo "soberbio" ya lo apunta en `_aplicar_cuerpo`: dos veces
			## por la misma frase sería cobrarla doble.
			if cuerpo != "soberbio":
				enojo_arbitral += 1
			_mover_relacion(per, 3 if perfil == "sensacionalista" else -3)
			dm += 1
			texto = " La frase se va a repetir toda la semana."
		"evasiva":
			_mover_relacion(per, -2)
			_mover_funa(1)
			texto = " No contestaste, y eso también es una respuesta."
	if titubeo:
		dc -= 1
		_mover_funa(2)
		texto += " Tardaste en contestar: en la sala se notó."
	return {"moral": dm, "confianza": dc, "texto": texto}

func _recordar(clave: String, frase: String, tono: String) -> void:
	if clave == "":
		return
	memoria[clave] = {"frase": frase.substr(0, 90), "tono": tono, "fecha": _fecha()}

## Repregunta si dejaste la puerta abierta. Con portavoz no: él cierra el tema.
func _toca_repreguntar(clave: String, tono: String, titubeo: bool) -> bool:
	if clave == "" or not vocero.is_empty():
		return false
	var perfil := String(periodista_de(clave)[3])
	return titubeo or tono == "evasiva" or (tono == "soberbia" and perfil in ["crítico", "sensacionalista"])

func _repregunta(clave: String, frase: String, tono: String, titubeo: bool) -> Dictionary:
	var f := periodista_de(clave)
	var q := ""
	var ops: Array = []
	if titubeo:
		q = "'Se ha tomado su tiempo para contestar. ¿Duda usted de su propio proyecto?'"
		ops = [
			{"txt": "No dudo: hay un plan y el plantel lo conoce", "moral": 1, "confianza": 2, "socios": 0, "tono": "calma"},
			{"txt": "No voy a entrar en eso", "moral": 0, "confianza": -2, "socios": -1, "tono": "evasiva"},
			{"txt": "Dudar es cosa de ustedes", "moral": 1, "confianza": -1, "socios": 0, "tono": "soberbia"},
		]
	elif tono == "evasiva":
		q = "'Con todo respeto, eso no es una respuesta. Se lo pregunto otra vez.'"
		ops = [
			{"txt": "Tiene razón: se lo digo claro, confío en este grupo", "moral": 1, "confianza": 1, "socios": 1, "tono": "calma"},
			{"txt": "Ya respondí. Siguiente pregunta", "moral": -1, "confianza": -1, "socios": -1, "tono": "evasiva"},
			{"txt": "Las respuestas las doy en la cancha", "moral": 2, "confianza": 0, "socios": 0, "tono": "soberbia"},
		]
	else:
		q = "'«%s». ¿No teme que esa frase se le vuelva en contra?'" % frase
		ops = [
			{"txt": "Lo matizo: hablo de ambición, no de desprecio", "moral": 0, "confianza": 1, "socios": 1, "tono": "calma"},
			{"txt": "No tengo nada más que añadir", "moral": 0, "confianza": -1, "socios": -1, "tono": "evasiva"},
			{"txt": "Lo digo y lo sostengo", "moral": 2, "confianza": 0, "socios": 1, "tono": "soberbia"},
		]
	return {"pregunta": q, "opciones": ops, "periodista": clave, "perfil": String(f[3]),
		"quien": "%s · %s (repregunta)" % [String(f[1]), String(f[2])], "paso": 1}

## La portada de mañana, escrita a la manera de quien preguntó.
func _preparar_titular(clave: String, frase: String, tono: String) -> void:
	if clave == "":
		return
	var f := periodista_de(clave)
	var perfil := String(f[3])
	var cita := "«%s»" % frase.substr(0, 70)
	var t := ""
	match perfil:
		"sensacionalista":
			t = {"soberbia": "%s: el DT enciende la polémica" % cita, "evasiva": "El DT esquiva y la sala se queda con las ganas"}.get(tono, "%s, la frase del día" % cita)
		"crítico":
			t = {"soberbia": "Soberbia en la sala: %s" % cita, "evasiva": "Sin respuestas: el DT se escondió tras el micrófono"}.get(tono, "%s. Palabras; faltan hechos" % cita)
		"aliado":
			t = {"soberbia": "Un DT con carácter: %s" % cita, "evasiva": "El DT prefirió la prudencia"}.get(tono, "%s: el DT pone la cara" % cita)
		"táctico":
			t = "%s: lo que hay detrás de la idea del DT" % cita
		_:
			t = "El DT: %s" % cita
	var tipo: String = {"calma": "bien", "soberbia": "neutro", "evasiva": "mal"}.get(tono, "neutro")
	titular_pendiente = {"t": t, "c": "Lo firma %s en %s." % [String(f[1]), String(f[2])], "tipo": tipo, "medio": String(f[2])}

## Responde la pregunta `i`. Devuelve el resumen de lo que movió, o vacío si no
## había rueda abierta.
##
## Los tres efectos van a sitios distintos y por eso una respuesta nunca es
## redonda: la moral la cobra el plantel, la confianza la directiva y los socios
## la taquilla del mes que viene. Quedar bien con el vestuario puede costarte el
## despacho.
##
## `segundos` (B5): lo que tardaste en contestar, medido por la pantalla. Más de
## `TITUBEO_SEG` y la sala lo nota -"los periodistas huelen sangre"-. Con -1 (las
## pruebas, o quien no mida) no cuenta.
##
## Si la respuesta deja la puerta abierta -evasiva, titubeo, o soberbia ante
## quien vive del titular-, el MISMO periodista repregunta: la rueda sigue
## abierta con la repregunta en `entrevista` y el resultado trae "sigue": true.
func responder(i: int, segundos: float = -1.0) -> Dictionary:
	if entrevista.is_empty():
		return {}
	var opciones: Array = entrevista["opciones"]
	if i < 0 or i >= opciones.size():
		return {}
	var m := _mundo()
	var mio: Club = m.mi_club() if m != null else null
	var o: Dictionary = opciones[i]

	var d_moral := int(o["moral"])
	var d_conf := int(o["confianza"])
	var d_socios := int(o["socios"])
	var extra := _aplicar_cuerpo(d_moral, d_conf, d_socios)
	d_moral = int(extra["moral"])
	d_conf = int(extra["confianza"])
	d_socios = int(extra["socios"])
	var tono := String(o.get("tono", "calma"))
	var titubeo := segundos >= TITUBEO_SEG
	var de_tono := _aplicar_tono(tono, titubeo)
	d_moral += int(de_tono["moral"])
	d_conf += int(de_tono["confianza"])
	extra["texto"] = String(extra["texto"]) + String(de_tono["texto"])

	## EL VOCERO AMORTIGUA. Si habla otro por ti, la rueda deja de ser tuya: ni
	## te luces ni te hundes. Es la contrapartida que el HTML prometia en el
	## texto del boton y no cobraba en ninguna cuenta.
	## EL DESGASTE DEL ENTRENADOR. Con la cabeza fundida lo que dices sale peor,
	## y esa es la unica consecuencia de quemarse: no te echa nadie, trabajas peor.
	if m != null and m.roles != null and m.roles.quemado():
		var f_des := m.roles.factor_desgaste()
		d_moral = int(round(float(d_moral) * f_des))
		d_conf = int(round(float(d_conf) * f_des))
	if not vocero.is_empty():
		d_moral = int(round(float(d_moral) * AMORTIGUA_VOCERO))
		d_conf = int(round(float(d_conf) * AMORTIGUA_VOCERO))
		d_socios = int(round(float(d_socios) * AMORTIGUA_VOCERO))

	if mio != null:
		for j in mio.plantilla:
			j.cambiar_moral(d_moral, "Prensa y declaraciones")
		## Los socios se mueven en PORCENTAJE, no en número: una declaración
		## afortunada le suma más gente a un club grande que a uno chico, que es
		## lo que corresponde. El suelo de 500 impide que una mala racha deje al
		## club literalmente sin masa social.
		mio.socios = clampi(int(round(float(mio.socios) * (1.0 + float(d_socios) / 100.0))), 500, 300000)
	if m != null and m.directiva != null and d_conf != 0:
		m.directiva.mover_confianza(d_conf, "rueda de prensa")

	var titular := String(o["txt"])
	## Quien da la cara. Con vocero el titular no lleva tu nombre, y esa es
	## justo la otra mitad del trato: menos desgaste, menos control.
	var quien := "🎙 Rueda de prensa"
	if not vocero.is_empty():
		quien = "🎙 Rueda de prensa · habla %s" % String(vocero.get("nombre", ""))
	var per := String(entrevista.get("periodista", ""))
	var paso := int(entrevista.get("paso", 0))
	_recordar(per, titular, tono)
	var sigue := paso == 0 and _toca_repreguntar(per, tono, titubeo)
	if sigue:
		entrevista = _repregunta(per, titular, tono, titubeo)
	else:
		_preparar_titular(per, titular, tono)
		entrevista = {}
		cuerpo = CUERPO_POR_DEFECTO
	noticia.emit(quien, "«%s».%s" % [titular, String(extra["texto"])])
	rueda_respondida.emit(titular, d_moral, d_conf, d_socios)
	return {"titular": titular, "moral": d_moral, "confianza": d_conf,
		"socios": d_socios, "extra": String(extra["texto"]), "tono": tono,
		"titubeo": titubeo, "sigue": sigue}

static func firma_identidad(c: Club) -> Dictionary:
	return {
		"esc": "|".join([c.esc_color1, c.esc_color2, c.esc_forma, c.esc_patron, c.esc_simbolo, c.esc_especial]),
		"kit": "|".join([c.kit_color1, c.kit_color2, c.kit_estilo]),
		"col": "|".join([c.color1, c.color2]),
	}

## `extra` (26-9-2026, plan maestro C20): lo que necesita la portada dibujada
## como periódico -"img": "dt" | "escudo" | "pid:<id>" (quién sale en la foto),
## "sub": la bajada, "medio": la cabecera-. Opcional: una portada vieja sin
## estas claves se dibuja igual, con valores por defecto.
func guardar_portada(titulo: String, cuerpo_texto: String, tipo: String, extra: Dictionary = {}) -> void:
	var m := _mundo()
	var d := {
		"t": titulo, "c": cuerpo_texto, "tipo": tipo,
		"anio": m.anio if m != null else 0,
		"semana": m.semana if m != null else 0,
	}
	d.merge(extra)
	portadas.push_front(d)
	while portadas.size() > PORTADAS_MAX:
		portadas.pop_back()

## Cambiar el escudo o la camiseta es de las decisiones más sensibles de un
## club: la gente se lo toma como algo suyo. Se revisa una vez por semana;
## devuelve lo que cambió ("" si nada).
func revisar_identidad(c: Club) -> String:
	if c == null:
		return ""
	var ahora := firma_identidad(c)
	if identidad.is_empty():
		identidad = ahora
		return ""
	var escudo: bool = ahora["esc"] != identidad["esc"] or ahora["col"] != identidad["col"]
	var camiseta: bool = ahora["kit"] != identidad["kit"] or ahora["col"] != identidad["col"]
	identidad = ahora
	if not escudo and not camiseta:
		return ""
	var que := "escudo y camiseta" if escudo and camiseta else ("escudo" if escudo else "camiseta")
	cambio_identidad = que
	## La afición se divide; cuánto, depende del día: un hash, no `Azar`.
	var h := _hash_de("%s|%d|%s" % [c.id, _fecha(), que])
	var d := (h % 11) - 6            ## de -6 a +4: tocar la identidad suele doler
	mover_animo(d)
	var reaccion := "La hinchada lo celebra en redes." if d > 0 else ("Hay división en la grada." if d > -3 else "Buena parte de la hinchada lo rechaza: «con la historia no se juega».")
	var tit := "El club cambia su %s" % que
	guardar_portada(tit.to_upper(), reaccion, "bien" if d > 0 else "mal", {"img": "escudo", "sub": reaccion, "nueva": true})
	noticia.emit("🗞️ " + tit, reaccion)
	mentor_dice.emit("Sobre el nuevo %s" % que,
		"Esto se va a comentar toda la semana. Prepárate: en la próxima rueda de prensa te van a preguntar por el %s, y lo que digas pesa tanto como el cambio." % que)
	return que

func publicar_titular_pendiente() -> String:
	if titular_pendiente.is_empty():
		return ""
	var t := String(titular_pendiente["t"])
	guardar_portada(t, String(titular_pendiente["c"]), String(titular_pendiente["tipo"]),
		{"img": "dt", "medio": String(titular_pendiente.get("medio", "")), "sub": String(titular_pendiente["c"])})
	noticia.emit("🗞️ " + t, String(titular_pendiente["c"]))
	titular_pendiente = {}
	return t
