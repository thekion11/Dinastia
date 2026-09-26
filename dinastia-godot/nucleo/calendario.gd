class_name Calendario
extends RefCounted
## EL CALENDARIO DE VERDAD: DÍAS NACIONALES, FECHAS DE MEMORIA, FESTIVIDADES Y
## GRANDES TORNEOS (26-9-2026, plan maestro C13 y C16).
##
## Pedido: *"días nacionales (independencias, 1 de mayo, el 11 de septiembre en
## Chile y en EE. UU.), eventos nacionales e internacionales reales"* y, sobre
## religión, *festividades por país*.
##
## Cuatro tipos de fecha, y cada uno se trata distinto:
##   - FIESTA: independencias y fiestas patrias. Si juegas en casa esa semana,
##     el estadio se llena más y el vestuario lo vive (moral +1).
##   - MEMORIA: fechas de duelo (el 11 de septiembre en Chile por 1973 y en
##     EE. UU. por 2001, el Día de la Memoria argentino, Hiroshima...). Minuto
##     de silencio, brazalete negro, y NADA de fiesta: ni bonus de taquilla ni
##     celebraciones. El texto es sobrio y factual a propósito.
##   - TRABAJO: el 1 de mayo (o el Labor Day de EE. UU.).
##   - FESTIVIDAD: religiosas o tradicionales (Semana Santa, Ramadán, Día de
##     Muertos...). Solo el calendario del país: NUNCA la religión de un jugador,
##     que es un dato personal (regla C16).
## Y los TORNEOS internacionales (Mundial, Juegos Olímpicos, Eurocopa, Copa
## América) con sus sedes cuando son conocidas.
##
## La primera vez que aparece cada fecha, el mentor la explica en una frase.
## Todo es aritmética de fechas: no se consume `Azar`.

signal noticia(titulo: String, cuerpo: String)
signal mentor(titulo: String, texto: String)

## La temporada arranca el 1 de febrero (el lunes de esa semana), igual que la
## tira de días de la pantalla principal.
const INICIO := {"mes": 2, "dia": 1}

