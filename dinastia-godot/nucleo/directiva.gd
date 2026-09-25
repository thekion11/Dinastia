class_name Directiva
extends RefCounted
## La directiva: el objetivo que te ponen, la confianza que te tienen y el día
## que te echan.
##
## Es lo que convierte un simulador en un manager. Sin esto puedes acabar
## decimosexto veinte temporadas seguidas y no pasa nada; con esto, cada jornada
## cuenta para algo que no es solo la tabla.
##
## El objetivo NO se elige: te lo pone el club según lo que es. Al que manda le
## exigen el título; al que pelea abajo, salvarse. Es la regla del HTML y es lo
## que hace que dirigir a un grande y a un chico sean dos juegos distintos —
## salvar al Limache vale más que ser cuarto con Colo-Colo.

signal confianza_cambio(antes: int, ahora: int, motivo: String)
signal despedido(motivo: String)
signal objetivo_cumplido(objetivo: String)

## La confianza va de 0 a 100. Por debajo de este número te echan.
const UMBRAL_DESPIDO := 12
const INICIAL := 55

var club: Club
var confianza: int = INICIAL
var meta_puesto: int = 8
var objetivo: String = ""
var temporadas: int = 0
var trofeos: Array[String] = []
var despedido_ya: bool = false

## Si tu ROL actual admite que te echen -"lo_echan" de `Roles.PERMISOS`-.
## `Directiva` no conoce a `Roles` -son decisiones que se apoyan una en otra
## pero no se duplican, ver la cabecera de `roles.gd`-, así que esto es un
## simple booleano que `Mundo` mantiene al día; por defecto en `true` porque
## un DT normal SÍ es despedible y la mayoría de partidas de prueba no tocan
## `Roles` para nada. Al dueño, al ayudante y al interino no los juzga el
## directorio -la confianza les sigue midiendo el apoyo del entorno igual que
## a cualquiera, pero cruzar el umbral no tiene la misma consecuencia-.
var puede_despedirte: bool = true

## "CONSEJEROS DEL DIRECTORIO" del HTML (`CONSEJ`/`contratarConsejero`): hasta
## dos asesores a la vez, cada uno con un efecto fijo. Los cuatro están
## conectados: `dep` y `mkt` (ver Ojeadores.nivel_de() y Finanzas.patrocinio())
## desde el porte original; `fin` y `leg` se enganchan a `Banco` desde el
## 13-9-2026 (`Mundo.avanzar_semana()` fija `banco.descuento_sobregiro`/
## `gracia_liquidacion` según estos dos) -antes de esa fecha decían "sin
## efecto" porque `Banco` todavía no existía, y se quedaron así después de
## que se construyera: un jugador podía pagarle a un consejero por algo que
## de verdad no hacía nada, sin que nada avisara-.
const CONSEJEROS := {
	"dep": {"nombre": "Consejero deportivo", "desc": "Un ojo extra: afina la niebla de ojeo en todo el mundo"},
	"fin": {"nombre": "Consejero financiero", "desc": "Negocia el sobregiro: −35% de interés mientras la caja está en rojo"},
	"mkt": {"nombre": "Consejero de marketing", "desc": "+10% en auspicios y ventas de la tienda"},
	"leg": {"nombre": "Consejero legal", "desc": "Ablanda la mora: 3 semanas más antes de que se liquide el club"},
}
const COSTO_CONTRATAR_CONSEJERO := 600000
const HONORARIO_CONSEJERO_SEMANAL := 15000
const MAX_CONSEJEROS := 2

var consejeros: Dictionary = {}   ## clave de CONSEJEROS -> {nombre, edad, perfil}

func _init(c: Club, puesto_esperado: int) -> void:
	club = c
	_fijar_objetivo(puesto_esperado)

func tiene_consejero(k: String) -> bool:
	return consejeros.has(k)

## Cuánto cuesta la plana de consejeros por semana -se suma al gasto de
## estructura, igual que `25000+15000*count` en el HTML-.
func honorarios_semanales() -> int:
	return HONORARIO_CONSEJERO_SEMANAL * consejeros.size()

