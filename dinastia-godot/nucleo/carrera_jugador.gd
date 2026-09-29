class_name CarreraJugador
extends RefCounted
## LA CARRERA DE JUGADOR (29-9-2026, mapa de metas 18). No eres el entrenador:
## eres UN futbolista de 17 años en un club chico. Tu jugador es un `Jugador`
## más de la plantilla -la liga, el mercado y las lesiones lo tratan igual que
## a los demás-; esto lleva lo que solo tiene sentido desde sus botas:
##
##   - ENTRENAR: cada semana eliges en qué te matas (tiro, pase, regate,
##     físico, defensa o descanso). Sube más cuanto más joven y cuanto más
##     lejos estás de tu techo; cansa.
##   - EL ENTRENADOR: la relación con el DT decide si juegas. Sube jugando
##     bien y con buena actitud; baja con polémicas y noches largas.
##   - FAMA, SEGUIDORES Y AGENTE: la prensa, las redes y las ofertas.
##   - EVENTOS ÚNICOS con decisiones, que solo le pasan a un futbolista: la
##     primera convocatoria, un rival que te provoca, la fiesta antes del
##     derbi, hacerte cargo de los penales, la renovación, la oferta del
##     grande, la selección...
##   - LOS PARTIDOS se juegan de verdad en el motor jugable (`MotorJugable`),
##     controlando a tu futbolista; o se simulan.
##
## No usa `Azar`: su propio generador, para no mover la simulación del mundo.

const ENERGIA_MAX := 100
const FOCOS := {
	"tiro": ["🎯 Tiro", "tir"], "pase": ["🎼 Pase", "pas"], "regate": ["🌀 Regate", "reg"],
	"fisico": ["💪 Físico", "fis"], "ritmo": ["⚡ Velocidad", "rit"], "defensa": ["🛡️ Defensa", "def"],
	"descanso": ["😴 Descanso", ""],
}
## Las demarcaciones que se pueden elegir al crear el jugador (sin portero: el
## modo es de jugador de campo, con balón en los pies).
const PUESTOS := ["DC", "ED", "EI", "MCO", "MC", "MCD", "LD", "LI", "DFC"]

var jugador_id := ""
var fama := 5              ## 0-100
var relacion_dt := 55      ## 0-100: por encima de 60 juegas si das el nivel
var energia := ENERGIA_MAX
var seguidores := 150
var agente := ""
var foco := "tiro"
var lanzador := {"penales": false, "faltas": false, "corners": true}
var convocatorias := 0
var partidos_jugables := 0
var stats_temp := {"pj": 0, "titular": 0, "goles": 0, "asist": 0, "notas": []}
var temporadas: Array = []        ## [{anio, club, pj, goles, asist, nota}]
var eventos: Array = []           ## pendientes: [{id, titulo, texto, opciones}]
var historial: Array = []         ## lo que decidiste: [{anio, semana, titulo, eleccion}]
var ofertas: Array = []           ## [{club_id, sueldo, semanas}]
var hitos := {}                   ## eventos únicos que ya ocurrieron (id -> true)
var ultima_vez := {}              ## id -> semana absoluta: los repetibles esperan 5 semanas
var _rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------- creación

