class_name Nativo
extends RefCounted
## LA EXTENSIÓN EN C++ (30-10-2026, rendimiento): `bin_nativo/` (código en `nativo/src`). Los
## bucles más pesados de GDScript, traducidos uno a uno para dar los MISMOS bytes (lo comprueba
## `pruebas/probar_nativo.tscn`). Si no hay binario para esta plataforma (macOS, iOS; Web sí lo tiene desde el 16-11: wasm32 sin hilos con plantilla dlink), o con
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

static var _tiene: Dictionary = {}

## La extensión SOLO si trae ese método (20-11): un binario de otra plataforma compilado antes de que existiera esa función
## devuelve null y el llamador usa su gemela GDScript. El resultado de cada nombre se guarda (un `has_method` por nombre).
static func de(nombre: String) -> Object:
	var o := obj()
	if o == null:
		return null
	if not _tiene.has(nombre):
		_tiene[nombre] = o.has_method(nombre)
	return o if _tiene[nombre] else null
