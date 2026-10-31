class_name Nativo
extends RefCounted
## LA EXTENSIÓN EN C++ (30-10-2026, rendimiento): `bin_nativo/` (código en `nativo/src`). Los
## bucles más pesados de GDScript, traducidos uno a uno para dar los MISMOS bytes (lo comprueba
## `pruebas/probar_nativo.tscn`). Si no hay binario para esta plataforma (hoy: Android y Web), o con
## `DINASTIA_SIN_NATIVO=1`, `obj()` devuelve null y cada llamador usa su versión GDScript.

static var _obj: Object = null
static var _mirado := false

## Llamar primero desde el hilo principal (los hilos de `RuidosFondo` lo usan después).
static func obj() -> Object:
	if not _mirado:
		_mirado = true
		if OS.get_environment("DINASTIA_SIN_NATIVO") != "1" and ClassDB.class_exists("DinastiaNativo"):
			_obj = ClassDB.instantiate("DinastiaNativo")
	return _obj