## Crea al futbolista y lo pone en un club modesto: el peor de la segunda
## división del primer país del mundo (o de la primera, si no hay segunda).
static func crear(m: Mundo, nombre: String, pos_e: String, pie_zurdo: bool, semilla: int = 0) -> CarreraJugador:
	var c := CarreraJugador.new()
	c._rng.seed = semilla if semilla != 0 else hash(nombre + pos_e)
	var j := Jugador.new()
	j.id = "yo_%d" % absi(hash(nombre + str(semilla)))
	j.nombre = nombre
	j.pos_e = pos_e
	var posd: Dictionary = Datos.tabla("POSD")
	j.pos = String((posd.get(pos_e, {"g": "MED"}) as Dictionary).get("g", "MED"))
	j.edad = 17
	j.ovr = 58
	j.pot = 86
	j.moral = 75
	j.anios_contrato = 2
	j.rasgo = ""
	## Atributos con el generador propio (no `Azar`): 58 de media, con el
	## sesgo de su puesto.
	var pesos: Dictionary = (posd.get(pos_e, posd.get("MC", {})) as Dictionary).get("p", {})
	for k: String in pesos:
		j.atributos[k] = clampi(58 + c._rng.randi_range(-6, 6) + (6 if float(pesos[k]) >= 0.2 else 0), 40, 75)
	j.ovr = j.media_en(pos_e)
	j.ovr_al_empezar = j.ovr
	if pie_zurdo:
		j.look["pie"] = "zurdo"
	var club := _club_inicial(m)
	if club != null:
		club.fichar(j)
		j.dorsal = _dorsal_libre(club)
	j.tasar()
	c.jugador_id = j.id
	c.agente = ""
	c._evento_bienvenida(m)
	return c

static func _club_inicial(m: Mundo) -> Club:
	var liga: Liga = m.ligas[mini(1, m.ligas.size() - 1)]
	var peor: Club = null
	for cl: Club in liga.clubes:
		if peor == null or cl.rep < peor.rep:
			peor = cl
	return peor

static func _dorsal_libre(club: Club) -> int:
	var usados := {}
	for j: Jugador in club.plantilla:
		usados[j.dorsal] = true
	for d: int in [9, 10, 11, 7, 8, 17, 19, 20, 21, 22, 23, 27, 29, 30]:
		if not usados.has(d):
			return d
	return 33

# ---------------------------------------------------------------- consultas

func jugador(m: Mundo) -> Jugador:
	for c: Club in m.clubes.values():
		for j: Jugador in c.plantilla:
			if j.id == jugador_id:
				return j
	return null

func club(m: Mundo) -> Club:
	var j := jugador(m)
	return m.clubes.get(j.club_id) if j != null else null

## ¿Sale de titular? El DT mira tu media en tu puesto contra la de los que
## compiten por él, y le suma o resta según cómo os llevéis.
func es_titular(m: Mundo) -> bool:
	var j := jugador(m)
	var c := club(m)
	if j == null or c == null or not j.disponible():
		return false
	if c.once().has(j):
		return true
	var rivales := 0
	var mia := float(j.media_en(j.pos_e)) + float(relacion_dt - 55) * 0.25 + (4.0 if energia > 60 else -4.0)
	for o: Jugador in c.plantilla:
		if o != j and o.pos == j.pos and o.disponible() and float(o.media_en(o.pos_e)) > mia:
			rivales += 1
	var huecos := {"DEL": 2, "MED": 3, "DEF": 4}
	return rivales < int(huecos.get(j.pos, 2))

## El once de tu club para el partido jugable: el del DT, y si te toca jugar y
## no estás, entras por el peor de tu línea.
func once_para_partido(m: Mundo) -> Array[Jugador]:
	var c := club(m)
	var j := jugador(m)
	var once := c.once()
	if j == null or once.has(j) or not es_titular(m):
		return once
	var peor := -1
	for i in once.size():
		if once[i].pos == j.pos and (peor < 0 or once[i].ovr < once[peor].ovr):
			peor = i
	if peor < 0:
		for i in once.size():
			if not once[i].es_portero() and (peor < 0 or once[i].ovr < once[peor].ovr):
				peor = i
	if peor >= 0:
		once[peor] = j
	return once

func nota_media() -> float:
	var n: Array = stats_temp["notas"]
	if n.is_empty():
		return 0.0
	var s := 0.0
	for x: float in n:
		s += x
	return s / float(n.size())

# ---------------------------------------------------------------- la semana

