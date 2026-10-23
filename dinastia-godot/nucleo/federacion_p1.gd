extends RefCounted
## (Parte 1 de 3 de `federacion.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `federacion.gd`, conserva la clase.)

## El reglamento de la liga: quién lo escribe, cómo se cambia y a quién castiga.
##
## Es el sistema que impide que las reglas del juego sean una constante. La
## asamblea de clubes vota, y lo que sale de esa votación cambia de verdad:
## cuánta televisión cobras, si puedes fichar al séptimo extranjero, si el
## árbitro tiene VAR y —la que más duele— si el campeón es el líder de la tabla
## o el que gane una eliminatoria de cuatro.
##
## En el HTML todo esto vivía en `G.fed` y llevaba banderas que no miraba nadie:
## se votaban los playoffs, salía la noticia, y en diciembre el campeón seguía
## siendo el primero de la tabla. Aquí cada bandera tiene su método y una puerta
## por la que entra al juego; están todas listadas en `reglas_vigentes()`. Una
## regla que no se nota es una pantalla de votación decorativa, y este proyecto
## ya pagó ese error.
##
## LO QUE NECESITA DE FUERA (no se lo inventa):
##  - `semana(mi, anio, semana)` cada semana, desde `Mundo.avanzar_semana()`.
##  - `votar(op, mi, asamblea)` con los clubes de tu país y tu división.
##  - `campeon_de_liga(tabla, anio, mi_id)` en el cierre, EN VEZ de `tabla[0]`.
##  - `auditoria_anual(mi, obras, anio)` una vez por temporada.
##  - Quien lo llame conecta `movimiento`, `castigo_directiva` y `escandalo`:
##    esta clase no toca la confianza de la directiva ni la funa de la hinchada
##    porque no son suyas, solo dice cuánto se mueven y por qué.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)
signal votacion_abierta(v: Dictionary)
signal votacion_resuelta(id: String, pasa: bool, ganaste: bool, efecto: String)
signal playoffs_jugados(detalle: Dictionary)
signal licencia_revisada(estado: String, fallos: Array)
signal caso_abierto(caso: Dictionary)
signal caso_resuelto(caso: Dictionary)
signal control_hecho(nombre: String, positivo: bool)
## Lo que esta clase provoca pero no administra: la paciencia del directorio y
## el ruido de la calle. Los tienen `Directiva` y `Prensa`, y son suyos.
signal castigo_directiva(delta: int, motivo: String)
signal escandalo(funa: int, motivo: String)

## --- NÚMEROS DEL HTML. No son redondeos bonitos: están equilibrados. --------
const PROB_VOTACION := 0.05        ## que la asamblea convoque, cada semana
const PROB_CONTROL := 0.05         ## que a alguien le toque el vasito
const PROB_POSITIVO := 0.045       ## que ese control salga adverso
const MULTA_LICENCIA := 450000.0
const COSTE_APELACION := 60000.0
const PRIMA_SUPERLIGA := 2200000.0
const COSTE_VAR := 26000.0
const MULTA_SIN_JUVENIL := 90000.0
const BONO_JUVENIL := 35000.0
const TOPE_EXTRANJEROS := 6
const CLUB_GRANDE := 78            ## de aquí para arriba mandas en la asamblea
const MAX_CASOS := 30
const MAX_CONTROLES := 12
## Ventaja en el duelo de playoffs por haber acabado arriba en la tabla.
const VENTAJA_PRIMERO := 4.0
const VENTAJA_SEGUNDO := 2.0
const VENTAJA_FINAL := 2.0

## Cómo vota el RESTO de la asamblea, por moción y por tamaño de club.
## Sale de la cadena de `if` del HTML (`votar()`), y el sentido es el mismo en
## todas: al grande le conviene lo contrario que al chico. `umbral` es la
## reputación a partir de la cual un club cuenta como grande; el 0 de "playoffs"
## no es un descuido, es que ahí todos votan igual (0,55) y por eso ese formato
## sale tantas veces.
const VOTO_IA := {
	"tvigual":     {"umbral": 78, "grande": 0.20, "chico": 0.85},
	"juveniles":   {"umbral": 78, "grande": 0.35, "chico": 0.70},
	"extranjeros": {"umbral": 78, "grande": 0.30, "chico": 0.65},
	"playoffs":    {"umbral": 0,  "grande": 0.55, "chico": 0.55},
	"superliga":   {"umbral": 82, "grande": 0.70, "chico": 0.08},
	"var":         {"umbral": 75, "grande": 0.75, "chico": 0.35},
	## El fair play financiero lo votan los CHICOS: es la unica regla que frena a
	## quien puede gastar sin mirar, y por eso los grandes lo tumban.
	"fpf":         {"umbral": 78, "grande": 0.25, "chico": 0.80},
	## Reglamento fino (28-9-2026): al chico le conviene la promoción (una
	## segunda oportunidad); el desempate directo divide a la asamblea.
	"desempate":   {"umbral": 0,  "grande": 0.5, "chico": 0.5},
	"promocion":   {"umbral": 78, "grande": 0.35, "chico": 0.7},
}
const PROB_NEUTRA := 0.5           ## moción desconocida: la asamblea se parte