## pais -> [[mes, dia, nombre, tipo, explicación del mentor]]
const FIJAS := {
	"ARG": [[3, 24, "Día de la Memoria por la Verdad y la Justicia", "memoria", "Recuerda a las víctimas de la última dictadura militar (1976-1983). Es un día de respeto: minuto de silencio en los estadios."],
		[4, 2, "Día del Veterano y de los Caídos en Malvinas", "memoria", "Homenaje a los soldados de la guerra de 1982. Se guarda silencio antes de los partidos."],
		[5, 25, "Revolución de Mayo", "fiesta", "En 1810 se formó el primer gobierno patrio. Es una de las dos grandes fiestas nacionales."],
		[7, 9, "Día de la Independencia", "fiesta", "El 9 de julio de 1816 se declaró la independencia en Tucumán."]],
	"AUS": [[1, 26, "Australia Day", "fiesta", "Fiesta nacional. Para muchos pueblos originarios es, en cambio, un día de duelo: conviene no pasarse con la celebración."],
		[4, 25, "ANZAC Day", "memoria", "Recuerda a los soldados australianos y neozelandeses caídos en guerra. Minuto de silencio."]],
	"BOL": [[1, 22, "Día del Estado Plurinacional", "fiesta", "Conmemora la fundación del Estado Plurinacional en 2010."],
		[8, 6, "Día de la Independencia", "fiesta", "Bolivia se independizó el 6 de agosto de 1825."]],
	"BRA": [[4, 21, "Tiradentes", "fiesta", "Homenaje a Tiradentes, héroe de la Inconfidencia Mineira."],
		[9, 7, "Dia da Independência", "fiesta", "El 7 de septiembre de 1822 Brasil se separó de Portugal."],
		[11, 15, "Proclamação da República", "fiesta", "En 1889 cayó la monarquía y nació la república."]],
	"CHI": [[5, 21, "Día de las Glorias Navales", "fiesta", "Recuerda el combate naval de Iquique de 1879."],
		[9, 11, "11 de septiembre", "memoria", "El 11 de septiembre de 1973 hubo un golpe de Estado en Chile. Es una fecha de memoria y de respeto por las víctimas: minuto de silencio y nada de celebraciones."],
		[9, 18, "Fiestas Patrias", "fiesta", "Primera Junta Nacional de Gobierno, 1810. Es la gran fiesta de Chile: fondas, cueca y estadios llenos."],
		[9, 19, "Día de las Glorias del Ejército", "fiesta", "Segundo día de las Fiestas Patrias."]],
	"COL": [[7, 20, "Día de la Independencia", "fiesta", "El grito de independencia del 20 de julio de 1810."],
		[8, 7, "Batalla de Boyacá", "fiesta", "La victoria de 1819 que selló la independencia."]],
	"ECU": [[5, 24, "Batalla de Pichincha", "fiesta", "La batalla de 1822 que liberó Quito."],
		[8, 10, "Primer Grito de Independencia", "fiesta", "Quito, 10 de agosto de 1809."]],
	"EGY": [[7, 23, "Día de la Revolución", "fiesta", "Conmemora la revolución de 1952."]],
	"ENG": [[4, 23, "Día de San Jorge", "fiesta", "El patrón de Inglaterra. No es festivo, pero se ven muchas banderas."],
		[11, 11, "Remembrance Day", "memoria", "Recuerda a los caídos en guerra: amapolas en las camisetas y minuto de silencio."]],
	"ESP": [[3, 11, "Día de las Víctimas del Terrorismo", "memoria", "Recuerda a las víctimas del terrorismo; coincide con el aniversario de los atentados de Madrid de 2004. Minuto de silencio."],
		[10, 12, "Fiesta Nacional", "fiesta", "La fiesta nacional de España."],
		[12, 6, "Día de la Constitución", "fiesta", "La Constitución de 1978."]],
	"FRA": [[5, 8, "Victoire 1945", "memoria", "El fin de la Segunda Guerra Mundial en Europa."],
		[7, 14, "Fête nationale", "fiesta", "La toma de la Bastilla, 1789."],
		[11, 11, "Armistice", "memoria", "El armisticio de 1918. Minuto de silencio."]],
	"GER": [[1, 27, "Día de Recuerdo del Holocausto", "memoria", "Aniversario de la liberación de Auschwitz. Los clubes alemanes guardan silencio y organizan actos de memoria."],
		[10, 3, "Tag der Deutschen Einheit", "fiesta", "La reunificación alemana de 1990."]],
	"ITA": [[4, 25, "Festa della Liberazione", "fiesta", "La liberación de 1945."],
		[6, 2, "Festa della Repubblica", "fiesta", "El referéndum de 1946 que dio paso a la república."]],
	"JPN": [[2, 11, "Día de la Fundación Nacional", "fiesta", "Fiesta nacional de Japón."],
		[8, 6, "Memorial de Hiroshima", "memoria", "Aniversario de la bomba atómica de 1945. Minuto de silencio a las 8:15."],
		[8, 13, "Obon", "festividad", "Tradición de honrar a los antepasados: mucha gente vuelve a su pueblo."]],
	"KOR": [[3, 1, "Día del Movimiento de Independencia", "fiesta", "El movimiento del 1 de marzo de 1919."],
		[6, 6, "Día de los Caídos", "memoria", "Honra a quienes murieron por el país. Minuto de silencio."],
		[8, 15, "Gwangbokjeol", "fiesta", "El día de la liberación, 1945."]],
	"KSA": [[2, 22, "Día de la Fundación", "fiesta", "Recuerda la fundación del primer Estado saudí, en 1727."],
		[9, 23, "Día Nacional", "fiesta", "La unificación del reino en 1932."]],
	"MAR": [[7, 30, "Fiesta del Trono", "fiesta", "Aniversario de la llegada al trono del rey."],
		[11, 18, "Día de la Independencia", "fiesta", "La independencia de 1956."]],
	"MEX": [[9, 16, "Día de la Independencia", "fiesta", "El Grito de Dolores de 1810."],
		[11, 2, "Día de Muertos", "festividad", "Tradición mexicana de recordar a los difuntos con altares y flores de cempasúchil."],
		[11, 20, "Revolución Mexicana", "fiesta", "El inicio de la revolución de 1910."]],
	"PAR": [[3, 1, "Día de los Héroes", "memoria", "Recuerda a los caídos en la Guerra de la Triple Alianza."],
		[5, 14, "Independencia", "fiesta", "La independencia del 14 y 15 de mayo de 1811."]],
	"PER": [[7, 28, "Fiestas Patrias", "fiesta", "La independencia proclamada en 1821."]],
	"RSA": [[4, 27, "Freedom Day", "fiesta", "Las primeras elecciones democráticas de 1994."],
		[6, 16, "Youth Day", "memoria", "Recuerda el levantamiento de Soweto de 1976."],
		[9, 24, "Heritage Day", "festividad", "Celebra la diversidad cultural del país."]],
	"URU": [[7, 18, "Jura de la Constitución", "fiesta", "La primera constitución, 1830."],
		[8, 25, "Declaratoria de la Independencia", "fiesta", "Florida, 25 de agosto de 1825."]],
	"USA": [[7, 4, "Independence Day", "fiesta", "La Declaración de Independencia de 1776: fuegos artificiales y barbacoas."],
		[9, 11, "11 de septiembre", "memoria", "Aniversario de los atentados de 2001. Es un día de memoria: minuto de silencio antes de los partidos."]],
	"VEN": [[4, 19, "Declaración de Independencia", "fiesta", "El 19 de abril de 1810."],
		[6, 24, "Batalla de Carabobo", "fiesta", "La batalla de 1821."],
		[7, 5, "Día de la Independencia", "fiesta", "El acta de independencia de 1811."]],
}

