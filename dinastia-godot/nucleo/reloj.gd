class_name Reloj
extends RefCounted
## EL RELOJ ÚNICO (fase 0 del guion, 25-10-2026). Plan del lunes §2.1, «Reloj y
## agenda únicos»: *un solo tiempo para menú central y mundo 3D; jornada laboral,
## horas extra, días libres, adelantar el día con el teléfono, esperar*.
##
## Hasta hoy el juego solo conocía la SEMANA (`Mundo.semana`): todo se simula de
## semana en semana. El reloj añade DENTRO de esa semana el día (0 = lunes) y la
## hora (minuto del día), sin quitarle a la semana la última palabra:
##   - LA SEMANA LA MANDA EL MUNDO. El reloj nunca avanza la semana por su cuenta:
##     si se le pide pasar del domingo a las 23:59 se queda ahí (el TOPE) y avisa
##     con `semana_agotada`; quien lo use (la interfaz, en la fase 3) llama
##     entonces a `Mundo.avanzar_semana()` como siempre. Así el avance de semana de
##     siempre da EXACTAMENTE el mismo resultado: el reloj solo escucha.
##   - Cuando la semana avanza (señal `Mundo.semana_avanzada`, o al leer el reloj
##     tras `nueva_temporada()`/una carga), el reloj salta al lunes a las 08:00 de
##     la semana nueva y dice cuántos minutos se saltaron (`semana_cambiada`): las
##     necesidades lo usan para saber si esa semana se vivió o se dio por vivida.
##   - Los días y las horas salen de `Calendario.unix_de()`, la misma cuenta que la
##     tira de días de la pantalla principal (la temporada arranca el lunes de la
##     semana del 1 de febrero).
##
## Todo es aritmética entera: no consume `Azar` ni lee la hora del sistema, así
## que dos partidas con la misma semilla tienen el mismo reloj.

## Cada vez que pasa tiempo (en tramos que nunca cruzan una hora en punto). Las
## `Necesidades` lo escuchan para evolucionar según lo que se estaba haciendo.
signal tiempo_pasado(minutos: int, actividad: String)
## Al llegar a una hora en punto (0-23) del día `dia` (0 = lunes).
signal hora_cambiada(hora: int, dia: int)
## Al empezar un día nuevo dentro de la semana (también el lunes de cada semana).
signal dia_cambiado(dia: int, semana: int, anio: int)
## Al empezar una semana nueva. `minutos_saltados`: tiempo que pasó sin vivirse
## entre donde estaba el reloj y el lunes 08:00 nuevo (10.080 si la semana se
## avanzó desde el menú sin tocar el reloj).
signal semana_cambiada(semana: int, anio: int, minutos_saltados: int)
## Se pidió pasar del domingo 23:59: la semana ya no da más de sí.
signal semana_agotada()

const MINUTOS_HORA := 60
const MINUTOS_DIA := 1440
const DIAS_SEMANA := 7
const MINUTOS_SEMANA := MINUTOS_DIA * DIAS_SEMANA
## La semana «empieza» el lunes a las 08:00: es la hora a la que se llega al
## club, y donde se queda el reloj mientras se juega solo desde el menú.
const HORA_INICIO := 8
## El último minuto vivible de la semana (domingo 23:59), contado desde el lunes 00:00.
const TOPE_SEMANA := MINUTOS_SEMANA - 1
## La jornada laboral del club (para distinguir trabajo de horas extra).
const JORNADA_INICIO := 9
const JORNADA_FIN := 18
## La noche, para la luz del mundo 3D y para lo que no se puede hacer a deshoras.
const NOCHE_DESDE := 21
const NOCHE_HASTA := 7

## LA RUTINA de un día normal: [desde (minuto del día), actividad]. Es lo que hace
## el DT cuando el día se adelanta sin vivirlo (`avanzar_dias`, el teléfono):
## duerme ocho horas, come tres veces y trabaja la jornada. Con estas tasas
## (`Necesidades.TASAS`) un día de rutina deja la energía y el hambre donde
## estaban: adelantar días no castiga, saltarse comidas o el sueño sí.
const RUTINA := [
	[0, "dormir"], [420, "comer"], [450, "libre"], [540, "trabajo"], [780, "comer"],
	[810, "trabajo"], [1080, "libre"], [1230, "comer"], [1260, "libre"], [1380, "dormir"],
]

