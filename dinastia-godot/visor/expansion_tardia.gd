class_name ExpansionTardia
extends RefCounted
## EL MOBILIARIO URBANO DE LA CIUDAD, la parte que se puede construir DESPUÉS de mostrarla (2-11-2026, meta de carga de 5 s): marquesinas, guirnaldas, farolas,
## mobiliario, placas de calle, orillas, obras y losetas Kenney. Lo llama `CiudadExpansion.construir` de seguida o, con `CityBuilder.diferir`, `CityBuilder._resto`.

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
