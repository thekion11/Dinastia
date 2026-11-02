class_name Imprevistos
extends RefCounted
## IMPREVISTOS CON CONTEXTO (26-10-2026, investigación s4, propuesta fila 13).
## Pedido del dueño: *«~40 eventos inesperados con contexto: intoxicación,
## morriña, cambio de dueño, recorte, oferta loca, jugador en la discoteca…»*.
## La queja que se quiere evitar (FC 26) es la falta de contexto: un agente que
## se queja de un jugador que lleva tres meses lesionado. Por eso cada imprevisto
## lleva CONDICIONES (no le pasa a quien no debe) y EFECTOS QUE DURAN semanas.
##
## Convive con `LesionesAbsurdas` (no la sustituye): aquella son lesiones cortas
## y tontas; esto es la vida alrededor del club.
##
## Reglas del proyecto:
##   - A los jugadores REALES (`Jugador.real`) solo les pasan los imprevistos
##     DEPORTIVOS (`dep`): nada de su vida privada, salud fuera del campo, noches
##     ni familia. En los de toda la plantilla, los no deportivos se los saltan.
##   - Política y dinero ficticios (la «hacienda» es la del juego).
##   - Nada de `Azar`: el sorteo sale de un generador sembrado con club y fecha,
##     así que no mueve ningún otro resultado de la partida.

const PROB_SEMANA := 0.12
## Cuántos imprevistos recientes no se repiten (por id).
const MEMORIA := 12

## Títulos de la noticia, por tono.
const TITULOS := {
	"salud": "😷 Imprevisto de salud",
	"vestuario": "🧳 Cosas del vestuario",
	"noche": "🌙 Noche movida",
	"club": "🏢 Noticias de los despachos",
	"mercado": "💸 Mercado",
	"aficion": "📣 La afición",
	"bueno": "🍀 Buena noticia",
}

