class_name Federacion
extends RefCounted
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

func _titulo_mocion(id: String) -> String:
	for v: Dictionary in catalogo():
		if String(v.get("id", "")) == id:
			return String(v.get("t", id))
	return id

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

## Vota la moción pendiente. `opcion` es "a" (a favor) o "b" (en contra).
##
## `asamblea` son los clubes con derecho a voto: los de tu país y tu división.
## Pásala COMPLETA, con tu club dentro: el HTML recorre la lista entera —el tuyo
## incluido, que además vota por su cuenta— y después suma tu voto aparte. Es
## una rareza suya, pero cambiarla movería el umbral de aprobación de las seis
## mociones a la vez, así que se porta tal cual.
func votar(opcion: String, mi: Club, asamblea: Array) -> Dictionary:
	if voto_pendiente.is_empty() or mi == null:
		return {}
	var v := voto_pendiente
	var id := String(v.get("id", ""))
	var reglas: Dictionary = VOTO_IA.get(id, {})

	var a_favor := 0
	var total := 0
	for x: Club in asamblea:
		total += 1
		var p := PROB_NEUTRA
		if not reglas.is_empty():
			p = float(reglas["grande"]) if x.rep >= int(reglas["umbral"]) else float(reglas["chico"])
		## El presidente hace campaña por lo suyo.
		if agenda_empuja(id):
			p = minf(p + EMPUJE_PRESIDENTE, 0.95)
		if Azar.suerte(p):
			a_favor += 1
	if opcion == "a":
		a_favor += 1
	else:
		total += 1
	## OJO: división REAL, no entera. Con `total / 2` sobre enteros, una asamblea
	## de 17 clubes aprobaría con 8 votos de 17, porque 17/2 da 8 y basta con
	## empatarlo. En coma flotante hace falta la mitad de verdad.
	var pasa := float(a_favor) > float(total) / 2.0

	var efecto := _aplicar_mocion(id, pasa, opcion, mi)
	var ganaste := (opcion == "a") == pasa
	aliados = clampi(aliados + (1 if ganaste else -1), -10, 10)
	votos.push_front({"id": id, "t": String(v.get("t", "")), "pasa": pasa,
		"vote_a": opcion == "a"})

	noticia.emit("Asamblea de la liga: " + String(v.get("t", "")),
		"Resultado: %d votos a favor de %d. La moción %s. %s Tu posición %s" % [
			a_favor, total, "SE APRUEBA" if pasa else "se rechaza", efecto,
			"salió ganadora: sumas peso político en la asamblea."
				if ganaste else "quedó en minoría."])
	votacion_resuelta.emit(id, pasa, ganaste, efecto)
	voto_pendiente = {}
	return {"id": id, "pasa": pasa, "ganaste": ganaste, "efecto": efecto,
		"a_favor": a_favor, "total": total, "aliados": aliados}

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

# ============================================================================
# LAS PUERTAS POR LAS QUE EL REGLAMENTO ENTRA AL JUEGO
# ============================================================================

## Multiplicador de los derechos de televisión de TU club. Lo aplica quien los
## cobra; que se decida aquí y no en Finanzas es a propósito: el reparto es una
## regla de la liga, no una partida contable.
func factor_tv() -> float:
	return reparto_tv

## Cuánto se recortan las tarjetas de un árbitro tarjetero por haber VAR. El
## HTML lo llama `_fVAR` y vale 0,5: con vídeo se protesta menos y se inventan
## menos faltas.
func factor_tarjetas() -> float:
	return 0.5 if var_activo else 1.0

## Cupo juvenil: multa si sacas un once sin sub-21, bonificación por cada uno que
## juegue. Devuelve el dinero neto (negativo si te multaron) y mueve la caja.
##
## Se le pasa el once REAL que saltó al campo, no la plantilla: el cupo es de
## minutos jugados, no de fichas guardadas en un cajón.
func revisar_cupo_juvenil(mi: Club, once: Array) -> int:
	if not cupo_juvenil or mi == null:
		return 0
	var juveniles: Array = []
	for j: Jugador in once:
		if j != null and j.edad <= 21:
			juveniles.append(j)
	if juveniles.is_empty():
		var multa := Eco.escalar(MULTA_SIN_JUVENIL, float(mi.rep))
		mi.mover_saldo(-multa)
		movimiento.emit("Multa: sin sub-21 en el once", -multa)
		castigo_directiva.emit(-2, "incumplir el cupo juvenil")
		noticia.emit("Multa por incumplir el cupo juvenil",
			"Saliste sin ningún sub-21 en el once y la federación te sanciona. El reglamento que votó la asamblea obliga a alinear al menos uno.")
		return -multa
	var bono := Eco.escalar(BONO_JUVENIL, float(mi.rep)) * juveniles.size()
	mi.mover_saldo(bono)
	movimiento.emit("Bonificación por minutos juveniles (%d)" % juveniles.size(), bono)
	for j: Jugador in juveniles:
		j.moral = clampi(j.moral + 2, 10, 99)
	return bono