## El 1 de mayo es festivo en casi todos; donde no, su equivalente.
const SIN_PRIMERO_DE_MAYO := ["USA", "AUS", "JPN", "ENG"]
## Semana Santa en el calendario (es festiva o se nota en el país).
const SEMANA_SANTA := ["ARG", "AUS", "BOL", "BRA", "CHI", "COL", "ECU", "ENG", "ESP", "GER",
	"ITA", "MEX", "PAR", "PER", "RSA", "URU", "VEN"]
## Ramadán y el fin del ayuno en el calendario del país.
const RAMADAN := ["KSA", "EGY", "MAR"]

var explicadas: Dictionary = {}   ## nombre -> true: el mentor ya la explicó
var ultima_semana: int = -1

## ---------------------------------------------------------------- FECHAS ---

## El unix de un día concreto de la temporada (0 = lunes de la semana).
static func unix_de(anio: int, semana: int, dia: int) -> int:
	var base := int(Time.get_unix_time_from_datetime_dict({"year": anio, "month": INICIO["mes"],
		"day": INICIO["dia"], "hour": 12, "minute": 0, "second": 0}))
	var dow := int(Time.get_datetime_dict_from_unix_time(base).get("weekday", 1))
	base -= ((dow + 6) % 7) * 86400
	return base + ((maxi(semana, 1) - 1) * 7 + dia) * 86400

static func fecha(anio: int, semana: int, dia: int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(unix_de(anio, semana, dia))

static func _unix(anio: int, mes: int, dia: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": anio, "month": mes, "day": dia,
		"hour": 12, "minute": 0, "second": 0}))

static func _md(u: int) -> Array:
	var d := Time.get_datetime_dict_from_unix_time(u)
	return [int(d["month"]), int(d["day"])]

## Domingo de Pascua (algoritmo anónimo gregoriano).
static func pascua(anio: int) -> Array:
	var a := anio % 19
	var b := int(anio / 100.0)
	var c := anio % 100
	var d := int(b / 4.0)
	var e := b % 4
	var f := int((b + 8) / 25.0)
	var g := int((b - f + 1) / 3.0)
	var h := (19 * a + b - d - g + 15) % 30
	var i := int(c / 4.0)
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := int((a + 11 * h + 22 * l) / 451.0)
	var mes := int((h + l - 7 * m + 114) / 31.0)
	var dia := ((h + l - 7 * m + 114) % 31) + 1
	return [mes, dia]

