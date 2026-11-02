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

## El azar de cada pieza sale de SU clave y no de lo que se haya dibujado antes (`_rng` compartido): así la ciudad es la misma se construya de seguida o por partes, y en cualquier orden.
static func sembrar(ex: CiudadExpansion, clave: Variant) -> void:
	ex._rng.seed = 13072026 + hash(clave)

## Una manzana, con su propio azar.
static func bloque(ex: CiudadExpansion, bl: Dictionary) -> void:
	sembrar(ex, ["bloque", bl["celda"]])
	ex._dibujar_bloque(bl)

## Lo que se agrupa tras dibujar todas las manzanas: edificios lejanos, casas y modulares.
static func casas(ex: CiudadExpansion) -> void:
	sembrar(ex, "edificios_lejanos")
	ex._edificios_lejanos()
	sembrar(ex, "casas")
	ex._casas_multimesh()
	sembrar(ex, "modular")
	ex._modular_multimesh()

## Las manzanas que faltan, una a una (cada una cede el fotograma si toca).
static func bloques_restantes(ex: CiudadExpansion) -> void:
	for bl: Dictionary in ex.bloques_diferidos:
		bloque(ex, bl)
		await ex.b._marca("exp.bloque")
	ex.bloques_diferidos = []
	casas(ex)
	await ex.b._marca("exp.casas")

static func mobiliario(ex: CiudadExpansion) -> void:
	sembrar(ex, "marquesinas")
	ex._marquesinas_bus()
	sembrar(ex, "guirnaldas")
	ex._guirnaldas()
	sembrar(ex, "farolas")
	ex._farolas()
	sembrar(ex, "mobiliario")
	ex._mobiliario_urbano()
	sembrar(ex, "placas")
	ex._placas_de_calle()
	sembrar(ex, "orillas")
	ex._orillas_nucleo()
	sembrar(ex, "obras")
	ex._obras_en_calle()
	sembrar(ex, "kenney")
	ex._kenney_calles()
	ex.tardio_pendiente = false
	await ex.b._marca("exp.mobiliario")

## Lo más lejano de la ciudad (no está en el prólogo): la autopista, el parque eólico, el depósito de agua y el teleférico.
static func afueras(ex: CiudadExpansion) -> void:
	sembrar(ex, "autopista")
	ex.cuenta["autopista"] = Autopista.montar(ex.b)
	sembrar(ex, "eolico")
	ex._parque_eolico()
	sembrar(ex, "deposito")
	ex._deposito_agua()
	ex.tele_nodo = Teleferico.montar(ex.b)
	ex.teleferico = ex.tele_nodo.datos()
