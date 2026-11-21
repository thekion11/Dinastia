extends RefCounted
## [Capa 1/3 de `carrera_jugador.gd`] jugador, club, _club_inicial, _dorsal_libre, crear, es_titular … (+13)

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
const EDAD_TOPE := 40   ## (16-11, revisión de R-01) el mundo protege a tu futbolista hasta esta edad, y nunca ya retirado
const FOCOS := {
	"tiro": ["🎯 Tiro", "tir"], "pase": ["🎼 Pase", "pas"], "regate": ["🌀 Regate", "reg"],
	"fisico": ["💪 Físico", "fis"], "ritmo": ["⚡ Velocidad", "rit"], "defensa": ["🛡️ Defensa", "def"],
	"descanso": ["😴 Descanso", ""],
}
## Las demarcaciones que se pueden elegir al crear el jugador (el portero, desde
## el 25-10-2026: sus focos, nota y eventos viven en `CarreraPortero`).
const PUESTOS := ["DC", "ED", "EI", "MCO", "MC", "MCD", "LD", "LI", "DFC", "POR"]

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
var stats_temp := {"pj": 0, "titular": 0, "goles": 0, "asist": 0, "notas": [], "vallas": 0}
var temporadas: Array = []        ## [{anio, club, pj, goles, asist, nota}]
var eventos: Array = []           ## pendientes: [{id, titulo, texto, opciones}]
var historial: Array = []         ## lo que decidiste: [{anio, semana, titulo, eleccion}]
var ofertas: Array = []           ## [{club_id, sueldo, semanas}]
var hitos := {}                   ## eventos únicos que ya ocurrieron (id -> true)
var ultima_vez := {}              ## id -> semana absoluta: los repetibles esperan 5 semanas
## FASE 3 DEL MEGAPLAN: selección, eventos de verdad y el paso a entrenador.
var goles_carrera := 0
var pj_carrera := 0
var caps := 0                     ## partidos con la selección
var goles_sel := 0
var convocatoria := {}            ## la de esta fecha FIFA: {pais, nombre, rival}
var capitan := false
var licencia := false             ## curso de entrenador hecho (licencia C)
var retiro_anunciado := false
var retirado := false
var clubes_pasados: Array = []    ## nombres de los clubes donde jugaste
## LA AGENDA DE LA SEMANA (M-263, `CarreraAgenda`): qué haces fuera del entreno.
var agenda := "normal"
var racha_social := 0             ## semanas seguidas de vida social
var ovr_inicio := -1              ## tu media al empezar la temporada (progresión)
var _rng := RandomNumberGenerator.new()

# ---------------------------------------------------------------- selección

## Cupos por línea de una convocatoria (18 jugadores).
## Selecciones rivales que no tienen liga en el mundo (y por eso no están en
## PAIS_SELECCION): su código, para la bandera.
const CODIGO_SELECCION := {"Portugal": "POR", "Holanda": "NED", "Bélgica": "BEL", "Croacia": "CRO",
	"Dinamarca": "DEN", "Senegal": "SEN", "Nigeria": "NGA", "Camerún": "CMR", "Irán": "IRN",
	"Costa Rica": "CRC", "Canadá": "CAN", "N. Zelanda": "NZL", "Catar": "QAT"}
const CUPOS_SEL := {"POR": 2, "DEF": 6, "MED": 6, "DEL": 4}

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

# ---------------------------------------------------------------- creación

const BASE_INICIAL := 55   ## con el sesgo del puesto y el estilo, la media sale en unos 60
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
	## Atributos con el generador propio (no `Azar`), con el sesgo de su puesto.
	## (13-11 noche, dueño) La media parte en unos 60.
	var pesos: Dictionary = (posd.get(pos_e, posd.get("MC", {})) as Dictionary).get("p", {})
	for k: String in pesos:
		j.atributos[k] = clampi(BASE_INICIAL + c._rng.randi_range(-5, 5) + (6 if float(pesos[k]) >= 0.2 else 0), 40, 75)
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
	c.foco = CarreraPortero.foco_inicial(pos_e)
	c.agente = ""
	c._evento_bienvenida(m)
	return c

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
	var huecos := {"DEL": 2, "MED": 3, "DEF": 4, "POR": 1}
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

## DESDE EL BANCO (MEGAPLAN fase 3): si empiezas de suplente, ¿te hace entrar
## el DT y en qué minuto? Con buena relación y energía entras antes y más a
## menudo. -1 = no sales del banco. El portero suplente solo entra si el
## titular se lesiona (~1 de cada 16 partidos; en el motor, `MotorCambioPortero`),
## o si lo expulsan estando tú en la banda.
func minuto_entrada_suplente(portero := false) -> int:
	if portero:
		return _rng.randi_range(15, 85) if _rng.randf() < 0.06 else -1
	var prob := clampf(0.35 + float(relacion_dt - 50) / 100.0 + (0.1 if energia > 50 else -0.1), 0.1, 0.85)
	if _rng.randf() >= prob:
		return -1
	return clampi(_rng.randi_range(56, 82) - int(float(relacion_dt - 55) / 5.0), 46, 86)

