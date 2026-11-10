class_name EstrategiaRapida
extends RefCounted
## LAS ESTRATEGIAS RÁPIDAS DEL PARTIDO (10-11; idea del PES, aprobada por el dueño: cambiar el plan con un toque sin parar el partido). Cuatro preajustes de
## las MISMAS cuatro palancas de la pizarra (`Tactica`: mentalidad, presión, línea, ritmo; 0-2 cada una), así que el motor no cambia: el partido las
## aplica igual que si las tocaras en la pizarra. Volver a pulsar la activa devuelve el plan que tenías antes. Entre cambio y cambio, `ESPERA` minutos.
const ESPERA := 2   ## minutos de partido entre dos cambios rápidos
## clave: [icono, nombre, mentalidad, presión, línea, ritmo]
const PRESETS := {
	"ataque": ["⚔", "Ataque total", 2, 2, 2, 2],
	"presion": ["🔥", "Presión arriba", 1, 2, 2, 1],
	"contra": ["⚡", "Contraataque", 0, 1, 0, 2],
	"cerrojo": ["🔒", "Cerrojo", 0, 0, 0, 0],
}
const ORDEN := ["ataque", "presion", "contra", "cerrojo"]

var activa := ""
var _plan_previo: Array = []
var _ultimo_minuto := -100

## ¿Se puede cambiar ya? (la espera desde el último cambio rápido).
func puede(minuto: int) -> bool:
	return minuto - _ultimo_minuto >= ESPERA

static func foto(t: Tactica) -> Array:
	return [t.mentalidad, t.presion, t.linea, t.ritmo]

static func poner(t: Tactica, v: Array) -> void:
	t.mentalidad = int(v[0]); t.presion = int(v[1]); t.linea = int(v[2]); t.ritmo = int(v[3])

## Aplica (o, si ya estaba activa, quita) la estrategia `clave` en la táctica de `club`. Devuelve "" si se aplicó, o el motivo si no.
func aplicar(club: Club, clave: String, minuto: int) -> String:
	if not PRESETS.has(clave):
		return "no existe"
	if not puede(minuto):
		return "espera"
	var t := club.tactica
	if activa == clave:
		poner(t, _plan_previo)
		activa = ""
	else:
		if activa == "":
			_plan_previo = foto(t)
		var p: Array = PRESETS[clave]
		poner(t, [p[2], p[3], p[4], p[5]])
		activa = clave
	_ultimo_minuto = minuto
	return ""
