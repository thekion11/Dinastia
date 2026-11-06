class_name Nativo
extends RefCounted
## LA EXTENSIÓN EN C++ (30-10-2026, rendimiento): `bin_nativo/` (código en `nativo/src`). Los
## bucles más pesados de GDScript, traducidos uno a uno para dar los MISMOS bytes (lo comprueba
## `pruebas/probar_nativo.tscn`). Si no hay binario para esta plataforma (hoy: Web; el de Android lo compila el CI, M-353), o con
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

## TRACY (5-11, opcional; docs/04_auditorias/tracy_2026-11-05.md): zonas propias desde GDScript. Sin la compilación `tracy`
## no hacen nada y cuestan una comprobación. Uso: `Nativo.zona("ia_22")` ... `Nativo.zona_fin()` (siempre en pareja, hilo principal).
static func zona(nombre: String) -> void:
	var o := obj()
	if o != null:
		o.tracy_zona_ini(nombre)

static func zona_fin() -> void:
	var o := obj()
	if o != null:
		o.tracy_zona_fin()

static func fotograma() -> void:
	var o := obj()
	if o != null:
		o.tracy_fotograma()
