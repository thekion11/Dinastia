class_name CiudadSolar
extends RefCounted
## EL PARQUE SOLAR DE LA PERIFERIA (27-10-2026, orden del dueño: recursos sin usar en las zonas vacías). Una manzana lejana que era un campo de cajas
## baratas pasa a ser un parque solar con las piezas sin usar del kit industrial (`solar-panel-*`, `windmill-low`, `building-*`, CC0): cuatro hileras
## de paneles orientados al sur, una subestación, dos molinos pequeños al norte, un camino de servicio y la valla. Se registra como la feria
## (`_lejanos` + `_sin_lejano`) para que el azar de los edificios lejanos se consuma igual y no se mueva nada más de la ciudad.
const IND := "res://assets/kenney/industrial/%s.glb"
const Y := 0.12

static func _suelto(ex: CiudadExpansion, ruta: String, pos: Vector3, esc: float, giro: float) -> void:
	var ps := load(ruta) as PackedScene
	if ps == null:
		return
	var n: Node3D = ps.instantiate()
	n.scale = Vector3.ONE * esc
	n.position = pos
	n.rotation.y = giro
	ex.b.add_child(n)

static func montar(ex: CiudadExpansion, r: Rect2) -> void:
	var b := ex.b
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	var w := r.size.x
	var f := r.size.y
	ex._lote("cesped", Vector3(c.x, 0.25, c.z), Vector3(w, 0.1, f))
	## Camino de servicio de tierra, de norte a sur por el centro, y entrada.
	ex._lote("solar", Vector3(c.x, 0.3, c.z), Vector3(5.0, 0.06, f * 0.96))
	## Cuatro hileras de ocho mesas de paneles; el pasillo de en medio queda libre.
	var ruta := IND % "solar-panel-landscape-group"
	for fila in 4:
		for k in 8:
			var x := c.x + (float(k) - 3.5) * w * 0.105 + (2.4 if k >= 4 else -2.4)
			var z := c.z + (float(fila) - 1.2) * f * 0.2
			_suelto(ex, ruta, Vector3(x, Y + 0.2, z), 4.2, PI)
	## Subestación (caseta con transformadores) junto a la entrada sur, y valla.
	_suelto(ex, IND % "building-n", Vector3(c.x + w * 0.32, Y, c.z + f * 0.42), 4.5, PI)
	_suelto(ex, IND % "building-b", Vector3(c.x - w * 0.32, Y, c.z + f * 0.42), 3.5, PI)
	for k in 2:
		_suelto(ex, IND % "windmill-low", Vector3(c.x + (float(k) - 0.5) * w * 0.5, Y, c.z - f * 0.44), 9.0, float(k) * 1.1)
	var valla := b._mat_simple(Color(0.34, 0.36, 0.38), 0.6)
	b._caja_en(Vector3(c.x, 1.0, c.z - f * 0.5 + 1.0), Vector3(w - 2.0, 2.0, 0.12), valla)
	b._caja_en(Vector3(c.x, 1.0, c.z + f * 0.5 - 1.0), Vector3(w - 2.0, 2.0, 0.12), valla)
	for sx: float in [-1.0, 1.0]:
		b._caja_en(Vector3(c.x + sx * (w * 0.5 - 1.0), 1.0, c.z), Vector3(0.12, 2.0, f - 2.0), valla)
