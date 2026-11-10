class_name CasaAcceso
extends RefCounted
## LA PUERTA DE LA CASA DEL PERSONAJE (10-11, orden 33 «solo club»). Menú Vida → «Ver tu casa» y la acción «casa» del menú lateral
## llegan aquí. Con la ciudad apagada (`InterruptorCiudad.activa` falso, lo normal) se entra a la casa a pie, sin construir la
## ciudad (`CasaRecorrido`); con la ciudad encendida sigue la escena de siempre (`CasaEscena3D`: terraza, móvil, cámara libre).
## Ni una ni otra se nombran como clase: el menú no puede arrastrar el 3D a la memoria (regla del 3-11), así que van por `load`.

static func abrir(p: Control, m: Mundo, bandeja: Array = []) -> Control:
	if InterruptorCiudad.activa:
		return CargaCiudad.de("CasaEscena3D").abrir(p, m, bandeja)
	return load("res://ui/casa_recorrido.gd").abrir(p, m, bandeja)
