class_name Contratos
extends RefCounted
## CONTRATOS Y JORNADA LABORAL SEGÚN LA LEY (26-9-2026, plan maestro C9). Pedido:
## *"tipos de contrato y horarios de trabajo según la ley de cada país en 2026"*.
##
## Dos cosas distintas, y conviene no mezclarlas:
##   1. LOS FUTBOLISTAS tienen un régimen especial en casi todos los países
##      (contrato de deportista profesional, siempre a plazo fijo). Lo que sí es
##      igual en todo el mundo es la norma FIFA (Reglamento sobre el Estatuto y
##      la Transferencia de Jugadores): un contrato dura como mínimo hasta el
##      final de la temporada y como máximo 5 años, y un menor de 18 no puede
##      firmar por más de 3. Eso se aplica aquí a fichajes y renovaciones.
##   2. EL PERSONAL DEL CLUB (cocina, mantenimiento, oficinas...) sí trabaja con
##      la jornada legal de su país. Menos horas legales = más turnos que cubrir,
##      así que la estructura del club cuesta un poco más (y al revés). Los
##      cambios de ley que caen durante la partida salen como noticia.
##
## La tabla es la jornada ordinaria máxima semanal vigente en 2026, con la
## norma de la que sale. Donde el dato tiene matices se dice en la nota.
## `seguro = false` marca lo que conviene revisar antes de publicar.

signal noticia(titulo: String, cuerpo: String)

const MAX_ANIOS := 5          ## FIFA RSTP, art. 18.2
const MAX_ANIOS_MENOR := 3    ## menores de 18, mismo artículo
## La jornada "neutra": con 44 horas la estructura cuesta lo de siempre.
const HORAS_BASE := 44.0

## pais -> [horas, norma, nota, seguro]
const JORNADA := {
	"CHI": [42, "Ley 21.561 (ley de las 40 horas)", "Bajó de 44 a 42 horas el 26 de abril de 2026; bajará a 40 en abril de 2028.", true],
	"ARG": [48, "Ley 11.544 de jornada de trabajo", "8 horas diarias o 48 semanales.", true],
	"URU": [48, "Ley 5.350 y normas complementarias", "48 horas en industria; en comercio suele ser 44.", true],
	"PAR": [48, "Código del Trabajo", "Jornada diurna de 8 horas diarias.", true],
	"BRA": [44, "Constitución Federal, art. 7", "44 horas semanales y 8 diarias.", true],
	"BOL": [48, "Ley General del Trabajo", "Las mujeres tienen jornada de 40 horas.", true],
	"PER": [48, "Constitución, art. 25", "8 horas diarias o 48 semanales.", true],
	"ECU": [40, "Código del Trabajo", "8 horas diarias y 40 semanales.", true],
	"COL": [44, "Ley 2101 de 2021", "Bajó a 44 en julio de 2025 y baja a 42 el 15 de julio de 2026.", true],
	"VEN": [40, "LOTTT (2012)", "40 horas semanales.", true],
	"MEX": [48, "Constitución, art. 123 (reforma de 2026)", "48 horas en 2026; baja 2 horas al año desde 2027 hasta 40 en 2030 (DOF, 3-3-2026).", true],
	"USA": [40, "Fair Labor Standards Act", "No es un tope: desde la hora 40 se pagan horas extra.", true],
	"ESP": [40, "Estatuto de los Trabajadores, art. 34", "La rebaja a 37,5 horas no salió adelante en 2025.", true],
	"ENG": [48, "Working Time Regulations 1998", "Tope medio de 48 horas; se puede renunciar por escrito.", true],
	"FRA": [35, "Code du travail (ley de las 35 horas)", "Desde la hora 35 son horas extra.", true],
	"GER": [48, "Arbeitszeitgesetz", "8 horas por día laborable (lunes a sábado); lo normal por convenio es menos.", true],
	"ITA": [40, "D.Lgs. 66/2003", "40 horas normales; máximo 48 con extras.", true],
	"JPN": [40, "Ley de Normas Laborales", "8 horas diarias y 40 semanales.", true],
	"KOR": [40, "Ley de Normas Laborales", "40 horas más un máximo de 12 extra (semana de 52).", true],
	"KSA": [48, "Ley del Trabajo", "En Ramadán baja a 36 horas para los musulmanes.", true],
	"EGY": [48, "Ley del Trabajo n.º 14 de 2025", "8 horas diarias o 48 semanales; vigente desde el 1-9-2025.", true],
	"MAR": [44, "Código del Trabajo", "2.288 horas al año fuera del campo (unas 44 semanales).", true],
	"RSA": [45, "Basic Conditions of Employment Act", "45 horas semanales.", true],
	"AUS": [38, "National Employment Standards", "38 horas más horas adicionales razonables.", true],
}

