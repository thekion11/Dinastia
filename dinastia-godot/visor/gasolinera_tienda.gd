class_name GasolineraTienda
extends RefCounted
## La E ante el mostrador de la tienda de la gasolinera (`tienda_<n>`, punto puesto por `CiudadGasolinera`). Aparte de `SubsueloCiudad.servicio` para
## no tocar el archivo de las redes. La compra y el cobro, en `VidaCiudad.usar_tienda`.
static func servicio(e, k: String) -> bool:
	if not k.begins_with("tienda_"):
		return false
	return e.vida != null and e.vida.usar_tienda()
