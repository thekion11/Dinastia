class_name Copa
extends RefCounted
## Un torneo de eliminación directa: octavos, cuartos, semifinal y final.
##
## La diferencia con la liga no es solo el formato. En una liga un mal día se
## arregla la semana siguiente; aquí no hay semana siguiente. Por eso el partido
## de copa usa la tanda de penales que ya trae `Partido`, y por eso la final se
## juega en cancha neutral, sin el 1,08 de local: es lo único que separa una
## final de un partido cualquiera.
##
## El premio es FIJO, no escalado al tamaño del club. Es a propósito y viene del
## HTML: 220.000 valen lo mismo para Colo-Colo que para Deportes Limache, y por
## eso ganar la copa cambia el año de un club chico y a uno grande le da igual.
## Escalarlo lo convertiría en un ingreso más.

signal ronda_terminada(nombre: String, resultados: Array)
signal campeon_proclamado(club: Club)
## El sorteo de una eliminatoria, para la cinemática del bombo. Se emite cuando
## los cruces ya están decididos y ANTES de jugarlos: es el momento en que el
## jugador se entera de con quién le toca, que es de lo poco del año que pasa sin
## que él pueda hacer nada. `parejas` es un Array de [Club, Club].
signal sorteo_eliminatoria(ronda: String, parejas: Array)

## Los cruces de la ronda que viene, en pares consecutivos de `vivos`.
func cruces() -> Array:
	var salida: Array = []
	for i in range(0, vivos.size() - 1, 2):
		salida.append([vivos[i], vivos[i + 1]])
	return salida

## Avisa del sorteo de la ronda actual. Lo llama quien haga avanzar el torneo,
## no `jugar_ronda()`: la cinemática tiene que salir ANTES de que se juegue.
func anunciar_sorteo() -> void:
	if en_curso():
		sorteo_eliminatoria.emit(nombre_de_ronda(), cruces())

const PREMIO := 220000

## Lo que pesa el premio de ESTA copa. La FA Cup y la Copa del Rey valen el
## premio entero; una copa de liga, algo mas de la mitad. Es lo que hace que
## las dos copas de un mismo pais no se sientan igual de importantes.
var peso_premio: float = 1.0

var nombre: String = "Copa"
var participantes: Array[Club] = []
var vivos: Array[Club] = []
var ronda: int = 0
var campeon: Club = null
var historial: Array[Dictionary] = []

func _init(_nombre: String = "Copa") -> void:
	nombre = _nombre

## Arranca el torneo con estos clubes. Se recorta a la potencia de dos más
## cercana: con 24 equipos habría que inventar eliminatorias previas y byes, y un
## bye mal repartido es la forma más fácil de que el sorteo parezca amañado.
func preparar(clubes: Array[Club]) -> void:
	participantes = clubes.duplicate()
	Azar.barajar(participantes)
	var n := 2
	while n * 2 <= participantes.size():
		n *= 2
	participantes.resize(n)
	vivos = participantes.duplicate()
	ronda = 0
	campeon = null
	historial.clear()

func en_curso() -> bool:
	return campeon == null and vivos.size() >= 2

## Cómo se llama la ronda que toca, según cuántos quedan vivos.
func nombre_de_ronda() -> String:
	match vivos.size():
		2: return "Final"
		4: return "Semifinales"
		8: return "Cuartos de final"
		16: return "Octavos de final"
		32: return "Dieciseisavos"
		_: return "Ronda de %d" % vivos.size()

## El cruce en el que está tu club, o vacío si ya cayó.
func emparejamiento_de(c: Club) -> Array:
	if not en_curso():
		return []
	for i in range(0, vivos.size() - 1, 2):
		if vivos[i] == c or vivos[i + 1] == c:
			return [vivos[i], vivos[i + 1]]
	return []