## --- EL PRESIDENTE DE LA FEDERACIÓN (26-9-2026, plan maestro C5) -----------
## Pedido: *"los presidentes de las competencias deben ser importantes, en la
## vida real los presidentes de las instituciones del fútbol hacen reglas o
## cambian formas"*. Hasta hoy la asamblea convocaba mociones al azar, sin nadie
## detrás. Ahora hay un presidente con NOMBRE y AGENDA, elegido cada cuatro
## años: las mociones de su agenda salen antes, y presiona a los clubes para
## que las aprueben (+12 puntos a favor en el voto de la IA). Nombre y agenda
## salen de un hash del año -ficticios: ni personas ni programas reales-.
const MANDATO_ANIOS := 4
## agenda -> [nombre de la corriente, mociones que empuja, frase de campaña]
const AGENDAS := {
	"modernizador": ["Modernizador", ["var", "fpf"], "«Tecnología y cuentas claras: el fútbol del siglo XXI.»"],
	"comercial": ["Comercial", ["playoffs", "superliga"], "«Más espectáculo, más televisión, más dinero para todos.»"],
	"proteccionista": ["Proteccionista", ["extranjeros", "juveniles"], "«Primero lo nuestro: la cantera y el jugador del país.»"],
	"igualitario": ["Igualitario", ["tvigual", "fpf"], "«Que el chico pueda soñar: reparto justo y cuentas limpias.»"],
}
const EMPUJE_PRESIDENTE := 0.12
const _PRES_NOMBRES := ["Armando", "Rodolfo", "Esteban", "Gustavo", "Horacio", "Ignacio", "Lisandro",
	"Marcelo", "Norberto", "Osvaldo", "Patricio", "Reinaldo", "Susana", "Verónica", "Graciela", "Mónica"]
const _PRES_APELLIDOS := ["Achával", "Berríos", "Cienfuegos", "Dalmasso", "Echazarreta", "Figueroa",
	"Goycolea", "Hurtado", "Irarrázaval", "Lagos", "Maturana", "Ossandón", "Pradenas", "Quezada"]
## {nombre, agenda, hasta (año en que acaba el mandato)}
var presidente: Dictionary = {}

## --- EL REGLAMENTO EN VIGOR ------------------------------------------------
## Multiplicador de tus derechos de televisión. Lo aplica quien los cobra
## (`Finanzas.derechos_tv()`); aquí solo se decide cuánto vale.
var reparto_tv: float = 1.0
var cupo_juvenil: bool = false     ## obligación de alinear un sub-21
var tope_extranjeros: int = 0      ## 0 = sin tope
var playoffs: bool = false         ## el campeón se juega, no se suma
var superliga: bool = false        ## te fuiste con los separatistas
var var_activo: bool = false       ## hay VAR en la categoría
var desempate_directo: bool = false  ## a igualdad de puntos, el enfrentamiento directo
var promocion: bool = false        ## el antepenúltimo se juega la categoría
## EL HISTORIAL POR ÁRBITRO (28-9-2026): con quién te fue cómo. nombre ->
## {pj, g, e, p, perfil}. Solo tus partidos.
var arbitros: Dictionary = {}

## --- POLÍTICA --------------------------------------------------------------
var aliados: int = 0               ## peso político, de -10 a 10
var votos: Array = []              ## historial de asambleas, la última primero
var voto_pendiente: Dictionary = {}