## El 1 de ramadán y el 1 de shawal (fin del ayuno) que caen en ese año, por el
## calendario islámico tabular: acierta con un día de margen, que es lo mismo
## que varía en la realidad según se vea la luna. [[mes, dia, nombre]]
static func ramadan(anio: int) -> Array:
	var r: Array = []
	for ah in range(anio - 580, anio - 576):
		for par: Array in [[9, "Empieza el Ramadán"], [10, "Eid al-Fitr, fin del Ramadán"]]:
			var jd := 1.0 + ceilf(29.5 * float(int(par[0]) - 1)) + float(ah - 1) * 354.0 \
				+ floorf(float(3 + 11 * ah) / 30.0) + 1948439.5 - 1.0
			var u := int(round((jd - 2440587.5) * 86400.0)) + 43200
			var d := Time.get_datetime_dict_from_unix_time(u)
			if int(d["year"]) == anio:
				r.append([int(d["month"]), int(d["day"]), String(par[1])])
	return r

## El n-ésimo día de la semana (0 = lunes) de un mes; n = -1 es el último.
static func _enesimo(anio: int, mes: int, dow: int, n: int) -> int:
	if n > 0:
		var u := _unix(anio, mes, 1)
		var w := (int(Time.get_datetime_dict_from_unix_time(u)["weekday"]) + 6) % 7
		return int(_md(u + (((dow - w + 7) % 7) + (n - 1) * 7) * 86400)[1])
	var sig := _unix(anio + (1 if mes == 12 else 0), 1 if mes == 12 else mes + 1, 1) - 86400
	var w2 := (int(Time.get_datetime_dict_from_unix_time(sig)["weekday"]) + 6) % 7
	return int(_md(sig - ((w2 - dow + 7) % 7) * 86400)[1])

## Todas las fechas de un país en un año: [{mes, dia, nombre, tipo, texto}].
static func del_anio(pais: String, anio: int) -> Array:
	var r: Array = []
	for f: Array in FIJAS.get(pais, []):
		r.append({"mes": int(f[0]), "dia": int(f[1]), "nombre": String(f[2]), "tipo": String(f[3]), "texto": String(f[4])})
	if not SIN_PRIMERO_DE_MAYO.has(pais):
		r.append({"mes": 5, "dia": 1, "nombre": "Día del Trabajador", "tipo": "trabajo",
			"texto": "El 1 de mayo recuerda las luchas por la jornada de 8 horas. En el club, el personal libra y los jugadores suelen dedicarle el partido."})
	if pais == "USA":
		r.append({"mes": 9, "dia": _enesimo(anio, 9, 0, 1), "nombre": "Labor Day", "tipo": "trabajo",
			"texto": "En EE. UU. el día del trabajador es el primer lunes de septiembre, no el 1 de mayo."})
		r.append({"mes": 5, "dia": _enesimo(anio, 5, 0, -1), "nombre": "Memorial Day", "tipo": "memoria",
			"texto": "Último lunes de mayo: recuerda a los militares caídos. Minuto de silencio."})
		r.append({"mes": 11, "dia": _enesimo(anio, 11, 3, 4), "nombre": "Thanksgiving", "tipo": "festividad",
			"texto": "Acción de Gracias: la gran cena familiar del año en EE. UU."})
	if pais == "ENG":
		r.append({"mes": 5, "dia": _enesimo(anio, 5, 0, 1), "nombre": "Early May Bank Holiday", "tipo": "trabajo",
			"texto": "En Inglaterra el feriado de mayo es el primer lunes del mes."})
	if SEMANA_SANTA.has(pais):
		var p := pascua(anio)
		var vs := _md(_unix(anio, int(p[0]), int(p[1])) - 2 * 86400)
		r.append({"mes": int(vs[0]), "dia": int(vs[1]),
			"nombre": "Semana de Turismo" if pais == "URU" else "Semana Santa", "tipo": "festividad",
			"texto": ("En Uruguay, que es un Estado laico, se llama Semana de Turismo: media ciudad se va de vacaciones." if pais == "URU"
				else "Semana Santa: festivos en todo el país, procesiones y mucha gente de viaje. Los horarios de los partidos se acomodan.")})
	if RAMADAN.has(pais):
		for x: Array in ramadan(anio):
			r.append({"mes": int(x[0]), "dia": int(x[1]), "nombre": String(x[2]), "tipo": "festividad",
				"texto": ("Durante el Ramadán los partidos se juegan de noche, después del iftar, la comida que rompe el ayuno."
					if String(x[2]).begins_with("Empieza") else "La fiesta que cierra el mes de ayuno: días festivos y reuniones familiares.")})
	if not RAMADAN.has(pais) and pais != "JPN" and pais != "KOR":
		r.append({"mes": 12, "dia": 25, "nombre": "Navidad", "tipo": "festividad",
			"texto": "Fiesta cristiana y, en muchos países, sobre todo familiar."})
	r.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["mes"]) * 40 + int(a["dia"]) < int(b["mes"]) * 40 + int(b["dia"]))
	return r