## Contrata o cesa a un consejero -toggle, como `contratarConsejero(k)` del
## HTML-. Devuelve "" si se hizo, o el motivo por el que no.
func alternar_consejero(k: String) -> String:
	if not CONSEJEROS.has(k):
		return "Ese tipo de consejero no existe."
	if consejeros.has(k):
		consejeros.erase(k)
		return ""
	if consejeros.size() >= MAX_CONSEJEROS:
		return "El directorio solo tiene sitio para %d consejeros a la vez." % MAX_CONSEJEROS
	if club.saldo < COSTO_CONTRATAR_CONSEJERO:
		return "No hay caja para contratarlo: hacen falta %d." % COSTO_CONTRATAR_CONSEJERO
	club.mover_saldo(-COSTO_CONTRATAR_CONSEJERO)
	var n: Array = Datos.tabla("NOMBRES")
	var a: Array = Datos.tabla("APELLIDOS")
	consejeros[k] = {
		"nombre": "%s %s" % [Azar.uno(n), Azar.uno(a)] if not n.is_empty() and not a.is_empty() else "Consejero",
		"edad": Azar.ent(45, 66),
		"perfil": String(CONSEJEROS[k]["nombre"]),
	}
	return ""

## "EMBAJADOR DEL CLUB" del HTML (`G.embajador`/`candidatasLeyenda()`/
## `contratarEmbajador`/`despedirEmbajador`): una leyenda retirada -de
## cualquier club, no hace falta que sea el tuyo- que vuelve como ídolo
## institucional. Reutiliza `Cantera.leyendas`, que ya guarda exactamente los
## mismos datos (nombre/club_id/pos/nivel) que pedía esta pantalla: no hizo
## falta inventar una lista nueva de "leyendas candidatas".
var embajador: Dictionary = {}   ## {nombre, pos, nivel, sueldo}
const SUELDO_EMBAJADOR_SEMANAL := 20000
const FINIQUITO_EMBAJADOR := 200000
const SOCIOS_POR_SEMANA_EMBAJADOR := 25

## Las tres candidatas del año, determinista -mismo cálculo que
## `candidatasLeyenda()` del HTML: no cambia si recargas la pantalla, solo si
## cambia el año-.
static func candidatas_embajador(leyendas: Array[Dictionary], anio: int) -> Array[Dictionary]:
	if leyendas.is_empty():
		return []
	var n := leyendas.size()
	var indices := [anio % n, (anio * 3 + 1) % n, (anio * 7 + 2) % n]
	var vistos: Array[String] = []
	var salida: Array[Dictionary] = []
	for i: int in indices:
		var l: Dictionary = leyendas[i]
		var nombre := String(l.get("nombre", ""))
		if nombre != "" and not vistos.has(nombre):
			vistos.append(nombre)
			salida.append(l)
	return salida

## Ficha a una candidata. Devuelve "" si se hizo, o el motivo por el que no.
func contratar_embajador(l: Dictionary) -> String:
	var costo := 400000 + int(l.get("nivel", 80)) * 8000
	if club.saldo < costo:
		return "No hay caja para ficharlo: hacen falta %d." % costo
	club.mover_saldo(-costo)
	embajador = {
		"nombre": String(l.get("nombre", "")), "pos": String(l.get("pos", "")),
		"nivel": int(l.get("nivel", 80)), "sueldo": SUELDO_EMBAJADOR_SEMANAL,
	}
	return ""

func cesar_embajador() -> String:
	if embajador.is_empty():
		return "No tienes embajador."
	if club.saldo < FINIQUITO_EMBAJADOR:
		return "No hay caja para el finiquito: hacen falta %d." % FINIQUITO_EMBAJADOR
	club.mover_saldo(-FINIQUITO_EMBAJADOR)
	embajador = {}
	return ""

## Guarda consejeros Y embajador juntos: son los dos "asientos institucionales"
## que vive esta clase y no `Mundo`. La clave de guardado sigue llamándose
## "consejeros" por compatibilidad con los guardados de la tanda anterior a
## esta -son solo de esta sesión de desarrollo, pero total, ya que se puede no
## romperlos-: si no trae ninguna de las dos claves (guardado más viejo
## todavía) el dict entero era la tabla de consejeros.
func a_dic() -> Dictionary:
	return {"consejeros": consejeros.duplicate(true), "embajador": embajador.duplicate()}

