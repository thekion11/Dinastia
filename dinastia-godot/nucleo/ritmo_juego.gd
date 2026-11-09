class_name RitmoJuego
extends RefCounted
## (9-11, orden del dueño: «la velocidad es demasiado rápida para jugar con mando»; referencia PES 2020, que tiene un ritmo más pausado
## y un ajuste de velocidad de juego). Escala del tiempo del partido EN DIRECTO (jugadores, balón y reloj a la vez): solo la usa
## `MotorJugable._physics_process`; `paso(delta)` no la toca, así que las pruebas y la simulación no cambian.
const RUTA := "user://ajustes.cfg"
const SECCION := "juego"
const CLAVE := "velocidad_juego"
## Nombre → escala. «Normal» es 0,85 (más pausado que el 1,0 de antes); «Arcade» devuelve el ritmo anterior y algo más.
const NIVELES := [["Lenta", 0.70], ["Normal", 0.85], ["Rápida", 1.00], ["Arcade", 1.15]]
const POR_DEFECTO := 1
static var _i := -1

static func indice() -> int:
	if _i < 0:
		var cfg := ConfigFile.new()
		cfg.load(RUTA)
		_i = clampi(int(cfg.get_value(SECCION, CLAVE, POR_DEFECTO)), 0, NIVELES.size() - 1)
	return _i

static func escala() -> float:
	return float((NIVELES[indice()] as Array)[1])

static func fijar(i: int) -> void:
	_i = clampi(i, 0, NIVELES.size() - 1)
	var cfg := ConfigFile.new()
	cfg.load(RUTA)
	cfg.set_value(SECCION, CLAVE, _i)
	cfg.save(RUTA)
