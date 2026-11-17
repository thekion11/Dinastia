class_name DiasMemoria
extends RefCounted
## DÍAS DE MEMORIA (y, desde el 17-11, de INDEPENDENCIA) CON PANTALLA COMPLETA (16-11, orden del dueño): cada país tiene fechas de duelo y de recuerdo (`Calendario`, tipo «memoria»).
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

## categoría (`CalendarioMemorias`) -> frase de reflexión de los días que no tienen una propia en `REFLEXIONES`.
const CATEGORIAS := {
	"guerra": "Honramos a quienes cayeron y a las familias que los lloran. La paz también se construye recordando.",
	"genocidio": "Recordar a las víctimas es el primer paso para que nunca vuelva a ocurrir.",
	"represion": "Por quienes sufrieron la represión y por las familias que aún buscan verdad y justicia. Que no se repita.",
	"martires": "Gratitud en silencio con quienes dieron la vida por su país y su libertad.",
	"desastre": "Recordamos a las víctimas y a quienes ayudaron en los días más difíciles. La memoria también protege.",
	"terror": "Memoria y respeto para las víctimas y sus familias. Frente al odio, unidad.",
	"independencia": "Hoy se celebra la libertad que tantas personas soñaron y defendieron. Un país entero se reúne, y el fútbol es parte de la fiesta.",
}

static func reflexion_de(f: Dictionary) -> String:
	var n := String(f["nombre"])
	return String(REFLEXIONES[n]) if REFLEXIONES.has(n) else String(CATEGORIAS.get(String(f.get("cat", "")), f["texto"]))

## El día de memoria o de independencia que toca esta semana (y no se vio este año) o {}; la memoria va antes. Claves: clave, tipo ("memoria" o
## "independencia"), nombre, pais, dia, mes, texto (la explicación del mentor), reflexion.
static func pendiente(m: Mundo) -> Dictionary:
	if m == null or m.prensa == null or m.mi_club() == null or not m.temporada_en_curso():
		return {}
	var pais := String(m.mi_club().pais)
	var fechas := Calendario.de_la_semana(pais, m.anio, m.semana)
	for tipo: String in ["memoria", "independencia"]:
		for f: Dictionary in fechas:
			if (tipo == "memoria" and String(f["tipo"]) != "memoria") or (tipo == "independencia" and not CalendarioMemorias.es_independencia(f)):
				continue
			var clave := clave_de(pais, m.anio, String(f["nombre"]))
			if m.prensa.eventos_vistos.has(clave):
				continue
			return {"clave": clave, "tipo": tipo, "nombre": String(f["nombre"]), "pais": pais, "dia": int(f["dia"]), "mes": int(f["mes"]),
				"texto": String(f["texto"]), "reflexion": reflexion_de(f) if tipo == "memoria" else String(CATEGORIAS["independencia"])}
	return {}

static func clave_de(pais: String, anio: int, nombre: String) -> String:
	return "memoria:%s:%d:%s" % [pais, anio, nombre]

## Lo marca como visto (se guarda con la partida): no vuelve a salir ese año.
static func marcar(m: Mundo, ev: Dictionary) -> void:
	if m != null and m.prensa != null and not m.prensa.eventos_vistos.has(String(ev["clave"])):
		m.prensa.eventos_vistos.append(String(ev["clave"]))