func desde_dic(datos: Dictionary) -> void:
	if datos.has("consejeros") or datos.has("embajador"):
		consejeros = (datos.get("consejeros", {}) as Dictionary).duplicate(true)
		embajador = (datos.get("embajador", {}) as Dictionary).duplicate()
	else:
		consejeros = datos.duplicate(true)

## El objetivo sale del puesto que le corresponde al club por su reputación, no
## de su posición actual: si no, un grande que empieza mal se libraría de que le
## exijan.
func _fijar_objetivo(rank: int) -> void:
	if club.division == 2:
		objetivo = "Ascender a Primera" if rank <= 3 else "Pelear el ascenso (top 6)"
		meta_puesto = 2 if rank <= 3 else 6
	elif rank <= 2:
		objetivo = "Salir campeón"
		meta_puesto = 1
	elif rank <= 6:
		objetivo = "Clasificar a copa internacional (top 4)"
		meta_puesto = 4
	elif rank <= 12:
		objetivo = "Terminar en la mitad superior (top 8)"
		meta_puesto = 8
	else:
		objetivo = "Evitar el descenso"
		meta_puesto = 14

func mover_confianza(delta: int, motivo: String) -> void:
	if despedido_ya:
		return
	var antes := confianza
	confianza = clampi(confianza + delta, 0, 100)
	if confianza != antes:
		confianza_cambio.emit(antes, confianza, motivo)
	if puede_despedirte and confianza <= UMBRAL_DESPIDO:
		despedido_ya = true
		despedido.emit(motivo)

## Después de cada partido. Ganar suma, perder resta, y el tamaño del rival
## importa: ganarle al líder no vale lo mismo que ganarle al colista.
func tras_partido(goles_propios: int, goles_rival: int, rival: Club) -> void:
	var brecha := float(rival.rep - club.rep) / 10.0
	if goles_propios > goles_rival:
		mover_confianza(int(round(clampf(3.0 + brecha, 1.0, 8.0))), "victoria ante %s" % rival.nombre)
	elif goles_propios < goles_rival:
		mover_confianza(-int(round(clampf(3.0 - brecha, 1.0, 8.0))), "derrota ante %s" % rival.nombre)
	else:
		## El empate no es neutro: contra uno peor que tú es un disgusto.
		mover_confianza(1 if brecha > 0.5 else (-1 if brecha < -0.5 else 0),
			"empate ante %s" % rival.nombre)

## El cierre de temporada, que es donde de verdad se decide.
##
## Cumplir el objetivo repone confianza; fallarlo cuesta caro, y cuanto más lejos
## quedes, más. Es lo que hace que un año malo se pueda remontar y dos no.
func tras_temporada(puesto: int, campeon_liga: bool, campeon_copa: bool) -> Dictionary:
	temporadas += 1
	var cumplido := puesto <= meta_puesto
	var delta := 0
	if cumplido:
		delta = 18 + (meta_puesto - puesto) * 2
		objetivo_cumplido.emit(objetivo)
	else:
		delta = -(10 + (puesto - meta_puesto) * 3)
	if campeon_liga:
		delta += 25
		trofeos.append("Liga %d" % temporadas)
	if campeon_copa:
		delta += 15
		trofeos.append("Copa %d" % temporadas)
	mover_confianza(delta, "cierre de temporada")
	return {
		"cumplido": cumplido, "puesto": puesto, "meta": meta_puesto,
		"objetivo": objetivo, "delta": delta, "confianza": confianza,
		"despedido": despedido_ya,
	}

## Cómo lo ve la directiva ahora mismo, en una frase. Es lo que se enseña en
## pantalla: un número sin traducir no le dice nada a nadie.
func humor() -> String:
	if confianza >= 85: return "La directiva te firmaría diez años más"
	if confianza >= 65: return "La directiva está tranquila contigo"
	if confianza >= 45: return "La directiva observa, sin más"
	if confianza >= 25: return "La directiva empieza a impacientarse"
	if confianza > UMBRAL_DESPIDO: return "Tu puesto está en el aire"
	return "Estás despedido"
