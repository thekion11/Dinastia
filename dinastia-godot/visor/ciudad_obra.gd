class_name CiudadObra
extends RefCounted
## UNA OBRA EN LA PERIFERIA (27-10-2026, «recursos sin usar»): un edificio en estructura (columnas de `kit_edificios` y forjados), una
## grúa torre, la valla de obra, conos, balizas, contenedores y una pala (`ciudad/kenney_roads/construction-*`, `dumpster`; CC0).
## Como el parque solar: la manzana era lejana y se apunta igual (`_lejanos` + `_sin_lejano`) para no mover el azar. No usa `_rng`.
const ROADS := "res://assets/ciudad/kenney_roads/%s.glb"
const EDIF := "res://assets/kenney/kit_edificios/%s.glb"
const PISO := 4.8

static func montar(ex: CiudadExpansion, r: Rect2) -> void:
	var b := ex.b
	var c := Vector3(r.get_center().x, 0.0, r.get_center().y)
	var w := r.size.x
	var f := r.size.y
	var h := absi(hash(Vector2(c.x, c.z)))
	ex._lote("solar", Vector3(c.x, 0.25, c.z), Vector3(w, 0.1, f))
	var hormigon: Material = ex._mat["solar"]
	var Y := 0.3
	## Estructura: 6 × 4 columnas cada 7 m, forjados en los pisos 1 y 2 y medio forjado en el 3.
	var cx := c.x - w * 0.12
	var cz := c.z - f * 0.1
	for i in 6:
		for j in 4:
			for p in 3:
				ex._pieza_kit(EDIF % "column-thin", Vector3(cx + (float(i) - 2.5) * 7.0, Y + float(p) * PISO, cz + (float(j) - 1.5) * 7.0), 2.0, 0.0)
	for p in 3:
		var largo := 36.0 if p < 2 else 22.0
		b._caja_en(Vector3(cx - (36.0 - largo) * 0.5, Y + float(p + 1) * PISO + 0.1, cz), Vector3(largo, 0.4, 22.0), hormigon)
	ex._pieza_kit(EDIF % "stairs-open", Vector3(cx + 21.0, Y, cz), 2.0, PI * 0.5)
	## Grúa torre amarilla con contrapeso y cable.
	var amarillo := b._mat_simple(Color(0.95, 0.75, 0.1), 0.6)
	var gx := cx + 26.0
	var gz := cz - 18.0
	b._caja_en(Vector3(gx, 19.0, gz), Vector3(1.2, 38.0, 1.2), amarillo)
	b._caja_en(Vector3(gx - 10.0, 38.6, gz), Vector3(40.0, 1.0, 1.0), amarillo)
	b._caja_en(Vector3(gx + 8.0, 37.5, gz), Vector3(3.5, 2.4, 2.4), b._mat_simple(Color(0.35, 0.35, 0.35), 0.8))
	b._caja_en(Vector3(gx - 22.0, 32.0, gz), Vector3(0.1, 13.0, 0.1), b._mat_simple(Color(0.1, 0.1, 0.1), 0.9))
	b._caja_en(Vector3(gx - 22.0, 25.0, gz), Vector3(1.8, 1.2, 1.8), amarillo)
	## Valla de obra alrededor (con la entrada al sur), balizas en las esquinas y conos en la puerta.
	var x0 := r.position.x + 3.0
	var x1 := r.end.x - 3.0
	var z0 := r.position.y + 3.0
	var z1 := r.end.y - 3.0
	var paso := 3.0
	var x := x0
	while x < x1:
		ex._pieza_kit(ROADS % "construction-fence", Vector3(x, 0.3, z0), 8.0, PI * 0.5)
		if absf(x - c.x) > 8.0:
			ex._pieza_kit(ROADS % "construction-fence", Vector3(x, 0.3, z1), 8.0, PI * 0.5)
		x += paso
	var z := z0
	while z < z1:
		ex._pieza_kit(ROADS % "construction-fence", Vector3(x0, 0.3, z), 8.0, 0.0)
		ex._pieza_kit(ROADS % "construction-fence", Vector3(x1, 0.3, z), 8.0, 0.0)
		z += paso
	for sx: float in [x0, x1]:
		for sz: float in [z0, z1]:
			ex._pieza_kit(ROADS % "construction-light", Vector3(sx, 0.3, sz), 9.0, 0.0)
	for k in 6:
		ex._pieza_kit(ROADS % "construction-cone", Vector3(c.x - 7.0 + float(k) * 2.8, 0.3, z1 - 2.0), 8.0, 0.0)
	for k in 3:
		ex._pieza_kit(ROADS % "construction-barrier", Vector3(c.x - 6.0 + float(k) * 6.0, 0.3, z1 - 5.0), 8.0, PI * 0.5)
	## Contenedores de escombros, pala y cajas.
	ex._pieza_kit(ROADS % "dumpster", Vector3(x0 + 8.0, 0.3, z1 - 10.0), 8.0, 0.4)
	ex._pieza_kit(ROADS % "dumpster", Vector3(x0 + 13.0, 0.3, z1 - 11.0), 8.0, -0.2)
	var pala: PackedScene = load("res://assets/ciudad/kenney_cars/tractor-shovel.glb")
	if pala != null:
		var n: Node3D = pala.instantiate()
		n.scale = Vector3.ONE * 2.6
		n.position = Vector3(cx - 24.0, 0.3, cz + 14.0)
		n.rotation.y = 0.5 + float(h % 3)
		b.add_child(n)
	var caja := b._mat_simple(Color(0.55, 0.45, 0.3), 0.8)
	for k in 8:
		b._caja_en(Vector3(cx - 22.0 + float(k % 4) * 1.6, 0.9 + float(k / 4) * 1.2, cz - 20.0), Vector3(1.4, 1.1, 1.4), caja)
	var rotulo := Label3D.new()
	rotulo.text = Idiomas.t("Obras")
	rotulo.font_size = 96
	rotulo.pixel_size = 0.03
	rotulo.modulate = Color(0.95, 0.75, 0.1)
	rotulo.outline_modulate = Color(0.1, 0.1, 0.1)
	rotulo.position = Vector3(c.x, 5.0, z1 - 0.2)
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.add_child(rotulo)
