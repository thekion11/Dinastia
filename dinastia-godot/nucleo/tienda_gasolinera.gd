class_name TiendaGasolinera
extends RefCounted
## LA TIENDA DE LA GASOLINERA (27-10-2026, pieza C de `PLAN_DEL_LUNES.md` §2.2h). Sin pantalla todavía: E ante el mostrador compra lo que toca según
## el hambre del DT (sin gastar tiempo, `Necesidades.picar`) y lo paga con `CarteraDT.cobrar`. Cuando haya pantalla de caja, el surtido es esta tabla.
const SURTIDO := [
	{"id": "bocadillo", "nombre": "Bocadillo", "precio": 4, "hambre": 25},
	{"id": "bolleria", "nombre": "Bollería", "precio": 2, "hambre": 12},
	{"id": "cafe", "nombre": "Café", "precio": 2, "hambre": 3},
]

## Qué compra un DT con ese hambre (0-100): bocadillo si tiene hambre, bollería si algo, y si no un café.
static func elegir(hambre: int) -> Dictionary:
	if hambre >= 40:
		return SURTIDO[0]
	if hambre >= 15:
		return SURTIDO[1]
	return SURTIDO[2]