## Condiciones (`c`): sano · sin_lesion_larga (≤ 2 semanas de baja) · extranjero
## (de otro país que su club) · joven (≤ 21) · veterano (≥ 31) · noche (el toque de
## queda la evita) · moral_baja (< 50) · moral_alta (≥ 75) · bueno (ovr ≥ 68).
## Efectos (`e`): moral, forma, lesion (semanas) al momento; moral_sem, forma_sem
## cada semana durante `sem` [mín, máx]; saldo y saldo_sem en semanas de masa
## salarial; oferta = múltiplo del valor que ofrece un club rico.
## `a`: "j" (un jugador) o "eq" (toda la plantilla) o "club" (solo dinero).
const CATALOGO := [
	{"id": "intox", "a": "j", "t": "salud", "c": ["sano"], "e": {"lesion": 1, "forma": -8},
		"txt": "%s se intoxicó con un marisco en mal estado y pasó la noche en urgencias"},
	{"id": "morrina", "a": "j", "t": "vestuario", "c": ["extranjero", "sin_lesion_larga"], "e": {"moral_sem": -3}, "sem": [3, 5],
		"txt": "%s tiene morriña: echa de menos su país y su familia"},
	{"id": "discoteca", "a": "j", "t": "noche", "c": ["sano", "noche"], "e": {"forma": -10, "moral": -2},
		"txt": "Fotografían a %s saliendo de una discoteca a las cinco de la mañana"},
	{"id": "gripe", "a": "j", "t": "salud", "c": ["sano"], "e": {"lesion": 1},
		"txt": "Una gripe deja a %s en la cama toda la semana"},
	{"id": "mudanza", "a": "j", "t": "vestuario", "c": ["sin_lesion_larga"], "e": {"forma_sem": -2}, "sem": [2, 3],
		"txt": "%s se muda de casa y anda despistado en los entrenamientos"},
	{"id": "padre", "a": "j", "t": "bueno", "c": ["veterano"], "e": {"moral": 8, "forma": -5},
		"txt": "%s ha sido padre: llega al entrenamiento sin dormir, pero feliz"},
	{"id": "multa", "a": "j", "t": "vestuario", "c": [], "e": {"moral": -3},
		"txt": "Multan a %s por exceso de velocidad con su coche nuevo"},
	{"id": "consola", "a": "j", "t": "bueno", "c": ["joven"], "e": {"moral": 4},
		"txt": "%s gana un torneo benéfico de videojuegos y el vestuario no habla de otra cosa"},
	{"id": "queja", "a": "j", "t": "vestuario", "c": ["moral_baja", "sin_lesion_larga"], "e": {"moral": -4},
		"txt": "%s se queja en una entrevista de sus pocos minutos"},
	{"id": "pelea", "a": "j", "t": "vestuario", "c": ["sano"], "e": {"moral": -5, "moral_eq": -1},
		"txt": "%s y un compañero llegan a las manos en el entrenamiento"},
	{"id": "extra_tiros", "a": "j", "t": "bueno", "c": ["sano"], "e": {"forma_sem": 2}, "sem": [2, 4],
		"txt": "%s se queda cada tarde a practicar tiros libres por su cuenta"},
	{"id": "muela", "a": "j", "t": "salud", "c": ["sano"], "e": {"forma": -6},
		"txt": "A %s le sacan una muela del juicio y juega con la cara hinchada"},
	{"id": "alergia", "a": "j", "t": "salud", "c": ["sin_lesion_larga"], "e": {"forma_sem": -2}, "sem": [2, 3],
		"txt": "La alergia de primavera tiene a %s estornudando todo el día"},
	{"id": "avispa", "a": "j", "t": "salud", "c": ["sano"], "e": {"lesion": 1},
		"txt": "Una avispa pica a %s en un ojo en pleno entrenamiento"},
	{"id": "abuela", "a": "j", "t": "aficion", "c": ["joven"], "e": {"moral": 2},
		"txt": "La abuela de %s llama a la radio para pedir que juegue más"},
	{"id": "tatuaje", "a": "j", "t": "aficion", "c": [], "e": {"moral": 3},
		"txt": "%s se tatúa el escudo del club en la espalda y la grada lo adora"},
	{"id": "restaurante", "a": "j", "t": "vestuario", "c": ["veterano"], "e": {"forma_sem": -1, "moral": 2}, "sem": [3, 5],
		"txt": "%s abre un restaurante y pasa más horas en la cocina que en el gimnasio"},
	{"id": "idioma", "a": "j", "t": "bueno", "c": ["extranjero"], "e": {"moral_sem": 2}, "sem": [2, 3],
		"txt": "%s empieza clases del idioma local y ya bromea con los compañeros"},
	{"id": "botas", "a": "j", "t": "salud", "c": ["sano"], "e": {"forma": -5},
		"txt": "%s estrena botas y acaba la semana lleno de ampollas"},
	{"id": "apuesta", "a": "j", "t": "vestuario", "c": [], "e": {"moral_eq": 1},
		"txt": "%s pierde una apuesta con el capitán y cargará la bolsa de balones un mes"},
	{"id": "cumple", "a": "j", "t": "bueno", "c": [], "e": {"moral": 5},
		"txt": "El vestuario le prepara una fiesta sorpresa de cumpleaños a %s"},
	{"id": "hospital", "a": "j", "t": "bueno", "c": [], "e": {"moral": 4},
		"txt": "%s visita a los niños del hospital y vuelve emocionado"},
	{"id": "atasco", "a": "j", "t": "vestuario", "c": ["sin_lesion_larga"], "e": {"moral": -1},
		"txt": "%s llega tarde al entrenamiento por un atasco monumental y paga la multa interna"},
	{"id": "resfriado", "a": "j", "t": "salud", "c": ["sano"], "e": {"forma": -4},
		"txt": "%s se resfría con la lluvia del último partido"},
	{"id": "fiesta_casa", "a": "j", "t": "noche", "c": ["sano", "noche", "joven"], "e": {"moral": 2, "forma_sem": -2}, "sem": [1, 2],
		"txt": "Los vecinos de %s llaman a la policía por el ruido de una fiesta en su casa"},
	## --- DEPORTIVOS: también les pueden pasar a los jugadores reales ---
	{"id": "viral", "a": "j", "t": "bueno", "dep": true, "c": ["sano"], "e": {"moral": 5},
		"txt": "Un regate de %s en el entrenamiento se hace viral en las redes"},
	{"id": "joven_mes", "a": "j", "t": "bueno", "dep": true, "c": ["joven", "sano"], "e": {"moral": 6},
		"txt": "La liga elige a %s mejor jugador joven del mes"},
	{"id": "sub21", "a": "j", "t": "bueno", "dep": true, "c": ["joven", "sin_lesion_larga"], "e": {"moral": 8},
		"txt": "%s recibe su primera convocatoria con la selección sub-21"},
	{"id": "ojeadores", "a": "j", "t": "mercado", "dep": true, "c": ["bueno", "sano"], "e": {"forma": -4, "moral": 2},
		"txt": "Ojeadores de un grande vienen a ver a %s y anda distraído"},
	{"id": "sobrecarga", "a": "j", "t": "salud", "dep": true, "c": ["sano"], "e": {"lesion": 1},
		"txt": "Los preparadores detectan sobrecarga en %s: mejor que descanse una semana"},
	{"id": "rumor", "a": "j", "t": "mercado", "dep": true, "c": ["bueno"], "e": {"moral": -2},
		"txt": "La prensa coloca a %s en otro club y él tiene que desmentirlo"},
	{"id": "oferta_loca", "a": "j", "t": "mercado", "dep": true, "c": ["bueno", "sin_lesion_larga"], "e": {"oferta": 2.5},
		"txt": "Un club con mucho dinero ofrece una locura por %s: la oferta está en tu despacho"},
	## --- CLUB Y PLANTILLA ---
	{"id": "dueno", "a": "club", "t": "club", "c": [], "e": {"saldo": 4.0, "moral_eq": 1},
		"txt": "El club cambia de dueño: el nuevo propietario promete dinero… y exige resultados"},
	{"id": "recorte", "a": "club", "t": "club", "c": ["saldo_positivo"], "e": {"saldo_sem": -0.15}, "sem": [4, 6],
		"txt": "La junta anuncia un recorte: menos dinero para el día a día durante unas semanas"},
	{"id": "panaderia", "a": "club", "t": "aficion", "c": [], "e": {"saldo_sem": 0.05}, "sem": [4, 8],
		"txt": "Una panadería del barrio patrocina los entrenamientos a cambio de una foto con la plantilla"},
	{"id": "caldera", "a": "eq", "t": "vestuario", "c": [], "e": {"moral_eq": -2},
		"txt": "Se estropea la caldera del vestuario: duchas frías toda la semana"},
	{"id": "hotel", "a": "eq", "t": "salud", "c": [], "e": {"forma_eq": -6},
		"txt": "Media plantilla se intoxica con la cena de un hotel en el último viaje"},
	{"id": "loteria", "a": "eq", "t": "aficion", "c": [], "e": {"moral_eq": 2},
		"txt": "La peña del club gana la lotería e invita a comer a toda la plantilla"},
	{"id": "inspeccion", "a": "club", "t": "club", "c": ["saldo_positivo"], "e": {"saldo": -0.5},
		"txt": "Una inspección de hacienda encuentra papeles mal hechos en las oficinas: multa"},
	{"id": "cesped", "a": "eq", "t": "club", "dep": true, "c": [], "e": {"forma_eq_sem": -1}, "sem": [2, 3],
		"txt": "Un hongo ataca el césped del campo de entrenamiento: toca entrenar en el sintético"},
	{"id": "tele", "a": "club", "t": "bueno", "c": [], "e": {"saldo": 0.8},
		"txt": "Un canal extranjero compra los derechos de los amistosos del club"},
	{"id": "mascota", "a": "eq", "t": "aficion", "dep": true, "c": [], "e": {"moral_eq": 1},
		"txt": "La mascota del club se pierde y aparece en el estadio del rival: risas en todo el país"},
]

