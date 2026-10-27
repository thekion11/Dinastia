class_name TiendaGasolinera
extends RefCounted
## LA TIENDA DE LA GASOLINERA (27-10-2026, pieza C de `PLAN_DEL_LUNES.md` §2.2h). E ante el mostrador abre `PanelTienda` con este surtido; cada compra se cobra con `CarteraDT.cobrar`
## y baja el hambre (`Necesidades.picar`) o sube la energía (`Necesidades.animar`) sin gastar tiempo. `elegir` (qué compraría alguien con ese hambre) queda para las pruebas.
const SURTIDO := [
	{"id": "bocadillo", "nombre": "Bocadillo", "precio": 4, "hambre": 25, "energia": 0},
	{"id": "bolleria", "nombre": "Bollería", "precio": 2, "hambre": 12, "energia": 0},
	{"id": "barrita", "nombre": "Barrita de cereales", "precio": 2, "hambre": 8, "energia": 3},
	{"id": "cafe", "nombre": "Café", "precio": 2, "hambre": 3, "energia": 6},
	{"id": "bebida", "nombre": "Bebida energética", "precio": 3, "hambre": 0, "energia": 15},
	{"id": "agua", "nombre": "Botella de agua", "precio": 1, "hambre": 0, "energia": 1},
]

## Qué compra un DT con ese hambre (0-100): bocadillo si tiene hambre, bollería si algo, y si no un café.
static func elegir(hambre: int) -> Dictionary:
	if hambre >= 40:
		return SURTIDO[0]
	if hambre >= 15:
		return SURTIDO[1]
	return SURTIDO[2]