## Los grandes torneos de ese año: [{nombre, desde [mes, dia], hasta, sede, sedes}].
static func torneos(anio: int) -> Array:
	var r: Array = []
	if (anio - 2026) % 4 == 0:
		var sedes: Dictionary = {2026: ["USA", "MEX"], 2030: ["ESP", "MAR"], 2034: ["KSA"]}
		r.append({"nombre": "Copa del Mundo", "desde": [6, 11], "hasta": [7, 19],
			"sedes": sedes.get(anio, []), "texto": "El Mundial: cada cuatro años. Los jugadores convocados se van con sus selecciones."})
	if (anio - 2028) % 4 == 0:
		var sedes_jj: Dictionary = {2028: ["USA"], 2032: ["AUS"]}
		r.append({"nombre": "Juegos Olímpicos", "desde": [7, 14], "hasta": [7, 30],
			"sedes": sedes_jj.get(anio, []), "texto": "Los Juegos Olímpicos: en fútbol juegan selecciones sub-23 con tres mayores."})
		r.append({"nombre": "Eurocopa", "desde": [6, 9], "hasta": [7, 9],
			"sedes": [], "texto": "La Eurocopa de selecciones europeas."})
		r.append({"nombre": "Copa América", "desde": [6, 15], "hasta": [7, 12],
			"sedes": [], "texto": "La Copa América, el torneo de selecciones más antiguo del mundo."})
	return r

## Lo que cae en un día concreto (para la tira de días).
static func del_dia(pais: String, anio: int, semana: int, dia: int) -> Array:
	var d := fecha(anio, semana, dia)
	var r: Array = []
	for f: Dictionary in del_anio(pais, int(d["year"])):
		if int(f["mes"]) == int(d["month"]) and int(f["dia"]) == int(d["day"]):
			r.append(f)
	return r

## Lo que cae en toda una semana.
static func de_la_semana(pais: String, anio: int, semana: int) -> Array:
	var r: Array = []
	for i in 7:
		r.append_array(del_dia(pais, anio, semana, i))
	return r

static func icono(tipo: String) -> String:
	match tipo:
		"fiesta": return "🎉"
		"memoria": return "🕯️"
		"trabajo": return "🛠️"
		"festividad": return "🕊️"
	return "📅"

## El torneo en curso esa semana, o {}.
static func torneo_en_curso(anio: int, semana: int) -> Dictionary:
	var u := unix_de(anio, semana, 3)
	for t: Dictionary in torneos(anio):
		var desde := _unix(anio, int(t["desde"][0]), int(t["desde"][1]))
		var hasta := _unix(anio, int(t["hasta"][0]), int(t["hasta"][1]))
		if u >= desde and u <= hasta:
			return t
	return {}

## ---------------------------------------------------------------- EFECTOS ---

