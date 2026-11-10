class_name KitLegible
extends RefCounted
## LEGIBILIDAD DE LA CAMISETA A LA CÁMARA REAL DEL PARTIDO (10-11): a esa distancia el jugador mide ~30 px y los dibujos finos (franjas finas, aros finos, diagonal fina)
## se funden en un color medio. Para el campo (no para las fichas 2D ni el editor) se pasa cada diseño fino al de su misma familia con trazos más anchos.
## El club conserva su diseño en todas las demás pantallas; aquí solo cambia el ancho del trazo.
const ANCHOS := {"franjas": "franjas_anchas", "franjas_finas": "franjas", "aros": "aros_anchos", "aros_finos": "aros", "diagonal": "sash",
	"bastones": "vertical3", "cuadros": "tercios_h"}

## La equipación `x` (de `DisenosKit.kit_de_club`) con el diseño de la camiseta más ancho si era fino. No toca el original.
static func para_partido(x: Dictionary) -> Dictionary:
	var d := String(x.get("dis", ""))
	if not ANCHOS.has(d):
		return x
	var y := x.duplicate()
	y["dis"] = ANCHOS[d]
	return y
