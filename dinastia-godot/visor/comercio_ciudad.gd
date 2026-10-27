class_name ComercioCiudad
extends RefCounted
## EL GANCHO ÚNICO de la E ante los puntos de comercio de la ciudad (tienda de la gasolinera, cajeros y máquinas expendedoras), aparte de
## `SubsueloCiudad.servicio` (redes) para no tocar su archivo y con una sola llamada en `explorador_ciudad_p4.gd`.
static func servicio(e, k: String) -> bool:
	return GasolineraTienda.servicio(e, k) or CajeroCiudad.servicio(e, k) or ExpendedoraCiudad.servicio(e, k) or BancoCiudad.servicio(e, k)
