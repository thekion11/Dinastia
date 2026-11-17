class_name LimpiezaPartido
extends RefCounted
## LAS CACHÉS POR JUGADOR, CON TOPE (17-11-2026, Auditoría: «+17 MB por partido no es normal»). La prueba de extremo a extremo
## (`pruebas/e2e_dia_partido`, 6 partidos seguidos) midió qué crecía: las cachés de los modelos 3D guardadas POR JUGADOR (la cara moldeada y su textura,
## los materiales de equipación y de cara, la ropa aparte, el pelo con volumen, los impostores lejanos…). Cada rival nuevo añadía sus 25-30 jugadores y
## nada se soltaba: ~30-110 MB de texturas por partido, y en una temporada (38 rivales) más de 1 GB.
## Al salir del estadio (`VistaEstadio._exit_tree`) cada una se recorta a su tope quitando LO MÁS ANTIGUO (los diccionarios guardan el orden de llegada):
## tu club y el último rival siguen en la caché (abrir el partido siguiente no recalcula lo tuyo), lo de rivales viejos se suelta. Nada cambia en lo que
## se ve: solo se vuelve a calcular si ese jugador vuelve a salir.

## [script, variable estática, tope]: el tope cubre dos equipos con banquillo y árbitros (cada caché crece a un ritmo distinto por partido).
const CACHES := [
	["res://visor/cara_malla.gd", "_cache", 70],
	["res://visor/cara_malla.gd", "_texturas", 70],
	["res://visor/cara_malla.gd", "_cache_mallas", 70],
	["res://visor/vestidor_q_p1.gd", "_cache_equipacion", 200],
	["res://visor/vestidor_q_p1.gd", "_cache_cara", 300],
	["res://visor/ropa_separada.gd", "_mats", 150],
	["res://visor/pelo_capas_p1.gd", "_cache_cuero", 100],
	["res://visor/pelo_capas_p1.gd", "_cache_pestanas", 60],
	["res://visor/pelo_q.gd", "_mats", 60],
	["res://visor/impostor_lejano.gd", "_mats", 40],
	["res://visor/retrato3d.gd", "_cache", 150],
]

## Recorta todas; devuelve cuántas entradas soltó (para las pruebas).
static func recortar() -> int:
	var soltadas := 0
	for c: Array in CACHES:
		var ruta := String(c[0])
		if not ResourceLoader.has_cached(ruta):
			continue   ## esa pieza no se usó: no hay nada que recortar (y no se carga por esto)
		var d: Variant = (load(ruta) as Script).get(String(c[1]))
		if not (d is Dictionary):
			continue
		var dic := d as Dictionary
		var tope := int(c[2])
		if dic.size() <= tope:
			continue
		var sobran := dic.size() - tope
		for k: Variant in dic.keys().slice(0, sobran):
			dic.erase(k)
		soltadas += sobran
	return soltadas
