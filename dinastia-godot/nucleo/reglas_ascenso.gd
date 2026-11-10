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
}

static func de(pais: String) -> Dictionary:
	return POR_PAIS.get(pais, {})

## ¿Este país usa reglas reales? (si no, las generales de `Liga.plazas_descenso`).
static func tiene(pais: String) -> bool:
	return POR_PAIS.has(pais)
