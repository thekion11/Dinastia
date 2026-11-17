class_name CicloCarrera
extends RefCounted
## LA CARRERA SIN PATINAR (17-11-2026, punto 7 de `docs/04_auditorias/COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`). Qué ciclo
## (parado, trotar o correr) y a qué velocidad de reproducción lleva un futbolista según lo rápido que va. Antes:
##  · el paso de trotar a correr era un umbral seco a 5,2 m/s: quien iba a 5,1-5,3 m/s (muy habitual al acompañar la jugada) cambiaba
##    de ciclo casi cada fotograma, y cada cambio reiniciaba la zancada con un fundido de 0,2 s (el cuerpo «tartamudeaba»);
##  · la escala de reproducción se cortaba en 0,7-1,4: el trote no pasa de 3,4 × 1,4 = 4,8 m/s, así que entre 4,8 y 5,2 m/s los pies
##    se quedaban cortos (patinaban) y por debajo de 2,4 m/s el trote iba más deprisa que el cuerpo (andar «en el sitio»).
## Ahora: histéresis (se pasa a correr a 5,2 m/s y se vuelve a trotar por debajo de 4,5) y un margen de escala que cubre, sin
## patinar, todo el tramo de cada ciclo. Solo cambia lo que se VE (el clip y su velocidad): la huella del motor no cambia.

const PARADO := 0.5     ## m/s
const A_CORRER := 5.2   ## m/s: de trotar a correr (el de siempre)
const A_TROTAR := 4.5   ## m/s: de correr a trotar (histéresis)
## Velocidad (m/s) a la que cada ciclo pisa sin patinar con escala 1, y el margen de escala que se le permite.
const CICLO := {"trotar": [3.4, 0.55, 1.55], "correr": [7.0, 0.6, 1.45], "conducir": [3.6, 0.7, 1.4], "trotar_atras": [2.6, 0.7, 1.4],
	"portero_lateral_der": [2.0, 0.7, 1.4], "portero_lateral_izq": [2.0, 0.7, 1.4]}

## El ciclo de desplazamiento según la velocidad y el que ya lleva (para la histéresis).
static func ciclo(sp: float, actual: String) -> String:
	if sp < PARADO:
		return "parado"
	return "correr" if sp >= (A_TROTAR if actual == "correr" else A_CORRER) else "trotar"

## La escala de reproducción para que la zancada vaya con el cuerpo (1 para lo que no es un ciclo).
static func escala(anim: String, sp: float) -> float:
	var c: Array = CICLO.get(anim, [])
	if c.is_empty():
		return 1.0
	return clampf(sp / float(c[0]), float(c[1]), float(c[2]))

## Lo que patina el pie (m/s): la diferencia entre lo que avanza el cuerpo y lo que avanza la zancada (para las pruebas).
static func patina(anim: String, sp: float) -> float:
	var c: Array = CICLO.get(anim, [])
	return 0.0 if c.is_empty() else absf(sp - float(c[0]) * escala(anim, sp))