## --- LICENCIA, TRIBUNAL Y ANTIDOPAJE ---------------------------------------
var licencia: String = "vigente"   ## vigente | condicional | denegada
var avisos: Array = []
var auditoria: Dictionary = {}
var sin_cupo_internacional: bool = false
var casos: Array = []
var controles: Array = []
var semanas_en_rojo: int = 0
## Cuántas veces has recurrido y te han dicho que no. Los árbitros toman nota y
## la siguiente apelación sale más cara de ganar.
var enojo_arbitral: int = 0
## SANCIÓN AL DT (estadio 2.0, fase 3; el `G.dtSusp` del HTML que no se había
## portado). Fechas que te quedan viéndolo desde la grada, y si la sanción es
## de ESTE partido (aún no ha empezado a cumplirse).
var dt_suspension: int = 0
var dt_susp_nueva := false
var playoffs_ultimo: Dictionary = {}

## Contador para los identificadores de caso. El HTML usaba `Date.now()`, que en
## un juego con semilla es veneno: dos partidas con la misma semilla daban
## expedientes con nombres distintos y el guardado dejaba de ser comparable.
var _sec: int = 0
## El campeón de los últimos playoffs, como objeto. Va aparte de
## `playoffs_ultimo` porque ahí solo puede haber cosas que quepan en un JSON:
## meter un Club en el diccionario del guardado es la forma más rápida de que al
## cargar la partida el campeón sea otro club distinto con el mismo nombre.
var _campeon_ref: Club = null

## INCUMPLIR LA LEY SE PAGA (7-10-2026, pedido: «se puede incumplir la ley a
## cambio de multas, eso haría que fuera más dinámico»). Tras cada partido:
##   · plantel por encima del cupo: multa por cada jugador de más, que crece
##     con cada semana que sigues así en la temporada;
##   · alineación indebida (más «de fuera» en cancha o sin el juvenil): multa
##     que crece con cada reincidencia; desde la tercera, además, 3 puntos menos;
##   · cada infracción enfada al tribunal y la directiva toma nota.
## Todo se escala con el tamaño del club (`Eco.escalar`) y se reinicia cada año.
const MULTA_PLANTEL_LEY := 35000.0
const MULTA_ALINEACION := 110000.0
const PUNTOS_ALINEACION := 3
var infracciones_ley: Dictionary = {}   ## "anio" -> {"plantel": n, "alin": n}

# ---------------------------------------------------------------------------
#  FAIR PLAY FINANCIERO
# ---------------------------------------------------------------------------
#
# «Fair Play Financiero (límite de gasto según ingresos)», idea 109. Es la única
# regla del juego que no te castiga por perder partidos, sino por gastar de más:
# si tu masa salarial se come más del 70% de lo que ingresa el club, la
# federación te abre expediente, y si no lo corriges, te multa y te cierra el
# mercado.
#
# POR QUÉ EL 70%. Es el umbral que usa la contabilidad real del fútbol y el que
# ya enseña `Finanzas.proyeccion_anual()` en la pantalla: no se inventa un
# número nuevo, se le pone consecuencia al que ya se estaba enseñando.

const FPF_UMBRAL := 70
const FPF_MULTA := 380000.0
## Cuántas temporadas seguidas por encima antes de que la federación actúe. Una
## mala es un mal año; dos seguidas es un modelo de gestión.
const FPF_AVISOS := 2

var fpf_activo: bool = false
var fpf_avisos: int = 0
var fpf_sancionado: bool = false

func catalogo() -> Array:
	var t: Variant = Datos.tabla("VOTACIONES")
	return t if t is Array else []

func _titulo_mocion(id: String) -> String:
	for v: Dictionary in catalogo():
		if String(v.get("id", "")) == id:
			return String(v.get("t", id))
	return id

## Elige presidente si no hay o si acabó el mandato. Devuelve true si hubo
## elecciones.
func revisar_presidencia(anio: int) -> bool:
	if not presidente.is_empty() and anio < int(presidente.get("hasta", 0)):
		return false
	var h := absi(("presidencia|%d" % anio).hash())
	var claves := AGENDAS.keys()
	var agenda: String = claves[h % claves.size()]
	var nombre := "%s %s" % [_PRES_NOMBRES[(h / 7) % _PRES_NOMBRES.size()], _PRES_APELLIDOS[(h / 131) % _PRES_APELLIDOS.size()]]
	var reelegido := not presidente.is_empty() and String(presidente.get("agenda", "")) == agenda
	if reelegido:
		nombre = String(presidente["nombre"])
	presidente = {"nombre": nombre, "agenda": agenda, "hasta": anio + MANDATO_ANIOS}
	var a: Array = AGENDAS[agenda]
	noticia.emit("🏛️ Elecciones en la federación",
		"%s %s la presidencia (corriente %s) hasta %d. %s Empujará: %s." % [
			nombre, "renueva" if reelegido else "gana", String(a[0]).to_lower(), anio + MANDATO_ANIOS,
			String(a[2]), ", ".join(PackedStringArray((a[1] as Array).map(func(x: String) -> String: return _titulo_mocion(x))))])
	return true