## Juega la ronda entera. `ya_jugado` es el partido que el entrenador acaba de
## dirigir en directo, igual que en la liga: no se vuelve a simular.
func jugar_ronda(ya_jugado: Partido = null) -> Array:
	if not en_curso():
		return []
	var titulo := nombre_de_ronda()
	var final := vivos.size() == 2
	var pasan: Array[Club] = []
	var resultados: Array = []
	for i in range(0, vivos.size() - 1, 2):
		var a: Club = vivos[i]
		var b: Club = vivos[i + 1]
		var gl := 0
		var gv := 0
		var penales: Array = []
		if ya_jugado != null and ya_jugado.local == a and ya_jugado.visita == b:
			gl = ya_jugado.goles_local
			gv = ya_jugado.goles_visita
			if gl == gv:
				penales = ya_jugado.penales()
		else:
			## La final se juega en cancha neutral: sin empuje de local.
			var p := Partido.new(a, b, final)
			var r := p.simular()
			gl = r["local"]
			gv = r["visita"]
			if gl == gv:
				penales = p.penales()
		var gana: Club = a
		if gv > gl:
			gana = b
		elif gl == gv and not penales.is_empty() and int(penales[1]) > int(penales[0]):
			gana = b
		pasan.append(gana)
		resultados.append({
			"local": a, "visita": b, "gl": gl, "gv": gv,
			"penales": penales, "pasa": gana, "ronda": titulo,
		})
	historial.append({"ronda": titulo, "resultados": resultados})
	vivos = pasan
	ronda += 1
	ronda_terminada.emit(titulo, resultados)
	if vivos.size() == 1:
		campeon = vivos[0]
		campeon.mover_saldo(int(round(float(PREMIO) * peso_premio)))
		campeon_proclamado.emit(campeon)
	else:
		## Los que pasan ya tienen rival para la ronda siguiente: eso es un
		## sorteo nuevo, y el usuario pidió la cinemática en CADA eliminatoria,
		## no solo al abrir el cuadro.
		anunciar_sorteo()
	return resultados

func jugar_hasta_el_final() -> Club:
	while en_curso():
		jugar_ronda()
	return campeon

# ---------------------------------------------------------------------------
#  LAS COPAS DE CADA PAÍS
# ---------------------------------------------------------------------------
#
# «El sistema de ligas y de copa debería ser igual al real: en Inglaterra está
# la Carabao y la FA Cup, en España la Copa del Rey». Lo pedía el documento de
# instrucciones y hasta ahora todos los países jugaban una genérica «Copa de
# Chile», «Copa de Inglaterra», con el mismo formato en todas partes.
#
# CADA PAÍS TIENE SU CALENDARIO DE VERDAD: unos juegan una copa, Inglaterra dos
# —la FA Cup abierta a todos y la Carabao de liga—, y el nombre no es un adorno:
# es lo que hace que ganar la Copa del Rey se sienta como ganar la Copa del Rey.
#
# El formato queda igual para todas -eliminatoria directa- porque replicar el
# sistema argentino de verdad, con sus dos torneos y sus zonas, es rehacer el
# calendario entero, y eso no cabe en una tabla de nombres.
const COPAS_POR_PAIS := {
	"ENG": [["FA Cup", 1.0], ["Copa de la Liga", 0.55]],
	"ESP": [["Copa del Rey", 1.0]],
	"ITA": [["Copa de Italia", 1.0]],
	"GER": [["Copa de Alemania", 1.0]],
	"FRA": [["Copa de Francia", 1.0]],
	"ARG": [["Copa Argentina", 1.0], ["Trofeo de Campeones", 0.5]],
	"BRA": [["Copa de Brasil", 1.0]],
	"CHI": [["Copa Chile", 1.0]],
	"URU": [["Copa Uruguay", 1.0]],
	"COL": [["Copa Colombia", 1.0]],
	"PER": [["Copa Perú", 1.0]],
	"MEX": [["Copa MX", 1.0]],
	"USA": [["US Open Cup", 1.0]],
	"JPN": [["Copa del Emperador", 1.0], ["Copa de la Liga", 0.55]],
	"KOR": [["Copa de Corea", 1.0]],
	"KSA": [["Copa del Rey de Campeones", 1.0]],
	"EGY": [["Copa de Egipto", 1.0]],
	"MAR": [["Copa del Trono", 1.0]],
	"RSA": [["Copa Nedbank", 1.0]],
	"AUS": [["Copa de Australia", 1.0]],
}

## Las copas que se juegan en un país: [nombre, peso del premio]. Si el país no
## está en la tabla se le pone una genérica, que es lo que había antes para
## todos y sigue siendo mejor que quedarse sin copa.
static func copas_de(pais: String, nombre_pais: String) -> Array:
	if COPAS_POR_PAIS.has(pais):
		return COPAS_POR_PAIS[pais]
	return [["Copa de %s" % nombre_pais, 1.0]]