## ¿Cabe este extranjero en el plantel? Devuelve "" si sí, o el motivo si no.
## Lo consulta el mercado ANTES de cerrar un fichaje: rechazarlo después sería
## fichar y descubrir en la pantalla siguiente que no puede jugar.
func puede_fichar_extranjero(mi: Club, j: Jugador) -> String:
	if tope_extranjeros <= 0 or mi == null or j == null:
		return ""
	if j.pais == mi.pais:
		return ""
	var extranjeros := 0
	for x: Jugador in mi.plantilla:
		if x.pais != mi.pais:
			extranjeros += 1
	if extranjeros >= tope_extranjeros:
		return "Cupo de extranjeros lleno (%d): la liga lo votó así" % tope_extranjeros
	return ""

## Las reglas que están en vigor ahora mismo, en frases. Es lo que se enseña en
## la pantalla de Federación: un puñado de banderas booleanas no le dice nada a
## nadie.
func reglas_vigentes() -> Array:
	var l: Array = []
	if not is_equal_approx(reparto_tv, 1.0):
		l.append("Reparto de TV al %d%% de lo normal" % int(round(reparto_tv * 100.0)))
	if cupo_juvenil:
		l.append("Obligatorio un sub-21 en el once")
	if tope_extranjeros > 0:
		l.append("Máximo %d extranjeros por plantel" % tope_extranjeros)
	if playoffs:
		l.append("El campeón se decide por playoffs")
	if superliga:
		l.append("Tu club juega la superliga separatista")
	if var_activo:
		l.append("VAR en toda la categoría")
	if licencia != "vigente":
		l.append("Licencia %s" % licencia)
	if l.is_empty():
		l.append("Reglamento estándar: nada que la asamblea haya cambiado todavía")
	return l

# ============================================================================
# PLAYOFFS POR EL TÍTULO
# ============================================================================
#
# POR QUÉ ESTO NO USA `Copa`, que ya hace eliminatorias con penales:
#
#  - `Copa.preparar()` BARAJA a los participantes. Aquí el cruce no se sortea:
#    es 1º-4º y 2º-3º, y esa es la mitad de la gracia del formato.
#  - No hay forma de decirle a `Copa` que el primero de la tabla arranca con
#    ventaja. Sin esa ventaja, treinta fechas no valdrían absolutamente nada.
#  - `Partido` tiene mucha más varianza que el duelo del HTML. Con él, el líder
#    perdería el título casi la mitad de las veces; con esta fórmula lo pierde
#    en torno a una de cada cuatro, que es lo que mide el banco de pruebas y lo
#    que hace que el formato sea injusto sin ser una lotería.
#
# El día que los playoffs se jueguen en directo (dirigiendo tú la semifinal),
# `Copa` es el sitio: entonces el partido lo simula `Partido` y esta fórmula se
# queda solo para los cruces que no juegas.