## Entrena: sube el atributo del foco. Más cuanto más joven y más lejos del
## techo. Descansar recupera energía y no sube nada.
func entrenar(m: Mundo) -> String:
	var j := jugador(m)
	if j == null:
		return ""
	if foco == "descanso":
		energia = mini(ENERGIA_MAX, energia + 35)
		return "Descansaste: energía %d." % energia
	var attr := String(FOCOS[foco][1])
	if not j.atributos.has(attr):
		attr = j.atributos.keys()[0]
	var margen := maxf(0.0, float(j.pot - j.ovr)) / 30.0
	var juventud := clampf((24.0 - float(j.edad)) / 7.0, 0.2, 1.0)
	var prob := clampf(0.35 + margen * 0.5 + juventud * 0.25, 0.15, 0.95) * (1.0 if energia > 30 else 0.4)
	energia = maxi(0, energia - 14)
	if _rng.randf() < prob:
		j.atributos[attr] = mini(99, int(j.atributos[attr]) + 1)
		var antes := j.ovr
		j.ovr = maxi(j.ovr, j.media_en(j.pos_e))
		if j.ovr != antes:
			j.tasar()
			return "¡Mejoraste! %s sube a %d y tu media a %d." % [String(FOCOS[foco][0]), int(j.atributos[attr]), j.ovr]
		return "%s sube a %d." % [String(FOCOS[foco][0]), int(j.atributos[attr])]
	return "Semana dura de %s, pero sin mejora visible." % String(FOCOS[foco][0]).to_lower()

## Lo que pasa cada semana fuera del campo. Devuelve los eventos nuevos.
func semana(m: Mundo) -> Array:
	var nuevos: Array = []
	energia = mini(ENERGIA_MAX, energia + 12)
	relacion_dt = clampi(relacion_dt + (1 if nota_media() >= 6.8 else 0) - (1 if energia < 25 else 0), 0, 100)
	seguidores += int(float(fama) * 3.0) + _rng.randi_range(0, 20)
	var j := jugador(m)
	if j == null:
		return nuevos
	var ahora := m.anio * 60 + m.semana
	var pool := _eventos_posibles(m, j).filter(func(e: Dictionary) -> bool:
		return ahora - int(ultima_vez.get(String(e["id"]), -99)) >= 5)
	if not pool.is_empty() and _rng.randf() < 0.45:
		var ev: Dictionary = pool[_rng.randi() % pool.size()]
		eventos.append(ev)
		nuevos.append(ev)
		ultima_vez[String(ev["id"])] = ahora
		if bool(ev.get("unico", false)):
			hitos[String(ev["id"])] = true
	## Ofertas de otros clubes si destacas.
	if fama >= 30 and _rng.randf() < 0.08 + float(fama) / 600.0:
		var destino := _club_interesado(m, j)
		if destino != null:
			ofertas.append({"club_id": destino.id, "sueldo": int(float(j.sueldo) * 1.6), "semanas": 3})
	for o: Dictionary in ofertas:
		o["semanas"] = int(o["semanas"]) - 1
	ofertas = ofertas.filter(func(o: Dictionary) -> bool: return int(o["semanas"]) > 0)
	return nuevos

func _club_interesado(m: Mundo, j: Jugador) -> Club:
	var mio := club(m)
	var mejores: Array = []
	for c: Club in m.clubes.values():
		if c != mio and c.rep > (mio.rep if mio != null else 0) + 5 and c.rep < 60 + fama / 2:
			mejores.append(c)
	return mejores[_rng.randi() % mejores.size()] if not mejores.is_empty() else null

func _ev(id: String, titulo: String, texto: String, opciones: Array, unico := false) -> Dictionary:
	return {"id": id, "titulo": titulo, "texto": texto, "opciones": opciones, "unico": unico}

## Una opción: texto y efectos {fama, relacion, energia, seguidores, moral,
## lanzador_*, attr_*}.
func _op(texto: String, efectos: Dictionary) -> Dictionary:
	return {"texto": texto, "efectos": efectos}

