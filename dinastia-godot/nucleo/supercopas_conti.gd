class_name SupercopasConti
extends RefCounted
## LAS SUPERCOPAS CONTINENTALES (sesión 6, 10-11): al empezar la temporada, el campeón de la copa grande de una
## confederación contra el de la segunda copa, a partido único y en cancha neutral.
##
##   Supercopa de Europa   campeón de la Champions  contra el de la Europa League
##   Recopa Sudamericana   campeón de la Libertadores contra el de la Sudamericana
##   Supercopa CAF         campeón de África contra el de la Copa de la Confederación
##
## Van en `Mundo.nueva_temporada()` justo antes de volver a sortear los continentales (los campeones del año que se
## cierra siguen en `continentales`), igual que la supercopa nacional. Se juegan simuladas, con azar propio
## (`CopasMundo._aislado`) para no mover nada de lo que ya pasaba: si tu club es uno de los dos, ganar suma el título
## a tu vitrina, cobra el premio y queda en el palmarés del mundo.

const TABLA := [
	{"nombre": "Supercopa de Europa", "grande": "ucl", "chica": "uel", "premio": 300000},
	{"nombre": "Recopa Sudamericana", "grande": "lib", "chica": "sud", "premio": 150000},
	{"nombre": "Supercopa CAF", "grande": "afr", "chica": "afr2", "premio": 120000},
]

## Juega las supercopas con los campeones de los continentales de la temporada que se cierra. Devuelve lo jugado:
## [{nombre, local, visita, gl, gv, penales, campeon, mio}].
static func jugar(m: Mundo) -> Array:
	var jugadas: Array = []
	if m == null:
		return jugadas
	for fila: Dictionary in TABLA:
		var grande: Continental = m.continentales.get(String(fila["grande"]))
		var chica: Continental = m.continentales.get(String(fila["chica"]))
		if grande == null or chica == null or grande.campeon == null or chica.campeon == null or grande.campeon == chica.campeon:
			continue
		jugadas.append(_partido(m, fila, grande.campeon, chica.campeon))
	return jugadas

static func _partido(m: Mundo, fila: Dictionary, a: Club, b: Club) -> Dictionary:
	var p := Partido.new(a, b, true)
	var guarda := {"penales": []}   ## una lambda no puede reasignar una variable de fuera: se guarda dentro del diccionario
	CopasMundo._aislado("supercont%d/%s" % [m.anio, String(fila["grande"])], func() -> void:
		p.simular()
		if p.goles_local == p.goles_visita:
			guarda["penales"] = p.penales())
	var penales: Array = guarda["penales"]
	var gana: Club = a
	if p.goles_visita > p.goles_local:
		gana = b
	elif p.goles_local == p.goles_visita and int(penales[1]) > int(penales[0]):
		gana = b
	gana.mover_saldo(int(fila["premio"]))
	var nombre := String(fila["nombre"])
	CopasMundo.anotar(m, gana.pais, nombre, gana)
	var mio := gana == m.mi_club()
	if mio:
		if m.logros != null:
			m.logros.celebrar_titulo(nombre)
		if m.roles != null:
			m.roles.sumar_trofeo(nombre, {"final": "%s %d-%d %s" % [a.nombre, p.goles_local, p.goles_visita, b.nombre]})
	if m.prensa != null:
		m.prensa.noticia.emit("🏆 %s" % nombre, "%s %d-%d %s%s. %s se lleva el título." % [
			a.nombre, p.goles_local, p.goles_visita, b.nombre,
			(" (pen. %d-%d)" % [int(penales[0]), int(penales[1])]) if not penales.is_empty() else "", gana.nombre])
	return {"nombre": nombre, "local": a, "visita": b, "gl": p.goles_local, "gv": p.goles_visita,
		"penales": penales, "campeon": gana, "mio": mio}