## Juega la eliminatoria si la asamblea la votó. Devuelve {} si no hay playoffs
## —o si no hay cuatro equipos—, y si los hay, el detalle guardable de lo que
## pasó: los dos marcadores de semifinales, el de la final y quién levantó la copa.
##
## `tabla` es la de `Liga.tabla()`: filas con la clave "club". También acepta un
## array de Clubes pelados, que es como resulta cómodo llamarla desde una prueba.
func jugar_playoffs(tabla: Array, anio: int, mi_id: String = "") -> Dictionary:
	_campeon_ref = null
	if not playoffs or tabla.size() < 4:
		return {}
	var cuatro: Array[Club] = []
	for i in 4:
		var c := _club_de(tabla[i])
		if c == null:
			return {}
		cuatro.append(c)

	var s1 := _duelo(cuatro[0], cuatro[3], VENTAJA_PRIMERO)
	var s2 := _duelo(cuatro[1], cuatro[2], VENTAJA_SEGUNDO)
	## A la final el líder llega con menos ventaja que a la semifinal: acabar
	## primero pesa, pero cada vez menos. Si no, los playoffs serían el mismo
	## campeón de siempre con dos partidos de trámite.
	var ventaja := VENTAJA_FINAL if s1["gana"] == cuatro[0] else 0.0
	var fin := _duelo(s1["gana"], s2["gana"], ventaja)
	var campeon: Club = fin["gana"]
	_campeon_ref = campeon

	playoffs_ultimo = {
		"anio": anio,
		"semis": [String(s1["marcador"]), String(s2["marcador"])],
		"final": String(fin["marcador"]),
		"campeon": campeon.id,
		"campeon_nombre": Nombres.visible(campeon.nombre),
		"lider": cuatro[0].id,
		"lider_nombre": Nombres.visible(cuatro[0].nombre),
	}

	var mio := false
	for c in cuatro:
		if c.id == mi_id:
			mio = true
	var cola := " Tu equipo no llegó a los cuatro primeros."
	if mio:
		cola = " Lo ganaste tú: el mejor de la tabla no siempre levanta la copa, y esta vez fuiste tú." \
			if campeon.id == mi_id else \
			" Entraste en los playoffs y te quedaste sin el título. Así es este formato."
	noticia.emit("PLAYOFFS POR EL TÍTULO %d" % anio,
		"La federación decidió que el campeón se juega. Semifinales: %s · %s. FINAL: %s. Campeón: %s.%s" % [
			s1["marcador"], s2["marcador"], fin["marcador"],
			Nombres.visible(campeon.nombre), cola])
	if cuatro[0].id != campeon.id:
		noticia.emit("El líder se quedó sin corona",
			"%s terminó primero en la tabla pero perdió los playoffs. Con este formato, treinta fechas no garantizan nada." % Nombres.visible(cuatro[0].nombre))
	playoffs_jugados.emit(playoffs_ultimo)
	return playoffs_ultimo

## El campeón de la temporada: el de los playoffs si los hay, y si no, el líder.
## Es el `jugarPlayoffs(t1) || t1[0]` del HTML, y es la única línea que hay que
## cambiar en el cierre de temporada para que la votación signifique algo.
func campeon_de_liga(tabla: Array, anio: int, mi_id: String = "") -> Club:
	if tabla.is_empty():
		return null
	jugar_playoffs(tabla, anio, mi_id)
	if _campeon_ref != null:
		return _campeon_ref
	return _club_de(tabla[0])

## Un cruce. La fuerza es la reputación más la ventaja de haber acabado arriba, y
## cada punto de diferencia vale 2,2 puntos porcentuales, con el resultado
## acotado entre el 15% y el 85%: ni el más grande tiene el título asegurado ni
## el cuarto va de paseo.
func _duelo(a: Club, b: Club, ventaja: float) -> Dictionary:
	var fa := float(a.rep) + ventaja
	var fb := float(b.rep)
	var pa := clampf(0.5 + (fa - fb) * 0.022, 0.15, 0.85)
	var gana := a if Azar.suerte(pa) else b
	var pierde := b if gana == a else a
	## El marcador se inventa DESPUÉS de saber quién gana, y por eso nunca puede
	## salir un empate: al ganador se le da al menos un gol más que al otro.
	var ga := Azar.ent(0, 3)
	var gb := Azar.ent(0, maxi(0, ga - 1))
	return {
		"gana": gana, "pierde": pierde,
		"marcador": "%s %d-%d %s" % [Nombres.visible(gana.nombre),
			maxi(ga, gb + 1), mini(ga, gb), Nombres.visible(pierde.nombre)],
	}

## Acepta una fila de `Liga.tabla()` o un Club suelto.
func _club_de(fila: Variant) -> Club:
	if fila is Club:
		return fila as Club
	if fila is Dictionary and (fila as Dictionary).has("club"):
		return (fila as Dictionary)["club"] as Club
	return null

# ============================================================================
# LICENCIA DE CLUB
# ============================================================================