## La semana a la que pertenece el reloj (-1 = aún sin sincronizar con el mundo).
var anio: int = -1
var semana: int = -1
## 0 = lunes … 6 = domingo.
var dia: int = 0
## Minuto del día, 0..1439.
var minuto: int = HORA_INICIO * MINUTOS_HORA
## Para no repetir `semana_agotada` en cada intento de pasar del tope.
var _agotada_avisada: bool = false
## El mundo del que se lee la semana (débil: el mundo es el dueño del reloj).
var _mundo: WeakRef = null

## Engancha el reloj a la señal `semana_avanzada(semana, anio)` del mundo. Se
## pasa la SEÑAL y no el mundo para que el reloj no dependa de la clase `Mundo`.
func seguir_a(senal_semana: Signal) -> void:
	_mundo = weakref(senal_semana.get_object())
	if not senal_semana.is_connected(_al_avanzar_semana):
		senal_semana.connect(_al_avanzar_semana)

func _al_avanzar_semana(nueva_semana: int, nuevo_anio: int) -> void:
	sincronizar(nuevo_anio, nueva_semana)

## Lee la semana del mundo y, si cambió (p. ej. tras `nueva_temporada()`, que
## pone `semana = 1` sin emitir señal), salta a ella. Lo llaman todas las
## lecturas públicas: el reloj nunca enseña una semana vieja.
func _al_dia() -> void:
	var m: Object = _mundo.get_ref() if _mundo != null else null
	if m != null:
		sincronizar(int(m.get("anio")), int(m.get("semana")))

## Pone el reloj en la semana `(a, s)`. Si ya estaba en ella no hace nada. La
## primera vez (reloj recién creado) es silenciosa: no es que haya pasado
## tiempo, es que el reloj aún no sabía en qué semana vivía.
func sincronizar(a: int, s: int) -> bool:
	if a == anio and s == semana:
		return false
	var primera := anio < 0 or semana < 0
	var saltados := 0
	if not primera:
		var antes := Calendario.unix_de(anio, semana, dia) + minuto * 60
		var despues := Calendario.unix_de(a, s, 0) + HORA_INICIO * MINUTOS_HORA * 60
		saltados = maxi(0, int((despues - antes) / 60))
	anio = a
	semana = s
	dia = 0
	minuto = HORA_INICIO * MINUTOS_HORA
	_agotada_avisada = false
	if not primera:
		semana_cambiada.emit(semana, anio, saltados)
		dia_cambiado.emit(dia, semana, anio)
		hora_cambiada.emit(HORA_INICIO, dia)
	return true

## ------------------------------------------------------------- LECTURAS ---

func hora() -> int:
	_al_dia()
	return minuto / MINUTOS_HORA

func minutos_de_la_hora() -> int:
	_al_dia()
	return minuto % MINUTOS_HORA

## La hora con decimales (8.5 = 08:30), para la luz del ciclo día/noche en 3D.
func hora_decimal() -> float:
	_al_dia()
	return float(minuto) / float(MINUTOS_HORA)

## «08:05». Sin día ni idioma: el nombre del día lo pone la interfaz con `Idiomas.t`.
func texto_hora() -> String:
	_al_dia()
	return "%02d:%02d" % [minuto / MINUTOS_HORA, minuto % MINUTOS_HORA]

## Minutos desde el lunes 00:00 de la semana del reloj.
func minuto_de_semana() -> int:
	_al_dia()
	return dia * MINUTOS_DIA + minuto

func minutos_hasta_fin_de_semana() -> int:
	return TOPE_SEMANA - minuto_de_semana()

## La fecha de verdad (dict de `Time`: year, month, day, weekday…), con la hora del reloj.
func fecha() -> Dictionary:
	_al_dia()
	var u := Calendario.unix_de(maxi(anio, 1970), maxi(semana, 1), dia)
	## `unix_de` da el día a las 12:00; se corrige a la hora del reloj.
	u += (minuto - 12 * MINUTOS_HORA) * 60
	return Time.get_datetime_dict_from_unix_time(u)

func es_jornada_laboral() -> bool:
	var h := hora()
	return dia <= 4 and h >= JORNADA_INICIO and h < JORNADA_FIN

func es_de_noche() -> bool:
	var h := hora()
	return h >= NOCHE_DESDE or h < NOCHE_HASTA

func es_fin_de_semana() -> bool:
	_al_dia()
	return dia >= 5

func agotada() -> bool:
	return minuto_de_semana() >= TOPE_SEMANA

## Lo que toca a esta hora según la rutina (para la agenda y para `avanzar_dias`).
static func actividad_de_rutina(minuto_del_dia: int) -> String:
	var act := String(RUTINA[0][1])
	for tramo: Array in RUTINA:
		if minuto_del_dia >= int(tramo[0]):
			act = String(tramo[1])
	return act

