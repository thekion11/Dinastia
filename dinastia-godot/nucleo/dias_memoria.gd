class_name DiasMemoria
extends RefCounted
## DÍAS DE MEMORIA CON PANTALLA DE REFLEXIÓN (16-11, orden del dueño): cada país tiene fechas de duelo y de recuerdo (`Calendario`, tipo «memoria»).
## La semana en que cae una, el club del jugador (según el PAÍS que eligió) abre un evento breve a pantalla completa (`EventoReflexion`): el nombre
## del día, su fecha, una frase de reflexión y un minuto de silencio. UNA vez por año y día (clave en `Prensa.eventos_vistos`, que se guarda).
## No mueve moral ni confianza: es un acto de respeto, no una decisión (como en `Calendario.semana`: la memoria no sube la moral).
## Día de memoria nuevo en `Calendario.FIJAS` = reflexión nueva aquí (la prueba del banco falla si falta).

## nombre del día (tal cual en `Calendario`) -> frase de reflexión (se traduce con `Idiomas.t`).
const REFLEXIONES := {
	"Día de la Memoria por la Verdad y la Justicia": "Que nunca más se repita. Recordar también es una forma de cuidar a quienes vendrán.",
	"Día del Veterano y de los Caídos en Malvinas": "Jóvenes que lo dieron todo lejos de casa. Hoy los recordamos con gratitud y en silencio.",
	"ANZAC Day": "Más de un siglo después, su sacrificio sigue uniendo a dos países. Que no se olvide.",
	"Conmemoración del golpe de Estado": "Un día para recordar el dolor de tantas familias y para elegir siempre el diálogo y el respeto. Que no se repita.",
	"Remembrance Day": "Las amapolas nos recuerdan a quienes no volvieron. Una pausa de silencio por ellos.",
	"Día de las Víctimas del Terrorismo": "Por las víctimas y sus familias: memoria, dignidad y justicia. El fútbol también guarda silencio.",
	"Victoire 1945": "El fin de la guerra trajo alivio y un compromiso: construir la paz entre los pueblos.",
	"Armistice": "Cuando callaron los cañones, quedó la memoria de millones de vidas perdidas. Un minuto por todas ellas.",
	"Día de Recuerdo del Holocausto": "Millones de personas fueron asesinadas por el odio; seis millones de ellas judías. Recordar es la mejor defensa contra el odio.",
	"Memorial de Hiroshima": "A las 8:15 el mundo cambió. Que el recuerdo de las víctimas nos mantenga del lado de la paz.",
	"Día de los Caídos": "Gratitud en silencio con quienes dieron la vida por el país y con las familias que los lloran.",
	"Día de los Héroes": "Recordamos a quienes cayeron por el país y a las familias que quedaron esperando.",
	"Youth Day": "Miles de jóvenes se levantaron por una educación y un país más justos. Su valentía cambió la historia.",
	"Conmemoración de las Torres Gemelas": "Casi tres mil personas perdieron la vida ese día. Recordamos a las víctimas, a los equipos de rescate y a sus familias.",
	"Memorial Day": "Un día para honrar a quienes murieron sirviendo al país y para acompañar a sus familias.",
}

## El día de memoria que toca esta semana (y no se vio este año) o {}. Claves: clave, nombre, pais, dia, mes, texto (la explicación del mentor), reflexion.
static func pendiente(m: Mundo) -> Dictionary:
	if m == null or m.prensa == null or m.mi_club() == null or not m.temporada_en_curso():
		return {}
	var pais := String(m.mi_club().pais)
	for f: Dictionary in Calendario.de_la_semana(pais, m.anio, m.semana):
		if String(f["tipo"]) != "memoria":
			continue
		var clave := clave_de(pais, m.anio, String(f["nombre"]))
		if m.prensa.eventos_vistos.has(clave):
			continue
		return {"clave": clave, "nombre": String(f["nombre"]), "pais": pais, "dia": int(f["dia"]), "mes": int(f["mes"]),
			"texto": String(f["texto"]), "reflexion": String(REFLEXIONES.get(String(f["nombre"]), String(f["texto"])))}
	return {}

static func clave_de(pais: String, anio: int, nombre: String) -> String:
	return "memoria:%s:%d:%s" % [pais, anio, nombre]

## Lo marca como visto (se guarda con la partida): no vuelve a salir ese año.
static func marcar(m: Mundo, ev: Dictionary) -> void:
	if m != null and m.prensa != null and not m.prensa.eventos_vistos.has(String(ev["clave"])):
		m.prensa.eventos_vistos.append(String(ev["clave"]))