## Los seis requisitos de licencia, con su estado y el dato que lo justifica.
## La lista es la del HTML; dos de ellos apuntaban a sitios que en Godot todavía
## no existen y se han enganchado a lo más parecido que sí existe:
##  - "patrimonio neto positivo" miraba la contabilidad completa; aquí mira la
##    caja, que es el único patrimonio que el club tiene portado.
##  - "plan de seguridad" miraba la seguridad privada de la ciudad deportiva;
##    aquí mira la calidad del estadio, que es la obra que paga accesos y luces.
## Las dos son sustituciones conscientes, no despistes: cuando se porten esos
## sistemas se cambian estas dos líneas y nada más.
func requisitos_licencia(mi: Club, obras: Instalaciones) -> Array:
	var minimo := 12000 if mi.division == 1 else 5000
	return [
		{"k": "aforo", "t": "Aforo mínimo de la categoría",
			"ok": mi.estadio_aforo >= minimo,
			"det": "%d butacas" % mi.estadio_aforo},
		{"k": "med", "t": "Centro médico nivel 1 o superior",
			"ok": obras.nivel("med") >= 1, "det": "nivel %d" % obras.nivel("med")},
		{"k": "acad", "t": "Academia juvenil operativa",
			"ok": obras.nivel("acad") >= 1, "det": "nivel %d" % obras.nivel("acad")},
		{"k": "caja", "t": "Caja sin mora prolongada",
			"ok": semanas_en_rojo < 4, "det": "%d semanas en rojo" % semanas_en_rojo},
		{"k": "patrim", "t": "Patrimonio neto positivo",
			"ok": mi.saldo > 0, "det": "caja de %d" % mi.saldo},
		{"k": "seg", "t": "Plan de seguridad del estadio",
			"ok": obras.nivel("cal") >= 1, "det": "calidad de estadio nivel %d" % obras.nivel("cal")},
	]

## La revisión anual. Uno o dos incumplimientos son un aviso con pérdida del cupo
## internacional; tres o más, multa y licencia denegada.
##
## Es lo que hace que construir no sea opcional: puedes ganar la liga con un
## plantel caro y una ciudad deportiva de cartón, pero no dos años seguidos.
func auditoria_anual(mi: Club, obras: Instalaciones, anio: int) -> Dictionary:
	if mi == null or obras == null:
		return {}
	## Se limpia primero: el veto internacional es de UNA temporada, y si no se
	## borrara al empezar la revisión, un club que arregló sus papeles seguiría
	## castigado para siempre.
	sin_cupo_internacional = false
	var fallos: Array = []
	for r: Dictionary in requisitos_licencia(mi, obras):
		if not bool(r["ok"]):
			fallos.append(String(r["t"]))
	auditoria = {"anio": anio, "fallos": fallos}
	avisos = fallos.duplicate()

	if fallos.is_empty():
		licencia = "vigente"
		avisos = []
		noticia.emit("Auditoría federativa superada",
			"El club cumple los seis requisitos de licencia. Sin observaciones: puedes competir e inscribir jugadores con normalidad.")
	elif fallos.size() <= 2:
		licencia = "condicional"
		sin_cupo_internacional = true
		noticia.emit("Licencia CONDICIONAL",
			"La federación detectó %d incumplimiento(s): %s. Tienes una temporada para corregirlo o pierdes el cupo internacional." % [
				fallos.size(), _en_lista(fallos)])
	else:
		licencia = "denegada"
		sin_cupo_internacional = true
		var multa := Eco.escalar(MULTA_LICENCIA, float(mi.rep))
		mi.mover_saldo(-multa)
		movimiento.emit("Multa federativa por licencia denegada", -multa)
		castigo_directiva.emit(-16, "licencia denegada")
		noticia.emit("LICENCIA DENEGADA",
			"La federación rechaza la licencia por %d incumplimientos: %s. Multa, sin cupo internacional y con el mercado bajo lupa. Arréglalo esta temporada." % [
				fallos.size(), _en_lista(fallos)])
	licencia_revisada.emit(licencia, fallos)
	return {"estado": licencia, "fallos": fallos, "anio": anio}

func _en_lista(l: Array) -> String:
	var m: Array = []
	for t: String in l:
		m.append(t.to_lower())
	return ", ".join(m)

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