func _eventos_posibles(m: Mundo, j: Jugador) -> Array:
	var c := club(m)
	var nombre_club := c.nombre if c != null else "el club"
	var p: Array = []
	if not hitos.has("capitan_consejo"):
		p.append(_ev("capitan_consejo", "El capitán te llama aparte",
			"«Chico, aquí nadie te regala nada. Llega el primero, vete el último.» ¿Qué le contestas?",
			[_op("«Lo haré, capitán.» (relación con el vestuario)", {"relacion": 4, "fama": 0}),
			_op("«Yo ya sé lo que tengo que hacer.»", {"relacion": -5, "fama": 2})], true))
	if not hitos.has("penales") and j.atributos.get("tir", 0) >= 62:
		p.append(_ev("penales", "¿Quién tira los penales?",
			"El DT pregunta en el vestuario quién quiere hacerse cargo de los penales.",
			[_op("Levantas la mano.", {"lanzador_penales": true, "fama": 3, "relacion": 1}),
			_op("Mejor que los tire el veterano.", {"relacion": 3})], true))
	if not hitos.has("faltas") and j.atributos.get("tir", 0) >= 60 and j.atributos.get("pas", 0) >= 60:
		p.append(_ev("faltas", "Las faltas directas",
			"Después del entrenamiento te quedas pateando tiros libres. El DT te ve.",
			[_op("Le pides lanzarlas en el próximo partido.", {"lanzador_faltas": true, "relacion": 1}),
			_op("Sigues practicando sin decir nada.", {"attr_tir": 1})], true))
	p.append(_ev("fiesta", "Una fiesta antes del partido",
		"Tus amigos te invitan a una fiesta el viernes. El sábado juegas.",
		[_op("Vas, pero vuelves temprano.", {"energia": -10, "seguidores": 60}),
		_op("Te quedas hasta tarde.", {"energia": -35, "relacion": -6, "seguidores": 200, "fama": 1}),
		_op("No vas: descanso.", {"energia": 10, "relacion": 1})]))
	p.append(_ev("prensa", "Micrófono en la zona mixta",
		"Un periodista te pregunta si te ves de titular en %s." % nombre_club,
		[_op("«Trabajo para ganarme el puesto.»", {"relacion": 2, "fama": 1}),
		_op("«Si no juego, me buscaré otro club.»", {"relacion": -8, "fama": 5, "seguidores": 250}),
		_op("«Aquí manda el míster.»", {"relacion": 3})]))
	p.append(_ev("provocacion", "Te provocan en Tribuna",
		"Un defensa del próximo rival publica: «Ese pibe no pasa de mí».",
		[_op("Le respondes con un emoji de reloj.", {"fama": 3, "seguidores": 300, "relacion": -1}),
		_op("No contestas: respondes en la cancha.", {"relacion": 2, "moral": 5})]))
	if fama >= 15 and agente == "":
		p.append(_ev("agente", "Un representante quiere llevarte",
			"Un agente con buena cartera te ofrece llevar tu carrera a cambio del 10 %.",
			[_op("Firmas con él.", {"agente": "sí", "fama": 2}),
			_op("Sigues sin agente.", {})]))
	if not hitos.has("botas") and seguidores >= 1500:
		p.append(_ev("botas", "Una marca de botas te llama",
			"Quieren que seas su cara joven. Pagan bien, pero hay sesiones de fotos.",
			[_op("Aceptas.", {"seguidores": 800, "fama": 4, "energia": -8}),
			_op("Ahora no, primero el fútbol.", {"relacion": 2})], true))
	if not hitos.has("seleccion") and j.ovr >= 68:
		p.append(_ev("seleccion", "¡Convocado a la selección!",
			"El seleccionador te incluye en la lista para la próxima fecha FIFA.",
			[_op("Aceptas con orgullo.", {"fama": 10, "seguidores": 1500, "energia": -15, "moral": 10, "convocado": true}),
			_op("Pides no ir para asentarte en el club.", {"relacion": 6, "fama": -2})], true))
	if j.anios_contrato <= 1 and not hitos.has("renovacion_%d" % m.anio):
		p.append(_ev("renovacion_%d" % m.anio, "La renovación",
			"El club te ofrece renovar tres años con una subida de sueldo.",
			[_op("Firmas.", {"contrato": 3, "relacion": 4}),
			_op("Pides más dinero.", {"contrato": 3, "sueldo": 1.3, "relacion": -4}),
			_op("Esperas ofertas.", {"fama": 1})], true))
	if energia < 30:
		p.append(_ev("sobrecarga", "Molestias en el isquio",
			"Llevas semanas sin parar. El médico te recomienda frenar.",
			[_op("Paras una semana.", {"energia": 40, "relacion": -1}),
			_op("Juegas infiltrado.", {"energia": -5, "lesion_riesgo": true})]))
	return p

