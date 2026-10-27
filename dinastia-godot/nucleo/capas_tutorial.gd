class_name CapasTutorial
extends RefCounted
## TUTORIAL POR CAPAS (27-10-2026, fila 1040): además del recorrido guiado del principio, cada sistema enseña su capa la PRIMERA vez que el jugador lo usa
## (Mi plantel, Táctica, Entrenar, Enfermería, Camarín, Cantera, Contratos, Mercado, Finanzas…): una tarjeta con 3 líneas, las mismas de la «?» de esa
## pantalla (`AyudaPestana.TEXTOS`). Se cierra con «Entendido» (no vuelve a salir esa capa) o con «No mostrar más ayudas» (se apaga todo); se vuelve a
## encender, o a empezar de cero, desde Ajustes. Lo que se ha visto es del JUGADOR, no de la partida (`user://ajustes.cfg`, sección `capas`).
## Lo apaga también el «Modo experto», y no sale mientras corre el recorrido guiado ni en las pruebas sin pantalla (salvo `forzar`).
const ARCHIVO := "user://ajustes.cfg"
const SECCION := "capas"

static var forzar := false   ## las pruebas lo encienden para ver la tarjeta sin pantalla

static func _cargar() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(ARCHIVO)
	return cf

static func activas() -> bool:
	return bool(_cargar().get_value(SECCION, "activas", true))

static func poner_activas(si: bool) -> void:
	var cf := _cargar()
	cf.set_value(SECCION, "activas", si)
	cf.save(ARCHIVO)

static func vistas() -> Array:
	return Array(_cargar().get_value(SECCION, "vistas", []))

static func marcar_vista(clave: String) -> void:
	var cf := _cargar()
	var v := Array(cf.get_value(SECCION, "vistas", []))
	if not v.has(clave):
		v.append(clave)
	cf.set_value(SECCION, "vistas", v)
	cf.save(ARCHIVO)

## Vuelve a empezar: todas las capas sin ver y las ayudas encendidas.
static func reiniciar() -> void:
	var cf := _cargar()
	cf.set_value(SECCION, "vistas", [])
	cf.set_value(SECCION, "activas", true)
	cf.save(ARCHIVO)

## ¿Toca enseñar la capa de `clave` ahora? (la pestaña tiene ayuda, aún no se vio y todo está encendido)
static func debe_mostrar(clave: String, modo_experto := false) -> bool:
	if modo_experto or not AyudaPestana.TEXTOS.has(clave):
		return false
	if DisplayServer.get_name() == "headless" and not forzar:
		return false
	return activas() and not vistas().has(clave)
