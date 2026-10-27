class_name DesbloqueoModos
extends RefCounted
## «EL BLOQUEO» DE MODOS (decisión del dueño, 27-10-2026): una opción en Ajustes, APAGADA por defecto («Todo
## abierto»). Encendida, algunos modos se ganan jugando, con lo que se lleva entre todas tus partidas (`Meta`:
## temporadas cerradas y títulos del museo global). Los modos de entrada (DT, Ayudante, Carrera de Jugador,
## Retos y Tutorial) siempre están abiertos: nadie se queda sin poder empezar.

## id del modo -> [temporadas cerradas, títulos] que pide (los que no salen, siempre abiertos).
const REGLAS := {
	"interino": [1, 0],
	"dir": [1, 0],
	"cantera": [2, 0],
	"creador": [3, 0],
	"imperio": [0, 1],
	"jeque": [0, 2],
	"fondo": [0, 3],
}

static func activo() -> bool:
	return bool(Meta.leer().get("modos_bloqueados", false))

static func fijar_activo(v: bool) -> void:
	var d := Meta.leer()
	d["modos_bloqueados"] = v
	Meta.guardar(d)

## Lo ganado hasta hoy: {"temporadas", "titulos"}.
static func progreso() -> Dictionary:
	var d := Meta.leer()
	return {"temporadas": int(d.get("temporadas", 0)), "titulos": (d.get("museo", []) as Array).size()}

static func abierto(id: String) -> bool:
	if not activo() or not REGLAS.has(id):
		return true
	var r: Array = REGLAS[id]
	var p := progreso()
	return int(p["temporadas"]) >= int(r[0]) and int(p["titulos"]) >= int(r[1])

## Qué falta para abrirlo, ya traducido ("" si está abierto).
static func requisito(id: String) -> String:
	if abierto(id):
		return ""
	var r: Array = REGLAS[id]
	var p := progreso()
	if int(r[1]) > 0:
		return Idiomas.t("🔒 Se abre al ganar %d títulos (llevas %d).") % [int(r[1]), int(p["titulos"])] if int(r[1]) > 1 \
			else Idiomas.t("🔒 Se abre al ganar tu primer título.")
	return Idiomas.t("🔒 Se abre al completar %d temporadas (llevas %d).") % [int(r[0]), int(p["temporadas"])] if int(r[0]) > 1 \
		else Idiomas.t("🔒 Se abre al completar tu primera temporada.")