## Aplica la opción elegida de un evento pendiente.
func resolver(m: Mundo, indice: int, opcion: int) -> String:
	if indice < 0 or indice >= eventos.size():
		return ""
	var ev: Dictionary = eventos[indice]
	var ops: Array = ev["opciones"]
	if opcion < 0 or opcion >= ops.size():
		return ""
	var o: Dictionary = ops[opcion]
	var ef: Dictionary = o["efectos"]
	var j := jugador(m)
	fama = clampi(fama + int(ef.get("fama", 0)), 0, 100)
	relacion_dt = clampi(relacion_dt + int(ef.get("relacion", 0)), 0, 100)
	energia = clampi(energia + int(ef.get("energia", 0)), 0, ENERGIA_MAX)
	seguidores = maxi(0, seguidores + int(ef.get("seguidores", 0)))
	if j != null:
		j.moral = clampi(j.moral + int(ef.get("moral", 0)), 10, 99)
		for k: String in ef:
			if k.begins_with("attr_") and j.atributos.has(k.substr(5)):
				j.atributos[k.substr(5)] = mini(99, int(j.atributos[k.substr(5)]) + int(ef[k]))
		if ef.has("contrato"):
			j.anios_contrato = int(ef["contrato"])
			j.sueldo = int(float(j.sueldo) * float(ef.get("sueldo", 1.15)))
		if bool(ef.get("lesion_riesgo", false)) and _rng.randf() < 0.4:
			j.lesionar(2)
	if bool(ef.get("lanzador_penales", false)):
		lanzador["penales"] = true
	if bool(ef.get("lanzador_faltas", false)):
		lanzador["faltas"] = true
	if bool(ef.get("convocado", false)):
		convocatorias += 1
	if String(ef.get("agente", "")) != "":
		agente = "Agente propio"
	historial.append({"anio": m.anio, "semana": m.semana, "titulo": String(ev["titulo"]), "eleccion": String(o["texto"])})
	eventos.remove_at(indice)
	return String(o["texto"])

## Acepta una oferta: te vas a ese club.
func aceptar_oferta(m: Mundo, i: int) -> bool:
	if i < 0 or i >= ofertas.size():
		return false
	var o: Dictionary = ofertas[i]
	var destino: Club = m.clubes.get(String(o["club_id"]))
	var j := jugador(m)
	if destino == null or j == null:
		return false
	var origen := club(m)
	if origen != null:
		origen.soltar(j)
	destino.fichar(j)
	j.sueldo = int(o["sueldo"])
	j.anios_contrato = 3
	j.dorsal = _dorsal_libre(destino)
	relacion_dt = 50
	fama = mini(100, fama + 5)
	ofertas.clear()
	historial.append({"anio": m.anio, "semana": m.semana, "titulo": "Traspaso", "eleccion": "Fichas por %s" % destino.nombre})
	return true

