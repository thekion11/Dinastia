class_name ExpansionTardia
extends RefCounted
## EL MOBILIARIO URBANO DE LA CIUDAD, la parte que se puede construir DESPUÉS de mostrarla (2-11-2026, meta de carga de 5 s): marquesinas, guirnaldas, farolas,
## mobiliario, placas de calle, orillas, obras y losetas Kenney. Lo llama `CiudadExpansion.construir` de seguida o, con `CityBuilder.diferir`, `CityBuilder._resto`.

## Con `CityBuilder.diferir`, solo las `PRIMEROS` manzanas más cercanas al estadio se dibujan antes de mostrar la ciudad; el resto se guarda en `ex.bloques_diferidos` (de cerca a lejos).
const PRIMEROS := 26

static func primeros_bloques(ex: CiudadExpansion) -> Array:
	if not CityBuilder.diferir or ex.bloques.size() <= PRIMEROS:
		return ex.bloques
	var orden: Array = ex.bloques.duplicate()
	var centro := Vector2(CityBuilder.ESTADIO_EN.x, CityBuilder.ESTADIO_EN.z)
	orden.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return (a["rect"] as Rect2).get_center().distance_to(centro) < (c["rect"] as Rect2).get_center().distance_to(centro))
	ex.bloques_diferidos = orden.slice(PRIMEROS)
	return orden.slice(0, PRIMEROS)

## Las manzanas que faltan, una a una (cada una cede el fotograma si toca).
static func bloques_restantes(ex: CiudadExpansion) -> void:
	for bl: Dictionary in ex.bloques_diferidos:
		ex._dibujar_bloque(bl)
		await ex.b._marca("exp.bloque")
	ex.bloques_diferidos = []
	ex._edificios_lejanos()
	ex._casas_multimesh()
	ex._modular_multimesh()
	await ex.b._marca("exp.casas")

static func mobiliario(ex: CiudadExpansion) -> void:
	ex._marquesinas_bus()
	ex._guirnaldas()
	ex._farolas()
	ex._mobiliario_urbano()
	ex._placas_de_calle()
	ex._orillas_nucleo()
	ex._obras_en_calle()
	ex._kenney_calles()
	ex.tardio_pendiente = false
	await ex.b._marca("exp.mobiliario")
