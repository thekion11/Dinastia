class_name PrensaContexto
extends RefCounted
## LA RUEDA DE PRENSA QUE LEE EL MOMENTO (26-10-2026, sesión 5). Antes, tras cada partido había UNA
## pregunta sacada de tres barajas (ganaste, empataste, perdiste): daba igual que llevaras cinco
## derrotas seguidas, que acabaras de fichar a una estrella o que el domingo viniera el líder. Ahora,
## detrás de la pregunta de siempre pueden venir hasta tres más, sacadas de lo que pasa de verdad:
##   - EL PORQUÉ del partido que se acaba de jugar (`Partido.ultimas_causas`, de `CausasPartido`): la
##     causa que más pesó se convierte en la pregunta («el rival os encerró entre el 60' y el 75'…»).
##   - LA RACHA: tres o más resultados iguales seguidos en la liga.
##   - EL ÚLTIMO FICHAJE, si llegó alguno desde la última rueda.
##   - EL PRÓXIMO RIVAL, si es el clásico o uno de los tres primeros.
## Cuántas: depende de lo que haya en juego (clásico, goleada, racha fuerte, crisis); un martes
## tranquilo puede quedarse en una sola. Y se puede DELEGAR la rueda en el ayudante (una opción más en la
## primera pregunta): no te desgastas, pero la sala lo anota, la directiva también y tu fama mediática
## baja.
##
## Nada de esto usa `Azar` (los sorteos van por hash de la fecha): la rueda no cambia el resto de la
## partida. Los textos van con `Idiomas.t`, como el resto de la interfaz.

const MAX_EXTRA := 3
## Lo que cuesta mandar al ayudante: relación con cada periodista, confianza de la directiva y
## reputación mediática.
const DELEGAR_RELACION := -2
const DELEGAR_CONFIANZA := -1
const DELEGAR_REPUTACION := -2

## Las preguntas que van detrás de la de siempre (0 a `MAX_EXTRA`), ya con sus opciones.
static func preguntas_extra(prensa: RefCounted, m: Mundo, mio: Club, gane: bool, empate: bool, h: int) -> Array:
	if m == null or mio == null:
		return []
	var cand: Array = []
	var por := _del_porque(m, gane, empate)
	if not por.is_empty():
		cand.append(por)
	var racha := racha_de(m, mio)
	var rq := _de_racha(racha)
	if not rq.is_empty():
		cand.append(rq)
	var fq := _del_fichaje(prensa, m)
	if not fq.is_empty():
		cand.append(fq)
	var proximo := _rival_siguiente(m, mio)
	var pq := _del_rival(m, mio, proximo)
	if not pq.is_empty():
		cand.append(pq)
	return cand.slice(0, cuantas(cand.size(), racha, _hay_mucho_en_juego(m, mio, proximo), h))

## Cuántas preguntas extra: una de base si hay de qué hablar, una más si hay mucho en juego, otra si
## la racha es larga; y uno de cada tres días tranquilos, ninguna (la rueda corta también existe).
static func cuantas(disponibles: int, racha: Array, en_juego: bool, h: int) -> int:
	if disponibles == 0:
		return 0
	var n := 1 + (1 if en_juego else 0) + (1 if absi(racha_larga(racha)) >= 4 else 0)
	if not en_juego and absi(racha_larga(racha)) < 3 and h % 3 == 0:
		n = 0
	return mini(mini(n, disponibles), MAX_EXTRA)

## Los últimos resultados de tu club en la liga, del más viejo al más nuevo ("V", "E", "D").
static func racha_de(m: Mundo, mio: Club) -> Array:
	var liga := m.liga_de(mio)
	var r: Array = []
	if liga == null:
		return r
	for jornada: Array in liga.historial:
		for x: Dictionary in jornada:
			var es_l: bool = x["local"] == mio
			if not es_l and x["visita"] != mio:
				continue
			var a := int(x["gl"] if es_l else x["gv"])
			var b := int(x["gv"] if es_l else x["gl"])
			r.append("V" if a > b else ("E" if a == b else "D"))
	return r.slice(maxi(r.size() - 8, 0))

## Cuántos resultados iguales seguidos al final: +n victorias, −n derrotas, 0 si el último fue empate.
static func racha_larga(r: Array) -> int:
	if r.is_empty() or String(r[r.size() - 1]) == "E":
		return 0
	var ultimo := String(r[r.size() - 1])
	var n := 0
	for i in range(r.size() - 1, -1, -1):
		if String(r[i]) != ultimo:
			break
		n += 1
	return n if ultimo == "V" else -n