func agenda_empuja(id_mocion: String) -> bool:
	if presidente.is_empty():
		return false
	return (AGENDAS[String(presidente["agenda"])][1] as Array).has(id_mocion)

# ============================================================================
# POLÍTICA DE LIGA: LA ASAMBLEA
# ============================================================================

## Convoca una asamblea, si toca. Cada moción se vota UNA vez en toda la
## carrera: cuando se acaban, se acabó la política.
func abrir_votacion() -> Dictionary:
	if not voto_pendiente.is_empty():
		return {}
	if not Azar.suerte(PROB_VOTACION):
		return {}
	var usadas := {}
	for v: Dictionary in votos:
		usadas[String(v.get("id", ""))] = true
	var libres: Array = []
	for v: Dictionary in catalogo():
		if not usadas.has(String(v.get("id", ""))):
			libres.append(v)
	if libres.is_empty():
		return {}
	## Lo que empuja el presidente sale antes (7 de cada 10 veces, por hash: la
	## tirada de `Azar` es una sola, como siempre).
	var suyas: Array = libres.filter(func(v: Dictionary) -> bool: return agenda_empuja(String(v.get("id", ""))))
	if not suyas.is_empty() and absi(("agenda|%d" % votos.size()).hash()) % 10 < 7:
		libres = suyas
	voto_pendiente = Azar.uno(libres)
	if agenda_empuja(String(voto_pendiente.get("id", ""))):
		voto_pendiente["del_presidente"] = String(presidente.get("nombre", ""))
	votacion_abierta.emit(voto_pendiente)
	## Hasta el 14-9-2026 esto era la única de las nueve señales de la clase sin
	## `noticia.emit()`: la asamblea convocaba de verdad y el jugador solo se
	## enteraba si entraba a la pestaña Federación por su cuenta. Con solo seis
	## mociones en toda la carrera, era fácil perderse una entera.
	var quien := ""
	if voto_pendiente.has("del_presidente"):
		quien = "Propuesta del presidente %s. " % String(voto_pendiente["del_presidente"])
	noticia.emit("Nueva votación en la asamblea",
		"%sLa federación convoca sobre: %s. %s Puedes votar desde Federación." % [quien,
			String(voto_pendiente.get("t", "")), String(voto_pendiente.get("desc", ""))])
	return voto_pendiente

# ============================================================================
# TRIBUNAL DE DISCIPLINA
# ============================================================================

## Abre un expediente y aplica la sanción. Lo llaman el partido (rojas,
## agresiones) y el control antidopaje de aquí abajo.
func abrir_caso(tipo: String, j: Jugador, fechas: int, motivo: String, anio: int, semana_n: int) -> Dictionary:
	_sec += 1
	var caso := {
		"id": "k%d" % _sec, "tipo": tipo,
		"pid": j.id if j != null else "",
		"nombre": Nombres.visible(j.nombre) if j != null else "el club",
		"fechas": fechas, "motivo": motivo, "estado": "firme",
		"anio": anio, "semana": semana_n, "apelado": false,
	}
	casos.push_front(caso)
	if casos.size() > MAX_CASOS:
		casos.pop_back()
	if j != null:
		j.suspension = maxi(j.suspension, fechas)
	noticia.emit("Tribunal de disciplina",
		"%s: %s. Sanción de %d fecha(s). Puedes apelar desde Federación." % [
			caso["nombre"], motivo, fechas])
	caso_abierto.emit(caso)
	return caso

# ============================================================================
# ANTIDOPAJE
# ============================================================================