## Hasta qué minuto del día dura el tramo de rutina que empieza en `minuto_del_dia`.
static func _fin_tramo(minuto_del_dia: int) -> int:
	for tramo: Array in RUTINA:
		if int(tramo[0]) > minuto_del_dia:
			return int(tramo[0])
	return MINUTOS_DIA

## -------------------------------------------------------------- AVANZAR ---

## Hace pasar `n` minutos haciendo `actividad` ("libre", "trabajo", "dormir",
## "comer"… ver `Necesidades.TASAS`). Avanza en tramos que acaban en cada hora en
## punto, para que las necesidades y quien escuche `hora_cambiada` vean el día
## tal como pasa. Nunca cruza el domingo 23:59 (TOPE): devuelve los minutos que
## de verdad pasaron.
func avanzar_minutos(n: int, actividad: String = "libre") -> int:
	_al_dia()
	var quedan := maxi(n, 0)
	var pasados := 0
	while quedan > 0:
		var hasta_tope := TOPE_SEMANA - (dia * MINUTOS_DIA + minuto)
		if hasta_tope <= 0:
			break
		var hasta_hora := MINUTOS_HORA - minuto % MINUTOS_HORA
		var paso := mini(quedan, mini(hasta_hora, hasta_tope))
		minuto += paso
		quedan -= paso
		pasados += paso
		tiempo_pasado.emit(paso, actividad)
		if minuto >= MINUTOS_DIA:
			minuto -= MINUTOS_DIA
			dia += 1
			hora_cambiada.emit(0, dia)
			dia_cambiado.emit(dia, semana, anio)
		elif minuto % MINUTOS_HORA == 0:
			hora_cambiada.emit(minuto / MINUTOS_HORA, dia)
	if quedan > 0 and not _agotada_avisada:
		_agotada_avisada = true
		semana_agotada.emit()
	return pasados

func avanzar_horas(h: int, actividad: String = "libre") -> int:
	return avanzar_minutos(h * MINUTOS_HORA, actividad)

## Espera haciendo `actividad` hasta la próxima vez que el reloj marque `hora_objetivo`
## en punto (si ya es esa hora en punto, espera un día entero). «Esperar» del plan.
func esperar_hasta(hora_objetivo: int, actividad: String = "libre") -> int:
	_al_dia()
	var objetivo := clampi(hora_objetivo, 0, 23) * MINUTOS_HORA
	var falta := (objetivo - minuto + MINUTOS_DIA) % MINUTOS_DIA
	if falta == 0:
		falta = MINUTOS_DIA
	return avanzar_minutos(falta, actividad)

## Adelanta `n` días enteros siguiendo la RUTINA (dormir, comer, trabajar): es
## «adelantar el día con el teléfono». Si se topa con el fin de la semana, para
## ahí. Devuelve los minutos que pasaron.
func avanzar_dias(n: int) -> int:
	_al_dia()
	var quedan := maxi(n, 0) * MINUTOS_DIA
	var pasados := 0
	while quedan > 0 and not agotada():
		var fin := _fin_tramo(minuto)
		var tramo := mini(quedan, fin - minuto)
		var hecho := avanzar_minutos(tramo, actividad_de_rutina(minuto))
		pasados += hecho
		quedan -= hecho
		if hecho < tramo:
			break
	if quedan > 0 and not _agotada_avisada:
		_agotada_avisada = true
		semana_agotada.emit()
	return pasados

## ------------------------------------------------------------- GUARDADO ---

func a_dic() -> Dictionary:
	_al_dia()
	return {"anio": anio, "sem": semana, "dia": dia, "min": minuto}

## Silencioso: cargar no es que pase el tiempo. Un guardado sin reloj (anterior a
## la fase 0) deja el reloj sin sincronizar y la primera lectura lo pone en el
## lunes 08:00 de la semana guardada.
func desde_dic(d: Dictionary) -> void:
	anio = int(d.get("anio", -1))
	semana = int(d.get("sem", -1))
	dia = clampi(int(d.get("dia", 0)), 0, DIAS_SEMANA - 1)
	minuto = clampi(int(d.get("min", HORA_INICIO * MINUTOS_HORA)), 0, MINUTOS_DIA - 1)
	if dia * MINUTOS_DIA + minuto > TOPE_SEMANA:
		minuto = TOPE_SEMANA - dia * MINUTOS_DIA
	_agotada_avisada = false
