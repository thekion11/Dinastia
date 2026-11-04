class_name TunelMedidas
extends RefCounted
## LAS MEDIDAS DEL TÚNEL Y DEL VESTUARIO (3-11-2026, memoria del menú): constantes y `zona_en`, sin dependencias, para que quien solo necesita saber dónde
## está la puerta o en qué zona está un punto no cargue `TunelVestuario` (que arrastra al constructor del estadio). `TunelVestuario` las repite con
## los mismos nombres.

## Medio ancho libre del pasillo y su alto libre.
const MEDIO := 2.4
const ALTO := 3.0
## La puerta del club en la fachada de atrás del vestuario (a la calle): desplazada del eje para no chocar con la pizarra.
const PUERTA_X := 5.5
const PUERTA_MEDIO := 1.3
## Vestuario: medio ancho y fondo.
const VEST_MEDIO := 8.0
const VEST_FONDO := 13.0

## ¿En qué zona transitable cae `p` (coordenadas del estadio)? Vacío si en ninguna. Lo usan los dos exploradores (el del estadio y el de la ciudad).
static func zona_en(zonas: Array, p: Vector3, planta: int = 0) -> Dictionary:
	for z: Dictionary in zonas:
		if int(z.get("planta", 0)) == planta and (z["r"] as Rect2).has_point(Vector2(p.x, p.z)):
			return z
	return {}
