class_name CiudadVilla
extends RefCounted
## LA VILLA MODERNA (27-10-2026, pasada C2 de la ciudad). Antes la manzana instanciaba `oficina_dt.glb` escalado al solar y,
## como el modelo trae una semiesfera de cielo de 103 m, salía una cúpula blanca de ~75 m. Ahora es una casa a escala
## humana armada con piezas del kit suburbano (`assets/kenney/suburbano/`, CC0): la casa principal, un ala y una cochera
## (máximo `ALTO_MAX` m, dos plantas), con camino de losas, acceso de coches y árboles alrededor. `ex` es la expansión
## de la ciudad (`CiudadExpansion`): de ella salen `_pieza_kit`, `_escala_ancho` y `_malla_kit`.
const RUTA := "res://assets/kenney/suburbano/%s.glb"
const ALTO_MAX := 11.5

## [pieza, dx, dz (en fracciones del solar), ancho en m, giro]
const CASAS := [
	["building-type-l", 0.0, -0.06, 22.0, 0.0],
	["building-type-t", 0.24, 0.02, 12.0, 0.0],
	["building-type-b", -0.24, 0.0, 11.0, 0.0],
]

## Levanta la villa en el centro `c` de un solar de `w` × `f`. Devuelve cuántos edificios puso.
static func montar(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> int:
	var puestos := 0
	var y := c.y + 0.3
	for p: Array in CASAS:
		var ruta := RUTA % String(p[0])
		var k: Dictionary = ex._malla_kit(ruta)
		if k.is_empty():
			continue
		var s := minf(ex._escala_ancho(ruta, float(p[3])), ALTO_MAX / maxf((k["caja"] as AABB).size.y, 0.01))
		ex._pieza_kit(ruta, Vector3(c.x + float(p[1]) * w, y, c.z + float(p[2]) * f), s, float(p[4]))
		puestos += 1
	## El acceso de coches y el camino de losas, de la puerta hasta la calle (lado sur), a trozos seguidos.
	for z: float in range(int(f * 0.12), int(f * 0.5), 5):
		ex._pieza_kit(RUTA % "path-stones-long", Vector3(c.x, y + 0.02, c.z + float(z)), ex._escala_ancho(RUTA % "path-stones-long", 3.0), 0.0)
		ex._pieza_kit(RUTA % "driveway-long", Vector3(c.x + w * 0.24, y + 0.02, c.z + float(z)), ex._escala_ancho(RUTA % "driveway-long", 5.0), 0.0)
	## Árboles: grandes en las esquinas del jardín, pequeños junto a la casa.
	for q: Vector2 in [Vector2(-0.36, -0.36), Vector2(0.36, -0.36), Vector2(-0.36, 0.36), Vector2(0.36, 0.36), Vector2(-0.38, 0.0), Vector2(0.38, 0.0)]:
		ex._pieza_kit(RUTA % "tree-large", Vector3(c.x + q.x * w, y, c.z + q.y * f), ex._escala_ancho(RUTA % "tree-large", 7.0), 0.0)
	for q: Vector2 in [Vector2(-0.12, 0.16), Vector2(0.12, 0.16), Vector2(0.3, -0.16)]:
		ex._pieza_kit(RUTA % "tree-small", Vector3(c.x + q.x * w, y, c.z + q.y * f), ex._escala_ancho(RUTA % "tree-small", 3.5), 0.0)
	return puestos