static func _hay_mucho_en_juego(m: Mundo, mio: Club, proximo: Club) -> bool:
	var u: Dictionary = Partido.ultimo_mio
	var goleada := not u.is_empty() and absi(int(u.get("gl", 0)) - int(u.get("gv", 0))) >= 3
	return goleada or (proximo != null and m.es_clasico(mio, proximo)) or (m.directiva != null and m.directiva.confianza < 35)

static func _rival_siguiente(m: Mundo, mio: Club) -> Club:
	var par := m.proximo_partido()
	if par.size() != 2:
		return null
	var otro: Club = par[1] if par[0] == mio else par[0]
	## Si la jornada todavía no avanzó, el «próximo» es el que se acaba de jugar: ese no.
	var u: Dictionary = Partido.ultimo_mio
	if not u.is_empty() and (otro.nombre == String(u.get("local", "")) or otro.nombre == String(u.get("visita", ""))):
		return null
	return otro

static func _op(txt: String, moral: int, conf: int, socios: int, tono: String) -> Dictionary:
	return {"txt": txt, "moral": moral, "confianza": conf, "socios": socios, "tono": tono}

## EL PORQUÉ: la causa que más pesó en el partido de esta semana, hecha pregunta.
static func _del_porque(m: Mundo, gane: bool, empate: bool) -> Dictionary:
	var u: Dictionary = Partido.ultimas_causas
	if u.is_empty() or int(u.get("anio", -1)) != m.anio or int(u.get("semana", -1)) != m.semana:
		return {}
	for c: Dictionary in u.get("causas", []):
		var clave := String(c["clave"])
		var s := int(c["signo"])
		var q := ""
		var ops: Array = []
		match clave:
			"momentum":
				if s < 0:
					q = Idiomas.t("Hubo un tramo en que el rival les encerró en su área. ¿Qué falló ahí?")
					ops = [_op(Idiomas.t("Nos faltó salir con el balón; lo vamos a trabajar"), 1, 1, 0, "calma"),
						_op(Idiomas.t("Ningún equipo domina noventa minutos"), 0, 0, 0, "evasiva"),
						_op(Idiomas.t("Encerrados no: les dejamos venir a propósito"), 1, -1, 0, "soberbia")]
				elif s > 0:
					q = Idiomas.t("En su mejor tramo pasaron por encima del rival. ¿Fue cosa de la pizarra?")
					ops = [_op(Idiomas.t("Del trabajo de toda la semana; el mérito es de ellos"), 2, 0, 1, "calma"),
						_op(Idiomas.t("Cuando apretamos así, no hay quien nos pare"), 1, 1, 0, "soberbia"),
						_op(Idiomas.t("Prefiero no desvelar lo que hablamos"), 0, 0, 0, "evasiva")]
			"forma", "cansancio":
				if s < 0:
					q = Idiomas.t("Su equipo llegó con menos piernas que el rival. ¿Está fallando la preparación física?")
					ops = [_op(Idiomas.t("El calendario aprieta; vamos a rotar más"), 1, 0, 0, "calma"),
						_op(Idiomas.t("Eso es una excusa y aquí no ponemos excusas"), 0, 1, 0, "soberbia"),
						_op(Idiomas.t("Eso pregúnteselo al preparador físico"), -1, -1, 0, "evasiva")]
			"plantilla":
				if s > 0 and not gane:
					q = Idiomas.t("Sobre el papel eran mejores y no ganaron. ¿Qué pasó?")
					ops = [_op(Idiomas.t("El papel no juega; hoy no estuvimos a la altura"), 1, 1, 1, "calma"),
						_op(Idiomas.t("Somos mejores, y se va a ver muy pronto"), 0, -1, 0, "soberbia"),
						_op(Idiomas.t("No voy a hacer comparaciones"), 0, 0, -1, "evasiva")]
				elif s < 0 and gane:
					q = Idiomas.t("Ganaron a un once mejor que el suyo sobre el papel. ¿Es su mejor partido?")
					ops = [_op(Idiomas.t("Es el partido de un grupo que cree en lo que hace"), 2, 1, 1, "calma"),
						_op(Idiomas.t("Lo del papel lo dicen ustedes, no yo"), 1, 0, 0, "soberbia"),
						_op(Idiomas.t("Ya pensamos en el siguiente"), 0, 0, 0, "evasiva")]
			"arbitro":
				if s < 0:
					q = Idiomas.t("El arbitraje les perjudicó. ¿Qué opina del colegiado?")
					ops = [_op(Idiomas.t("No voy a hablar del árbitro: hablo de lo nuestro"), 0, 1, 1, "calma"),
						_op(Idiomas.t("Hoy no nos dejaron jugar, y lo saben todos"), 1, 0, 1, "soberbia"),
						_op(Idiomas.t("Que lo valore el comité"), 0, 0, 0, "evasiva")]
			"eficacia":
				if s < 0:
					q = Idiomas.t("Generaron más que el rival y el marcador no lo dice. ¿Falta un delantero?")
					ops = [_op(Idiomas.t("Llegamos; el gol va a venir"), 1, 0, 0, "calma"),
						_op(Idiomas.t("Tengo los delanteros que quiero"), 1, -1, 0, "soberbia"),
						_op(Idiomas.t("El mercado no es un tema para hoy"), 0, 0, -1, "evasiva")]
				elif s > 0:
					q = Idiomas.t("Fueron letales de cara a puerta. ¿Mérito o suerte?")
					ops = [_op(Idiomas.t("Se entrena: la definición también se trabaja"), 1, 1, 0, "calma"),
						_op(Idiomas.t("La suerte hay que buscarla"), 1, 0, 0, "soberbia"),
						_op(Idiomas.t("Lo importante son los tres puntos"), 0, 0, 0, "evasiva")]
			"tactica":
				if s < 0:
					q = Idiomas.t("El planteamiento del rival les cambió el partido. ¿Le ganaron la partida en la pizarra?")
					ops = [_op(Idiomas.t("Nos costó leerlo; tomamos nota"), 0, 1, 0, "calma"),
						_op(Idiomas.t("A mí no me gana nadie la pizarra"), 0, -1, 0, "soberbia"),
						_op(Idiomas.t("No voy a explicar la táctica aquí"), 0, 0, 0, "evasiva")]
			"lesion":
				q = Idiomas.t("La lesión les condicionó el partido. ¿Cómo está el jugador?")
				ops = [_op(Idiomas.t("Esperamos las pruebas; el grupo está con él"), 1, 0, 1, "calma"),
					_op(Idiomas.t("No vamos a llorar: hay plantel"), 0, 1, 0, "soberbia"),
					_op(Idiomas.t("El parte médico lo dará el club"), 0, 0, 0, "evasiva")]
		if q != "":
			return {"pregunta": "'%s'" % q, "opciones": ops, "tema": "porque", "causa": clave}
	return {}