## Lo que dejó un partido tuyo (jugado en el motor o simulado).
func tras_partido(m: Mundo, d: Dictionary) -> void:
	var j := jugador(m)
	var min_jugados := int(d.get("minutos", 90))
	if min_jugados <= 0:
		return
	stats_temp["pj"] = int(stats_temp["pj"]) + 1
	if bool(d.get("titular", true)):
		stats_temp["titular"] = int(stats_temp["titular"]) + 1
	stats_temp["goles"] = int(stats_temp["goles"]) + int(d.get("goles", 0))
	stats_temp["asist"] = int(stats_temp["asist"]) + int(d.get("asist", 0))
	var nota := float(d.get("nota", 6.0))
	(stats_temp["notas"] as Array).append(nota)
	fama = clampi(fama + int(d.get("goles", 0)) * 2 + int(d.get("asist", 0)) + (1 if nota >= 7.5 else 0), 0, 100)
	relacion_dt = clampi(relacion_dt + (3 if nota >= 7.5 else (1 if nota >= 6.5 else -2)), 0, 100)
	energia = maxi(0, energia - int(float(min_jugados) / 3.0))
	seguidores += int(d.get("goles", 0)) * 120
	if j != null:
		for _g in int(d.get("goles", 0)):
			j.anotar()
		j.asistencias += int(d.get("asist", 0))
		j.partidos += 1
		j.anotar_nota(nota)

## Cierra la temporada: la guarda en tu historial y cumples un año.
func fin_de_temporada(m: Mundo) -> void:
	var c := club(m)
	temporadas.append({"anio": m.anio, "club": c.nombre if c != null else "", "pj": int(stats_temp["pj"]),
		"goles": int(stats_temp["goles"]), "asist": int(stats_temp["asist"]), "nota": snappedf(nota_media(), 0.01)})
	stats_temp = {"pj": 0, "titular": 0, "goles": 0, "asist": 0, "notas": []}

func _evento_bienvenida(m: Mundo) -> void:
	eventos.append(_ev("debut_firma", "Tu primer contrato profesional",
		"Tienes 17 años y acabas de firmar tu primer contrato. El utilero te da la camiseta con tu dorsal.",
		[_op("Te sacas una foto con ella para tu familia.", {"moral": 5, "seguidores": 50}),
		_op("La guardas y te vas a entrenar.", {"relacion": 3})], true))
	hitos["debut_firma"] = true

# ---------------------------------------------------------------- guardado

func a_dic() -> Dictionary:
	return {"jugador_id": jugador_id, "fama": fama, "relacion_dt": relacion_dt, "energia": energia,
		"seguidores": seguidores, "agente": agente, "foco": foco, "lanzador": lanzador,
		"convocatorias": convocatorias, "partidos_jugables": partidos_jugables, "stats_temp": stats_temp,
		"temporadas": temporadas, "eventos": eventos, "historial": historial, "ofertas": ofertas,
		"hitos": hitos, "ultima_vez": ultima_vez, "semilla": _rng.seed}

static func desde_dic(d: Dictionary) -> CarreraJugador:
	var c := CarreraJugador.new()
	c.jugador_id = String(d.get("jugador_id", ""))
	c.fama = int(d.get("fama", 5))
	c.relacion_dt = int(d.get("relacion_dt", 55))
	c.energia = int(d.get("energia", ENERGIA_MAX))
	c.seguidores = int(d.get("seguidores", 150))
	c.agente = String(d.get("agente", ""))
	c.foco = String(d.get("foco", "tiro"))
	c.lanzador = d.get("lanzador", c.lanzador)
	c.convocatorias = int(d.get("convocatorias", 0))
	c.partidos_jugables = int(d.get("partidos_jugables", 0))
	c.stats_temp = d.get("stats_temp", c.stats_temp)
	c.temporadas = d.get("temporadas", [])
	c.eventos = d.get("eventos", [])
	c.historial = d.get("historial", [])
	c.ofertas = d.get("ofertas", [])
	c.hitos = d.get("hitos", {})
	c.ultima_vez = d.get("ultima_vez", {})
	c._rng.seed = int(d.get("semilla", 1))
	return c
