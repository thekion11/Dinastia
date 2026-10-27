class_name CiudadOeste
extends RefCounted
## RELLENO DE LAS MANZANAS DE PISOS DEL OESTE (27-10-2026, auditoría de la ciudad, «barrio oeste (pisos)»): seis bloques minúsculos
## esparcidos por una manzana de asfalto vacío. Ahora la manzana lleva una losa de baldosa clara y, a lo largo de
## los lados norte y sur, bloques modulares como los del este (`_bloque_modular`, cada uno distinto por la semilla de su posición).
## No usa `_rng` (todo sale del hash de la posición): no mueve el azar de nada más.

static func rellenar(ex: CiudadExpansion, r: Rect2) -> void:
	if ex._mallas_mod().is_empty():
		return
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	ex._lote("acera", Vector3(c.x, 0.27, c.z), Vector3(r.size.x - 6.0, 0.04, r.size.y - 6.0))
	for fila: float in [-1.0, 1.0]:
		for k in 4:
			var x := c.x + (float(k) - 1.5) * r.size.x * 0.3
			var zf := r.end.y - 1.4 if fila > 0.0 else r.position.y + 1.4
			var puerta: Vector3 = ex._bloque_modular(Vector3(x, 0.24, zf), 0.0 if fila > 0.0 else PI, hash(Vector2(x, zf)), r.size.x * 0.24 - 4.0, r.size.y * 0.3 - 6.0)
			var fam: String = String(ex.APELLIDOS[absi(hash(puerta)) % ex.APELLIDOS.size()])
			ex.b.puntos_clic.append({"k": "edificio_vivienda|Piso de la familia %s" % fam, "n": "Piso de la familia %s" % fam,
				"pos": Vector3(puerta.x, 0, zf + fila * 2.6), "estado": "ciudad", "radio": 6.0})