## Apela un expediente. Devuelve "" si se tramitó, o el motivo por el que no.
##
## `prestigio_dt` es la reputación del entrenador, de 0 a 99. Va como parámetro y
## no como campo porque el perfil de gestor todavía no está portado: con el 50
## por defecto la fórmula queda en su punto neutro, y el día que exista solo hay
## que pasárselo. El HTML sumaba además 0,22 si tenías consejero legal, que
## tampoco existe aún: cuando exista, entra por esta misma línea.
func apelar(caso_id: String, mi: Club, prestigio_dt: int = 50) -> String:
	if mi == null:
		return "no hay club"
	var caso: Dictionary = {}
	for c: Dictionary in casos:
		if String(c["id"]) == caso_id:
			caso = c
			break
	if caso.is_empty():
		return "ese expediente no existe"
	if bool(caso["apelado"]):
		return "ese expediente ya se apeló"
	var coste := Eco.escalar(COSTE_APELACION, float(mi.rep))
	if mi.saldo < coste:
		return "no hay caja: la apelación cuesta %d" % coste
	mi.mover_saldo(-coste)
	movimiento.emit("Honorarios legales: apelación de %s" % caso["nombre"], -coste)
	caso["apelado"] = true

	var p := 0.35 + float(prestigio_dt - 50) / 400.0 - float(enojo_arbitral) * 0.03
	if String(caso["tipo"]) == "roja":
		p -= 0.08
	if String(caso["tipo"]) == "agresion":
		p -= 0.2
	p = clampf(p, 0.05, 0.85)

	var j := _jugador_de(mi, String(caso["pid"]))
	if Azar.suerte(p):
		## O te la quitan entera o te quitan una sola fecha: el tribunal no hace
		## descuentos finos, y esa es justo la tensión de apelar.
		var quita: int = int(caso["fechas"]) if Azar.suerte(0.5) else 1
		quita = mini(int(caso["fechas"]), quita)
		caso["fechas"] = int(caso["fechas"]) - quita
		caso["estado"] = "rebajada"
		if j != null:
			j.suspension = maxi(0, j.suspension - quita)
		noticia.emit("Apelación ACOGIDA",
			"El tribunal rebaja la sanción de %s en %d fecha(s). Le quedan %d." % [
				caso["nombre"], quita, caso["fechas"]])
	else:
		caso["estado"] = "confirmada"
		enojo_arbitral += 1
		noticia.emit("Apelación RECHAZADA",
			"El tribunal confirma la sanción de %s y deja constancia de que el club recurre demasiado. Los árbitros toman nota." % caso["nombre"])
	caso_resuelto.emit(caso)
	return ""

func _jugador_de(mi: Club, pid: String) -> Jugador:
	if mi == null or pid == "":
		return null
	for j: Jugador in mi.plantilla:
		if j.id == pid:
			return j
	return null

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
	j.moral = clampi(j.moral - 30, 10, 99)
	escandalo.emit(Azar.ent(15, 28), "positivo por dopaje")
	castigo_directiva.emit(-8, "positivo por dopaje en el plantel")
	abrir_caso("dopaje", j, fechas, "control antidopaje con resultado adverso", anio, semana_n)
	noticia.emit("POSITIVO POR DOPAJE: " + String(registro["nombre"]),
		"%s dio positivo. Suspensión provisional de %d fechas, escándalo mediático y patrocinadores llamando. Puedes montarle defensa legal apelando en Federación, o soltarlo y salvar la imagen del club." % [
			registro["nombre"], fechas])
	registro["fechas"] = fechas
	return registro

# ============================================================================
# GUARDADO
# ============================================================================

func a_dic() -> Dictionary:
	return {
		"reparto_tv": reparto_tv, "cupo_juvenil": cupo_juvenil,
		"tope_extranjeros": tope_extranjeros, "playoffs": playoffs,
		"superliga": superliga, "var": var_activo,
		"fpf": fpf_activo, "fpf_avisos": fpf_avisos, "fpf_sancion": fpf_sancionado,
		"aliados": aliados, "votos": votos, "voto_pendiente": voto_pendiente,
		"licencia": licencia, "avisos": avisos, "auditoria": auditoria,
		"sin_cupo": sin_cupo_internacional,
		"casos": casos, "controles": controles,
		"semanas_en_rojo": semanas_en_rojo, "enojo_arbitral": enojo_arbitral,
		"playoffs_ultimo": playoffs_ultimo, "sec": _sec,
		"presidente": presidente,
		"desempate": desempate_directo, "promocion": promocion, "arbitros": arbitros,
	}

