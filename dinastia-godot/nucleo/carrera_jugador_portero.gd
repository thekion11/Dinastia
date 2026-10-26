class_name CarreraPortero
extends RefCounted
## EL PORTERO EN LA CARRERA DE JUGADOR (25-10-2026, aprobado por el dueño).
## Hasta esta fecha el modo era solo de jugador de campo. Un portero no entrena
## tiro ni regate ni se le juzga por los goles: aquí vive lo que le cambia
## -los focos de entreno con sus atributos (`div`, `ref`, `par`, `pos`, `saq`),
## la nota del partido simulado por lo que encaja y sus eventos propios-, para
## que `CarreraJugador` siga igual para el resto de puestos.
##
## Todo con el generador propio de la carrera: no mueve la simulación del mundo.

## Focos de entreno del portero (mismo formato que `CarreraJugador.FOCOS`:
## nombre visible y atributo que sube).
const FOCOS := {
	"estirada": ["🧤 Estirada", "div"], "reflejos": ["⚡ Reflejos", "ref"], "blocaje": ["✋ Blocaje", "par"],
	"colocacion": ["📐 Colocación", "pos"], "saque": ["🦶 Saque", "saq"], "descanso": ["😴 Descanso", ""],
}

## Los focos que tienen sentido para `j` (los de campo si no es portero).
static func focos_para(j: Jugador) -> Dictionary:
	return FOCOS if j != null and j.es_portero() else CarreraJugador.FOCOS

## El foco de partida para un puesto (el portero no entrena «tiro»).
static func foco_inicial(pos_e: String) -> String:
	return "estirada" if pos_e == "POR" else "tiro"

## Goles en contra de `c` en su liga hasta ahora (para saber lo que encajó el
## portero en un partido simulado: se mira antes y después de la semana).
static func goles_en_contra(m: Mundo, c: Club) -> int:
	if c == null:
		return 0
	for l: Liga in m.ligas:
		if l.tabla_puntos.has(c.id):
			return int((l.tabla_puntos[c.id] as Dictionary).get("gc", 0))
	return 0

## La nota del partido simulado de un portero: su nivel, y lo que encajó en vez
## de los goles que marcó (a cero sube; cada gol en contra resta).
static func nota_simulada(j: Jugador, encajados: int, azar: float) -> float:
	var n := 5.9 + float(j.ovr - 55) * 0.04 - float(encajados) * 0.45 + (0.8 if encajados == 0 else 0.0) + azar
	return clampf(n, 4.0, 9.5)

## Eventos únicos del portero (se suman a los de la carrera).
static func eventos(c: CarreraJugador, j: Jugador) -> Array:
	var p: Array = []
	if j == null or not j.es_portero():
		return p
	if not c.hitos.has("primera_valla") and c.vallas_invictas >= 1:
		p.append(c._ev("primera_valla", "Tu primera portería a cero",
			"Noventa minutos sin encajar. Los defensas te rodean al final y te dan palmadas en los guantes.",
			[c._op("Invitas a la defensa a cenar.", {"relacion": 3, "moral": 4}),
			c._op("Subes a las redes la foto de tus guantes.", {"seguidores": 400, "fama": 2})], true))
	if not c.hitos.has("vallas_10") and c.vallas_invictas >= 10:
		p.append(c._ev("vallas_10", "Diez porterías a cero",
			"La prensa ya habla de ti como uno de los porteros más fiables de la liga.",
			[c._op("«El mérito es de toda la defensa.»", {"relacion": 4, "fama": 2}),
			c._op("Pides al club unos guantes con tu nombre.", {"fama": 4, "seguidores": 600})], true))
	if not c.hitos.has("entreno_penales") and int(j.atributos.get("ref", 0)) >= 64:
		p.append(c._ev("entreno_penales", "Los penales del entreno",
			"El delantero estrella te reta a parar cinco penales seguidos después del entrenamiento.",
			[c._op("Aceptas y estudias cómo los tira.", {"attr_ref": 1, "energia": -8}),
			c._op("Prefieres guardar fuerzas para el partido.", {"energia": 6})], true))
	return p