## El control semanal. Casi siempre no pasa nada, y cuando pasa se lleva por
## delante media temporada de un titular.
func control_antidopaje(mi: Club, anio: int, semana_n: int) -> Dictionary:
	if mi == null or mi.plantilla.is_empty():
		return {}
	if not Azar.suerte(PROB_CONTROL):
		return {}
	var j: Jugador = Azar.uno(mi.plantilla)
	if j == null:
		return {}
	var positivo := Azar.suerte(PROB_POSITIVO)
	var registro := {"nombre": Nombres.visible(j.nombre), "anio": anio,
		"semana": semana_n, "positivo": positivo}
	controles.push_front(registro)
	if controles.size() > MAX_CONTROLES:
		controles.pop_back()
	control_hecho.emit(String(registro["nombre"]), positivo)

	if not positivo:
		noticia.emit("Control antidopaje",
			"Le tocó a %s tras el partido. Muestra negativa, todo en orden." % registro["nombre"])
		return registro

	var fechas := Azar.ent(8, 24)
	j.suspension = maxi(j.suspension, fechas)
	j.cambiar_moral(-30, "Federación y sanciones")
	escandalo.emit(Azar.ent(15, 28), "positivo por dopaje")
	castigo_directiva.emit(-8, "positivo por dopaje en el plantel")
	abrir_caso("dopaje", j, fechas, "control antidopaje con resultado adverso", anio, semana_n)
	noticia.emit("POSITIVO POR DOPAJE: " + String(registro["nombre"]),
		"%s dio positivo. Suspensión provisional de %d fechas, escándalo mediático y patrocinadores llamando. Puedes montarle defensa legal apelando en Federación, o soltarlo y salvar la imagen del club." % [
			registro["nombre"], fechas])
	registro["fechas"] = fechas
	return registro

# ============================================================================
# EL PULSO SEMANAL
# ============================================================================

## Lo que la federación hace cada semana sin que nadie la llame: convocar
## asambleas y aparecer con el vasito. Va desde `Mundo.avanzar_semana()`.
func semana(mi: Club, anio: int, semana_n: int) -> void:
	if mi == null:
		return
	## La mora se cuenta aquí y no en Finanzas porque es un requisito de
	## LICENCIA, no un dato contable: lo que la federación mira no es cuánto
	## debes, es cuántas semanas seguidas llevas debiéndolo.
	if mi.saldo < 0:
		semanas_en_rojo += 1
	else:
		semanas_en_rojo = 0
	revisar_presidencia(anio)
	abrir_votacion()
	control_antidopaje(mi, anio, semana_n)

## Lo que cambia en el juego cuando una moción prospera. Devuelve la frase que
## se le enseña al jugador: si un efecto no se puede explicar en una línea, es
## que no se nota.
func _aplicar_mocion(id: String, pasa: bool, opcion: String, mi: Club) -> String:
	if not pasa:
		return "La moción no prosperó."
	match id:
		"tvigual":
			## Aquí no gana el que vota mejor, gana el que es chico: el reparto
			## igualitario le quita a los grandes para darle a los demás.
			var grande := mi.rep >= CLUB_GRANDE
			reparto_tv = 0.72 if grande else 1.45
			return "Tu club pierde peso en el reparto: los derechos de TV bajan un 28%." \
				if grande else \
				"Tu club gana en el reparto: los derechos de TV suben un 45%."
		"juveniles":
			cupo_juvenil = true
			return "Desde ahora debes alinear un sub-21; a cambio la federación bonifica por cada minuto juvenil."
		"extranjeros":
			tope_extranjeros = TOPE_EXTRANJEROS
			return "Máximo seis extranjeros por plantel a partir de la próxima ventana."
		"playoffs":
			playoffs = true
			return "El campeón se decidirá por playoffs desde la próxima temporada."
		"superliga":
			## La única moción en la que tu voto cambia TU situación y no solo la
			## regla: la superliga se funda igual, pero solo cobras si te subes.
			if opcion != "a":
				return "La superliga sigue adelante sin ti. Conservas la dignidad y pierdes la prima."
			superliga = true
			var prima := Eco.escalar(PRIMA_SUPERLIGA, float(mi.rep))
			mi.mover_saldo(prima)
			movimiento.emit("Prima de incorporación a la superliga", prima)
			escandalo.emit(30, "el club se sumó a la superliga")
			return "Entras en la superliga: dinero inmediato, pero la hinchada y la federación te lo van a cobrar."
		"fpf":
			fpf_activo = true
			fpf_avisos = 0
			return "Entra en vigor el fair play financiero: si tu masa salarial pasa del %d%% de los ingresos dos temporadas seguidas, hay multa y mercado cerrado." % FPF_UMBRAL
		"desempate":
			desempate_directo = true
			Liga.desempate_directo = true
			return "Desde ahora, a igualdad de puntos manda el enfrentamiento directo."
		"promocion":
			promocion = true
			return "Desde esta temporada, el antepenúltimo de Primera juega la promoción contra el tercero de Ascenso."
		"var":
			var_activo = true
			var coste := Eco.escalar(COSTE_VAR, float(mi.rep))
			mi.mover_saldo(-coste)
			movimiento.emit("Instalación del VAR", -coste)
			return "El VAR llega a la categoría. Menos polémicas, más costes."
	return "La moción no prosperó."
