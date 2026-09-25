class_name Clima
extends RefCounted
## EL CLIMA DE CADA PARTIDO, EL DE LA CIUDAD (26-9-2026, plan maestro C1).
##
## Pedido: *"el ambiente del estadio debe ser el mismo de la ciudad por lógica,
## según el clima los jugadores deben sentirse mejor o peor o mencionarse en la
## rueda de prensa"*. Hasta hoy el clima era una opción del DISEÑADOR del
## estadio -se elegía "lluvia" como se elige el color de las butacas- y
## `Partido.clima` (un factor que ya estaba en la fórmula del minuto) valía 1.0
## siempre porque nadie lo escribía.
##
## Ahora sale del PAÍS y de la ÉPOCA DEL AÑO:
##   - la latitud del país (`GLOBO_PAIS`) dice el hemisferio -julio es invierno
##     en Santiago y verano en Madrid- y si es tropical, templado o frío;
##   - la semana dice el mes (la temporada arranca a fines de enero);
##   - un hash de los dos clubes y la fecha decide el día concreto: el mismo
##     partido tiene siempre el mismo tiempo, y NO se consume `Azar`.
##
## Lo que cambia en el campo:
##   - lluvia, tormenta, nieve o niebla traban el partido (menos llegadas para
##     los dos: `factor()`), como ya preveía la fórmula;
##   - el VISITANTE que no está hecho a eso sufre: la altura de La Paz, Quito,
##     Bogotá o Ciudad de México; el calor para quien viene de un país frío; la
##     nieve para quien viene del trópico (`factor_visita()`).

## Capitales a más de 2.000 m: el visitante de tierras bajas lo nota.
const ALTURA := ["BOL", "ECU", "COL", "MEX"]
## Desierto: calor seco, casi nunca llueve.
const DESIERTO := ["KSA", "EGY", "QAT", "UAE"]

static func latitud(pais: String) -> float:
	var g: Variant = Datos.tabla("GLOBO_PAIS")
	if g is Dictionary and (g as Dictionary).has(pais):
		return float((g[pais] as Array)[1])
	return -33.4   ## Santiago: el país por defecto del juego

## El mes (1-12) de una semana de la temporada. La semana 1 es la última de
## enero, como en el calendario de la pantalla principal.
static func mes_de(semana: int) -> int:
	return clampi(1 + int(float(maxi(semana, 1) - 1) * 7.0 / 30.4 + 0.85), 1, 12)

## "verano", "otono", "invierno", "primavera", o "tropical" cerca del ecuador.
static func estacion(pais: String, semana: int) -> String:
	var lat := latitud(pais)
	if absf(lat) < 23.5:
		return "tropical"
	var mes := mes_de(semana)
	if lat < 0.0:
		mes = ((mes + 5) % 12) + 1   ## medio año de desfase en el sur
	if mes in [12, 1, 2]:
		return "invierno"
	if mes in [3, 4, 5]:
		return "primavera"
	if mes in [6, 7, 8]:
		return "verano"
	return "otono"

static func _hash(s: String) -> int:
	return absi(s.hash())