## Lo que tolera el DT antes de sacarte (0 = mucho, 1 = poco), para el motor.
func exigencia_dt() -> float:
	return clampf(float(70 - relacion_dt) / 40.0, 0.0, 1.0)

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
		return Idiomas.t("Descansaste: energía %d.") % energia
	## Cada puesto con sus focos (el portero, los suyos): uno que no es del
	## puesto -una partida vieja- entrena el primero que lo sea.
	var tabla := CarreraPortero.focos_para(j)
	var f: Array = tabla.get(foco, tabla.values()[0])
	var attr := String(f[1])
	## Los avisos se traducen aquí, por plantilla (con los números dentro ya no
	## casan con el diccionario): la UI los une con «·».
	var nombre_foco := Idiomas.t(String(f[0]))
	if not j.atributos.has(attr):
		attr = j.atributos.keys()[0]
	var margen := maxf(0.0, float(j.pot - j.ovr)) / 30.0
	var juventud := clampf((24.0 - float(j.edad)) / 7.0, 0.2, 1.0)
	## (13-11 noche, dueño: «la velocidad de crecimiento está muy alta») Antes 0,35 + 0,5 + 0,25 (casi un punto cada semana).
	var prob := clampf(0.15 + margen * 0.30 + juventud * 0.12 + CarreraAgenda.extra_entreno(agenda), 0.08, 0.60) * (1.0 if energia > 30 else 0.4)
	energia = maxi(0, energia - 14)
	if _rng.randf() < prob:
		j.atributos[attr] = mini(99, int(j.atributos[attr]) + 1)
		var antes := j.ovr
		j.ovr = maxi(j.ovr, j.media_en(j.pos_e))
		if j.ovr != antes:
			j.tasar()
			return Idiomas.t("¡Mejoraste! %s sube a %d y tu media a %d.") % [nombre_foco, int(j.atributos[attr]), j.ovr]
		return Idiomas.t("%s sube a %d.") % [nombre_foco, int(j.atributos[attr])]
	return Idiomas.t("Semana dura de %s, pero sin mejora visible.") % nombre_foco.to_lower()

## ¿Te convoca tu selección? Los mejores de tu país en tu línea, jueguen donde
## jueguen. Solo en las fechas FIFA.
func revisar_convocatoria(m: Mundo) -> bool:
	convocatoria = {}
	var j := jugador(m)
	## (Sin depender de `m.selecciones`: en la carrera de jugador no se crea,
	## solo existe cuando diriges un club.)
	if j == null or retirado or not Selecciones.SEMANAS_FIFA.has(m.semana) or not j.disponible():
		return false
	var mejores := 0
	for c: Club in m.clubes.values():
		for o: Jugador in c.plantilla:
			if o != j and o.pais == j.pais and o.pos == j.pos and o.disponible() and o.ovr > j.ovr:
				mejores += 1
	if mejores >= int(CUPOS_SEL.get(j.pos, 4)):
		return false
	var nombre := String(Selecciones._tabla_paises().get(j.pais, j.pais))
	var rivales: Array = []
	for n: Variant in Selecciones._tabla_selecciones():
		if String(n) != nombre:
			rivales.append(String(n))
	convocatoria = {"pais": j.pais, "nombre": nombre,
		"rival": String(rivales[_rng.randi() % rivales.size()]) if not rivales.is_empty() else "Selección rival"}
	return true

## (16-11, informe R-12) Título y texto son la PLANTILLA (se traduce al pintar, `CarreraEventosRuta.texto`); los nombres y
## cifras van aparte, en `titulo_datos` / `texto_datos`.
func _ev(id: String, titulo: String, texto: String, opciones: Array, unico := false, datos := {}) -> Dictionary:
	return {"id": id, "titulo": titulo, "texto": texto, "opciones": opciones, "unico": unico}.merged(datos)

## Una opción: texto y efectos {fama, relacion, energia, seguidores, moral,
## lanzador_*, attr_*}.
func _op(texto: String, efectos: Dictionary) -> Dictionary:
	return {"texto": texto, "efectos": efectos}

func _veterano(c: Club, j: Jugador) -> Jugador:
	if c == null:
		return null
	var mejor: Jugador = null
	for o: Jugador in c.plantilla:
		if o != j and o.edad >= 32 and (mejor == null or o.ovr > mejor.ovr):
			mejor = o
	return mejor

## El partido de liga de `c` esta semana ([local, visita] o []).
static func partido_de_la_semana(m: Mundo, c: Club) -> Array:
	if c == null:
		return []
	for l: Liga in m.ligas:
		if not l.clubes.has(c) or not l.quedan_jornadas():
			continue
		for par: Array in l.calendario[l.jornada_actual]:
			if par[0] == c or par[1] == c:
				return par
	return []

## El rival de esta semana, si es un club donde ya jugaste.
func _rival_ex_club(m: Mundo, c: Club) -> String:
	if c == null or clubes_pasados.is_empty():
		return ""
	var par := partido_de_la_semana(m, c)
	if par.size() < 2:
		return ""
	for cl: Club in [par[0], par[1]]:
		if cl != c and clubes_pasados.has(cl.nombre):
			return cl.nombre
	return ""

func _club_interesado(m: Mundo, _j: Jugador) -> Club:
	var mio := club(m)
	var mejores: Array = []
	for c: Club in m.clubes.values():
		if c != mio and c.rep > (mio.rep if mio != null else 0) + 5 and c.rep < 60 + fama / 2:
			mejores.append(c)
	return mejores[_rng.randi() % mejores.size()] if not mejores.is_empty() else null
