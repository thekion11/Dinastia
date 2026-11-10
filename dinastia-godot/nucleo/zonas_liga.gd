class_name ZonasLiga
extends RefCounted
## ZONAS Y CONFERENCIAS REALES (10-11-2026) de las ligas con fase final (`FaseFinalLiga`), por la POSICIÓN del club en la tabla de su liga
## (el mismo orden en la base ficticia y en el pack, así sirve con los dos nombres). 0 = zona A / Conferencia Este, 1 = zona B / Oeste.
## ARG: sorteo del 10-12-2025 para el Apertura y el Clausura 2026 (Tiempo Argentino). USA: las conferencias de la MLS 2025 (15 y 15).
## Si la liga no tiene exactamente esos clubes (se fundó uno), `FaseFinalLiga` reparte por id como antes.
const ZONAS := {
	"ARG": [0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1],
	"USA": [0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 1],
}

## La zona de cada club de la liga (id -> 0/1), o {} si no hay tabla para este país o los clubes no cuadran.
static func de(l: Liga) -> Dictionary:
	var t: Array = ZONAS.get(l.pais, [])
	if t.is_empty() or t.size() != l.clubes.size():
		return {}
	var sal := {}
	for i in l.clubes.size():
		sal[l.clubes[i].id] = int(t[i])
	return sal
