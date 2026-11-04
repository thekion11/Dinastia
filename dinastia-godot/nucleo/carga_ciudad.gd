class_name CargaCiudad
extends RefCounted
## CARGADOR PEREZOSO DE LA CIUDAD 3D (3-11-2026). Godot compila un script en cuanto otro lo nombra; al nombrar `CityBuilder`, `ExploradorCiudad`… desde el menú
## se compilaban 1,5 MB de código (~105 MB de RAM) que solo hace falta al salir a la ciudad. Desde FUERA de la familia, `CargaCiudad.de("CityBuilder").construir(…)`
## carga la clase al usarla por primera vez (ver `herramientas/compilacion_menu/aplicar.py` y `docs/04_auditorias/compilacion_menu_2026-11-03.md`).
## Dentro de la familia se siguen nombrando las clases directamente. Regla para código nuevo FUERA de la ciudad: nunca nombrar sus clases; usar esto.
static var _cache := {}

static func de(nombre: String) -> Variant:
	var s: Variant = _cache.get(nombre)
	if s == null:
		s = load(CargaCiudadRutas.RUTAS[nombre])
		_cache[nombre] = s
	return s