## El tiempo del partido. Devuelve:
##   clave   -> una de EST_CLIMAS (dia, tarde, noche, lluvia, nieve, niebla, tormenta)
##   calor   -> hace calor de verdad (verano templado de día, trópico, desierto)
##   altura  -> se juega en altura
##   texto   -> cómo lo diría el parte: "Lluvia fría de invierno"
static func del_partido(pais: String, semana: int, anio: int, semilla: String) -> Dictionary:
	var est := estacion(pais, semana)
	var frio := absf(latitud(pais)) >= 45.0
	var h := _hash("%s|%d|%d|%s" % [pais, anio, semana, semilla])
	var r := float(h % 1000) / 1000.0
	var r2 := float((h / 1000) % 1000) / 1000.0
	var p_lluvia: float = {"invierno": 0.34, "otono": 0.28, "primavera": 0.22, "verano": 0.10, "tropical": 0.30}[est]
	if pais in DESIERTO:
		p_lluvia = 0.03
	var clave := ""
	if frio and est == "invierno" and r < 0.22:
		clave = "nieve"
	elif r < p_lluvia:
		clave = "tormenta" if (est in ["verano", "tropical"] and r2 < 0.35) else "lluvia"
	elif est in ["otono", "invierno"] and r < p_lluvia + 0.07:
		clave = "niebla"
	else:
		clave = "noche" if r2 < 0.5 else ("tarde" if r2 < 0.8 else "dia")
	var calor: bool = clave in ["dia", "tarde"] and (est in ["verano", "tropical"] or pais in DESIERTO)
	var altura := pais in ALTURA
	var textos := {
		"nieve": "Nieve y frío de invierno", "lluvia": "Lluvia" + (" fría de invierno" if est == "invierno" else ""),
		"tormenta": "Tormenta eléctrica", "niebla": "Niebla cerrada", "noche": "Noche despejada",
		"tarde": "Tarde despejada", "dia": "Mediodía despejado",
	}
	var texto := String(textos[clave])
	if calor:
		texto = "Calor intenso" + (" y seco" if pais in DESIERTO else "")
	if altura:
		texto += ", en la altura"
	return {"clave": clave, "calor": calor, "altura": altura, "texto": texto, "estacion": est}

## Cuánto traba el tiempo el partido, para los dos (es `Partido.clima`).
static func factor(info: Dictionary) -> float:
	var f: float = {"lluvia": 0.93, "tormenta": 0.88, "nieve": 0.85, "niebla": 0.95}.get(String(info.get("clave", "")), 1.0)
	if bool(info.get("calor", false)):
		f *= 0.96
	return f

## Cuánto le cuesta al visitante que no está hecho a esto. El local juega en
## su clima de siempre: esa es parte de la ventaja de jugar en casa.
static func factor_visita(info: Dictionary, pais_visita: String, pais_local: String) -> float:
	if pais_visita == pais_local:
		return 1.0
	var f := 1.0
	if bool(info.get("altura", false)) and not (pais_visita in ALTURA):
		f *= 0.92
	if bool(info.get("calor", false)) and absf(latitud(pais_visita)) >= 40.0:
		f *= 0.95
	if String(info.get("clave", "")) == "nieve" and absf(latitud(pais_visita)) < 23.5:
		f *= 0.93
	return f

## Un emoji para el parte.
static func icono(info: Dictionary) -> String:
	if bool(info.get("calor", false)):
		return "🥵"
	return {"nieve": "❄️", "lluvia": "🌧️", "tormenta": "⛈️", "niebla": "🌫️",
		"noche": "🌙", "tarde": "🌇", "dia": "☀️"}.get(String(info.get("clave", "")), "🌤️")

## ¿Es un tiempo que merece pregunta en la rueda de prensa?
static func es_extremo(info: Dictionary) -> bool:
	return String(info.get("clave", "")) in ["nieve", "lluvia", "tormenta", "niebla"] \
		or bool(info.get("calor", false)) or bool(info.get("altura", false))

## Lo que diría el mentor antes de un partido así ("" si no hay nada que decir).
static func consejo(info: Dictionary, soy_local: bool) -> String:
	if bool(info.get("altura", false)):
		return "En la altura el balón corre más y a la hora de juego falta el aire. " + \
			("Aquí es nuestra ventaja: que el rival lo sufra." if soy_local else "Haz los cambios antes de lo normal.")
	if bool(info.get("calor", false)):
		return "Con este calor, pausa de hidratación y ritmo bajo al principio: el partido se gana en el segundo tiempo."
	match String(info.get("clave", "")):
		"nieve":
			return "Con nieve el balón no rueda: juego directo y centros. Y cuidado con las lesiones."
		"tormenta":
			return "Tormenta: el árbitro puede parar el partido. Que el equipo no se enfríe en la pausa."
		"lluvia":
			return "Campo mojado: el balón patina. Tiros desde lejos y ojo con los resbalones de la defensa."
		"niebla":
			return "Con niebla ni los de la grada verán el partido. Juego corto y seguro."
	return ""