func desde_dic(d: Dictionary) -> void:
	reparto_tv = float(d.get("reparto_tv", 1.0))
	cupo_juvenil = bool(d.get("cupo_juvenil", false))
	tope_extranjeros = int(d.get("tope_extranjeros", 0))
	playoffs = bool(d.get("playoffs", false))
	superliga = bool(d.get("superliga", false))
	var_activo = bool(d.get("var", false))
	desempate_directo = bool(d.get("desempate", false))
	Liga.desempate_directo = desempate_directo
	promocion = bool(d.get("promocion", false))
	arbitros = (d.get("arbitros", {}) as Dictionary).duplicate(true)
	fpf_activo = bool(d.get("fpf", false))
	fpf_avisos = int(d.get("fpf_avisos", 0))
	fpf_sancionado = bool(d.get("fpf_sancion", false))
	aliados = int(d.get("aliados", 0))
	presidente = (d.get("presidente", {}) as Dictionary).duplicate()
	votos = (d.get("votos", []) as Array).duplicate()
	voto_pendiente = (d.get("voto_pendiente", {}) as Dictionary).duplicate()
	licencia = String(d.get("licencia", "vigente"))
	avisos = (d.get("avisos", []) as Array).duplicate()
	auditoria = (d.get("auditoria", {}) as Dictionary).duplicate()
	sin_cupo_internacional = bool(d.get("sin_cupo", false))
	casos = (d.get("casos", []) as Array).duplicate()
	controles = (d.get("controles", []) as Array).duplicate()
	semanas_en_rojo = int(d.get("semanas_en_rojo", 0))
	enojo_arbitral = int(d.get("enojo_arbitral", 0))
	playoffs_ultimo = (d.get("playoffs_ultimo", {}) as Dictionary).duplicate()
	_sec = int(d.get("sec", 0))
	## El campeón no se restaura: es una referencia viva a un Club de ESTA
	## partida cargada, y el que se guardó ya no existe. Quien lo necesite lo
	## busca por el id, que sí está en `playoffs_ultimo`.
	_campeon_ref = null

## Las seis mociones. Vienen de la tabla del juego, no reescritas aquí: si el
## HTML añade una séptima, se vuelve a exportar `tablas.json` y aparece sola.
## Anota el resultado de TU partido con su árbitro.
func anotar_arbitro(nombre: String, perfil: String, gf: int, gc: int) -> void:
	if nombre == "":
		return
	var h: Dictionary = arbitros.get(nombre, {"pj": 0, "g": 0, "e": 0, "p": 0, "perfil": perfil})
	h["pj"] = int(h["pj"]) + 1
	var k := "g" if gf > gc else ("e" if gf == gc else "p")
	h[k] = int(h[k]) + 1
	arbitros[nombre] = h

## "Con él: 5 PJ · 1G 2E 2P" o vacío si nunca te dirigió.
func texto_arbitro(nombre: String) -> String:
	if not arbitros.has(nombre):
		return ""
	var h: Dictionary = arbitros[nombre]
	return "Con él: %d PJ · %dG %dE %dP" % [int(h["pj"]), int(h["g"]), int(h["e"]), int(h["p"])]

func catalogo() -> Array:
	var t: Variant = Datos.tabla("VOTACIONES")
	return t if t is Array else []

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

## Revisa las cuentas del club al cerrar la temporada. `pct` es el porcentaje de
## masa salarial sobre ingresos, el mismo que enseña la proyección anual.
func revisar_fair_play(mi: Club, pct: int) -> String:
	if not fpf_activo or mi == null:
		fpf_sancionado = false
		return ""
	if pct <= FPF_UMBRAL:
		if fpf_avisos > 0:
			noticia.emit("Cuentas en regla",
				"La federación cierra el expediente: tu masa salarial vuelve a estar por debajo del %d%% de los ingresos." % FPF_UMBRAL)
		fpf_avisos = 0
		fpf_sancionado = false
		return ""
	fpf_avisos += 1
	if fpf_avisos < FPF_AVISOS:
		noticia.emit("Aviso de fair play financiero",
			"Tu masa salarial se lleva el %d%% de los ingresos, por encima del %d%% permitido. Un año más así y hay sanción." % [pct, FPF_UMBRAL])
		return "aviso"
	var multa := Eco.escalar(FPF_MULTA, float(mi.rep))
	mi.mover_saldo(-multa)
	movimiento.emit("Multa por fair play financiero", -multa)
	fpf_sancionado = true
	castigo_directiva.emit(-3, "el expediente de fair play financiero")
	noticia.emit("Sanción por fair play financiero",
		"Dos temporadas gastando por encima de lo que ingresas. La federación multa al club con %s y te cierra el mercado la próxima ventana: solo podrás fichar libres." % Cesiones.dinero(multa))
	return "sancion"

## Con el expediente abierto solo se puede fichar a coste cero. Lo consulta el
## mercado, igual que el cupo de extranjeros.
func puede_pagar_traspaso() -> bool:
	return not fpf_sancionado