static func _de_racha(r: Array) -> Dictionary:
	var n := racha_larga(r)
	if n >= 3:
		return {"pregunta": "'%s'" % (Idiomas.t("Llevan %d victorias seguidas. ¿Hasta dónde puede llegar este equipo?") % n), "tema": "racha", "opciones": [
			_op(Idiomas.t("Partido a partido; no miramos más allá del domingo"), 1, 1, 0, "calma"),
			_op(Idiomas.t("Hasta lo más alto, y que nadie lo dude"), 2, 0, 2, "soberbia"),
			_op(Idiomas.t("Las rachas no me interesan"), 0, 0, -1, "evasiva")]}
	if n <= -3:
		return {"pregunta": "'%s'" % (Idiomas.t("Llevan %d derrotas seguidas. ¿Se siente con fuerzas para darle la vuelta?") % -n), "tema": "racha", "opciones": [
			_op(Idiomas.t("Sí: el grupo está unido y saldremos juntos"), 1, 1, 1, "calma"),
			_op(Idiomas.t("Mi continuidad no está en discusión"), 0, -1, -1, "soberbia"),
			_op(Idiomas.t("Eso lo decidirá la directiva"), -1, -2, -1, "evasiva")]}
	return {}

static func _del_fichaje(prensa: RefCounted, m: Mundo) -> Dictionary:
	if m.mercado == null:
		return {}
	var entran: Array = []
	for f: Dictionary in m.mercado.fichajes_temporada:
		if bool(f.get("entra", false)):
			entran.append(f)
	var vistos := int(prensa.get("fichajes_preguntados"))
	if entran.size() <= vistos:
		return {}
	prensa.set("fichajes_preguntados", entran.size())
	var f: Dictionary = entran[entran.size() - 1]
	var nom := Nombres.visible(String(f["nombre"]))
	return {"pregunta": "'%s'" % (Idiomas.t("Ha llegado %s. ¿Qué espera de él y cuándo lo veremos de titular?") % nom), "tema": "fichaje", "opciones": [
		_op(Idiomas.t("Que se adapte sin prisa; tendrá sus minutos"), 1, 0, 0, "calma"),
		_op(Idiomas.t("Es lo que nos faltaba: va a marcar diferencias"), 1, 1, 1, "soberbia"),
		_op(Idiomas.t("No hablo de jugadores en concreto"), 0, 0, 0, "evasiva")]}