## Efectos en marcha: [{id, jid ("" = plantilla/club), q (efecto), v, s (semanas que quedan)}].
var activos: Array = []
## Ids de los últimos imprevistos, para no repetirlos seguidos.
var recientes: Array = []

## Una semana: primero corren los efectos que duran y luego, quizá, uno nuevo.
## Devuelve el imprevisto nuevo ({fila, jugador, texto, semanas}) o vacío.
## `riesgo` (≥ 1): `Necesidades.factor_riesgo()` del DT al cerrar la semana: cansado o con hambre,
## más imprevistos (con la rutina es 1 y todo queda igual que siempre).
func semana(m: Object, c: Club, anio: int, semana_n: int, toque_de_queda: bool, riesgo: float = 1.0) -> Dictionary:
	if c == null:
		return {}
	correr_activos(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(("%s|%d|%d|imprevisto" % [c.id, anio, semana_n]).hash())
	if rng.randf() >= clampf(PROB_SEMANA * riesgo, 0.0, 1.0):
		return {}
	return sortear(m, c, rng, toque_de_queda)

## Elige uno que encaje con el contexto y lo aplica.
func sortear(m: Object, c: Club, rng: RandomNumberGenerator, toque_de_queda: bool) -> Dictionary:
	var posibles: Array = []
	for f: Dictionary in CATALOGO:
		if recientes.has(String(f["id"])):
			continue
		if String(f["a"]) == "j":
			if not _candidatos(f, c, toque_de_queda).is_empty():
				posibles.append(f)
		elif _cumple_club(f, c):
			posibles.append(f)
	if posibles.is_empty():
		return {}
	var fila: Dictionary = posibles[rng.randi() % posibles.size()]
	var j: Jugador = null
	if String(fila["a"]) == "j":
		var cand := _candidatos(fila, c, toque_de_queda)
		j = cand[rng.randi() % cand.size()]
	var sem := 0
	if fila.has("sem"):
		sem = rng.randi_range(int(fila["sem"][0]), int(fila["sem"][1]))
	aplicar(m, c, fila, j, sem)
	recientes.append(String(fila["id"]))
	while recientes.size() > MEMORIA:
		recientes.pop_front()
	var txt := Idiomas.t(String(fila["txt"]))
	if txt.contains("%s"):
		txt = txt % (j.nombre if j != null else c.nombre)
	return {"fila": fila, "jugador": j, "texto": txt, "semanas": sem,
		"titulo": Idiomas.t(String(TITULOS.get(String(fila["t"]), TITULOS["club"])))}

## Los jugadores a los que les puede pasar `f` ahora mismo.
func _candidatos(f: Dictionary, c: Club, toque_de_queda: bool) -> Array[Jugador]:
	var out: Array[Jugador] = []
	var conds: Array = f["c"]
	if toque_de_queda and conds.has("noche"):
		return out
	for j: Jugador in c.plantilla:
		if j.real and not bool(f.get("dep", false)):
			continue
		if _tiene_activo(j.id):
			continue      ## un imprevisto en marcha por jugador: no se apilan
		if _cumple_jugador(conds, j, c):
			out.append(j)
	return out

func _cumple_jugador(conds: Array, j: Jugador, c: Club) -> bool:
	for k: String in conds:
		match k:
			"sano":
				if j.lesion > 0: return false
			"sin_lesion_larga":
				if j.lesion > 2: return false
			"extranjero":
				if j.pais == c.pais: return false
			"joven":
				if j.edad > 21: return false
			"veterano":
				if j.edad < 31: return false
			"moral_baja":
				if j.moral >= 50: return false
			"moral_alta":
				if j.moral < 75: return false
			"bueno":
				if j.ovr < 68: return false
	return true

func _cumple_club(f: Dictionary, c: Club) -> bool:
	if c.plantilla.is_empty():
		return false
	if (f["c"] as Array).has("saldo_positivo") and c.saldo <= 0:
		return false
	return true

func _tiene_activo(jid: String) -> bool:
	for a: Dictionary in activos:
		if String(a["jid"]) == jid:
			return true
	return false

## La masa salarial semanal: la vara de medir del dinero de los imprevistos.
static func masa(c: Club) -> int:
	var s := 0
	for j: Jugador in c.plantilla:
		s += j.sueldo
	return maxi(s, 1000)

const MOTIVO := "Imprevistos de la semana"

func aplicar(m: Object, c: Club, fila: Dictionary, j: Jugador, sem: int) -> void:
	var e: Dictionary = fila["e"]
	var dep := bool(fila.get("dep", false))
	if j != null:
		if e.has("moral"): j.cambiar_moral(int(e["moral"]), MOTIVO)
		if e.has("forma"): j.forma = clampi(j.forma + int(e["forma"]), 20, 99)
		if e.has("lesion"): j.lesionar(int(e["lesion"]))
		for q: String in ["moral_sem", "forma_sem"]:
			if e.has(q):
				activos.append({"id": fila["id"], "jid": j.id, "q": q, "v": int(e[q]), "s": sem})
		if e.has("oferta"):
			_oferta_loca(m, c, j, float(e["oferta"]))
	for x: Jugador in c.plantilla:
		if x.real and not dep:
			continue
		if e.has("moral_eq") and x != j: x.cambiar_moral(int(e["moral_eq"]), MOTIVO)
		if e.has("forma_eq"): x.forma = clampi(x.forma + int(e["forma_eq"]), 20, 99)
	if e.has("forma_eq_sem"):
		activos.append({"id": fila["id"], "jid": "", "q": "forma_eq_sem", "v": int(e["forma_eq_sem"]), "s": sem, "dep": dep})
	if e.has("saldo"):
		c.saldo += int(round(float(masa(c)) * float(e["saldo"])))
	if e.has("saldo_sem"):
		activos.append({"id": fila["id"], "jid": "", "q": "saldo_sem", "v": int(round(float(masa(c)) * float(e["saldo_sem"]))), "s": sem})

## Corre una semana de cada efecto en marcha. Si el jugador ya no está en el club,
## el efecto se va con él.
func correr_activos(c: Club) -> void:
	var siguen: Array = []
	for a: Dictionary in activos:
		var q := String(a["q"])
		var v := int(a["v"])
		if q == "saldo_sem":
			c.saldo += v
		elif q == "forma_eq_sem":
			for x: Jugador in c.plantilla:
				if not (x.real and not bool(a.get("dep", false))):
					x.forma = clampi(x.forma + v, 20, 99)
		else:
			var j: Jugador = null
			for x: Jugador in c.plantilla:
				if x.id == String(a["jid"]):
					j = x
			if j == null:
				continue
			if q == "moral_sem": j.cambiar_moral(v, MOTIVO)
			elif q == "forma_sem": j.forma = clampi(j.forma + v, 20, 99)
		a["s"] = int(a["s"]) - 1
		if int(a["s"]) > 0:
			siguen.append(a)
	activos = siguen

## La oferta loca entra por la puerta de siempre (`Mercado.ofertas_recibidas`), así
## que se acepta o se rechaza desde el despacho como cualquier otra.
func _oferta_loca(m: Object, c: Club, j: Jugador, mult: float) -> void:
	if m == null or m.get("mercado") == null:
		return
	var rico: Club = null
	for x: Club in (m.get("clubes") as Dictionary).values():
		if x.id != c.id and (rico == null or x.saldo > rico.saldo):
			rico = x
	if rico == null:
		return
	var monto := int(round(float(maxi(j.valor, 100000)) * mult))
	var mer: Object = m.get("mercado")
	(mer.get("ofertas_recibidas") as Array).append({"jugador": j, "club": rico, "monto": monto,
		"semana": int(m.get("semana")), "abs": int(m.get("anio")) * 60 + int(m.get("semana")), "clausula": false})
	mer.emit_signal("oferta_recibida", j, rico, monto)

## ------------------------------------------------------------- GUARDADO ---

func a_dic() -> Dictionary:
	return {"act": activos.duplicate(true), "rec": recientes.duplicate()}

func desde_dic(d: Dictionary) -> void:
	activos = (d.get("act", []) as Array).duplicate(true)
	recientes = (d.get("rec", []) as Array).duplicate()
