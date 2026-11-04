class_name MandoPerfiles
extends RefCounted
## PERFILES DE MANDO (2-11-2026, M-442): tres huecos con todo lo que se configura en Controles (esquema de teclado,
## teclas y botones cambiados a mano y ayudas), para quien comparte el PC o juega con dos mandos distintos.
## Archivo propio (`Mando.guardar()` reescribe el suyo entero y los borraría).

const RUTA := "user://perfiles_mando.cfg"
const HUECOS := 3
static var ruta := RUTA   ## las pruebas la cambian para no tocar la del jugador

static func tiene(n: int) -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(ruta) == OK and cfg.has_section("perfil_%d" % n)

## Guarda lo de ahora en el hueco `n` (1..3).
static func guardar_en(n: int) -> void:
	if n < 1 or n > HUECOS:
		return
	if not Mando._cargado:
		Mando.cargar()
	var cfg := ConfigFile.new()
	cfg.load(ruta)
	var s := "perfil_%d" % n
	cfg.set_value(s, "esquema", Mando.esquema)
	cfg.set_value(s, "propio", Mando.propio.duplicate(true))
	cfg.set_value(s, "ayudas", Mando.ayudas.duplicate())
	cfg.save(ruta)

## Carga el hueco `n` en `Mando` (y lo aplica y guarda como los controles de ahora). false si está vacío.
static func cargar_de(n: int) -> bool:
	var cfg := ConfigFile.new()
	var s := "perfil_%d" % n
	if cfg.load(ruta) != OK or not cfg.has_section(s):
		return false
	Mando.esquema = String(cfg.get_value(s, "esquema", "wasd"))
	Mando.propio = (cfg.get_value(s, "propio", {}) as Dictionary).duplicate(true)
	var ay: Dictionary = cfg.get_value(s, "ayudas", {})
	for k: String in Mando.AYUDAS:
		var v := String(ay.get(k, Mando.AYUDAS[k][0]))
		Mando.ayudas[k] = v if v in Mando.AYUDAS[k] else Mando.AYUDAS[k][0]
	Mando.guardar()
	Mando.aplicar()
	return true