static func _del_rival(m: Mundo, mio: Club, otro: Club) -> Dictionary:
	if otro == null:
		return {}
	var clasico := m.es_clasico(mio, otro)
	var puesto := 0
	var liga := m.liga_de(otro)
	if liga != null:
		var t := liga.tabla()
		for i in t.size():
			if t[i]["club"] == otro:
				puesto = i + 1
	if not clasico and (puesto == 0 or puesto > 3):
		return {}
	var nom := Nombres.visible(otro.nombre)
	var q := Idiomas.t("Ahora viene el clásico contra %s. ¿Cómo se prepara un partido así?") % nom if clasico \
		else Idiomas.t("El próximo rival es %s, %dº en la tabla. ¿Le preocupa?") % [nom, puesto]
	return {"pregunta": "'%s'" % q, "tema": "rival", "opciones": [
		_op(Idiomas.t("Con respeto y con la idea clara"), 1, 1, 0, "calma"),
		_op(Idiomas.t("Que se preocupen ellos"), 2, 0, 1, "soberbia"),
		_op(Idiomas.t("Hoy toca hablar de este partido"), 0, 0, 0, "evasiva")]}

## La opción de mandar al ayudante: va como una respuesta más de la primera pregunta (la pantalla ya
## pinta todas las opciones que haya, sin cambios).
static func opcion_delegar() -> Dictionary:
	return {"txt": Idiomas.t("🙋 Que responda mi ayudante"), "moral": 0, "confianza": DELEGAR_CONFIANZA, "socios": 0, "tono": "delegar"}

# ---------------------------------------------------------------------------
#  LA PREVIA (26-10-2026): la rueda ANTES del partido
# ---------------------------------------------------------------------------
# El plató ya sabía pintar una previa (`ParedPrensa`, tipo "previa", con los dos escudos) pero el juego
# nunca abría una rueda antes de jugar. Se abre al cerrar la semana, para el partido que viene, si no hubo
# rueda tras el resultado y el partido lo merece: el clásico, un rival de arriba, una racha larga o muchas
# bajas (y uno de cada tres días tranquilos). Es corta -una o dos preguntas- y se puede delegar.

## ¿Toca previa para el partido contra `rival`? `h`: hash de la fecha (sin `Azar`).
static func toca_previa(m: Mundo, mio: Club, rival: Club, h: int) -> bool:
	if rival == null:
		return false
	if m.es_clasico(mio, rival) or _puesto(m, rival) in [1, 2, 3] or absi(racha_larga(racha_de(m, mio))) >= 3 or bajas(mio) >= 3:
		return true
	return h % 3 == 0

static func bajas(c: Club) -> int:
	var n := 0
	for j: Jugador in c.plantilla:
		if not j.disponible():
			n += 1
	return n

static func _puesto(m: Mundo, c: Club) -> int:
	var liga := m.liga_de(c)
	if liga == null:
		return 0
	var t := liga.tabla()
	for i in t.size():
		if t[i]["club"] == c:
			return i + 1
	return 0

## Las preguntas de la previa: la del rival y, detrás, la racha o las bajas (una como mucho).
static func preguntas_previa(m: Mundo, mio: Club, rival: Club) -> Array:
	var r: Array = []
	var nom := Nombres.visible(rival.nombre)
	var puesto := _puesto(m, rival)
	var q := ""
	if m.es_clasico(mio, rival):
		q = Idiomas.t("Se viene el clásico contra %s. ¿Cómo está el vestuario?") % nom
	elif puesto > 0:
		q = Idiomas.t("El próximo partido es contra %s, %dº en la tabla. ¿Qué partido espera?") % [nom, puesto]
	else:
		q = Idiomas.t("El próximo partido es contra %s. ¿Qué partido espera?") % nom
	r.append({"pregunta": "'%s'" % q, "tema": "previa_rival", "opciones": [
		_op(Idiomas.t("Un rival exigente: lo hemos preparado a conciencia"), 1, 1, 0, "calma"),
		_op(Idiomas.t("Vamos a ganar, y en su casa o en la nuestra da igual"), 2, 0, 2, "soberbia"),
		_op(Idiomas.t("Lo que tenga que decir se lo diré a mis jugadores"), 0, 0, -1, "evasiva")]})
	var n_bajas := bajas(mio)
	var rq := _de_racha(racha_de(m, mio))
	if not rq.is_empty():
		rq["tema"] = "previa_racha"
		r.append(rq)
	elif n_bajas >= 3:
		r.append({"pregunta": "'%s'" % (Idiomas.t("Llegan con %d bajas. ¿Le preocupa cómo formar el once?") % n_bajas), "tema": "previa_bajas", "opciones": [
			_op(Idiomas.t("Confío en los que entren: para eso están"), 2, 0, 0, "calma"),
			_op(Idiomas.t("Con los que haya, ganamos igual"), 1, 0, 1, "soberbia"),
			_op(Idiomas.t("No voy a dar pistas del once"), 0, 0, 0, "evasiva")]})
	return r