## ¿Hay fiesta esta semana? (y ninguna fecha de memoria, que manda sobre todo).
static func factor_publico(pais: String, anio: int, semana: int) -> float:
	var hay_fiesta := false
	for f: Dictionary in de_la_semana(pais, anio, semana):
		if String(f["tipo"]) == "memoria":
			return 1.0
		if String(f["tipo"]) == "fiesta":
			hay_fiesta = true
	return 1.12 if hay_fiesta else 1.0

static func hay_memoria(pais: String, anio: int, semana: int) -> bool:
	for f: Dictionary in de_la_semana(pais, anio, semana):
		if String(f["tipo"]) == "memoria":
			return true
	return false

## Una vez por semana: noticias, moral y la explicación del mentor. Devuelve las
## fechas de la semana (para las pruebas).
func semana(c: Club, anio: int, sem: int) -> Array:
	if c == null or ultima_semana == anio * 60 + sem:
		return []
	ultima_semana = anio * 60 + sem
	var fechas := de_la_semana(c.pais, anio, sem)
	var hubo_fiesta := false
	var hubo_memoria := false
	for f: Dictionary in fechas:
		var nombre := String(f["nombre"])
		var tipo := String(f["tipo"])
		var cuando := "%d/%d" % [int(f["dia"]), int(f["mes"])]
		match tipo:
			"memoria":
				hubo_memoria = true
				noticia.emit("%s %s" % [icono(tipo), nombre],
					"(%s) Los partidos de esta semana empiezan con un minuto de silencio y los jugadores llevan brazalete negro." % cuando)
			"fiesta":
				hubo_fiesta = true
				noticia.emit("%s %s" % [icono(tipo), nombre], "(%s) Semana de fiesta en el país: se esperan estadios llenos." % cuando)
			"trabajo":
				noticia.emit("%s %s" % [icono(tipo), nombre], "(%s) El personal del club libra. El plantel dedica el partido a los trabajadores del club." % cuando)
			_:
				noticia.emit("%s %s" % [icono(tipo), nombre], "(%s) %s" % [cuando, String(f["texto"])])
		if not explicadas.has(nombre):
			explicadas[nombre] = true
			mentor.emit(nombre, String(f["texto"]))
	## La memoria manda: con duelo no hay fiesta que valga.
	if hubo_fiesta and not hubo_memoria:
		for j: Jugador in c.plantilla:
			j.moral = clampi(j.moral + 1, 10, 99)
	var t := torneo_en_curso(anio, sem)
	if not t.is_empty():
		var clave := "%s %d" % [String(t["nombre"]), anio]
		if not explicadas.has(clave):
			explicadas[clave] = true
			var sedes: Array = t["sedes"]
			var en_casa := sedes.has(c.pais)
			noticia.emit("🌍 %s %d" % [String(t["nombre"]), anio],
				("¡El torneo se juega en tu país! Las ciudades sede se llenan de visitantes." if en_casa else "Empieza el torneo. Medio mundo está pendiente."))
			mentor.emit(String(t["nombre"]), String(t["texto"]))
	return fechas

## Las próximas fechas desde esta semana, para el calendario.
static func proximas(pais: String, anio: int, semana: int, cuantas: int = 6) -> Array:
	var hoy := unix_de(anio, semana, 0)
	var r: Array = []
	var todas: Array = []
	for a0 in [anio, anio + 1]:
		for x: Dictionary in del_anio(pais, a0):
			var y := x.duplicate()
			y["anio"] = a0
			todas.append(y)
	for f: Dictionary in todas:
		var a := int(f["anio"])
		var u := _unix(a, int(f["mes"]), int(f["dia"]))
		if u >= hoy:
			var g := f.duplicate()
			g["anio"] = a
			g["faltan"] = int((u - hoy) / 86400.0)
			r.append(g)
		if r.size() >= cuantas:
			break
	return r

func a_dic() -> Dictionary:
	return {"exp": explicadas.keys(), "ult": ultima_semana}

func desde_dic(d: Dictionary) -> void:
	explicadas = {}
	for k: Variant in d.get("exp", []):
		explicadas[String(k)] = true
	ultima_semana = int(d.get("ult", -1))
