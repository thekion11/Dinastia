class_name ReglasAscenso
extends RefCounted
## LAS REGLAS REALES DE ASCENSOS Y DESCENSOS (sesión 6, 10-11, orden 35 del dueño: segundas divisiones con su cantidad real).
## Un país que no está aquí usa lo de siempre: bajan y suben `Liga.plazas_descenso` (2 por defecto, editable) y, si la asamblea
## lo aprobó, la promoción del antepenúltimo contra el tercero de la de abajo.
##
##   bajan      cuántos descienden directos de Primera.
##   directos   cuántos de Segunda suben directos (los primeros de la tabla).
##   playoff    (4) los siguientes cuatro juegan un playoff por la plaza que falta: semifinales a ida y vuelta y final a partido único.
##   relegacion el que queda justo encima de los que bajan juega contra el tercero de Segunda (ida y vuelta) la plaza que falta.
## Siempre bajan y suben tantos como bajan (el número de clubes de cada liga no cambia).
const POR_PAIS := {
	"ENG": {"bajan": 3, "directos": 2, "playoff": 4},
	"ESP": {"bajan": 3, "directos": 2, "playoff": 4},
	"ITA": {"bajan": 3, "directos": 2, "playoff": 4},
	"GER": {"bajan": 2, "directos": 2, "relegacion": true},
	"FRA": {"bajan": 2, "directos": 2, "relegacion": true},
	## Argentina: el campeón de la Primera Nacional sube directo y el segundo ascenso sale del reducido (aquí, el playoff de 2.º a 5.º); bajan 2.
	"ARG": {"bajan": 2, "directos": 1, "playoff": 4},
	## Brasil: bajan 4 de la Série A y suben los 4 primeros de la Série B.
	"BRA": {"bajan": 4, "directos": 4},
	## México: la Liga de Expansión es un circuito CERRADO (desde 2020 no hay ascenso ni descenso): bajan 0. Con 0 no se mueve nadie y la segunda
	## división juega su liga aparte; si algún día vuelve el descenso, basta cambiar este número.
	"MEX": {"bajan": 0, "directos": 0},
}

static func de(pais: String) -> Dictionary:
	return POR_PAIS.get(pais, {})

## ¿Este país usa reglas reales? (si no, las generales de `Liga.plazas_descenso`).
static func tiene(pais: String) -> bool:
	return POR_PAIS.has(pais)
