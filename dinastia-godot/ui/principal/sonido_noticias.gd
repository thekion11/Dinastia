class_name SonidoNoticias
extends RefCounted
## EL SONIDO DE LAS NOTICIAS DE GESTIÓN (13-11-2026, sesión 15). Los sonidos de club y gestión (alta médica, préstamo, junta, votación…) estaban
## en el catálogo y nadie los pedía. La noticia llega al jugador por `avance_semana._anotar(titulo, cuerpo)`, que es donde SE VE el hecho: aquí se
## decide qué suena según el título (y el cuerpo, para el resultado de una votación). Solo UI: `Sonido.toca` no toca `Azar`, la simulación no cambia.
## Un solo sonido por tipo: el mismo sonido no se repite en menos de `ENFRIAMIENTO_MS` (una semana puede traer varias noticias iguales) y, si
## caen varios distintos a la vez, solo suena el primero.

const ENFRIAMIENTO_MS := 900
static var _ultimo_ms := -100000

## [fragmento del título en minúsculas, sonido]; gana la primera fila que coincida.
const REGLAS := [
	["alta médica", "alta_medica"],
	["se lesiona", "baja_medica"],
	["recaída", "baja_medica"],
	["moción de censura", "sancion_directiva"],
	["apelación acogida", "votacion_ganada"],
	["apelación rechazada", "votacion_perdida"],
	["elecciones en la federación", "elecciones_club"],
	["licencia denegada", "sancion_directiva"],
	["sanción", "sancion_directiva"],
	["multa", "sancion_directiva"],
	["alineación indebida", "sancion_directiva"],
	["tribunal de disciplina", "sancion_directiva"],
	["junta de accionistas", "reunion_directiva"],
	["cedido a préstamo", "prestamo"],
	["cesión a", "cesion_jugador"],
	["vuelve de la cesión", "cesion_jugador"],
	["ejecutan la opción", "cesion_jugador"],
	["entra dinero", "dinero_entra"],
	["cobras", "dinero_entra"],
	["te toca pagar", "dinero_sale"],
	["el fondo cobra", "dinero_sale"],
	["sube un chico del filial", "ascenso_juvenil"],
	["de la academia al primer equipo", "ascenso_juvenil"],
	["debut de la casa", "debut_juvenil"],
	["se retira", "retiro_jugador"],
	["renovado:", "renovacion"],
	["prima de fidelidad", "renovacion"],
	["elige capitán", "capitania"],
	["campaña de abonos", "aumento_socios"],
	["el modelo señala un nombre", "scouting_informe"],
	["gala de fin de año", "premio_individual"],
	["rumor", "rumor_fichaje"],
	["oferta retirada", "oferta_rechazada"],
	["guerra por", "rumor_fichaje"],
]

## El sonido que toca esta noticia ("" si ninguno). El resultado de la asamblea se lee en el cuerpo.
static func de(titulo: String, cuerpo: String = "") -> String:
	var t := titulo.to_lower()
	if t.contains("asamblea de la liga"):
		if cuerpo.contains("salió ganadora"):
			return "votacion_ganada"
		return "votacion_perdida" if cuerpo.contains("minoría") else "reunion_directiva"
	if t.contains("nueva votación"):
		return "reunion_directiva"
	if t.contains("gala de fin de año") and cuerpo.contains("de vacío"):
		return ""
	for r: Array in REGLAS:
		if t.contains(String(r[0])):
			return String(r[1])
	return ""

## Lo toca con enfriamiento. Devuelve el sonido que pidió ("" si no hubo).
static func tocar(titulo: String, cuerpo: String = "") -> String:
	var s := de(titulo, cuerpo)
	if s == "" or not Sonido.catalogo().has(s):
		return ""
	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_ms < ENFRIAMIENTO_MS:
		return ""
	_ultimo_ms = ahora
	Sonido.toca(s, Sonido.Bus.INTERFAZ)
	return s