## Cambios de ley con fecha: [pais, anio, mes, dia, horas nuevas, texto].
const CAMBIOS := [
	["CHI", 2026, 4, 26, 42, "La jornada legal en Chile baja de 44 a 42 horas semanales (Ley 21.561)."],
	["COL", 2026, 7, 15, 42, "La jornada legal en Colombia baja de 44 a 42 horas semanales (Ley 2101)."],
	## México (reforma del art. 123, DOF 3-3-2026): dos horas menos cada enero.
	["MEX", 2027, 1, 1, 46, "La jornada legal en México baja de 48 a 46 horas semanales (reforma constitucional de 2026)."],
	["MEX", 2028, 1, 1, 44, "La jornada legal en México baja a 44 horas semanales."],
	["MEX", 2029, 1, 1, 42, "La jornada legal en México baja a 42 horas semanales."],
	["MEX", 2030, 1, 1, 40, "La jornada legal en México llega a las 40 horas semanales."],
	["CHI", 2028, 4, 26, 40, "La jornada legal en Chile llega a 40 horas semanales (Ley 21.561)."],
]

var avisados: Dictionary = {}   ## "pais|anio|mes" -> true

## Las horas legales en una fecha concreta.
static func horas(pais: String, anio: int, semana: int) -> int:
	## Antes del primer cambio de la lista rige la jornada anterior; después,
	## la del último cambio ya ocurrido (la lista va en orden de fecha).
	var antes := {"CHI": 44, "COL": 44}
	var h := int(antes.get(pais, JORNADA.get(pais, [44])[0]))
	var u := Calendario.unix_de(anio, semana, 6)
	for c: Array in CAMBIOS:
		if String(c[0]) == pais and u >= _unix_cambio(c):
			h = int(c[4])
	return h

static func _unix_cambio(c: Array) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": int(c[1]), "month": int(c[2]), "day": int(c[3]),
		"hour": 12, "minute": 0, "second": 0}))

## Cuánto cuesta la estructura del club según las horas legales: suave, un
## 1% por hora de diferencia con 44.
static func factor_estructura(pais: String, anio: int, semana: int) -> float:
	return clampf(1.0 + (HORAS_BASE - float(horas(pais, anio, semana))) * 0.01, 0.9, 1.12)

## El máximo de años que puede firmar un jugador (norma FIFA).
static func max_anios(j: Jugador) -> int:
	return MAX_ANIOS_MENOR if j != null and j.edad < 18 else MAX_ANIOS

static func ajustar_anios(j: Jugador, anios: int) -> int:
	return clampi(anios, 1, max_anios(j))

## El tipo de contrato de un jugador, para la ficha.
static func tipo(j: Jugador, cedido: bool) -> String:
	if cedido:
		return "Cedido"
	if j.edad < 18:
		return "Menor (máx. %d años)" % MAX_ANIOS_MENOR
	return "Profesional (máx. %d)" % MAX_ANIOS

static func texto_jornada(pais: String, anio: int, semana: int) -> String:
	var j: Array = JORNADA.get(pais, [44, "", "", false])
	return "%d h semanales · %s. %s" % [horas(pais, anio, semana), String(j[1]), String(j[2])]

## Una vez por semana: avisa de los cambios de ley que caen en esta semana.
func semana(c: Club, anio: int, sem: int) -> void:
	if c == null:
		return
	var desde := Calendario.unix_de(anio, sem, 0)
	var hasta := Calendario.unix_de(anio, sem, 6)
	for cb: Array in CAMBIOS:
		if String(cb[0]) != c.pais:
			continue
		var uc := _unix_cambio(cb)
		var clave := "%s|%d|%d" % [c.pais, int(cb[1]), int(cb[2])]
		if uc >= desde and uc <= hasta and not avisados.has(clave):
			avisados[clave] = true
			noticia.emit("⚖️ Cambia la jornada laboral", "%s El personal del club trabaja menos horas y hay que cubrir más turnos: la estructura cuesta un poco más." % String(cb[5]))

func a_dic() -> Dictionary:
	return {"av": avisados.keys()}

func desde_dic(d: Dictionary) -> void:
	avisados = {}
	for k: Variant in d.get("av", []):
		avisados[String(k)] = true
