class_name BancoCiudad
extends RefCounted
## El gancho de la E ante la ventanilla del banco (`banco_<n>`, puesta por `CiudadBanco`): abre el panel en modo ventanilla (`VidaCiudad.usar_banco`).
static func servicio(e, k: String) -> bool:
	if not k.begins_with("banco_"):
		return false
	return e.vida != null and e.vida.usar_banco(k)
